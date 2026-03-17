// lib/screens/analyze_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

enum _DeviceType { known, newDevice, suspicious }
enum _LocationType { home, nearby, foreign, vpn }
enum _TimeType { business, evening, lateNight }
enum _MerchantType { regular, newMerchant, highRisk }

class _ScanResult {
  final int score;
  final String decision;
  final List<_Factor> factors;
  final double amount;
  _ScanResult({required this.score, required this.decision, required this.factors, required this.amount});
}

class _Factor {
  final String icon, text;
  final Color color;
  final double weight;
  _Factor(this.icon, this.text, this.color, {this.weight = 0});
}

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});
  @override State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> with SingleTickerProviderStateMixin {
  final _amountCtrl = TextEditingController(text: '150');
  _DeviceType _device = _DeviceType.known;
  _LocationType _location = _LocationType.home;
  _TimeType _time = _TimeType.business;
  _MerchantType _merchant = _MerchantType.regular;

  _ScanResult? _result;
  bool _isAnalyzing = false;
  final List<_ScanResult> _history = [];

  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); _amountCtrl.dispose(); super.dispose(); }

  Future<void> _analyze() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 150;
    setState(() { _isAnalyzing = true; _result = null; });
    await Future.delayed(const Duration(milliseconds: 800));

    int score = 5;
    final factors = <_Factor>[];

    // Amount scoring
    double amtWeight = 0;
    if (amount > 3000)      { score += 45; amtWeight = 0.95; factors.add(_Factor('💰', 'Amount is ${(amount/52).toStringAsFixed(0)}× your average — extreme anomaly', AppColors.danger, weight: amtWeight)); }
    else if (amount > 1000) { score += 28; amtWeight = 0.70; factors.add(_Factor('💰', 'Amount is ${(amount/52).toStringAsFixed(0)}× above your average spend', AppColors.danger, weight: amtWeight)); }
    else if (amount > 300)  { score += 14; amtWeight = 0.40; factors.add(_Factor('⚠', 'Transaction moderately above baseline', AppColors.warn, weight: amtWeight)); }
    else { amtWeight = 0.10; factors.add(_Factor('✓', 'Amount is within normal spending range', AppColors.safe, weight: amtWeight)); }

    // Device scoring
    double devWeight = 0;
    switch (_device) {
      case _DeviceType.suspicious: score += 38; devWeight = 0.90; factors.add(_Factor('📵', 'Device is flagged in fraud database', AppColors.danger, weight: devWeight));
      case _DeviceType.newDevice:  score += 20; devWeight = 0.55; factors.add(_Factor('📱', 'Unrecognized device — first time seen', AppColors.warn, weight: devWeight));
      case _DeviceType.known: devWeight = 0.05; factors.add(_Factor('✓', 'Known and verified device', AppColors.safe, weight: devWeight));
    }

    // Location scoring
    double locWeight = 0;
    switch (_location) {
      case _LocationType.vpn:     score += 32; locWeight = 0.92; factors.add(_Factor('🌐', 'VPN / proxy detected — identity masking', AppColors.danger, weight: locWeight));
      case _LocationType.foreign: score += 24; locWeight = 0.75; factors.add(_Factor('🗺', 'Geographic anomaly: IP outside wallet region', AppColors.danger, weight: locWeight));
      case _LocationType.nearby:  score += 9;  locWeight = 0.30; factors.add(_Factor('📍', 'Nearby region — minor geographic deviation', AppColors.warn, weight: locWeight));
      case _LocationType.home:    locWeight = 0.05; factors.add(_Factor('✓', 'Location matches your home region', AppColors.safe, weight: locWeight));
    }

    // Time scoring
    double timeWeight = 0;
    switch (_time) {
      case _TimeType.lateNight: score += 18; timeWeight = 0.65; factors.add(_Factor('🌙', 'Late-night activity (12AM–5AM) — high-risk window', AppColors.danger, weight: timeWeight));
      case _TimeType.evening:   score += 5;  timeWeight = 0.20; factors.add(_Factor('🌆', 'Evening transaction — slightly elevated risk', AppColors.warn, weight: timeWeight));
      case _TimeType.business:  timeWeight = 0.05; factors.add(_Factor('✓', 'Business hours — normal activity window', AppColors.safe, weight: timeWeight));
    }

    // Merchant scoring
    double merWeight = 0;
    switch (_merchant) {
      case _MerchantType.highRisk:   score += 20; merWeight = 0.70; factors.add(_Factor('🏪', 'High-risk merchant category detected', AppColors.danger, weight: merWeight));
      case _MerchantType.newMerchant: score += 8; merWeight = 0.30; factors.add(_Factor('🏬', 'First transaction with this merchant', AppColors.warn, weight: merWeight));
      case _MerchantType.regular:    merWeight = 0.05; factors.add(_Factor('✓', 'Regular, trusted merchant', AppColors.safe, weight: merWeight));
    }

    score = score.clamp(2, 99);

    final decision = score >= 70 ? '⛔  BLOCKED' : score >= 35 ? '⚑  FLAGGED' : '✓  APPROVED';

    final res = _ScanResult(score: score, decision: decision, factors: factors, amount: amount);
    setState(() {
      _result = res;
      _isAnalyzing = false;
      _history.insert(0, res);
      if (_history.length > 10) _history.removeLast();
    });
  }

  Color get _color {
    final s = _result?.score ?? 0;
    if (s >= 70) return AppColors.danger;
    if (s >= 35) return AppColors.warn;
    return AppColors.safe;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Tab bar header
      Container(
        color: AppColors.card,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Analyze Transaction', style: AppText.display(22)),
          const SizedBox(height: 4),
          Text('Real-time AI fraud risk scoring', style: AppText.body(13, color: AppColors.ink3)),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabCtrl,
            labelStyle: AppText.body(13, weight: FontWeight.w600),
            unselectedLabelStyle: AppText.body(13),
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.ink3,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2.5,
            tabs: [
              const Tab(text: '🔍  New Scan'),
              Tab(text: '📋  History (${_history.length})'),
            ],
          ),
        ]),
      ),

      Expanded(child: TabBarView(
        controller: _tabCtrl,
        children: [
          // Scan tab
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _InputCard(
                amountCtrl: _amountCtrl,
                device: _device, location: _location,
                time: _time, merchant: _merchant,
                onDevice: (v) => setState(() => _device = v),
                onLocation: (v) => setState(() => _location = v),
                onTime: (v) => setState(() => _time = v),
                onMerchant: (v) => setState(() => _merchant = v),
                isAnalyzing: _isAnalyzing,
                onAnalyze: _analyze,
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                _ResultCard(result: _result!, color: _color),
              ],
              const SizedBox(height: 32),
            ]),
          ),

          // History tab
          _history.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('📋', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text('No scans yet', style: AppText.body(14, color: AppColors.ink3)),
                const SizedBox(height: 4),
                Text('Run a scan to see history', style: AppText.body(12, color: AppColors.ink3)),
              ]))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: _history.length,
                itemBuilder: (_, i) => _HistoryCard(result: _history[i], index: i),
              ),
        ],
      )),
    ]);
  }
}

// ── Input Card ──────────────────────────────────────
class _InputCard extends StatelessWidget {
  final TextEditingController amountCtrl;
  final _DeviceType device;
  final _LocationType location;
  final _TimeType time;
  final _MerchantType merchant;
  final ValueChanged<_DeviceType> onDevice;
  final ValueChanged<_LocationType> onLocation;
  final ValueChanged<_TimeType> onTime;
  final ValueChanged<_MerchantType> onMerchant;
  final bool isAnalyzing;
  final VoidCallback onAnalyze;

  const _InputCard({
    required this.amountCtrl, required this.device, required this.location,
    required this.time, required this.merchant,
    required this.onDevice, required this.onLocation,
    required this.onTime, required this.onMerchant,
    required this.isAnalyzing, required this.onAnalyze,
  });

  InputDecoration _dec(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(14, color: AppColors.ink3),
    filled: true, fillColor: AppColors.card2,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    isDense: true,
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t.toUpperCase(), style: AppText.mono(9, color: AppColors.ink3).copyWith(letterSpacing: 1)),
  );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Transaction Amount (MYR)'),
        TextField(controller: amountCtrl, keyboardType: TextInputType.number,
          style: AppText.body(15), decoration: _dec('e.g. 150.00')),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Device'),
            DropdownButtonFormField<_DeviceType>(
              value: device, decoration: _dec(null), style: AppText.body(13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: _DeviceType.known, child: Text('Known Device')),
                DropdownMenuItem(value: _DeviceType.newDevice, child: Text('New Device')),
                DropdownMenuItem(value: _DeviceType.suspicious, child: Text('Suspicious')),
              ],
              onChanged: (v) => v != null ? onDevice(v) : null,
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Location'),
            DropdownButtonFormField<_LocationType>(
              value: location, decoration: _dec(null), style: AppText.body(13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: _LocationType.home, child: Text('Home (MY)')),
                DropdownMenuItem(value: _LocationType.nearby, child: Text('Nearby (SG)')),
                DropdownMenuItem(value: _LocationType.foreign, child: Text('Foreign')),
                DropdownMenuItem(value: _LocationType.vpn, child: Text('VPN')),
              ],
              onChanged: (v) => v != null ? onLocation(v) : null,
            ),
          ])),
        ]),
        const SizedBox(height: 14),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Time of Day'),
            DropdownButtonFormField<_TimeType>(
              value: time, decoration: _dec(null), style: AppText.body(13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: _TimeType.business, child: Text('Business Hrs')),
                DropdownMenuItem(value: _TimeType.evening, child: Text('Evening')),
                DropdownMenuItem(value: _TimeType.lateNight, child: Text('Late Night')),
              ],
              onChanged: (v) => v != null ? onTime(v) : null,
            ),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Merchant Type'),
            DropdownButtonFormField<_MerchantType>(
              value: merchant, decoration: _dec(null), style: AppText.body(13, color: AppColors.ink),
              items: const [
                DropdownMenuItem(value: _MerchantType.regular, child: Text('Regular')),
                DropdownMenuItem(value: _MerchantType.newMerchant, child: Text('New Merchant')),
                DropdownMenuItem(value: _MerchantType.highRisk, child: Text('High Risk')),
              ],
              onChanged: (v) => v != null ? onMerchant(v) : null,
            ),
          ])),
        ]),
        const SizedBox(height: 18),

        GradientButton(
          label: 'Analyze Now',
          emoji: '🔍',
          loading: isAnalyzing,
          onTap: onAnalyze,
        ),
      ]),
    );
  }
}

// ── Result Card ─────────────────────────────────────
class _ResultCard extends StatelessWidget {
  final _ScanResult result;
  final Color color;
  const _ResultCard({required this.result, required this.color});

  Color get _bg {
    if (result.score >= 70) return AppColors.dangerLight;
    if (result.score >= 35) return AppColors.warnLight;
    return AppColors.safeLight;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        // Score row
        Row(children: [
          SizedBox(width: 72, height: 72,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(width: 72, height: 72,
                child: CircularProgressIndicator(
                  value: result.score / 100,
                  backgroundColor: Colors.black.withOpacity(0.08),
                  color: color, strokeWidth: 6, strokeCap: StrokeCap.round,
                )),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${result.score}%', style: AppText.mono(15, color: color, weight: FontWeight.w700)),
                Text('risk', style: AppText.body(9, color: color.withOpacity(0.7))),
              ]),
            ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.decision, style: AppText.display(20, color: color)),
            const SizedBox(height: 4),
            Text('RM ${result.amount.toStringAsFixed(2)}',
              style: AppText.mono(14, color: AppColors.ink2, weight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(result.score >= 70 ? 'Transaction automatically blocked by AI'
              : result.score >= 35 ? 'Flagged for manual review'
              : 'Cleared — safe to proceed',
              style: AppText.body(11, color: AppColors.ink2)),
          ])),
        ]),

        const SizedBox(height: 14),
        const Divider(color: Color(0x18000000), height: 1),
        const SizedBox(height: 12),

        // Factor weight bars
        Text('Factor Breakdown', style: AppText.display(13)),
        const SizedBox(height: 10),
        ...result.factors.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 6, height: 6,
                decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(f.text, style: AppText.body(12, color: AppColors.ink2))),
              Text('${(f.weight * 100).toInt()}%', style: AppText.mono(10, color: f.color, weight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: f.weight,
                backgroundColor: Colors.black.withOpacity(0.08),
                color: f.color,
                minHeight: 4,
              ),
            ),
          ]),
        )),
      ]),
    );
  }
}

// ── History Card ────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final _ScanResult result;
  final int index;
  const _HistoryCard({required this.result, required this.index});

  Color get _color {
    if (result.score >= 70) return AppColors.danger;
    if (result.score >= 35) return AppColors.warn;
    return AppColors.safe;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          SizedBox(width: 48, height: 48,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: result.score / 100,
                backgroundColor: AppColors.border,
                color: _color, strokeWidth: 4,
              ),
              Text('${result.score}%', style: AppText.mono(10, color: _color, weight: FontWeight.w700)),
            ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.decision, style: AppText.body(14, weight: FontWeight.w700, color: _color)),
            Text('RM ${result.amount.toStringAsFixed(2)} · Scan #${index + 1}',
              style: AppText.mono(11, color: AppColors.ink3)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${result.score}/100', style: AppText.mono(11, color: _color, weight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}
