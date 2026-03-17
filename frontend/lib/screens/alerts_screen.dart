// lib/screens/alerts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/common_widgets.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});
  @override State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _filter = 0;
  final _filters = ['All', 'Critical', 'Warning', 'Info'];

  List<AlertItem> _getFiltered(List<AlertItem> alerts) {
    return switch (_filter) {
      1 => alerts.where((a) => a.severity == AlertSeverity.danger).toList(),
      2 => alerts.where((a) => a.severity == AlertSeverity.warning).toList(),
      3 => alerts.where((a) => a.severity == AlertSeverity.info).toList(),
      _ => alerts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = _getFiltered(state.alerts);
    final unread = state.unreadCount;

    return Column(children: [
      // Header
      Container(
        color: AppColors.card,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Alerts', style: AppText.display(22)),
              if (unread > 0)
                Text('$unread unread notification${unread > 1 ? 's' : ''}',
                  style: AppText.body(12, color: AppColors.danger)),
            ]),
            if (unread > 0)
              GestureDetector(
                onTap: state.markAllRead,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
                  child: Text('Mark all read', style: AppText.body(12, color: AppColors.accent, weight: FontWeight.w600)),
                ),
              ),
          ]),
          const SizedBox(height: 12),
          ChipFilterRow(chips: _filters, selected: _filter, onSelect: (i) => setState(() => _filter = i)),
        ]),
      ),

      // Stats row
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          _AlertCount(state.alerts.where((a) => a.severity == AlertSeverity.danger).length, 'Critical', AppColors.danger),
          const SizedBox(width: 8),
          _AlertCount(state.alerts.where((a) => a.severity == AlertSeverity.warning).length, 'Warning', AppColors.warn),
          const SizedBox(width: 8),
          _AlertCount(state.alerts.where((a) => a.severity == AlertSeverity.info).length, 'Info', AppColors.accent),
        ]),
      ),

      // List
      Expanded(
        child: filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('✅', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text('All clear!', style: AppText.display(18)),
              const SizedBox(height: 4),
              Text('No alerts in this category', style: AppText.body(13, color: AppColors.ink3)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _AlertCard(
                alert: filtered[i],
                onTap: () => context.read<AppState>().markRead(filtered[i].id),
              ),
            ),
      ),
    ]);
  }
}

Widget _AlertCount(int count, String label, Color color) => Expanded(
  child: Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text('$count $label', style: AppText.body(11, color: color, weight: FontWeight.w600)),
    ]),
  ),
);

class _AlertCard extends StatefulWidget {
  final AlertItem alert;
  final VoidCallback onTap;
  const _AlertCard({required this.alert, required this.onTap});
  @override State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;

  (Color, Color, String, String) get _meta => switch (widget.alert.severity) {
    AlertSeverity.danger  => (AppColors.dangerLight, AppColors.danger,  '🚨', 'CRITICAL'),
    AlertSeverity.warning => (AppColors.warnLight,   AppColors.warn,    '⚑',  'WARNING'),
    AlertSeverity.info    => (AppColors.safeLight,   AppColors.safe,    '✅', 'INFO'),
  };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = _meta;
    final isUnread = !widget.alert.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          setState(() => _expanded = !_expanded);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnread ? fg.withOpacity(0.3) : AppColors.border,
              width: isUnread ? 1.5 : 1,
            ),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isUnread ? 0.08 : 0.04),
              blurRadius: isUnread ? 20 : 12,
              offset: const Offset(0, 2),
            )],
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Unread dot
                if (isUnread) Container(
                  width: 8, height: 8, margin: const EdgeInsets.only(top: 4, right: 8),
                  decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                ),
                // Icon
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
                  alignment: Alignment.center,
                  child: Text(icon, style: const TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(widget.alert.title,
                      style: AppText.body(13, weight: isUnread ? FontWeight.w700 : FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
                      child: Text(label, style: AppText.mono(8, color: fg, weight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(widget.alert.description,
                    style: AppText.body(11, color: AppColors.ink3),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(widget.alert.time, style: AppText.mono(10, color: AppColors.ink3)),
                    Text(_expanded ? 'Show less ↑' : 'Show more ↓',
                      style: AppText.body(10, color: AppColors.accent, weight: FontWeight.w500)),
                  ]),
                ])),
              ]),
            ),

            // Expanded actions
            if (_expanded) ...[
              Container(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(children: [
                  if (widget.alert.severity != AlertSeverity.info) ...[
                    _ActionChip('🔍 Investigate', AppColors.accent, AppColors.accentLight),
                    const SizedBox(width: 8),
                    _ActionChip('✓ Dismiss', AppColors.safe, AppColors.safeLight),
                  ] else
                    _ActionChip('👁 Mark as read', AppColors.ink2, AppColors.card2),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

Widget _ActionChip(String label, Color fg, Color bg) => GestureDetector(
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
      border: Border.all(color: fg.withOpacity(0.2))),
    child: Text(label, style: AppText.body(12, color: fg, weight: FontWeight.w600)),
  ),
);
