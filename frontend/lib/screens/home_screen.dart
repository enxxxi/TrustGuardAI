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
                Container(width: 1, height: 20, color: AppColors.darkBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
                _MicroStat('1.2%', 'False +', AppColors.warn),
                Container(width: 1, height: 20, color: AppColors.darkBorder,
                  margin: const EdgeInsets.symmetric(horizontal: 10)),
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
  void _showSheet(BuildContext context, String title, Color color,
      List<Transaction> txs, String summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _KpiSheet(
        title: title, color: color, txs: txs, summary: summary),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final approved = AppData.transactions
        .where((t) => t.status == TxStatus.approved).toList();
    final flagged  = AppData.transactions
        .where((t) => t.status == TxStatus.flagged).toList();
    final blocked  = AppData.transactions
        .where((t) => t.status == TxStatus.blocked).toList();
    final savedAmt = blocked.fold(0.0, (s, t) => s + t.amount);
 
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
            Expanded(child: _TapChip(
              value: '${approved.length}', label: 'Approved',
              color: AppColors.safe, sub: '↑ +8',
              onTap: () => _showSheet(context, 'Approved Transactions',
                AppColors.safe, approved,
                '${approved.length} transactions cleared safely today'),
            )),
            _VDivider(),
            Expanded(child: _TapChip(
              value: '${flagged.length}', label: 'Flagged',
              color: AppColors.warn, sub: '↑ +1',
              onTap: () => _showSheet(context, 'Flagged Transactions',
                AppColors.warn, flagged,
                '${flagged.length} transactions pending review'),
            )),
            _VDivider(),
            Expanded(child: _TapChip(
              value: '${blocked.length}', label: 'Blocked',
              color: AppColors.danger, sub: '⚠ High',
              onTap: () => _showSheet(context, 'Blocked Transactions',
                AppColors.danger, blocked,
                '${blocked.length} high-risk transactions stopped'),
            )),
            _VDivider(),
            Expanded(child: _TapChip(
              value: 'RM ${savedAmt.toStringAsFixed(0)}',
              label: 'Saved', color: AppColors.accent, sub: '✓',
              onTap: () => _showSheet(context, 'Money Saved',
                AppColors.accent, blocked,
                'RM ${savedAmt.toStringAsFixed(2)} protected from fraud'),
            )),
          ])),
        ),
      ),
    );
  }
}
 
// ── Tappable KPI Chip ────────────────────────────────
class _TapChip extends StatefulWidget {
  final String value, label, sub;
  final Color color;
  final VoidCallback onTap;
  const _TapChip({required this.value, required this.label,
    required this.sub, required this.color, required this.onTap});
  @override State<_TapChip> createState() => _TapChipState();
}
 
class _TapChipState extends State<_TapChip> {
  bool _pressed = false;
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(children: [
          Text(widget.value, style: AppText.h1(20, color: widget.color)),
          const SizedBox(height: 2),
          Text(widget.sub, style: AppText.label(9, color: widget.color.withOpacity(0.75))),
          const SizedBox(height: 2),
          Text(widget.label, style: AppText.label(10, color: AppColors.ink3)),
          const SizedBox(height: 4),
          // Tap hint
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.touch_app_rounded, size: 9, color: AppColors.ink4),
            const SizedBox(width: 2),
            Text('details', style: AppText.label(8, color: AppColors.ink4)),
          ]),
        ]),
      ),
    );
  }
}
 
class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
    Container(width: 1, color: AppColors.divider,
      margin: const EdgeInsets.symmetric(vertical: 12));
}
 
// ── KPI Bottom Sheet ─────────────────────────────────
class _KpiSheet extends StatelessWidget {
  final String title, summary;
  final Color color;
  final List<Transaction> txs;
  const _KpiSheet({required this.title, required this.color,
    required this.txs, required this.summary});
 
  @override
  Widget build(BuildContext context) {
    final totalAmt = txs.fold(0.0, (s, t) => s + t.amount);
 
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Drag handle
        Center(child: Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card3, borderRadius: BorderRadius.circular(2)),
        )),
 
        // Header
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(_statusIcon(color), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.h2(17)),
            Text(summary, style: AppText.label(12, color: color)),
          ])),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.card2, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Icon(Icons.close_rounded, size: 16, color: AppColors.ink3),
            ),
          ),
        ]),
 
        const SizedBox(height: 14),
 
        // Summary stats
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Row(children: [
            Expanded(child: _SheetStat('${txs.length}', 'Transactions', color)),
            Container(width: 1, height: 32, color: color.withOpacity(0.15)),
            Expanded(child: _SheetStat(
              'RM ${totalAmt.toStringAsFixed(0)}', 'Total Value', color)),
            Container(width: 1, height: 32, color: color.withOpacity(0.15)),
            Expanded(child: _SheetStat(
              txs.isEmpty ? '-'
                : '${(txs.fold(0, (s, t) => s + t.riskScore) / txs.length).toStringAsFixed(0)}%',
              'Avg Risk', color)),
          ]),
        ),
 
        const SizedBox(height: 14),
 
        // Transaction list
        if (txs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              Icon(Icons.check_circle_outline_rounded,
                size: 44, color: AppColors.safe),
              const SizedBox(height: 10),
              Text('No transactions in this category',
                style: AppText.body(14, color: AppColors.ink3)),
            ]),
          )
        else
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              physics: const BouncingScrollPhysics(),
              shrinkWrap: true,
              itemCount: txs.length,
              itemBuilder: (ctx, i) {
                final tx = txs[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => TransactionDetailScreen(tx: tx)));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border.withOpacity(0.6)),
                      boxShadow: AppShadow.card,
                    ),
                    child: Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(tx.emoji, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 11),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tx.name,
                          style: AppText.body(13, color: AppColors.ink,
                            weight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text('${tx.platform} · ${tx.date} · ${tx.time}',
                          style: AppText.label(10)),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('RM ${tx.amount.toStringAsFixed(2)}',
                          style: AppText.mono(13, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text('${tx.riskScore}%',
                            style: AppText.tag(9, color: color)),
                        ),
                      ]),
                    ]),
                  ),
                );
              },
            ),
          ),
      ]),
    );
  }
 
  IconData _statusIcon(Color c) {
    if (c == AppColors.safe)   return Icons.check_circle_outline_rounded;
    if (c == AppColors.warn)   return Icons.flag_outlined;
    if (c == AppColors.danger) return Icons.block_rounded;
    return Icons.savings_outlined;
  }
}
 
class _SheetStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _SheetStat(this.value, this.label, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: AppText.mono(15, color: color)),
    const SizedBox(height: 2),
    Text(label, style: AppText.label(10)),
  ]);
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
            Icon(Icons.chevron_right_rounded,
              color: AppColors.danger.withOpacity(0.6), size: 20),
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
              decoration: BoxDecoration(
                color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
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
                  getTitlesWidget: (v, _) => Text(
                    AppData.weekDays[v.toInt()], style: AppText.label(10)),
                )),
                leftTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                  const FlLine(color: AppColors.divider, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              barGroups: AppData.weeklyVolumes.asMap().entries.map((e) =>
                BarChartGroupData(x: e.key, barRods: [BarChartRodData(
                  toY: e.value, width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
                  color: cat.color, minHeight: 6,
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
              Text(tx.name,
                style: AppText.body(14, color: AppColors.ink, weight: FontWeight.w600),
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
 