import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

// ─── Screen header ─────────────────────────────────────────────────────────────

class ScreenHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  const ScreenHeader({super.key, required this.eyebrow, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: body(size: 12, weight: FontWeight.w600, color: AppColors.mutedFg)
                .copyWith(letterSpacing: 1.3),
          ),
          const SizedBox(height: 4),
          Text(title, style: display(size: 26, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── App card ──────────────────────────────────────────────────────────────────

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─── Primary button ────────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool secondary;
  final VoidCallback? onTap;

  const PrimaryButton(
    this.label, {
    super.key,
    this.icon,
    this.secondary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: secondary ? AppColors.secondary : AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          border: secondary ? Border.all(color: AppColors.border) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: secondary ? AppColors.foreground : Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: body(
                size: 15,
                weight: FontWeight.w600,
                color: secondary ? AppColors.foreground : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Health ring (circular score indicator) ─────────────────────────────────────

class HealthRing extends StatelessWidget {
  final int score;
  final Color? color;
  const HealthRing(this.score, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final fraction = score / 100.0;
    final effectiveColor = color ??
        (score >= 80
            ? AppColors.tier1Solid
            : score >= 60
                ? AppColors.tier2Solid
                : AppColors.tier3Solid);

    return SizedBox(
      height: 68,
      width: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 68,
            width: 68,
            child: CustomPaint(painter: _RingPainter(fraction, effectiveColor)),
          ),
          Text(
            score.toString(),
            style: display(size: 22, weight: FontWeight.w700, color: effectiveColor),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;
  _RingPainter(this.fraction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AppColors.border,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.fraction != fraction || old.color != color;
}

// ─── Tier badge ────────────────────────────────────────────────────────────────

class TierBadge extends StatelessWidget {
  final int tier;
  const TierBadge(this.tier, {super.key});

  @override
  Widget build(BuildContext context) {
    final t = tierStyle(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: t.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(t.icon, size: 12, color: t.fg),
          const SizedBox(width: 4),
          Text(
            t.short,
            style: body(size: 11.5, weight: FontWeight.w600, color: t.fg),
          ),
        ],
      ),
    );
  }
}

// ─── Confidence bar ────────────────────────────────────────────────────────────

class ConfidenceBar extends StatelessWidget {
  final int value;
  final Color color;
  const ConfidenceBar(this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value / 100.0,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

// ─── Sparkline (mini trend chart) ──────────────────────────────────────────────

class Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const Sparkline(this.data, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      width: 60,
      child: CustomPaint(painter: _SparklinePainter(data, color)),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minV = data.reduce(math.min);
    final maxV = data.reduce(math.max);
    final range = maxV - minV == 0 ? 1.0 : maxV - minV;

    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.data != data || old.color != color;
}
