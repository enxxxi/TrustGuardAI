# TrustGuardAI
>Real-Time Fraud Protection for ASEAN's Digital Wallet Users
TrustGuard AI is an AI-powered fraud detection system that protects digital wallet users by analyzing transactions in real time and returning an **Approve / Flag / Block** decision.

## Key Features
### 1. Behavioral Transaction Profiling
TrustGuard AI builds a behavioral profile for each user by analyzing patterns such as:
- Average transaction amount
- Transaction frequency
- Typical transaction time
- Location patterns
- Merchant categories
The system learns what “normal behavior” looks like for each user.

### 2. Real-Time Fraud Risk Scoring
Every transaction is analyzed instantly and assigned a risk score between 0 and 100.
will Approve/ Flag/ Block according to score
this helps prevent fraud before money is lost

### 3. Explainable Fraud Detection
TrustGuard AI provides clear explanations for every decision.

### 4. Adaptive Fraud Learning
TrustGuard AI continuously improves by learning from:
- New transaction patterns
- Confirmed fraud cases
- Behavioral changes over time

This allows the system to:
- Detect emerging fraud strategies
- Reduce false positives
- Adapt to new user behaviors

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter / Dart |
| **Backend** | Node.js + Express (Firebase Cloud Functions) |
| **AI / ML** | Python + FastAPI, XGBoost, Isolation Forest |
| **Database** | Firebase |
| **Dataset** | PaySim (Kaggle) |

## ⚙️ How To Run
```bash
# 1. Clone the repo
git clone https://github.com/your-org/trustguard-ai.git
cd trustguard-ai

# 2. Install Flutter dependencies
cd frontend
flutter pub get

# 3. Install Firebase Functions dependencies
cd ../backend/functions
npm install

# 4. Configure service endpoints 
- Update the Flutter API base URL in frontend/lib/services/api_service.dart
- Set AI_MODEL_URL or AI_API_URL in Firebase Functions to your Render endpoint

# 5. Run the Flutter app
cd ../../frontend
flutter run
```

---

## Demo video
> [!IMPORTANT]
>Disclamer: This project is built for educational and demonstration purposes. Do not use in production without proper security audits and compliance checks.
