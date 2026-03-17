// lib/models/app_state.dart
import 'package:flutter/material.dart';

// ─── Enums ───────────────────────────────────────────
enum TxStatus { approved, flagged, blocked }
enum AlertSeverity { danger, warning, info }
enum TxCategory { food, transport, shopping, transfer, utility, unknown }

// ─── Models ──────────────────────────────────────────
class Transaction {
  final String id;
  final String name;
  final String userType;
  final double amount;
  final String time;
  final String date;
  final String location;
  final int riskScore;
  final TxStatus status;
  final String emoji;
  final TxCategory category;
  final String? blockReason;
  final String platform;

  const Transaction({
    required this.id, required this.name, required this.userType,
    required this.amount, required this.time, required this.date,
    required this.location, required this.riskScore, required this.status,
    required this.emoji, required this.category, required this.platform,
    this.blockReason,
  });
}

class AlertItem {
  final String id;
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;
  bool isRead;

  AlertItem({
    required this.id, required this.title, required this.description,
    required this.time, required this.severity, this.isRead = false,
  });
}

class BehaviorStat {
  final String label;
  final String icon;
  final double normalValue;
  final double currentValue;
  final String normalDisplay;
  final String currentDisplay;
  final bool isAnomaly;

  const BehaviorStat({
    required this.label, required this.icon,
    required this.normalValue, required this.currentValue,
    required this.normalDisplay, required this.currentDisplay,
    this.isAnomaly = false,
  });
}

class SpendCategory {
  final String name;
  final String emoji;
  final double amount;
  final double pct;
  final Color color;

  const SpendCategory({
    required this.name, required this.emoji,
    required this.amount, required this.pct, required this.color,
  });
}

// ─── App State (Provider) ────────────────────────────
class AppState extends ChangeNotifier {
  int _navIndex = 0;
  int get navIndex => _navIndex;
  void setNav(int i) { _navIndex = i; notifyListeners(); }

  // Notifications
  bool _notifEnabled = true;
  bool get notifEnabled => _notifEnabled;
  void toggleNotif() { _notifEnabled = !_notifEnabled; notifyListeners(); }

  bool _locationEnabled = true;
  bool get locationEnabled => _locationEnabled;
  void toggleLocation() { _locationEnabled = !_locationEnabled; notifyListeners(); }

  bool _realtimeEnabled = true;
  bool get realtimeEnabled => _realtimeEnabled;
  void toggleRealtime() { _realtimeEnabled = !_realtimeEnabled; notifyListeners(); }

  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;
  void toggleBiometric() { _biometricEnabled = !_biometricEnabled; notifyListeners(); }

  // Alert read state
  final List<AlertItem> _alerts = List.from(AppData.alerts);
  List<AlertItem> get alerts => _alerts;

  int get unreadCount => _alerts.where((a) => !a.isRead).length;

  void markAllRead() {
    for (var a in _alerts) { a.isRead = true; }
    notifyListeners();
  }

  void markRead(String id) {
    final a = _alerts.firstWhere((a) => a.id == id, orElse: () => _alerts.first);
    a.isRead = true;
    notifyListeners();
  }

  // Monthly spend chart data
  static const monthlyFraud = [2, 0, 1, 3, 5, 8, 4, 2, 6, 12, 7, 3];
  static const monthlyApproved = [280, 310, 290, 340, 380, 420, 395, 410, 450, 480, 460, 520];
  static const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
}

// ─── Static Data ─────────────────────────────────────
class AppData {
  static final transactions = <Transaction>[
    const Transaction(
      id: 'TX#9201', name: 'Shopee Pay', userType: 'E-commerce',
      amount: 45.00, time: '14:32', date: 'Today',
      location: 'Kuala Lumpur, MY', riskScore: 8,
      status: TxStatus.approved, emoji: '🛒',
      category: TxCategory.shopping, platform: 'Shopee Pay',
    ),
    const Transaction(
      id: 'TX#9198', name: 'GrabPay', userType: 'Ride-hailing',
      amount: 1200.00, time: '14:31', date: 'Today',
      location: 'Indonesia IP → MY', riskScore: 91,
      status: TxStatus.blocked, emoji: '🚫',
      category: TxCategory.transport, platform: 'GrabPay',
      blockReason: 'New device + foreign IP + 7× normal amount',
    ),
    const Transaction(
      id: 'TX#9195', name: "Touch 'n Go", userType: 'E-wallet',
      amount: 340.00, time: '14:30', date: 'Today',
      location: 'Penang, MY', riskScore: 58,
      status: TxStatus.flagged, emoji: '⚑',
      category: TxCategory.transport, platform: "Touch 'n Go",
    ),
    const Transaction(
      id: 'TX#9192', name: 'Lazada Wallet', userType: 'E-commerce',
      amount: 78.50, time: '14:29', date: 'Today',
      location: 'Shah Alam, MY', riskScore: 12,
      status: TxStatus.approved, emoji: '🛍️',
      category: TxCategory.shopping, platform: 'Lazada',
    ),
    const Transaction(
      id: 'TX#9189', name: 'GrabFood', userType: 'Food delivery',
      amount: 33.00, time: '14:28', date: 'Today',
      location: 'Johor Bahru, MY', riskScore: 5,
      status: TxStatus.approved, emoji: '🍜',
      category: TxCategory.food, platform: 'GrabFood',
    ),
    const Transaction(
      id: 'TX#9185', name: 'BigPay Transfer', userType: 'Transfer',
      amount: 500.00, time: '11:15', date: 'Today',
      location: 'Kuala Lumpur, MY', riskScore: 22,
      status: TxStatus.approved, emoji: '💸',
      category: TxCategory.transfer, platform: 'BigPay',
    ),
    const Transaction(
      id: 'TX#9180', name: 'TNB eBill', userType: 'Utility',
      amount: 120.00, time: '09:00', date: 'Yesterday',
      location: 'Selangor, MY', riskScore: 4,
      status: TxStatus.approved, emoji: '⚡',
      category: TxCategory.utility, platform: 'myTNB',
    ),
    const Transaction(
      id: 'TX#9177', name: 'Boost eWallet', userType: 'Transfer',
      amount: 2800.00, time: '02:47', date: 'Yesterday',
      location: 'Unknown IP / VPN', riskScore: 96,
      status: TxStatus.blocked, emoji: '🔒',
      category: TxCategory.transfer, platform: 'Boost',
      blockReason: 'VPN detected + off-hours + 18× above normal amount',
    ),
  ];

  static final alerts = <AlertItem>[
    AlertItem(
      id: 'A1',
      title: 'Transaction Blocked — RM 1,200',
      description: 'GrabPay transaction blocked. New device + Indonesian IP detected. Velocity spike: 5 transactions in 8 minutes. Risk: 91%.',
      time: '2 min ago',
      severity: AlertSeverity.danger,
    ),
    AlertItem(
      id: 'A2',
      title: 'Transaction Flagged — RM 340',
      description: "Touch 'n Go transaction flagged. Amount 6× above baseline. Unusual merchant category for this time of day. Risk: 58%.",
      time: '7 min ago',
      severity: AlertSeverity.warning,
    ),
    AlertItem(
      id: 'A3',
      title: 'New Device Login Detected',
      description: 'Account accessed from unrecognized device in Selangor at 02:47 AM. Device fingerprint has not been seen before.',
      time: '22 min ago',
      severity: AlertSeverity.danger,
    ),
    AlertItem(
      id: 'A4',
      title: 'High-Risk Cluster: 3 Blocked Txns',
      description: '3 blocked transactions from the same device fingerprint within 12 minutes — possible account takeover attempt.',
      time: '1h ago',
      severity: AlertSeverity.danger,
    ),
    AlertItem(
      id: 'A5',
      title: 'Model Retrained — Accuracy 96.4%',
      description: 'Adaptive learning updated with 142 new confirmed fraud cases. False positive rate reduced to 1.2%.',
      time: '2h ago',
      severity: AlertSeverity.info,
      isRead: true,
    ),
    AlertItem(
      id: 'A6',
      title: 'Velocity Alert Cleared',
      description: 'User #7731 transaction spike reviewed and resolved by fraud team.',
      time: '3h ago',
      severity: AlertSeverity.info,
      isRead: true,
    ),
    AlertItem(
      id: 'A7',
      title: 'Weekly Security Report Ready',
      description: 'Your fraud protection summary for the week is ready. 0 successful fraud attempts.',
      time: '1 day ago',
      severity: AlertSeverity.info,
      isRead: true,
    ),
  ];

  static const behaviorStats = <BehaviorStat>[
    BehaviorStat(
      label: 'Avg Transaction', icon: '💰',
      normalValue: 0.26, currentValue: 0.85,
      normalDisplay: 'RM 52', currentDisplay: 'RM 1,200',
      isAnomaly: true,
    ),
    BehaviorStat(
      label: 'Tx per Hour', icon: '⚡',
      normalValue: 0.15, currentValue: 0.80,
      normalDisplay: '1–2 / hr', currentDisplay: '8 / hr',
      isAnomaly: true,
    ),
    BehaviorStat(
      label: 'Night Activity', icon: '🌙',
      normalValue: 0.05, currentValue: 0.80,
      normalDisplay: '5%', currentDisplay: '80%',
      isAnomaly: true,
    ),
    BehaviorStat(
      label: 'Home Region', icon: '📍',
      normalValue: 0.95, currentValue: 0.20,
      normalDisplay: '95%', currentDisplay: '20%',
      isAnomaly: true,
    ),
    BehaviorStat(
      label: 'Known Device', icon: '📱',
      normalValue: 0.90, currentValue: 0.12,
      normalDisplay: '90%', currentDisplay: '12%',
      isAnomaly: true,
    ),
    BehaviorStat(
      label: 'Merchant Diversity', icon: '🏪',
      normalValue: 0.70, currentValue: 0.68,
      normalDisplay: '70%', currentDisplay: '68%',
      isAnomaly: false,
    ),
  ];

  static const spendCategories = <SpendCategory>[
    SpendCategory(name: 'Shopping', emoji: '🛒', amount: 342.50, pct: 0.38, color: Color(0xFF0057FF)),
    SpendCategory(name: 'Food',     emoji: '🍜', amount: 198.00, pct: 0.22, color: Color(0xFF00B96B)),
    SpendCategory(name: 'Transport',emoji: '🚗', amount: 156.00, pct: 0.17, color: Color(0xFFF59E0B)),
    SpendCategory(name: 'Transfer', emoji: '💸', amount: 120.00, pct: 0.13, color: Color(0xFF6366F1)),
    SpendCategory(name: 'Utility',  emoji: '⚡', amount: 90.00,  pct: 0.10, color: Color(0xFFEF2D56)),
  ];

  // Hourly fraud heatmap data (0–23)
  static const hourlyFraud = <int>[
    2, 1, 3, 5, 1, 0, 0, 1, 2, 4, 6, 8,
    9, 11, 10, 8, 12, 16, 22, 18, 13, 9, 6, 3,
  ];

  // Weekly transaction volumes
  static const weeklyVolumes = <double>[
    142, 178, 203, 156, 289, 312, 198,
  ];
  static const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}
