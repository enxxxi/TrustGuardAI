import joblib
import numpy as np
from pathlib import Path

# Load trained model
model_path = Path(__file__).resolve().parent.parent / "models" / "fraud_baseline.pkl"
model = joblib.load(model_path)


def predict_transaction(transaction_features):
    features = np.array(transaction_features).reshape(1, -1)

    fraud_probability = model.predict_proba(features)[0][1]
    risk_score = int(fraud_probability * 100)

    if risk_score >= 70:
        status = "BLOCK"
        reasons = ["High predicted fraud probability"]
        recommended_action = "Block transaction and trigger security review"
    elif risk_score >= 40:
        status = "FLAG"
        reasons = ["Moderate fraud risk detected"]
        recommended_action = "Flag transaction for review or OTP verification"
    else:
        status = "APPROVE"
        reasons = ["Low predicted fraud probability"]
        recommended_action = "Allow transaction"

    return {
        "risk_score": risk_score,
        "status": status,
        "reasons": reasons,
        "recommended_action": recommended_action
    }


if __name__ == "__main__":
    fake_transaction = np.random.rand(20)
    result = predict_transaction(fake_transaction)

    print("Prediction Result:")
    print(result)