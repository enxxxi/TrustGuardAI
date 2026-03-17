import json
from pathlib import Path

import pandas as pd

try:
    from src.predict import (
        load_models,
        preprocess_transaction,
        align_features_for_model,
        compute_risk_score,
        derive_reasons,
        map_decision,
    )
except ModuleNotFoundError:
    from predict import (
        load_models,
        preprocess_transaction,
        align_features_for_model,
        compute_risk_score,
        derive_reasons,
        map_decision,
    )


DATA_PATH = Path("data/paysim.csv")
SAMPLE_SIZE = 300


def build_transaction_payload(row: pd.Series) -> dict:
    return {
        "step": int(row["step"]),
        "type": str(row["type"]),
        "amount": float(row["amount"]),
        "oldbalanceOrg": float(row["oldbalanceOrg"]),
        "newbalanceOrig": float(row["newbalanceOrig"]),
        "oldbalanceDest": float(row["oldbalanceDest"]),
        "newbalanceDest": float(row["newbalanceDest"]),
        "isFlaggedFraud": int(row["isFlaggedFraud"]),
        "nameOrig": str(row["nameOrig"]) if "nameOrig" in row else "C_UNKNOWN_ORIG",
        "nameDest": str(row["nameDest"]) if "nameDest" in row else "C_UNKNOWN_DEST",
    }


def preprocess_dataset(df: pd.DataFrame) -> pd.DataFrame:
    processed_rows = []
    for _, row in df.iterrows():
        tx = build_transaction_payload(row)
        processed = preprocess_transaction(tx)
        processed_rows.append(processed.iloc[0])
    return pd.DataFrame(processed_rows).reset_index(drop=True)


def print_section(title: str, section_df: pd.DataFrame, limit: int = 10) -> None:
    print(f"\n{'=' * 80}")
    print(title)
    print(f"{'=' * 80}")

    if section_df.empty:
        print("No rows found.")
        return

    cols = [
        "row_index",
        "step",
        "type",
        "amount",
        "isFraud",
        "isFlaggedFraud",
        "risk_score",
        "status",
        "fraud_probability",
        "anomaly_prediction",
        "anomaly_raw_score",
        "reasons",
    ]
    cols = [c for c in cols if c in section_df.columns]
    print(section_df[cols].head(limit).to_string(index=False))


def main():
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Dataset not found: {DATA_PATH}")

    df = pd.read_csv(DATA_PATH, nrows=SAMPLE_SIZE).reset_index(drop=True)

    classifier_model, anomaly_model = load_models()

    processed_df = preprocess_dataset(df)

    classifier_input = align_features_for_model(processed_df, classifier_model)
    anomaly_input = align_features_for_model(processed_df, anomaly_model)

    fraud_probabilities = classifier_model.predict_proba(classifier_input)[:, 1]
    anomaly_predictions = anomaly_model.predict(anomaly_input)
    anomaly_scores = anomaly_model.decision_function(anomaly_input)

    results = []

    for i, row in df.iterrows():
        tx = build_transaction_payload(row)

        fraud_probability = float(fraud_probabilities[i])
        anomaly_prediction = int(anomaly_predictions[i])
        anomaly_score = float(anomaly_scores[i])

        risk_score = compute_risk_score(
            transaction=tx,
            fraud_probability=fraud_probability,
            anomaly_prediction=anomaly_prediction,
            anomaly_score=anomaly_score,
        )

        reasons = derive_reasons(
            transaction=tx,
            fraud_probability=fraud_probability,
            anomaly_prediction=anomaly_prediction,
            anomaly_score=anomaly_score,
        )

        decision = map_decision(risk_score)

        results.append(
            {
                "row_index": i,
                "step": tx["step"],
                "type": tx["type"],
                "amount": tx["amount"],
                "isFraud": int(row["isFraud"]) if "isFraud" in row else None,
                "isFlaggedFraud": tx["isFlaggedFraud"],
                "risk_score": risk_score,
                "status": decision["status"],
                "fraud_probability": round(fraud_probability, 6),
                "anomaly_prediction": anomaly_prediction,
                "anomaly_raw_score": round(anomaly_score, 6),
                "reasons": " | ".join(reasons),
            }
        )

    scored_df = pd.DataFrame(results)

    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"Total rows checked: {len(scored_df)}")
    print("Decision counts:")
    print(json.dumps(scored_df["status"].value_counts().to_dict(), indent=2))

    if "isFraud" in scored_df.columns:
        fraud_rows = scored_df[scored_df["isFraud"] == 1]
        nonfraud_rows = scored_df[scored_df["isFraud"] == 0]

        print(f"Actual fraud rows in sample: {len(fraud_rows)}")
        print(f"Actual non-fraud rows in sample: {len(nonfraud_rows)}")

        if len(fraud_rows) > 0:
            caught = fraud_rows[fraud_rows["status"].isin(["FLAG", "BLOCK"])]
            blocked = fraud_rows[fraud_rows["status"] == "BLOCK"]
            print(f"Fraud rows flagged or blocked: {len(caught)} / {len(fraud_rows)}")
            print(f"Fraud rows blocked: {len(blocked)} / {len(fraud_rows)}")

        if len(nonfraud_rows) > 0:
            flagged_nonfraud = nonfraud_rows[nonfraud_rows["status"].isin(["FLAG", "BLOCK"])]
            print(f"Non-fraud rows flagged or blocked: {len(flagged_nonfraud)} / {len(nonfraud_rows)}")

    print_section("FLAG EXAMPLES", scored_df[scored_df["status"] == "FLAG"], limit=10)
    print_section("BLOCK EXAMPLES", scored_df[scored_df["status"] == "BLOCK"], limit=10)

    if "isFraud" in scored_df.columns:
        print_section("ACTUAL FRAUD EXAMPLES", scored_df[scored_df["isFraud"] == 1], limit=10)


if __name__ == "__main__":
    main()