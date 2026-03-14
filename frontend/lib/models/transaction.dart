// lib/models/transaction.dart

enum TxStatus { approved, flagged, blocked }

class Transaction {
  final String id;
  final String name;
  final String userType;
  final double amount;
  final String time;
  final String location;
  final int riskScore;
  final TxStatus status;
  final String emoji;

  const Transaction({
    required this.id,
    required this.name,
    required this.userType,
    required this.amount,
    required this.time,
    required this.location,
    required this.riskScore,
    required this.status,
    required this.emoji,
  });
}

class AlertItem {
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;

  const AlertItem({
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
  });
}

enum AlertSeverity { danger, warning, info }

class BehaviorStat {
  final String label;
  final String icon;
  final double value; // 0.0 - 1.0
  final String display;
  final bool isAnomaly;

  const BehaviorStat({
    required this.label,
    required this.icon,
    required this.value,
    required this.display,
    this.isAnomaly = false,
  });
}

// ── Sample Data ──
class AppData {
  static const transactions = [
    Transaction(
      id: 'TX#9201', name: 'Shopee Pay', userType: 'E-commerce',
      amount: 45.00, time: '14:32', location: 'Kuala Lumpur, MY',
      riskScore: 8, status: TxStatus.approved, emoji: '🛒',
    ),
    Transaction(
      id: 'TX#9198', name: 'GrabPay — BLOCKED', userType: 'Ride-hailing',
      amount: 1200.00, time: '14:31', location: 'Indonesia IP → MY',
      riskScore: 91, status: TxStatus.blocked, emoji: '🚫',
    ),
    Transaction(
      id: 'TX#9195', name: "Touch 'n Go — Flagged", userType: 'E-wallet',
      amount: 340.00, time: '14:30', location: 'Penang, MY',
      riskScore: 58, status: TxStatus.flagged, emoji: '⚑',
    ),
    Transaction(
      id: 'TX#9192', name: 'Lazada Wallet', userType: 'E-commerce',
      amount: 78.50, time: '14:29', location: 'Shah Alam, MY',
      riskScore: 12, status: TxStatus.approved, emoji: '🛍️',
    ),
    Transaction(
      id: 'TX#9189', name: 'GrabFood', userType: 'Food delivery',
      amount: 33.00, time: '14:28', location: 'Johor Bahru, MY',
      riskScore: 5, status: TxStatus.approved, emoji: '🍜',
    ),
  ];

  static const alerts = [
    AlertItem(
      title: 'Transaction Blocked — RM 1,200',
      description: 'GrabPay transaction blocked. New device + Indonesian IP. Risk score: 91%.',
      time: '2 min ago',
      severity: AlertSeverity.danger,
    ),
    AlertItem(
      title: 'Transaction Flagged — RM 340',
      description: "Touch 'n Go flagged for review. Amount above user baseline. Risk: 58%.",
      time: '7 min ago',
      severity: AlertSeverity.warning,
    ),
    AlertItem(
      title: 'New Device Login Detected',
      description: 'Account accessed from unrecognized device in Selangor at 02:47 AM.',
      time: '22 min ago',
      severity: AlertSeverity.danger,
    ),
    AlertItem(
      title: 'Model Updated — Accuracy 96.4%',
      description: 'Adaptive learning retrained with 142 new fraud cases.',
      time: '2h ago',
      severity: AlertSeverity.info,
    ),
    AlertItem(
      title: 'Velocity Alert Cleared',
      description: 'User #7731 transaction spike has been reviewed and resolved.',
      time: '3h ago',
      severity: AlertSeverity.info,
    ),
  ];

  static const behaviorStats = [
    BehaviorStat(label: 'Avg Transaction', icon: '💰', value: 0.26, display: 'RM 52 / normal'),
    BehaviorStat(label: 'Active Hours', icon: '⏰', value: 0.80, display: '8AM–10PM'),
    BehaviorStat(label: 'Home Region', icon: '📍', value: 0.94, display: '94% match'),
    BehaviorStat(label: 'Known Device', icon: '📱', value: 0.89, display: '89% logins'),
    BehaviorStat(label: 'Tx Velocity', icon: '🔁', value: 0.18, display: '1–3 per hour'),
  ];
}
