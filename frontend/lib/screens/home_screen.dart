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
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        _HeroSection(anim: _anim),
        _KpiRow(),
        _ActiveAlertBanner(),
        _WeeklyCard(),
        _SpendCard(),
        SectionHeader(
          title: 'Recent Transactions',
          action: 'View all',
          onAction: () => context.read<AppState>().setNav(1),
        ),
        _RecentList(),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Hero ─────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final Animation<double> anim;
  const _HeroSection({required this.anim});

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppState>().unreadCount;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.dark1, AppColors.dark2]),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 56),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentMid]),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('🛡️', style: TextStyle(fontSize: 17)),
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TrustGuard', style: AppText.h2(16, color: Colors.white)),
              Text('AI Fraud Shield', style: AppText.label(10, color: AppColors.darkText)),
            ]),
          ]),
          GestureDetector(
            onTap: () => context.read<AppState>().setNav(3),
            child: Stack(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                alignment: Alignment.center,
                child: const Text('🔔', style: TextStyle(fontSize: 18)),
              ),
              if (unread > 0) Positioned(
                top: 6, right: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.danger, shape: BoxShape.circle,
                    border: Border.all(color: AppColors.dark1, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text('$unread', style: AppText.tag(8, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: 20),
        Text('Good afternoon,', style: AppText.body(13, color: AppColors.darkText)),
        const SizedBox(height: 2),
        Text('Aisha Binti Razak 👋', style: AppText.h1(22, color: Colors.white)),
        const SizedBox(height: 14),

        // Protection card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(children: [
            SizedBox(
              width: 72, height: 72,
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) => CustomPaint(
                  painter: _RingPainter(progress: anim.value * 0.80),
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('80%', style: AppText.mono(16, color: Colors.white)),
                    Text('safe', style: AppText.label(8, color: AppColors.darkText)),
                  ])),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.safe.withOpacity(0.35)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                      decoration: const BoxDecoration(color: AppColors.safe, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('Protected', style: AppText.tag(9, color: AppColors.safe)),
                  ]),
                ),
                const Spacer(),
                Text('XGBoost v2.4', style: AppText.label(9, color: AppColors.darkText2)),
              ]),
              const SizedBox(height: 8),
              Text('Real-time monitoring active. No threats detected in the last 30 minutes.',
                style: AppText.body(11, color: AppColors.darkText)),
              const SizedBox(height: 10),
              Row(children: [
                _MicroStat('96.4%', 'Accuracy', AppColors.safe),
                Container(width: 1, height: 20, color: AppColors.darkBorder, margin: const EdgeInsets.symmetric(horizontal: 10)),
                _MicroStat('1.2%', 'False +', AppColors.warn),
                Container(width: 1, height: 20, color: AppColors.darkBorder, margin: const EdgeInsets.symmetric(horizontal: 10)),
                _MicroStat('38ms', 'Latency', AppColors.accentMid),
              ]),
            ])),
          ]),
        ),
      ]),
    );
  }
}

class _MicroStat extends StatelessWidget {
  final String val, label;
  final Color color;
  const _MicroStat(this.val, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(val, style: AppText.mono(12, color: color)),
    Text(label, style: AppText.label(9, color: AppColors.darkText2)),
  ]);
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke..strokeWidth = 6);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r),
      -math.pi / 2, 2 * math.pi * progress, false,
      Paint()..color = AppColors.safe..style = PaintingStyle.stroke
        ..strokeWidth = 6..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

// ── KPI Row ──────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.6)),
            boxShadow: AppShadow.elevated,
          ),
          child: IntrinsicHeight(child: Row(children: [
            Expanded(child: StatChip(value: '142', label: 'Approved', color: AppColors.safe, sub: '↑ +8')),
            _VDivider(), Expanded(child: StatChip(value: '3', label: 'Flagged', color: AppColors.warn, sub: '↑ +1')),
            _VDivider(), Expanded(child: StatChip(value: '1', label: 'Blocked', color: AppColors.danger, sub: '⚠ High')),
            _VDivider(), Expanded(child: StatChip(value: 'RM 906', label: 'Saved', color: AppColors.accent, sub: '✓')),
          ])),
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 12));
}

// ── Alert Banner ─────────────────────────────────────
class _ActiveAlertBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () => context.read<AppState>().setNav(3),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.danger.withOpacity(0.2)),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text('🚨', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Suspicious activity detected',
                style: AppText.body(13, color: AppColors.danger, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('RM 1,200 blocked — new device from Indonesia. Tap to review.',
                style: AppText.body(11, color: AppColors.ink2)),
            ])),
            Icon(Icons.chevron_right_rounded, color: AppColors.danger.withOpacity(0.6), size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Weekly Chart ─────────────────────────────────────
class _WeeklyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('This Week', style: AppText.h2(15)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
              child: Text('RM 906 total',
                style: AppText.label(11, color: AppColors.accent, weight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Text('Transactions by day', style: AppText.label(12)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 350,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: AppColors.ink,
                  getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                    '${AppData.weekDays[group.x]}\nRM ${rod.toY.toInt()}',
                    AppText.label(10, color: Colors.white),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) => Text(AppData.weekDays[v.toInt()],
                    style: AppText.label(10)),
                )),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              barGroups: AppData.weeklyVolumes.asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [BarChartRodData(
                  toY: e.value, width: 20, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    colors: e.key == 6
                      ? [AppColors.accent, AppColors.accentMid]
                      : [AppColors.accentSoft, AppColors.accentLight],
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                  ),
                )])).toList(),
            )),
          ),
        ]),
      ),
    );
  }
}

// ── Spend Breakdown ──────────────────────────────────
class _SpendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Spending Breakdown', style: AppText.h2(15)),
            Text('This month', style: AppText.label(12)),
          ]),
          const SizedBox(height: 14),
          ...AppData.spendCategories.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(children: [
              Text(cat.emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 10),
              SizedBox(width: 72, child: Text(cat.name,
                style: AppText.body(12, color: AppColors.ink, weight: FontWeight.w500))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: cat.pct,
                  backgroundColor: cat.color.withOpacity(0.1),
                  color: cat.color,
                  minHeight: 6,
                ),
              )),
              const SizedBox(width: 10),
              SizedBox(width: 54, child: Text('RM ${cat.amount.toStringAsFixed(0)}',
                style: AppText.mono(11, color: AppColors.ink2), textAlign: TextAlign.right)),
            ]),
          )),
        ]),
      ),
    );
  }
}

// ── Recent Transactions ──────────────────────────────
class _RecentList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final txs = AppData.transactions.take(5).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: txs.map((tx) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppCard(
          padding: const EdgeInsets.all(13),
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => TransactionDetailScreen(tx: tx))),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: switch (tx.status) {
                  TxStatus.approved => AppColors.accentLight,
                  TxStatus.flagged  => AppColors.warnLight,
                  TxStatus.blocked  => AppColors.dangerLight,
                },
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(tx.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.name, style: AppText.body(14, color: AppColors.ink, weight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${tx.platform} · ${tx.time}', style: AppText.label(11)),
              const SizedBox(height: 5),
              RiskBadge(score: tx.riskScore),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('RM ${tx.amount.toStringAsFixed(2)}',
                style: AppText.mono(14, color: AppColors.ink)),
              const SizedBox(height: 6),
              StatusPill(status: tx.status, score: tx.riskScore),
            ]),
          ]),
        ),
      )).toList()),
    );
  }
}
