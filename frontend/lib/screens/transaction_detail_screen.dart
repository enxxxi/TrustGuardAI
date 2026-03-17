// lib/screens/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/common_widgets.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction tx;
  const TransactionDetailScreen({super.key, required this.tx});

  Color get _statusColor => switch (tx.status) {
    TxStatus.approved => AppColors.safe,
    TxStatus.flagged  => AppColors.warn,
    TxStatus.blocked  => AppColors.danger,
  };

  String get _statusLabel => switch (tx.status) {
    TxStatus.approved => '✓  APPROVED',
    TxStatus.flagged  => '⚑  FLAGGED',
    TxStatus.blocked  => '⛔  BLOCKED',
  };

  List<_Factor> get _factors {
    final f = <_Factor>[];
    if (tx.riskScore > 60) {
      f.add(_Factor('⚠', 'Unusual amount', 'RM ${tx.amount.toStringAsFixed(0)} is ${(tx.amount / 52).toStringAsFixed(0)}× your average (RM 52)', AppColors.danger));
    }
    if (tx.location.contains('IP') || tx.location.contains('VPN')) {
      f.add(_Factor('🌐', 'Geographic anomaly', 'Login origin does not match wallet region', AppColors.danger));
    }
    if (tx.riskScore > 50) {
      f.add(_Factor('📱', 'New device fingerprint', 'Device not seen in previous 90 days', AppColors.warn));
    }
    if (tx.time.startsWith('02') || tx.time.startsWith('03')) {
      f.add(_Factor('🌙', 'Off-hours transaction', 'Activity at ${tx.time} AM is outside normal pattern', AppColors.warn));
    }
    if (tx.riskScore <= 30) {
      f.add(_Factor('✓', 'Known device', 'Verified device fingerprint matches history', AppColors.safe));
      f.add(_Factor('✓', 'Home region', 'Location consistent with usage history', AppColors.safe));
      f.add(_Factor('✓', 'Normal amount', 'Within expected spending range', AppColors.safe));
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
          // App bar
          SliverAppBar(
            expandedHeight: 200,
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [AppColors.dark1, AppColors.dark2],
                  ),
                ),
                child: SafeArea(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(height: 40),
                    Text(tx.emoji, style: const TextStyle(fontSize: 42)),
                    const SizedBox(height: 8),
                    Text('RM ${tx.amount.toStringAsFixed(2)}',
                      style: AppText.display(28, color: Colors.white)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _statusColor.withOpacity(0.4)),
                      ),
                      child: Text(_statusLabel, style: AppText.mono(13, color: _statusColor, weight: FontWeight.w700)),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [

              // Risk gauge card
              AppCard(child: Column(children: [
                Row(children: [
                  SizedBox(
                    width: 72, height: 72,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox(width: 72, height: 72,
                        child: CircularProgressIndicator(
                          value: tx.riskScore / 100,
                          backgroundColor: AppColors.border,
                          color: _statusColor,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Text('${tx.riskScore}%', style: AppText.mono(14, color: _statusColor, weight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Risk Score', style: AppText.body(12, color: AppColors.ink3)),
                    const SizedBox(height: 2),
                    Text('${tx.riskScore} / 100', style: AppText.display(22, color: _statusColor)),
                    const SizedBox(height: 4),
                    Text(tx.riskScore >= 70 ? 'High risk — transaction blocked automatically'
                      : tx.riskScore >= 35 ? 'Medium risk — flagged for manual review'
                      : 'Low risk — transaction approved',
                      style: AppText.body(11, color: AppColors.ink2)),
                  ])),
                ]),
                const SizedBox(height: 14),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 12),
                // Risk breakdown bars
                _RiskBar('Amount', tx.amount > 500 ? 0.85 : 0.2, _statusColor),
                const SizedBox(height: 8),
                _RiskBar('Location', tx.location.contains('IP') ? 0.9 : 0.1, _statusColor),
                const SizedBox(height: 8),
                _RiskBar('Device', tx.riskScore > 60 ? 0.75 : 0.1, _statusColor),
                const SizedBox(height: 8),
                _RiskBar('Time', (tx.time.startsWith('02') || tx.time.startsWith('03')) ? 0.8 : 0.15, _statusColor),
              ])),

              const SizedBox(height: 12),

              // Transaction details
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transaction Details', style: AppText.display(15)),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 8),
                InfoRow(label: 'Transaction ID', value: tx.id),
                InfoRow(label: 'Platform', value: tx.platform),
                InfoRow(label: 'Amount', value: 'RM ${tx.amount.toStringAsFixed(2)}'),
                InfoRow(label: 'Date & Time', value: '${tx.date} · ${tx.time}'),
                InfoRow(label: 'Location', value: tx.location),
                InfoRow(label: 'User Type', value: tx.userType),
                InfoRow(label: 'Status', value: _statusLabel, valueColor: _statusColor),
              ])),

              const SizedBox(height: 12),

              // Risk factors
              AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Risk Factors', style: AppText.display(15)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Explainable AI', style: AppText.mono(9, color: AppColors.accent)),
                  ),
                ]),
                const SizedBox(height: 12),
                ..._factors.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: f.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(f.icon, style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.title, style: AppText.body(13, weight: FontWeight.w600, color: f.color)),
                      const SizedBox(height: 2),
                      Text(f.desc, style: AppText.body(11, color: AppColors.ink2)),
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
                    border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('⛔', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Block Reason', style: AppText.body(13, color: AppColors.danger, weight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(tx.blockReason!, style: AppText.body(12, color: AppColors.ink2)),
                    ])),
                  ]),
                ),
              ],

              const SizedBox(height: 12),

              // Actions
              if (tx.status == TxStatus.flagged || tx.status == TxStatus.blocked)
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Analyst Actions', style: AppText.display(15)),
                  const SizedBox(height: 6),
                  Text('Manually override the AI decision if needed.',
                    style: AppText.body(12, color: AppColors.ink3)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _ActionButton('✓ Approve', AppColors.safe, AppColors.safeLight,
                      () => _showSnack(context, 'Transaction approved manually'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionButton('🔍 Review', AppColors.accent, AppColors.accentLight,
                      () => _showSnack(context, 'Sent to fraud team for review'))),
                    const SizedBox(width: 8),
                    Expanded(child: _ActionButton('⛔ Block', AppColors.danger, AppColors.dangerLight,
                      () => _showSnack(context, 'Transaction permanently blocked'))),
                  ]),
                ])),

              const SizedBox(height: 24),
            ]),
          )),
        ],
      ),
    );
  }

  Widget _RiskBar(String label, double val, Color color) {
    return Row(children: [
      SizedBox(width: 70, child: Text(label, style: AppText.body(11, color: AppColors.ink3))),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(value: val, backgroundColor: AppColors.border, color: color, minHeight: 6),
      )),
      const SizedBox(width: 8),
      Text('${(val * 100).toInt()}%', style: AppText.mono(10, color: color, weight: FontWeight.w500)),
    ]);
  }

  Widget _ActionButton(String label, Color fg, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withOpacity(0.3))),
        alignment: Alignment.center,
        child: Text(label, style: AppText.body(11, color: fg, weight: FontWeight.w700)),
      ),
    );
  }

  void _showSnack(BuildContext context, String msg) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppText.body(13, color: Colors.white)),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

class _Factor {
  final String icon, title, desc;
  final Color color;
  const _Factor(this.icon, this.title, this.desc, this.color);
}
