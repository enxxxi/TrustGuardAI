// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/transaction.dart';

// ── Status Pill ──
class StatusPill extends StatelessWidget {
  final TxStatus status;
  final int? score;
  const StatusPill({super.key, required this.status, this.score});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      TxStatus.approved => (AppColors.safeLight, AppColors.safe, '✓ ${score ?? ""}%'),
      TxStatus.flagged  => (AppColors.warnLight,   AppColors.warn,   '⚑ ${score ?? ""}%'),
      TxStatus.blocked  => (AppColors.dangerLight, AppColors.danger, '⛔ ${score ?? ""}%'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppText.mono(10, color: fg, weight: FontWeight.w600)),
    );
  }
}

// ── Section Header ──
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.display(16)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: AppText.body(12, color: AppColors.accent, weight: FontWeight.w500)),
            ),
        ],
      ),
    );
  }
}

// ── App Card ──
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double radius;
  const AppCard({super.key, required this.child, this.padding, this.color, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
    );
  }
}

// ── Risk Bar ──
class RiskBar extends StatelessWidget {
  final int score;
  const RiskBar({super.key, required this.score});

  Color get _color {
    if (score < 30) return AppColors.safe;
    if (score < 65) return AppColors.warn;
    return AppColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: AppColors.border,
              color: _color,
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text('$score%', style: AppText.mono(12, color: _color)),
      ],
    );
  }
}

// ── Behavior Row ──
class BehaviorRow extends StatelessWidget {
  final String icon;
  final String label;
  final double value;
  final String display;
  const BehaviorRow({super.key, required this.icon, required this.label, required this.value, required this.display});

  @override
  Widget build(BuildContext context) {
    final color = value > 0.6 ? AppColors.safe : value > 0.3 ? AppColors.accent : AppColors.warn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: AppText.body(12, weight: FontWeight.w600)),
                    Text(display, style: AppText.mono(10, color: AppColors.ink3)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppColors.border,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle Row ──
class SettingToggleRow extends StatefulWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool initialValue;
  const SettingToggleRow({
    super.key, required this.icon, required this.iconBg,
    required this.title, required this.subtitle, this.initialValue = true,
  });
  @override State<SettingToggleRow> createState() => _SettingToggleRowState();
}

class _SettingToggleRowState extends State<SettingToggleRow> {
  late bool _value;
  @override void initState() { super.initState(); _value = widget.initialValue; }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: widget.iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(widget.icon, style: const TextStyle(fontSize: 17)),
        ),
        title: Text(widget.title, style: AppText.body(14, weight: FontWeight.w500)),
        subtitle: Text(widget.subtitle, style: AppText.body(11, color: AppColors.ink3)),
        trailing: Switch.adaptive(
          value: _value,
          onChanged: (v) => setState(() => _value = v),
          activeColor: AppColors.safe,
        ),
      ),
    );
  }
}

// ── Setting Nav Row ──
class SettingNavRow extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Color? arrowColor;
  const SettingNavRow({
    super.key, required this.icon, required this.iconBg,
    required this.title, required this.subtitle, this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))]),
      child: ListTile(
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 17)),
        ),
        title: Text(title, style: AppText.body(14, weight: FontWeight.w500)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: AppText.body(11, color: AppColors.ink3)) : null,
        trailing: Icon(Icons.chevron_right, color: arrowColor ?? AppColors.ink3),
      ),
    );
  }
}
