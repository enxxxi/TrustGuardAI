// lib/screens/analyze_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
 
enum _Device   { known, newDevice, suspicious }
enum _Location { home, nearby, foreign, vpn }
enum _Time     { business, evening, lateNight }
enum _Merchant { regular, newMerchant, highRisk }
 
class _Result {
  final int score;
  final String decision;
  final double amount;
  final List<({String icon, String text, Color color, double weight})> factors;
  _Result({required this.score, required this.decision, required this.amount, required this.factors});
}
 
class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});
  @override State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}
 
class _AnalyzeScreenState extends State<AnalyzeScreen> with SingleTickerProviderStateMixin {
  final _amtCtrl = TextEditingController(text: '150');
  _Device   _device   = _Device.known;
  _Location _location = _Location.home;
  _Time     _time     = _Time.business;
  _Merchant _merchant = _Merchant.regular;
  _Result? _result;
  bool _loading = false;
  final _history = <_Result>[];
  late TabController _tab;
 
  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose()   { _tab.dispose(); _amtCtrl.dispose(); super.dispose(); }
 
  Future<void> _analyze() async {
    final amt = double.tryParse(_amtCtrl.text) ?? 150;
    setState(() { _loading = true; _result = null; });
    await Future.delayed(const Duration(milliseconds: 700));
 
    int score = 5;
    final factors = <({String icon, String text, Color color, double weight})>[];
 
    if      (amt > 3000) { score += 45; factors.add((icon:'💰', text:'Amount is ${(amt/52).toStringAsFixed(0)}× your average — extreme anomaly', color:AppColors.danger, weight:0.95)); }
    else if (amt > 1000) { score += 28; factors.add((icon:'💰', text:'Amount is ${(amt/52).toStringAsFixed(0)}× above your average spend of RM 52', color:AppColors.danger, weight:0.70)); }
    else if (amt > 300)  { score += 14; factors.add((icon:'⚠',  text:'Transaction is moderately above your daily baseline', color:AppColors.warn, weight:0.40)); }
    else                 {              factors.add((icon:'✓',  text:'Amount is within your normal spending range', color:AppColors.safe, weight:0.10)); }
 
    switch (_device) {
      case _Device.suspicious: score += 38; factors.add((icon:'📵', text:'Device is flagged in the fraud database', color:AppColors.danger, weight:0.90));
      case _Device.newDevice:  score += 20; factors.add((icon:'📱', text:'Unrecognized device — first seen today', color:AppColors.warn, weight:0.55));
      case _Device.known:                   factors.add((icon:'✓',  text:'Known and verified device', color:AppColors.safe, weight:0.05));
    }
    switch (_location) {
      case _Location.vpn:     score += 32; factors.add((icon:'🌐', text:'VPN or proxy detected — possible identity masking', color:AppColors.danger, weight:0.92));
      case _Location.foreign: score += 24; factors.add((icon:'🗺',  text:'Geographic anomaly: IP is outside your wallet region', color:AppColors.danger, weight:0.75));
      case _Location.nearby:  score += 9;  factors.add((icon:'📍', text:'Nearby region — minor geographic deviation', color:AppColors.warn, weight:0.30));
      case _Location.home:                 factors.add((icon:'✓',  text:'Location matches your registered home region', color:AppColors.safe, weight:0.05));
    }
    switch (_time) {
      case _Time.lateNight: score += 18; factors.add((icon:'🌙', text:'Late-night transaction (12AM–5AM) — high-risk window', color:AppColors.danger, weight:0.65));
      case _Time.evening:   score += 5;  factors.add((icon:'🌆', text:'Evening transaction — slightly elevated risk', color:AppColors.warn, weight:0.20));
      case _Time.business:               factors.add((icon:'✓',  text:'Business hours — within your normal activity window', color:AppColors.safe, weight:0.05));
    }
    switch (_merchant) {
      case _Merchant.highRisk:    score += 20; factors.add((icon:'🏪', text:'High-risk merchant category detected', color:AppColors.danger, weight:0.70));
      case _Merchant.newMerchant: score += 8;  factors.add((icon:'🏬', text:'First transaction with this merchant', color:AppColors.warn, weight:0.30));
      case _Merchant.regular:                  factors.add((icon:'✓',  text:'Regular, trusted merchant', color:AppColors.safe, weight:0.05));
    }
 
    score = score.clamp(2, 99);
    final res = _Result(
      score: score,
      decision: score >= 70 ? '✕  BLOCKED' : score >= 35 ? '⚑  FLAGGED' : '✓  APPROVED',
      amount: amt, factors: factors,
    );
    setState(() { _result = res; _loading = false; _history.insert(0, res); if (_history.length > 10) _history.removeLast(); });
  }
 
  Color get _rc { final s = _result?.score ?? 0; return s >= 70 ? AppColors.danger : s >= 35 ? AppColors.warn : AppColors.safe; }
 
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: AppColors.card,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Analyze Transaction', style: AppText.h1(22)),
          const SizedBox(height: 2),
          Text('Real-time AI fraud risk scoring', style: AppText.label(13)),
          const SizedBox(height: 14),
          TabBar(
            controller: _tab,
            labelStyle: AppText.label(13, weight: FontWeight.w700),
            unselectedLabelStyle: AppText.label(13),
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.ink3,
            indicatorColor: AppColors.accent,
            indicatorWeight: 2,
            tabs: [const Tab(text: 'New Scan'), Tab(text: 'History (${_history.length})')],
          ),
        ]),
      ),
      Expanded(child: TabBarView(controller: _tab, children: [
        // Scan tab
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _InputCard(amtCtrl: _amtCtrl, device: _device, location: _location,
              time: _time, merchant: _merchant,
              onDevice: (v) => setState(() => _device = v),
              onLocation: (v) => setState(() => _location = v),
              onTime: (v) => setState(() => _time = v),
              onMerchant: (v) => setState(() => _merchant = v),
              loading: _loading, onAnalyze: _analyze),
            if (_result != null) ...[const SizedBox(height: 16), _ResultCard(result: _result!, color: _rc)],
            const SizedBox(height: 32),
          ]),
        ),
        // History tab
        _history.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.history_rounded, size: 48, color: AppColors.ink4),
              const SizedBox(height: 12),
              Text('No scans yet', style: AppText.h2(16, color: AppColors.ink3)),
              const SizedBox(height: 4),
              Text('Run a scan to see history here', style: AppText.label(13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.all(16), physics: const BouncingScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (_, i) => _HistoryCard(result: _history[i], index: i)),
      ])),
    ]);
  }
}
 
class _InputCard extends StatelessWidget {
  final TextEditingController amtCtrl;
  final _Device device; final _Location location;
  final _Time time; final _Merchant merchant;
  final ValueChanged<_Device> onDevice;
  final ValueChanged<_Location> onLocation;
  final ValueChanged<_Time> onTime;
  final ValueChanged<_Merchant> onMerchant;
  final bool loading; final VoidCallback onAnalyze;
  const _InputCard({required this.amtCtrl, required this.device, required this.location,
    required this.time, required this.merchant, required this.onDevice, required this.onLocation,
    required this.onTime, required this.onMerchant, required this.loading, required this.onAnalyze});
 
  Widget _lbl(String t) => Padding(padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: AppText.label(11, weight: FontWeight.w600)));
 
  InputDecoration _dec(String? hint) => InputDecoration(
    hintText: hint, hintStyle: AppText.label(14),
    filled: true, fillColor: AppColors.card2,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), isDense: true,
  );
 
  @override
  Widget build(BuildContext context) {
    return AppCard(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _lbl('Transaction Amount (MYR)'),
      TextField(controller: amtCtrl, keyboardType: TextInputType.number,
        style: AppText.body(15, color: AppColors.ink), decoration: _dec('e.g. 150.00')),
      const SizedBox(height: 14),
      // Use LayoutBuilder so dropdowns never overflow on small phones
      LayoutBuilder(builder: (context, constraints) {
        final useRow = constraints.maxWidth > 280;
        Widget deviceField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Device'),
          DropdownButtonFormField<_Device>(value: device, decoration: _dec(null),
            isExpanded: true,
            style: AppText.body(13, color: AppColors.ink),
            items: const [
              DropdownMenuItem(value: _Device.known, child: Text('Known Device')),
              DropdownMenuItem(value: _Device.newDevice, child: Text('New Device')),
              DropdownMenuItem(value: _Device.suspicious, child: Text('Suspicious')),
            ], onChanged: (v) => v != null ? onDevice(v) : null),
        ]);
        Widget locationField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Location'),
          DropdownButtonFormField<_Location>(value: location, decoration: _dec(null),
            isExpanded: true,
            style: AppText.body(13, color: AppColors.ink),
            items: const [
              DropdownMenuItem(value: _Location.home, child: Text('Home (MY)')),
              DropdownMenuItem(value: _Location.nearby, child: Text('Nearby (SG)')),
              DropdownMenuItem(value: _Location.foreign, child: Text('Foreign')),
              DropdownMenuItem(value: _Location.vpn, child: Text('VPN')),
            ], onChanged: (v) => v != null ? onLocation(v) : null),
        ]);
        return useRow
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: deviceField), const SizedBox(width: 10), Expanded(child: locationField)])
          : Column(children: [deviceField, const SizedBox(height: 10), locationField]);
      }),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, constraints) {
        final useRow = constraints.maxWidth > 280;
        Widget timeField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Time of Day'),
          DropdownButtonFormField<_Time>(value: time, decoration: _dec(null),
            isExpanded: true,
            style: AppText.body(13, color: AppColors.ink),
            items: const [
              DropdownMenuItem(value: _Time.business, child: Text('Business Hrs')),
              DropdownMenuItem(value: _Time.evening, child: Text('Evening')),
              DropdownMenuItem(value: _Time.lateNight, child: Text('Late Night')),
            ], onChanged: (v) => v != null ? onTime(v) : null),
        ]);
        Widget merchantField = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl('Merchant Type'),
          DropdownButtonFormField<_Merchant>(value: merchant, decoration: _dec(null),
            isExpanded: true,
            style: AppText.body(13, color: AppColors.ink),
            items: const [
              DropdownMenuItem(value: _Merchant.regular, child: Text('Regular')),
              DropdownMenuItem(value: _Merchant.newMerchant, child: Text('New Merchant')),
              DropdownMenuItem(value: _Merchant.highRisk, child: Text('High Risk')),
            ], onChanged: (v) => v != null ? onMerchant(v) : null),
        ]);
        return useRow
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: timeField), const SizedBox(width: 10), Expanded(child: merchantField)])
          : Column(children: [timeField, const SizedBox(height: 10), merchantField]);
      }),
      const SizedBox(height: 18),
      GradientButton(label: 'Analyze Now', emoji: '🔍', loading: loading, onTap: onAnalyze),
    ]));
  }
}
 
class _ResultCard extends StatelessWidget {
  final _Result result; final Color color;
  const _ResultCard({required this.result, required this.color});
 
  Color get _bg => color == AppColors.danger ? AppColors.dangerLight
    : color == AppColors.warn ? AppColors.warnLight : AppColors.safeLight;
 
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 68, height: 68, child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 68, height: 68, child: CircularProgressIndicator(
              value: result.score / 100, backgroundColor: color.withOpacity(0.12),
              color: color, strokeWidth: 6, strokeCap: StrokeCap.round)),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('${result.score}%', style: AppText.mono(14, color: color)),
              Text('risk', style: AppText.label(9, color: color.withOpacity(0.7))),
            ]),
          ])),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(result.decision, style: AppText.h2(20, color: color)),
            const SizedBox(height: 4),
            Text('RM ${result.amount.toStringAsFixed(2)}',
              style: AppText.mono(14, color: AppColors.ink2)),
            const SizedBox(height: 6),
            Text(result.score >= 70 ? 'Transaction automatically blocked by AI'
              : result.score >= 35 ? 'Flagged for manual review'
              : 'Transaction cleared — safe to proceed',
              style: AppText.body(11)),
          ])),
        ]),
        const SizedBox(height: 14),
        const Divider(color: Color(0x18000000), height: 1),
        const SizedBox(height: 12),
        Text('Factor Breakdown', style: AppText.h2(13)),
        const SizedBox(height: 10),
        ...result.factors.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: f.color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Text(f.text, style: AppText.body(12))),
              Text('${(f.weight * 100).toInt()}%',
                style: AppText.mono(10, color: f.color)),
            ]),
            const SizedBox(height: 4),
            ClipRRect(borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: f.weight,
                backgroundColor: color.withOpacity(0.08), color: f.color, minHeight: 4)),
          ]),
        )),
      ]),
    );
  }
}
 
class _HistoryCard extends StatelessWidget {
  final _Result result; final int index;
  const _HistoryCard({required this.result, required this.index});
  Color get _c => result.score >= 70 ? AppColors.danger : result.score >= 35 ? AppColors.warn : AppColors.safe;
 
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: AppCard(padding: const EdgeInsets.all(14), child: Row(children: [
      SizedBox(width: 48, height: 48, child: Stack(alignment: Alignment.center, children: [
        CircularProgressIndicator(value: result.score / 100,
          backgroundColor: AppColors.card3, color: _c, strokeWidth: 4),
        Text('${result.score}%', style: AppText.mono(10, color: _c)),
      ])),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(result.decision, style: AppText.body(14, color: _c, weight: FontWeight.w700)),
        Text('RM ${result.amount.toStringAsFixed(2)} · Scan #${index + 1}',
          style: AppText.label(11)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: _c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text('${result.score}/100', style: AppText.mono(11, color: _c)),
      ),
    ])),
  );
}