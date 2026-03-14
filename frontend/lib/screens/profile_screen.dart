// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _ProfileHero(),
          _ProfileStats(),
          SectionHeader(title: 'Behavior Profile'),
          _BehaviorSection(),
          SectionHeader(title: 'Security Settings'),
          _SecuritySettings(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Profile Hero ──
class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: AppColors.accent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            alignment: Alignment.center,
            child: const Text('👩', style: TextStyle(fontSize: 30)),
          ),
          const SizedBox(height: 12),
          Text('Aisha Binti Razak', style: AppText.display(20, color: Colors.white)),
          const SizedBox(height: 3),
          Text("GrabPay · Touch 'n Go · Gig Worker",
            style: AppText.body(12, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ── Profile Stats ──
class _ProfileStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppCard(
          child: IntrinsicHeight(
            child: Row(
              children: [
                _PStat('142', 'Transactions', AppColors.accent),
                _Div(),
                _PStat('96%', 'Safe Rate', AppColors.safe),
                _Div(),
                _PStat('RM 52', 'Avg Spend', AppColors.warn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PStat extends StatelessWidget {
  final String val, label;
  final Color color;
  const _PStat(this.val, this.label, this.color);

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    const SizedBox(height: 8),
    Text(val, style: AppText.display(18, color: color)),
    const SizedBox(height: 3),
    Text(label, style: AppText.body(10, color: AppColors.ink3)),
    const SizedBox(height: 8),
  ]));
}

class _Div extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(width: 1, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 12));
}

// ── Behavior Section ──
class _BehaviorSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(
        child: Column(
          children: AppData.behaviorStats.map((s) => BehaviorRow(
            icon: s.icon, label: s.label, value: s.value, display: s.display,
          )).toList(),
        ),
      ),
    );
  }
}

// ── Security Settings ──
class _SecuritySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SettingToggleRow(
            icon: '🛡️', iconBg: AppColors.safeLight,
            title: 'Real-Time Protection',
            subtitle: 'AI monitoring active',
          ),
          SettingToggleRow(
            icon: '🔔', iconBg: AppColors.accentLight,
            title: 'Fraud Alerts',
            subtitle: 'Push notifications on',
          ),
          SettingToggleRow(
            icon: '📍', iconBg: AppColors.warnLight,
            title: 'Location Verification',
            subtitle: 'Geofencing enabled',
          ),
          SettingNavRow(
            icon: '🔑', iconBg: AppColors.card2,
            title: 'Trusted Devices',
            subtitle: '2 devices registered',
          ),
          SettingNavRow(
            icon: '🚪', iconBg: AppColors.dangerLight,
            title: 'Sign Out',
            subtitle: '',
            arrowColor: AppColors.danger,
          ),
        ],
      ),
    );
  }
}
