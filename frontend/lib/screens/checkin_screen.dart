import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme.dart';
import '../data/mock.dart';
import '../widgets/primitives.dart';
import '../services/api_service.dart';
import '../services/chat_history_storage.dart';


class ChatMessage {
  final String sender; // 'user' or 'assistant'
  final String text;
  final TriageResult? triageResult;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.text,
    this.triageResult,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ChatSession {
  final String id;
  String title;
  final DateTime date;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.date,
    required this.messages,
  });
}

class CheckInScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  final void Function(int tab)? onNavigate;
  final void Function(bool isScrollingDown)? onScrollDirectionChanged;

  const CheckInScreen({
    super.key,
    this.userProfile,
    this.onNavigate,
    this.onScrollDirectionChanged,
  });

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}


class _CheckInScreenState extends State<CheckInScreen> with SingleTickerProviderStateMixin {

  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  bool _listening = false;
  bool _done = false;
  bool _isTextChatMode = false;
  bool _isSendingQuery = false;
  bool _includeHistoryToggle = true;
  bool _isScrolledDown = false;

  final List<String> _answers = [];

  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechInitialized = false;

  TriageResult? _aiTriageResult;

  // History sessions list & current active session ID
  final List<ChatSession> _sessions = [];
  late String _activeSessionId;

  @override
  void initState() {
    super.initState();
    _initMockSessions();
    _scrollController.addListener(_onScroll);
    _loadHistorySessions();
  }

  Future<void> _toggleSpeechListening() async {
    if (_listening) {
      setState(() => _listening = false);
      try {
        await _speech.stop();
      } catch (_) {}
      if (_chatController.text.trim().isNotEmpty) {
        _sendTypedQuery();
      }
      return;
    }

    try {
      if (!_speechInitialized) {
        _speechInitialized = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              if (mounted) {
                setState(() => _listening = false);
                if (_chatController.text.trim().isNotEmpty) {
                  _sendTypedQuery();
                }
              }
            }
          },
          onError: (errorNotification) {
            if (mounted) setState(() => _listening = false);
          },
        );
      }

      if (_speechInitialized) {
        setState(() {
          _listening = true;
          _isTextChatMode = true;
        });
        _chatController.clear();
        await _speech.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _chatController.text = result.recognizedWords;
              });
            }
          },
        );
      } else {
        setState(() {
          _listening = !_listening;
        });
      }
    } catch (e) {
      print('Speech recognition fallback: $e');
      setState(() {
        _listening = !_listening;
      });
    }
  }


  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;
    final direction = _scrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && !_isScrolledDown) {
      setState(() => _isScrolledDown = true);
      widget.onScrollDirectionChanged?.call(true);
    } else if (direction == ScrollDirection.forward && _isScrolledDown) {
      setState(() => _isScrolledDown = false);
      widget.onScrollDirectionChanged?.call(false);
    }
  }

  Future<void> _loadHistorySessions() async {
    final loaded = await ChatHistoryStorage.loadAllSessions();
    if (!mounted) return;
    if (loaded.isNotEmpty) {
      setState(() {
        _sessions.clear();
        _sessions.addAll(loaded);
        _activeSessionId = _sessions.first.id;
      });
    }
  }

  void _initMockSessions() {
    final now = DateTime.now();

    final activeSession = ChatSession(
      id: "session_active",
      title: "Today's Daily Check-in",
      date: now,
      messages: [
        ChatMessage(sender: 'assistant', text: checkInScript[0]["q"] as String),
      ],
    );

    _sessions.clear();
    _sessions.add(activeSession);
    _activeSessionId = activeSession.id;
  }

  ChatSession get _activeSession {
    if (_sessions.isEmpty) {
      _initMockSessions();
    }
    return _sessions.firstWhere(
      (s) => s.id == _activeSessionId,
      orElse: () => _sessions.first,
    );
  }


  List<ChatMessage> get _chatMessages => _activeSession.messages;

  @override
  void dispose() {
    _pulse.dispose();
    _chatController.dispose();
    _chatFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _createNewChatSession() {
    final newId = "session_${DateTime.now().millisecondsSinceEpoch}";
    final newSession = ChatSession(
      id: newId,
      title: "New Health Chat",
      date: DateTime.now(),
      messages: [
        ChatMessage(sender: 'assistant', text: "How are you feeling today? Describe any symptoms or questions."),
      ],
    );

    setState(() {
      _sessions.insert(0, newSession);
      _activeSessionId = newId;
      _done = false;
      _answers.clear();
      _isTextChatMode = true;
    });

    ChatHistoryStorage.saveSession(newSession);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _chatFocusNode.requestFocus();
        _scrollToBottom();
      }
    });
  }

  void _deleteChatSession(ChatSession session) {
    ChatHistoryStorage.deleteSession(session.id);
    setState(() {
      _sessions.removeWhere((s) => s.id == session.id);
      if (_sessions.isEmpty) {
        _createNewChatSession();
      } else if (_activeSessionId == session.id) {
        _activeSessionId = _sessions.first.id;
      }
    });
  }

  void _selectChatSession(ChatSession session) {
    setState(() {
      _activeSessionId = session.id;
      _done = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendTypedQuery() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isSendingQuery) return;

    _chatController.clear();
    setState(() {
      _isSendingQuery = true;
      _chatMessages.add(ChatMessage(sender: 'user', text: text));
      if (_activeSession.title == "New Health Chat" || _activeSession.title.startsWith("Today's")) {
        _activeSession.title = text.length > 24 ? "${text.substring(0, 24)}…" : text;
      }
    });
    ChatHistoryStorage.saveSession(_activeSession);
    _scrollToBottom();

    // Build LangChain context window for backend (last 3 interactions = max 6 messages)
    final historyForBackend = _chatMessages
        .take(_chatMessages.length - 1)
        .where((m) => m.text.isNotEmpty)
        .toList();

    final recentMessages = historyForBackend.length > 6
        ? historyForBackend.sublist(historyForBackend.length - 6)
        : historyForBackend;

    final List<Map<String, String>> chatHistoryPayload = recentMessages
        .map((m) => {
              'role': m.sender == 'user' ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    // Call FastAPI backend triage endpoint with LangChain context window and targeted medical history
    final patientId = widget.userProfile?['patient_id'];
    final result = await ApiService.analyzeSymptoms(
      symptomsText: text,
      patientId: patientId,
      includeMedicalHistory: _includeHistoryToggle,
      chatHistory: chatHistoryPayload,
    );

    if (mounted) {
      setState(() {
        _isSendingQuery = false;
        _aiTriageResult = result;
        _chatMessages.add(
          ChatMessage(
            sender: 'assistant',
            text: result.rationale,
            triageResult: result,
          ),
        );
      });
      ChatHistoryStorage.saveSession(_activeSession);
      _scrollToBottom();
    }
  }


  void _enableTextChatMode() {

    setState(() {
      _isTextChatMode = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _chatFocusNode.requestFocus();
        _scrollToBottom();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_done && !_isTextChatMode) return _summary();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildHistoryDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Top-Left Double-Dash (=) Menu Button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  Builder(
                    builder: (scaffoldContext) => IconButton(
                      onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                      icon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          "=",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                        ),
                      ),
                      tooltip: "Open Chat History Menu",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "DAILY HEALTH CHECK-IN",
                          style: body(size: 11, weight: FontWeight.w600, color: AppColors.mutedFg)
                              .copyWith(letterSpacing: 1.0),
                        ),
                        Text(
                          _activeSession.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: display(size: 18, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (_isTextChatMode)
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: AppColors.primary),
                      onPressed: () {
                        setState(() {
                          _isTextChatMode = false;
                        });
                        FocusScope.of(context).unfocus();
                      },
                      tooltip: "Switch to Voice",
                    ),
                ],
              ),
            ),

            // Scrollable Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: _chatMessages.length + (_isSendingQuery ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index < _chatMessages.length) {
                    final msg = _chatMessages[index];
                    return _buildChatMessageBubble(msg);
                  } else {
                    return _buildTypingIndicator();
                  }
                },
              ),
            ),

            // Bottom Control Bar
            _buildVoiceAndChipsControl(),
          ],
        ),
      ),
    );
  }

  /// Slide-Out Drawer for Chat History with Delete (3 vertical dots) Options
  Widget _buildHistoryDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text("Chat History", style: display(size: 18, weight: FontWeight.w600)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.mutedFg),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),

            // "+ New Chat" Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _createNewChatSession();
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  label: Text(
                    "New Chat",
                    style: body(size: 14.5, weight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Text(
                "RECENT CONVERSATIONS (LANGCHAIN MEMORY)",
                style: body(size: 10.5, weight: FontWeight.w700, color: AppColors.mutedFg)
                    .copyWith(letterSpacing: 0.8),
              ),
            ),

            // Sessions List with 3 Vertical Dots (Bin / Delete) Options
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _sessions.length,
                itemBuilder: (context, idx) {
                  final session = _sessions[idx];
                  final isSelected = session.id == _activeSessionId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.secondary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: () {
                        Navigator.pop(context);
                        _selectChatSession(session);
                      },
                      leading: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: isSelected ? AppColors.primary : AppColors.mutedFg,
                      ),
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(
                          size: 13.5,
                          weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.foreground,
                        ),
                      ),
                      subtitle: Text(
                        "${session.messages.length} messages",
                        style: body(size: 11, color: AppColors.mutedFg),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                            ),

                          // 3 Vertical Dots menu for deleting chat
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.mutedFg),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteChatSession(session);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Delete chat",
                                      style: body(size: 13, color: Colors.red, weight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Context window set to 3 interactions. Older turns cycle out smoothly.",
                textAlign: TextAlign.center,
                style: body(size: 11, color: AppColors.mutedFg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == 'user';
    final result = msg.triageResult;

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x0C000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            msg.text,
            style: body(size: 14.5, weight: FontWeight.w500, color: Colors.white),
          ),
        ),
      );
    }

    // Assistant / Arogya AI Message
    final t = result != null ? tierStyle(result.tier) : tierStyle(1);


    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: result != null ? t.bg : AppColors.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  "AROGYA AI RESPONSE",
                  style: body(size: 11, weight: FontWeight.w700, color: AppColors.mutedFg)
                      .copyWith(letterSpacing: 0.8),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              msg.text,
              style: body(size: 14.5, weight: FontWeight.w500).copyWith(height: 1.45),
            ),

            if (result != null) _buildStructuredTriageCard(result),
          ],
        ),
      ),
    );
  }

  Widget _buildStructuredTriageCard(TriageResult result) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PROBABLE CONDITIONS (3-4 Conditions with Severity Remarks HIGH / MEDIUM / LOW)
          if (result.probableConditions.isNotEmpty) ...[
            Text("1. Probable Conditions", style: body(size: 13.5, weight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            ...result.probableConditions.map((pc) {
              final sev = pc.severityRemark.toUpperCase();
              Color badgeBg;
              Color badgeFg;
              Color borderCol;

              if (sev == "HIGH") {
                badgeBg = const Color(0xFFFEE2E2);
                badgeFg = const Color(0xFFDC2626);
                borderCol = const Color(0xFFFCA5A5);
              } else if (sev == "LOW") {
                badgeBg = const Color(0xFFDCFCE7);
                badgeFg = const Color(0xFF16A34A);
                borderCol = const Color(0xFF86EFAC);
              } else {
                // MEDIUM
                badgeBg = const Color(0xFFFEF3C7);
                badgeFg = const Color(0xFFD97706);
                borderCol = const Color(0xFFFDE68A);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badgeBg.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderCol),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            pc.conditionName,
                            style: body(size: 13.5, weight: FontWeight.bold, color: AppColors.foreground),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: borderCol),
                          ),
                          child: Text(
                            sev,
                            style: body(size: 10.5, weight: FontWeight.w800, color: badgeFg),
                          ),
                        ),
                      ],
                    ),
                    if (pc.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        pc.description,
                        style: body(size: 12, color: AppColors.mutedFg).copyWith(height: 1.35),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],

          // 2. TRIAGE ASSESSMENT REASONING
          if (result.triageReasoning.isNotEmpty) ...[
            Text("2. Triage Assessment Reasoning", style: body(size: 13.5, weight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                result.triageReasoning,
                style: body(size: 12.5, color: AppColors.foreground).copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 3. CLINICAL EXPLANATION & MEDICATIONS
          if (result.clinicalExplanation.isNotEmpty) ...[
            Text("3. Clinical Explanation & Medications", style: body(size: 13.5, weight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                result.clinicalExplanation,
                style: body(size: 12.5, color: AppColors.foreground).copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 4. RECOMMENDED NEXT STEPS
          if (result.recommendedNextSteps.isNotEmpty) ...[
            Text("4. Recommended Next Steps", style: body(size: 13.5, weight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result.recommendedNextSteps.map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Expanded(child: Text(step, style: body(size: 12.5, color: AppColors.foreground))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 5. CRITICAL RED FLAGS TO MONITOR (Omitted for NO-RISK / HOMECARE evaluations)
          if (result.criticalRedFlags.isNotEmpty) ...[
            Text("5. Critical Red Flags to Monitor", style: body(size: 13.5, weight: FontWeight.bold, color: const Color(0xFFDC2626))),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Text("CRITICAL MONITORING ALERTS", style: body(size: 11.5, weight: FontWeight.w800, color: const Color(0xFFDC2626))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (result.criticalRedFlags.isNotEmpty)
                    ...result.criticalRedFlags.map((flag) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text("🚨 $flag", style: body(size: 12, weight: FontWeight.w600, color: const Color(0xFF991B1B))),
                        ))
                  else if (result.redFlag != null)
                    Text("🚨 ${result.redFlag}", style: body(size: 12, weight: FontWeight.w600, color: const Color(0xFF991B1B))),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // DISCLAIMER & DOCTOR BOOKING CTA
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "AI can make mistakes but you can book an appointment with doctors for consultation",
                        style: body(size: 12.5, color: AppColors.primary, weight: FontWeight.w600).copyWith(height: 1.35),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => widget.onNavigate?.call(1),
                    icon: const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white),
                    label: Text("Book Now", style: body(size: 12.5, weight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text(
              "Arogya AI is analyzing clinical data…",
              style: body(size: 13, color: AppColors.mutedFg, weight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceAndChipsControl() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PRIVACY HISTORY TOGGLE SWITCH (Smoothly collapses on scroll down)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: _isScrolledDown ? 0 : 50,
            margin: EdgeInsets.only(bottom: _isScrolledDown ? 0 : 12),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isScrolledDown ? 0.0 : 1.0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _includeHistoryToggle ? AppColors.primary.withValues(alpha: 0.3) : AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _includeHistoryToggle ? Icons.history_edu_rounded : Icons.history_toggle_off_rounded,
                            size: 18,
                            color: _includeHistoryToggle ? AppColors.primary : AppColors.mutedFg,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Include Medical History Context",
                            style: body(size: 12, weight: FontWeight.w600, color: _includeHistoryToggle ? AppColors.primary : AppColors.mutedFg),
                          ),
                        ],
                      ),
                      Switch(
                        value: _includeHistoryToggle,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) => setState(() => _includeHistoryToggle = val),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!_isTextChatMode) ...[
            // Pulse & Mic Button block (Smoothly collapses on scroll down)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isScrolledDown ? 0 : 160,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isScrolledDown ? 0.0 : 1.0,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _toggleSpeechListening,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          height: 80,
                          width: 80,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_listening)
                                AnimatedBuilder(
                                  animation: _pulse,
                                  builder: (context, child) => Container(
                                    height: 80 * (0.7 + _pulse.value * 0.5),
                                    width: 80 * (0.7 + _pulse.value * 0.5),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withValues(alpha: 0.2 * (1 - _pulse.value)),
                                    ),
                                  ),
                                ),
                              Container(
                                height: 60,
                                width: 60,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x28000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const Icon(Icons.mic_rounded, size: 28, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _listening ? "Listening… tap to stop" : "Tap to speak",
                        style: body(size: 12.5, color: AppColors.mutedFg),
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: _enableTextChatMode,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.primary, width: 1.2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.keyboard_outlined, size: 20, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                "Type instead",
                                style: body(size: 14, weight: FontWeight.w600, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          if (_isTextChatMode || _isScrolledDown) ...[
            // INLINE TEXT CHAT INPUT BAR (REMAINS FLOATING AT BOTTOM WHEN SCROLLING DOWN)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    focusNode: _chatFocusNode,
                    style: body(size: 14.5),
                    onSubmitted: (_) => _sendTypedQuery(),
                    decoration: InputDecoration(
                      hintText: "Type your query or symptoms...",
                      hintStyle: body(size: 13.5, color: AppColors.mutedFg),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendTypedQuery,
                  icon: Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],

          if (_isTextChatMode)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              height: _isScrolledDown ? 0 : 36,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isScrolledDown ? 0.0 : 1.0,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _isTextChatMode = false);
                        FocusScope.of(context).unfocus();
                      },
                      icon: const Icon(Icons.mic_rounded, size: 16, color: AppColors.mutedFg),
                      label: Text("Switch back to voice", style: body(size: 12, color: AppColors.mutedFg)),
                    ),
                  ),
                ),
              ),
            ),


        ],
      ),
    );
  }

  Widget _summary() {
    final result = _aiTriageResult;
    final t = result != null ? tierStyle(result.tier) : tierStyle(1);

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _buildHistoryDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                child: Row(
                  children: [
                    Builder(
                      builder: (scaffoldContext) => IconButton(
                        onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                        icon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Text(
                            "=",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              height: 1.0,
                            ),
                          ),
                        ),
                        tooltip: "Open Chat History Menu",
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ScreenHeader(eyebrow: "DAILY CHECK-IN", title: "Check-in logged"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Text("Today's check-in logged", style: display(size: 18, weight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (var i = 0; i < _answers.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                "• ${_answers[i]}",
                                style: body(size: 13.5, color: AppColors.mutedFg),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (result != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(20)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(t.icon, size: 14, color: t.fg),
                                  const SizedBox(width: 6),
                                  Text(
                                    "AI BACKEND RESPONSE · ${t.short}",
                                    style: body(size: 11.5, weight: FontWeight.w600, color: t.fg),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(result.headline, style: display(size: 19, weight: FontWeight.w600, color: t.fg)),
                            const SizedBox(height: 6),
                            Text(result.rationale, style: body(size: 13.5, color: t.fg).copyWith(height: 1.45)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    PrimaryButton(
                      "Back to check-in",
                      icon: Icons.refresh_rounded,
                      secondary: true,
                      onTap: () => setState(() {
                        _done = false;
                        _isTextChatMode = false;
                        _answers.clear();
                        _aiTriageResult = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
