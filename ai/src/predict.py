import json
from functools import lru_cache
from pathlib import Path
from typing import Any, Dict, List, Tuple

import joblib
import pandas as pd

try:
    from src.load_dataset import preprocess_data
except ModuleNotFoundError:
    from load_dataset import preprocess_data

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent
MODELS_DIR = BASE_DIR / "models"

CLASSIFIER_PATH = MODELS_DIR / "fraud_paysim_xgboost_features.pkl"
ANOMALY_MODEL_PATH = MODELS_DIR / "fraud_isolation_forest.pkl"

VALID_TRANSACTION_TYPES = {"CASH_IN", "CASH_OUT", "DEBIT", "PAYMENT", "TRANSFER"}

REQUIRED_FIELDS = [
    "step",
    "type",
    "amount",
    "oldbalanceOrg",
    "newbalanceOrig",
    "oldbalanceDest",
    "newbalanceDest",
    "isFlaggedFraud",
]

NUMERIC_FIELDS = [
    "step",
    "amount",
    "oldbalanceOrg",
    "newbalanceOrig",
    "oldbalanceDest",
    "newbalanceDest",
    "isFlaggedFraud",
]

EXPECTED_RAW_COLUMNS = [
    "step",
    "type",
    "amount",
    "nameOrig",
    "oldbalanceOrg",
    "newbalanceOrig",
    "nameDest",
    "oldbalanceDest",
    "newbalanceDest",
    "isFlaggedFraud",
]

# Optional: use training-derived values later if available
ANOMALY_REFERENCE_MIN = -0.06
ANOMALY_REFERENCE_MAX = 0.29

APPROVE_THRESHOLD = 40
BLOCK_THRESHOLD = 70


# -------------------------------------------------------------------
# Model loading
# -------------------------------------------------------------------
@lru_cache(maxsize=1)
def load_models() -> Tuple[Any, Any]:
    """
    Load and cache trained classifier and anomaly detector.
    Lazy loading prevents import-time crashes in API apps.
    """
    if not CLASSIFIER_PATH.exists():
        raise FileNotFoundError(f"Classifier model not found: {CLASSIFIER_PATH}")

    if not ANOMALY_MODEL_PATH.exists():
        raise FileNotFoundError(f"Anomaly model not found: {ANOMALY_MODEL_PATH}")

    classifier_model = joblib.load(CLASSIFIER_PATH)
    anomaly_model = joblib.load(ANOMALY_MODEL_PATH)

    if not hasattr(classifier_model, "predict_proba"):
        raise TypeError("Classifier model must implement predict_proba().")

    if not hasattr(anomaly_model, "predict"):
        raise TypeError("Anomaly model must implement predict().")

    if not hasattr(anomaly_model, "decision_function"):
        raise TypeError("Anomaly model must implement decision_function().")

    return classifier_model, anomaly_model


# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------
def validate_transaction(transaction: Dict[str, Any]) -> Dict[str, Any]:
    """
    Validate and normalize incoming transaction payload.
    Returns a cleaned transaction dict.
    """
    if not isinstance(transaction, dict):
        raise ValueError("Transaction payload must be a JSON object / Python dict.")

    missing_fields = [field for field in REQUIRED_FIELDS if field not in transaction]
    if missing_fields:
        raise ValueError(f"Missing required fields: {missing_fields}")

    cleaned = transaction.copy()

    if not isinstance(cleaned["type"], str):
        raise ValueError("Transaction type must be a string.")

    cleaned["type"] = cleaned["type"].strip().upper()
    if cleaned["type"] not in VALID_TRANSACTION_TYPES:
        raise ValueError(
            f"Invalid transaction type: {transaction['type']}. "
            f"Valid types: {sorted(VALID_TRANSACTION_TYPES)}"
        )

    for field in NUMERIC_FIELDS:
        if not isinstance(cleaned[field], (int, float)):
            raise ValueError(f"{field} must be numeric.")

    if cleaned["step"] < 0:
        raise ValueError("step cannot be negative.")
    if cleaned["amount"] < 0:
        raise ValueError("amount cannot be negative.")
    if cleaned["oldbalanceOrg"] < 0 or cleaned["newbalanceOrig"] < 0:
        raise ValueError("origin balances cannot be negative.")
    if cleaned["oldbalanceDest"] < 0 or cleaned["newbalanceDest"] < 0:
        raise ValueError("destination balances cannot be negative.")
    if cleaned["isFlaggedFraud"] not in (0, 1):
        raise ValueError("isFlaggedFraud must be 0 or 1.")

    # Optional defaults for schema compatibility
    cleaned.setdefault("nameOrig", "C_UNKNOWN_ORIG")
    cleaned.setdefault("nameDest", "C_UNKNOWN_DEST")

    return cleaned


# -------------------------------------------------------------------
# Preprocessing
# -------------------------------------------------------------------
def build_raw_transaction_df(transaction: Dict[str, Any]) -> pd.DataFrame:
    """
    Build a one-row raw dataframe using the expected training schema.
    """
    tx = transaction.copy()
    df = pd.DataFrame([tx])

    for col in EXPECTED_RAW_COLUMNS:
        if col not in df.columns:
            if col == "type":
                df[col] = "PAYMENT"
            elif col == "nameOrig":
                df[col] = "C_UNKNOWN_ORIG"
            elif col == "nameDest":
                df[col] = "C_UNKNOWN_DEST"
            else:
                df[col] = 0

    return df[EXPECTED_RAW_COLUMNS]


def preprocess_transaction(transaction: Dict[str, Any]) -> pd.DataFrame:
    """
    Preprocess a single transaction using the same logic as training.
    """
    raw_df = build_raw_transaction_df(transaction)

    # Shared preprocessing expects training-like structure
    raw_df["isFraud"] = 0

    processed_df = preprocess_data(raw_df)

    # Drop labels before inference
    cols_to_drop = [col for col in ["isFraud", "isFlaggedFraud"] if col in processed_df.columns]
    processed_df = processed_df.drop(columns=cols_to_drop)

    # Convert booleans if any were created in preprocessing
    bool_cols = processed_df.select_dtypes(include=["bool"]).columns.tolist()
    if bool_cols:
        processed_df[bool_cols] = processed_df[bool_cols].astype(int)

    # Final safety: convert any remaining non-numeric columns if possible
    non_numeric_cols = processed_df.select_dtypes(exclude=["number"]).columns.tolist()
    if non_numeric_cols:
        raise ValueError(
            f"Preprocessing produced non-numeric columns not suitable for inference: {non_numeric_cols}"
        )

    return processed_df


def align_features_for_model(processed_df: pd.DataFrame, model: Any) -> pd.DataFrame:
    """
    Align dataframe columns to match model training features exactly.
    Extra columns are dropped; missing columns are added as zeros.
    """
    aligned_df = processed_df.copy()

    if not hasattr(model, "feature_names_in_"):
        return aligned_df

    expected_features = list(model.feature_names_in_)

    for col in expected_features:
        if col not in aligned_df.columns:
            aligned_df[col] = 0

    extra_cols = [col for col in aligned_df.columns if col not in expected_features]
    if extra_cols:
        aligned_df = aligned_df.drop(columns=extra_cols)

    aligned_df = aligned_df[expected_features]
    return aligned_df


# -------------------------------------------------------------------
# Scoring helpers
# -------------------------------------------------------------------
def normalize_anomaly_risk(
    anomaly_score: float,
    reference_min: float = ANOMALY_REFERENCE_MIN,
    reference_max: float = ANOMALY_REFERENCE_MAX,
) -> float:
    """
    Convert raw Isolation Forest score to an interpretable 0-100 anomaly risk.
    Lower raw score => higher anomaly risk.
    """
    if reference_max <= reference_min:
        return 0.0

    clipped = min(max(anomaly_score, reference_min), reference_max)
    normalized = (reference_max - clipped) / (reference_max - reference_min)
    return round(normalized * 100, 2)


def derive_reasons(
    transaction: Dict[str, Any],
    fraud_probability: float,
    anomaly_prediction: int,
    anomaly_score: float,
) -> List[str]:
    """
    Generate human-readable reasons for the decision.
    """
    reasons: List[str] = []

    if fraud_probability >= 0.95:
        reasons.append("Very high fraud probability from supervised classifier")
    elif fraud_probability >= 0.70:
        reasons.append("High fraud probability from supervised classifier")
    elif fraud_probability >= 0.40:
        reasons.append("Moderate fraud probability from supervised classifier")
    else:
        reasons.append("Low fraud probability from supervised classifier")

    if anomaly_prediction == -1:
        reasons.append("Unusual transaction behavior detected by anomaly model")
    elif anomaly_score < 0.02:
        reasons.append("Borderline anomalous transaction pattern detected")

    tx_type = transaction["type"]

    if tx_type in {"TRANSFER", "CASH_OUT"} and transaction["amount"] >= 50000:
        reasons.append("High-value transfer or cash-out transaction")

    if (
    transaction["oldbalanceOrg"] > 0
    and transaction["newbalanceOrig"] == 0
    and transaction["amount"] >= 50000
    and transaction["type"] in {"TRANSFER", "CASH_OUT"}
):
        reasons.append("Source account balance drained to zero on high-risk transfer/cash-out")

    if (
        tx_type == "TRANSFER"
        and transaction["oldbalanceDest"] == 0
        and transaction["newbalanceDest"] == 0
    ):
        reasons.append("Destination balance pattern appears unusual for transfer")

    if transaction["isFlaggedFraud"] == 1:
        reasons.append("Transaction was flagged by upstream rule-based system")

    if transaction["newbalanceOrig"] > transaction["oldbalanceOrg"]:
        reasons.append("Origin balance increased after transaction, which is unusual")

    return reasons


def compute_risk_score(
    transaction: Dict[str, Any],
    fraud_probability: float,
    anomaly_prediction: int,
    anomaly_score: float,
) -> int:
    """
    Compute final risk score using classifier probability as the primary signal,
    with anomaly and business-rule safeguards layered on top.
    """
    risk_score = int(round(fraud_probability * 100))

    # Anomaly safeguard
    if anomaly_prediction == -1:
        risk_score = max(risk_score, 55)
    elif anomaly_score < 0.02:
        risk_score = max(risk_score, 45)

    # High-risk transfer/cash-out safeguard
    tx_type = transaction["type"]
    if tx_type in {"TRANSFER", "CASH_OUT"} and transaction["amount"] >= 50000:
        risk_score = max(risk_score, 40)

    # Full-balance-drain safeguard
    if (
    transaction["oldbalanceOrg"] > 0
    and transaction["newbalanceOrig"] == 0
    and transaction["amount"] >= 50000
    and transaction["type"] in {"TRANSFER", "CASH_OUT"}
):
        risk_score = max(risk_score, 50)

    # Upstream system signal safeguard
    if transaction["isFlaggedFraud"] == 1:
        risk_score = max(risk_score, 85)

    # Defensive logical inconsistency safeguard
    if transaction["newbalanceOrig"] > transaction["oldbalanceOrg"]:
        risk_score = max(risk_score, 60)

    return max(0, min(risk_score, 100))


def map_decision(risk_score: int) -> Dict[str, str]:
    """
    Convert risk score into business action.
    """
    if risk_score >= BLOCK_THRESHOLD:
        return {
            "status": "BLOCK",
            "recommended_action": "Block transaction and trigger security review",
        }
    if risk_score >= APPROVE_THRESHOLD:
        return {
            "status": "FLAG",
            "recommended_action": "Flag transaction for review, OTP verification, or step-up authentication",
        }
    return {
        "status": "APPROVE",
        "recommended_action": "Allow transaction",
    }


# -------------------------------------------------------------------
# Main prediction function
# -------------------------------------------------------------------
def predict_transaction(transaction: Dict[str, Any]) -> Dict[str, Any]:
    """
    Predict fraud risk for a single transaction using:
    1. supervised classifier
    2. anomaly detector
    3. rule-based safeguards

    Returns a production-friendly response payload.
    """
    classifier_model, anomaly_model = load_models()
    validated_tx = validate_transaction(transaction)

    processed_df = preprocess_transaction(validated_tx)

    classifier_input = align_features_for_model(processed_df, classifier_model)
    anomaly_input = align_features_for_model(processed_df, anomaly_model)

    fraud_probability = float(classifier_model.predict_proba(classifier_input)[0][1])

    anomaly_prediction = int(anomaly_model.predict(anomaly_input)[0])  # -1 anomaly, 1 normal
    anomaly_raw_score = float(anomaly_model.decision_function(anomaly_input)[0])
    anomaly_risk_score = normalize_anomaly_risk(anomaly_raw_score)

    risk_score = compute_risk_score(
        transaction=validated_tx,
        fraud_probability=fraud_probability,
        anomaly_prediction=anomaly_prediction,
        anomaly_score=anomaly_raw_score,
    )

    reasons = derive_reasons(
        transaction=validated_tx,
        fraud_probability=fraud_probability,
        anomaly_prediction=anomaly_prediction,
        anomaly_score=anomaly_raw_score,
    )

    decision = map_decision(risk_score)

    return {
        "risk_score": risk_score,
        "status": decision["status"],
        "fraud_probability": round(fraud_probability, 6),
        "anomaly_prediction": anomaly_prediction,
        "anomaly_detected": anomaly_prediction == -1,
        "anomaly_raw_score": round(anomaly_raw_score, 6),
        "anomaly_risk_score": anomaly_risk_score,
        "reasons": reasons,
        "recommended_action": decision["recommended_action"],
    }


# -------------------------------------------------------------------
# Demo test transactions
# -------------------------------------------------------------------
if __name__ == "__main__":
    test_transactions = [
        {
            "step": 1,
            "type": "PAYMENT",
            "amount": 50,
            "nameOrig": "C123",
            "oldbalanceOrg": 5000,
            "newbalanceOrig": 4950,
            "nameDest": "C456",
            "oldbalanceDest": 0,
            "newbalanceDest": 50,
            "isFlaggedFraud": 0,
        },
        {
            "step": 1,
            "type": "TRANSFER",
            "amount": 35063.63,
            "nameOrig": "C1364127192",
            "oldbalanceOrg": 35063.63,
            "newbalanceOrig": 0,
            "nameDest": "C1136419747",
            "oldbalanceDest": 0,
            "newbalanceDest": 0,
            "isFlaggedFraud": 0,
        },
        {
            "step": 1,
            "type": "TRANSFER",
            "amount": 1277212.77,
            "nameOrig": "C1334405552",
            "oldbalanceOrg": 1277212.77,
            "newbalanceOrig": 0,
            "nameDest": "C431687661",
            "oldbalanceDest": 0,
            "newbalanceDest": 0,
            "isFlaggedFraud": 0,
        },
        {
            "step": 50,
            "type": "CASH_OUT",
            "amount": 210000,
            "nameOrig": "C5555555555",
            "oldbalanceOrg": 250000,
            "newbalanceOrig": 40000,
            "nameDest": "C6666666666",
            "oldbalanceDest": 10000,
            "newbalanceDest": 220000,
            "isFlaggedFraud": 0,
        },
        {
            "step": 1,
            "type": "TRANSFER",
            "amount": 10000000,
            "nameOrig": "C9999999999",
            "oldbalanceOrg": 10000000,
            "newbalanceOrig": 0,
            "nameDest": "C8888888888",
            "oldbalanceDest": 0,
            "newbalanceDest": 10000000,
            "isFlaggedFraud": 1,
        },
        {
            "step": 5,
            "type": "PAYMENT",
            "amount": -100,
            "nameOrig": "C999000111",
            "oldbalanceOrg": 500,
            "newbalanceOrig": 600,
            "nameDest": "C888000222",
            "oldbalanceDest": 1000,
            "newbalanceDest": 900,
            "isFlaggedFraud": 0,
        },
    ]

    for i, tx in enumerate(test_transactions, start=1):
        print(f"\nTest Transaction {i}")
        try:
            processed = preprocess_transaction(validate_transaction(tx))
            print("Processed feature shape:", processed.shape)

            result = predict_transaction(tx)
            print(json.dumps(result, indent=2))
        except Exception as e:
            print(json.dumps({"error": str(e)}, indent=2))