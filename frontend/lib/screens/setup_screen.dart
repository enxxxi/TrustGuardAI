// lib/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/auth_state.dart';
 
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override State<SetupScreen> createState() => _SetupScreenState();
}
 
class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0=personal, 1=wallet, 2=security
  late PageController _pageCtrl;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
 
  // Step 1 — Personal
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl  = TextEditingController();
  String _country  = 'Malaysia';
  String _avatar   = '👤';
 
  // Step 2 — Wallet
  final List<String> _wallets    = [];
  String _occupation             = 'Employed';
 
  // Step 3 — Security
  bool _realtimeOn  = true;
  bool _alertsOn    = true;
  bool _locationOn  = true;
  bool _biometricOn = false;
 
  final _avatars = ['👤','👨','👩','🧑','👦','👧','🧔','👱'];
  final _countries = ['Malaysia','Indonesia','Singapore','Thailand',
    'Philippines','Vietnam','Myanmar','Cambodia'];
  final _occupations = ['Employed','Self-employed','Gig Worker',
    'Student','Business Owner','Freelancer','Other'];
  final _walletOptions = [
    ('GrabPay','🚗'), ("Touch 'n Go",'🔵'), ('Boost','💜'),
    ('BigPay','💙'), ('Shopee Pay','🟠'), ('MAE','🟢'),
    ('Lazada Wallet','🔴'), ('Other','💳'),
  ];
 
  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    // Pre-fill from existing profile
    final p = context.read<AuthState>().profile;
    _nameCtrl.text  = p.name;
    _phoneCtrl.text = p.phone;
    _cityCtrl.text  = p.city;
    _country        = p.country;
    _avatar         = p.avatarEmoji;
    _occupation     = p.occupation;
    _wallets.add(p.walletType);
  }
 
  @override
  void dispose() {
    _pageCtrl.dispose(); _animCtrl.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _cityCtrl.dispose();
    super.dispose();
  }
 
  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }
 
  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut);
    }
  }
 
  void _finish() {
    final auth = context.read<AuthState>();
    final updated = auth.profile.copyWith(
      name:        _nameCtrl.text.trim(),
      phone:       _phoneCtrl.text.trim(),
      city:        _cityCtrl.text.trim(),
      country:     _country,
      walletType:  _wallets.isNotEmpty ? _wallets.first : 'GrabPay',
      occupation:  _occupation,
      avatarEmoji: _avatar,
    );
    auth.completeSetup(updated);
  }
 
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(children: [
            _Header(step: _step, onBack: _step > 0 ? _back : null),
            _ProgressBar(step: _step),
            Expanded(child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PersonalStep(
                  nameCtrl: _nameCtrl, phoneCtrl: _phoneCtrl,
                  cityCtrl: _cityCtrl, country: _country,
                  avatar: _avatar, countries: _countries, avatars: _avatars,
                  onCountry: (v) => setState(() => _country = v),
                  onAvatar:  (v) => setState(() => _avatar  = v),
                ),
                _WalletStep(
                  selected: _wallets, options: _walletOptions,
                  occupation: _occupation, occupations: _occupations,
                  onToggleWallet: (w) => setState(() {
                    _wallets.contains(w) ? _wallets.remove(w) : _wallets.add(w);
                  }),
                  onOccupation: (v) => setState(() => _occupation = v),
                ),
                _SecurityStep(
                  realtimeOn: _realtimeOn, alertsOn: _alertsOn,
                  locationOn: _locationOn, biometricOn: _biometricOn,
                  onRealtime:  (v) => setState(() => _realtimeOn  = v),
                  onAlerts:    (v) => setState(() => _alertsOn    = v),
                  onLocation:  (v) => setState(() => _locationOn  = v),
                  onBiometric: (v) => setState(() => _biometricOn = v),
                ),
              ],
            )),
            // Bottom CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: _SetupBtn(
                label: _step < 2 ? 'Continue' : 'Start Protection',
                loading: auth.loading,
                onTap: _next,
                isLast: _step == 2,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
 
// ── Header ────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  const _Header({required this.step, this.onBack});
 
  static const _titles = [
    'Personal Info', 'Your Wallets', 'Security Setup'];
  static const _subs = [
    'Tell us about yourself', 'Select your digital wallets',
    'Configure your protection'];
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40, height: 40, margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadow.card,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 15, color: AppColors.ink2),
            ),
          ),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentMid]),
                borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Text('🛡️', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Text('Setup · Step ${step + 1} of 3',
              style: AppText.tag(11, color: AppColors.accent)),
          ]),
          const SizedBox(height: 6),
          Text(_titles[step], style: AppText.h1(22)),
          Text(_subs[step], style: AppText.body(13)),
        ])),
      ]),
    );
  }
}
 
// ── Progress Bar ─────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int step;
  const _ProgressBar({required this.step});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(children: List.generate(3, (i) => Expanded(child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 4,
        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
        decoration: BoxDecoration(
          color: i <= step ? AppColors.accent : AppColors.border,
          borderRadius: BorderRadius.circular(2)),
      )))),
    );
  }
}
 
// ── Step 1: Personal ─────────────────────────────────
class _PersonalStep extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, cityCtrl;
  final String country, avatar;
  final List<String> countries, avatars;
  final ValueChanged<String> onCountry, onAvatar;
  const _PersonalStep({
    required this.nameCtrl, required this.phoneCtrl, required this.cityCtrl,
    required this.country, required this.avatar,
    required this.countries, required this.avatars,
    required this.onCountry, required this.onAvatar});
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 
        // Avatar picker
        _SetupCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Choose your avatar', style: AppText.h2(14)),
          const SizedBox(height: 12),
          // Wrap instead of Row — prevents overflow on narrow screens
          Wrap(spacing: 8, runSpacing: 8, children: avatars.map((e) => GestureDetector(
            onTap: () => onAvatar(e),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: e == avatar ? AppColors.accentLight : AppColors.card2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: e == avatar ? AppColors.accent : AppColors.border,
                  width: e == avatar ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: Text(e, style: const TextStyle(fontSize: 22)),
            ),
          )).toList()),
        ])),
 
        const SizedBox(height: 12),
 
        _SetupCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SLabel('Full Name'),
          _SField(ctrl: nameCtrl, hint: 'e.g. Aisha Binti Razak',
            icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _SLabel('Phone Number'),
          _SField(ctrl: phoneCtrl, hint: '+60 12-345 6789',
            icon: Icons.phone_outlined,
            type: TextInputType.phone),
        ])),
 
        const SizedBox(height: 12),
 
        _SetupCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SLabel('City'),
          _SField(ctrl: cityCtrl, hint: 'e.g. Johor Bahru',
            icon: Icons.location_city_outlined),
          const SizedBox(height: 14),
          _SLabel('Country'),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: country,
              isExpanded: true,
              style: AppText.body(14, color: AppColors.ink),
              items: countries.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: AppText.body(14, color: AppColors.ink)),
              )).toList(),
              onChanged: (v) => v != null ? onCountry(v) : null,
            )),
          ),
        ])),
 
        const SizedBox(height: 12),
      ]),
    );
  }
}
 
// ── Step 2: Wallet ────────────────────────────────────
class _WalletStep extends StatelessWidget {
  final List<String> selected;
  final List<(String, String)> options;
  final String occupation;
  final List<String> occupations;
  final ValueChanged<String> onToggleWallet, onOccupation;
  const _WalletStep({
    required this.selected, required this.options,
    required this.occupation, required this.occupations,
    required this.onToggleWallet, required this.onOccupation});
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
 
        _SetupCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select your digital wallets',
            style: AppText.h2(14)),
          const SizedBox(height: 4),
          Text('Choose all wallets you use regularly',
            style: AppText.label(12)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: options.map((opt) {
            final (name, emoji) = opt;
            final isOn = selected.contains(name);
            return GestureDetector(
              onTap: () => onToggleWallet(name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOn ? AppColors.accentLight : AppColors.card2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOn ? AppColors.accent : AppColors.border,
                    width: isOn ? 1.5 : 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(name, style: AppText.label(13,
                    color: isOn ? AppColors.accent : AppColors.ink2,
                    weight: isOn ? FontWeight.w700 : FontWeight.w500)),
                  if (isOn) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 14),
                  ],
                ]),
              ),
            );
          }).toList()),
        ])),
 
        const SizedBox(height: 12),
 
        _SetupCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Occupation', style: AppText.h2(14)),
          const SizedBox(height: 4),
          Text('Helps us tailor fraud patterns to your profile',
            style: AppText.label(12)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: occupations.map((o) {
            final isOn = o == occupation;
            return GestureDetector(
              onTap: () => onOccupation(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isOn ? AppColors.ink : AppColors.card2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isOn ? AppColors.ink : AppColors.border),
                ),
                child: Text(o, style: AppText.label(13,
                  color: isOn ? Colors.white : AppColors.ink2,
                  weight: isOn ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
          }).toList()),
        ])),
 
        const SizedBox(height: 12),
 
        // Info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentSoft),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline_rounded,
              color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'TrustGuard uses your wallet & occupation data only for fraud pattern modeling. Your data is never sold.',
              style: AppText.body(11, color: AppColors.accent))),
          ]),
        ),
 
        const SizedBox(height: 12),
      ]),
    );
  }
}
 
// ── Step 3: Security ──────────────────────────────────
class _SecurityStep extends StatelessWidget {
  final bool realtimeOn, alertsOn, locationOn, biometricOn;
  final ValueChanged<bool> onRealtime, onAlerts, onLocation, onBiometric;
  const _SecurityStep({
    required this.realtimeOn, required this.alertsOn,
    required this.locationOn, required this.biometricOn,
    required this.onRealtime, required this.onAlerts,
    required this.onLocation, required this.onBiometric});
 
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(children: [
 
        // Trust score preview
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.dark1, AppColors.dark2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(width: 60, height: 60,
                child: CircularProgressIndicator(
                  value: _protectionScore / 100,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: AppColors.safe, strokeWidth: 5)),
              Text('$_protectionScore%',
                style: AppText.mono(14, color: Colors.white)),
            ]),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Protection Score', style: AppText.h2(14, color: Colors.white)),
              const SizedBox(height: 4),
              Text('Enable all options for maximum security',
                style: AppText.body(11, color: AppColors.darkText)),
            ])),
          ]),
        ),
 
        const SizedBox(height: 14),
 
        _SetupCard(child: Column(children: [
          _SecurityToggle(
            icon: '🛡️', iconBg: AppColors.safeLight,
            title: 'Real-Time Protection',
            desc: 'AI monitors every transaction instantly',
            value: realtimeOn, onChanged: onRealtime,
            recommended: true),
          const Divider(height: 1, color: AppColors.divider),
          _SecurityToggle(
            icon: '🔔', iconBg: AppColors.accentLight,
            title: 'Fraud Alerts',
            desc: 'Push notifications for suspicious activity',
            value: alertsOn, onChanged: onAlerts,
            recommended: true),
          const Divider(height: 1, color: AppColors.divider),
          _SecurityToggle(
            icon: '📍', iconBg: AppColors.warnLight,
            title: 'Location Verification',
            desc: 'Detect transactions from unusual locations',
            value: locationOn, onChanged: onLocation,
            recommended: true),
          const Divider(height: 1, color: AppColors.divider),
          _SecurityToggle(
            icon: '👆', iconBg: AppColors.accentLight,
            title: 'Biometric Lock',
            desc: 'Fingerprint or Face ID for added security',
            value: biometricOn, onChanged: onBiometric,
            recommended: false),
        ])),
 
        const SizedBox(height: 12),
 
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.safeLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.safeSoft),
          ),
          child: Row(children: [
            const Text('🔒', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('You\'re protected by XGBoost AI',
                style: AppText.body(13, color: AppColors.safe, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('96.4% detection accuracy · 1.2% false positives',
                style: AppText.label(11, color: AppColors.safe)),
            ])),
          ]),
        ),
 
        const SizedBox(height: 12),
      ]),
    );
  }
 
  int get _protectionScore {
    int s = 0;
    if (realtimeOn)  s += 35;
    if (alertsOn)    s += 25;
    if (locationOn)  s += 25;
    if (biometricOn) s += 15;
    return s;
  }
}
 
class _SecurityToggle extends StatelessWidget {
  final String icon, title, desc;
  final Color iconBg;
  final bool value, recommended;
  final ValueChanged<bool> onChanged;
  const _SecurityToggle({required this.icon, required this.iconBg,
    required this.title, required this.desc, required this.value,
    required this.onChanged, required this.recommended});
 
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 17)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
            Text(title, style: AppText.body(13,
              color: AppColors.ink, weight: FontWeight.w600)),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.safeLight,
                  borderRadius: BorderRadius.circular(4)),
                child: Text('RECOMMENDED',
                  style: AppText.tag(7, color: AppColors.safe)),
              ),
          ]),
          const SizedBox(height: 2),
          Text(desc, style: AppText.label(11)),
        ])),
        Switch.adaptive(
          value: value, onChanged: onChanged,
          activeColor: AppColors.safe, activeTrackColor: AppColors.safeSoft),
      ]),
    );
  }
}
 
// ── Setup shared widgets ──────────────────────────────
class _SetupCard extends StatelessWidget {
  final Widget child;
  const _SetupCard({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border.withOpacity(0.6)),
      boxShadow: AppShadow.card,
    ),
    child: child,
  );
}
 
Widget _SLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: AppText.label(12,
    color: AppColors.ink2, weight: FontWeight.w600)),
);
 
class _SField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType type;
  const _SField({required this.ctrl, required this.hint,
    required this.icon, this.type = TextInputType.text});
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: AppText.body(14, color: AppColors.ink),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: AppText.label(14),
      prefixIcon: Icon(icon, color: AppColors.ink3, size: 18),
      filled: true, fillColor: AppColors.card2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      isDense: true,
    ),
  );
}
 
class _SetupBtn extends StatelessWidget {
  final String label;
  final bool loading, isLast;
  final VoidCallback onTap;
  const _SetupBtn({required this.label, required this.loading,
    required this.onTap, required this.isLast});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLast
            ? [AppColors.safe, const Color(0xFF10B981)]
            : [AppColors.accent, AppColors.accentMid],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: loading ? [] : AppShadow.colored(
          isLast ? AppColors.safe : AppColors.accent),
      ),
      alignment: Alignment.center,
      child: loading
        ? const SizedBox(width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (isLast) const Text('🛡️', style: TextStyle(fontSize: 18)),
            if (isLast) const SizedBox(width: 8),
            Text(label, style: AppText.h2(16, color: Colors.white)),
            const SizedBox(width: 8),
            Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
              color: Colors.white, size: 18),
          ]),
    ),
  );
}