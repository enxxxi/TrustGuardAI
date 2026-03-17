import pandas as pd
import joblib
from pathlib import Path
from sklearn.ensemble import IsolationForest

print("Loading dataset...")

df = pd.read_csv("data/paysim.csv", nrows=200000)

# Feature engineering (must match predict.py)
df["balance_diff_orig"] = df["oldbalanceOrg"] - df["newbalanceOrig"]
df["balance_diff_dest"] = df["newbalanceDest"] - df["oldbalanceDest"]
df["amount_balance_ratio"] = df["amount"] / (df["oldbalanceOrg"] + 1)
df["is_large_amount"] = (df["amount"] > 200000).astype(int)
df["is_zero_oldbalanceDest"] = (df["oldbalanceDest"] == 0).astype(int)
df["is_zero_newbalanceDest"] = (df["newbalanceDest"] == 0).astype(int)

# Drop ID columns
df = df.drop(["nameOrig", "nameDest"], axis=1)

# One-hot encode transaction type
df = pd.get_dummies(df, columns=["type"], drop_first=True)

# Use the same feature set structure
X = df.drop(["isFraud", "isFlaggedFraud"], axis=1)

print("Feature columns:")
print(X.columns.tolist())
print("Feature shape:", X.shape)

print("Training Isolation Forest...")

model = IsolationForest(
    n_estimators=200,
    contamination=0.001,
    random_state=42,
    n_jobs=-1
)

model.fit(X)

train_pred = model.predict(X)
train_scores = model.decision_function(X)

print("Prediction distribution on training data:")
print(pd.Series(train_pred).value_counts())

print("Decision function summary:")
print(pd.Series(train_scores).describe())

df_eval = pd.DataFrame({
    "isFraud": df["isFraud"],
    "anomaly_pred": train_pred
})

print("Fraud vs anomaly crosstab:")
print(pd.crosstab(df_eval["isFraud"], df_eval["anomaly_pred"]))

models_dir = Path("models")
models_dir.mkdir(parents=True, exist_ok=True)

model_path = models_dir / "fraud_isolation_forest.pkl"
joblib.dump(model, model_path)

print("Isolation Forest model saved:", model_path)