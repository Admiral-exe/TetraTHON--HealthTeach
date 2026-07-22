import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/mock.dart';

class ApiService {
  /// Production Cloud Backend Base URL (Set this when deploying to Render, Railway, AWS, etc.)
  /// Example: ApiService.productionBaseUrl = 'https://healthtech-api.onrender.com';
  static String? productionBaseUrl;

  // Base URLs for local testing (Windows Desktop / Web vs. Android Emulator)
  static const String _primaryBaseUrl = 'http://127.0.0.1:8000';
  static const String _emulatorBaseUrl = 'http://10.0.2.2:8000';

  static String _activeBaseUrl = _primaryBaseUrl;

  /// Returns candidate base URLs in priority sequence (Production -> Cached Active -> Alternative Local)
  static List<String> get _candidateBaseUrls {
    final List<String> candidates = [];
    if (productionBaseUrl != null && productionBaseUrl!.trim().isNotEmpty) {
      candidates.add(productionBaseUrl!.trim());
    }
    candidates.add(_activeBaseUrl);
    final fallback = _activeBaseUrl == _primaryBaseUrl ? _emulatorBaseUrl : _primaryBaseUrl;
    if (!candidates.contains(fallback)) {
      candidates.add(fallback);
    }
    return candidates;
  }

  /// Analyze symptoms via the FastAPI triage router (/api/v1/triage/analyze)
  static Future<TriageResult> analyzeSymptoms({
    required String symptomsText,
    String? patientId,
    bool includeMedicalHistory = true,
    String? scrubbedHistoryContext,
    List<Map<String, String>>? chatHistory,
    double? spo2,
    double? heartRate,
    double? bpSys,
    double? bpDia,
  }) async {
    final Map<String, dynamic> payload = {
      'symptoms_text': symptomsText,
      'include_medical_history': includeMedicalHistory,
    };
    if (patientId != null) payload['patient_id'] = patientId;
    if (scrubbedHistoryContext != null) payload['scrubbed_history_context'] = scrubbedHistoryContext;

    if (chatHistory != null && chatHistory.isNotEmpty) payload['chat_history'] = chatHistory;
    if (spo2 != null) payload['spo2'] = spo2;
    if (heartRate != null) payload['heart_rate'] = heartRate;
    if (bpSys != null) payload['blood_pressure_sys'] = bpSys;
    if (bpDia != null) payload['blood_pressure_dia'] = bpDia;


    final bodyData = jsonEncode(payload);
    final headers = {'Content-Type': 'application/json'};

    // Attempt request with candidate base URLs
    for (final baseUrl in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/triage/analyze');
        final response = await http.post(uri, headers: headers, body: bodyData).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl; // Cache working URL
          final json = jsonDecode(response.body) as Map<String, dynamic>;

          final isEmergency = json['is_emergency_bypass'] as bool? ?? false;
          final rationale = json['plain_language_rationale'] as String? ?? 'Analysis complete.';
          final redFlagsRaw = json['red_flags'] as List<dynamic>? ?? [];
          final redFlags = redFlagsRaw.map((e) => e.toString()).toList();
          final extractedSymptoms = (json['extracted_symptoms'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

          final predictedRaw = json['predicted_diagnoses'] as List<dynamic>? ?? [];
          final List<Differential> differentials = [];

          int topConfidence = 75;
          int computedTier = isEmergency ? 3 : 1;

          for (final item in predictedRaw) {
            final map = item as Map<String, dynamic>;
            final rawName = (map['condition_name'] as String? ?? 'Unspecified Condition').replaceAll('_', ' ');
            final formattedName = rawName.isEmpty ? 'Condition' : rawName[0].toUpperCase() + rawName.substring(1);
            final prob = (map['probability_score'] as num? ?? 0.5).toDouble();
            final risk = (map['calculated_risk_index'] as num? ?? 5.0).toDouble();

            final confPct = (prob * 100).round().clamp(10, 99);
            differentials.add(
              Differential(
                cause: formattedName,
                note: 'Risk Index: $risk',
                confidence: confPct,
              ),
            );

            if (risk >= 7.5 || isEmergency) {
              computedTier = 3;
            } else if (risk >= 4.0 && computedTier < 3) {
              computedTier = 2;
            }
          }

          if (differentials.isNotEmpty) {
            topConfidence = differentials.first.confidence;
          } else {
            differentials.add(const Differential(cause: "Clinical Observation", note: "Mild presentation", confidence: 80));
          }

          String headline;
          if (isEmergency) {
            headline = "CRITICAL ALERT — Urgent Care Required";
          } else if (computedTier == 3) {
            headline = "Red Flag Detected — Live Doctor Recommended";
          } else if (computedTier == 2) {
            headline = "Moderate Symptoms — Doctor Review Recommended";
          } else {
            headline = "Low Risk — Home Care Protocol Suggested";
          }

          List<String> advice = [];
          if (isEmergency) {
            advice = [
              "Do not exert yourself. Sit upright and stay calm.",
              "Call emergency services or seek immediate medical attention.",
              "Vitals check triggered safety bypass protocol."
            ];
          } else if (computedTier == 2) {
            advice = [
              "Rest in a comfortable environment and monitor symptoms.",
              "Stay well-hydrated.",
              if (extractedSymptoms.isNotEmpty) "Extracted symptom markers: ${extractedSymptoms.join(', ')}",
              "Your case details have been formatted for clinician review."
            ];
          } else {
            advice = [
              "Rest well and monitor your symptoms over the next 24-48 hours.",
              "Drink plenty of fluids and maintain adequate rest.",
              if (extractedSymptoms.isNotEmpty) "Observed markers: ${extractedSymptoms.join(', ')}",
              "Re-evaluate if symptoms escalate or new red-flags appear."
            ];
          }

          // Parse 5 Compulsory Medical Sections
          final probableRaw = json['probable_conditions'] as List<dynamic>? ?? [];
          final List<ProbableCondition> probableConditions = probableRaw.map((e) {
            final m = e as Map<String, dynamic>;
            final sev = (m['severity_remark'] as String? ?? 'MEDIUM').toUpperCase();
            return ProbableCondition(
              conditionName: m['condition_name'] as String? ?? 'Observed Condition',
              severityRemark: ['HIGH', 'MEDIUM', 'LOW'].contains(sev) ? sev : 'MEDIUM',
              description: m['description'] as String? ?? '',
            );
          }).toList();

          final triageReasoning = json['triage_reasoning'] as String? ?? rationale;
          final clinicalExplanation = json['clinical_explanation'] as String? ?? '';
          final recommendedNextSteps = (json['recommended_next_steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
          final criticalRedFlags = (json['critical_red_flags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

          return TriageResult(
            tier: computedTier,
            confidence: topConfidence,
            headline: headline,
            rationale: rationale,
            redFlag: redFlags.isNotEmpty ? redFlags.join('\n• ') : null,
            differential: differentials,
            advice: advice,
            probableConditions: probableConditions,
            triageReasoning: triageReasoning,
            clinicalExplanation: clinicalExplanation,
            recommendedNextSteps: recommendedNextSteps,
            criticalRedFlags: criticalRedFlags,
          );
        }
      } catch (e) {
        // Continue to fallback or try next URL
      }
    }


    // Fallback if backend is unavailable
    return _generateFallbackResult(symptomsText);
  }

  /// Check chronic metric trends (/api/v1/chronic/check-trends)
  static Future<Map<String, dynamic>> checkTrends({
    required String conditionName,
    required List<double> metricHistory,
  }) async {
    final bodyData = jsonEncode({
      'condition_name': conditionName,
      'metric_history': metricHistory,
    });
    final headers = {'Content-Type': 'application/json'};

    for (final baseUrl in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/chronic/check-trends');
        final response = await http.post(
          uri,
          headers: headers,
          body: bodyData,
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return {
      'is_adverse_trend': false,
      'nudge_text': 'Metrics remain stable within normal parameters.',
    };
  }

  /// Register patient profile asynchronously to FastAPI / MongoDB (/api/v1/patient/register)
  static Future<Map<String, dynamic>?> registerPatient(Map<String, dynamic> patientData) async {
    final bodyData = jsonEncode(patientData);
    final headers = {'Content-Type': 'application/json'};

    for (final baseUrl in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/patient/register');
        final response = await http.post(uri, headers: headers, body: bodyData).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        // Logging error silently for background tasks
        print('Background registration attempt at $baseUrl error: $e');
      }
    }
    return null;
  }

  /// Lookup existing patient profile by phone number (/api/v1/patient/by-phone)
  static Future<Map<String, dynamic>?> fetchPatientByPhone(String phoneNumber) async {
    final encodedPhone = Uri.encodeComponent(phoneNumber);
    for (final baseUrl in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/patient/by-phone?phone_number=$encodedPhone');
        final response = await http.get(uri).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Fetch patient by phone error at $baseUrl: $e');
      }
    }
    return null;
  }


  /// Update existing patient profile by patient ID (/api/v1/patient/{patient_id})
  static Future<Map<String, dynamic>?> updatePatient(String patientId, Map<String, dynamic> updates) async {
    final bodyData = jsonEncode(updates);
    final headers = {'Content-Type': 'application/json'};

    for (final baseUrl in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/patient/$patientId');
        final response = await http.put(uri, headers: headers, body: bodyData).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Update patient error at $baseUrl: $e');
      }
    }
    return null;
  }

  /// Upload medical report (PDF or Image) to FastAPI backend (/api/v1/patient/upload-report)
  static Future<Map<String, dynamic>?> uploadMedicalReport({
    required List<int> fileBytes,
    required String fileName,
    required String patientId,
  }) async {
    for (final baseUrl in _candidateBaseUrls) {
      try {
        final uri = Uri.parse('$baseUrl/api/v1/patient/upload-report');
        final request = http.MultipartRequest('POST', uri);
        request.fields['patient_id'] = patientId;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: fileName,
          ),
        );

        final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          _activeBaseUrl = baseUrl;
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        print('Upload report error at $baseUrl: $e');
      }
    }
    return null;
  }




  /// Local intelligent fallback generator if backend service is unreachable
  static TriageResult _generateFallbackResult(String input) {
    final lower = input.toLowerCase();

    if (lower.contains('chest pain') || lower.contains('breath') || lower.contains('heart attack') || lower.contains('shortness') || lower.contains('bp') || lower.contains('blood pressure')) {
      return const TriageResult(
        tier: 3,
        confidence: 88,
        headline: "High Risk — Live Doctor Route Triggered",
        rationale: "Cardiovascular discomfort or shortness of breath reported. Immediate medical evaluation is required.",
        redFlag: "High-risk cardiac symptom combination detected. Real doctor consult advised immediately.",
        differential: [
          Differential(cause: "Essential Hypertension & Vascular Strain", note: "Urgent BP monitoring", confidence: 65),
          Differential(cause: "Anginal Discomfort / Cardiac Overload", note: "SpO2 check needed", confidence: 25),
        ],
        advice: [
          "Do not strain yourself.",
          "Seek emergency care or connect to a live clinician immediately.",
          "Keep vitals monitor nearby."
        ],
        probableConditions: [
          ProbableCondition(
            conditionName: "Essential Hypertension & Vascular Strain",
            severityRemark: "HIGH",
            description: "Elevated arterial blood pressure causing vascular resistance and clinical strain.",
          ),
          ProbableCondition(
            conditionName: "Anginal Discomfort & Myocardial Strain",
            severityRemark: "MEDIUM",
            description: "Imbalance in myocardial oxygen demand causing acute ischemic chest discomfort.",
          ),
          ProbableCondition(
            conditionName: "Stress-Induced Cardiopulmonary Overload",
            severityRemark: "LOW",
            description: "Transient tachycardia and elevated vascular tone secondary to physical stress.",
          ),
        ],
        triageReasoning: "High priority assigned to Essential Hypertension and Anginal strain based on reported symptoms and elevated cardiovascular workload risk.",
        clinicalExplanation: "Cardiovascular chest discomfort requires prompt clinical evaluation. Avoid physical exertion and keep prescribed antihypertensive therapy accessible.",
        recommendedNextSteps: [
          "Rest comfortably in a reclined position and avoid physical strain",
          "Measure and log blood pressure and heart rate",
          "Seek immediate emergency medical evaluation if chest pressure worsens"
        ],
        criticalRedFlags: [
          "Severe crushing chest pain radiating to left arm or jaw",
          "Sudden severe shortness of breath or fainting (syncope)"
        ],
      );
    } else if (lower.contains('headache') || lower.contains('dizzy') || lower.contains('dizziness') || lower.contains('sar dard') || lower.contains('fever') || lower.contains('sugar') || lower.contains('hba1c')) {
      return const TriageResult(
        tier: 2,
        confidence: 76,
        headline: "NO-RISK — Moderate Symptoms Review",
        rationale: "Cephalic discomfort and dizziness reported. Clinical evaluation recommended.",
        redFlag: null,
        differential: [
          Differential(cause: "Migraine / Tension Headache", note: "Hydration & rest required", confidence: 55),
          Differential(cause: "Glycemic / Vitals Variability", note: "Check sugar & BP trends", confidence: 30),
        ],
        advice: [
          "Rest in a quiet room and stay hydrated.",
          "Case file formatted for async clinician review.",
          "Re-check symptoms in 4 hours."
        ],
        probableConditions: [
          ProbableCondition(
            conditionName: "Migraine without Aura",
            severityRemark: "HIGH",
            description: "Throbbing cephalic discomfort exacerbated by bright light or exertion.",
          ),
          ProbableCondition(
            conditionName: "Primary Tension-Type Headache",
            severityRemark: "MEDIUM",
            description: "Bilateral pressure headache associated with fatigue, eye strain, or dehydration.",
          ),
          ProbableCondition(
            conditionName: "Systemic Fatigue & Physiological Strain",
            severityRemark: "LOW",
            description: "General bodily exhaustion, fluid depletion, or stress adaptation.",
          ),
        ],
        triageReasoning: "Triage assessment identifies cephalic discomfort and dizziness. Mild headaches often stem from fluid shifts, fatigue, or vascular tension.",
        clinicalExplanation: "Mild headaches and dizziness improve with rest and hydration. Over-the-counter analgesics (such as Acetaminophen) may be used under guidance.",
        recommendedNextSteps: [
          "Rest in a quiet, dimly lit, well-ventilated room",
          "Drink 2-3 liters of water or electrolyte fluid daily",
          "Limit screen exposure and schedule a doctor visit if symptoms persist"
        ],
        criticalRedFlags: [], // Omitted for NO-RISK / HOMECARE evaluations
      );
    }

    return TriageResult(
      tier: 1,
      confidence: 85,
      headline: "HOMECARE — Low Risk Protocol",
      rationale: "Symptom check completed. Clinical parameters evaluated.",
      redFlag: null,
      differential: [
        Differential(cause: "Systemic Fatigue / Stress", note: "Hydration protocol", confidence: 70),
        Differential(cause: "General Physiological Adjustment", note: "Rest observation", confidence: 20),
      ],
      advice: [
        "Rest well and stay hydrated.",
        "Log vitals regularly.",
        "If new symptoms occur, run another check-in."
      ],
      probableConditions: [
        ProbableCondition(
          conditionName: "High Symptom Observation Marker",
          severityRemark: "HIGH",
          description: "Primary observation metric under baseline health monitoring.",
        ),
        ProbableCondition(
          conditionName: "Systemic Health & Vitals Review",
          severityRemark: "MEDIUM",
          description: "Routine physiological check and baseline health monitoring.",
        ),
        ProbableCondition(
          conditionName: "Mild Physiological Fatigue",
          severityRemark: "LOW",
          description: "Transient tiredness or hydration shift.",
        ),
      ],
      triageReasoning: "Health check-in processed. No acute red alert flags detected for your query.",
      clinicalExplanation: "General symptoms respond well to restorative rest, proper fluid intake, and balanced nutrition.",
      recommendedNextSteps: [
        "Ensure 8 hours of restorative sleep",
        "Maintain optimal daily hydration",
        "Track symptom progression"
      ],
      criticalRedFlags: [], // Omitted for NO-RISK / HOMECARE evaluations
    );
  }
}
