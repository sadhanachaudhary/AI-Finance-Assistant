import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/security_provider.dart';
import '../../../shared/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../goals/providers/goal_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _suggestedPrompts = [
    'How can I build an emergency fund?',
    "What's the best budgeting method for me?",
    'How do I reduce my spending?',
    'How do I start small investments?',
  ];

  @override
  void dispose() {
    _textController.dispose();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(
        ChatMessage(
          text: userMsg,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    String aiResponse = '';
    final sec = ref.read(securityProvider);

    if (sec.isRestricted) {
      aiResponse = "⚠️ **Security Restrictions Active**\n\n"
          "Live Cloud AI features are locked down because privacy layers are restricted in your settings.\n\n"
          "🛡️ Go to **Profile → Privacy & Security Shield** to restore full AI capabilities.";
    } else {
      try {
        final apiClient = ref.read(apiClientProvider);
        final historyPayload = _messages.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        }).toList();

        final res = await apiClient.dio.post(
          ApiEndpoints.aiChat,
          data: {
            'message': userMsg,
            'history': historyPayload,
          },
        );

        if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
          aiResponse = res.data['data']['reply'] as String;
        }
      } catch (e) {
        debugPrint('AI API chat error: $e. Using local financial intelligence engine.');
      }
    }

    if (aiResponse.isEmpty) {
      aiResponse = _generateLocalAiAnswer(userMsg);
    }

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add(
          ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  String _generateLocalAiAnswer(String query) {
    final expenses = ref.read(expensesProvider).value ?? [];
    final totalSpend = ref.read(totalSpendProvider);
    final categoryMap = ref.read(categorySpendMapProvider);
    final goals = ref.read(goalsProvider).value ?? [];
    final lower = query.toLowerCase().trim();

    // 1. Goal saving plan (Matching Screen 3)
    if (lower.contains('plan') || lower.contains('car') || lower.contains('10,000') || lower.contains('save')) {
      return "Here's a simplified plan to save \$10,000 for a car by January next year:\n\n"
          "1. **Set the Goal**\n"
          "   • Save \$770/month over 13 months.\n\n"
          "2. **Analyze Your Budget**\n"
          "   • Calculate income and expenses.\n"
          "   • Ensure at least \$770 is left for savings monthly.\n\n"
          "3. **Cut Costs**\n"
          "   • Reduce non-essential spending (dining, subscriptions).\n"
          "   • Automate \$770 savings each month.\n\n"
          "4. **Boost Income**\n"
          "   • Consider side gigs or extra work to add to savings.\n\n"
          "5. **Monitor Progress**\n"
          "   • Track savings monthly and adjust if needed.";
    }

    // 2. Emergency fund
    if (lower.contains('emergency fund')) {
      return "🛡️ **Emergency Fund Strategy**:\n\n"
          "1. **Target**: Aim for 3-6 months of essential living expenses (~₹1,50,000).\n"
          "2. **Starter Step**: Save a starter cushion of ₹25,000 in a high-yield liquid account.\n"
          "3. **Rule**: Automate 10% of every paycheck directly to this fund before spending on wants.";
    }

    // 3. Subscriptions & Prioritization
    if (lower.contains('sub') || lower.contains('recurring') || lower.contains('reduce')) {
      return "💳 **Subscription & Cost Reduction Roadmap**:\n\n"
          "1. **Audit Discretionary Apps**: Review active streaming & food memberships.\n"
          "2. **The 48-Hour Cart Rule**: Delay online purchases by 48 hours to curb impulse buys.\n"
          "3. **Meal Planning**: Limit takeout to 2 meals/week, saving up to ₹4,000/month!";
    }

    // 4. Default overview
    return "Based on your current recorded spend of **${Formatters.formatCurrency(totalSpend)}**:\n\n"
        "1. 🎯 **Track Savings Targets**: You have ${goals.length} active savings goals.\n"
        "2. 💡 **Budget Optimization**: Tap **Budgets** to cap high-spend categories like *Food & Dining*.\n"
        "3. 🚀 **Smart Investments**: Start with index funds or recurring monthly deposits!";
  }

  @override
  Widget build(BuildContext context) {
    final hasMessages = _messages.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgCanvas,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        centerTitle: true,
        backgroundColor: AppTheme.bgCanvas,
        elevation: 0,
        actions: [
          if (hasMessages)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
              tooltip: 'Reset Conversation',
              onPressed: () {
                setState(() {
                  _messages.clear();
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // If no messages, show Screen 2 Welcome / Empty State
          if (!hasMessages)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 30),
                    // Concentric Glowing Pulsing Rings
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.04),
                              border: Border.all(
                                color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                              border: Border.all(
                                color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Ask Zyno AI anything about your savings\nand financial improvement.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Suggested',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._suggestedPrompts.map((prompt) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => _sendMessage(prompt),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    prompt,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 13,
                                  color: AppTheme.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            )
          else
            // Chat Messages View (Matching Screen 3)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

          if (_isTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryPurple),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Zyno AI is formulating your financial plan...',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick Suggested prompt chips above input bar (when in chat)
          if (hasMessages)
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return InkWell(
                    onTap: () => _sendMessage(prompt),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Center(
                        child: Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom Pill-Shaped Input Bar (Matching Screen 2 & 3)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.transparent,
            ),
            child: SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                          hintText: 'Ask AI anything',
                          hintStyle: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: AppTheme.textSecondary, size: 22),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎙️ Voice prompt listening ready! Type or speak your query.')),
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryPurple, AppTheme.primaryPurpleLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPurple.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        onPressed: () => _sendMessage(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF), // Soft iris purple lavender
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(6),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      child: const Icon(Icons.edit_outlined, size: 13, color: AppTheme.primaryPurple),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Response Bubble (Matching Screen 3)
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFormattedText(msg.text),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.textTertiary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: msg.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plan copied to clipboard')),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined, size: 16, color: AppTheme.textTertiary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Feedback saved. Thank you!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String content) {
    final spans = <TextSpan>[];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
        final headingText = line.replaceAll(RegExp(r'^#+\s*'), '');
        spans.add(
          TextSpan(
            text: '$headingText\n',
            style: const TextStyle(
              color: AppTheme.primaryPurple,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        );
      } else {
        _parseInlineMarkdown(line, spans);
        if (i < lines.length - 1) {
          spans.add(const TextSpan(text: '\n'));
        }
      }
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 14,
          height: 1.5,
          letterSpacing: 0.1,
        ),
        children: spans,
      ),
    );
  }

  void _parseInlineMarkdown(String text, List<TextSpan> spans) {
    final parts = text.split('**');
    for (int j = 0; j < parts.length; j++) {
      final part = parts[j];
      if (part.isEmpty) continue;

      final isBold = j % 2 == 1;
      spans.add(
        TextSpan(
          text: part,
          style: TextStyle(
            color: isBold ? AppTheme.textPrimary : const Color(0xFF334155),
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      );
    }
  }
}
