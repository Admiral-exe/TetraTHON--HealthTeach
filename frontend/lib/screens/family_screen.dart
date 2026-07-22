import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/mock.dart';
import '../widgets/primitives.dart';

class FamilyScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  const FamilyScreen({super.key, this.userProfile});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  int _selectedIdx = 0;

  @override
  Widget build(BuildContext context) {
    final realName = widget.userProfile?['full_name'] ??
        (widget.userProfile?['first_name'] != null
            ? "${widget.userProfile!['first_name']} ${widget.userProfile!['last_name'] ?? ''}".trim()
            : "Aarav Sharma");
    final realAge = widget.userProfile?['age'] != null ? "${widget.userProfile!['age']} yrs" : "44 yrs";
    final realGender = widget.userProfile?['gender'] ?? "Male";
    final realChronicList = (widget.userProfile?['chronic_diseases'] as List<dynamic>?)?.map((e) => e.toString()).toList();
    final realChronic = realChronicList != null && realChronicList.isNotEmpty ? realChronicList.join(", ") : null;


    final parts = realName.split(" ");
    final initials = parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty
        ? "${parts[0][0]}${parts[1][0]}".toUpperCase()
        : (parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0].toUpperCase() : "AS");

    final primaryMember = FamilyMember(
      name: realName,
      relation: "Self (Primary Member)",
      initials: initials,

      age: realAge,
      gender: realGender,
      chronic: realChronic,
      trend: "normal",
      lastCheckIn: "Today, 9:30 AM",
      healthScore: 88,
      tier: 1,
      scoreSpark: const [80, 82, 85, 86, 88],
      vitals: const [
        Vital(value: "98%", label: "SpO2", unit: "Normal"),
        Vital(value: "72", label: "Heart Rate", unit: "bpm"),
        Vital(value: "120/80", label: "Blood Pressure", unit: "mmHg"),
      ],
    );

    final familyMembersList = [primaryMember, ...family.sublist(1)];
    final selected = familyMembersList[_selectedIdx.clamp(0, familyMembersList.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(eyebrow: "FAMILY HEALTH", title: "Everyone, in one place"),
        const SizedBox(height: 4),

        // Member selector pill chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: familyMembersList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final m = familyMembersList[i];
              final isSelected = i == _selectedIdx;
              return GestureDetector(
                onTap: () => setState(() => _selectedIdx = i),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.secondary : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          m.initials,
                          style: body(size: 11.5, weight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        m.name.split(" ").first,

                        style: body(
                          size: 13.5,
                          weight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Selected Member Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        selected.initials,
                        style: display(size: 20, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selected.name, style: display(size: 20, weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(
                            "${selected.relation} · ${selected.age}${selected.chronic != null ? ' · ${selected.chronic}' : ''}",
                            style: body(size: 13, color: AppColors.mutedFg),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Badges row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.tier2,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_outlined, size: 14, color: AppColors.tier2Fg),
                          const SizedBox(width: 4),
                          Text(
                            "Doctor reviewing",
                            style: body(size: 12, weight: FontWeight.w600, color: AppColors.tier2Fg),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.tier2Fg),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(Icons.north_east_rounded, size: 14, color: AppColors.tier2Fg),
                        const SizedBox(width: 3),
                        Text(
                          "Watch trend",
                          style: body(size: 12.5, weight: FontWeight.w600, color: AppColors.tier2Fg),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Health Score Sparkline Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F4EE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.healthScore.toString(),
                            style: display(size: 28, weight: FontWeight.w700),
                          ),
                          Text(
                            "Health score",
                            style: body(size: 11.5, color: AppColors.mutedFg),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Sparkline(selected.scoreSpark, AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Last check-in: ${selected.lastCheckIn}",
                  style: body(size: 12.5, color: AppColors.mutedFg),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Dots Carousel Controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20, color: AppColors.mutedFg),
                onPressed: _selectedIdx > 0
                    ? () => setState(() => _selectedIdx--)
                    : null,
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(family.length, (i) {
                  final active = i == _selectedIdx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.mutedFg),
                onPressed: _selectedIdx < family.length - 1
                    ? () => setState(() => _selectedIdx++)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 2x2 Vitals Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: selected.vitals.map((v) => _VitalCard(v)).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Bottom Info Cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.mutedFg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "This is your own profile — you control what each family member can see.",
                        style: body(size: 12.5, color: AppColors.mutedFg).copyWith(height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_outlined, size: 16, color: AppColors.mutedFg),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tap a tier badge to see why it's set that way.",
                        style: body(size: 12.5, color: AppColors.mutedFg),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _VitalCard extends StatelessWidget {
  final Vital vital;
  const _VitalCard(this.vital);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(vital.label, style: body(size: 12, color: AppColors.mutedFg)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(vital.value, style: display(size: 22, weight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text(vital.unit, style: body(size: 11, color: AppColors.mutedFg)),
            ],
          ),
        ],
      ),
    );
  }
}
