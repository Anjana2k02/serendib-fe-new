import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage({required this.text, required this.isUser});
}

class AiChatOverlay extends StatefulWidget {
  const AiChatOverlay({super.key});

  @override
  State<AiChatOverlay> createState() => _AiChatOverlayState();
}

class _AiChatOverlayState extends State<AiChatOverlay>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  static const Map<String, String> _responses = {
    'hello':
        'Hello! Welcome to Serendib Guide. I\'m here to help you explore the rich cultural heritage of Sri Lanka. How can I assist you today?',
    'hi':
        'Hi there! I\'m your Serendib Guide assistant. Ask me anything about Sri Lankan heritage, artifacts, or historical sites!',
    'help':
        'I can help you with:\n• Information about historical artifacts\n• Details about heritage sites\n• Cultural traditions of Sri Lanka\n• Navigation within the museum\n• Tour recommendations\n\nJust ask me anything!',
    'artifact':
        'Sri Lanka has a rich collection of artifacts dating back over 2,500 years. From ancient Buddha statues to intricate moonstones, each piece tells a unique story. Would you like to know about a specific artifact?',
    'sigiriya':
        'Sigiriya, the Lion Rock, is a 5th-century rock fortress built by King Kashyapa. It features stunning frescoes, the famous mirror wall, and beautiful water gardens. It\'s a UNESCO World Heritage Site!',
    'kandy':
        'Kandy is the cultural capital of Sri Lanka, home to the sacred Temple of the Tooth Relic. The city is surrounded by mountains and hosts the famous Esala Perahera festival annually.',
    'anuradhapura':
        'Anuradhapura was the first capital of ancient Sri Lanka, established in the 4th century BC. Home to the sacred Bodhi Tree and massive dagobas. A UNESCO World Heritage Site!',
    'polonnaruwa':
        'Polonnaruwa served as the second capital of Sri Lanka (11th–13th century). Famous for Gal Vihara Buddha statues, the Royal Palace, and the Vatadage circular relic house.',
    'coin':
        'Ancient Sri Lankan coins are remarkable artifacts that document the island\'s rich trading history. Look for punch-marked coins and later Sinhalese coins in the collection nearby!',
    'tour':
        'Popular routes include:\n• Cultural Triangle (Anuradhapura, Polonnaruwa, Sigiriya)\n• Hill Country Heritage (Kandy, Nuwara Eliya)\n• Southern Heritage (Galle Fort, Matara)\n\nWhich interests you?',
    'default':
        'That\'s an interesting question! For more detailed information, explore our artifacts gallery or ask me about a specific heritage site. Is there something specific about Sri Lankan culture I can help with?',
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
    _messages.add(const ChatMessage(
      text:
          'Hello! I\'m your Serendib AI guide.\nAsk me about Sri Lankan heritage, artifacts, or the exhibits around you!',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();
    Future.delayed(const Duration(milliseconds: 800), () => _generateResponse(text));
  }

  void _generateResponse(String userMessage) {
    final lower = userMessage.toLowerCase();
    String response = _responses['default']!;
    for (final entry in _responses.entries) {
      if (lower.contains(entry.key)) {
        response = entry.value;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
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
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Expanded chat panel
            SizeTransition(
              sizeFactor: _expandAnim,
              axisAlignment: -1,
              child: _ChatPanel(
                messages: _messages,
                isTyping: _isTyping,
                controller: _controller,
                scrollController: _scrollController,
                onSend: _sendMessage,
              ),
            ),
            const SizedBox(height: 8),
            // FAB toggle button
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBrown,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isExpanded ? Icons.close : Icons.smart_toy,
                    key: ValueKey(_isExpanded),
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final List<ChatMessage> messages;
  final bool isTyping;
  final TextEditingController controller;
  final ScrollController scrollController;
  final VoidCallback onSend;

  const _ChatPanel({
    required this.messages,
    required this.isTyping,
    required this.controller,
    required this.scrollController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 380,
      decoration: BoxDecoration(
        color: AppColors.offWhite,
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryBrown,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusLg),
                topRight: Radius.circular(AppConstants.radiusLg),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Serendib AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Heritage Guide',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(10),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildBubble(messages[index]);
              },
            ),
          ),
          // Input row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.creamWhite,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppConstants.radiusLg),
                bottomRight: Radius.circular(AppConstants.radiusLg),
              ),
              border: Border(
                top: BorderSide(color: AppColors.lightCream, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 13),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: 'Ask about Sri Lankan heritage...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.warmWhite,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onSend,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBrown,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryBrown,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 12),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: msg.isUser ? AppColors.primaryBrown : AppColors.creamWhite,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(msg.isUser ? 12 : 2),
                  bottomRight: Radius.circular(msg.isUser ? 2 : 12),
                ),
                border: msg.isUser
                    ? null
                    : Border.all(color: AppColors.lightCream),
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  color: msg.isUser ? Colors.white : AppColors.textPrimary,
                  fontSize: 12,
                  height: 1.4,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryBrown,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 12),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.creamWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightCream),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TypingDot(delay: 0),
                const SizedBox(width: 4),
                _TypingDot(delay: 200),
                const SizedBox(width: 4),
                _TypingDot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryBrown.withValues(alpha: _anim.value),
        ),
      ),
    );
  }
}
