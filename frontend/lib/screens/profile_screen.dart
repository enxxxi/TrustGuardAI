// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        _Hero(),
        _Stats(),
        SectionHeader(title: 'Behavior Profile'),
        _Behavior(),
        SectionHeader(title: 'Fraud Activity — 12 Months'),
        _FraudChart(),
        SectionHeader(title: 'Security'),
        _Security(),
        SectionHeader(title: 'Account'),
        _Account(),
        const SizedBox(height: 40),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.dark1, AppColors.dark2]),
      ),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 88, height: 88,
            child: CircularProgressIndicator(value: 0.96,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: AppColors.safe, strokeWidth: 3)),
          Container(
            width: 74, height: 74,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6366F1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadow.colored(AppColors.accent),
            ),
            alignment: Alignment.center,
            child: const Text('👩', style: TextStyle(fontSize: 32)),
          ),
          Positioned(bottom: 2, right: 0, child: Container(
            width: 22, height: 22,
            decoration: BoxDecoration(color: AppColors.safe, shape: BoxShape.circle,
              border: Border.all(color: AppColors.dark1, width: 2)),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
          )),
        ]),
        const SizedBox(height: 12),
        Text('Aisha Binti Razak', style: AppText.h1(20, color: Colors.white)),
        const SizedBox(height: 4),
        Text("GrabPay · Touch 'n Go · Gig Worker",
          style: AppText.label(12, color: AppColors.darkText)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.safe.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.safe.withOpacity(0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛡️', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text('Trust Score: 96 / 100',
              style: AppText.label(12, color: AppColors.safe, weight: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}

class _Stats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.6)),
            boxShadow: AppShadow.elevated,
          ),
          child: IntrinsicHeight(child: Row(children: [
            Expanded(child: StatChip(value: '142', label: 'Transactions', color: AppColors.accent)),
            Container(width: 1, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 12)),
            Expanded(child: StatChip(value: '96%', label: 'Safe Rate', color: AppColors.safe)),
            Container(width: 1, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 12)),
            Expanded(child: StatChip(value: 'RM 52', label: 'Avg Spend', color: AppColors.warn)),
            Container(width: 1, color: AppColors.divider, margin: const EdgeInsets.symmetric(vertical: 12)),
            Expanded(child: StatChip(value: '0', label: 'Frauds', color: AppColors.ink3)),
          ])),
        ),
      ),
    );
  }
}

class _Behavior extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(child: Column(
        children: AppData.behaviorStats.map((s) => BehaviorRow(stat: s)).toList())),
    );
  }
}

class _FraudChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Fraud attempts blocked', style: AppText.body(13, color: AppColors.ink, weight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.safeLight, borderRadius: BorderRadius.circular(6)),
            child: Text('0 successful', style: AppText.tag(9, color: AppColors.safe)),
          ),
        ]),
        const SizedBox(height: 4),
        Text('All attempts were detected and blocked',
          style: AppText.label(12)),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: LineChart(LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1)),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= AppState.months.length) return const SizedBox();
                  return Text(AppState.months[i], style: AppText.label(9));
                })),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [LineChartBarData(
              spots: AppState.monthlyFraud.asMap().entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
              isCurved: true, color: AppColors.danger, barWidth: 2.5,
              dotData: FlDotData(show: true,
                getDotPainter: (_, __, ___, ____) =>
                  FlDotCirclePainter(radius: 3, color: AppColors.danger, strokeWidth: 0)),
              belowBarData: BarAreaData(show: true,
                gradient: LinearGradient(
                  colors: [AppColors.danger.withOpacity(0.12), Colors.transparent],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            )],
          )),
        ),
        const SizedBox(height: 8),
        Text('Peak in October — 12 attempts, all blocked',
          style: AppText.label(11)),
      ])),
    );
  }
}

class _Security extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(children: [
        SettingToggleRow(icon:'🛡️', iconBg:AppColors.safeLight,
          title:'Real-Time Protection',
          subtitle: s.realtimeEnabled ? 'AI monitoring active' : 'Protection paused',
          value: s.realtimeEnabled, onChanged: (_) => s.toggleRealtime()),
        SettingToggleRow(icon:'🔔', iconBg:AppColors.accentLight,
          title:'Fraud Alerts',
          subtitle: s.notifEnabled ? 'Push notifications on' : 'Notifications off',
          value: s.notifEnabled, onChanged: (_) => s.toggleNotif()),
        SettingToggleRow(icon:'📍', iconBg:AppColors.warnLight,
          title:'Location Verification',
          subtitle: s.locationEnabled ? 'Geofencing enabled' : 'Location off',
          value: s.locationEnabled, onChanged: (_) => s.toggleLocation()),
        SettingToggleRow(icon:'👆', iconBg:AppColors.accentLight,
          title:'Biometric Lock',
          subtitle: s.biometricEnabled ? 'Fingerprint / Face ID active' : 'Biometric disabled',
          value: s.biometricEnabled, onChanged: (_) => s.toggleBiometric()),
      ]),
    );
  }
}

class _Account extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(children: [
        SettingNavRow(icon:'📱', iconBg:AppColors.card2, title:'Trusted Devices', subtitle:'2 devices registered',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(6)),
              child: Text('2', style: AppText.mono(11, color: AppColors.accent))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink4, size: 20),
          ])),
        SettingNavRow(icon:'🔑', iconBg:AppColors.card2, title:'Change PIN', subtitle:'Last changed 30 days ago'),
        SettingNavRow(icon:'📊', iconBg:AppColors.accentLight, title:'Security Report', subtitle:'Weekly summary available',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: AppColors.safeLight, borderRadius: BorderRadius.circular(5)),
              child: Text('NEW', style: AppText.tag(8, color: AppColors.safe))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink4, size: 20),
          ])),
        SettingNavRow(icon:'🔒', iconBg:AppColors.card2, title:'Privacy Settings', subtitle:'Data sharing & storage'),
        SettingNavRow(icon:'❓', iconBg:AppColors.card2, title:'Help & Support', subtitle:'FAQ, contact fraud team'),
        SettingNavRow(icon:'🚪', iconBg:AppColors.dangerLight, title:'Sign Out', subtitle:'',
          arrowColor: AppColors.danger,
          onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Sign Out?', style: AppText.h2(18)),
            content: Text('Your real-time fraud protection will be paused.', style: AppText.body(13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: AppText.label(14, color: AppColors.ink3))),
              TextButton(onPressed: () => Navigator.pop(context),
                child: Text('Sign Out', style: AppText.label(14, color: AppColors.danger, weight: FontWeight.w700))),
            ],
          ))),
      ]),
    );
  }
}
