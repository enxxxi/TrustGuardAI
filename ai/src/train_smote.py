import json
from pathlib import Path

import joblib
import pandas as pd
from imblearn.over_sampling import SMOTE
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

MODEL_PATH = MODEL_DIR / "fraud_paysim_smote.pkl"
METRICS_PATH = OUTPUT_DIR / "smote_metrics.json"
FEATURE_IMPORTANCE_PATH = OUTPUT_DIR / "smote_feature_importance.csv"
TRAINING_SUMMARY_PATH = OUTPUT_DIR / "smote_training_summary.json"


# -------------------------------------------------------------------
# Data preparation
# -------------------------------------------------------------------
def prepare_features_and_target(df: pd.DataFrame):
    """
    Prepare model features and target.
    """
    target_col = "isFraud"
    cols_to_drop = [target_col]

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
    Build RandomForest classifier for SMOTE-resampled training.
    """
    model = RandomForestClassifier(
        n_estimators=250,
        max_depth=14,
        min_samples_split=8,
        min_samples_leaf=3,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )
    return model


# -------------------------------------------------------------------
# Evaluation
# -------------------------------------------------------------------
def evaluate_model(model, X_test, y_test):
    """
    Evaluate model using fraud-focused metrics.
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
    Print evaluation metrics clearly.
    """
    print("\n" + "=" * 70)
    print("SMOTE MODEL EVALUATION")
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
    Save model feature importances.
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
def save_artifacts(model, metrics, training_summary):
    """
    Save trained model, metrics, and training summary.
    """
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    joblib.dump(model, MODEL_PATH)

    with open(METRICS_PATH, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=4)

    with open(TRAINING_SUMMARY_PATH, "w", encoding="utf-8") as f:
        json.dump(training_summary, f, indent=4)

    print(f"\nModel saved to: {MODEL_PATH}")
    print(f"Metrics saved to: {METRICS_PATH}")
    print(f"Training summary saved to: {TRAINING_SUMMARY_PATH}")


# -------------------------------------------------------------------
# Training pipeline
# -------------------------------------------------------------------
def train_smote_model():
    """
    End-to-end training pipeline using SMOTE.
    """
    print("Loading PaySim dataset...")
    raw_df = load_data(path=DATA_PATH, nrows=NROWS)
    print(f"Initial raw shape: {raw_df.shape}")

    print("\nApplying preprocessing pipeline...")
    processed_df = preprocess_data(raw_df)
    print(f"Processed shape: {processed_df.shape}")

    X, y = prepare_features_and_target(processed_df)

    print("\nFeature matrix shape:", X.shape)
    print("Original fraud distribution:")
    print(y.value_counts())
    print("\nOriginal fraud percentage:")
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
    print("y_train distribution before SMOTE:")
    print(y_train.value_counts())

    print("\nApplying SMOTE to training data...")
    smote = SMOTE(random_state=RANDOM_STATE)
    X_train_resampled, y_train_resampled = smote.fit_resample(X_train, y_train)

    print("Resampled training distribution:")
    print(pd.Series(y_train_resampled).value_counts())

    print("\nTraining RandomForest model with SMOTE...")
    model = build_model()
    model.fit(X_train_resampled, y_train_resampled)

    print("Evaluating model...")
    metrics, _, _ = evaluate_model(model, X_test, y_test)
    print_metrics(metrics)

    training_summary = {
        "raw_shape": list(raw_df.shape),
        "processed_shape": list(processed_df.shape),
        "feature_shape": list(X.shape),
        "train_shape": list(X_train.shape),
        "test_shape": list(X_test.shape),
        "train_distribution_before_smote": {
            str(k): int(v) for k, v in y_train.value_counts().to_dict().items()
        },
        "train_distribution_after_smote": {
            str(k): int(v)
            for k, v in pd.Series(y_train_resampled).value_counts().to_dict().items()
        },
        "smote_applied_only_to_training_set": True,
    }

    save_artifacts(model, metrics, training_summary)
    save_feature_importance(model, X.columns)

    return model, metrics, training_summary


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
if __name__ == "__main__":
    try:
        train_smote_model()
    except FileNotFoundError:
        print(f"Error: Dataset file not found at {DATA_PATH}")
    except Exception as e:
        print(f"Error during SMOTE model training: {e}")