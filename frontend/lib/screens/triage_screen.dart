import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/mock.dart';
import '../widgets/primitives.dart';
import '../services/api_service.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});
  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  TriageResult? _result;
  bool _thinking = false;

  Future<void> _runWithText(String symptomsText) async {
    setState(() => _thinking = true);
    final res = await ApiService.analyzeSymptoms(symptomsText: symptomsText);
    if (mounted) {
      setState(() {
        _result = res;
        _thinking = false;
      });
    }
  }

  void _openCustomSymptomModal() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text("Describe your symptoms", style: display(size: 18, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                "Type your symptoms in detail. FastAPI & Arogya AI will process them.",
                style: body(size: 13, color: AppColors.mutedFg),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                style: body(size: 14.5),
                decoration: InputDecoration(
                  hintText: "E.g., Sharp stomach pain on the right side for 2 hours with nausea...",
                  hintStyle: body(size: 13.5, color: AppColors.mutedFg.withValues(alpha: 0.7)),
                  filled: true,
                  fillColor: const Color(0xFFF9F7F3),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final text = controller.text;
                    Navigator.pop(context);
                    if (text.trim().isNotEmpty) {
                      _runWithText(text);
                    }
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.white),
                  label: Text(
                    "Analyze Symptoms with AI",
                    style: body(size: 14.5, weight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _ResultView(result: _result!, onBack: () => setState(() => _result = null));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(eyebrow: "SYMPTOM CHECK", title: "What's going on?"),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Mic card
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _openCustomSymptomModal,
                      child: Container(
                        height: 72,
                        width: 72,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _thinking ? Icons.auto_awesome_rounded : Icons.mic_rounded,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _thinking ? "Assessing symptoms with FastAPI Backend..." : "Tap mic or type your symptoms below",
                      style: body(size: 14, weight: FontWeight.w500, color: AppColors.mutedFg),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openCustomSymptomModal,
                      icon: const Icon(Icons.keyboard_outlined, size: 18, color: AppColors.primary),
                      label: Text("Type symptoms manually", style: body(size: 13.5, weight: FontWeight.w600, color: AppColors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _label("OR PICK A COMMON ONE"),
              ...symptomPresets.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      onTap: () => _runWithText(p.label),
                      child: Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF4F0E8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.mutedFg),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.label,
                              style: body(size: 14.5, weight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: tierStyle(p.result.tier).solid,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),

              const SizedBox(height: 14),

              _label("HOW CARE ESCALATES"),
              for (final lvl in [1, 2, 3])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CareLevelCard(lvl),
                ),
              const SizedBox(height: 12),
              Text(
                "We give a ranked set of possibilities with a confidence level — never a single certain diagnosis. Serious symptom combinations always route to a real doctor.",
                textAlign: TextAlign.center,
                style: body(size: 12.5, color: AppColors.mutedFg).copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String t) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            t,
            style: body(size: 11.5, weight: FontWeight.w600, color: AppColors.mutedFg)
                .copyWith(letterSpacing: 1.1),
          ),
        ),
      );
}

class _CareLevelCard extends StatelessWidget {
  final int tier;
  const _CareLevelCard(this.tier);

  static const _copy = {
    1: (
      "Level 1 — AI home care",
      "Our own model gives a ranked, confidence-scored assessment and home-care guidance. No human needed.",
      Icons.eco_outlined,
    ),
    2: (
      "Level 2 — Auto case + doctor",
      "The engine pulls your health-app & conversation data on its own, builds a case file, and a matched doctor reviews it. No files to upload.",
      Icons.access_time_outlined,
    ),
    3: (
      "Level 3 — Live / in-clinic doctor",
      "Red-flag or serious cases route straight to a live consult or a booked clinic visit with a ready case file.",
      Icons.phone_outlined,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final t = tierStyle(tier);
    final c = _copy[tier]!;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: t.bg,
            child: Icon(c.$3, size: 18, color: t.solid),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.$1, style: body(size: 14.5, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  c.$2,
                  style: body(size: 12.5, color: AppColors.mutedFg).copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final TriageResult result;
  final VoidCallback onBack;
  const _ResultView({required this.result, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final t = tierStyle(result.tier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 20, 4),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left_rounded)),
              Text(
                "Assessment result",
                style: body(size: 14.5, weight: FontWeight.w500, color: AppColors.mutedFg),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 14, color: t.fg),
                          const SizedBox(width: 6),
                          Text(
                            "${t.short} · ${t.label}",
                            style: body(size: 12.5, weight: FontWeight.w600, color: t.fg),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(result.headline, style: display(size: 21, weight: FontWeight.w600, color: t.fg)),
                    const SizedBox(height: 6),
                    Text(result.rationale, style: body(size: 14, color: t.fg).copyWith(height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (result.redFlag != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.tier3,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.tier3Solid.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.gpp_maybe_rounded, size: 20, color: AppColors.tier3Fg),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          result.redFlag!,
                          style: body(size: 13.5, color: AppColors.tier3Fg).copyWith(height: 1.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("What this might be", style: display(size: 17, weight: FontWeight.w600)),
                        Text("AI confidence ${result.confidence}%", style: body(size: 12.5, color: AppColors.mutedFg)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...result.differential.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(d.cause, style: body(size: 14.5, weight: FontWeight.w500)),
                                  Text(d.note, style: body(size: 12.5, color: AppColors.mutedFg)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(child: ConfidenceBar(d.confidence, t.solid)),
                                  const SizedBox(width: 8),
                                  Text("${d.confidence}%", style: body(size: 12.5, weight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("What to do now", style: display(size: 17, weight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    ...result.advice.map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 7),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(color: t.solid, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(a, style: body(size: 14).copyWith(height: 1.45))),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (result.tier == 1)
                PrimaryButton("Log & finish", icon: Icons.assignment_turned_in_rounded, secondary: true, onTap: onBack)
              else
                _EscalationFlow(tier: result.tier, onBack: onBack),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

class _EscalationFlow extends StatefulWidget {
  final int tier;
  final VoidCallback onBack;
  const _EscalationFlow({required this.tier, required this.onBack});
  @override
  State<_EscalationFlow> createState() => _EscalationFlowState();
}

class _EscalationFlowState extends State<_EscalationFlow> {
  String? _booked;

  @override
  Widget build(BuildContext context) {
    final t = tierStyle(widget.tier);
    final doc = matchedDoctors[widget.tier]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.medical_services_rounded, size: 16, color: t.solid),
                  const SizedBox(width: 6),
                  Text(
                    widget.tier == 2 ? "MATCHED FOR ASYNC REVIEW" : "ROUTED TO YOU NOW",
                    style: body(size: 12, weight: FontWeight.w600, color: AppColors.mutedFg).copyWith(letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: t.bg,
                    child: Text(doc.name.split(" ").last[0], style: display(size: 18, weight: FontWeight.w600, color: t.fg)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name, style: body(size: 15.5, weight: FontWeight.w600)),
                        Text(doc.specialty, style: body(size: 13, color: AppColors.mutedFg)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(999)),
                    child: Text(doc.availableIn, style: body(size: 11.5, weight: FontWeight.w600, color: t.fg)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_booked == null) ...[
          if (widget.tier == 3)
            PrimaryButton("Connect to live video consult", icon: Icons.videocam_rounded, onTap: () => setState(() => _booked = "video")),
          if (widget.tier == 2)
            PrimaryButton("Send case for async review", icon: Icons.send_rounded, onTap: () => setState(() => _booked = "async")),
        ] else
          AppCard(
            child: Column(
              children: [
                Icon(
                  _booked == "video" ? Icons.videocam_rounded : Icons.mark_email_read_rounded,
                  size: 36,
                  color: t.solid,
                ),
                const SizedBox(height: 10),
                Text(
                  _booked == "video" ? "Connecting you to ${doc.name}…" : "Case sent to ${doc.name} for review",
                  textAlign: TextAlign.center,
                  style: body(size: 15, weight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                PrimaryButton("Done", icon: Icons.check_rounded, secondary: true, onTap: widget.onBack),
              ],
            ),
          ),
      ],
    );
  }
}
