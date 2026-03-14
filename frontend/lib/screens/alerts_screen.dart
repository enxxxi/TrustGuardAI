// lib/screens/alerts_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';
import '../widgets/common_widgets.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _filterIndex = 0;
  final _filters = ['All', 'Blocked', 'Flagged', 'System'];

  List<AlertItem> get _filtered {
    if (_filterIndex == 0) return AppData.alerts;
    if (_filterIndex == 1) return AppData.alerts.where((a) => a.severity == AlertSeverity.danger).toList();
    if (_filterIndex == 2) return AppData.alerts.where((a) => a.severity == AlertSeverity.warning).toList();
    return AppData.alerts.where((a) => a.severity == AlertSeverity.info).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AlertsHeader(
          filterIndex: _filterIndex,
          filters: _filters,
          onFilter: (i) => setState(() => _filterIndex = i),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _filtered.length,
            itemBuilder: (_, i) => _AlertCard(alert: _filtered[i]),
          ),
        ),
      ],
    );
  }
}

class _AlertsHeader extends StatelessWidget {
  final int filterIndex;
  final List<String> filters;
  final ValueChanged<int> onFilter;
  const _AlertsHeader({required this.filterIndex, required this.filters, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alerts', style: AppText.display(22)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.asMap().entries.map((e) {
                final active = e.key == filterIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onFilter(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: active ? AppColors.ink : AppColors.card2,
                        borderRadius: BorderRadius.circular(20),
                        border: active ? null : Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        e.value,
                        style: AppText.body(12, color: active ? Colors.white : AppColors.ink2, weight: FontWeight.w600),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertItem alert;
  const _AlertCard({required this.alert});

  (Color bg, Color iconBg, String icon, Widget pill) get _meta => switch (alert.severity) {
    AlertSeverity.danger => (
        AppColors.dangerLight, AppColors.dangerLight, '🚨',
        _Pill('BLOCKED', AppColors.danger, AppColors.dangerLight),
      ),
    AlertSeverity.warning => (
        AppColors.warnLight, AppColors.warnLight, '⚑',
        _Pill('FLAGGED', AppColors.warn, AppColors.warnLight),
      ),
    AlertSeverity.info => (
        AppColors.safeLight, AppColors.safeLight, '✅',
        _Pill('SYSTEM', AppColors.safe, AppColors.safeLight),
      ),
  };

  @override
  Widget build(BuildContext context) {
    final (_, iconBg, icon, pill) = _meta;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(icon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title, style: AppText.body(13, weight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(alert.description, style: AppText.body(11, color: AppColors.ink3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 7),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(alert.time, style: AppText.mono(10, color: AppColors.ink3)),
                      pill,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _Pill(String label, Color fg, Color bg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Text(label, style: AppText.mono(9, color: fg, weight: FontWeight.w600)),
);
