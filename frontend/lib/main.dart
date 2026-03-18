// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'models/app_state.dart';
import 'models/auth_state.dart';
import 'screens/login_screen.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/analyze_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AppState()),
    ChangeNotifierProvider(create: (_) => AuthState()),
  ], child: const TrustGuardApp()));
}

class TrustGuardApp extends StatelessWidget {
  const TrustGuardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TrustGuard AI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const _AuthGate(),
  );
}

// ── Auth Gate ─────────────────────────────────────────
class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
            .animate(anim),
          child: child),
      ),
      child: switch (auth.step) {
        AuthStep.login  => const LoginScreen(),
        AuthStep.signup => const SignupScreen(),
        AuthStep.setup  => const SetupScreen(),
        AuthStep.done   => const MainShell(),
      },
    );
  }
}

// ── Main Shell ────────────────────────────────────────
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(), TransactionsScreen(), AnalyzeScreen(),
    AlertsScreen(), ProfileScreen(),
  ];

  static const _tabs = [
    _Tab(icon: Icons.home_rounded,         label: 'Home'),
    _Tab(icon: Icons.receipt_long_rounded,  label: 'History'),
    _Tab(icon: Icons.search_rounded,        label: 'Analyze'),
    _Tab(icon: Icons.notifications_rounded, label: 'Alerts',  hasAlert: true),
    _Tab(icon: Icons.person_rounded,        label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(bottom: false,
        child: IndexedStack(index: state.navIndex, children: _screens)),
      bottomNavigationBar: _BottomNav(
        current: state.navIndex, tabs: _tabs,
        unread: state.unreadCount, onTap: state.setNav),
    );
  }
}

class _Tab {
  final IconData icon; final String label; final bool hasAlert;
  const _Tab({required this.icon, required this.label, this.hasAlert = false});
}

class _BottomNav extends StatelessWidget {
  final int current, unread;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.tabs,
    required this.unread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: SafeArea(top: false, child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: tabs.asMap().entries.map((e) {
          final active = e.key == current;
          return Expanded(child: GestureDetector(
            onTap: () => onTap(e.key),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Stack(clipBehavior: Clip.none, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: active ? AppColors.accentLight : Colors.transparent,
                      borderRadius: BorderRadius.circular(12)),
                    child: Icon(e.value.icon, size: 22,
                      color: active ? AppColors.accent : AppColors.ink4)),
                  if (e.value.hasAlert && unread > 0)
                    Positioned(top: -2, right: -4, child: Container(
                      width: 17, height: 17,
                      decoration: BoxDecoration(color: AppColors.danger,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.card, width: 2)),
                      alignment: Alignment.center,
                      child: Text('$unread', style: AppText.tag(8, color: Colors.white)))),
                ]),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppText.label(10,
                    color: active ? AppColors.accent : AppColors.ink4,
                    weight: active ? FontWeight.w700 : FontWeight.w500),
                  child: Text(e.value.label)),
              ]),
            ),
          ));
        }).toList()),
      )),
    );
  }
}
