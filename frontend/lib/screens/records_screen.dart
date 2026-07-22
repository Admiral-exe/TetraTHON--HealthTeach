import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../data/mock.dart';
import '../widgets/primitives.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecordsSection(showHeader: true, excludeCheckIns: false);
  }
}

class RecordsSection extends StatefulWidget {
  final bool showHeader;
  final bool excludeCheckIns;

  const RecordsSection({
    super.key,
    this.showHeader = true,
    this.excludeCheckIns = false,
  });

  @override
  State<RecordsSection> createState() => _RecordsSectionState();
}

class _RecordsSectionState extends State<RecordsSection> {
  String _filter = "all";

  @override
  Widget build(BuildContext context) {
    final availableRecords = widget.excludeCheckIns
        ? records.where((r) => r.type == "tier" || r.type == "doctor").toList()
        : records;

    final filters = widget.excludeCheckIns
        ? const [
            ("all", "All"),
            ("tier", "Tier events"),
            ("doctor", "Doctor notes"),
          ]
        : const [
            ("all", "All"),
            ("checkin", "Check-ins"),
            ("tier", "Tier events"),
            ("doctor", "Doctor notes"),
          ];

    final shown = _filter == "all"
        ? availableRecords
        : availableRecords.where((r) => r.type == _filter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader)
          const ScreenHeader(eyebrow: "HISTORY & RECORDS", title: "Your health story"),

        // Weekly doctor report PDF Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
                  child: Row(
                    children: [
                      Container(
                        height: 28,
                        width: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.insert_drive_file_outlined, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Weekly doctor report",
                              style: display(size: 17, weight: FontWeight.w600),
                            ),
                            Text(
                              "Jul 11 – 17 · trends, adherence & tier events",
                              style: body(size: 11.5, color: AppColors.mutedFg),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              "PDF",
                              style: body(size: 12.5, weight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Line chart
                SizedBox(
                  height: 140,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 18, 4),
                    child: _TrendChart(),
                  ),
                ),

                // Chart Legend
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  child: Row(
                    children: [
                      _legend(AppColors.primary, "Fasting sugar"),
                      const SizedBox(width: 20),
                      _legend(AppColors.tier3Solid, "Systolic BP"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Filter chips (Excludes check-ins when in Home section)
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = filters[i];
              final active = _filter == f.$1;
              return GestureDetector(
                onTap: () => setState(() => _filter = f.$1),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: active ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    f.$2,
                    style: body(
                      size: 13,
                      weight: active ? FontWeight.w600 : FontWeight.w500,
                      color: active ? Colors.white : AppColors.foreground,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Timeline list showing only Doctor notes and Tier events below the graph
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: shown.map((r) => _TimelineRow(r)).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _legend(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: body(size: 12, weight: FontWeight.w500, color: AppColors.foreground)),
        ],
      );
}

class _TrendChart extends StatelessWidget {
  List<FlSpot> _spots(String key) => [
        for (var i = 0; i < weeklyTrend.length; i++)
          FlSpot(i.toDouble(), (weeklyTrend[i][key] as num).toDouble())
      ];

  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      minY: 0,
      maxY: 60,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [3, 3]),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            interval: 20,
            getTitlesWidget: (v, _) => Text(
              v.toInt().toString(),
              style: body(size: 10, color: AppColors.mutedFg),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= weeklyTrend.length) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  weeklyTrend[i]["day"] as String,
                  style: body(size: 10, color: AppColors.mutedFg),
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: _spots("sugar"),
          isCurved: true,
          color: AppColors.primary,
          barWidth: 2.2,
          dotData: const FlDotData(show: false),
        ),
        LineChartBarData(
          spots: _spots("bp"),
          isCurved: true,
          color: AppColors.tier3Solid,
          barWidth: 2.2,
          dotData: const FlDotData(show: false),
        ),
      ],
    ));
  }
}

class _TimelineRow extends StatelessWidget {
  final RecordEntry r;
  const _TimelineRow(this.r);

  IconData get _icon => switch (r.category) {
        "TIER EVENT" => Icons.shield_outlined,
        "CHECK-IN" => Icons.mic_outlined,
        "DOCTOR NOTE" => Icons.medical_services_outlined,
        "SYMPTOM CHAT" => Icons.chat_bubble_outline_rounded,
        _ => Icons.notes_rounded,
      };

  Color get _iconColor => switch (r.category) {
        "TIER EVENT" => AppColors.tier2Fg,
        "CHECK-IN" => AppColors.primary,
        "DOCTOR NOTE" => AppColors.primary,
        "SYMPTOM CHAT" => AppColors.primary,
        _ => AppColors.mutedFg,
      };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail with icon
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Icon(_icon, size: 18, color: _iconColor),
              ),
              Expanded(
                child: Container(width: 1, color: AppColors.border),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.category,
                          style: body(size: 11, weight: FontWeight.w600, color: AppColors.mutedFg)
                              .copyWith(letterSpacing: 1.1),
                        ),
                        Text(
                          r.date,
                          style: body(size: 11.5, color: AppColors.mutedFg),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r.title,
                      style: body(size: 15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.summary,
                      style: body(size: 13, color: AppColors.mutedFg).copyWith(height: 1.35),
                    ),
                    if (r.dotColor != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: r.dotColor == "amber" ? AppColors.tier2Solid : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
