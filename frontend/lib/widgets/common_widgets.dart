// lib/widgets/common_widgets.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';

// ── Status Pill ──────────────────────────────────────
class StatusPill extends StatelessWidget {
  final TxStatus status;
  final int? score;
  final bool large;
  const StatusPill({super.key, required this.status, this.score, this.large = false});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      TxStatus.approved => (AppColors.safeLight,   AppColors.safe,   '✓ ${score ?? ""}%'),
      TxStatus.flagged  => (AppColors.warnLight,    AppColors.warn,   '⚑ ${score ?? ""}%'),
      TxStatus.blocked  => (AppColors.dangerLight,  AppColors.danger, '⛔ ${score ?? ""}%'),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 6 : 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: AppText.mono(large ? 12 : 10, color: fg, weight: FontWeight.w600)),
    );
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
      padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 10),
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

// ── App Card ─────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.padding, this.color, this.radius = 14, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.055), blurRadius: 16, offset: const Offset(0, 2))],
        ),
        child: Padding(padding: padding ?? const EdgeInsets.all(16), child: child),
      ),
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
    return Row(children: [
      SizedBox(
        width: 56,
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
      Text('$score%', style: AppText.mono(11, color: _color, weight: FontWeight.w500)),
      const SizedBox(width: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(_label, style: AppText.mono(8, color: _color, weight: FontWeight.w600)),
      ),
    ]);
  }
}

// ── Behavior Row ─────────────────────────────────────
class BehaviorRow extends StatelessWidget {
  final BehaviorStat stat;
  const BehaviorRow({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final anomalyColor = stat.isAnomaly ? AppColors.danger : AppColors.safe;
    final barColor = stat.isAnomaly ? AppColors.danger : AppColors.safe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: stat.isAnomaly ? AppColors.dangerLight : AppColors.accentLight,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: Text(stat.icon, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(stat.label, style: AppText.body(12, weight: FontWeight.w600)),
                  if (stat.isAnomaly)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('ANOMALY', style: AppText.mono(8, color: AppColors.danger, weight: FontWeight.w700)),
                    ),
                ]),
                const SizedBox(height: 4),
                Stack(children: [
                  // Normal baseline bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: stat.normalValue,
                      backgroundColor: AppColors.border,
                      color: AppColors.accent.withOpacity(0.25),
                      minHeight: 7,
                    ),
                  ),
                  // Current value bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: stat.currentValue,
                      backgroundColor: Colors.transparent,
                      color: barColor.withOpacity(0.8),
                      minHeight: 7,
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Normal: ${stat.normalDisplay}', style: AppText.mono(9, color: AppColors.ink3)),
                  Text('Current: ${stat.currentDisplay}',
                    style: AppText.mono(9, color: anomalyColor, weight: FontWeight.w600)),
                ]),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Info Row ─────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppText.body(13, color: AppColors.ink3)),
        Text(value, style: AppText.body(13, color: valueColor ?? AppColors.ink, weight: FontWeight.w600)),
      ]),
    );
  }
}

// ── Setting Toggle ───────────────────────────────────
class SettingToggleRow extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const SettingToggleRow({
    super.key, required this.icon, required this.iconBg,
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 17)),
        ),
        title: Text(title, style: AppText.body(14, weight: FontWeight.w500)),
        subtitle: Text(subtitle, style: AppText.body(11, color: AppColors.ink3)),
        trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: AppColors.safe),
      ),
    );
  }
}

// ── Setting Nav Row ──────────────────────────────────
class SettingNavRow extends StatelessWidget {
  final String icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Color? arrowColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  const SettingNavRow({
    super.key, required this.icon, required this.iconBg,
    required this.title, required this.subtitle,
    this.arrowColor, this.onTap, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.card, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 2))],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 17)),
          ),
          title: Text(title, style: AppText.body(14, weight: FontWeight.w500)),
          subtitle: subtitle.isNotEmpty ? Text(subtitle, style: AppText.body(11, color: AppColors.ink3)) : null,
          trailing: trailing ?? Icon(Icons.chevron_right, color: arrowColor ?? AppColors.ink3, size: 20),
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
  const GradientButton({
    super.key, required this.label, this.emoji, this.onTap,
    this.loading = false, this.colors = const [AppColors.accent, AppColors.accentMid],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: colors.first.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: loading
          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              if (emoji != null) ...[Text(emoji!, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8)],
              Text(label, style: AppText.display(16, color: Colors.white)),
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
      child: Row(
        children: chips.asMap().entries.map((e) {
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
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: active ? AppColors.ink : AppColors.border),
                ),
                child: Text(e.value,
                  style: AppText.body(12,
                    color: active ? Colors.white : AppColors.ink2,
                    weight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Stat Chip ────────────────────────────────────────
class StatChip extends StatelessWidget {
  final String value, label;
  final Color color;
  final String? trend;
  const StatChip({super.key, required this.value, required this.label, required this.color, this.trend});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 4),
      Text(value, style: AppText.display(20, color: color)),
      if (trend != null) ...[
        const SizedBox(height: 2),
        Text(trend!, style: AppText.mono(9, color: color.withOpacity(0.7))),
      ],
      const SizedBox(height: 3),
      Text(label, style: AppText.body(10, color: AppColors.ink3, weight: FontWeight.w500)),
      const SizedBox(height: 4),
    ]);
  }
}
