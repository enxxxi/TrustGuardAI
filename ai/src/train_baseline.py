import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    average_precision_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split

from load_dataset import load_data, preprocess_data


# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
DATA_PATH = "data/paysim.csv"
NROWS = 200000
TEST_SIZE = 0.2
RANDOM_STATE = 42

MODEL_DIR = Path("models")
OUTPUT_DIR = Path("outputs")

MODEL_PATH = MODEL_DIR / "fraud_paysim_baseline.pkl"
METRICS_PATH = OUTPUT_DIR / "baseline_metrics.json"
FEATURE_IMPORTANCE_PATH = OUTPUT_DIR / "baseline_feature_importance.csv"


# -------------------------------------------------------------------
# Data preparation
# -------------------------------------------------------------------
def prepare_features_and_target(df: pd.DataFrame):
    """
    Prepare model features and target.
    """
    target_col = "isFraud"

    cols_to_drop = [target_col]

    # Drop leakage-prone / rule-generated field
    if "isFlaggedFraud" in df.columns:
        cols_to_drop.append("isFlaggedFraud")

    X = df.drop(columns=cols_to_drop)
    y = df[target_col].astype(int)

    return X, y


# -------------------------------------------------------------------
# Model building
# -------------------------------------------------------------------
def build_model() -> RandomForestClassifier:
    """
    Build baseline RandomForest fraud classifier.
    """
    model = RandomForestClassifier(
        n_estimators=200,
        max_depth=12,
        min_samples_split=10,
        min_samples_leaf=4,
        class_weight="balanced",
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )
    return model


# -------------------------------------------------------------------
# Evaluation
# -------------------------------------------------------------------
def evaluate_model(model, X_test, y_test):
    """
    Evaluate model using fraud-relevant metrics.
    """
    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)[:, 1]

    metrics = {
        "roc_auc": float(roc_auc_score(y_test, y_prob)),
        "pr_auc": float(average_precision_score(y_test, y_prob)),
        "precision": float(precision_score(y_test, y_pred, zero_division=0)),
        "recall": float(recall_score(y_test, y_pred, zero_division=0)),
        "f1_score": float(f1_score(y_test, y_pred, zero_division=0)),
        "confusion_matrix": confusion_matrix(y_test, y_pred).tolist(),
        "classification_report": classification_report(
            y_test,
            y_pred,
            zero_division=0,
            output_dict=True,
        ),
    }

    return metrics, y_pred, y_prob


def print_metrics(metrics: dict):
    """
    Print metrics in a readable format.
    """
    print("\n" + "=" * 70)
    print("BASELINE MODEL EVALUATION")
    print("=" * 70)

    print(f"ROC-AUC   : {metrics['roc_auc']:.6f}")
    print(f"PR-AUC    : {metrics['pr_auc']:.6f}")
    print(f"Precision : {metrics['precision']:.6f}")
    print(f"Recall    : {metrics['recall']:.6f}")
    print(f"F1-Score  : {metrics['f1_score']:.6f}")

    print("\nConfusion Matrix:")
    print(metrics["confusion_matrix"])

    print("\nClassification Report:")
    report_df = pd.DataFrame(metrics["classification_report"]).transpose()
    print(report_df)


# -------------------------------------------------------------------
# Feature importance
# -------------------------------------------------------------------
def save_feature_importance(model, feature_names, output_path=FEATURE_IMPORTANCE_PATH):
    """
    Save RandomForest feature importances.
    """
    if not hasattr(model, "feature_importances_"):
        print("Model does not support feature importance.")
        return

    importance_df = pd.DataFrame(
        {
            "feature": feature_names,
            "importance": model.feature_importances_,
        }
    ).sort_values(by="importance", ascending=False)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    importance_df.to_csv(output_path, index=False)

    print(f"\nFeature importance saved to: {output_path}")
    print("\nTop 15 important features:")
    print(importance_df.head(15))


# -------------------------------------------------------------------
# Saving artifacts
# -------------------------------------------------------------------
def save_artifacts(model, metrics):
    """
    Save model and evaluation outputs.
    """
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    joblib.dump(model, MODEL_PATH)

    with open(METRICS_PATH, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=4)

    print(f"\nModel saved to: {MODEL_PATH}")
    print(f"Metrics saved to: {METRICS_PATH}")


# -------------------------------------------------------------------
# Training pipeline
# -------------------------------------------------------------------
def train_baseline_model():
    """
    End-to-end baseline model training pipeline.
    """
    print("Loading PaySim dataset...")
    raw_df = load_data(path=DATA_PATH, nrows=NROWS)
    print(f"Initial raw shape: {raw_df.shape}")

    print("\nApplying preprocessing pipeline...")
    processed_df = preprocess_data(raw_df)
    print(f"Processed shape: {processed_df.shape}")

    X, y = prepare_features_and_target(processed_df)

    print("\nFeature matrix shape:", X.shape)
    print("Target distribution:")
    print(y.value_counts())

    print("\nTarget percentage:")
    print(y.value_counts(normalize=True))

    print("\nSplitting train/test data...")
    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=y,
    )

    print("X_train shape:", X_train.shape)
    print("X_test shape :", X_test.shape)
    print("y_train shape:", y_train.shape)
    print("y_test shape :", y_test.shape)

    print("\nTraining RandomForest baseline model...")
    model = build_model()
    model.fit(X_train, y_train)

    print("Evaluating model...")
    metrics, _, _ = evaluate_model(model, X_test, y_test)
    print_metrics(metrics)

    save_artifacts(model, metrics)
    save_feature_importance(model, X.columns)

    return model, metrics


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
if __name__ == "__main__":
    try:
        train_baseline_model()
    except FileNotFoundError:
        print(f"Error: Dataset file not found at {DATA_PATH}")
    except Exception as e:
        print(f"Error during baseline model training: {e}")