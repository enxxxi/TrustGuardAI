import pandas as pd
import joblib
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, roc_auc_score, confusion_matrix
from xgboost import XGBClassifier

print("Loading PaySim dataset...")

df = pd.read_csv("data/paysim.csv", nrows=200000)

print("Initial shape:", df.shape)

# Drop ID columns
df = df.drop(["nameOrig", "nameDest"], axis=1)

# One-hot encode transaction type
df = pd.get_dummies(df, columns=["type"], drop_first=True)

# Features and target
X = df.drop(["isFraud", "isFlaggedFraud"], axis=1)
y = df["isFraud"]

print("Processed feature shape:", X.shape)
print("Feature columns:")
print(X.columns.tolist())

print("Fraud distribution:")
print(y.value_counts())

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# Handle imbalance using scale_pos_weight
scale_pos_weight = (y_train == 0).sum() / (y_train == 1).sum()
print("scale_pos_weight:", scale_pos_weight)

print("Training XGBoost model...")

model = XGBClassifier(
    n_estimators=200,
    max_depth=6,
    learning_rate=0.1,
    subsample=0.8,
    colsample_bytree=0.8,
    scale_pos_weight=scale_pos_weight,
    eval_metric="logloss",
    random_state=42,
    n_jobs=-1
)

model.fit(X_train, y_train)

print("Evaluating model...")

y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

print(classification_report(y_test, y_pred))
print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))
print("ROC-AUC:", roc_auc_score(y_test, y_prob))

models_dir = Path("models")
models_dir.mkdir(parents=True, exist_ok=True)

model_path = models_dir / "fraud_paysim_xgboost.pkl"
joblib.dump(model, model_path)

print(f"Model saved to {model_path}")