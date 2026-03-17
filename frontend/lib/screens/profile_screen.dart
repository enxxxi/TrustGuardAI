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
        _ProfileHero(),
        _ProfileStats(),
        SectionHeader(title: 'Behavior Profile'),
        _BehaviorSection(),
        SectionHeader(title: 'Monthly Fraud Activity'),
        _FraudChart(),
        SectionHeader(title: 'Security Settings'),
        _SecuritySettings(),
        SectionHeader(title: 'Account'),
        _AccountSection(),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Profile Hero ────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 68),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(children: [
        // Avatar with ring
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 90, height: 90,
            child: CircularProgressIndicator(
              value: 0.96, backgroundColor: Colors.white.withOpacity(0.1),
              color: AppColors.safe, strokeWidth: 3,
            )),
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, Color(0xFF6366F1)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            alignment: Alignment.center,
            child: const Text('👩', style: TextStyle(fontSize: 32)),
          ),
          Positioned(bottom: 2, right: 2,
            child: Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: AppColors.safe, shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0F172A), width: 2),
              ),
              alignment: Alignment.center,
              child: const Text('✓', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
            )),
        ]),
        const SizedBox(height: 12),
        Text('Aisha Binti Razak', style: AppText.display(20, color: Colors.white)),
        const SizedBox(height: 3),
        Text("GrabPay · Touch 'n Go · Gig Worker", style: AppText.body(12, color: Colors.white38)),
        const SizedBox(height: 10),
        // Trust score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.safe.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.safe.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🛡️', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text('Trust Score: 96/100', style: AppText.mono(12, color: AppColors.safe, weight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }
}

// ── Profile Stats ───────────────────────────────────
class _ProfileStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          radius: 16,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: IntrinsicHeight(child: Row(children: [
            Expanded(child: StatChip(value: '142', label: 'Transactions', color: AppColors.accent)),
            Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Expanded(child: StatChip(value: '96%', label: 'Safe Rate', color: AppColors.safe)),
            Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Expanded(child: StatChip(value: 'RM 52', label: 'Avg Spend', color: AppColors.warn)),
            Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 10)),
            Expanded(child: StatChip(value: '0', label: 'Frauds', color: AppColors.ink3)),
          ])),
        ),
      ),
    );
  }
}

// ── Behavior Section ────────────────────────────────
class _BehaviorSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(
        child: Column(
          children: AppData.behaviorStats.map((s) => BehaviorRow(stat: s)).toList(),
        ),
      ),
    );
  }
}

// ── Fraud Chart ─────────────────────────────────────
class _FraudChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Fraud Events (12 months)', style: AppText.body(13, weight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.safeLight, borderRadius: BorderRadius.circular(6)),
              child: Text('0 successful', style: AppText.mono(10, color: AppColors.safe, weight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: LineChart(LineChartData(
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= AppState.months.length) return const SizedBox();
                    return Text(AppState.months[idx], style: AppText.body(9, color: AppColors.ink3));
                  },
                )),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: AppState.monthlyFraud.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
                  isCurved: true,
                  color: AppColors.danger,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: AppColors.danger, strokeWidth: 0),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppColors.danger.withOpacity(0.15), AppColors.danger.withOpacity(0.0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            )),
          ),
          const SizedBox(height: 8),
          Text('Peak detected in October (12 attempts, all blocked)',
            style: AppText.body(11, color: AppColors.ink3)),
        ]),
      ),
    );
  }
}

// ── Security Settings ───────────────────────────────
class _SecuritySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        SettingToggleRow(
          icon: '🛡️', iconBg: AppColors.safeLight,
          title: 'Real-Time Protection',
          subtitle: state.realtimeEnabled ? 'AI monitoring active' : 'Protection paused',
          value: state.realtimeEnabled,
          onChanged: (_) => state.toggleRealtime(),
        ),
        SettingToggleRow(
          icon: '🔔', iconBg: AppColors.accentLight,
          title: 'Fraud Alerts',
          subtitle: state.notifEnabled ? 'Push notifications on' : 'Notifications off',
          value: state.notifEnabled,
          onChanged: (_) => state.toggleNotif(),
        ),
        SettingToggleRow(
          icon: '📍', iconBg: AppColors.warnLight,
          title: 'Location Verification',
          subtitle: state.locationEnabled ? 'Geofencing enabled' : 'Location off',
          value: state.locationEnabled,
          onChanged: (_) => state.toggleLocation(),
        ),
        SettingToggleRow(
          icon: '👆', iconBg: AppColors.accentLight,
          title: 'Biometric Lock',
          subtitle: state.biometricEnabled ? 'Fingerprint / Face ID active' : 'Biometric disabled',
          value: state.biometricEnabled,
          onChanged: (_) => state.toggleBiometric(),
        ),
      ]),
    );
  }
}

// ── Account Section ─────────────────────────────────
class _AccountSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        SettingNavRow(
          icon: '📱', iconBg: AppColors.card2,
          title: 'Trusted Devices',
          subtitle: '2 devices registered',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(6)),
              child: Text('2', style: AppText.mono(11, color: AppColors.accent, weight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.ink3, size: 20),
          ]),
        ),
        SettingNavRow(
          icon: '🔑', iconBg: AppColors.card2,
          title: 'Change PIN',
          subtitle: 'Last changed 30 days ago',
        ),
        SettingNavRow(
          icon: '📊', iconBg: AppColors.accentLight,
          title: 'Security Report',
          subtitle: 'Weekly summary available',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.safeLight, borderRadius: BorderRadius.circular(6)),
              child: Text('NEW', style: AppText.mono(9, color: AppColors.safe, weight: FontWeight.w700)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.ink3, size: 20),
          ]),
        ),
        SettingNavRow(
          icon: '🔒', iconBg: AppColors.card2,
          title: 'Privacy Settings',
          subtitle: 'Data sharing & storage',
        ),
        SettingNavRow(
          icon: '❓', iconBg: AppColors.card2,
          title: 'Help & Support',
          subtitle: 'FAQ, contact fraud team',
        ),
        SettingNavRow(
          icon: '🚪', iconBg: AppColors.dangerLight,
          title: 'Sign Out',
          subtitle: '',
          arrowColor: AppColors.danger,
          onTap: () => _showSignOutDialog(context),
        ),
      ]),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Sign Out?', style: AppText.display(18)),
      content: Text('Your real-time fraud protection will be paused.',
        style: AppText.body(13, color: AppColors.ink2)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppText.body(14, color: AppColors.ink3))),
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Sign Out', style: AppText.body(14, color: AppColors.danger, weight: FontWeight.w700))),
      ],
    ));
  }
}
