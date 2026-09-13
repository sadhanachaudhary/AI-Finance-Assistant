import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/formatters.dart';
import '../../analytics/providers/budget_provider.dart';
import '../../expenses/providers/expense_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Widget? customWidget;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.customWidget,
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
    '🔁 Detect recurring subscriptions',
    '🔮 15-day spending forecast',
    '📊 Where am I overspending?',
    '💡 How to save ₹5,000 this month',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: "Hello! I'm your AI Financial Advisor. Ask me anything about your spending, recurring subscriptions, or forecast your budget!",
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

    final totalSpend = ref.read(totalSpendProvider);
    final categoryMap = ref.read(categorySpendMapProvider);
    final expenses = ref.read(expensesProvider).value ?? [];
    final budgetSummary = ref.read(overallBudgetSummaryProvider);

    await Future.delayed(const Duration(milliseconds: 900));

    String aiResponse = '';
    final lower = userMsg.toLowerCase();

    if (lower.contains('recurring') || lower.contains('subscription') || lower.contains('detect')) {
      final subKeywords = ['netflix', 'spotify', 'gym', 'membership', 'icloud', 'prime', 'electricity', 'water', 'sub'];
      final detected = expenses.where((e) {
        final m = (e.merchant ?? '').toLowerCase();
        return subKeywords.any((kw) => m.contains(kw));
      }).toList();

      if (detected.isEmpty) {
        aiResponse = "I scanned your expenses and did not find any recurring subscriptions like Netflix, Spotify, or Gym memberships yet.";
      } else {
        final subTotal = detected.fold<double>(0.0, (s, e) => s + e.amount);
        final annualCost = subTotal * 12;
        final listStr = detected.map((e) => "• **${e.merchant}**: ${Formatters.formatCurrency(e.amount)}/mo").join("\n");

        aiResponse = "💳 **Detected Recurring Subscriptions & Fixed Bills**:\n\n$listStr\n\n💰 **Total Monthly Cost**: ${Formatters.formatCurrency(subTotal)}\n📅 **Projected Annual Cost**: ${Formatters.formatCurrency(annualCost)}\n\n💡 *Tip: Check if you have duplicate streaming services or memberships you rarely use to save ${Formatters.formatCurrency(subTotal * 0.3)}/month.*";
      }
    } else if (lower.contains('forecast') || lower.contains('15-day') || lower.contains('burn')) {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysPassed = now.day > 0 ? now.day : 1;
      final dailyBurn = totalSpend / daysPassed;
      final forecast = dailyBurn * daysInMonth;

      aiResponse = "🔮 **AI 15-Day Spending Forecast**:\n\n• **Current Spent**: ${Formatters.formatCurrency(totalSpend)} (Day $daysPassed of $daysInMonth)\n• **Daily Burn Rate**: ${Formatters.formatCurrency(dailyBurn)}/day\n• **Projected Month-End Spend**: **${Formatters.formatCurrency(forecast)}**\n• **Overall Budget Limit**: ${Formatters.formatCurrency(budgetSummary.totalBudget)}\n\n${forecast > budgetSummary.totalBudget ? '⚠️ You are currently trending **above** your total budget limit. Reducing daily spend to ${Formatters.formatCurrency(budgetSummary.totalBudget / daysInMonth)}/day will keep you on track.' : '✅ Great job! Your spending velocity is within healthy targets.'}";
    } else if (lower.contains('overspending') || lower.contains('where') || lower.contains('category') || lower.contains('biggest')) {
      if (categoryMap.isEmpty) {
        aiResponse = "You haven't logged categorized expenses yet.";
      } else {
        final sorted = categoryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.first;
        final secondStr = sorted.length > 1 ? "Second highest is **${sorted[1].key}** at ${Formatters.formatCurrency(sorted[1].value)}.\n\n" : "";
        aiResponse = "📊 **Spending Hotspot Analysis**:\n\nYour highest expense is **${top.key}** at **${Formatters.formatCurrency(top.value)}** (${((top.value / totalSpend) * 100).toStringAsFixed(1)}% of total).\n\n$secondStr💡 Try setting a stricter category limit on **${top.key}** in your Analytics tab!";
      }
    } else if (lower.contains('save') || lower.contains('5000') || lower.contains('tips')) {
      aiResponse = "💡 **How to Save ₹5,000+ This Month**:\n\n1. **Cut Food Delivery by 50%**: Cooking just 2 more meals a week saves ~₹2,200/mo.\n2. **Review Auto-Debits**: Pause 1 unused entertainment service (~₹649/mo).\n3. **Switch to Weekly Fuel/Cab Caps**: Pre-load a fixed transit budget (~₹1,500/mo savings).\n4. **Smart Grocery Batching**: Use bulk shopping instead of 10-minute micro-orders (~₹800/mo savings).";
    } else {
      aiResponse = "Based on your total spending of ${Formatters.formatCurrency(totalSpend)}, your finances look well-structured! You can ask me to **detect recurring bills**, **forecast end-of-month spend**, or **suggest money saving tips**.";
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
            Text('AI Financial Advisor'),
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
                        Text('AI Advisor is analyzing...', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Quick prompt chips
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
                      color: const Color(0xFF1E1E2C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2C2C3E)),
                    ),
                    child: Text(
                      prompt,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF03DAC6), fontWeight: FontWeight.w500),
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
              color: Color(0xFF14141E),
              border: Border(top: BorderSide(color: Color(0xFF2C2C3E), width: 1)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF2C2C3E)),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        decoration: const InputDecoration(
                          hintText: 'Ask financial question or forecast...',
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
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
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
                color: const Color(0xFF1E1E2C),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: const Color(0xFF2C2C3E)),
              ),
              child: Text(
                msg.text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
