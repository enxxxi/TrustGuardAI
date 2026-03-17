// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/common_widgets.dart';
import 'transaction_detail_screen.dart';

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
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _ringCtrl.forward();
  }

  @override
  void dispose() { _ringCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        _HeroHeader(ringAnim: _ringAnim),
        _FloatStats(),
        _AlertBanner(),
        _WeeklyChart(),
        _SpendBreakdown(),
        SectionHeader(
          title: 'Recent Transactions',
          action: 'See all',
          onAction: () => context.read<AppState>().setNav(1),
        ),
        _TransactionList(),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ─── Hero Header ────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final Animation<double> ringAnim;
  const _HeroHeader({required this.ringAnim});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppState>().unreadCount;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.dark1, AppColors.dark2],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 64),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: const Text('🛡️', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 9),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TrustGuard', style: AppText.display(17, color: Colors.white)),
              Text('AI Fraud Shield', style: AppText.body(10, color: AppColors.darkText)),
            ]),
          ]),
          GestureDetector(
            onTap: () => context.read<AppState>().setNav(2),
            child: Stack(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                alignment: Alignment.center,
                child: const Text('🔔', style: TextStyle(fontSize: 19)),
              ),
              if (unread > 0) Positioned(
                top: 5, right: 5,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dark1, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('$unread', style: AppText.mono(8, color: Colors.white, weight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 22),
        // Greeting
        Text('Good afternoon,', style: AppText.body(13, color: Colors.white54)),
        const SizedBox(height: 2),
        Text('Aisha Binti Razak 👋', style: AppText.display(22, color: Colors.white)),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.safe.withOpacity(0.3)),
            ),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.safe, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Protection Active', style: AppText.mono(10, color: AppColors.safe)),
            ]),
          ),
          const SizedBox(width: 8),
          Text('· Last scan 12s ago', style: AppText.body(11, color: Colors.white30)),
        ]),
        const SizedBox(height: 18),
        // Shield ring card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            border: Border.all(color: AppColors.darkBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            SizedBox(
              width: 76, height: 76,
              child: AnimatedBuilder(
                animation: ringAnim,
                builder: (_, __) => CustomPaint(
                  painter: _RingPainter(progress: ringAnim.value * 0.80),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('80%', style: AppText.mono(17, color: Colors.white, weight: FontWeight.w500)),
                    Text('safe', style: AppText.mono(8, color: Colors.white38)),
                  ])),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Protected ✓', style: AppText.display(15, color: AppColors.safe)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('XGBoost v2.4', style: AppText.mono(9, color: AppColors.accentMid)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('Real-time monitoring active. No threats detected in the last 30 minutes.',
                style: AppText.body(11, color: Colors.white54)),
              const SizedBox(height: 10),
              Row(children: [
                _MiniStat('96.4%', 'Accuracy', AppColors.safe),
                const SizedBox(width: 12),
                _MiniStat('1.2%', 'False +', AppColors.warn),
                const SizedBox(width: 12),
                _MiniStat('38ms', 'Latency', AppColors.accentMid),
              ]),
            ])),
          ]),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String val, label;
  final Color color;
  const _MiniStat(this.val, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(val, style: AppText.mono(12, color: color, weight: FontWeight.w600)),
    Text(label, style: AppText.body(9, color: Colors.white30)),
  ]);
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    canvas.drawCircle(center, radius, Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()
        ..color = AppColors.safe
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }
  @override bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Float Stats ────────────────────────────────────
class _FloatStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -34),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: IntrinsicHeight(child: Row(children: [
            Expanded(child: StatChip(value: '142', label: 'Approved', color: AppColors.safe, trend: '↑ +8 today')),
            Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Expanded(child: StatChip(value: '3', label: 'Flagged', color: AppColors.warn, trend: '↑ +1 hr')),
            Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Expanded(child: StatChip(value: '1', label: 'Blocked', color: AppColors.danger, trend: '⚠ High risk')),
            Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Expanded(child: StatChip(value: 'RM 906', label: 'Saved', color: AppColors.accent, trend: '✓ Protected')),
          ])),
        ),
      ),
    );
  }
}

// ─── Alert Banner ───────────────────────────────────
class _AlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () => context.read<AppState>().setNav(2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.danger.withOpacity(0.08), AppColors.dangerLight],
              begin: Alignment.centerLeft, end: Alignment.centerRight,
            ),
            border: Border.all(color: AppColors.danger.withOpacity(0.25)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: const Text('🚨', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Suspicious activity detected', style: AppText.body(13, color: AppColors.danger, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('RM 1,200 transaction blocked — new device from Indonesia. Tap to review.',
                style: AppText.body(11, color: AppColors.ink2)),
            ])),
            const Icon(Icons.chevron_right, color: AppColors.danger, size: 18),
          ]),
        ),
      ),
    );
  }
}

// ─── Weekly Chart ────────────────────────────────────
class _WeeklyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('This Week', style: AppText.display(15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
              child: Text('RM 906.00 total', style: AppText.mono(11, color: AppColors.accent, weight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 350,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: AppColors.ink,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${AppData.weekDays[group.x]}\nRM ${rod.toY.toInt()}',
                    AppText.mono(10, color: Colors.white),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) => Text(AppData.weekDays[v.toInt()],
                    style: AppText.body(10, color: AppColors.ink3)),
                )),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: AppData.weeklyVolumes.asMap().entries.map((e) => BarChartGroupData(
                x: e.key,
                barRods: [BarChartRodData(
                  toY: e.value,
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    colors: e.key == 6
                      ? [AppColors.accent, AppColors.accentMid]
                      : [AppColors.accent.withOpacity(0.3), AppColors.accent.withOpacity(0.15)],
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  ),
                )],
              )).toList(),
            )),
          ),
        ]),
      ),
    );
  }
}

// ─── Spend Breakdown ────────────────────────────────
class _SpendBreakdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Spending Breakdown', style: AppText.display(15)),
          const SizedBox(height: 14),
          ...AppData.spendCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(cat.name, style: AppText.body(12, weight: FontWeight.w500)),
                  Text('RM ${cat.amount.toStringAsFixed(0)}',
                    style: AppText.mono(12, color: AppColors.ink2, weight: FontWeight.w500)),
                ]),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: cat.pct, backgroundColor: AppColors.border,
                    color: cat.color, minHeight: 5,
                  ),
                ),
              ])),
              const SizedBox(width: 10),
              Text('${(cat.pct * 100).toInt()}%',
                style: AppText.mono(11, color: AppColors.ink3)),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ─── Transaction List ───────────────────────────────
class _TransactionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final txs = AppData.transactions.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: txs.map((tx) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(tx: tx))),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: switch (tx.status) {
                    TxStatus.approved => AppColors.accentLight,
                    TxStatus.flagged  => AppColors.warnLight,
                    TxStatus.blocked  => AppColors.dangerLight,
                  },
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(tx.emoji, style: const TextStyle(fontSize: 21)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tx.name, style: AppText.body(14, weight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Text(tx.platform, style: AppText.body(11, color: AppColors.ink3)),
                  Text(' · ${tx.time}', style: AppText.body(11, color: AppColors.ink3)),
                ]),
                const SizedBox(height: 4),
                RiskBadge(score: tx.riskScore),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('RM ${tx.amount.toStringAsFixed(2)}',
                  style: AppText.mono(14, weight: FontWeight.w600)),
                const SizedBox(height: 6),
                StatusPill(status: tx.status, score: tx.riskScore),
              ]),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}
