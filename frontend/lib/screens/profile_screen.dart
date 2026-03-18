// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../models/auth_state.dart';
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
        SectionHeader(title: 'Personal Information'),
        _PersonalInfo(),
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
 
class _ProfileHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthState>().profile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 64),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [AppColors.dark1, AppColors.dark2])),
      child: Column(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 92, height: 92,
            child: CircularProgressIndicator(value: 0.96,
              backgroundColor: Colors.white.withOpacity(0.08),
              color: AppColors.safe, strokeWidth: 3)),
          GestureDetector(
            onTap: () => _showAvatarPicker(context, profile),
            child: Stack(children: [
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.accent, Color(0xFF6366F1)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppShadow.colored(AppColors.accent)),
                alignment: Alignment.center,
                child: Text(profile.avatarEmoji, style: const TextStyle(fontSize: 34))),
              Positioned(bottom: 0, right: 0, child: Container(
                width: 22, height: 22,
                decoration: BoxDecoration(color: AppColors.accentMid, shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark1, width: 2)),
                alignment: Alignment.center,
                child: const Icon(Icons.edit_rounded, color: Colors.white, size: 11))),
            ])),
        ]),
        const SizedBox(height: 12),
        Text(profile.name, style: AppText.h1(20, color: Colors.white)),
        const SizedBox(height: 3),
        Text('${profile.occupation} · ${profile.city}, ${profile.country}',
          style: AppText.label(12, color: AppColors.darkText)),
        const SizedBox(height: 3),
        Text(profile.email, style: AppText.label(11, color: AppColors.darkText2)),
        const SizedBox(height: 12),
        // Wrap so badges stack vertically on narrow screens
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8, runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.safe.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.safe.withOpacity(0.25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🛡️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text('Trust Score: 96 / 100',
                  style: AppText.label(12, color: AppColors.safe, weight: FontWeight.w700)),
              ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.darkBorder)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('💳', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(profile.walletType,
                  style: AppText.label(12, color: AppColors.darkText),
                  overflow: TextOverflow.ellipsis),
              ])),
          ],
        ),
      ]),
    );
  }
 
  void _showAvatarPicker(BuildContext context, UserProfile profile) {
    const avatars = ['👤','👨','👩','🧑','👦','👧','🧔','👱','🧕','👲'];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.card3, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Choose Avatar', style: AppText.h2(18)),
          const SizedBox(height: 20),
          Wrap(spacing: 12, runSpacing: 12, children: avatars.map((e) =>
            GestureDetector(
              onTap: () { context.read<AuthState>().updateProfile(profile.copyWith(avatarEmoji: e)); Navigator.pop(context); },
              child: Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: e == profile.avatarEmoji ? AppColors.accentLight : AppColors.card2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: e == profile.avatarEmoji ? AppColors.accent : AppColors.border,
                    width: e == profile.avatarEmoji ? 2 : 1)),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 26))),
            )).toList()),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}
 
class _ProfileStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -36),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withOpacity(0.6)), boxShadow: AppShadow.elevated),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              spacing: 8,
              children: const [
                SizedBox(width: 72, child: StatChip(value: '142', label: 'Transactions', color: AppColors.accent)),
                SizedBox(width: 72, child: StatChip(value: '96%', label: 'Safe Rate', color: AppColors.safe)),
                SizedBox(width: 72, child: StatChip(value: 'RM 52', label: 'Avg Spend', color: AppColors.warn)),
                SizedBox(width: 72, child: StatChip(value: '0', label: 'Frauds', color: AppColors.ink3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 
class _PersonalInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<AuthState>().profile;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(child: Column(children: [
        _InfoTile(Icons.person_outline_rounded, 'Full Name', p.name),
        _InfoTile(Icons.email_outlined, 'Email', p.email),
        _InfoTile(Icons.phone_outlined, 'Phone', p.phone),
        _InfoTile(Icons.location_city_outlined, 'Location', '${p.city}, ${p.country}'),
        _InfoTile(Icons.work_outline_rounded, 'Occupation', p.occupation),
        _InfoTile(Icons.account_balance_wallet_outlined, 'Primary Wallet', p.walletType, last: true),
      ])),
    );
  }
}
 
class _InfoTile extends StatelessWidget {
  final IconData icon; final String label, value; final bool last;
  const _InfoTile(this.icon, this.label, this.value, {this.last = false});
 
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(9)),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.accent, size: 17)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.label(11)),
          const SizedBox(height: 1),
          Text(value, style: AppText.body(13, color: AppColors.ink, weight: FontWeight.w600)),
        ])),
        GestureDetector(
          onTap: () => _edit(context),
          child: Container(padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.edit_outlined, color: AppColors.ink3, size: 14))),
      ]),
    ),
    if (!last) const Divider(height: 1, color: AppColors.divider),
  ]);
 
  void _edit(BuildContext context) {
    final ctrl = TextEditingController(text: value);
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit $label', style: AppText.h2(17)),
      content: TextField(controller: ctrl, autofocus: true,
        style: AppText.body(14, color: AppColors.ink),
        decoration: InputDecoration(filled: true, fillColor: AppColors.card2,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: AppText.label(14, color: AppColors.ink3))),
        TextButton(onPressed: () {
          final auth = context.read<AuthState>();
          final p = auth.profile;
          switch (label) {
            case 'Full Name': auth.updateProfile(p.copyWith(name: ctrl.text));
            case 'Email':     auth.updateProfile(p.copyWith(email: ctrl.text));
            case 'Phone':     auth.updateProfile(p.copyWith(phone: ctrl.text));
            case 'Location':  auth.updateProfile(p.copyWith(city: ctrl.text));
          }
          Navigator.pop(context);
        }, child: Text('Save', style: AppText.label(14, color: AppColors.accent, weight: FontWeight.w700))),
      ],
    ));
  }
}
 
class _Behavior extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: AppCard(child: Column(children: AppData.behaviorStats.map((s) => BehaviorRow(stat: s)).toList())));
}
 
class _FraudChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Fraud attempts blocked',
          style: AppText.body(13, color: AppColors.ink, weight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.safeLight, borderRadius: BorderRadius.circular(6)),
          child: Text('0 successful', style: AppText.tag(9, color: AppColors.safe))),
      ]),
      const SizedBox(height: 4),
      Text('All attempts detected and blocked', style: AppText.label(12)),
      const SizedBox(height: 16),
      SizedBox(height: 120, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.divider, strokeWidth: 1)),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 24,
            getTitlesWidget: (v, _) { final i = v.toInt(); if (i < 0 || i >= AppState.months.length) return const SizedBox(); return Text(AppState.months[i], style: AppText.label(9)); })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [LineChartBarData(
          spots: AppState.monthlyFraud.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
          isCurved: true, color: AppColors.danger, barWidth: 2.5,
          dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: AppColors.danger, strokeWidth: 0)),
          belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.danger.withOpacity(0.12), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        )],
      ))),
      const SizedBox(height: 8),
      Text('Peak in October — 12 attempts, all blocked', style: AppText.label(11)),
    ])));
}
 
class _Security extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(children: [
        SettingToggleRow(icon:'🛡️', iconBg:AppColors.safeLight, title:'Real-Time Protection', subtitle: s.realtimeEnabled ? 'AI monitoring active' : 'Protection paused', value: s.realtimeEnabled, onChanged: (_) => s.toggleRealtime()),
        SettingToggleRow(icon:'🔔', iconBg:AppColors.accentLight, title:'Fraud Alerts', subtitle: s.notifEnabled ? 'Push notifications on' : 'Notifications off', value: s.notifEnabled, onChanged: (_) => s.toggleNotif()),
        SettingToggleRow(icon:'📍', iconBg:AppColors.warnLight, title:'Location Verification', subtitle: s.locationEnabled ? 'Geofencing enabled' : 'Location off', value: s.locationEnabled, onChanged: (_) => s.toggleLocation()),
        SettingToggleRow(icon:'👆', iconBg:AppColors.accentLight, title:'Biometric Lock', subtitle: s.biometricEnabled ? 'Fingerprint / Face ID active' : 'Biometric disabled', value: s.biometricEnabled, onChanged: (_) => s.toggleBiometric()),
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
        SettingNavRow(icon:'✏️', iconBg:AppColors.accentLight, title:'Edit Profile', subtitle:'Update your personal information',
          onTap: () => _editProfile(context)),
        SettingNavRow(icon:'📱', iconBg:AppColors.card2, title:'Trusted Devices', subtitle:'2 devices registered',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(6)),
              child: Text('2', style: AppText.mono(11, color: AppColors.accent))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.ink4, size: 20),
          ])),
        SettingNavRow(icon:'🔑', iconBg:AppColors.card2, title:'Change Password', subtitle:'Last changed 30 days ago'),
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
        SettingNavRow(icon:'🚪', iconBg:AppColors.dangerLight, title:'Sign Out', subtitle:'', arrowColor: AppColors.danger,
          onTap: () => showDialog(context: context, builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Sign Out?', style: AppText.h2(18)),
            content: Text('Your real-time fraud protection will be paused.', style: AppText.body(13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: AppText.label(14, color: AppColors.ink3))),
              TextButton(onPressed: () { Navigator.pop(context); context.read<AuthState>().logout(); },
                child: Text('Sign Out', style: AppText.label(14, color: AppColors.danger, weight: FontWeight.w700))),
            ]))),
      ]),
    );
  }
 
  void _editProfile(BuildContext context) {
    final auth = context.read<AuthState>();
    final p = auth.profile;
    final nc = TextEditingController(text: p.name);
    final pc = TextEditingController(text: p.phone);
    final cc = TextEditingController(text: p.city);
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.card3, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Edit Profile', style: AppText.h2(20)),
            const SizedBox(height: 20),
            _EF('Full Name', nc, Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _EF('Phone', pc, Icons.phone_outlined),
            const SizedBox(height: 12),
            _EF('City', cc, Icons.location_city_outlined),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () { auth.updateProfile(p.copyWith(name: nc.text, phone: pc.text, city: cc.text)); Navigator.pop(ctx); },
              child: Container(width: double.infinity, height: 50,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.accent, AppColors.accentMid]),
                  borderRadius: BorderRadius.circular(12), boxShadow: AppShadow.colored(AppColors.accent)),
                alignment: Alignment.center,
                child: Text('Save Changes', style: AppText.h2(15, color: Colors.white)))),
            const SizedBox(height: 8),
          ])),
      ),
    );
  }
}
 
Widget _EF(String label, TextEditingController ctrl, IconData icon) =>
  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: AppText.label(12, color: AppColors.ink2, weight: FontWeight.w600)),
    const SizedBox(height: 6),
    TextField(controller: ctrl, style: AppText.body(14, color: AppColors.ink),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.ink3, size: 18),
        filled: true, fillColor: AppColors.card2,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), isDense: true)),
  ]);
 
