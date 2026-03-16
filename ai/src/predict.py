import joblib
import pandas as pd
from pathlib import Path

# -----------------------------
# Load trained models
# -----------------------------
models_dir = Path("models")

xgb_model = joblib.load(models_dir / "fraud_paysim_xgboost_features.pkl")
iso_model = joblib.load(models_dir / "fraud_isolation_forest.pkl")


# -----------------------------
# Validation function
# -----------------------------
def validate_transaction(transaction: dict) -> None:
    required_fields = [
        "step",
        "type",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "isFlaggedFraud"
    ]

    for field in required_fields:
        if field not in transaction:
            raise ValueError(f"Missing required field: {field}")

    if not isinstance(transaction["type"], str):
        raise ValueError("Transaction type must be a string")

    numeric_fields = [
        "step",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "isFlaggedFraud"
    ]

    for field in numeric_fields:
        if not isinstance(transaction[field], (int, float)):
            raise ValueError(f"{field} must be numeric")

    if transaction["step"] < 0:
        raise ValueError("step cannot be negative")

    if transaction["amount"] < 0:
        raise ValueError("amount cannot be negative")

    if transaction["oldbalanceOrg"] < 0 or transaction["newbalanceOrig"] < 0:
        raise ValueError("origin balances cannot be negative")

    if transaction["oldbalanceDest"] < 0 or transaction["newbalanceDest"] < 0:
        raise ValueError("destination balances cannot be negative")

    valid_types = {"CASH_IN", "CASH_OUT", "DEBIT", "PAYMENT", "TRANSFER"}
    if transaction["type"] not in valid_types:
        raise ValueError(f"Invalid transaction type: {transaction['type']}")

    if transaction["isFlaggedFraud"] not in [0, 1]:
        raise ValueError("isFlaggedFraud must be 0 or 1")


# -----------------------------
# Preprocessing function
# -----------------------------
def preprocess_transaction(transaction: dict) -> pd.DataFrame:
    df = pd.DataFrame([transaction])

    # Feature engineering
    df["balance_diff_orig"] = df["oldbalanceOrg"] - df["newbalanceOrig"]
    df["balance_diff_dest"] = df["newbalanceDest"] - df["oldbalanceDest"]
    df["amount_balance_ratio"] = df["amount"] / (df["oldbalanceOrg"] + 1)
    df["is_large_amount"] = (df["amount"] > 200000).astype(int)
    df["is_zero_oldbalanceDest"] = (df["oldbalanceDest"] == 0).astype(int)
    df["is_zero_newbalanceDest"] = (df["newbalanceDest"] == 0).astype(int)

    # Manual transaction type encoding
    tx_type = df["type"].iloc[0]
    df["type_CASH_OUT"] = 1 if tx_type == "CASH_OUT" else 0
    df["type_DEBIT"] = 1 if tx_type == "DEBIT" else 0
    df["type_PAYMENT"] = 1 if tx_type == "PAYMENT" else 0
    df["type_TRANSFER"] = 1 if tx_type == "TRANSFER" else 0

    # Drop raw non-model columns
    for col in ["nameOrig", "nameDest", "type", "isFlaggedFraud"]:
        if col in df.columns:
            df = df.drop(columns=[col])

    # Must match training exactly
    expected_columns = [
        "step",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "balance_diff_orig",
        "balance_diff_dest",
        "amount_balance_ratio",
        "is_large_amount",
        "is_zero_oldbalanceDest",
        "is_zero_newbalanceDest",
        "type_CASH_OUT",
        "type_DEBIT",
        "type_PAYMENT",
        "type_TRANSFER"
    ]

    for col in expected_columns:
        if col not in df.columns:
            df[col] = 0

    df = df[expected_columns]
    return df


# -----------------------------
# Prediction function
# -----------------------------
def predict_transaction(transaction: dict) -> dict:
    validate_transaction(transaction)
    processed = preprocess_transaction(transaction)

    # Safety check for feature alignment
    if hasattr(xgb_model, "feature_names_in_"):
        expected = list(xgb_model.feature_names_in_)
        actual = list(processed.columns)
        if actual != expected:
            raise ValueError(f"Feature mismatch. Expected {expected}, got {actual}")

    # XGBoost fraud probability
    fraud_probability = float(xgb_model.predict_proba(processed)[0][1])

    # Isolation Forest: -1 = anomaly, 1 = normal
    anomaly_prediction = int(iso_model.predict(processed)[0])
    anomaly_raw_score = float(iso_model.decision_function(processed)[0])

    # Base risk score from classifier
    risk_score = int(fraud_probability * 100)

    # Secondary anomaly adjustment
    if anomaly_prediction == -1:
        risk_score = max(risk_score, 55)
    elif anomaly_raw_score < 0.02:
        risk_score = max(risk_score, 45)

    # Reasons
    reasons = []

    if fraud_probability >= 0.95:
        reasons.append("Very high fraud probability from classifier")
    elif fraud_probability >= 0.70:
        reasons.append("High fraud probability from classifier")
    elif fraud_probability >= 0.40:
        reasons.append("Moderate fraud probability from classifier")
    else:
        reasons.append("Low fraud probability from classifier")

    if anomaly_prediction == -1:
        reasons.append("Anomalous transaction pattern detected")
    elif anomaly_raw_score < 0.02:
        reasons.append("Suspicious transaction pattern detected from anomaly score")

    # Rule-based safeguard for large risky transaction types
    if transaction["type"] in {"TRANSFER", "CASH_OUT"} and transaction["amount"] >= 200000:
        risk_score = max(risk_score, 40)
        reasons.append("High-value transfer or cash-out transaction")

    # Rule-based upstream flag
    if transaction["isFlaggedFraud"] == 1:
        reasons.append("Transaction was flagged by upstream rule-based system")
        risk_score = max(risk_score, 85)

    risk_score = min(risk_score, 100)

    # Final decision
    if risk_score >= 70:
        status = "BLOCK"
        recommended_action = "Block transaction and trigger security review"
    elif risk_score >= 40:
        status = "FLAG"
        recommended_action = "Flag transaction for review or OTP verification"
    else:
        status = "APPROVE"
        recommended_action = "Allow transaction"

    return {
        "risk_score": risk_score,
        "status": status,
        "fraud_probability": round(fraud_probability, 4),
        "anomaly_prediction": anomaly_prediction,
        "anomaly_detected": anomaly_prediction == -1,
        "anomaly_raw_score": round(anomaly_raw_score, 6),
        "reasons": reasons,
        "recommended_action": recommended_action
    }


# -----------------------------
# Example test transactions
# -----------------------------
if __name__ == "__main__":
    test_transactions = [
        # Test 1 - normal
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
            "isFlaggedFraud": 0
        },

        # Test 2 - fraud-like transfer
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
            "isFlaggedFraud": 0
        },

        # Test 3 - fraud-like transfer
        {
            "step": 1,
            "type": "TRANSFER",
            "amount": 181,
            "nameOrig": "C1305486145",
            "oldbalanceOrg": 181,
            "newbalanceOrig": 0,
            "nameDest": "C553264065",
            "oldbalanceDest": 0,
            "newbalanceDest": 0,
            "isFlaggedFraud": 0
        },

        # Test 4 - highly suspicious transfer
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
            "isFlaggedFraud": 0
        },

        # Test 5 - extreme anomaly
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
            "isFlaggedFraud": 1
        },

        # Test 6 - cash out case
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
            "isFlaggedFraud": 0
        },

        # Test 7 - smaller transfer
        {
            "step": 1,
            "type": "TRANSFER",
            "amount": 5000,
            "nameOrig": "C7777777777",
            "oldbalanceOrg": 5000,
            "newbalanceOrig": 0,
            "nameDest": "C1111111111",
            "oldbalanceDest": 0,
            "newbalanceDest": 0,
            "isFlaggedFraud": 0
        },

        # Test 8 - debit
        {
            "step": 20,
            "type": "DEBIT",
            "amount": 8000,
            "nameOrig": "C2222222222",
            "oldbalanceOrg": 12000,
            "newbalanceOrig": 4000,
            "nameDest": "C3333333333",
            "oldbalanceDest": 5000,
            "newbalanceDest": 13000,
            "isFlaggedFraud": 0
        },

        # Test 9 - normal-looking transfer
        {
            "step": 30,
            "type": "TRANSFER",
            "amount": 12000,
            "nameOrig": "C4444444444",
            "oldbalanceOrg": 15000,
            "newbalanceOrig": 3000,
            "nameDest": "C5555555555",
            "oldbalanceDest": 2000,
            "newbalanceDest": 14000,
            "isFlaggedFraud": 0
        },

        # Test 10 - anomaly-heavy but not max fraud
        {
            "step": 1,
            "type": "CASH_OUT",
            "amount": 9500000,
            "nameOrig": "C1010101010",
            "oldbalanceOrg": 9600000,
            "newbalanceOrig": 100000,
            "nameDest": "C2020202020",
            "oldbalanceDest": 500,
            "newbalanceDest": 9500500,
            "isFlaggedFraud": 0
        },

        # Test 11 - invalid transaction (negative amount)
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
            "isFlaggedFraud": 0
        },

        # Test 12 - unusual balance pattern
        {
            "step": 1,
            "type": "TRANSFER",
            "amount": 1429051.47,
            "nameOrig": "C1212121212",
            "oldbalanceOrg": 0.00,
            "newbalanceOrig": 0.00,
            "nameDest": "C3434343434",
            "oldbalanceDest": 2041543.62,
            "newbalanceDest": 19169204.93,
            "isFlaggedFraud": 0
        },

        # Test 13 - CASH_IN baseline category support
        {
            "step": 10,
            "type": "CASH_IN",
            "amount": 3000,
            "nameOrig": "C5656565656",
            "oldbalanceOrg": 0,
            "newbalanceOrig": 3000,
            "nameDest": "C7878787878",
            "oldbalanceDest": 10000,
            "newbalanceDest": 7000,
            "isFlaggedFraud": 0
        }
    ]

    for i, tx in enumerate(test_transactions):
        print(f"\nTest Transaction {i+1}")

        if i == 5:  # Transaction 6
            print("Processed features for Transaction 6:")
            print(preprocess_transaction(tx).to_string(index=False))

        try:
            result = predict_transaction(tx)
            print(result)
        except ValueError as e:
            print({"error": str(e)})