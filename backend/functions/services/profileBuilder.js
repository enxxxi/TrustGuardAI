function buildUserProfile(transactions) {

  if (transactions.length === 0) {
    return null
  }

  const amounts = transactions.map(t => t.amount)

  const avgAmount =
    amounts.reduce((a, b) => a + b, 0) / amounts.length

  const variance =
    amounts.reduce((sum, a) =>
      sum + Math.pow(a - avgAmount, 2), 0) / amounts.length

  const stdAmount = Math.sqrt(variance)

  const locations =
    [...new Set(transactions.map(t => t.location))]

  const hours =
    [...new Set(transactions.map(t =>
      new Date(t.timestamp).getHours()))]

  return {
    avgAmount,
    stdAmount,
    commonLocations: locations,
    usualHours: hours,
    transactionCount: transactions.length
  }
}

module.exports = buildUserProfile