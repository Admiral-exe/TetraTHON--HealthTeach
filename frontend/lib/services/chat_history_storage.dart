import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../data/mock.dart';
import '../screens/checkin_screen.dart';

class ChatHistoryStorage {
  static const String _historyFolderName = 'Chat_History';

  /// Get or create local `Chat_History` directory inside app storage
  static Future<Directory?> _getHistoryDirectory() async {
    try {
      if (kIsWeb) return null; // Web fallback
      final appDocDir = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${appDocDir.path}/$_historyFolderName');
      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }
      return historyDir;
    } catch (e) {
      print('Error accessing Chat_History directory: $e');
      return null;
    }
  }

  /// Save or update a ChatSession into Chat_History/session_{id}.json
  static Future<void> saveSession(ChatSession session) async {
    try {
      final dir = await _getHistoryDirectory();
      if (dir == null) return;

      final file = File('${dir.path}/session_${session.id}.json');
      final Map<String, dynamic> data = {
        'id': session.id,
        'title': session.title,
        'date': session.date.toIso8601String(),
        'messages': session.messages.map((m) => _serializeMessage(m)).toList(),
      };

      await file.writeAsString(jsonEncode(data));
      await _updateIndex(session);
    } catch (e) {
      print('Error saving session ${session.id}: $e');
    }
  }

  /// Load all past chat sessions from Chat_History directory
  static Future<List<ChatSession>> loadAllSessions() async {
    try {
      final dir = await _getHistoryDirectory();
      if (dir == null) return [];

      final List<ChatSession> sessions = [];
      final List<FileSystemEntity> files = await dir.list().toList();

      for (final entity in files) {
        if (entity is File && entity.path.contains('session_') && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final Map<String, dynamic> json = jsonDecode(content);
            final session = _deserializeSession(json);
            sessions.add(session);
          } catch (err) {
            print('Error parsing session file ${entity.path}: $err');
          }
        }
      }

      // Sort newest first
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return sessions;
    } catch (e) {
      print('Error loading chat history: $e');
      return [];
    }
  }

  /// Delete session log file from Chat_History folder
  static Future<void> deleteSession(String sessionId) async {
    try {
      final dir = await _getHistoryDirectory();
      if (dir == null) return;

      final file = File('${dir.path}/session_$sessionId.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting session $sessionId: $e');
    }
  }

  // Helper: Update index file
  static Future<void> _updateIndex(ChatSession session) async {
    try {
      final dir = await _getHistoryDirectory();
      if (dir == null) return;

      final indexFile = File('${dir.path}/index.json');
      List<dynamic> indexList = [];

      if (await indexFile.exists()) {
        try {
          final content = await indexFile.readAsString();
          indexList = jsonDecode(content) as List<dynamic>;
        } catch (_) {}
      }

      indexList.removeWhere((item) => item['id'] == session.id);
      indexList.add({
        'id': session.id,
        'title': session.title,
        'date': session.date.toIso8601String(),
        'message_count': session.messages.length,
      });

      await indexFile.writeAsString(jsonEncode(indexList));
    } catch (e) {
      print('Error updating index file: $e');
    }
  }

  // Serializer helpers
  static Map<String, dynamic> _serializeMessage(ChatMessage msg) {
    return {
      'sender': msg.sender,
      'text': msg.text,
      'timestamp': msg.timestamp.toIso8601String(),
      'triageResult': msg.triageResult != null ? _serializeTriageResult(msg.triageResult!) : null,
    };
  }

  static Map<String, dynamic> _serializeTriageResult(TriageResult r) {
    return {
      'tier': r.tier,
      'confidence': r.confidence,
      'headline': r.headline,
      'rationale': r.rationale,
      'redFlag': r.redFlag,
      'triageReasoning': r.triageReasoning,
      'clinicalExplanation': r.clinicalExplanation,
      'recommendedNextSteps': r.recommendedNextSteps,
      'criticalRedFlags': r.criticalRedFlags,
      'differential': r.differential
          .map((d) => {
                'cause': d.cause,
                'note': d.note,
                'confidence': d.confidence,
              })
          .toList(),
      'advice': r.advice,
      'probableConditions': r.probableConditions
          .map((pc) => {
                'conditionName': pc.conditionName,
                'severityRemark': pc.severityRemark,
                'description': pc.description,
              })
          .toList(),
    };
  }

  static ChatSession _deserializeSession(Map<String, dynamic> json) {
    final String id = json['id'] as String;
    final String title = json['title'] as String? ?? 'Chat Session';
    final DateTime date = DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now();

    final List<dynamic> rawMsgs = json['messages'] as List<dynamic>? ?? [];
    final List<ChatMessage> messages = rawMsgs.map((m) {
      final map = m as Map<String, dynamic>;
      final sender = map['sender'] as String? ?? 'user';
      final text = map['text'] as String? ?? '';
      final timestamp = DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now();
      final rawTriage = map['triageResult'] as Map<String, dynamic>?;

      return ChatMessage(
        sender: sender,
        text: text,
        timestamp: timestamp,
        triageResult: rawTriage != null ? _deserializeTriageResult(rawTriage) : null,
      );
    }).toList();

    return ChatSession(
      id: id,
      title: title,
      date: date,
      messages: messages,
    );
  }

  static TriageResult _deserializeTriageResult(Map<String, dynamic> map) {
    final int tier = map['tier'] as int? ?? 1;
    final int confidence = map['confidence'] as int? ?? 75;
    final String headline = map['headline'] as String? ?? '';
    final String rationale = map['rationale'] as String? ?? '';
    final String? redFlag = map['redFlag'] as String?;
    final String triageReasoning = map['triageReasoning'] as String? ?? rationale;
    final String clinicalExplanation = map['clinicalExplanation'] as String? ?? '';

    final List<dynamic> rawDiff = map['differential'] as List<dynamic>? ?? [];
    final List<Differential> differential = rawDiff.map((d) {
      final dm = d as Map<String, dynamic>;
      return Differential(
        cause: dm['cause'] as String? ?? '',
        note: dm['note'] as String? ?? '',
        confidence: dm['confidence'] as int? ?? 50,
      );
    }).toList();

    final List<dynamic> rawAdvice = map['advice'] as List<dynamic>? ?? [];
    final List<String> advice = rawAdvice.map((e) => e.toString()).toList();

    final List<dynamic> rawNext = map['recommendedNextSteps'] as List<dynamic>? ?? [];
    final List<String> recommendedNextSteps = rawNext.map((e) => e.toString()).toList();

    final List<dynamic> rawRed = map['criticalRedFlags'] as List<dynamic>? ?? [];
    final List<String> criticalRedFlags = rawRed.map((e) => e.toString()).toList();

    final List<dynamic> rawProb = map['probableConditions'] as List<dynamic>? ?? [];
    final List<ProbableCondition> probableConditions = rawProb.map((pc) {
      final pcm = pc as Map<String, dynamic>;
      return ProbableCondition(
        conditionName: pcm['conditionName'] as String? ?? '',
        severityRemark: pcm['severityRemark'] as String? ?? 'MEDIUM',
        description: pcm['description'] as String? ?? '',
      );
    }).toList();

    return TriageResult(
      tier: tier,
      confidence: confidence,
      headline: headline,
      rationale: rationale,
      redFlag: redFlag,
      differential: differential,
      advice: advice,
      probableConditions: probableConditions,
      triageReasoning: triageReasoning,
      clinicalExplanation: clinicalExplanation,
      recommendedNextSteps: recommendedNextSteps,
      criticalRedFlags: criticalRedFlags,
    );
  }
}
