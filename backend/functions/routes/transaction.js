const express = require("express")
const router = express.Router()

const admin = require("firebase-admin")

const detectAnomaly = require("../services/anomalyDetector")
const buildUserProfile = require("../services/profileBuilder")

const db = admin.firestore()

router.post("/", async (req, res) => {

  try {

    const { userId, amount, location } = req.body

    const timestamp = Date.now()

    const transaction = {
      userId,
      amount,
      location,
      timestamp
    }

    // Get past transactions
    const snapshot = await db
      .collection("transactions")
      .where("userId", "==", userId)
      .get()

    const history = []

    snapshot.forEach(doc => {
      history.push(doc.data())
    })

    // Build user profile
    const profile = buildUserProfile(history)

    let result = { riskScore: 0, suspicious: false }

    if (profile) {
      result = detectAnomaly(profile, transaction)
    }

    // Save transaction
    await db.collection("transactions").add({
      ...transaction,
      riskScore: result.riskScore,
      suspicious: result.suspicious
    })

    res.json({
      message: "Transaction processed",
      riskScore: result.riskScore,
      suspicious: result.suspicious
    })

  } catch (error) {

    console.error(error)

    res.status(500).json({
      error: "Transaction processing failed"
    })

  }

})

module.exports = router