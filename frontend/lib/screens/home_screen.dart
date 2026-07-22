import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/mock.dart';
import '../widgets/primitives.dart';
import '../services/translation_service.dart';
import 'records_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tab) onNavigate;
  final Map<String, dynamic>? userProfile;

  const HomeScreen({
    super.key,
    required this.onNavigate,
    this.userProfile,
  });

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text("Notifications", style: display(size: 18, weight: FontWeight.w600)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.mutedFg),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 12),
              _buildNotificationItem(
                icon: Icons.medication_rounded,
                iconColor: const Color(0xFF16A34A),
                title: "Medication Due: Metformin 500mg",
                subtitle: "After breakfast • Today at 9:00 AM",
                time: "10m ago",
              ),
              _buildNotificationItem(
                icon: Icons.science_rounded,
                iconColor: const Color(0xFFD97706),
                title: "Lab Test Alert: HbA1c test due",
                subtitle: "Recommended every 3 months for your profile",
                time: "1h ago",
              ),
              _buildNotificationItem(
                icon: Icons.calendar_today_rounded,
                iconColor: AppColors.primary,
                title: "Appointment Scheduled: Dr. Rajesh Sharma",
                subtitle: "Cardiology Consult • Today at 4:30 PM",
                time: "3h ago",
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body(size: 13, weight: FontWeight.w700, color: AppColors.foreground)),
                const SizedBox(height: 2),
                Text(subtitle, style: body(size: 11.5, color: AppColors.mutedFg)),
              ],
            ),
          ),
          Text(time, style: body(size: 10.5, color: AppColors.mutedFg, weight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ValueListenableBuilder<String>(
          valueListenable: TranslationService.currentLanguage,
          builder: (context, activeLang, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.translate_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(TranslationService.tr('select_language'), style: display(size: 17, weight: FontWeight.w600)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.mutedFg),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: TranslationService.languages.length,
                      itemBuilder: (context, index) {
                        final opt = TranslationService.languages[index];
                        final isSelected = opt.code == activeLang;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            onTap: () {
                              TranslationService.setLanguage(opt.code);
                              Navigator.pop(context);
                            },
                            leading: Text(opt.flag, style: const TextStyle(fontSize: 20)),
                            title: Text(
                              opt.name,
                              style: body(
                                size: 14,
                                weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : AppColors.foreground,
                              ),
                            ),
                            subtitle: Text(
                              opt.nativeName,
                              style: body(size: 11.5, color: AppColors.mutedFg),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showScoreFactorsBottomSheet(BuildContext context) {

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                "What's affecting your score",
                style: display(size: 20, weight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                "Built from your check-in trends, symptom answers, and reminder adherence.",
                style: body(size: 13.5, color: AppColors.mutedFg),
              ),
              const SizedBox(height: 20),
              ...scoreFactors.map((f) {
                final isPositive = f.effect > 0;
                final iconBg = isPositive ? AppColors.tier1 : AppColors.tier3;
                final iconFg = isPositive ? AppColors.tier1Solid : AppColors.tier3Solid;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: iconBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
                          size: 18,
                          color: iconFg,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.label, style: body(size: 14.5, weight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(f.subtitle, style: body(size: 12.5, color: AppColors.mutedFg)),
                          ],
                        ),
                      ),
                      Text(
                        "${isPositive ? '+' : ''}${f.effect}",
                        style: body(
                          size: 15,
                          weight: FontWeight.w600,
                          color: iconFg,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = family.first;
    final firstName = userProfile?['first_name'] ?? (userProfile?['full_name'] != null ? userProfile!['full_name'].toString().split(' ').first : "Aarav");
    final bloodGroup = userProfile?['blood_group'] ?? "O+";
    final age = userProfile?['age'] != null ? userProfile!['age'].toString() : "25";
    final chronicList = (userProfile?['chronic_diseases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];


    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.currentLanguage,
      builder: (context, currentLang, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          TranslationService.tr('todays_overview'),
                          style: body(size: 11.5, weight: FontWeight.w600, color: AppColors.mutedFg)
                              .copyWith(letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text("${TranslationService.tr('good_morning')}, $firstName", style: display(size: 24, weight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  // 1) NOTIFICATION BELL BUTTON WITH RED UNREAD BADGE COUNTER
                  IconButton(
                    onPressed: () => _showNotificationSheet(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 20),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDC2626),
                              shape: BoxShape.circle,
                            ),
                            child: const Text("3", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, height: 1.0)),
                          ),
                        ),
                      ],
                    ),
                    tooltip: "Notifications",
                  ),
                  const SizedBox(width: 8),

                  // 2) LANGUAGE SELECTOR BUTTON ("अ" ICON BADGE)
                  GestureDetector(
                    onTap: () => _showLanguageSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "अ",
                            style: body(size: 15, weight: FontWeight.w800, color: AppColors.primary),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),


        // Patient ID & Quick Vitals Banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("HEALTH PROFILE VERIFIED", style: body(size: 11, weight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 2),
                      Text(
                        "Age: $age yrs  •  Blood: $bloodGroup",
                        style: body(size: 13, color: AppColors.foreground, weight: FontWeight.w600),
                      ),

                    ],
                  ),
                ),
                if (chronicList.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      "${chronicList.length} Chronic",
                      style: body(size: 11, weight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),


        // Check-in CTA
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            onTap: () => onNavigate(2),

            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Start today's check-in", style: body(size: 15, weight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        "Just talk — 30 seconds, no typing",
                        style: body(size: 13, color: AppColors.mutedFg),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.mutedFg, size: 20),
              ],
            ),
          ),
        ),

        // Health Score Card
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: AppCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HealthScoreRing(score: me.healthScore),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("Health score", style: display(size: 18, weight: FontWeight.w600)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.tier2,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  "Watch",
                                  style: body(size: 11.5, weight: FontWeight.w600, color: AppColors.tier2Fg),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Slightly down this week — your fasting sugar is trending up.",
                            style: body(size: 13, color: AppColors.mutedFg).copyWith(height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _showScoreFactorsBottomSheet(context),
                            child: Row(
                              children: [
                                Text(
                                  "What's affecting it",
                                  style: body(size: 13, weight: FontWeight.w600, color: AppColors.primary),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Today's Care Section
        const _SectionLabel("Today's care", trailing: "2/4 done"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < reminders.length; i++) ...[
                  _ReminderRow(reminders[i]),
                  if (i != reminders.length - 1) const Divider(height: 1, color: AppColors.border),
                ]
              ],
            ),
          ),
        ),

        // History & Records Section (Placed right after Today's Care)
        _SectionLabel(
          "History & records",
          trailing: "View all",
          onTrailingTap: () => onNavigate(4),
        ),
        const RecordsSection(showHeader: false, excludeCheckIns: true),

        const SizedBox(height: 20),
      ],
    );
  },
);
  }
}


// ─── Health Score Ring with "of 100" label matching screenshot ───────────────────

class _HealthScoreRing extends StatelessWidget {
  final int score;
  const _HealthScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      width: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 84,
            width: 84,
            child: CircularProgressIndicator(
              value: score / 100.0,
              strokeWidth: 7,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                score.toString(),
                style: display(size: 24, weight: FontWeight.w700),
              ),
              Text(
                "of 100",
                style: body(size: 10, color: AppColors.mutedFg),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  final Reminder r;
  const _ReminderRow(this.r);

  IconData get _icon => switch (r.kind) {
        "sun" => Icons.wb_sunny_outlined,
        "med" => Icons.medication_outlined,
        "ayurveda" => Icons.eco_outlined,
        _ => Icons.medical_services_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: const BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: body(
                    size: 14,
                    weight: FontWeight.w600,
                    color: r.done ? AppColors.mutedFg : AppColors.foreground,
                  ).copyWith(
                    decoration: r.done ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "${r.detail} · ${r.time}",
                  style: body(size: 12, color: AppColors.mutedFg),
                ),
              ],
            ),
          ),
          Icon(
            r.done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 22,
            color: r.done ? AppColors.primary : AppColors.border,
          ),
        ],
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  final String text;
  final String? trailing;
  final VoidCallback? onTrailingTap;
  const _SectionLabel(this.text, {this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: display(size: 18, weight: FontWeight.w600)),
            if (trailing != null)
              GestureDetector(
                onTap: onTrailingTap,
                child: Row(
                  children: [
                    Text(
                      trailing!,
                      style: body(size: 12.5, weight: FontWeight.w600, color: AppColors.mutedFg),
                    ),
                    if (trailing!.contains("View")) ...[
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.mutedFg),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
}

