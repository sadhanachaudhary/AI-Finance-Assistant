import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/formatters.dart';
import '../../expenses/providers/expense_provider.dart';

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
    'How much have I spent so far?',
    'Which category is my biggest expense?',
    'Give me 3 tips to save on food & dining',
    'Summarize my financial health',
  ];

  @override
  void initState() {
    super.initState();
    // Initial welcome message
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your AI Financial Advisor. Ask me anything about your spending, budgets, or how to optimize your savings!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

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

  void _sendMessage(String text) async {
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

    // Get current expense context for smart answering
    final totalSpend = ref.read(totalSpendProvider);
    final categoryMap = ref.read(categorySpendMapProvider);
    final expenses = ref.read(expensesProvider).value ?? [];

    await Future.delayed(const Duration(milliseconds: 1200));

    String aiResponse = '';
    final lower = userMsg.toLowerCase();

    if (lower.contains('how much') || lower.contains('spent') || lower.contains('total')) {
      aiResponse = "You have recorded a total expenditure of ${Formatters.formatCurrency(totalSpend)} across ${expenses.length} transactions.";
    } else if (lower.contains('category') || lower.contains('biggest') || lower.contains('top')) {
      if (categoryMap.isEmpty) {
        aiResponse = "You haven't added any categorized expenses yet.";
      } else {
        final sorted = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.first;
        aiResponse = "Your highest spending category is **${top.key}** with ${Formatters.formatCurrency(top.value)} (${((top.value / totalSpend) * 100).toStringAsFixed(1)}% of all expenses).";
      }
    } else if (lower.contains('tip') || lower.contains('save') || lower.contains('food')) {
      aiResponse = "💡 **Top 3 Money Saving Tips**:\n\n1. **Batch Meal Prep**: Plan groceries weekly to cut down on impulse restaurant orders.\n2. **50/30/20 Rule**: Allocate 50% to needs, 30% to wants, and 20% to savings.\n3. **Cancel Idle Subscriptions**: Review monthly auto-debits that you rarely use.";
    } else if (lower.contains('summarize') || lower.contains('health')) {
      aiResponse = "📊 **Financial Health Check**:\n• Total Spend: ${Formatters.formatCurrency(totalSpend)}\n• Active Categories: ${categoryMap.length}\n• Status: Healthy tracking habits! Keep logging daily to identify long-term trends.";
    } else {
      aiResponse = "Based on your current transactions (${Formatters.formatCurrency(totalSpend)} total), I recommend setting a category budget limit to ensure you hit your monthly savings targets.";
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: Color(0xFF03DAC6), size: 22),
            SizedBox(width: 8),
            Text('AI Financial Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Messages View
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF03DAC6)),
                        ),
                        SizedBox(width: 8),
                        Text('AI is thinking...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Suggested prompt chips
          if (_messages.length <= 3)
            Container(
              height: 42,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return InkWell(
                    onTap: () => _sendMessage(prompt),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                      ),
                      child: Text(
                        prompt,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF03DAC6)),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF181818),
              border: Border(top: BorderSide(color: Color(0xFF2C2C2C), width: 1)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C2C2C)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                          hintText: 'Ask financial question...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF03DAC6)],
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_textController.text),
                    ),
                  ),
                ],
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
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8B80F9)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: 10, top: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF03DAC6).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF03DAC6), size: 18),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
