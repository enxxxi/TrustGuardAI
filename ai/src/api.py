from typing import List

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, field_validator

from src.predict import predict_transaction


app = FastAPI(
    title="TrustGuard AI Fraud Detection API",
    description=(
        "Real-time fraud risk scoring API for digital wallet transactions. "
        "The engine combines a supervised fraud classifier, anomaly detection, "
        "and rule-based safeguards to return APPROVE / FLAG / BLOCK decisions."
    ),
    version="1.0.0",
)


# -------------------------------------------------------------------
# Request / Response Models
# -------------------------------------------------------------------
class TransactionRequest(BaseModel):
    step: int = Field(..., ge=0, examples=[1], description="Transaction step/time index")
    type: str = Field(..., examples=["TRANSFER"], description="Transaction type")
    amount: float = Field(..., ge=0, examples=[35063.63], description="Transaction amount")
    oldbalanceOrg: float = Field(..., ge=0, examples=[35063.63], description="Sender balance before transaction")
    newbalanceOrig: float = Field(..., ge=0, examples=[0.0], description="Sender balance after transaction")
    oldbalanceDest: float = Field(..., ge=0, examples=[0.0], description="Receiver balance before transaction")
    newbalanceDest: float = Field(..., ge=0, examples=[0.0], description="Receiver balance after transaction")
    isFlaggedFraud: int = Field(..., examples=[0], description="Upstream rule-based fraud flag: 0 or 1")

    @field_validator("type")
    @classmethod
    def validate_type(cls, value: str) -> str:
        valid_types = {"CASH_IN", "CASH_OUT", "DEBIT", "PAYMENT", "TRANSFER"}
        value = value.strip().upper()
        if value not in valid_types:
            raise ValueError(f"Invalid transaction type. Must be one of: {sorted(valid_types)}")
        return value

    @field_validator("isFlaggedFraud")
    @classmethod
    def validate_flag(cls, value: int) -> int:
        if value not in (0, 1):
            raise ValueError("isFlaggedFraud must be 0 or 1")
        return value


class PredictionResponse(BaseModel):
    risk_score: int
    status: str
    fraud_probability: float
    anomaly_prediction: int
    anomaly_detected: bool
    anomaly_raw_score: float
    anomaly_risk_score: float
    reasons: List[str]
    recommended_action: str


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str


# -------------------------------------------------------------------
# Routes
# -------------------------------------------------------------------
@app.get("/", tags=["General"])
def home():
    return {
        "message": "TrustGuard AI API is running",
        "docs": "/docs",
        "health": "/health",
        "predict_endpoint": "/predict",
    }


@app.get("/health", response_model=HealthResponse, tags=["General"])
def health_check():
    return HealthResponse(
        status="ok",
        service="TrustGuard AI Fraud Detection API",
        version="1.0.0",
    )


@app.post("/predict", response_model=PredictionResponse, tags=["Prediction"])
def predict(data: TransactionRequest):
    try:
        transaction_data = data.model_dump()
        result = predict_transaction(transaction_data)
        return PredictionResponse(**result)

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=f"Model file error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")