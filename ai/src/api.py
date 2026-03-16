from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from src.predict import predict_transaction

app = FastAPI(
    title="TrustGuard AI Fraud Detection API",
    description="API for detecting fraudulent transactions",
    version="1.0"
)


class Transaction(BaseModel):
    step: int
    type: str
    amount: float
    oldbalanceOrg: float
    newbalanceOrig: float
    oldbalanceDest: float
    newbalanceDest: float
    isFlaggedFraud: int


@app.get("/")
def home():
    return {"message": "TrustGuard AI API is running"}


@app.post("/predict")
def predict(data: Transaction):
    try:
        transaction_data = {
            "step": data.step,
            "type": data.type,
            "amount": data.amount,
            "oldbalanceOrg": data.oldbalanceOrg,
            "newbalanceOrig": data.newbalanceOrig,
            "oldbalanceDest": data.oldbalanceDest,
            "newbalanceDest": data.newbalanceDest,
            "isFlaggedFraud": data.isFlaggedFraud
        }

        result = predict_transaction(transaction_data)
        return result

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))