import json
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.metrics import (
    classification_report,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
)
from sklearn.model_selection import train_test_split

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
CONTAMINATION = 0.00075

MODEL_DIR = Path("models")
OUTPUT_DIR = Path("outputs")

MODEL_PATH = MODEL_DIR / "fraud_isolation_forest.pkl"
METRICS_PATH = OUTPUT_DIR / "isolation_forest_metrics.json"
TRAINING_SUMMARY_PATH = OUTPUT_DIR / "isolation_forest_training_summary.json"
ANOMALY_ANALYSIS_PATH = OUTPUT_DIR / "isolation_forest_anomaly_analysis.csv"
TOP_ANOMALIES_PATH = OUTPUT_DIR / "top_isolation_forest_anomalies.csv"


# -------------------------------------------------------------------
# Feature preparation
# -------------------------------------------------------------------
def prepare_anomaly_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Prepare numeric feature matrix for Isolation Forest.
    Drops supervised target columns while preserving engineered features.
    """
    drop_cols = []

    if "isFraud" in df.columns:
        drop_cols.append("isFraud")
    if "isFlaggedFraud" in df.columns:
        drop_cols.append("isFlaggedFraud")

    X = df.drop(columns=drop_cols).copy()

    bool_cols = X.select_dtypes(include=["bool"]).columns.tolist()
    if bool_cols:
        X[bool_cols] = X[bool_cols].astype(int)

    return X


# -------------------------------------------------------------------
# Model building
# -------------------------------------------------------------------
def build_model() -> IsolationForest:
    """
    Build Isolation Forest anomaly detector.
    """
    return IsolationForest(
        n_estimators=400,
        contamination=CONTAMINATION,
        max_samples="auto",
        bootstrap=False,
        random_state=RANDOM_STATE,
        n_jobs=-1,
    )


# -------------------------------------------------------------------
# Prediction conversion and scoring
# -------------------------------------------------------------------
def convert_iforest_predictions(raw_pred: np.ndarray) -> np.ndarray:
    """
    Convert IsolationForest outputs:
    -1 = anomaly, 1 = normal
    into:
    1 = anomaly, 0 = normal
    """
    return np.where(raw_pred == -1, 1, 0)


def normalize_anomaly_score(decision_scores: np.ndarray) -> np.ndarray:
    """
    Convert Isolation Forest decision_function outputs into a normalized
    anomaly intensity score between 0 and 100.
    Lower decision_function => more anomalous.
    """
    min_score = np.min(decision_scores)
    max_score = np.max(decision_scores)

    if np.isclose(max_score, min_score):
        return np.zeros_like(decision_scores, dtype=float)

    normalized = (max_score - decision_scores) / (max_score - min_score)
    return normalized * 100.0


# -------------------------------------------------------------------
# Evaluation
# -------------------------------------------------------------------
def evaluate_against_fraud_labels(y_true: pd.Series, anomaly_pred_binary: np.ndarray) -> dict:
    """
    Evaluate anomaly signal against known fraud labels.
    This is a proxy usefulness check, not a standalone fraud benchmark.
    """
    metrics = {
        "precision": float(precision_score(y_true, anomaly_pred_binary, zero_division=0)),
        "recall": float(recall_score(y_true, anomaly_pred_binary, zero_division=0)),
        "f1_score": float(f1_score(y_true, anomaly_pred_binary, zero_division=0)),
        "confusion_matrix": confusion_matrix(y_true, anomaly_pred_binary).tolist(),
        "classification_report": classification_report(
            y_true,
            anomaly_pred_binary,
            zero_division=0,
            output_dict=True,
        ),
    }
    return metrics


def print_metrics(metrics: dict):
    """
    Print evaluation metrics clearly.
    """
    print("\n" + "=" * 70)
    print("ISOLATION FOREST EVALUATION")
    print("=" * 70)

    print(f"Precision : {metrics['precision']:.6f}")
    print(f"Recall    : {metrics['recall']:.6f}")
    print(f"F1-Score  : {metrics['f1_score']:.6f}")

    print("\nConfusion Matrix:")
    print(metrics["confusion_matrix"])

    print("\nClassification Report:")
    print(pd.DataFrame(metrics["classification_report"]).transpose())


# -------------------------------------------------------------------
# Analysis helpers
# -------------------------------------------------------------------
def build_anomaly_analysis_df(
    raw_df: pd.DataFrame,
    processed_df: pd.DataFrame,
    raw_pred: np.ndarray,
    anomaly_binary_pred: np.ndarray,
    decision_scores: np.ndarray,
) -> pd.DataFrame:
    """
    Build detailed anomaly analysis table with raw transaction context.
    """
    analysis_df = pd.DataFrame({
        "step": raw_df["step"].values,
        "type": raw_df["type"].values,
        "amount": raw_df["amount"].values,
        "oldbalanceOrg": raw_df["oldbalanceOrg"].values,
        "newbalanceOrig": raw_df["newbalanceOrig"].values,
        "oldbalanceDest": raw_df["oldbalanceDest"].values,
        "newbalanceDest": raw_df["newbalanceDest"].values,
        "isFraud": processed_df["isFraud"].astype(int).values,
        "iforest_raw_pred": raw_pred,
        "anomaly_binary_pred": anomaly_binary_pred,
        "decision_score": decision_scores,
        "anomaly_risk_score": normalize_anomaly_score(decision_scores),
    })

    return analysis_df


def print_top_anomalies(analysis_df: pd.DataFrame, top_n: int = 20):
    """
    Print the most anomalous rows.
    """
    top_anomalies = analysis_df.sort_values(by="decision_score", ascending=True).head(top_n)

    print(f"\nTop {top_n} most anomalous samples:")
    print(top_anomalies.to_string(index=False))

    return top_anomalies


# -------------------------------------------------------------------
# Saving helpers
# -------------------------------------------------------------------
def save_artifacts(
    model,
    metrics: dict,
    training_summary: dict,
    anomaly_analysis_df: pd.DataFrame,
    top_anomalies_df: pd.DataFrame,
):
    """
    Save model, metrics, summaries, and analysis outputs.
    """
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    joblib.dump(model, MODEL_PATH)

    with open(METRICS_PATH, "w", encoding="utf-8") as f:
        json.dump(metrics, f, indent=4)

    with open(TRAINING_SUMMARY_PATH, "w", encoding="utf-8") as f:
        json.dump(training_summary, f, indent=4)

    anomaly_analysis_df.to_csv(ANOMALY_ANALYSIS_PATH, index=False)
    top_anomalies_df.to_csv(TOP_ANOMALIES_PATH, index=False)

    print(f"\nModel saved to: {MODEL_PATH}")
    print(f"Metrics saved to: {METRICS_PATH}")
    print(f"Training summary saved to: {TRAINING_SUMMARY_PATH}")
    print(f"Anomaly analysis saved to: {ANOMALY_ANALYSIS_PATH}")
    print(f"Top anomalies saved to: {TOP_ANOMALIES_PATH}")


# -------------------------------------------------------------------
# Training pipeline
# -------------------------------------------------------------------
def train_isolation_forest():
    """
    End-to-end Isolation Forest training pipeline.

    Framing:
    - trains an unsupervised anomaly detector
    - evaluates its usefulness against fraud labels
    - intended as an auxiliary signal in hybrid risk scoring
    """
    print("Loading PaySim dataset...")
    raw_df = load_data(path=DATA_PATH, nrows=NROWS)
    print(f"Initial raw shape: {raw_df.shape}")

    print("\nApplying preprocessing pipeline...")
    processed_df = preprocess_data(raw_df)
    print(f"Processed shape: {processed_df.shape}")

    if "isFraud" not in processed_df.columns:
        raise ValueError("Processed dataframe must contain 'isFraud' for evaluation.")

    y_true = processed_df["isFraud"].astype(int)
    X = prepare_anomaly_features(processed_df)

    print("\nFeature matrix shape:", X.shape)
    print("Fraud distribution:")
    print(y_true.value_counts())

    print("\nFraud percentage:")
    print(y_true.value_counts(normalize=True))

    # Holdout split for a more defensible usefulness check
    X_train, X_test, y_train, y_test, raw_train, raw_test, processed_train, processed_test = train_test_split(
        X,
        y_true,
        raw_df,
        processed_df,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=y_true,
    )

    print("\nTraining Isolation Forest on training split...")
    model = build_model()
    model.fit(X_train)

    raw_pred_test = model.predict(X_test)
    anomaly_binary_pred_test = convert_iforest_predictions(raw_pred_test)
    decision_scores_test = model.decision_function(X_test)

    print("\nAnomaly prediction distribution on test split:")
    print(pd.Series(anomaly_binary_pred_test).value_counts().sort_index())

    print("\nDecision function summary on test split:")
    print(pd.Series(decision_scores_test).describe())

    metrics = evaluate_against_fraud_labels(y_test, anomaly_binary_pred_test)
    metrics["model_name"] = "IsolationForest"
    metrics["evaluation_scope"] = "holdout_test_proxy_check"
    metrics["contamination"] = CONTAMINATION
    metrics["train_rows"] = int(len(X_train))
    metrics["test_rows"] = int(len(X_test))
    metrics["train_fraud_count"] = int(y_train.sum())
    metrics["test_fraud_count"] = int(y_test.sum())

    print_metrics(metrics)

    anomaly_analysis_df = build_anomaly_analysis_df(
        raw_df=raw_test.reset_index(drop=True),
        processed_df=processed_test.reset_index(drop=True),
        raw_pred=raw_pred_test,
        anomaly_binary_pred=anomaly_binary_pred_test,
        decision_scores=decision_scores_test,
    )

    print("\nFraud vs anomaly crosstab (test split):")
    print(pd.crosstab(anomaly_analysis_df["isFraud"], anomaly_analysis_df["anomaly_binary_pred"]))

    top_anomalies_df = print_top_anomalies(anomaly_analysis_df, top_n=20)

    fraud_detected_as_anomaly = int(
        anomaly_analysis_df[
            (anomaly_analysis_df["isFraud"] == 1)
            & (anomaly_analysis_df["anomaly_binary_pred"] == 1)
        ].shape[0]
    )

    total_fraud = int(y_test.sum())
    total_anomalies = int(anomaly_analysis_df["anomaly_binary_pred"].sum())

    training_summary = {
        "raw_shape": list(raw_df.shape),
        "processed_shape": list(processed_df.shape),
        "feature_shape": list(X.shape),
        "train_shape": list(X_train.shape),
        "test_shape": list(X_test.shape),
        "fraud_distribution_train": {
            str(k): int(v) for k, v in y_train.value_counts().to_dict().items()
        },
        "fraud_distribution_test": {
            str(k): int(v) for k, v in y_test.value_counts().to_dict().items()
        },
        "contamination": CONTAMINATION,
        "anomaly_prediction_distribution_test": {
            str(k): int(v)
            for k, v in pd.Series(anomaly_binary_pred_test).value_counts().to_dict().items()
        },
        "decision_function_summary_test": {
            "min": float(np.min(decision_scores_test)),
            "max": float(np.max(decision_scores_test)),
            "mean": float(np.mean(decision_scores_test)),
            "std": float(np.std(decision_scores_test)),
        },
        "fraud_detected_as_anomaly_test": fraud_detected_as_anomaly,
        "total_fraud_cases_test": total_fraud,
        "total_predicted_anomalies_test": total_anomalies,
        "recommended_system_role": "auxiliary_anomaly_signal",
        "note": (
            "Isolation Forest is used as an unsupervised anomaly signal to "
            "supplement the supervised fraud classifier, not replace it."
        ),
    }

    save_artifacts(
        model=model,
        metrics=metrics,
        training_summary=training_summary,
        anomaly_analysis_df=anomaly_analysis_df,
        top_anomalies_df=top_anomalies_df,
    )

    return model, metrics, training_summary


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
if __name__ == "__main__":
    try:
        train_isolation_forest()
    except FileNotFoundError:
        print(f"Error: Dataset file not found at {DATA_PATH}")
    except Exception as e:
        print(f"Error during Isolation Forest training: {e}")