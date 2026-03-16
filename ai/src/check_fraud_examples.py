import pandas as pd
import joblib
from pathlib import Path


# -----------------------------
# Load models
# -----------------------------
models_dir = Path("models")
xgb_model = joblib.load(models_dir / "fraud_paysim_xgboost_features.pkl")
iso_model = joblib.load(models_dir / "fraud_isolation_forest.pkl")


# -----------------------------
# Preprocessing function
# -----------------------------
def preprocess_transactions(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    # Feature engineering
    df["balance_diff_orig"] = df["oldbalanceOrg"] - df["newbalanceOrig"]
    df["balance_diff_dest"] = df["newbalanceDest"] - df["oldbalanceDest"]
    df["amount_balance_ratio"] = df["amount"] / (df["oldbalanceOrg"] + 1)
    df["is_large_amount"] = (df["amount"] > 200000).astype(int)
    df["is_zero_oldbalanceDest"] = (df["oldbalanceDest"] == 0).astype(int)
    df["is_zero_newbalanceDest"] = (df["newbalanceDest"] == 0).astype(int)

    # Drop raw ID columns
    for col in ["nameOrig", "nameDest"]:
        if col in df.columns:
            df = df.drop(columns=[col])

    # One-hot encode type
    df = pd.get_dummies(df, columns=["type"], drop_first=True)

    expected_columns = [
        "step",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "isFlaggedFraud",
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

    return df[expected_columns]


# -----------------------------
# Load real dataset sample
# -----------------------------
df = pd.read_csv("data/paysim.csv", nrows=50000)

# Keep original rows for display
original_df = df.copy()

# Preprocess
X = preprocess_transactions(df)

# Predictions
fraud_prob = xgb_model.predict_proba(X)[:, 1]
anomaly_pred = iso_model.predict(X)
anomaly_score = iso_model.decision_function(X)

# Attach outputs
original_df["fraud_probability"] = fraud_prob
original_df["anomaly_prediction"] = anomaly_pred
original_df["anomaly_raw_score"] = anomaly_score

# Possible FLAG candidates
flag_candidates = original_df[
    ((original_df["fraud_probability"] >= 0.30) & (original_df["fraud_probability"] < 0.70)) |
    (original_df["anomaly_prediction"] == -1) |
    (original_df["anomaly_raw_score"] < 0.05)
]

print("Total rows checked:", len(original_df))
print("Possible FLAG candidates found:", len(flag_candidates))

print("\nTop 20 candidate rows:")
print(
    flag_candidates[
        [
            "step", "type", "amount", "oldbalanceOrg", "newbalanceOrig",
            "oldbalanceDest", "newbalanceDest", "isFraud",
            "fraud_probability", "anomaly_prediction", "anomaly_raw_score"
        ]
    ]
    .head(20)
    .to_string(index=False)
)