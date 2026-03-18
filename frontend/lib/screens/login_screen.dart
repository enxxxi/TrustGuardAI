// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool _obscure       = true;
  bool _rememberMe    = true;
  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;
  late Animation<Offset>    _slideAnim;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthState>().clearError();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthState>().login(_emailCtrl.text, _passCtrl.text);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final error = context.watch<AuthState>().errorMessage;
    if (error != null && error != _lastError) {
      _lastError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: AppColors.dark1,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 40),

                  // Logo + brand
                  Center(child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accentMid],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadow.colored(AppColors.accent),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🛡️', style: TextStyle(fontSize: 34)),
                    ),
                    const SizedBox(height: 16),
                    Text('TrustGuard', style: AppText.h1(28, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('AI Fraud Shield for ASEAN',
                      style: AppText.label(14, color: AppColors.darkText)),
                  ])),

                  const SizedBox(height: 40),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadow.elevated,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome back', style: AppText.h1(22)),
                      const SizedBox(height: 4),
                      Text('Sign in to your account to continue',
                        style: AppText.body(13)),
                      const SizedBox(height: 24),

                      // Email
                      _FieldLabel('Email address'),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: AppText.body(14, color: AppColors.ink),
                        decoration: _dec('you@example.com',
                          Icons.email_outlined),
                        validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),

                      // Password
                      _FieldLabel('Password'),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        style: AppText.body(14, color: AppColors.ink),
                        decoration: _dec('••••••••', Icons.lock_outline).copyWith(
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscure = !_obscure),
                            child: Icon(_obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                              color: AppColors.ink3, size: 20),
                          ),
                        ),
                        validator: (v) => v == null || v.length < 6
                          ? 'Password must be at least 6 characters' : null,
                      ),
                      const SizedBox(height: 10),

                      // Remember + Forgot
                      Row(children: [
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: _rememberMe ? AppColors.accent : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _rememberMe ? AppColors.accent : AppColors.border,
                                  width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: _rememberMe
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 13)
                                : null,
                            ),
                            const SizedBox(width: 8),
                            Text('Remember me',
                              style: AppText.label(13, color: AppColors.ink2)),
                          ]),
                        ),
                        const Spacer(),
                        Text('Forgot password?',
                          style: AppText.label(13,
                            color: AppColors.accent, weight: FontWeight.w600)),
                      ]),

                      const SizedBox(height: 22),

                      // Sign in button
                      _PrimaryBtn(
                        label: 'Sign In',
                        loading: auth.loading,
                        onTap: _submit,
                        icon: Icons.arrow_forward_rounded,
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or continue with',
                            style: AppText.label(12)),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ]),
                      const SizedBox(height: 16),

                      // Social buttons
                      Row(children: [
                        Expanded(child: _SocialBtn('Google', '🇬')),
                        const SizedBox(width: 10),
                        Expanded(child: _SocialBtn('Apple', '🍎')),
                      ]),
                    ]),
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Center(child: GestureDetector(
                    onTap: () => context.read<AuthState>().goToSignup(),
                    child: RichText(text: TextSpan(children: [
                      TextSpan(text: "Don't have an account? ",
                        style: AppText.label(14, color: AppColors.darkText)),
                      TextSpan(text: 'Sign up',
                        style: AppText.label(14,
                          color: AppColors.accentMid, weight: FontWeight.w700)),
                    ])),
                  )),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: AppText.label(14),
    prefixIcon: Icon(icon, color: AppColors.ink3, size: 20),
    filled: true,
    fillColor: AppColors.card2,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 1.5)),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.danger)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ── Signup Screen ─────────────────────────────────────
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl= TextEditingController();
  final _formKey    = GlobalKey<FormState>();
  bool _obscure     = true;
  bool _agreed      = false;
  late AnimationController _animCtrl;
  late Animation<double>    _fadeAnim;
  late Animation<Offset>    _slideAnim;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<AuthState>().clearError();
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please agree to the Terms & Privacy Policy',
          style: AppText.body(13, color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      return;
    }
    context.read<AuthState>().signup(
      _nameCtrl.text, _emailCtrl.text, _passCtrl.text);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final error = context.watch<AuthState>().errorMessage;
    if (error != null && error != _lastError) {
      _lastError = error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      backgroundColor: AppColors.dark1,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 24),

                  // Back
                  GestureDetector(
                    onTap: () => context.read<AuthState>().goToLogin(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text('Create account', style: AppText.h1(28, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Join TrustGuard to protect your digital wallet',
                    style: AppText.label(14, color: AppColors.darkText)),
                  const SizedBox(height: 28),

                  // Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppShadow.elevated,
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Full Name'),
                        TextFormField(
                          controller: _nameCtrl,
                          textCapitalization: TextCapitalization.words,
                          style: AppText.body(14, color: AppColors.ink),
                          decoration: _dec('e.g. Aisha Binti Razak',
                            Icons.person_outline_rounded),
                          validator: (v) => v == null || v.trim().length < 2
                            ? 'Enter your full name' : null,
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel('Email address'),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: AppText.body(14, color: AppColors.ink),
                          decoration: _dec('you@example.com',
                            Icons.email_outlined),
                          validator: (v) => v == null || !v.contains('@')
                            ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel('Password'),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: AppText.body(14, color: AppColors.ink),
                          decoration: _dec('Minimum 8 characters',
                            Icons.lock_outline).copyWith(
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                                color: AppColors.ink3, size: 20),
                            ),
                          ),
                          validator: (v) => v == null || v.length < 8
                            ? 'At least 8 characters required' : null,
                        ),
                        const SizedBox(height: 14),

                        _FieldLabel('Confirm Password'),
                        TextFormField(
                          controller: _confirmCtrl,
                          obscureText: _obscure,
                          style: AppText.body(14, color: AppColors.ink),
                          decoration: _dec('Re-enter password',
                            Icons.lock_outline),
                          validator: (v) => v != _passCtrl.text
                            ? 'Passwords do not match' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password strength indicator
                        _PasswordStrength(pass: _passCtrl.text),
                        const SizedBox(height: 16),

                        // Terms
                        GestureDetector(
                          onTap: () => setState(() => _agreed = !_agreed),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
                                decoration: BoxDecoration(
                                  color: _agreed ? AppColors.accent : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: _agreed ? AppColors.accent : AppColors.border,
                                    width: 1.5)),
                                alignment: Alignment.center,
                                child: _agreed
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 13)
                                  : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: RichText(text: TextSpan(children: [
                                TextSpan(text: 'I agree to the ',
                                  style: AppText.body(12)),
                                TextSpan(text: 'Terms of Service',
                                  style: AppText.body(12,
                                    color: AppColors.accent,
                                    weight: FontWeight.w600)),
                                TextSpan(text: ' and ',
                                  style: AppText.body(12)),
                                TextSpan(text: 'Privacy Policy',
                                  style: AppText.body(12,
                                    color: AppColors.accent,
                                    weight: FontWeight.w600)),
                              ]))),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        _PrimaryBtn(
                          label: 'Create Account',
                          loading: auth.loading,
                          onTap: _submit,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ]),
                  ),

                  const SizedBox(height: 24),

                  Center(child: GestureDetector(
                    onTap: () => context.read<AuthState>().goToLogin(),
                    child: RichText(text: TextSpan(children: [
                      TextSpan(text: 'Already have an account? ',
                        style: AppText.label(14, color: AppColors.darkText)),
                      TextSpan(text: 'Sign in',
                        style: AppText.label(14,
                          color: AppColors.accentMid, weight: FontWeight.w700)),
                    ])),
                  )),

                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: AppText.label(14),
    prefixIcon: Icon(icon, color: AppColors.ink3, size: 20),
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
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.danger)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ── Password Strength ────────────────────────────────
class _PasswordStrength extends StatelessWidget {
  final String pass;
  const _PasswordStrength({required this.pass});

  int get _strength {
    int s = 0;
    if (pass.length >= 8)                      s++;
    if (pass.contains(RegExp(r'[A-Z]')))       s++;
    if (pass.contains(RegExp(r'[0-9]')))       s++;
    if (pass.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (pass.isEmpty) return const SizedBox();
    final s = _strength;
    final color = s <= 1 ? AppColors.danger : s == 2 ? AppColors.warn : AppColors.safe;
    final label = s <= 1 ? 'Weak' : s == 2 ? 'Fair' : s == 3 ? 'Good' : 'Strong';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: List.generate(4, (i) => Expanded(child: Container(
        height: 4,
        margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
        decoration: BoxDecoration(
          color: i < s ? color : AppColors.border,
          borderRadius: BorderRadius.circular(2)),
      )))),
      const SizedBox(height: 5),
      Text('Password strength: $label',
        style: AppText.label(11, color: color, weight: FontWeight.w600)),
    ]);
  }
}

// ── Shared widgets ────────────────────────────────────
Widget _FieldLabel(String text) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Text(text, style: AppText.label(12,
    color: AppColors.ink2, weight: FontWeight.w600)),
);

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  final IconData? icon;
  const _PrimaryBtn({required this.label, required this.loading,
    required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentMid],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading ? [] : AppShadow.colored(AppColors.accent),
        ),
        alignment: Alignment.center,
        child: loading
          ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label, style: AppText.h2(15, color: Colors.white)),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Icon(icon, color: Colors.white, size: 18),
              ],
            ]),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label, emoji;
  const _SocialBtn(this.label, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(label, style: AppText.label(13,
          color: AppColors.ink2, weight: FontWeight.w600)),
      ]),
    );
  }
}
