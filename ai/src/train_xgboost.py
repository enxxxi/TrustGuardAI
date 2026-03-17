import json
from pathlib import Path
from typing import Dict, Tuple

import joblib
import pandas as pd
from sklearn.metrics import (
    average_precision_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_recall_curve,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier

try:
    from src.load_dataset import load_data, preprocess_data
except ModuleNotFoundError:
    from load_dataset import load_data, preprocess_data


# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
DATA_PATH = "data/paysim.csv"
NROWS = 200000
TEST_SIZE = 0.2
RANDOM_STATE = 42
DEFAULT_THRESHOLD = 0.5

MODEL_DIR = Path("models")
OUTPUT_DIR = Path("outputs")

MODEL_PATH = MODEL_DIR / "fraud_paysim_xgboost.pkl"
METRICS_PATH = OUTPUT_DIR / "xgboost_metrics.json"
FEATURE_IMPORTANCE_PATH = OUTPUT_DIR / "xgboost_feature_importance.csv"
TRAINING_SUMMARY_PATH = OUTPUT_DIR / "xgboost_training_summary.json"


# -------------------------------------------------------------------
# Data preparation
# -------------------------------------------------------------------
def prepare_features_and_target(df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series]:
    """
    Prepare model features and target.
    """
    target_col = "isFraud"
    if target_col not in df.columns:
        raise ValueError(f"Target column '{target_col}' not found.")

    cols_to_drop = [target_col]

    if "isFlaggedFraud" in df.columns:
        cols_to_drop.append("isFlaggedFraud")

    X = df.drop(columns=cols_to_drop)
    y = df[target_col].astype(int)

    return X, y


# -------------------------------------------------------------------
# Model building
# -------------------------------------------------------------------
def build_model(scale_pos_weight: float) -> XGBClassifier:
    """
    Build XGBoost fraud classifier.
    """
    return XGBClassifier(
        n_estimators=300,
        max_depth=6,
        learning_rate=0.05,
        subsample=0.8,
        colsample_bytree=0.8,
        min_child_weight=3,
        gamma=0.0,
        reg_alpha=0.0,
        reg_lambda=1.0,
        scale_pos_weight=scale_pos_weight,
        objective="binary:logistic",
        eval_metric="logloss",
        random_state=RANDOM_STATE,
        n_jobs=-1,
        tree_method="hist",
    )


# -------------------------------------------------------------------
# Threshold utilities
# -------------------------------------------------------------------
def predict_with_threshold(y_prob, threshold: float):
    return (y_prob >= threshold).astype(int)


def find_best_f1_threshold(y_true, y_prob) -> Dict[str, float]:
    """
    Search thresholds from PR curve and return the best F1 threshold.
    """
    precision, recall, thresholds = precision_recall_curve(y_true, y_prob)

    best_threshold = DEFAULT_THRESHOLD
    best_f1 = -1.0
    best_precision = 0.0
    best_recall = 0.0

    for i, threshold in enumerate(thresholds):
        p = precision[i]
        r = recall[i]
        f1 = 0.0 if (p + r) == 0 else 2 * p * r / (p + r)

        if f1 > best_f1:
            best_f1 = f1
            best_threshold = float(threshold)
            best_precision = float(p)
            best_recall = float(r)

    return {
        "best_f1_threshold": round(best_threshold, 6),
        "best_f1_from_pr_curve": round(best_f1, 6),
        "precision_at_best_f1": round(best_precision, 6),
        "recall_at_best_f1": round(best_recall, 6),
    }


# -------------------------------------------------------------------
# Evaluation
# -------------------------------------------------------------------
def evaluate_model(model, X_test, y_test, threshold: float = DEFAULT_THRESHOLD):
    """
    Evaluate model using fraud-relevant metrics.
    """
    y_prob = model.predict_proba(X_test)[:, 1]
    y_pred = predict_with_threshold(y_prob, threshold)

    metrics = {
        "threshold": float(threshold),
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

    metrics.update(find_best_f1_threshold(y_test, y_prob))
    return metrics, y_pred, y_prob


def print_metrics(metrics: dict):
    """
    Print evaluation metrics clearly.
    """
    print("\n" + "=" * 70)
    print("XGBOOST MODEL EVALUATION")
    print("=" * 70)

    print(f"Threshold used        : {metrics['threshold']:.6f}")
    print(f"ROC-AUC               : {metrics['roc_auc']:.6f}")
    print(f"PR-AUC                : {metrics['pr_auc']:.6f}")
    print(f"Precision             : {metrics['precision']:.6f}")
    print(f"Recall                : {metrics['recall']:.6f}")
    print(f"F1-Score              : {metrics['f1_score']:.6f}")
    print(f"Best F1 threshold     : {metrics['best_f1_threshold']:.6f}")
    print(f"Best F1 from PR curve : {metrics['best_f1_from_pr_curve']:.6f}")
    print(f"Precision @ best F1   : {metrics['precision_at_best_f1']:.6f}")
    print(f"Recall @ best F1      : {metrics['recall_at_best_f1']:.6f}")

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
    Save XGBoost feature importances.
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
    print(importance_df.head(15).to_string(index=False))


# -------------------------------------------------------------------
# Saving artifacts
# -------------------------------------------------------------------
def save_artifacts(model, metrics, training_summary):
    """
    Save model, metrics, and training summary.
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
def train_xgboost_model():
    """
    End-to-end XGBoost training pipeline.
    """
    print("Loading PaySim dataset...")
    raw_df = load_data(path=DATA_PATH, nrows=NROWS)
    print(f"Initial raw shape: {raw_df.shape}")

    print("\nApplying preprocessing pipeline...")
    processed_df = preprocess_data(raw_df)
    print(f"Processed shape: {processed_df.shape}")

    X, y = prepare_features_and_target(processed_df)

    print("\nFeature matrix shape:", X.shape)
    print("Fraud distribution:")
    print(y.value_counts())

    print("\nFraud percentage:")
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

    print("\nTrain class distribution:")
    print(y_train.value_counts())

    print("\nTest class distribution:")
    print(y_test.value_counts())

    negative_count = int((y_train == 0).sum())
    positive_count = int((y_train == 1).sum())
    scale_pos_weight = negative_count / max(positive_count, 1)

    print(f"\nscale_pos_weight: {scale_pos_weight:.6f}")

    print("\nTraining XGBoost model...")
    model = build_model(scale_pos_weight=scale_pos_weight)
    model.fit(X_train, y_train)

    print("Evaluating model...")
    metrics, _, _ = evaluate_model(model, X_test, y_test, threshold=DEFAULT_THRESHOLD)

    metrics["model_name"] = "XGBClassifier"
    metrics["dataset_rows"] = int(len(raw_df))
    metrics["feature_count"] = int(X.shape[1])
    metrics["train_rows"] = int(len(X_train))
    metrics["test_rows"] = int(len(X_test))
    metrics["train_fraud_count"] = int(y_train.sum())
    metrics["test_fraud_count"] = int(y_test.sum())
    metrics["imbalance_strategy"] = "scale_pos_weight"
    metrics["scale_pos_weight"] = float(scale_pos_weight)

    print_metrics(metrics)

    training_summary = {
        "raw_shape": list(raw_df.shape),
        "processed_shape": list(processed_df.shape),
        "feature_shape": list(X.shape),
        "train_shape": list(X_train.shape),
        "test_shape": list(X_test.shape),
        "train_distribution": {
            str(k): int(v) for k, v in y_train.value_counts().to_dict().items()
        },
        "test_distribution": {
            str(k): int(v) for k, v in y_test.value_counts().to_dict().items()
        },
        "imbalance_strategy": "scale_pos_weight",
        "scale_pos_weight": float(scale_pos_weight),
    }

    save_artifacts(model, metrics, training_summary)
    save_feature_importance(model, X.columns)

    return model, metrics, training_summary


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
if __name__ == "__main__":
    try:
        train_xgboost_model()
    except FileNotFoundError:
        print(f"Error: Dataset file not found at {DATA_PATH}")
    except Exception as e:
        print(f"Error during XGBoost model training: {e}")