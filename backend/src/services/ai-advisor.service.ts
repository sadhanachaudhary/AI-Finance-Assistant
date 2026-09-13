import prisma from '../config/prisma';

export interface ChatContext {
  userId: string;
  totalSpent: number;
  transactionCount: number;
  categoryBreakdown: Record<string, number>;
  recentExpenses: Array<{
    merchant: string;
    amount: number;
    category: string;
    date: string;
  }>;
  recurringSubs: Array<{
    merchant: string;
    amount: number;
  }>;
}

export class AiAdvisorService {
  /**
   * Builds financial context snapshot for the user.
   */
  static async getUserFinancialContext(userId: string): Promise<ChatContext> {
    const expenses = await prisma.expense.findMany({
      where: { userId },
      include: { category: true },
      orderBy: { date: 'desc' },
    });

    const totalSpent = expenses.reduce((sum, e) => sum + e.amount, 0);
    const categoryBreakdown: Record<string, number> = {};

    for (const exp of expenses) {
      const cat = exp.category?.name || 'Uncategorized';
      categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + exp.amount;
    }

    const recentExpenses = expenses.slice(0, 10).map((e) => ({
      merchant: e.merchant || 'Expense',
      amount: e.amount,
      category: e.category?.name || 'Uncategorized',
      date: e.date.toISOString().split('T')[0],
    }));

    const subKeywords = ['netflix', 'spotify', 'gym', 'membership', 'icloud', 'prime', 'electricity', 'water'];
    const recurringSubs = expenses
      .filter((e) => subKeywords.some((kw) => (e.merchant || '').toLowerCase().includes(kw)))
      .map((e) => ({ merchant: e.merchant || 'Subscription', amount: e.amount }));

    return {
      userId,
      totalSpent,
      transactionCount: expenses.length,
      categoryBreakdown,
      recentExpenses,
      recurringSubs,
    };
  }

  /**
   * Generates intelligent, responsive financial answer based on message and user ledger.
   */
  static async generateAnswer(userMessage: string, history: Array<{ role: string; content: string }>, ctx: ChatContext): Promise<string> {
    const msg = userMessage.toLowerCase().trim();
    const prevAssistantMsg = history.filter((h) => h.role === 'assistant').slice(-1)[0]?.content.toLowerCase() || '';

    // 1. Follow-up handling (e.g. "how to set it", "where", "how do I do that")
    if (msg.includes('how to set') || msg.includes('how do i set') || (msg.includes('how') && prevAssistantMsg.includes('budget limit'))) {
      return (
        "🎯 **How to Set Your Monthly Budget Limit**:\n\n" +
        "1. Tap on the **Budgets** (Analytics) icon in the bottom navigation bar.\n" +
        "2. Scroll down to the **Monthly Budget Limits** section.\n" +
        "3. **Tap on any category** (e.g. *Food & Dining*, *Shopping*, or *Transportation*).\n" +
        "4. Enter your preferred monthly maximum (e.g. ₹5,000) and tap **Save Limit**.\n\n" +
        "The app will automatically calculate your spending progress and turn **Green (Safe)**, **Yellow (Warning)**, or **Red (Over-budget)** in real time!"
      );
    }

    // 2. Dashboard / Overview Request
    if (msg.includes('dashboard') || msg.includes('all my data') || msg.includes('overview') || msg.includes('summary')) {
      const topCategories = Object.entries(ctx.categoryBreakdown)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([name, val]) => `• **${name}**: ₹${val.toLocaleString()}`)
        .join('\n');

      return (
        `📊 **Your Complete Financial Dashboard Overview**:\n\n` +
        `• **Total Expenses**: ₹${ctx.totalSpent.toLocaleString()} across ${ctx.transactionCount} transactions\n` +
        `• **Top Spending Categories**:\n${topCategories || '• No categories recorded yet'}\n` +
        `• **Recent Transactions**:\n${ctx.recentExpenses.slice(0, 3).map((e) => `  - ${e.merchant}: ₹${e.amount} (${e.category})`).join('\n')}\n\n` +
        `💡 You can view full interactive charts on your **Home Dashboard** or the **Budgets & Analytics** tab!`
      );
    }

    // 3. Greetings & Casual chat
    if (/^(hi|hello|hey|good morning|good evening|namaste|hola)\b/i.test(msg)) {
      return (
        `👋 Hello! I am your AI Financial Advisor.\n\n` +
        `You currently have **${ctx.transactionCount} transactions** totaling **₹${ctx.totalSpent.toLocaleString()}**.\n\n` +
        `How can I help you today? You can ask me:\n` +
        `• *"Where am I overspending?"*\n` +
        `• *"Detect my subscriptions"*\n` +
        `• *"How to set category budgets"*\n` +
        `• *"How much did I spend on Food or Uber?"*\n` +
        `• *"Forecast my spending for this month"*`
      );
    }

    // 4. Specific Merchant Query (e.g., "how much on Starbucks/Swiggy/Amazon/Uber/Zara")
    const knownMerchants = ['starbucks', 'swiggy', 'zomato', 'amazon', 'uber', 'netflix', 'zara', 'shell', 'apollo', 'gym'];
    const matchedMerchant = knownMerchants.find((m) => msg.includes(m));

    if (matchedMerchant) {
      const matches = ctx.recentExpenses.filter((e) => e.merchant.toLowerCase().includes(matchedMerchant));
      if (matches.length > 0) {
        const sum = matches.reduce((acc, curr) => acc + curr.amount, 0);
        return (
          `🔍 **Spending on ${matches[0].merchant}**:\n\n` +
          `• Total spent: **₹${sum.toLocaleString()}** across ${matches.length} recent record(s).\n` +
          `• Category: **${matches[0].category}**\n` +
          `• Last recorded on: ${matches[0].date}`
        );
      }
    }

    // 5. Category Query (e.g. "Food", "Shopping", "Travel", "Groceries")
    for (const [catName, catAmount] of Object.entries(ctx.categoryBreakdown)) {
      if (msg.includes(catName.toLowerCase()) || (catName.includes('Food') && msg.includes('dining')) || (catName.includes('Bills') && msg.includes('utility'))) {
        const pct = ctx.totalSpent > 0 ? ((catAmount / ctx.totalSpent) * 100).toFixed(1) : '0';
        return (
          `🏷️ **Category Analysis: ${catName}**\n\n` +
          `• Total spent: **₹${catAmount.toLocaleString()}**\n` +
          `• Share of total budget: **${pct}%**\n` +
          `• Status: ${parseFloat(pct) > 30 ? '⚠️ High spend category. Consider setting a monthly limit.' : '🟢 Within normal proportions.'}`
        );
      }
    }

    // 6. Subscriptions Query
    if (msg.includes('subscription') || msg.includes('recurring') || msg.includes('autopay') || msg.includes('fixed')) {
      if (ctx.recurringSubs.length === 0) {
        return "💳 I haven't detected recurring subscriptions in your recent records. Recurring items like Netflix, Spotify, or Gym memberships will be flagged automatically once logged.";
      }
      const totalMonthly = ctx.recurringSubs.reduce((acc, curr) => acc + curr.amount, 0);
      const list = ctx.recurringSubs.map((s) => `• **${s.merchant}**: ₹${s.amount}/mo`).join('\n');
      return (
        `💳 **Your Active Subscriptions & Recurring Bills**:\n\n` +
        `${list}\n\n` +
        `• Total Monthly Fixed Costs: **₹${totalMonthly.toLocaleString()}**\n` +
        `• Projected Annual Cost: **₹${(totalMonthly * 12).toLocaleString()}**\n\n` +
        `💡 Canceling unused subscriptions is one of the easiest ways to save without impacting your lifestyle!`
      );
    }

    // 7. Forecast Query
    if (msg.includes('forecast') || msg.includes('projection') || msg.includes('burn rate') || msg.includes('end of month')) {
      const now = new Date();
      const currentDay = now.getDate() || 1;
      const daysInMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
      const dailyBurn = ctx.totalSpent / currentDay;
      const projected = dailyBurn * daysInMonth;

      return (
        `🔮 **Monthly Spending Forecast**:\n\n` +
        `• **Current Spend**: ₹${ctx.totalSpent.toLocaleString()} (Day ${currentDay} of ${daysInMonth})\n` +
        `• **Daily Velocity**: ₹${Math.round(dailyBurn).toLocaleString()}/day\n` +
        `• **Projected Month-End Spend**: **₹${Math.round(projected).toLocaleString()}**\n\n` +
        `💡 To keep your spend under ₹${Math.round(projected * 0.85).toLocaleString()}, aim for a daily budget of ₹${Math.round((projected * 0.85) / daysInMonth).toLocaleString()}.`
      );
    }

    // 8. General Savings & Advice Query
    if (msg.includes('save') || msg.includes('budget') || msg.includes('advice') || msg.includes('invest') || msg.includes('emergency')) {
      return (
        `💡 **Smart Financial Strategy Recommendations**:\n\n` +
        `1. **Follow the 50/30/20 Rule**:\n` +
        `   - 50% on Essentials (Rent, Groceries, Utilities)\n` +
        `   - 30% on Discretionary (Dining, Shopping, Entertainment)\n` +
        `   - 20% on Savings & Emergency Fund\n\n` +
        `2. **Target Your High-Spend Areas**:\n` +
        `   - Your top category is currently responsible for significant outlays. Setting a cap in the Budgets tab helps prevent impulse spending.\n\n` +
        `3. **Build a 3-Month Emergency Fund**:\n` +
        `   - Aim to save ₹${Math.round(ctx.totalSpent * 3).toLocaleString()} in a liquid deposit.`
      );
    }

    // 9. Natural conversational fallback (Context-aware and actionable)
    return (
      `I understand you're asking about: "${userMessage}".\n\n` +
      `Based on your current recorded spend of **₹${ctx.totalSpent.toLocaleString()}** across **${ctx.transactionCount} transactions**, I can help you with:\n\n` +
      `• **Setting Budget Limits**: Tap the *Budgets* tab in bottom navigation.\n` +
      `• **Scanning Receipts**: Tap *Scan Bill* on your dashboard.\n` +
      `• **Auto-Tracking Alerts**: Tap *Auto-Track* to parse bank SMS.\n` +
      `• **Expense Breakdown**: Ask me *"Where am I spending most?"* or *"Analyze my groceries"*.\n\n` +
      `Feel free to ask any specific question about your transactions!`
    );
  }
}
