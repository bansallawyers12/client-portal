import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/theme_config.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../book_appointment/book_location_screen.dart';

class ClaudeChatBotScreen extends StatefulWidget {
  const ClaudeChatBotScreen({super.key});

  @override
  State<ClaudeChatBotScreen> createState() => _ClaudeChatBotScreenState();
}

class _ClaudeChatBotScreenState extends State<ClaudeChatBotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _composerFocusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();

  final List<_Message> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  // Quick-reply suggestions shown before first user message
  bool _showQuickReplies = true;
  final List<_QuickReply> _quickReplies = const [
    _QuickReply(
      icon: Icons.flight_takeoff_rounded,
      label: 'Visa options',
      message: 'What visa options are available for me?',
    ),
    _QuickReply(
      icon: Icons.description_outlined,
      label: 'Documents needed',
      message: 'What documents do I need for my application?',
    ),
    _QuickReply(
      icon: Icons.schedule_rounded,
      label: 'Processing time',
      message: 'How long does the immigration process take?',
    ),
    _QuickReply(
      icon: Icons.calendar_month_rounded,
      label: 'Book consultation',
      message: 'How can I book a consultation appointment?',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _addBotMessage(
      "Hello! 👋 I'm your Bansal Immigration assistant. Send links, emails or phone numbers 😉",
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _composerFocusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(_Message(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;
    // Hide quick replies once user sends any message
    if (_showQuickReplies) setState(() => _showQuickReplies = false);

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    setState(() {
      _messages.add(_Message(text: text.trim(), isUser: true));
      _isLoading = true;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.sendChatBotMessage(text.trim());

      String reply;

      if (response['success'] == true) {
        final data = response['data'];
        final directReply =
            data is Map ? data['reply']?.toString().trim() : null;
        if (directReply != null && directReply.isNotEmpty) {
          reply = directReply;
        } else if (data is Map) {
          reply = data['content']?[0]?['text']?.toString() ??
              'No response received.';
        } else {
          reply = 'No response received.';
        }
      } else {
        reply = response['message'] ?? 'Something went wrong.';
      }

      // Detect booking intent — strip website URL and flag for in-app button
      final bool hasBookingIntent = _containsBookingIntent(reply);
      if (hasBookingIntent) {
        // Remove the website booking URL from the reply
        reply = reply
            .replaceAll(
              RegExp(
                r'https?://www\.bansalimmigration\.com\.au/book[^\s]*',
                caseSensitive: false,
              ),
              '',
            )
            .replaceAll(RegExp(r'\s{2,}'), ' ')
            .trim();
      }

      setState(() {
        _isLoading = false;
        _messages.add(
          _Message(
            text: reply,
            isUser: false,
            showBookingButton: hasBookingIntent,
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          const _Message(
            text: 'Network error. Please try again.',
            isUser: false,
          ),
        );
      });
      _scrollToBottom();
    }
  }

  bool _containsBookingIntent(String text) {
    final lower = text.toLowerCase();
    return lower.contains('bansalimmigration.com.au/book') ||
        lower.contains('book directly') ||
        lower.contains('book a consultation') ||
        lower.contains('book an appointment') ||
        lower.contains('book a free consultation') ||
        lower.contains('schedule a consultation') ||
        lower.contains('schedule an appointment') ||
        lower.contains('book online');
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable || _isLoading) {
      if (!_speechAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice input is not available on this device.')),
        );
      }
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _textController.text = result.recognizedWords;
          _textController.selection = TextSelection.fromPosition(
            TextPosition(offset: _textController.text.length),
          );
        });
        if (result.finalResult) {
          _speech.stop();
          setState(() => _isListening = false);
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildTextComposer() {
    final hasText = _textController.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10 + MediaQuery.of(context).padding.bottom * 0.25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      _isListening
                          ? ThemeConfig.goldenYellow.withValues(alpha: 0.6)
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _composerFocusNode,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: _isLoading ? null : _sendMessage,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none_rounded,
                      color:
                          _isListening
                              ? ThemeConfig.errorColor
                              : Colors.grey.shade600,
                    ),
                    onPressed: _isLoading ? null : _toggleListening,
                    tooltip: _isListening ? 'Stop listening' : 'Voice input',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color:
                hasText && !_isLoading
                    ? ThemeConfig.goldenYellow
                    : Colors.grey.shade300,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap:
                  hasText && !_isLoading
                      ? () => _sendMessage(_textController.text)
                      : null,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.send_rounded,
                  color: hasText && !_isLoading ? Colors.white : Colors.grey,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 14, height: 14, child: AppLoader(size: 20)),
                SizedBox(width: 8),
                Text(
                  'Assistant is typing...',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.navyBlue.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 14,
                    decoration: BoxDecoration(
                      color: ThemeConfig.goldenYellow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Suggestions',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ThemeConfig.navyBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final reply in _quickReplies)
                    _SuggestionChip(
                      icon: reply.icon,
                      label: reply.label,
                      onTap:
                          _isLoading
                              ? null
                              : () => _sendMessage(reply.message),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton.icon(
                  onPressed: _isLoading ? null : _openCustomQuery,
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeConfig.navyBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: ThemeConfig.goldenYellow.withValues(alpha: 0.95),
                  ),
                  label: const Text(
                    'Ask something else',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCustomQuery() {
    setState(() => _showQuickReplies = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _composerFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: ThemeConfig.goldenYellow,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: ThemeConfig.goldenYellow.withValues(alpha: 0.35),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
        ),
        title: const Text('Chatbot'),
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoading && index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[index];
                      if (!msg.isUser && msg.showBookingButton) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            msg,
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 42,
                                bottom: 10,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const BookLocationScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 18,
                                ),
                                label: const Text('Book Consultation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F3C88),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return msg;
                    },
                  ),
                ),
                // Quick-reply chips — visible only before first user message
                if (_showQuickReplies) _buildQuickReplies(),
                // Chat input — hidden until user taps a quick question
                if (!_showQuickReplies) _buildTextComposer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool showBookingButton;

  const _Message({
    required this.text,
    required this.isUser,
    this.showBookingButton = false,
  });

  Future<void> _handleTap(String value) async {
    Uri uri;

    if (value.startsWith('http')) {
      uri = Uri.parse(value);
    } else if (value.contains('@')) {
      uri = Uri.parse('mailto:$value');
    } else {
      uri = Uri.parse('tel:$value');
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildRichText() {
    final RegExp regExp = RegExp(
      r'((https?:\/\/[^\s]+)|(\+?\d{7,})|([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}))',
    );

    final matches = regExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isUser ? Colors.white : const Color(0xFF1F2937),
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    final spans = <TextSpan>[];
    int start = 0;

    for (final match in matches) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: TextStyle(
              color: isUser ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
        );
      }

      final matchText = match.group(0)!;

      spans.add(
        TextSpan(
          text: matchText,
          style: TextStyle(
            color: isUser ? Colors.white70 : const Color(0xFF2563EB),
            decoration: TextDecoration.underline,
          ),
          recognizer:
              TapGestureRecognizer()..onTap = () => _handleTap(matchText),
        ),
      );

      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      );
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: const TextStyle(fontSize: 15, height: 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(18);

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Copied')));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: ThemeConfig.goldenYellow,
                child: const Icon(
                  Icons.support_agent_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser ? ThemeConfig.goldenYellow : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: radius,
                    topRight: radius,
                    bottomLeft: isUser ? radius : Radius.zero,
                    bottomRight: isUser ? Radius.zero : radius,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildRichText(),
              ),
            ),
            if (isUser) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class _QuickReply {
  final IconData icon;
  final String label;
  final String message;

  const _QuickReply({
    required this.icon,
    required this.label,
    required this.message,
  });
}

class _SuggestionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SuggestionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F6FB),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: ThemeConfig.navyBlue),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ThemeConfig.navyBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
