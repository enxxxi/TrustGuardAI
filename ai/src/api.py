from datetime import datetime, timezone
from typing import List, Literal

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, field_validator

try:
    from src.predict import load_models, predict_transaction
except ModuleNotFoundError:
    from predict import load_models, predict_transaction


APP_VERSION = "1.0.0"
VALID_TRANSACTION_TYPES = {"CASH_IN", "CASH_OUT", "DEBIT", "PAYMENT", "TRANSFER"}

app = FastAPI(
    title="TrustGuard AI Fraud Detection API",
    description=(
        "Real-time fraud risk scoring API for digital wallet transactions. "
        "The engine combines a supervised fraud classifier, anomaly detection, "
        "and rule-based safeguards to return APPROVE / FLAG / BLOCK decisions."
    ),
    version=APP_VERSION,
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
        value = value.strip().upper()
        if value not in VALID_TRANSACTION_TYPES:
            raise ValueError(f"Invalid transaction type. Must be one of: {sorted(VALID_TRANSACTION_TYPES)}")
        return value

    @field_validator("isFlaggedFraud")
    @classmethod
    def validate_flag(cls, value: int) -> int:
        if value not in (0, 1):
            raise ValueError("isFlaggedFraud must be 0 or 1")
        return value


class PredictionResponse(BaseModel):
    risk_score: int = Field(..., description="Final risk score from 0 to 100")
    status: Literal["APPROVE", "FLAG", "BLOCK"] = Field(..., description="Final decision for the transaction")
    fraud_probability: float = Field(..., description="Fraud probability from supervised classifier")
    anomaly_prediction: int = Field(..., description="Isolation Forest output: 1 = normal, -1 = anomaly")
    anomaly_detected: bool = Field(..., description="Whether anomaly model marked the transaction as unusual")
    anomaly_raw_score: float = Field(..., description="Raw decision score from anomaly model")
    anomaly_risk_score: float = Field(..., description="Normalized anomaly risk score from 0 to 100")
    reasons: List[str] = Field(..., description="Human-readable explanations for the decision")
    recommended_action: str = Field(..., description="Suggested downstream action for wallet/app backend")
    model_version: str = Field(..., description="API/model version identifier")
    scored_at_utc: str = Field(..., description="UTC timestamp when scoring was completed")


class HealthResponse(BaseModel):
    status: str
    service: str
    version: str
    models_loaded: bool


class HomeResponse(BaseModel):
    message: str
    docs: str
    health: str
    predict_endpoint: str
    version: str


# -------------------------------------------------------------------
# Startup
# -------------------------------------------------------------------
@app.on_event("startup")
def startup_event():
    """
    Keep startup lightweight for deployment.
    Models will still be loaded on first request or health check.
    """
    pass


# -------------------------------------------------------------------
# Routes
# -------------------------------------------------------------------
@app.get("/", response_model=HomeResponse, tags=["General"])
def home():
    return HomeResponse(
        message="TrustGuard AI API is running",
        docs="/docs",
        health="/health",
        predict_endpoint="/predict",
        version=APP_VERSION,
    )


@app.get("/health", response_model=HealthResponse, tags=["General"])
def health_check():
    try:
        load_models()
        models_loaded = True
        status = "ok"
    except Exception:
        models_loaded = False
        status = "degraded"

    return HealthResponse(
        status=status,
        service="TrustGuard AI Fraud Detection API",
        version=APP_VERSION,
        models_loaded=models_loaded,
    )


@app.post(
    "/predict",
    response_model=PredictionResponse,
    tags=["Prediction"],
    summary="Score a transaction for fraud risk",
    description="Returns a real-time APPROVE / FLAG / BLOCK decision for a transaction.",
)
def predict(data: TransactionRequest):
    try:
        transaction_data = data.model_dump()
        result = predict_transaction(transaction_data)

        return PredictionResponse(
            **result,
            model_version=APP_VERSION,
            scored_at_utc=datetime.now(timezone.utc).isoformat(),
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=f"Model file error: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {str(e)}")