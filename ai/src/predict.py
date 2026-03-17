import json
from pathlib import Path
from typing import Dict, Any, List

import joblib
import numpy as np
import pandas as pd

from src.load_dataset import preprocess_data

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
MODELS_DIR = Path("models")
OUTPUTS_DIR = Path("outputs")

CLASSIFIER_PATH = MODELS_DIR / "fraud_paysim_xgboost.pkl"
ANOMALY_MODEL_PATH = MODELS_DIR / "fraud_isolation_forest.pkl"

VALID_TRANSACTION_TYPES = {"CASH_IN", "CASH_OUT", "DEBIT", "PAYMENT", "TRANSFER"}


# -------------------------------------------------------------------
# Model loading
# -------------------------------------------------------------------
def load_models():
    """
    Load trained classifier and anomaly detector.
    """
    if not CLASSIFIER_PATH.exists():
        raise FileNotFoundError(f"Classifier model not found: {CLASSIFIER_PATH}")

    if not ANOMALY_MODEL_PATH.exists():
        raise FileNotFoundError(f"Anomaly model not found: {ANOMALY_MODEL_PATH}")

    classifier_model = joblib.load(CLASSIFIER_PATH)
    anomaly_model = joblib.load(ANOMALY_MODEL_PATH)

    return classifier_model, anomaly_model


classifier_model, anomaly_model = load_models()


# -------------------------------------------------------------------
# Validation
# -------------------------------------------------------------------
def validate_transaction(transaction: Dict[str, Any]) -> None:
    """
    Validate incoming transaction payload.
    """
    required_fields = [
        "step",
        "type",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "isFlaggedFraud",
    ]

    missing_fields = [field for field in required_fields if field not in transaction]
    if missing_fields:
        raise ValueError(f"Missing required fields: {missing_fields}")

    if not isinstance(transaction["type"], str):
        raise ValueError("Transaction type must be a string.")

    tx_type = transaction["type"].strip().upper()
    if tx_type not in VALID_TRANSACTION_TYPES:
        raise ValueError(
            f"Invalid transaction type: {transaction['type']}. "
            f"Valid types: {sorted(VALID_TRANSACTION_TYPES)}"
        )

    numeric_fields = [
        "step",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "isFlaggedFraud",
    ]

    for field in numeric_fields:
        if not isinstance(transaction[field], (int, float)):
            raise ValueError(f"{field} must be numeric.")

    if transaction["step"] < 0:
        raise ValueError("step cannot be negative.")
    if transaction["amount"] < 0:
        raise ValueError("amount cannot be negative.")
    if transaction["oldbalanceOrg"] < 0 or transaction["newbalanceOrig"] < 0:
        raise ValueError("origin balances cannot be negative.")
    if transaction["oldbalanceDest"] < 0 or transaction["newbalanceDest"] < 0:
        raise ValueError("destination balances cannot be negative.")
    if transaction["isFlaggedFraud"] not in [0, 1]:
        raise ValueError("isFlaggedFraud must be 0 or 1.")


# -------------------------------------------------------------------
# Preprocessing
# -------------------------------------------------------------------
def build_raw_transaction_df(transaction: Dict[str, Any]) -> pd.DataFrame:
    """
    Build a one-row raw dataframe with all expected raw columns.
    """
    tx = transaction.copy()
    tx["type"] = tx["type"].strip().upper()

    # Optional fields for compatibility with preprocessing pipeline
    tx.setdefault("nameOrig", "C_UNKNOWN_ORIG")
    tx.setdefault("nameDest", "C_UNKNOWN_DEST")

    df = pd.DataFrame([tx])

    # Ensure raw schema compatibility
    expected_raw_columns = [
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

    for col in expected_raw_columns:
        if col not in df.columns:
            if col == "type":
                df[col] = "PAYMENT"
            elif col in ["nameOrig", "nameDest"]:
                df[col] = "UNKNOWN"
            else:
                df[col] = 0

    return df[expected_raw_columns]


def preprocess_transaction(transaction: Dict[str, Any]) -> pd.DataFrame:
    """
    Preprocess a single transaction using the same shared preprocessing
    logic as training.
    """
    raw_df = build_raw_transaction_df(transaction)

    # Add dummy isFraud column because shared preprocessing pipeline expects
    # training-like schema. It will be dropped later before prediction.
    raw_df["isFraud"] = 0

    processed_df = preprocess_data(raw_df)

    # Drop target columns for inference
    cols_to_drop = [col for col in ["isFraud", "isFlaggedFraud"] if col in processed_df.columns]
    processed_df = processed_df.drop(columns=cols_to_drop)

    # Defensive conversion
    bool_cols = processed_df.select_dtypes(include=["bool"]).columns.tolist()
    if bool_cols:
        processed_df[bool_cols] = processed_df[bool_cols].astype(int)

    return processed_df


def align_features_for_model(processed_df: pd.DataFrame, model) -> pd.DataFrame:
    """
    Align dataframe columns to exactly match model training features.
    """
    if not hasattr(model, "feature_names_in_"):
        return processed_df

    expected_features = list(model.feature_names_in_)
    aligned_df = processed_df.copy()

    for col in expected_features:
        if col not in aligned_df.columns:
            aligned_df[col] = 0

    aligned_df = aligned_df[expected_features]

    return aligned_df


# -------------------------------------------------------------------
# Scoring helpers
# -------------------------------------------------------------------
def normalize_anomaly_risk(anomaly_score: float, reference_min: float = -0.06, reference_max: float = 0.29) -> float:
    """
    Convert raw Isolation Forest decision_function score to a rough
    0-100 anomaly intensity scale.
    Lower raw score => higher anomaly risk.
    """
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
    Build human-readable reasons for risk decision.
    """
    reasons = []

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

    tx_type = transaction["type"].strip().upper()

    if tx_type in {"TRANSFER", "CASH_OUT"} and transaction["amount"] >= 50000:
        reasons.append("High-value transfer or cash-out transaction")

    if transaction["oldbalanceOrg"] > 0 and transaction["newbalanceOrig"] == 0:
        reasons.append("Source account balance drained to zero")

    if transaction["oldbalanceDest"] == 0 and transaction["newbalanceDest"] == 0 and tx_type == "TRANSFER":
        reasons.append("Destination balance pattern appears unusual for transfer")

    if transaction["isFlaggedFraud"] == 1:
        reasons.append("Transaction was flagged by upstream rule-based system")

    return reasons


def compute_risk_score(
    transaction: Dict[str, Any],
    fraud_probability: float,
    anomaly_prediction: int,
    anomaly_score: float,
) -> int:
    """
    Compute final risk score from classifier, anomaly model, and business rules.
    """
    risk_score = int(round(fraud_probability * 100))

    # anomaly adjustments
    if anomaly_prediction == -1:
        risk_score = max(risk_score, 55)
    elif anomaly_score < 0.02:
        risk_score = max(risk_score, 45)

    # transaction-type safeguard
    tx_type = transaction["type"].strip().upper()
    if tx_type in {"TRANSFER", "CASH_OUT"} and transaction["amount"] >= 50000:
        risk_score = max(risk_score, 40)

    # full balance drain safeguard
    if transaction["oldbalanceOrg"] > 0 and transaction["newbalanceOrig"] == 0:
        risk_score = max(risk_score, 50)

    # upstream system signal
    if transaction["isFlaggedFraud"] == 1:
        risk_score = max(risk_score, 85)

    return min(risk_score, 100)


def map_decision(risk_score: int) -> Dict[str, str]:
    """
    Map risk score to decision status and recommended action.
    """
    if risk_score >= 70:
        return {
            "status": "BLOCK",
            "recommended_action": "Block transaction and trigger security review",
        }
    if risk_score >= 40:
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
    Predict transaction fraud risk using:
    - supervised classifier
    - anomaly detector
    - rule-based risk safeguards
    """
    validate_transaction(transaction)

    processed_df = preprocess_transaction(transaction)

    classifier_input = align_features_for_model(processed_df, classifier_model)
    anomaly_input = align_features_for_model(processed_df, anomaly_model)

    fraud_probability = float(classifier_model.predict_proba(classifier_input)[0][1])

    anomaly_prediction = int(anomaly_model.predict(anomaly_input)[0])   # -1 anomaly, 1 normal
    anomaly_raw_score = float(anomaly_model.decision_function(anomaly_input)[0])
    anomaly_risk_score = normalize_anomaly_risk(anomaly_raw_score)

    risk_score = compute_risk_score(
        transaction=transaction,
        fraud_probability=fraud_probability,
        anomaly_prediction=anomaly_prediction,
        anomaly_score=anomaly_raw_score,
    )

    reasons = derive_reasons(
        transaction=transaction,
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
            processed = preprocess_transaction(tx)
            print("Processed feature shape:", processed.shape)

            result = predict_transaction(tx)
            print(json.dumps(result, indent=2))
        except ValueError as e:
            print(json.dumps({"error": str(e)}, indent=2))