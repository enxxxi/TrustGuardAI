// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';

// ── App Card ─────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final Border? border;
  const AppCard({super.key, required this.child, this.padding, this.color,
    this.radius = 16, this.onTap, this.border});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          border: border ?? Border.all(color: AppColors.border.withOpacity(0.6)),
          boxShadow: AppShadow.card,
        ),
        child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

// ── Status Pill ──────────────────────────────────────
class StatusPill extends StatelessWidget {
  final TxStatus status;
  final int? score;
  final bool large;
  const StatusPill({super.key, required this.status, this.score, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon, label) = switch (status) {
      TxStatus.approved => (AppColors.safeLight,   AppColors.safe,   '✓', score != null ? '${score}%' : 'Safe'),
      TxStatus.flagged  => (AppColors.warnLight,    AppColors.warn,   '⚑',  score != null ? '${score}%' : 'Review'),
      TxStatus.blocked  => (AppColors.dangerLight,  AppColors.danger, '✕', score != null ? '${score}%' : 'Blocked'),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 8, vertical: large ? 6 : 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: TextStyle(fontSize: large ? 12 : 10, color: fg)),
        const SizedBox(width: 4),
        Text(label, style: AppText.tag(large ? 11 : 9, color: fg)),
      ]),
    );
  }
}

// ── Risk Badge ───────────────────────────────────────
class RiskBadge extends StatelessWidget {
  final int score;
  const RiskBadge({super.key, required this.score});

  Color get _color {
    if (score < 30) return AppColors.safe;
    if (score < 60) return AppColors.warn;
    return AppColors.danger;
  }

  String get _label {
    if (score < 30) return 'LOW';
    if (score < 60) return 'MED';
    return 'HIGH';
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: _color.withOpacity(0.12),
            color: _color,
            minHeight: 4,
          ),
        ),
      ),
      const SizedBox(width: 6),
      Text('$score%', style: AppText.mono(11, color: _color)),
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(_label, style: AppText.tag(8, color: _color)),
      ),
    ]);
  }
}

// ── Section Header ────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets? padding;
  const SectionHeader({super.key, required this.title, this.action, this.onAction, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(title, style: AppText.h2(15)),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
              style: AppText.label(13, color: AppColors.accent, weight: FontWeight.w600)),
          ),
      ]),
    );
  }
}

// ── Info Row ─────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool divider;
  const InfoRow({super.key, required this.label, required this.value,
    this.valueColor, this.divider = true});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppText.body(13, color: AppColors.ink3)),
          Flexible(child: Text(value, style: AppText.body(13,
            color: valueColor ?? AppColors.ink, weight: FontWeight.w600),
            textAlign: TextAlign.right)),
        ]),
      ),
      if (divider) const Divider(height: 1, color: AppColors.divider),
    ]);
  }
}

// ── Behavior Row ─────────────────────────────────────
class BehaviorRow extends StatelessWidget {
  final BehaviorStat stat;
  const BehaviorRow({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final barColor = stat.isAnomaly ? AppColors.danger : AppColors.safe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: stat.isAnomaly ? AppColors.dangerLight : AppColors.accentLight,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(stat.icon, style: const TextStyle(fontSize: 15)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(stat.label, style: AppText.body(13, weight: FontWeight.w600, color: AppColors.ink)),
            Row(children: [
              if (stat.isAnomaly) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(5)),
                child: Text('ANOMALY', style: AppText.tag(8, color: AppColors.danger)),
              ),
            ]),
          ]),
          const SizedBox(height: 6),
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: stat.normalValue,
                backgroundColor: AppColors.card3, color: AppColors.accentSoft, minHeight: 8)),
            ClipRRect(borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: stat.currentValue,
                backgroundColor: Colors.transparent, color: barColor.withOpacity(0.75), minHeight: 8)),
          ]),
          const SizedBox(height: 5),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Baseline: ${stat.normalDisplay}', style: AppText.label(10, color: AppColors.ink4)),
            Text('Now: ${stat.currentDisplay}',
              style: AppText.label(10, color: barColor, weight: FontWeight.w700)),
          ]),
        ])),
      ]),
    );
  }
}

// ── Setting Toggle ───────────────────────────────────
class SettingToggleRow extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SettingToggleRow({super.key, required this.icon, required this.iconBg,
    required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: AppShadow.card,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(title, style: AppText.body(14, color: AppColors.ink, weight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppText.label(12)),
        trailing: Switch.adaptive(value: value, onChanged: onChanged,
          activeColor: AppColors.safe, activeTrackColor: AppColors.safeSoft),
      ),
    );
  }
}

// ── Setting Nav Row ──────────────────────────────────
class SettingNavRow extends StatelessWidget {
  final String icon, title, subtitle;
  final Color iconBg;
  final Color? arrowColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  const SettingNavRow({super.key, required this.icon, required this.iconBg,
    required this.title, required this.subtitle,
    this.arrowColor, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border.withOpacity(0.6)),
          boxShadow: AppShadow.card,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 4, 12, 4),
          leading: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          title: Text(title, style: AppText.body(14, color: AppColors.ink, weight: FontWeight.w600)),
          subtitle: subtitle.isNotEmpty ? Text(subtitle, style: AppText.label(12)) : null,
          trailing: trailing ?? Icon(Icons.chevron_right_rounded,
            color: arrowColor ?? AppColors.ink4, size: 20),
        ),
      ),
    );
  }
}

// ── Gradient Button ──────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final VoidCallback? onTap;
  final bool loading;
  final List<Color> colors;
  const GradientButton({super.key, required this.label, this.emoji, this.onTap,
    this.loading = false, this.colors = const [AppColors.accent, AppColors.accentMid]});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: loading ? [AppColors.ink3, AppColors.ink4] : colors,
            begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading ? [] : AppShadow.colored(colors.first),
        ),
        alignment: Alignment.center,
        child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8)],
              Text(label, style: AppText.h2(15, color: Colors.white)),
            ]),
      ),
    );
  }
}

// ── Chip Filter Row ──────────────────────────────────
class ChipFilterRow extends StatelessWidget {
  final List<String> chips;
  final int selected;
  final ValueChanged<int> onSelect;
  const ChipFilterRow({super.key, required this.chips, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips.asMap().entries.map((e) {
        final active = e.key == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? AppColors.ink : AppColors.border),
              ),
              child: Text(e.value, style: AppText.label(12,
                color: active ? Colors.white : AppColors.ink2,
                weight: FontWeight.w600)),
            ),
          ),
        );
      }).toList()),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  final String? sub;
  const StatChip({super.key, required this.value, required this.label,
    required this.color, this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(value, style: AppText.h1(20, color: color)),
        const SizedBox(height: 2),
        if (sub != null) ...[
          Text(sub!, style: AppText.label(9, color: color.withOpacity(0.75))),
          const SizedBox(height: 2),
        ],
        Text(label, style: AppText.label(10, color: AppColors.ink3)),
      ]),
    );
  }
}
