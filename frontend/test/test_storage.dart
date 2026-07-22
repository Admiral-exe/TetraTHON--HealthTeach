import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthtech_app/data/mock.dart';
import 'package:healthtech_app/services/api_service.dart';
import 'package:healthtech_app/screens/checkin_screen.dart';

void main() {
  test('Test ChatSession serialization and deserialization', () {
    final triage = TriageResult(
      tier: 1,
      confidence: 88,
      headline: "Low Severity — Tension Headache",
      rationale: "Symptoms indicate tension headache.",
      redFlag: null,
      differential: [
        Differential(cause: "Tension Headache", note: "Stress", confidence: 80),
      ],
      advice: ["Rest"],
      probableConditions: [
        ProbableCondition(conditionName: "Migraine", severityRemark: "HIGH", description: "Right side headache with light sensitivity.")
      ],
      triageReasoning: "High priority to Migraine.",
      clinicalExplanation: "Neurovascular inflammation.",
      recommendedNextSteps: ["Rest in dark room"],
      criticalRedFlags: ["Thunderclap headache"],
    );

    final session = ChatSession(
      id: "test_session_123",
      title: "Test Headache Session",
      date: DateTime.now(),
      messages: [
        ChatMessage(sender: 'user', text: "Severe right side headache"),
        ChatMessage(sender: 'assistant', text: "High priority assigned to Migraine.", triageResult: triage),
      ],
    );

    final serializedMap = {
      'id': session.id,
      'title': session.title,
      'date': session.date.toIso8601String(),
      'messages': session.messages.map((m) => {
        'sender': m.sender,
        'text': m.text,
        'timestamp': m.timestamp.toIso8601String(),
        'triageResult': m.triageResult != null ? {
          'tier': m.triageResult!.tier,
          'confidence': m.triageResult!.confidence,
          'headline': m.triageResult!.headline,
          'rationale': m.triageResult!.rationale,
          'redFlag': m.triageResult!.redFlag,
          'triageReasoning': m.triageResult!.triageReasoning,
          'clinicalExplanation': m.triageResult!.clinicalExplanation,
          'recommendedNextSteps': m.triageResult!.recommendedNextSteps,
          'criticalRedFlags': m.triageResult!.criticalRedFlags,
          'differential': m.triageResult!.differential.map((d) => {'cause': d.cause, 'note': d.note, 'confidence': d.confidence}).toList(),
          'advice': m.triageResult!.advice,
          'probableConditions': m.triageResult!.probableConditions.map((pc) => {'conditionName': pc.conditionName, 'severityRemark': pc.severityRemark, 'description': pc.description}).toList(),
        } : null,
      }).toList(),
    };

    final jsonString = jsonEncode(serializedMap);
    final decodedJson = jsonDecode(jsonString);

    expect(decodedJson['id'], equals("test_session_123"));
    expect(decodedJson['messages'].length, equals(2));
    expect(decodedJson['messages'][1]['triageResult']['probableConditions'][0]['conditionName'], equals("Migraine"));
  });
}
