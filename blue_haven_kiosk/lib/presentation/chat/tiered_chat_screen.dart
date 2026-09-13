import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/config/kiosk_config.dart';
import '../../core/interfaces/ai_provider.dart';
import '../../data/local/island_knowledge_base.dart';
import '../call/kiosk_video_call_screen.dart';
import '../providers/kiosk_session_provider.dart';
import '../widgets/kiosk_app_bar.dart';
import '../widgets/whatsapp_qr_dialog.dart';

class TieredChatScreen extends ConsumerStatefulWidget {
  const TieredChatScreen({super.key});

  @override
  ConsumerState<TieredChatScreen> createState() => _TieredChatScreenState();
}

class _TieredChatScreenState extends ConsumerState<TieredChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  final AIProvider _aiProvider = CloudAIProvider();
  bool _isTyping = false;
  bool _isAwaitingHuman = false;
  int _escalationSeconds = 0;
  Timer? _escalationTimer;

  @override
  void initState() {
    super.initState();
    // Welcome message with Quick Questions
    _messages.add({
      'role': 'ai',
      'text': 'Hello! I am your Blue Haven virtual concierge. How can I assist you today? I can answer questions about Wi-Fi, breakfast hours, ferry schedules, surf breaks, check-out, or island rules.',
      'tier': 'Tier 1 Local',
    });
  }

  @override
  void dispose() {
    _escalationTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSendMessage([String? prefilledText]) async {
    final query = prefilledText ?? _textController.text.trim();
    if (query.isEmpty) return;

    if (prefilledText == null) _textController.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isTyping = true;
    });
    Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);

    final cleanQuery = query.toLowerCase();

    // ── Hard Escalation Check: Money, Booking Changes, Complaints, Safety ───
    if (cleanQuery.contains('refund') ||
        cleanQuery.contains('discount') ||
        cleanQuery.contains('money') ||
        cleanQuery.contains('cancel') ||
        cleanQuery.contains('complaint') ||
        cleanQuery.contains('hurt') ||
        cleanQuery.contains('doctor') ||
        cleanQuery.contains('hospital') ||
        cleanQuery.contains('emergency')) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'system',
          'text': 'This matter requires immediate host assistance. Escalating to remote staff...',
          'tier': 'Tier 3 Escalation',
        });
      });
      _startHumanEscalationLadder('Policy / Safety Query');
      return;
    }

    // ── Tier 1: Local Knowledge Base Match (<100ms, 100% offline) ───────────
    final localMatch = IslandKnowledgeBase.searchLocalKB(query);
    if (localMatch != null) {
      await Future.delayed(const Duration(milliseconds: 100)); // Instant on-device
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'role': 'ai',
          'text': localMatch.answer,
          'tier': 'Tier 1 Local KB',
        });
      });
      Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
      return;
    }

    // ── Tier 2: Cloud LLM (Strict Grounding) ────────────────────────────────
    try {
      final aiResponse = await _aiProvider.generateResponse(
        prompt: query,
        knowledgeBaseContext: IslandKnowledgeBase.fullKnowledgeBaseSummary,
      );

      if (!mounted) return;

      if (aiResponse.shouldEscalateToHuman) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'system',
            'text': aiResponse.text,
            'tier': 'Tier 3 Escalation',
          });
        });
        _startHumanEscalationLadder(aiResponse.escalationReason ?? 'Unknown Query');
      } else {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'ai',
            'text': aiResponse.text,
            'tier': 'Tier 2 Cloud AI',
          });
        });
        Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
      }
    } catch (_) {
      // Degrade to escalation
      if (!mounted) return;
      setState(() => _isTyping = false);
      _startHumanEscalationLadder('Offline fallback');
    }
  }

  // ── Escalation Ladder: 0s -> 15s -> 60s -> 90s WhatsApp fallback ─────────
  void _startHumanEscalationLadder(String reason) {
    if (_isAwaitingHuman) return;

    final session = ref.read(kioskSessionNotifierProvider);
    final sessionId = session?.id;

    setState(() {
      _isAwaitingHuman = true;
      _escalationSeconds = 0;
    });

    // 0s: Status awaiting_human + FCM push to staff
    if (sessionId != null) {
      FirebaseFirestore.instance.collection('sessions').doc(sessionId).set({
        'status': 'awaiting_human',
        'escalatedAt': FieldValue.serverTimestamp(),
        'escalationReason': reason,
      }, SetOptions(merge: true));
    }

    _escalationTimer?.cancel();
    _escalationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _escalationSeconds++);

      // 90s: Show WhatsApp QR fallback (The most important behavior in the app)
      if (_escalationSeconds >= KioskConfig.humanChatEscalationSeconds) {
        timer.cancel();
        setState(() {
          _isAwaitingHuman = false;
          _messages.add({
            'role': 'system',
            'text': 'Our on-duty team is currently assisting other guests. We have transitioned this conversation to WhatsApp so you receive our reply on your phone.',
            'tier': 'WhatsApp QR Fallback',
          });
        });
        WhatsAppQRDialog.show(
          context,
          title: 'Continuing on WhatsApp',
          subtitle: 'Our remote team has received your query and will reply directly to your WhatsApp shortly.',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const KioskAppBar(showBackButton: true),
      body: SafeArea(
        child: Column(
          children: [
            if (_isAwaitingHuman) _buildEscalationStatusBar(),
            Expanded(child: _buildChatList()),
            _buildQuickSuggestionChips(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalationStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF476F).withValues(alpha: 0.15),
        border: Border(bottom: BorderSide(color: const Color(0xFFEF476F).withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFEF476F)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _escalationSeconds < 15
                  ? 'Alerting on-duty staff... (${_escalationSeconds}s)'
                  : _escalationSeconds < 60
                      ? 'Waiting for host response. You can also start a live video call.'
                      : 'Connecting to emergency backup phone...',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF476F)),
            ),
          ),
          if (_escalationSeconds >= 15)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KioskVideoCallScreen()),
                );
              },
              icon: const Icon(Icons.video_call, color: Color(0xFF00F0FF)),
              label: const Text('Start Video Call', style: TextStyle(color: Color(0xFF00F0FF), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isTyping) {
          return _buildTypingIndicator();
        }

        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        final isSystem = msg['role'] == 'system';

        return Align(
          alignment: isUser
              ? Alignment.centerRight
              : isSystem
                  ? Alignment.center
                  : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 22.0),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF0077B6)
                  : isSystem
                      ? const Color(0xFF5A1528)
                      : const Color(0xFF0E2238),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUser
                    ? const Color(0xFF00F0FF).withValues(alpha: 0.3)
                    : isSystem
                        ? const Color(0xFFEF476F)
                        : const Color(0xFF1E3A5F),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSystem ? Icons.warning_amber : Icons.auto_awesome,
                        size: 16,
                        color: isSystem ? const Color(0xFFEF476F) : const Color(0xFF00F0FF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        msg['tier'] ?? 'AI Concierge',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSystem ? const Color(0xFFEF476F) : const Color(0xFF00F0FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  msg['text'],
                  style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickSuggestionChips() {
    final chips = [
      '📶 Wi-Fi password',
      '🍳 Breakfast hours',
      '🚤 Ferry to Malé',
      '🔑 Check-out time',
      '🏄 Cokes surf break',
      '👙 Bikini beach rules',
    ];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return ActionChip(
            label: Text(chip, style: const TextStyle(fontSize: 15, color: Colors.white)),
            backgroundColor: const Color(0xFF0E2238),
            side: const BorderSide(color: Color(0xFF1E3A5F)),
            onPressed: () => _handleSendMessage(chip),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0E2238),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('Checking knowledge base...', style: TextStyle(fontSize: 16, color: Colors.white60)),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF071322),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(fontSize: 18, color: Colors.white),
              onSubmitted: (_) => _handleSendMessage(),
              decoration: const InputDecoration(
                hintText: 'Ask about Wi-Fi, breakfast, island rules, ferry...',
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filled(
            onPressed: () => _handleSendMessage(),
            icon: const Icon(Icons.send, color: Colors.black, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
