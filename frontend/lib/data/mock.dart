// ─── Data models ───────────────────────────────────────────────────────────────

class Vital {
  final String value, label, unit;
  const Vital({required this.value, required this.label, required this.unit});
}

class FamilyMember {
  final String name, relation, initials, age, gender;
  final String? chronic;
  final String trend;          // "normal" | "watch" | "concerning"
  final String lastCheckIn;
  final int healthScore, tier;
  final List<double> scoreSpark;
  final List<Vital> vitals;

  const FamilyMember({
    required this.name,
    required this.relation,
    required this.initials,
    required this.age,
    required this.gender,
    this.chronic,
    required this.trend,
    required this.lastCheckIn,
    required this.healthScore,
    required this.tier,
    required this.scoreSpark,
    required this.vitals,
  });
}

class Reminder {
  final String kind, title, detail, time;
  final bool done;
  const Reminder({
    required this.kind,
    required this.title,
    required this.detail,
    required this.time,
    this.done = false,
  });
}

class ScoreFactor {
  final String label;
  final String subtitle;
  final int effect;
  const ScoreFactor({required this.label, required this.subtitle, required this.effect});
}

class RecordEntry {
  final String category; // "TIER EVENT", "CHECK-IN", "DOCTOR NOTE", "SYMPTOM CHAT"
  final String type;     // "all", "checkin", "tier", "doctor"
  final String title;
  final String summary;
  final String date;
  final int? tier;
  final String? dotColor; // "amber", "green", "red"

  const RecordEntry({
    required this.category,
    required this.type,
    required this.title,
    required this.summary,
    required this.date,
    this.tier,
    this.dotColor,
  });
}

class ProbableCondition {
  final String conditionName;
  final String severityRemark; // "HIGH", "MEDIUM", "LOW"
  final String description;

  const ProbableCondition({
    required this.conditionName,
    required this.severityRemark,
    required this.description,
  });
}

class TriageResult {
  final int tier;
  final int confidence;
  final String headline;
  final String rationale;
  final String? redFlag;
  final List<Differential> differential;
  final List<String> advice;

  // 5 Compulsory Medical Sections:
  final List<ProbableCondition> probableConditions;
  final String triageReasoning;
  final String clinicalExplanation;
  final List<String> recommendedNextSteps;
  final List<String> criticalRedFlags;

  const TriageResult({
    required this.tier,
    required this.confidence,
    required this.headline,
    required this.rationale,
    this.redFlag,
    required this.differential,
    required this.advice,
    this.probableConditions = const [],
    this.triageReasoning = "",
    this.clinicalExplanation = "",
    this.recommendedNextSteps = const [],
    this.criticalRedFlags = const [],
  });
}


class Differential {
  final String cause, note;
  final int confidence;
  const Differential({
    required this.cause,
    required this.note,
    required this.confidence,
  });
}

class SymptomPreset {
  final String label;
  final TriageResult result;
  const SymptomPreset({required this.label, required this.result});
}

class Doctor {
  final String name, specialty, availableIn;
  const Doctor({
    required this.name,
    required this.specialty,
    required this.availableIn,
  });
}

class ConnectedSource {
  final String name, icon;
  final int points;
  final bool synced;
  const ConnectedSource({
    required this.name,
    required this.icon,
    required this.points,
    this.synced = true,
  });
}

// ─── Mock data ─────────────────────────────────────────────────────────────────

final List<FamilyMember> family = [
  const FamilyMember(
    name: "Aarav Sharma", relation: "You", initials: "AS",
    age: "44 yrs", gender: "Male",
    chronic: "Type 2 Diabetes",
    trend: "watch", lastCheckIn: "Today, 8:05 AM",
    healthScore: 74, tier: 2,
    scoreSpark: [70, 71, 72, 70, 73, 75, 74],
    vitals: [
      Vital(value: "138", label: "Fasting sugar", unit: "mg/dL"),
      Vital(value: "78", label: "Resting HR", unit: "bpm"),
      Vital(value: "6.1", label: "Sleep", unit: "hrs"),
      Vital(value: "4,210", label: "Steps", unit: "today"),
    ],
  ),
  const FamilyMember(
    name: "Meera Sharma", relation: "Wife", initials: "MS",
    age: "41 yrs", gender: "Female",
    chronic: null,
    trend: "normal", lastCheckIn: "Today, 7:30 AM",
    healthScore: 88, tier: 1,
    scoreSpark: [85, 86, 87, 87, 88, 88, 88],
    vitals: [
      Vital(value: "96", label: "Fasting sugar", unit: "mg/dL"),
      Vital(value: "68", label: "Resting HR", unit: "bpm"),
      Vital(value: "7.2", label: "Sleep", unit: "hrs"),
      Vital(value: "6,840", label: "Steps", unit: "today"),
    ],
  ),
  const FamilyMember(
    name: "Ramesh Sharma", relation: "Father", initials: "RS",
    age: "68 yrs", gender: "Male",
    chronic: "Hypertension",
    trend: "concerning", lastCheckIn: "Yesterday, 8:02 PM",
    healthScore: 61, tier: 3,
    scoreSpark: [67, 65, 64, 63, 62, 61, 61],
    vitals: [
      Vital(value: "156", label: "Systolic BP", unit: "mmHg"),
      Vital(value: "82", label: "Resting HR", unit: "bpm"),
      Vital(value: "5.4", label: "Sleep", unit: "hrs"),
      Vital(value: "1,820", label: "Steps", unit: "today"),
    ],
  ),
  const FamilyMember(
    name: "Diya Sharma", relation: "Daughter", initials: "DS",
    age: "16 yrs", gender: "Female",
    chronic: null,
    trend: "normal", lastCheckIn: "Today, 7:45 AM",
    healthScore: 94, tier: 1,
    scoreSpark: [92, 93, 93, 94, 94, 94, 94],
    vitals: [
      Vital(value: "88", label: "Fasting sugar", unit: "mg/dL"),
      Vital(value: "62", label: "Resting HR", unit: "bpm"),
      Vital(value: "8.0", label: "Sleep", unit: "hrs"),
      Vital(value: "7,320", label: "Steps", unit: "today"),
    ],
  ),
];

final List<Map<String, dynamic>> checkInScript = [
  {
    "q": "How are you feeling today?",
    "chips": ["Good", "A bit tired", "Not great"],
  },
  {
    "q": "Did you take your morning medication?",
    "chips": ["Yes, all of them", "Skipped one", "Forgot"],
  },
  {
    "q": "How did you sleep last night?",
    "chips": ["Slept well", "Woke up once", "Barely slept"],
  },
  {
    "q": "Any new symptoms since yesterday?",
    "chips": ["None", "Headache", "Something else"],
  },
];

final List<Reminder> reminders = [
  const Reminder(
    kind: "sun", title: "Morning sunlight",
    detail: "10 minutes of sun for Vitamin D",
    time: "7:00 \u2013 8:00 AM", done: true,
  ),
  const Reminder(
    kind: "med", title: "Metformin 500mg",
    detail: "After breakfast",
    time: "9:00 AM", done: true,
  ),
  const Reminder(
    kind: "ayurveda", title: "Ashwagandha",
    detail: "Ayurveda \u00b7 1 tsp with warm milk",
    time: "9:30 PM", done: false,
  ),
  const Reminder(
    kind: "test", title: "HbA1c test due",
    detail: "Recommended every 3 months for your profile",
    time: "This week", done: false,
  ),
];

final List<ScoreFactor> scoreFactors = [
  const ScoreFactor(label: "Daily check-in streak",       subtitle: "12 days in a row",      effect:  6),
  const ScoreFactor(label: "Sleep consistency",            subtitle: "Averaging 6.1 hrs",     effect:  4),
  const ScoreFactor(label: "Fasting sugar trending up",    subtitle: "138 vs 122 last week",  effect: -8),
  const ScoreFactor(label: "Step goal",                    subtitle: "4,210 of 8,000",        effect: -3),
];

final List<RecordEntry> records = [
  const RecordEntry(
    category: "TIER EVENT",
    type: "tier",
    title: "Async review opened",
    summary: "Persistent headache assessed against BP trend. Case file sent to Dr. Nair.",
    date: "Jul 17",
    dotColor: "amber",
  ),
  const RecordEntry(
    category: "CHECK-IN",
    type: "checkin",
    title: "Morning voice check-in",
    summary: "Felt slightly tired. Sleep 6.1 hrs, fasting sugar 138 mg/dL.",
    date: "Jul 17",
  ),
  const RecordEntry(
    category: "DOCTOR NOTE",
    type: "doctor",
    title: "Dr. Nair \u2014 note",
    summary: "Continue Metformin. Reduce evening carbs; recheck fasting sugar in 1 week.",
    date: "Jul 15",
  ),
  const RecordEntry(
    category: "SYMPTOM CHAT",
    type: "checkin",
    title: "Symptom chat \u2014 mild cough",
    summary: "Assessed as common cold. Home care advised. No escalation.",
    date: "Jul 14",
    dotColor: "green",
  ),
  const RecordEntry(
    category: "CHECK-IN",
    type: "checkin",
    title: "Morning voice check-in",
    summary: "Feeling good. Sleep 7.0 hrs, 6,400 steps.",
    date: "Jul 11",
  ),
];

final List<Map<String, dynamic>> weeklyTrend = [
  {"day": "Mon", "sugar": 20, "bp": 35},
  {"day": "Tue", "sugar": 24, "bp": 38},
  {"day": "Wed", "sugar": 22, "bp": 42},
  {"day": "Thu", "sugar": 21, "bp": 45},
  {"day": "Fri", "sugar": 25, "bp": 50},
  {"day": "Sat", "sugar": 26, "bp": 52},
  {"day": "Sun", "sugar": 27, "bp": 55},
];

final List<SymptomPreset> symptomPresets = [
  SymptomPreset(
    label: "Runny nose & mild cough",
    result: TriageResult(
      tier: 1,
      confidence: 82,
      headline: "Likely common cold",
      rationale:
          "Based on your description and recent check-in data, this matches a typical upper respiratory pattern. No red-flag symptoms detected.",
      differential: [
        const Differential(cause: "Common cold",       note: "seasonal pattern",        confidence: 72),
        const Differential(cause: "Allergic rhinitis",  note: "no prior allergy history", confidence: 18),
        const Differential(cause: "Mild flu",           note: "no fever reported",        confidence: 10),
      ],
      advice: [
        "Rest and stay hydrated \u2014 aim for 8 glasses of water today.",
        "Steam inhalation can help with congestion.",
        "If fever develops or symptoms worsen in 3 days, start another check.",
      ],
    ),
  ),
  SymptomPreset(
    label: "Headache for 3 days",
    result: TriageResult(
      tier: 2,
      confidence: 74,
      headline: "Persistent headache \u2014 doctor review queued",
      rationale:
          "A headache lasting 3+ days combined with your recent BP trend (rising over the past week) warrants a doctor\u2019s review.",
      redFlag:
          "If you experience sudden severe headache, vision changes, or neck stiffness, call emergency services immediately.",
      differential: [
        const Differential(cause: "Tension headache",        note: "sleep deficit + stress", confidence: 55),
        const Differential(cause: "Hypertension-related",    note: "BP trending up 5 days",  confidence: 30),
        const Differential(cause: "Medication side effect",  note: "check Metformin timing",  confidence: 15),
      ],
      advice: [
        "Rest in a quiet, dimly lit room.",
        "Your case file has been sent to Dr. Nair for async review.",
        "Expected response within 2\u20134 hours.",
      ],
    ),
  ),
  SymptomPreset(
    label: "Chest pain & breathlessness",
    result: TriageResult(
      tier: 3,
      confidence: 68,
      headline: "Red flag \u2014 routing to live doctor now",
      rationale:
          "Chest pain combined with breathlessness triggers our safety protocol. This requires immediate human assessment \u2014 the AI steps back here.",
      redFlag:
          "This is a safety-critical symptom combination. A real doctor must evaluate you. If symptoms worsen, call 108 (ambulance) or go to the nearest ER.",
      differential: [
        const Differential(cause: "Cardiac event (rule out)", note: "must be excluded first", confidence: 35),
        const Differential(cause: "Anxiety / panic attack",   note: "possible but not assumed", confidence: 30),
        const Differential(cause: "GERD / acid reflux",       note: "history of acidity noted", confidence: 25),
      ],
      advice: [
        "Do NOT exert yourself. Sit upright and stay calm.",
        "A live video consult is being connected right now.",
        "Your complete health timeline has been shared with the doctor.",
        "Nearest facility: Civil Hospital, Anand \u2014 3.2 km.",
      ],
    ),
  ),
];

final Map<int, Doctor> matchedDoctors = {
  2: const Doctor(name: "Dr. Nair", specialty: "Internal Medicine", availableIn: "2\u20134 hr async"),
  3: const Doctor(name: "Dr. Vikram Mehta", specialty: "Cardiology", availableIn: "Connecting now\u2026"),
};

final List<ConnectedSource> connectedSources = [
  const ConnectedSource(name: "Daily check-ins",    icon: "mic",     points: 48),
  const ConnectedSource(name: "Wearable sync",      icon: "watch",   points: 336),
  const ConnectedSource(name: "BP / glucose logs",   icon: "monitor", points: 28),
  const ConnectedSource(name: "Medication tracker",  icon: "pill",    points: 84),
];
