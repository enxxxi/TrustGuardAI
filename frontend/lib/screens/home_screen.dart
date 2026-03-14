// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
    _ringCtrl.forward();
  }

  @override
  void dispose() { _ringCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _HeroHeader(ringAnim: _ringAnim),
          _FloatStats(),
          _AlertBanner(),
          SectionHeader(title: 'Recent Transactions', action: 'See all'),
          _TransactionList(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Hero Header ──
class _HeroHeader extends StatelessWidget {
  final Animation<double> ringAnim;
  const _HeroHeader({required this.ringAnim});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.dark1, AppColors.dark2],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                  alignment: Alignment.center,
                  child: const Text('🛡️', style: TextStyle(fontSize: 17)),
                ),
                const SizedBox(width: 8),
                Text('TrustGuard', style: AppText.display(17, color: Colors.white)),
              ]),
              Stack(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🔔', style: TextStyle(fontSize: 18)),
                ),
                Positioned(
                  top: 7, right: 7,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.dark1, width: 1.5),
                    ),
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 24),
          // Greeting
          Text('Good afternoon,', style: AppText.body(13, color: Colors.white54)),
          const SizedBox(height: 2),
          Text('Aisha Binti Razak 👋', style: AppText.display(21, color: Colors.white)),
          const SizedBox(height: 18),
          // Shield score card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              border: Border.all(color: AppColors.darkBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 72, height: 72,
                  child: AnimatedBuilder(
                    animation: ringAnim,
                    builder: (_, __) => CustomPaint(
                      painter: _RingPainter(progress: ringAnim.value * 0.80),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('80%', style: AppText.mono(16, color: Colors.white, weight: FontWeight.w500)),
                            Text('safe', style: AppText.mono(8, color: Colors.white38)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Protected ✓', style: AppText.display(16, color: AppColors.safe)),
                      const SizedBox(height: 4),
                      Text(
                        'Your wallet is monitored in real-time. No threats detected.',
                        style: AppText.body(12, color: Colors.white54),
                      ),
                      const SizedBox(height: 6),
                      Text('Last scan: 12 seconds ago', style: AppText.mono(10, color: Colors.white24)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Ring painter
class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = AppColors.safe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Float Stats ──
class _FloatStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _StatCell(value: '142', label: 'Approved', color: AppColors.safe),
                _Divider(),
                _StatCell(value: '3', label: 'Flagged', color: AppColors.warn),
                _Divider(),
                _StatCell(value: '1', label: 'Blocked', color: AppColors.danger),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value, label;
  final Color color;
  const _StatCell({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Text(value, style: AppText.display(22, color: color)),
      const SizedBox(height: 4),
      Text(label, style: AppText.body(10, color: AppColors.ink3, weight: FontWeight.w500)),
    ]),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, margin: const EdgeInsets.symmetric(vertical: 8),
    color: AppColors.border,
  );
}

// ── Alert Banner ──
class _AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          border: Border.all(color: AppColors.danger.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Suspicious activity detected',
                    style: AppText.body(13, color: AppColors.danger, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('A transaction of RM 1,200 was blocked — unusual amount from new device.',
                    style: AppText.body(11, color: AppColors.ink2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Transaction List ──
class _TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: AppData.transactions.asMap().entries.map((e) {
          final tx = e.value;
          return _TxCard(tx: tx, delay: e.key * 50);
        }).toList(),
      ),
    );
  }
}

class _TxCard extends StatelessWidget {
  final Transaction tx;
  final int delay;
  const _TxCard({required this.tx, required this.delay});

  Color get _avatarBg => switch (tx.status) {
    TxStatus.approved => AppColors.accentLight,
    TxStatus.flagged  => AppColors.warnLight,
    TxStatus.blocked  => AppColors.dangerLight,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: _avatarBg, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Text(tx.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.name, style: AppText.body(14, weight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(tx.location, style: AppText.body(11, color: AppColors.ink3)),
                    Text(' · ${tx.time}', style: AppText.body(11, color: AppColors.ink3)),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('RM ${tx.amount.toStringAsFixed(2)}',
                  style: AppText.mono(14, weight: FontWeight.w500)),
                const SizedBox(height: 4),
                StatusPill(status: tx.status, score: tx.riskScore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
