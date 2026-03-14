function detectAnomaly(profile, transaction) {

  let riskScore = 0

  // Amount anomaly
  if (transaction.amount > profile.avgAmount + 3 * profile.stdAmount) {
    riskScore += 40
  }

  // Location anomaly
  if (!profile.commonLocations.includes(transaction.location)) {
    riskScore += 30
  }

  // Time anomaly
  const hour = new Date(transaction.timestamp).getHours()

  if (!profile.usualHours.includes(hour)) {
    riskScore += 20
  }

  // Extreme transaction
  if (transaction.amount > profile.avgAmount * 10) {
    riskScore += 50
  }

  return {
    riskScore,
    suspicious: riskScore >= 50
  }
}

module.exports = detectAnomaly