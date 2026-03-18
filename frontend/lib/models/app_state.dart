// lib/models/app_state.dart
import 'package:flutter/material.dart';

enum TxStatus   { approved, flagged, blocked }
enum AlertSeverity { danger, warning, info }
enum TxCategory { food, transport, shopping, transfer, utility, unknown }

class Transaction {
  final String id, name, userType, time, date, location, emoji, platform;
  final double amount;
  final int riskScore;
  final TxStatus status;
  final TxCategory category;
  final String? blockReason;
  const Transaction({
    required this.id, required this.name, required this.userType,
    required this.amount, required this.time, required this.date,
    required this.location, required this.riskScore, required this.status,
    required this.emoji, required this.category, required this.platform,
    this.blockReason,
  });
}

class AlertItem {
  final String id, title, description, time;
  final AlertSeverity severity;
  bool isRead;
  AlertItem({required this.id, required this.title, required this.description,
    required this.time, required this.severity, this.isRead = false});
}

class BehaviorStat {
  final String label, icon, normalDisplay, currentDisplay;
  final double normalValue, currentValue;
  final bool isAnomaly;
  const BehaviorStat({required this.label, required this.icon,
    required this.normalValue, required this.currentValue,
    required this.normalDisplay, required this.currentDisplay,
    this.isAnomaly = false});
}

class SpendCategory {
  final String name, emoji;
  final double amount, pct;
  final Color color;
  const SpendCategory({required this.name, required this.emoji,
    required this.amount, required this.pct, required this.color});
}

// ── App State ────────────────────────────────────────
class AppState extends ChangeNotifier {
  int _navIndex = 0;
  int get navIndex => _navIndex;
  void setNav(int i) { _navIndex = i; notifyListeners(); }

  bool _notifEnabled    = true;
  bool _locationEnabled = true;
  bool _realtimeEnabled = true;
  bool _biometricEnabled= false;

  bool get notifEnabled     => _notifEnabled;
  bool get locationEnabled  => _locationEnabled;
  bool get realtimeEnabled  => _realtimeEnabled;
  bool get biometricEnabled => _biometricEnabled;

  void toggleNotif()     { _notifEnabled    = !_notifEnabled;    notifyListeners(); }
  void toggleLocation()  { _locationEnabled = !_locationEnabled; notifyListeners(); }
  void toggleRealtime()  { _realtimeEnabled = !_realtimeEnabled; notifyListeners(); }
  void toggleBiometric() { _biometricEnabled= !_biometricEnabled;notifyListeners(); }

  final List<Transaction> _transactions = List.from(AppData.transactions);
  List<Transaction> get transactions => _transactions;

  final List<AlertItem> _alerts = List.from(AppData.alerts);
  List<AlertItem> get alerts => _alerts;
  int get unreadCount => _alerts.where((a) => !a.isRead).length;
  AlertItem? get latestAlert => _alerts.isEmpty ? null : _alerts.first;
  AlertItem? get latestDangerAlert {
    for (final alert in _alerts) {
      if (alert.severity == AlertSeverity.danger) return alert;
    }
    return null;
  }

  void addAlert(AlertItem alert) {
    _alerts.insert(0, alert);
    notifyListeners();
  }

  void addTransaction(Transaction tx) {
    _transactions.insert(0, tx);
    notifyListeners();
  }

  void addAnalyzedTransaction({
    required double amount,
    required int riskScore,
    required String status,
    List<String> reasons = const [],
    String? location,
    String? merchant,
    String? platform,
  }) {
    final normalizedScore = riskScore.clamp(0, 100).toInt();
    final txStatus = _txStatusFromApi(status, riskScore);
    final timestamp = DateTime.now();
    final transactionId = 'TX#${timestamp.millisecondsSinceEpoch.toString().substring(7)}';
    final merchantName = merchant ?? 'AI Scanned Transaction';
    final txPlatform = platform ?? merchantName;
    final txLocation = location ?? 'Unknown location';

    _transactions.insert(0, Transaction(
      id: transactionId,
      name: merchantName,
      userType: _userTypeFromPlatform(txPlatform),
      amount: amount,
      time: _formatTime(timestamp),
      date: _formatDateLabel(timestamp),
      location: txLocation,
      riskScore: normalizedScore,
      status: txStatus,
      emoji: _emojiForStatus(txStatus),
      category: _categoryFromPlatform(txPlatform),
      platform: txPlatform,
      blockReason: reasons.isEmpty ? null : reasons.join(' + '),
    ));

    final alert = _buildAlertForAnalysis(
      amount: amount,
      riskScore: normalizedScore,
      status: txStatus,
      reasons: reasons,
      platform: txPlatform,
      location: txLocation,
      timestamp: timestamp,
    );

    if (alert != null) {
      _alerts.insert(0, alert);
    }

    notifyListeners();
  }

  void markAllRead() { for (var a in _alerts) { a.isRead = true; } notifyListeners(); }
  void markRead(String id) {
    try { _alerts.firstWhere((a) => a.id == id).isRead = true; } catch (_) {}
    notifyListeners();
  }

  TxStatus _txStatusFromApi(String status, int riskScore) {
    final normalized = status.toUpperCase();
    if (normalized.contains('BLOCK')) return TxStatus.blocked;
    if (normalized.contains('FLAG') || normalized.contains('REVIEW')) {
      return TxStatus.flagged;
    }
    if (riskScore >= 70) return TxStatus.blocked;
    if (riskScore >= 35) return TxStatus.flagged;
    return TxStatus.approved;
  }

  AlertItem? _buildAlertForAnalysis({
    required double amount,
    required int riskScore,
    required TxStatus status,
    required List<String> reasons,
    required String platform,
    required String location,
    required DateTime timestamp,
  }) {
    if (status == TxStatus.approved) return null;

    final severity = status == TxStatus.blocked
        ? AlertSeverity.danger
        : AlertSeverity.warning;
    final title = status == TxStatus.blocked
        ? 'Transaction Blocked - RM ${amount.toStringAsFixed(2)}'
        : 'Transaction Flagged - RM ${amount.toStringAsFixed(2)}';
    final detail = reasons.isEmpty
        ? 'AI detected suspicious activity for $platform in $location.'
        : reasons.join('. ');

    return AlertItem(
      id: 'A${timestamp.millisecondsSinceEpoch}',
      title: title,
      description: '$detail Risk score: ${riskScore.clamp(0, 100)}%.',
      time: 'Just now',
      severity: severity,
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateLabel(DateTime value) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(value.year, value.month, value.day);
    final diff = today.difference(target).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${value.day}/${value.month}/${value.year}';
  }

  String _emojiForStatus(TxStatus status) => switch (status) {
    TxStatus.approved => 'OK',
    TxStatus.flagged => '!',
    TxStatus.blocked => 'X',
  };

  TxCategory _categoryFromPlatform(String platform) {
    final value = platform.toLowerCase();
    if (value.contains('food')) return TxCategory.food;
    if (value.contains('grab') || value.contains('transport')) {
      return TxCategory.transport;
    }
    if (value.contains('transfer')) return TxCategory.transfer;
    if (value.contains('tnb') || value.contains('bill') || value.contains('utility')) {
      return TxCategory.utility;
    }
    if (value.contains('shop') || value.contains('lazada')) {
      return TxCategory.shopping;
    }
    return TxCategory.unknown;
  }

  String _userTypeFromPlatform(String platform) {
    return switch (_categoryFromPlatform(platform)) {
      TxCategory.food => 'Food delivery',
      TxCategory.transport => 'Ride-hailing',
      TxCategory.shopping => 'E-commerce',
      TxCategory.transfer => 'Transfer',
      TxCategory.utility => 'Utility',
      TxCategory.unknown => 'Digital payment',
    };
  }

  static const monthlyFraud    = [2,0,1,3,5,8,4,2,6,12,7,3];
  static const monthlyApproved = [280,310,290,340,380,420,395,410,450,480,460,520];
  static const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];



}

// ── Static Data ──────────────────────────────────────
class AppData {
  static final transactions = <Transaction>[
    const Transaction(id:'TX#9201', name:'Shopee Pay',      userType:'E-commerce',   amount:45.00,   time:'14:32', date:'Today',     location:'Kuala Lumpur, MY',    riskScore:8,  status:TxStatus.approved, emoji:'🛒', category:TxCategory.shopping,  platform:'Shopee Pay'),
    const Transaction(id:'TX#9198', name:'GrabPay',         userType:'Ride-hailing', amount:1200.00, time:'14:31', date:'Today',     location:'Indonesia IP → MY',   riskScore:91, status:TxStatus.blocked,  emoji:'🚫', category:TxCategory.transport, platform:'GrabPay',   blockReason:'New device + foreign IP + 7× normal amount'),
    const Transaction(id:'TX#9195', name:"Touch 'n Go",     userType:'E-wallet',     amount:340.00,  time:'14:30', date:'Today',     location:'Penang, MY',          riskScore:58, status:TxStatus.flagged,  emoji:'⚑',  category:TxCategory.transport, platform:"Touch 'n Go"),
    const Transaction(id:'TX#9192', name:'Lazada Wallet',   userType:'E-commerce',   amount:78.50,   time:'14:29', date:'Today',     location:'Shah Alam, MY',       riskScore:12, status:TxStatus.approved, emoji:'🛍️', category:TxCategory.shopping,  platform:'Lazada'),
    const Transaction(id:'TX#9189', name:'GrabFood',        userType:'Food delivery',amount:33.00,   time:'14:28', date:'Today',     location:'Johor Bahru, MY',     riskScore:5,  status:TxStatus.approved, emoji:'🍜', category:TxCategory.food,      platform:'GrabFood'),
    const Transaction(id:'TX#9185', name:'BigPay Transfer', userType:'Transfer',     amount:500.00,  time:'11:15', date:'Today',     location:'Kuala Lumpur, MY',    riskScore:22, status:TxStatus.approved, emoji:'💸', category:TxCategory.transfer,  platform:'BigPay'),
    const Transaction(id:'TX#9180', name:'TNB eBill',       userType:'Utility',      amount:120.00,  time:'09:00', date:'Yesterday', location:'Selangor, MY',        riskScore:4,  status:TxStatus.approved, emoji:'⚡', category:TxCategory.utility,   platform:'myTNB'),
    const Transaction(id:'TX#9177', name:'Boost eWallet',   userType:'Transfer',     amount:2800.00, time:'02:47', date:'Yesterday', location:'Unknown IP / VPN',    riskScore:96, status:TxStatus.blocked,  emoji:'🔒', category:TxCategory.transfer,  platform:'Boost',     blockReason:'VPN detected + off-hours + 18× above normal amount'),
  ];

  static final alerts = <AlertItem>[
    AlertItem(id:'A1', title:'Transaction Blocked — RM 1,200', description:'GrabPay transaction blocked. New device + Indonesian IP detected. Velocity spike: 5 transactions in 8 minutes. Risk score: 91%.', time:'2 min ago', severity:AlertSeverity.danger),
    AlertItem(id:'A2', title:'Transaction Flagged — RM 340',   description:"Touch 'n Go transaction flagged for review. Amount is 6× above your daily baseline. Unusual merchant category. Risk: 58%.", time:'7 min ago',  severity:AlertSeverity.warning),
    AlertItem(id:'A3', title:'New Device Login Detected',      description:'Account accessed from unrecognized device in Selangor at 02:47 AM. Device fingerprint has not been seen in 90 days.', time:'22 min ago', severity:AlertSeverity.danger),
    AlertItem(id:'A4', title:'High-Risk Cluster Detected',     description:'3 blocked transactions from same device fingerprint within 12 minutes — possible account takeover attempt.', time:'1h ago', severity:AlertSeverity.danger),
    AlertItem(id:'A5', title:'Model Retrained — 96.4% Accuracy', description:'Adaptive learning updated with 142 new confirmed fraud cases. False positive rate reduced to 1.2%. Your protection is stronger.', time:'2h ago', severity:AlertSeverity.info, isRead:true),
    AlertItem(id:'A6', title:'Velocity Alert Cleared',         description:'User #7731 transaction spike reviewed and resolved by the fraud team.', time:'3h ago', severity:AlertSeverity.info, isRead:true),
    AlertItem(id:'A7', title:'Weekly Security Report Ready',   description:'Your fraud protection summary for this week is ready to view. 0 successful fraud attempts detected.', time:'1 day ago', severity:AlertSeverity.info, isRead:true),
  ];

  static const behaviorStats = <BehaviorStat>[
    BehaviorStat(label:'Avg Transaction', icon:'💰', normalValue:0.26, currentValue:0.85, normalDisplay:'RM 52',    currentDisplay:'RM 1,200', isAnomaly:true),
    BehaviorStat(label:'Tx per Hour',     icon:'⚡', normalValue:0.15, currentValue:0.80, normalDisplay:'1–2/hr',   currentDisplay:'8/hr',     isAnomaly:true),
    BehaviorStat(label:'Night Activity',  icon:'🌙', normalValue:0.05, currentValue:0.80, normalDisplay:'5%',       currentDisplay:'80%',      isAnomaly:true),
    BehaviorStat(label:'Home Region',     icon:'📍', normalValue:0.95, currentValue:0.20, normalDisplay:'95%',      currentDisplay:'20%',      isAnomaly:true),
    BehaviorStat(label:'Known Device',    icon:'📱', normalValue:0.90, currentValue:0.12, normalDisplay:'90%',      currentDisplay:'12%',      isAnomaly:true),
    BehaviorStat(label:'Merchant Diversity',icon:'🏪',normalValue:0.70, currentValue:0.68, normalDisplay:'70%',     currentDisplay:'68%',      isAnomaly:false),
  ];

  static const spendCategories = <SpendCategory>[
    SpendCategory(name:'Shopping',  emoji:'🛒', amount:342.50, pct:0.38, color:Color(0xFF1D4ED8)),
    SpendCategory(name:'Food',      emoji:'🍜', amount:198.00, pct:0.22, color:Color(0xFF059669)),
    SpendCategory(name:'Transport', emoji:'🚗', amount:156.00, pct:0.17, color:Color(0xFFD97706)),
    SpendCategory(name:'Transfer',  emoji:'💸', amount:120.00, pct:0.13, color:Color(0xFF7C3AED)),
    SpendCategory(name:'Utility',   emoji:'⚡', amount:90.00,  pct:0.10, color:Color(0xFFDC2626)),
  ];

  static const weeklyVolumes = <double>[142, 178, 203, 156, 289, 312, 198];
  static const weekDays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  static const hourlyFraud = <int>[2,1,3,5,1,0,0,1,2,4,6,8,9,11,10,8,12,16,22,18,13,9,6,3];
}
