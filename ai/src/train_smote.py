import pandas as pd
import joblib
from pathlib import Path
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score, confusion_matrix
from imblearn.over_sampling import SMOTE

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

print("Original fraud distribution:")
print(y.value_counts())

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

print("Applying SMOTE to training data...")
smote = SMOTE(random_state=42)
X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)

print("Resampled training distribution:")
print(pd.Series(y_train_resampled).value_counts())

print("Training RandomForest model with SMOTE...")

model = RandomForestClassifier(
    n_estimators=100,
    random_state=42,
    n_jobs=-1
)

model.fit(X_train_resampled, y_train_resampled)

print("Evaluating model...")

y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

print(classification_report(y_test, y_pred))
print("Confusion Matrix:")
print(confusion_matrix(y_test, y_pred))
print("ROC-AUC:", roc_auc_score(y_test, y_prob))

models_dir = Path("models")
models_dir.mkdir(parents=True, exist_ok=True)

model_path = models_dir / "fraud_paysim_smote.pkl"
joblib.dump(model, model_path)

print(f"Model saved to {model_path}")