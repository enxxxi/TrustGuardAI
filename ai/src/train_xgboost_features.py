import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.metrics import (
    average_precision_score,
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.model_selection import StratifiedKFold, cross_val_score, train_test_split
from xgboost import XGBClassifier

from load_dataset import load_data, preprocess_data


# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
DATA_PATH = "data/paysim.csv"
NROWS = 200000
TEST_SIZE = 0.2
RANDOM_STATE = 42
CV_FOLDS = 5

MODEL_DIR = Path("models")
OUTPUT_DIR = Path("outputs")

MODEL_PATH = MODEL_DIR / "fraud_paysim_xgboost_features.pkl"
METRICS_PATH = OUTPUT_DIR / "xgboost_features_metrics.json"
FEATURE_IMPORTANCE_PATH = OUTPUT_DIR / "xgboost_features_feature_importance.csv"
TRAINING_SUMMARY_PATH = OUTPUT_DIR / "xgboost_features_training_summary.json"
CV_RESULTS_PATH = OUTPUT_DIR / "xgboost_features_cv_results.json"


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
def build_model(scale_pos_weight: float) -> XGBClassifier:
    """
    Build XGBoost classifier for engineered-feature training.
    """
    return XGBClassifier(
        n_estimators=350,
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

    return metrics


def print_metrics(metrics: dict):
    print("\n" + "=" * 70)
    print("XGBOOST FEATURES MODEL EVALUATION")
    print("=" * 70)

    print(f"ROC-AUC   : {metrics['roc_auc']:.6f}")
    print(f"PR-AUC    : {metrics['pr_auc']:.6f}")
    print(f"Precision : {metrics['precision']:.6f}")
    print(f"Recall    : {metrics['recall']:.6f}")
    print(f"F1-Score  : {metrics['f1_score']:.6f}")

    print("\nConfusion Matrix:")
    print(metrics["confusion_matrix"])

    print("\nClassification Report:")
    print(pd.DataFrame(metrics["classification_report"]).transpose())


# -------------------------------------------------------------------
# Feature importance
# -------------------------------------------------------------------
def save_feature_importance(model, feature_names):
    if not hasattr(model, "feature_importances_"):
        print("Model does not support feature importance.")
        return

    importance_df = pd.DataFrame(
        {
            "feature": feature_names,
            "importance": model.feature_importances_,
        }
    ).sort_values(by="importance", ascending=False)

    FEATURE_IMPORTANCE_PATH.parent.mkdir(parents=True, exist_ok=True)
    importance_df.to_csv(FEATURE_IMPORTANCE_PATH, index=False)

    print(f"\nFeature importance saved to: {FEATURE_IMPORTANCE_PATH}")
    print("\nTop 15 important features:")
    print(importance_df.head(15))


# -------------------------------------------------------------------
# Cross-validation
# -------------------------------------------------------------------
def run_cross_validation(X, y, scale_pos_weight: float):
    """
    Run stratified cross-validation using ROC-AUC.
    """
    print("\nRunning stratified cross-validation...")

    cv_model = build_model(scale_pos_weight=scale_pos_weight)
    cv = StratifiedKFold(n_splits=CV_FOLDS, shuffle=True, random_state=RANDOM_STATE)

    scores = cross_val_score(
        cv_model,
        X,
        y,
        cv=cv,
        scoring="roc_auc",
        n_jobs=-1,
    )

    cv_results = {
        "cv_folds": CV_FOLDS,
        "roc_auc_scores": [float(score) for score in scores],
        "mean_roc_auc": float(scores.mean()),
        "std_roc_auc": float(scores.std()),
    }

    print("Cross-validation ROC-AUC scores:", scores)
    print("Mean ROC-AUC:", scores.mean())
    print("Std ROC-AUC :", scores.std())

    with open(CV_RESULTS_PATH, "w", encoding="utf-8") as f:
        json.dump(cv_results, f, indent=4)

    print(f"Cross-validation results saved to: {CV_RESULTS_PATH}")

    return cv_results


# -------------------------------------------------------------------
# Saving artifacts
# -------------------------------------------------------------------
def save_artifacts(model, metrics, training_summary):
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
def train_xgboost_features_model():
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

    negative_count = int((y_train == 0).sum())
    positive_count = int((y_train == 1).sum())
    scale_pos_weight = negative_count / max(positive_count, 1)

    print(f"\nscale_pos_weight: {scale_pos_weight:.6f}")

    print("\nTraining XGBoost model with engineered/shared features...")
    model = build_model(scale_pos_weight=scale_pos_weight)
    model.fit(X_train, y_train)

    print("Evaluating model...")
    metrics = evaluate_model(model, X_test, y_test)
    print_metrics(metrics)

    cv_results = run_cross_validation(X, y, scale_pos_weight=scale_pos_weight)

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
        "cross_validation_mean_roc_auc": cv_results["mean_roc_auc"],
        "cross_validation_std_roc_auc": cv_results["std_roc_auc"],
    }

    save_artifacts(model, metrics, training_summary)
    save_feature_importance(model, X.columns)

    return model, metrics, training_summary, cv_results


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
if __name__ == "__main__":
    try:
        train_xgboost_features_model()
    except FileNotFoundError:
        print(f"Error: Dataset file not found at {DATA_PATH}")
    except Exception as e:
        print(f"Error during XGBoost features model training: {e}")