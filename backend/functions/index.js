const functions = require("firebase-functions");
const express = require("express");
const cors = require("cors");
const admin = require("firebase-admin");

admin.initializeApp();

const app = express();
app.use(cors());
app.use(express.json());

// Import transaction route (Behavioral Profiling)
const transactionRoutes = require("./routes/transaction");
app.use("/transaction", transactionRoutes);


/*
-----------------------------------------
Simple Risk Analyzer (your original API)
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

