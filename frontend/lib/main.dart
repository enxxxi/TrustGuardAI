// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'models/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/analyze_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(ChangeNotifierProvider(
    create: (_) => AppState(),
    child: const TrustGuardApp(),
  ));
}

class TrustGuardApp extends StatelessWidget {
  const TrustGuardApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TrustGuard AI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.theme,
    home: const MainShell(),
  );
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const _screens = [
    HomeScreen(),
    TransactionsScreen(),
    AnalyzeScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  static const _tabs = [
    _Tab(icon: '🏠', label: 'Home'),
    _Tab(icon: '📋', label: 'History'),
    _Tab(icon: '🔍', label: 'Analyze'),
    _Tab(icon: '🔔', label: 'Alerts', hasAlert: true),
    _Tab(icon: '👤', label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: state.navIndex, children: _screens),
      ),
      bottomNavigationBar: _BottomNav(
        current: state.navIndex,
        tabs: _tabs,
        unreadCount: state.unreadCount,
        onTap: state.setNav,
      ),
    );
  }
}

class _Tab {
  final String icon, label;
  final bool hasAlert;
  const _Tab({required this.icon, required this.label, this.hasAlert = false});
}

class _BottomNav extends StatelessWidget {
  final int current;
  final List<_Tab> tabs;
  final int unreadCount;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.tabs, required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: tabs.asMap().entries.map((e) {
              final active = e.key == current;
              final isAlerts = e.value.hasAlert;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    // Active indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: active ? 32 : 0, height: 2.5,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedScale(
                          scale: active ? 1.12 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: active ? AppColors.accentLight : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(e.value.icon, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        if (isAlerts && unreadCount > 0) Positioned(
                          top: -2, right: -4,
                          child: Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.danger, shape: BoxShape.circle,
                              border: Border.all(color: AppColors.card, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text('$unreadCount',
                              style: AppText.mono(9, color: Colors.white, weight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(e.value.label, style: AppText.body(10,
                      color: active ? AppColors.accent : AppColors.ink3,
                      weight: active ? FontWeight.w700 : FontWeight.w400)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
