import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Warm, editorial health-app colour tokens ───────────────────────────────────

class AppColors {
  AppColors._();

  // Brand
  static const primary   = Color(0xFF477A56); // Forest Green
  static const secondary = Color(0xFFE8F0E9); // Light Sage

  // Surface
  static const background = Color(0xFFF4F0E8); // Warm Cream
  static const card       = Color(0xFFFFFFFF);
  static const border     = Color(0xFFECE7DF);

  // Text
  static const foreground = Color(0xFF2C261E); // Dark Warm Charcoal
  static const mutedFg    = Color(0xFF868075); // Warm Muted Gray

  // Tier 1 — AI home care (green)
  static const tier1      = Color(0xFFE8F1EA);
  static const tier1Solid = Color(0xFF477A56);
  static const tier1Fg    = Color(0xFF2E593B);

  // Tier 2 — Async doctor (amber)
  static const tier2      = Color(0xFFFBF1D8);
  static const tier2Solid = Color(0xFFC7922B);
  static const tier2Fg    = Color(0xFF855E13);

  // Tier 3 — Live doctor (red)
  static const tier3      = Color(0xFFFCE9E6);
  static const tier3Solid = Color(0xFFD64A38);
  static const tier3Fg    = Color(0xFF8C2618);
}

// ─── Typography helpers ────────────────────────────────────────────────────────

TextStyle display({
  double size = 16,
  FontWeight weight = FontWeight.w600,
  Color? color,
}) {
  return GoogleFonts.newsreader(
    fontSize: size,
    fontWeight: weight,
    color: color ?? AppColors.foreground,
  );
}

TextStyle body({
  double size = 14,
  FontWeight? weight,
  Color? color,
}) {
  return GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? AppColors.foreground,
  );
}

// ─── Tier style bundle ─────────────────────────────────────────────────────────

class TierStyle {
  final Color bg;
  final Color fg;
  final Color solid;
  final IconData icon;
  final String short;
  final String label;

  const TierStyle({
    required this.bg,
    required this.fg,
    required this.solid,
    required this.icon,
    required this.short,
    required this.label,
  });
}

TierStyle tierStyle(int tier) {
  return switch (tier) {
    1 => const TierStyle(
          bg: AppColors.tier1,
          fg: AppColors.tier1Fg,
          solid: AppColors.tier1Solid,
          icon: Icons.check_circle_rounded,
          short: "Tier 1",
          label: "AI home care",
        ),
    2 => const TierStyle(
          bg: AppColors.tier2,
          fg: AppColors.tier2Fg,
          solid: AppColors.tier2Solid,
          icon: Icons.schedule_rounded,
          short: "Tier 2",
          label: "Doctor review",
        ),
    _ => const TierStyle(
          bg: AppColors.tier3,
          fg: AppColors.tier3Fg,
          solid: AppColors.tier3Solid,
          icon: Icons.local_hospital_rounded,
          short: "Tier 3",
          label: "Live consult",
        ),
  };
}
