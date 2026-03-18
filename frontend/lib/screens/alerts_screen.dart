// lib/screens/alerts_screen.dart — v3 CLEAN
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
 
  List<AlertItem> _filtered(List<AlertItem> alerts) => switch (_filter) {
    1 => alerts.where((a) => a.severity == AlertSeverity.danger).toList(),
    2 => alerts.where((a) => a.severity == AlertSeverity.warning).toList(),
    3 => alerts.where((a) => a.severity == AlertSeverity.info).toList(),
    _ => alerts,
  };
 
  @override
  Widget build(BuildContext context) {
    final state  = context.watch<AppState>();
    final list   = _filtered(state.alerts);
    final unread = state.unreadCount;
 
    return Column(children: [
      Container(
        color: AppColors.card,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Alerts', style: AppText.h1(22)),
              Text(unread > 0 ? '$unread unread notification${unread > 1 ? 's' : ''}'
                : 'All caught up',
                style: AppText.label(12, color: unread > 0 ? AppColors.danger : AppColors.safe)),
            ]),
            if (unread > 0) GestureDetector(
              onTap: state.markAllRead,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
                child: Text('Mark all read',
                  style: AppText.label(12, color: AppColors.accent, weight: FontWeight.w700)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ChipFilterRow(chips: _filters, selected: _filter, onSelect: (i) => setState(() => _filter = i)),
        ]),
      ),
 
      // Stats row
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          Expanded(child: _ACount(state.alerts.where((a) => a.severity == AlertSeverity.danger).length,  'Critical', AppColors.danger)),
          const SizedBox(width: 6),
          Expanded(child: _ACount(state.alerts.where((a) => a.severity == AlertSeverity.warning).length, 'Warning',  AppColors.warn)),
          const SizedBox(width: 6),
          Expanded(child: _ACount(state.alerts.where((a) => a.severity == AlertSeverity.info).length,    'Info',     AppColors.accent)),
        ]),
      ),
 
      Expanded(
        child: list.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('✅', style: TextStyle(fontSize: 44)),
              const SizedBox(height: 12),
              Text('All clear!', style: AppText.h2(18)),
              const SizedBox(height: 4),
              Text('No alerts in this category', style: AppText.label(13)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (_, i) => _AlertCard(
                alert: list[i],
                onTap: () => context.read<AppState>().markRead(list[i].id),
              ),
            ),
      ),
    ]);
  }
}
 
Widget _ACount(int count, String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
  decoration: BoxDecoration(color: color.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Flexible(child: Text('$count $label',
      style: AppText.label(11, color: color, weight: FontWeight.w700),
      overflow: TextOverflow.ellipsis)),
  ]),
);
 
class _AlertCard extends StatefulWidget {
  final AlertItem alert;
  final VoidCallback onTap;
  const _AlertCard({required this.alert, required this.onTap});
  @override State<_AlertCard> createState() => _AlertCardState();
}
 
class _AlertCardState extends State<_AlertCard> {
  bool _expanded = false;
 
  (Color, Color, String, String) get _m => switch (widget.alert.severity) {
    AlertSeverity.danger  => (AppColors.dangerLight, AppColors.danger,  '🚨', 'CRITICAL'),
    AlertSeverity.warning => (AppColors.warnLight,   AppColors.warn,    '⚑',  'WARNING'),
    AlertSeverity.info    => (AppColors.safeLight,   AppColors.safe,    '✅', 'INFO'),
  };
 
  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = _m;
    final unread = !widget.alert.isRead;
 
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () { widget.onTap(); setState(() => _expanded = !_expanded); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: unread ? fg.withOpacity(0.3) : AppColors.border, width: unread ? 1.5 : 1),
            boxShadow: unread ? AppShadow.elevated : AppShadow.card,
          ),
          child: Column(children: [
            Padding(padding: const EdgeInsets.all(14), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (unread) Container(width: 7, height: 7, margin: const EdgeInsets.only(top: 5, right: 8),
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
              Container(width: 40, height: 40,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(11)),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 18))),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(widget.alert.title,
                    style: AppText.body(13, color: AppColors.ink,
                      weight: unread ? FontWeight.w700 : FontWeight.w600))),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
                    child: Text(label, style: AppText.tag(8, color: fg))),
                ]),
                const SizedBox(height: 4),
                Text(widget.alert.description,
                  style: AppText.body(12),
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded ? null : TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(widget.alert.time, style: AppText.label(10)),
                  Text(_expanded ? 'Show less ↑' : 'Show more ↓',
                    style: AppText.label(10, color: AppColors.accent, weight: FontWeight.w600)),
                ]),
              ])),
            ])),
 
            if (_expanded) ...[
              const Divider(height: 1, color: AppColors.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(children: [
                  if (widget.alert.severity != AlertSeverity.info) ...[
                    _AChip('Investigate', Icons.search_rounded, AppColors.accent, AppColors.accentLight),
                    const SizedBox(width: 8),
                    _AChip('Dismiss', Icons.check_rounded, AppColors.safe, AppColors.safeLight),
                  ] else
                    _AChip('Mark as read', Icons.visibility_rounded, AppColors.ink2, AppColors.card2),
                ]),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
 
Widget _AChip(String label, IconData icon, Color fg, Color bg) => GestureDetector(
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
      border: Border.all(color: fg.withOpacity(0.2))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: fg),
      const SizedBox(width: 5),
      Text(label, style: AppText.label(12, color: fg, weight: FontWeight.w700)),
    ]),
  ),
);