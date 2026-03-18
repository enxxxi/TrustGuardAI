# TrustGuardAI
>Real-Time Fraud Protection for ASEAN's Digital Wallet Users
TrustGuard AI is an AI-powered fraud detection system that protects digital wallet users by analyzing transactions in real time and returning an **Approve / Flag / Block** decision.

## Key Features
### 1. Behavioral Transaction Profiling
TrustGuard AI builds a behavioral profile for each user by analyzing patterns such as:
• Average transaction amount
 • Transaction frequency
 • Typical transaction time
 • Location patterns
 • Merchant categories
The system learns what “normal behavior” looks like for each user.

### 2. Real-Time Fraud Risk Scoring
Every transaction is analyzed instantly and assigned a risk score between 0 and 100.
will Approve/ Flag/ Block according to score
this helps prevent fraud before money is lost

### 3. Explainable Fraud Detection
TrustGuard AI provides clear explanations for every decision.

### 4. Adaptive Fraud Learning
TrustGuard AI continuously improves by learning from:
• New transaction patterns
• Confirmed fraud cases
• Behavioral changes over time

This allows the system to:
• Detect emerging fraud strategies
• Reduce false positives
• Adapt to new user behaviors

## Tech Stack

| Layer     | Technology                          |
|-----------|--------------------------------------|
| Frontend  | React (Web), Flutter (Mobile)        |
| Backend   | FastAPI (Python)                     |
| AI Models | XGBoost, Isolation Forest            |
| Database  | Firebase                             |
| Dataset   | PaySim (Kaggle)                      |

## 🤖 AI Model Details

| Model             | Purpose                                      |
|------------------|----------------------------------------------|
| XGBoost          | Supervised fraud classification              |
| Isolation Forest | Anomaly detection for unknown fraud patterns |
| Rule-based checks | Large transfers, suspicious balance changes |

## ⚙️ How To Run
```bash
# 1. Clone the repo
git clone https://github.com/your-org/trustguard-ai.git

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate        # Windows
source venv/bin/activate     # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Download dataset and place at:
ai/data/paysim.csv
# Dataset: https://www.kaggle.com/datasets/ealaxi/paysim1

# 5. Train models
python src/train_xgboost_features.py
python src/train_isolation_forest.py

# 6. Run prediction
python src/predict.py
```

---

## Demo video
## ⚠️ Disclaimer
This project is built for educational and demonstration purposes. Do not use in production without proper security audits and compliance checks.
