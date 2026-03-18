import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

enum _Device { known, newDevice, suspicious }
enum _Location { home, nearby, foreign, vpn }
enum _Time { business, evening, lateNight }
enum _Merchant { regular, newMerchant, highRisk }

typedef _Factor = ({String icon, String text, Color color, double weight});

class _Result {
  final int score;
  final String decision;
  final double amount;
  final List<_Factor> factors;

  _Result({
    required this.score,
    required this.decision,
    required this.amount,
    required this.factors,
  });
}

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen>
    with SingleTickerProviderStateMixin {
  final _amtCtrl = TextEditingController(text: '150');
  _Device _device = _Device.known;
  _Location _location = _Location.home;
  _Time _time = _Time.business;
  _Merchant _merchant = _Merchant.regular;
  _Result? _result;
  bool _loading = false;
  final _history = <_Result>[];
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final amt = double.tryParse(_amtCtrl.text) ?? 150;
    setState(() {
      _loading = true;
      _result = null;
    });

    final response = await ApiService.analyzeTransaction({
      'amount': amt,
      'device': _device.name,
      'location': _location.name,
      'time': _time.name,
      'merchant': _merchant.name,
      'step': _history.length + 1,
      'hour': _hourForTime(_time),
      'newDevice': _device != _Device.known,
      'newLocation': _location != _Location.home,
      'highRiskMerchant': _merchant == _Merchant.highRisk,
      'isForeignTransaction': _location == _Location.foreign,
      'isVpn': _location == _Location.vpn,
    });

    if (!mounted) return;

    if (response['error'] != null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'].toString())),
      );
      return;
    }

    final score = _parseScore(response['risk_score'] ?? response['riskScore']);
    final status =
        (response['status'] ?? response['decision'] ?? 'APPROVED').toString();
    final reasons = _parseReasons(response);
    final factors =
        reasons.isEmpty ? [_defaultFactor(score)] : _buildFactors(reasons, score);

    final result = _Result(
      score: score,
      decision: _decisionLabel(status, score),
      amount: amt,
      factors: factors,
    );

    setState(() {
      _result = result;
      _loading = false;
      _history.insert(0, result);
      if (_history.length > 10) _history.removeLast();
    });
  }

  int _parseScore(dynamic value) {
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);
    return int.tryParse(value?.toString() ?? '')?.clamp(0, 100) ?? 0;
  }

  List<String> _parseReasons(Map<String, dynamic> response) {
    final raw = response['reasons'] ?? response['explanation'];
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _decisionLabel(String status, int score) {
    final normalized = status.toUpperCase();
    if (normalized.contains('BLOCK')) return 'BLOCKED';
    if (normalized.contains('FLAG') || normalized.contains('REVIEW')) {
      return 'FLAGGED';
    }
    if (score >= 70) return 'BLOCKED';
    if (score >= 35) return 'FLAGGED';
    return 'APPROVED';
  }

  _Factor _defaultFactor(int score) {
    if (score >= 70) {
      return (
        icon: '!',
        text: 'High-risk fraud pattern detected by the model',
        color: AppColors.danger,
        weight: 0.85,
      );
    }
    if (score >= 35) {
      return (
        icon: 'i',
        text: 'Transaction requires manual review',
        color: AppColors.warn,
        weight: 0.55,
      );
    }
    return (
      icon: 'OK',
      text: 'No strong fraud signals detected',
      color: AppColors.safe,
      weight: 0.10,
    );
  }

  List<_Factor> _buildFactors(List<String> reasons, int score) {
    final baseColor = score >= 70
        ? AppColors.danger
        : score >= 35
            ? AppColors.warn
            : AppColors.safe;

    return reasons.asMap().entries.map((entry) {
      final text = entry.value;
      return (
        icon: _iconForReason(text),
        text: text,
        color: _colorForReason(text, baseColor),
        weight: _weightForReason(text, entry.key, reasons.length),
      );
    }).toList();
  }

  String _iconForReason(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('amount')) return 'RM';
    if (lower.contains('device')) return 'DEV';
    if (lower.contains('vpn') ||
        lower.contains('proxy') ||
        lower.contains('location') ||
        lower.contains('ip')) {
      return 'NET';
    }
    if (lower.contains('merchant')) return 'M';
    if (lower.contains('time') ||
        lower.contains('hour') ||
        lower.contains('night')) {
      return 'T';
    }
    return '!';
  }

  Color _colorForReason(String text, Color baseColor) {
    final lower = text.toLowerCase();
    if (lower.contains('safe') ||
        lower.contains('normal') ||
        lower.contains('verified')) {
      return AppColors.safe;
    }
    if (lower.contains('slight') ||
        lower.contains('minor') ||
        lower.contains('review')) {
      return AppColors.warn;
    }
    return baseColor;
  }

  double _weightForReason(String text, int index, int total) {
    final lower = text.toLowerCase();
    if (lower.contains('extreme') ||
        lower.contains('blocked') ||
        lower.contains('vpn')) {
      return 0.92;
    }
    if (lower.contains('high') ||
        lower.contains('unusual') ||
        lower.contains('new')) {
      return 0.75;
    }
    if (lower.contains('review') ||
        lower.contains('moderate') ||
        lower.contains('nearby')) {
      return 0.45;
    }
    final step = total <= 1 ? 0 : index / total;
    return (0.65 - (step * 0.2)).clamp(0.2, 0.8);
  }

  int _hourForTime(_Time time) {
    switch (time) {
      case _Time.business:
        return 14;
      case _Time.evening:
        return 20;
      case _Time.lateNight:
        return 2;
    }
  }

  Color get _rc {
    final s = _result?.score ?? 0;
    return s >= 70
        ? AppColors.danger
        : s >= 35
            ? AppColors.warn
            : AppColors.safe;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analyze Transaction', style: AppText.h1(22)),
              const SizedBox(height: 2),
              Text('Real-time AI fraud risk scoring',
                  style: AppText.label(13)),
              const SizedBox(height: 14),
              TabBar(
                controller: _tab,
                labelStyle: AppText.label(13, weight: FontWeight.w700),
                unselectedLabelStyle: AppText.label(13),
                labelColor: AppColors.accent,
                unselectedLabelColor: AppColors.ink3,
                indicatorColor: AppColors.accent,
                indicatorWeight: 2,
                tabs: [
                  const Tab(text: 'New Scan'),
                  Tab(text: 'History (${_history.length})'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InputCard(
                      amtCtrl: _amtCtrl,
                      device: _device,
                      location: _location,
                      time: _time,
                      merchant: _merchant,
                      onDevice: (v) => setState(() => _device = v),
                      onLocation: (v) => setState(() => _location = v),
                      onTime: (v) => setState(() => _time = v),
                      onMerchant: (v) => setState(() => _merchant = v),
                      loading: _loading,
                      onAnalyze: _analyze,
                    ),
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      _ResultCard(result: _result!, color: _rc),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              _history.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded,
                              size: 48, color: AppColors.ink4),
                          const SizedBox(height: 12),
                          Text('No scans yet',
                              style: AppText.h2(16, color: AppColors.ink3)),
                          const SizedBox(height: 4),
                          Text('Run a scan to see history here',
                              style: AppText.label(13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _history.length,
                      itemBuilder: (_, i) =>
                          _HistoryCard(result: _history[i], index: i),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController amtCtrl;
  final _Device device;
  final _Location location;
  final _Time time;
  final _Merchant merchant;
  final ValueChanged<_Device> onDevice;
  final ValueChanged<_Location> onLocation;
  final ValueChanged<_Time> onTime;
  final ValueChanged<_Merchant> onMerchant;
  final bool loading;
  final VoidCallback onAnalyze;

  const _InputCard({
    required this.amtCtrl,
    required this.device,
    required this.location,
    required this.time,
    required this.merchant,
    required this.onDevice,
    required this.onLocation,
    required this.onTime,
    required this.onMerchant,
    required this.loading,
    required this.onAnalyze,
  });

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: AppText.label(11, weight: FontWeight.w600)),
      );

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppText.label(14),
        filled: true,
        fillColor: AppColors.card2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        isDense: true,
      );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _lbl('Transaction Amount (MYR)'),
          TextField(
            controller: amtCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppText.body(15, color: AppColors.ink),
            decoration: _dec('e.g. 150.00'),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('Device'),
                    DropdownButtonFormField<_Device>(
                      value: device,
                      decoration: _dec(null),
                      style: AppText.body(13, color: AppColors.ink),
                      items: const [
                        DropdownMenuItem(
                          value: _Device.known,
                          child: Text('Known Device'),
                        ),
                        DropdownMenuItem(
                          value: _Device.newDevice,
                          child: Text('New Device'),
                        ),
                        DropdownMenuItem(
                          value: _Device.suspicious,
                          child: Text('Suspicious'),
                        ),
                      ],
                      onChanged: (v) => v != null ? onDevice(v) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('Location'),
                    DropdownButtonFormField<_Location>(
                      value: location,
                      decoration: _dec(null),
                      style: AppText.body(13, color: AppColors.ink),
                      items: const [
                        DropdownMenuItem(
                          value: _Location.home,
                          child: Text('Home (MY)'),
                        ),
                        DropdownMenuItem(
                          value: _Location.nearby,
                          child: Text('Nearby (SG)'),
                        ),
                        DropdownMenuItem(
                          value: _Location.foreign,
                          child: Text('Foreign'),
                        ),
                        DropdownMenuItem(
                          value: _Location.vpn,
                          child: Text('VPN'),
                        ),
                      ],
                      onChanged: (v) => v != null ? onLocation(v) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('Time of Day'),
                    DropdownButtonFormField<_Time>(
                      value: time,
                      decoration: _dec(null),
                      style: AppText.body(13, color: AppColors.ink),
                      items: const [
                        DropdownMenuItem(
                          value: _Time.business,
                          child: Text('Business Hrs'),
                        ),
                        DropdownMenuItem(
                          value: _Time.evening,
                          child: Text('Evening'),
                        ),
                        DropdownMenuItem(
                          value: _Time.lateNight,
                          child: Text('Late Night'),
                        ),
                      ],
                      onChanged: (v) => v != null ? onTime(v) : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _lbl('Merchant Type'),
                    DropdownButtonFormField<_Merchant>(
                      value: merchant,
                      decoration: _dec(null),
                      style: AppText.body(13, color: AppColors.ink),
                      items: const [
                        DropdownMenuItem(
                          value: _Merchant.regular,
                          child: Text('Regular'),
                        ),
                        DropdownMenuItem(
                          value: _Merchant.newMerchant,
                          child: Text('New Merchant'),
                        ),
                        DropdownMenuItem(
                          value: _Merchant.highRisk,
                          child: Text('High Risk'),
                        ),
                      ],
                      onChanged: (v) => v != null ? onMerchant(v) : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          GradientButton(
            label: 'Analyze Now',
            emoji: 'AI',
            loading: loading,
            onTap: onAnalyze,
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _Result result;
  final Color color;

  const _ResultCard({required this.result, required this.color});

  Color get _bg => color == AppColors.danger
      ? AppColors.dangerLight
      : color == AppColors.warn
          ? AppColors.warnLight
          : AppColors.safeLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: result.score / 100,
                        backgroundColor: color.withOpacity(0.12),
                        color: color,
                        strokeWidth: 6,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${result.score}%',
                            style: AppText.mono(14, color: color)),
                        Text('risk',
                            style: AppText.label(
                              9,
                              color: color.withOpacity(0.7),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.decision, style: AppText.h2(20, color: color)),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${result.amount.toStringAsFixed(2)}',
                      style: AppText.mono(14, color: AppColors.ink2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      result.score >= 70
                          ? 'Transaction automatically blocked by AI'
                          : result.score >= 35
                              ? 'Flagged for manual review'
                              : 'Transaction cleared and safe to proceed',
                      style: AppText.body(11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0x18000000), height: 1),
          const SizedBox(height: 12),
          Text('Factor Breakdown', style: AppText.h2(13)),
          const SizedBox(height: 10),
          ...result.factors.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: f.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f.text, style: AppText.body(12))),
                      Text(
                        '${(f.weight * 100).toInt()}%',
                        style: AppText.mono(10, color: f.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: f.weight,
                      backgroundColor: color.withOpacity(0.08),
                      color: f.color,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _Result result;
  final int index;

  const _HistoryCard({required this.result, required this.index});

  Color get _c => result.score >= 70
      ? AppColors.danger
      : result.score >= 35
          ? AppColors.warn
          : AppColors.safe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: result.score / 100,
                    backgroundColor: AppColors.card3,
                    color: _c,
                    strokeWidth: 4,
                  ),
                  Text('${result.score}%',
                      style: AppText.mono(10, color: _c)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.decision,
                    style:
                        AppText.body(14, color: _c, weight: FontWeight.w700),
                  ),
                  Text(
                    'RM ${result.amount.toStringAsFixed(2)} - Scan #${index + 1}',
                    style: AppText.label(11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _c.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${result.score}/100',
                  style: AppText.mono(11, color: _c)),
            ),
          ],
        ),
      ),
    );
  }
}
