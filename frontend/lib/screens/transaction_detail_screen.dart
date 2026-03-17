// lib/screens/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/common_widgets.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction tx;
  const TransactionDetailScreen({super.key, required this.tx});

  Color get _sc => switch (tx.status) {
    TxStatus.approved => AppColors.safe, TxStatus.flagged => AppColors.warn, TxStatus.blocked => AppColors.danger,
  };
  String get _sl => switch (tx.status) {
    TxStatus.approved => '✓  APPROVED', TxStatus.flagged => '⚑  FLAGGED', TxStatus.blocked => '✕  BLOCKED',
  };

  List<({String icon, String title, String desc, Color color})> get _factors {
    final f = <({String icon, String title, String desc, Color color})>[];
    if (tx.riskScore > 60)
      f.add((icon:'💰', title:'Unusual amount', desc:'RM ${tx.amount.toStringAsFixed(0)} is ${(tx.amount/52).toStringAsFixed(0)}× your average of RM 52', color:AppColors.danger));
    if (tx.location.contains('IP') || tx.location.contains('VPN'))
      f.add((icon:'🌐', title:'Geographic anomaly', desc:'Login origin does not match your registered wallet region', color:AppColors.danger));
    if (tx.riskScore > 50)
      f.add((icon:'📱', title:'New device fingerprint', desc:'This device has not been seen in the past 90 days', color:AppColors.warn));
    if (tx.time.startsWith('02') || tx.time.startsWith('03'))
      f.add((icon:'🌙', title:'Off-hours activity', desc:'Transaction at ${tx.time} falls outside your normal usage pattern', color:AppColors.warn));
    if (tx.riskScore <= 30) {
      f.add((icon:'✓', title:'Known device', desc:'Verified device fingerprint matches your history', color:AppColors.safe));
      f.add((icon:'✓', title:'Home region', desc:'Location is consistent with your registered address', color:AppColors.safe));
      f.add((icon:'✓', title:'Normal amount', desc:'Within your expected daily spending range', color:AppColors.safe));
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 210,
            pinned: true,
            backgroundColor: AppColors.dark1,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.dark1, AppColors.dark2])),
                child: SafeArea(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 36),
                  Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      color: _sc.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _sc.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(tx.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(height: 10),
                  Text('RM ${tx.amount.toStringAsFixed(2)}',
                    style: AppText.h1(28, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _sc.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _sc.withOpacity(0.35)),
                    ),
                    child: Text(_sl, style: AppText.tag(12, color: _sc)),
                  ),
                ])),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Risk gauge
              AppCard(child: Column(children: [
                Row(children: [
                  SizedBox(width: 68, height: 68, child: Stack(alignment: Alignment.center, children: [
                    SizedBox(width: 68, height: 68, child: CircularProgressIndicator(
                      value: tx.riskScore / 100, backgroundColor: AppColors.card3,
                      color: _sc, strokeWidth: 6, strokeCap: StrokeCap.round)),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${tx.riskScore}%', style: AppText.mono(14, color: _sc)),
                      Text('risk', style: AppText.label(9, color: AppColors.ink3)),
                    ]),
                  ])),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Risk Score', style: AppText.label(12)),
                    const SizedBox(height: 2),
                    Text('${tx.riskScore} out of 100', style: AppText.h1(20, color: _sc)),
                    const SizedBox(height: 6),
                    Text(tx.riskScore >= 70
                      ? 'High risk — automatically blocked by AI'
                      : tx.riskScore >= 35
                        ? 'Medium risk — flagged for manual review'
                        : 'Low risk — transaction approved safely',
                      style: AppText.body(12)),
                  ])),
                ]),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 14),
                _FactorBar('Amount',   tx.amount > 500 ? 0.85 : 0.2,   _sc),
                const SizedBox(height: 8),
                _FactorBar('Location', tx.location.contains('IP') ? 0.9 : 0.1, _sc),
                const SizedBox(height: 8),
                _FactorBar('Device',   tx.riskScore > 60 ? 0.75 : 0.1, _sc),
                const SizedBox(height: 8),
                _FactorBar('Time',     (tx.time.startsWith('02') || tx.time.startsWith('03')) ? 0.8 : 0.15, _sc),
              ])),

              const SizedBox(height: 12),

              // Details
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transaction Details', style: AppText.h2(15)),
                const SizedBox(height: 12),
                InfoRow(label: 'Transaction ID', value: tx.id),
                InfoRow(label: 'Platform',       value: tx.platform),
                InfoRow(label: 'Amount',         value: 'RM ${tx.amount.toStringAsFixed(2)}'),
                InfoRow(label: 'Date & Time',    value: '${tx.date} · ${tx.time}'),
                InfoRow(label: 'Location',       value: tx.location),
                InfoRow(label: 'User Type',      value: tx.userType),
                InfoRow(label: 'Status',         value: _sl, valueColor: _sc, divider: false),
              ])),

              const SizedBox(height: 12),

              // Explainable AI
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Risk Factors', style: AppText.h2(15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(6)),
                    child: Text('Explainable AI', style: AppText.tag(9, color: AppColors.accent)),
                  ),
                ]),
                const SizedBox(height: 14),
                ..._factors.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: f.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(f.icon, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.title, style: AppText.body(13, color: f.color, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(f.desc, style: AppText.body(12)),
                    ])),
                  ]),
                )),
              ])),

              if (tx.blockReason != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('✕', style: TextStyle(fontSize: 16, color: AppColors.danger, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Block Reason', style: AppText.body(13, color: AppColors.danger, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(tx.blockReason!, style: AppText.body(12)),
                    ])),
                  ]),
                ),
              ],

              if (tx.status == TxStatus.flagged || tx.status == TxStatus.blocked) ...[
                const SizedBox(height: 12),
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Analyst Actions', style: AppText.h2(15)),
                  const SizedBox(height: 4),
                  Text('Manually override the AI decision if needed.',
                    style: AppText.body(12)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _ActBtn('✓ Approve', AppColors.safe, AppColors.safeLight,
                      () => _snack(context, 'Transaction approved manually'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActBtn('🔍 Review', AppColors.accent, AppColors.accentLight,
                      () => _snack(context, 'Sent to fraud team for review'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActBtn('✕ Block', AppColors.danger, AppColors.dangerLight,
                      () => _snack(context, 'Transaction permanently blocked'))),
                  ]),
                ])),
              ],

              const SizedBox(height: 24),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _FactorBar(String label, double val, Color color) => Row(children: [
    SizedBox(width: 66, child: Text(label, style: AppText.label(11))),
    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(value: val, backgroundColor: color.withOpacity(0.1),
        color: color, minHeight: 6))),
    const SizedBox(width: 8),
    SizedBox(width: 32, child: Text('${(val * 100).toInt()}%',
      style: AppText.mono(10, color: color), textAlign: TextAlign.right)),
  ]);

  Widget _ActBtn(String label, Color fg, Color bg, VoidCallback onTap) =>
    GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withOpacity(0.25))),
        alignment: Alignment.center,
        child: Text(label, style: AppText.label(12, color: fg, weight: FontWeight.w700)),
      ));

  void _snack(BuildContext context, String msg) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppText.body(13, color: Colors.white)),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }
}
