import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';
import 'package:skillforge_student/core/theme/app_theme.dart';

/// AI Tutor Screen — uses the backend AiController session-based flow:
///   1. POST /api/v1/ai/sessions         → creates/gets sessionId
///   2. POST /api/v1/ai/sessions/{id}/messages  { question } → gets answer
///   3. GET  /api/v1/ai/sessions/{id}/history   → full history
class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  static const _storage = FlutterSecureStorage();

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Message> _messages = [];
  bool _sending = false;
  bool _initializingSession = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _messages.add(const _Message(
      text: "Hi! 👋 I'm your AI Tutor. Ask me anything about your courses, programming, or career growth!",
      isUser: false,
    ));
    _initSession();
  }

  /// Step 1 — Create or restore AI session
  Future<void> _initSession() async {
    // Try to restore existing session from secure storage
    final stored = await _storage.read(key: AppConstants.aiSessionIdKey);
    if (stored != null) {
      setState(() => _sessionId = stored);
      return;
    }

    // Create new session
    setState(() => _initializingSession = true);
    try {
      final resp = await ApiClient.post(AppConstants.aiSessionsUrl, {});
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final id = body['data']?['sessionId']?.toString() ??
            body['data']?['id']?.toString();
        if (id != null) {
          await _storage.write(key: AppConstants.aiSessionIdKey, value: id);
          if (mounted) setState(() => _sessionId = id);
        }
      }
    } catch (_) {
      // Silently fail — message will show error when sending
    }
    if (mounted) setState(() => _initializingSession = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Step 2 — Send message to session
  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_Message(text: text, isUser: true));
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    // If no session yet, try creating one inline
    if (_sessionId == null) {
      await _initSession();
    }

    if (_sessionId == null) {
      if (mounted) {
        setState(() {
          _messages.add(const _Message(
              text: 'Could not connect to AI Tutor. Please try again.',
              isUser: false));
          _sending = false;
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      // POST /api/v1/ai/sessions/{sessionId}/messages
      final url = '${AppConstants.aiSessionsUrl}/$_sessionId/messages';
      final resp = await ApiClient.post(url, {'question': text});

      String reply;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        reply = body['data']?['answer']?.toString() ??
            body['data']?['content']?.toString() ??
            'I processed your question. Could you add more detail?';
      } else if (resp.statusCode == 404) {
        // Session expired — clear and re-create
        await _storage.delete(key: AppConstants.aiSessionIdKey);
        _sessionId = null;
        reply = 'Session expired. Please send your message again.';
      } else {
        reply = 'Something went wrong. Please try again.';
      }

      if (mounted) {
        setState(() {
          _messages.add(_Message(text: reply, isUser: false));
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add(const _Message(
              text: 'You are offline. Please check your connection.',
              isUser: false));
          _sending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgMain,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: AppTheme.sp8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Tutor',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textHeading)),
                Text(
                  _initializingSession
                      ? 'Starting session...'
                      : _sessionId != null
                          ? 'Session active'
                          : 'Ready to help',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _initializingSession
                          ? AppTheme.warning
                          : AppTheme.success),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppTheme.sp16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (_, i) {
                if (_sending && i == _messages.length) {
                  return const _TypingBubble();
                }
                return _Bubble(message: _messages[i]);
              },
            ),
          ),
          // Input bar
          Container(
            color: AppTheme.bgMain,
            padding: const EdgeInsets.fromLTRB(AppTheme.sp16,
                AppTheme.sp8, AppTheme.sp16, AppTheme.sp16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 4, minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Ask anything...',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: AppTheme.sp8),
                InkWell(
                  onTap: _send,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                    ),
                    child: _sending
                        ? const Center(
                            child: SizedBox(width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  const _Message({required this.text, required this.isUser});
}

class _Bubble extends StatelessWidget {
  final _Message message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp8),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: AppTheme.primary, size: 16),
            ),
            const SizedBox(width: AppTheme.sp8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.sp16, vertical: AppTheme.sp8),
              decoration: BoxDecoration(
                color: message.isUser ? AppTheme.primary : AppTheme.bgMain,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser
                    ? null
                    : Border.all(color: AppTheme.divider),
              ),
              child: Text(
                message.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: message.isUser ? Colors.white : AppTheme.textBody),
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: AppTheme.sp8),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp8),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppTheme.primary, size: 16),
          ),
          const SizedBox(width: AppTheme.sp8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp16, vertical: AppTheme.sp8),
            decoration: BoxDecoration(
              color: AppTheme.bgMain,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Text('Thinking...',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
