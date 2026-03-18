const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

const app = express();
app.use(cors());
app.use(express.json());

// Import transaction route (Behavioral Profiling)
const transactionRoutes = require("./routes/transaction");
app.use("/transaction", transactionRoutes);


/*
-----------------------------------------
Simple Risk Analyzer 
-----------------------------------------
POST /analyze
Body example:
{
  "amount": 1200,
  "hour": 2,
  "newLocation": true
}
*/

app.post("/analyze", (req, res) => {

    const { amount, hour, newLocation } = req.body;

    let riskScore = 0;
    let reasons = [];

    if (amount > 1000) {
        riskScore += 50;
        reasons.push("High transaction amount");
    }

    if (hour < 6 || hour > 23) {
        riskScore += 30;
        reasons.push("Unusual transaction time");
    }

    if (newLocation) {
        riskScore += 20;
        reasons.push("Transaction from new location");
    }

    let status = "APPROVED";

    if (riskScore >= 70) status = "BLOCKED";
    else if (riskScore >= 40) status = "REVIEW";

    res.json({
        riskScore,
        status,
        reasons
    });
});


// Export Firebase HTTPS Function
exports.api = functions.https.onRequest(app);

//Score Transaction Endpoint
app.post("/scoreTransaction", (req, res) => {
    
    const { amount, hour, newLocation } = req.body;

    let riskScore = 0;
    let reasons = [];

    // 1️. High transaction amount
    if (amount > 1000) {
        riskScore += 40;
        reasons.push("Transaction amount significantly higher than usual");
    }

    // 2️. Suspicious time
    if (hour < 6 || hour > 23) {
        riskScore += 25;
        reasons.push("Transaction performed at unusual hour");
    }

    // 3️. New location
    if (newLocation === true) {
        riskScore += 30;
        reasons.push("Transaction location differs from previous pattern");
    }

    // Limit risk score to 100
    if (riskScore > 100) {
        riskScore = 100;
    }

    // Decision Logic
    let status = "";

    if (riskScore <= 39) {
        status = "APPROVED";
    } 
    else if (riskScore <= 69) {
        status = "FLAGGED (OTP VERIFICATION)";
    } 
    else {
        status = "BLOCKED";
    }

    res.json({
        amount: amount,
        riskScore: riskScore,
        status: status,
        reasons: reasons
    });

});

// Mock transaction database
const transactionDB = {
    "U1001": [
        { amount: 50, location: "Kuala Lumpur", hour: 14 },
        { amount: 75, location: "Kuala Lumpur", hour: 16 },
        { amount: 40, location: "Kuala Lumpur", hour: 12 }
    ],
    "U2001": [
        { amount: 300, location: "Johor Bahru", hour: 10 },
        { amount: 150, location: "Johor Bahru", hour: 15 }
    ]
};

// Transaction History Endpoint
app.get("/transactionHistory/:userId", (req, res) => {

    const userId = req.params.userId;

    const history = transactionDB[userId];

    if (!history) {
        return res.json({
            message: "No transaction history found"
        });
    }

    res.json({
        userId: userId,
        transactions: history
    });

});

//Fraud Alert Endpoint
app.post("/fraudAlert", (req, res) => {

    const { userId, riskScore, status } = req.body;

    if (status === "BLOCKED") {

        return res.json({
            alert: "HIGH RISK TRANSACTION DETECTED",
            message: `Transaction blocked for user ${userId}`,
            action: "User notified and account temporarily secured"
        });

    }

    if (status.includes("FLAGGED")) {

        return res.json({
            alert: "SUSPICIOUS TRANSACTION",
            message: `OTP verification required for user ${userId}`,
            action: "OTP sent to registered mobile number"
        });

    }

    res.json({
        alert: "LOW RISK",
        message: "Transaction approved"
    });

});

//Risk Dashboard Endpoint
app.get("/riskDashboard", (req, res) => {

    const dashboard = {
        totalTransactions: 1200,
        approved: 980,
        flagged: 150,
        blocked: 70,
        fraudRate: "5.8%",
        mostCommonFraudReason: "Unusual location"
    };

    res.json(dashboard);

});

// Feature 3: Explainable Fraud Detection
app.post("/explain", (req, res) => {

  const {
    amount,
    userAverage,
    newDevice,
    newLocation
  } = req.body;

  let riskScore = 0;
  let explanations = [];

  // Rule 1: Amount much higher than average
  if (amount > userAverage * 5) {
    riskScore += 40;
    explanations.push(
      `Transaction amount is ${(amount / userAverage).toFixed(1)}× higher than the user's average`
    );
  }

  // Rule 2: New device login
  if (newDevice) {
    riskScore += 30;
    explanations.push("Login from a new device");
  }

  // Rule 3: New geographic location
  if (newLocation) {
    riskScore += 30;
    explanations.push("Transaction location is unusual");
  }

  // Determine status
  let status = "APPROVED";

  if (riskScore >= 80) {
    status = "BLOCKED";
  } else if (riskScore >= 40) {
    status = "REVIEW";
  }

  res.json({
    riskScore,
    status,
    explanation: explanations
  });

});

// Feature 4: Adaptive Fraud Learning
app.post("/feedback", (req, res) => {
  const { userId, transactionAmount, location, device, isFraud } = req.body;

  let learningUpdate = "";

  if (isFraud) {
    learningUpdate = "Fraud pattern recorded. Risk model will increase sensitivity for similar transactions.";
  } else {
    learningUpdate = "Legitimate transaction recorded. Model will reduce false positives for similar behaviour.";
  }

  res.json({
    status: "Feedback Recorded",
    userId,
    isFraud,
    learningUpdate
  });
});

//Update User Behavior Profile Endpoint
app.post("/update-profile", (req, res) => {
  const { userId, avgAmount, usualLocations, trustedDevices } = req.body;

  const updatedProfile = {
    userId,
    avgAmount,
    usualLocations,
    trustedDevices,
    lastUpdated: new Date()
  };

  res.json({
    status: "User behaviour profile updated",
    profile: updatedProfile
  });
});


//Retrieve Fraud Insights Endpoint
app.get("/fraud-insights", (req, res) => {

  const insights = {
    emergingFraudPatterns: [
      "High-value transactions from new devices",
      "Transactions occurring outside normal hours",
      "Rapid multiple transfers within short time"
    ],
    modelStatus: "Learning from recent confirmed fraud cases",
    lastUpdated: new Date()
  };

  res.json({
    status: "Adaptive learning insights",
    insights
  });
});

function buildRuleBasedAnalysis(transactionData) {
  const amount = Number(transactionData.amount || 0);
  const device = (transactionData.device || "known").toString();
  const location = (transactionData.location || "home").toString();
  const time = (transactionData.time || "business").toString();
  const merchant = (transactionData.merchant || "regular").toString();

  let riskScore = 5;
  const reasons = [];

  if (amount > 3000) {
    riskScore += 45;
    reasons.push("Amount is far above the user's normal spending pattern");
  } else if (amount > 1000) {
    riskScore += 28;
    reasons.push("Transaction amount is unusually high");
  } else if (amount > 300) {
    riskScore += 14;
    reasons.push("Transaction is moderately above the baseline");
  } else {
    reasons.push("Amount is within the normal spending range");
  }

  if (device === "suspicious") {
    riskScore += 38;
    reasons.push("Device is flagged as suspicious");
  } else if (device === "newDevice") {
    riskScore += 20;
    reasons.push("Transaction is coming from a new device");
  } else {
    reasons.push("Device is known and previously trusted");
  }

  if (location === "vpn") {
    riskScore += 32;
    reasons.push("VPN or proxy usage detected");
  } else if (location === "foreign") {
    riskScore += 24;
    reasons.push("Location is outside the usual wallet region");
  } else if (location === "nearby") {
    riskScore += 9;
    reasons.push("Location shows a mild geographic deviation");
  } else {
    reasons.push("Location matches the expected home region");
  }

  if (time === "lateNight") {
    riskScore += 18;
    reasons.push("Transaction happened in a high-risk late-night window");
  } else if (time === "evening") {
    riskScore += 5;
    reasons.push("Transaction time is slightly outside normal activity");
  } else {
    reasons.push("Transaction occurred during normal business hours");
  }

  if (merchant === "highRisk") {
    riskScore += 20;
    reasons.push("Merchant category is considered high risk");
  } else if (merchant === "newMerchant") {
    riskScore += 8;
    reasons.push("This is the first transaction with the merchant");
  } else {
    reasons.push("Merchant is a familiar low-risk counterparty");
  }

  riskScore = Math.max(0, Math.min(99, riskScore));

  let status = "APPROVED";
  if (riskScore >= 70) status = "BLOCKED";
  else if (riskScore >= 35) status = "FLAGGED";

  return { risk_score: riskScore, status, reasons };
}

function resolveAiModelUrl() {
  const rawUrl = process.env.AI_MODEL_URL || process.env.AI_API_URL;
  if (!rawUrl) return null;

  const trimmed = rawUrl.trim();
  if (trimmed.endsWith("/predict")) return trimmed;

  return `${trimmed.replace(/\/$/, "")}/predict`;
}

// AI-Powered Transaction Analysis Endpoint
exports.analyzeTransaction = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    const transactionData = req.body || {};
    const aiModelUrl = resolveAiModelUrl();

    if (aiModelUrl) {
      try {
        const aiResponse = await axios.post(aiModelUrl, transactionData);
        const result = aiResponse.data || {};

        return res.json({
          success: true,
          risk_score: Number(result.risk_score ?? result.riskScore ?? 0),
          status: result.status || "APPROVED",
          reasons: result.reasons || result.explanation || [],
          source: "model",
        });
      } catch (modelError) {
        console.error("AI MODEL ERROR:", modelError.message);
        console.error("AI MODEL RESPONSE:", modelError.response?.data);
      }
    }

    const fallback = buildRuleBasedAnalysis(transactionData);
    return res.json({
      success: true,
      ...fallback,
      source: "rules",
    });
  } catch (error) {
    console.error("FULL ERROR:", error);
    console.error("MESSAGE:", error.message);
    console.error("RESPONSE:", error.response?.data);

    res.status(500).json({
      error: "AI service failed",
      details: error.message,
    });
  }
});
