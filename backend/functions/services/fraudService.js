function detectFraud(transaction) {
    let riskScore = 0;
    let reasons = [];

    if (transaction.amount > 1000) {
        riskScore += 50;
        reasons.push("Transaction amount unusually high");
    }
    if (transaction.hour < 6 || transaction.hour > 23) {
        riskScore += 20;
        reasons.push("Unusual transaction time");
    }
    if (transaction.newLocation) {
        riskScore += 30;
        reasons.push("Transaction from new location");
    }

    let status = "APPROVED";
    if (riskScore >= 70) status = "BLOCKED";
    else if (riskScore >= 40) status = "FLAGGED";

    return { riskScore, status, reasons };
}

module.exports = { detectFraud };