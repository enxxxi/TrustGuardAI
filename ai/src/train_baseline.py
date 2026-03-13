import pandas as pd
from sklearn.datasets import make_classification
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score
import joblib
from pathlib import Path

print("Generating synthetic fraud dataset...")

X, y = make_classification(
    n_samples=10000,
    n_features=20,
    n_informative=10,
    n_redundant=5,
    weights=[0.98, 0.02],
    random_state=42
)

X = pd.DataFrame(X)
y = pd.Series(y)

print("Splitting dataset...")

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

print("Training model...")

model = RandomForestClassifier(
    n_estimators=100,
    class_weight="balanced",
    random_state=42
)

model.fit(X_train, y_train)

print("Evaluating model...")

y_pred = model.predict(X_test)
y_prob = model.predict_proba(X_test)[:, 1]

print(classification_report(y_test, y_pred))
print("ROC-AUC:", roc_auc_score(y_test, y_prob))

models_dir = Path(__file__).resolve().parent.parent / "models"
models_dir.mkdir(parents=True, exist_ok=True)

model_path = models_dir / "fraud_baseline.pkl"
joblib.dump(model, model_path)

print(f"Model saved to {model_path}")