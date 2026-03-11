const { detectFraud } = require("../services/fraudService");

const analyzeTransaction = (req, res) => {
    const transaction = req.body;

    if (!transaction || transaction.amount === undefined) {
        return res.status(400).json({ error: "Invalid transaction data" });
    }

    const result = detectFraud(transaction);
    res.json(result);
};

module.exports = { analyzeTransaction };