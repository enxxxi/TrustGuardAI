// lib/screens/analyze_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

enum _DeviceType { known, newDevice, suspicious }
enum _LocationType { home, nearby, foreign, vpn }

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});
  @override State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen> {
  final _amountCtrl = TextEditingController(text: '150');
  _DeviceType _device = _DeviceType.known;
  _LocationType _location = _LocationType.home;

  int? _score;
  String? _decision;
  List<({String text, Color color})>? _factors;
  bool _isAnalyzing = false;

  Future<void> _analyze() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 150;
    setState(() { _isAnalyzing = true; });
    await Future.delayed(const Duration(milliseconds: 600));

    int score = 5;
    final factors = <({String text, Color color})>[];

    // Amount
    if (amount > 2000) { score += 40; factors.add((text: '⚠ Amount 13× above your average spend', color: AppColors.danger)); }
    else if (amount > 500) { score += 22; factors.add((text: '⚠ Transaction above typical range', color: AppColors.warn)); }
    else { factors.add((text: '✓ Amount within your normal range', color: AppColors.safe)); }

    // Device
    switch (_device) {
      case _DeviceType.suspicious: score += 35; factors.add((text: '⚠ Device flagged in fraud database', color: AppColors.danger));
      case _DeviceType.newDevice:  score += 18; factors.add((text: '◦ New unrecognized device detected', color: AppColors.warn));
      case _DeviceType.known: factors.add((text: '✓ Known and trusted device', color: AppColors.safe));
    }

    // Location
    switch (_location) {
      case _LocationType.vpn:     score += 30; factors.add((text: '⚠ VPN/proxy detected — high risk signal', color: AppColors.danger));
      case _LocationType.foreign: score += 22; factors.add((text: '⚠ Location outside your home region', color: AppColors.warn));
      case _LocationType.nearby:  score += 8;  factors.add((text: '◦ Nearby region — minor anomaly', color: AppColors.warn));
      case _LocationType.home: factors.add((text: '✓ Location matches home region', color: AppColors.safe));
    }

    score = score.clamp(2, 98);

    setState(() {
      _score = score;
      _factors = factors;
      _decision = score >= 70 ? '⛔  BLOCKED' : score >= 35 ? '⚑  FLAGGED' : '✓  APPROVED';
      _isAnalyzing = false;
    });
  }

  Color get _resultColor {
    if (_score == null) return AppColors.accent;
    if (_score! >= 70) return AppColors.danger;
    if (_score! >= 35) return AppColors.warn;
    return AppColors.safe;
  }

  Color get _resultBg {
    if (_score == null) return AppColors.accentLight;
    if (_score! >= 70) return AppColors.dangerLight;
    if (_score! >= 35) return AppColors.warnLight;
    return AppColors.safeLight;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _ScanHero(),
          _AnalyzerCard(
            amountCtrl: _amountCtrl,
            device: _device,
            location: _location,
            isAnalyzing: _isAnalyzing,
            onDeviceChanged: (v) => setState(() => _device = v),
            onLocationChanged: (v) => setState(() => _location = v),
            onAnalyze: _analyze,
          ),
          if (_score != null) ...[
            const SizedBox(height: 16),
            _ResultCard(
              score: _score!,
              decision: _decision!,
              factors: _factors!,
              resultColor: _resultColor,
              resultBg: _resultBg,
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Scan Hero ──
class _ScanHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 76),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF0D1F3C)],
        ),
      ),
      child: Column(
        children: [
          Row(children: [
            Text('Analyze Transaction', style: AppText.display(18, color: Colors.white)),
          ]),
          const SizedBox(height: 20),
          const Text('🛡️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 8),
          Text('Real-time fraud risk scoring',
            style: AppText.body(13, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ── Analyzer Card ──
class _AnalyzerCard extends StatelessWidget {
  final TextEditingController amountCtrl;
  final _DeviceType device;
  final _LocationType location;
  final bool isAnalyzing;
  final ValueChanged<_DeviceType> onDeviceChanged;
  final ValueChanged<_LocationType> onLocationChanged;
  final VoidCallback onAnalyze;

  const _AnalyzerCard({
    required this.amountCtrl, required this.device, required this.location,
    required this.isAnalyzing, required this.onDeviceChanged,
    required this.onLocationChanged, required this.onAnalyze,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -48),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          radius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel('Transaction Amount (MYR)'),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                style: AppText.body(15),
                decoration: _inputDec('e.g. 150.00'),
              ),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Device'),
                    DropdownButtonFormField<_DeviceType>(
                      value: device,
                      decoration: _inputDec(null),
                      style: AppText.body(14),
                      items: const [
                        DropdownMenuItem(value: _DeviceType.known, child: Text('Known Device')),
                        DropdownMenuItem(value: _DeviceType.newDevice, child: Text('New Device')),
                        DropdownMenuItem(value: _DeviceType.suspicious, child: Text('Suspicious')),
                      ],
                      onChanged: (v) => v != null ? onDeviceChanged(v) : null,
                    ),
                  ],
                )),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Location'),
                    DropdownButtonFormField<_LocationType>(
                      value: location,
                      decoration: _inputDec(null),
                      style: AppText.body(14),
                      items: const [
                        DropdownMenuItem(value: _LocationType.home, child: Text('Home (MY)')),
                        DropdownMenuItem(value: _LocationType.nearby, child: Text('Nearby (SG)')),
                        DropdownMenuItem(value: _LocationType.foreign, child: Text('Foreign')),
                        DropdownMenuItem(value: _LocationType.vpn, child: Text('VPN')),
                      ],
                      onChanged: (v) => v != null ? onLocationChanged(v) : null,
                    ),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isAnalyzing ? null : onAnalyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 4,
                    shadowColor: AppColors.accent.withOpacity(0.35),
                  ),
                  child: isAnalyzing
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('🔍  Analyze Now', style: AppText.display(16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String? hint) => InputDecoration(
    hintText: hint,
    hintStyle: AppText.body(14, color: AppColors.ink3),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    isDense: true,
  );
}

Widget _FieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text.toUpperCase(),
    style: AppText.mono(9, color: AppColors.ink3, weight: FontWeight.w500).copyWith(letterSpacing: 1)),
);

// ── Result Card ──
class _ResultCard extends StatelessWidget {
  final int score;
  final String decision;
  final List<({String text, Color color})> factors;
  final Color resultColor, resultBg;

  const _ResultCard({
    required this.score, required this.decision,
    required this.factors, required this.resultColor, required this.resultBg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: resultBg,
          border: Border.all(color: resultColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Gauge
                SizedBox(
                  width: 64, height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64, height: 64,
                        child: CircularProgressIndicator(
                          value: score / 100,
                          backgroundColor: Colors.black.withOpacity(0.08),
                          color: resultColor,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text('$score%', style: AppText.mono(13, color: resultColor, weight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(decision, style: AppText.display(20, color: resultColor)),
                      const SizedBox(height: 4),
                      Text('Risk Score: $score / 100', style: AppText.mono(12, color: AppColors.ink2)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Color(0x18000000), height: 1),
            const SizedBox(height: 10),
            ...factors.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: f.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f.text, style: AppText.body(12, color: AppColors.ink2))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
