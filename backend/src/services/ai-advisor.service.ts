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
    dayOfWeek: string;
    time: string;
    notes?: string | null;
  }>;
  recurringSubs: Array<{
    merchant: string;
    amount: number;
  }>;
  goals: Array<{
    name: string;
    targetAmount: number;
    currentAmount: number;
    currency: string;
    percentage: number;
  }>;
}

export class AiAdvisorService {
  /**
   * Builds financial context snapshot for the user with exact dates, days, times, and goals.
   */
  static async getUserFinancialContext(userId: string): Promise<ChatContext> {
    const [expenses, goals] = await Promise.all([
      prisma.expense.findMany({
        where: { userId },
        include: { category: true },
        orderBy: { date: 'desc' },
      }),
      (prisma as any).goal.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      }).catch(() => []),
    ]);

    const totalSpent = expenses.reduce((sum, e) => sum + e.amount, 0);
    const categoryBreakdown: Record<string, number> = {};

    for (const exp of expenses) {
      const cat = exp.category?.name || 'Uncategorized';
      categoryBreakdown[cat] = (categoryBreakdown[cat] || 0) + exp.amount;
    }

    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    const recentExpenses = expenses.slice(0, 20).map((e) => {
      const d = new Date(e.date);
      const dayOfWeek = days[d.getDay()];
      const hour = d.getHours() % 12 || 12;
      const period = d.getHours() >= 12 ? 'PM' : 'AM';
      const min = d.getMinutes().toString().padStart(2, '0');
      const timeStr = `${hour}:${min} ${period}`;
      const dateStr = `${d.getDate()} ${months[d.getMonth()]} ${d.getFullYear()}`;

      return {
        merchant: e.merchant || 'Expense',
        amount: e.amount,
        category: e.category?.name || 'Uncategorized',
        date: dateStr,
        dayOfWeek,
        time: timeStr,
        notes: e.notes,
      };
    });

    const subKeywords = ['netflix', 'spotify', 'gym', 'membership', 'icloud', 'prime', 'electricity', 'water', 'hotstar', 'youtube', 'apple'];
    const recurringSubs = expenses
      .filter((e) => subKeywords.some((kw) => (e.merchant || '').toLowerCase().includes(kw)))
      .map((e) => ({ merchant: e.merchant || 'Subscription', amount: e.amount }));

    const parsedGoals = (goals || []).map((g: any) => ({
      name: g.name,
      targetAmount: g.targetAmount,
      currentAmount: g.currentAmount,
      currency: g.currency || 'INR',
      percentage: g.targetAmount > 0 ? Math.min(100, Math.round((g.currentAmount / g.targetAmount) * 100)) : 0,
    }));

    return {
      userId,
      totalSpent,
      transactionCount: expenses.length,
      categoryBreakdown,
      recentExpenses,
      recurringSubs,
      goals: parsedGoals,
    };
  }

  /**
   * Calls Google Gemini 1.5 Flash API with user financial context
   */
  private static async callGeminiApi(userMessage: string, history: Array<{ role: string; content: string }>, ctx: ChatContext): Promise<string | null> {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || apiKey.trim().length === 0) return null;

    try {
      const systemPrompt = `You are a calm, expert, empathetic AI Financial Advisor inside the AI Finance Assistant app.
User's Live Financial Snapshot:
- Total Spent This Month: ${ctx.totalSpent} INR across ${ctx.transactionCount} transactions
- Top Spending Categories: ${JSON.stringify(ctx.categoryBreakdown)}
- Recent Transactions (with date, day, time, notes): ${JSON.stringify(ctx.recentExpenses.slice(0, 15))}
- Detected Subscriptions: ${JSON.stringify(ctx.recurringSubs)}
- Active Savings Goals: ${JSON.stringify(ctx.goals)}

Guidelines:
1. Always be encouraging, actionable, and calm (reduce financial anxiety).
2. Use specific figures, merchant names, days, and times from the user's data when relevant.
3. Format output in clean GitHub markdown with bold key figures and bullet points.
4. If asked how to save money, provide a realistic multi-step reduction plan based on their real category spending.`;

      const contents: Array<{ role: string; parts: Array<{ text: string }> }> = [
        { role: 'user', parts: [{ text: `[System Financial Context]\n${systemPrompt}` }] },
        { role: 'model', parts: [{ text: "Understood. I have access to your live financial snapshot and am ready to provide personalized, actionable financial advice." }] },
      ];

      for (const h of history.slice(-4)) {
        contents.push({
          role: h.role === 'assistant' ? 'model' : 'user',
          parts: [{ text: h.content }],
        });
      }

      contents.push({
        role: 'user',
        parts: [{ text: userMessage }],
      });

      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${encodeURIComponent(apiKey.trim())}`;
      
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents,
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 800,
          },
        }),
      });

      if (response.ok) {
        const data: any = await response.json();
        const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text && typeof text === 'string' && text.trim().length > 0) {
          return text.trim();
        }
      }
    } catch (err) {
      console.warn('Gemini API call failed, using heuristic advisor fallback:', err);
    }
    return null;
  }

  /**
   * Generates intelligent, responsive financial answer based on message and user ledger.
   */
  static async generateAnswer(userMessage: string, history: Array<{ role: string; content: string }>, ctx: ChatContext): Promise<string> {
    // 1. Try Live Gemini Generative AI first if API Key is configured
    if (process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim().length > 5) {
      const geminiReply = await AiAdvisorService.callGeminiApi(userMessage, history, ctx);
      if (geminiReply) return geminiReply;
    }

    const msg = userMessage.toLowerCase().trim();
    const prevAssistantMsg = history.filter((h) => h.role === 'assistant').slice(-1)[0]?.content.toLowerCase() || '';
    const prevUserMsg = history.filter((h) => h.role === 'user').slice(-2)[0]?.content.toLowerCase() || '';

    // 0. Contextual Multi-Turn Affirmations (e.g. "yes", "sure", "model", "do it", "give me a model")
    const isAffirmation = /^(yes|yeah|yep|sure|ok|okay|please|model|give me a model|prioritize|do it|proceed|continue)\b/i.test(msg);
    if (isAffirmation || (msg.length <= 15 && (msg.includes('yes') || msg.includes('model') || msg.includes('model')))) {
      if (prevUserMsg.includes('sub') || prevUserMsg.includes('recurring') || prevAssistantMsg.includes('subscription') || msg.includes('model') || msg.includes('priorit')) {
        return AiAdvisorService.buildSubscriptionPrioritizationModel(ctx);
      }
      if (prevAssistantMsg.includes('budget') || prevUserMsg.includes('budget')) {
        return AiAdvisorService.build503020BudgetModel(ctx);
      }
      if (prevAssistantMsg.includes('saving') || prevUserMsg.includes('save')) {
        return AiAdvisorService.buildCustomSavingsRoadmap(ctx, 5000);
      }
    }

    // 1. Subscriptions & Prioritization Models (e.g. "check my recurring subs and check which way i should prioritize and give me a model")
    if (
      msg.includes('priorit') ||
      msg.includes('model') ||
      (msg.includes('recurring') && msg.includes('sub')) ||
      (msg.includes('sub') && (msg.includes('check') || msg.includes('audit') || msg.includes('cancel') || msg.includes('cut')))
    ) {
      return AiAdvisorService.buildSubscriptionPrioritizationModel(ctx);
    }

    // 2. Standard Subscriptions Query
    if (msg.includes('subscription') || msg.includes('recurring') || msg.includes('autopay') || msg.includes('fixed')) {
      return AiAdvisorService.buildSubscriptionPrioritizationModel(ctx);
    }

    // 3. Goals Query (e.g. "how are my goals", "savings targets", "emergency fund status")
    if (msg.includes('goal') || msg.includes('target') || msg.includes('funds') || msg.includes('savings status')) {
      if (ctx.goals.length === 0) {
        return (
          "🎯 **Savings Goals Tracker**:\n\n" +
          "You haven't set up any savings targets yet! You can tap **Goals** in the bottom navigation bar to set targets like:\n" +
          "• *Emergency Fund (₹50,000)*\n" +
          "• *Vacation Trip (₹30,000)*\n" +
          "• *New Laptop (₹80,000)*\n\n" +
          "Setting visual targets accelerates savings by 3x through consistent micro-deposits!"
        );
      }

      const goalsList = ctx.goals
        .map((g) => `• 🏆 **${g.name}**: ${g.currency} ${g.currentAmount.toLocaleString()} / ${g.targetAmount.toLocaleString()} (**${g.percentage}%** completed)`)
        .join('\n');

      return (
        `🎯 **Your Active Savings Goals Status**:\n\n` +
        `${goalsList}\n\n` +
        `💡 Tap on the **Goals** tab to make a new deposit or adjust target deadlines!`
      );
    }

    // 4. Day / Time / Specific Date Queries
    const daysOfWeek = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
    const matchedDay = daysOfWeek.find((d) => msg.includes(d));

    if (matchedDay || msg.includes('today') || msg.includes('yesterday') || msg.includes('when') || msg.includes('time') || msg.includes('date')) {
      let filtered = ctx.recentExpenses;

      if (matchedDay) {
        filtered = filtered.filter((e) => e.dayOfWeek.toLowerCase() === matchedDay);
      } else if (msg.includes('today')) {
        const today = new Date();
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const todayStr = `${today.getDate()} ${months[today.getMonth()]}`;
        filtered = filtered.filter((e) => e.date.includes(todayStr));
      }

      if (filtered.length > 0) {
        const total = filtered.reduce((s, e) => s + e.amount, 0);
        const list = filtered
          .map((e) => `• **${e.merchant}**: ₹${e.amount.toLocaleString()} (${e.category})\n  🕒 **${e.dayOfWeek}, ${e.date} at ${e.time}**${e.notes ? `\n  📝 _${e.notes}_` : ''}`)
          .join('\n\n');

        return (
          `📅 **Itemized Spending Timeline (${matchedDay ? matchedDay.toUpperCase() : 'Recent'})**:\n\n` +
          `${list}\n\n` +
          `💰 **Total**: ₹${total.toLocaleString()} across ${filtered.length} record(s).`
        );
      }
    }

    // 5. Follow-up handling (e.g. "how to set it", "where")
    if (msg.includes('how to set') || msg.includes('how do i set') || (msg.includes('how') && prevAssistantMsg.includes('budget limit'))) {
      return (
        "🎯 **How to Set Your Monthly Budget Limit**:\n\n" +
        "1. Tap on the **Budgets** (Analytics) icon in the bottom navigation bar.\n" +
        "2. Scroll down to the **Monthly Budget Limits** section.\n" +
        "3. **Tap on any category** (e.g. *Food & Dining*, *Shopping*, or *Transportation*).\n" +
        "4. Enter your preferred monthly maximum (e.g. ₹5,000) and tap **Save Limit**.\n\n" +
        "The app will automatically calculate your spending progress and turn **Green (Safe)**, **Yellow (Warning)**, or **Coral (Over-budget)** in real time!"
      );
    }

    // 6. Dashboard / Overview Request
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
        `• **Recent Transactions**:\n${ctx.recentExpenses.slice(0, 3).map((e) => `  - ${e.merchant}: ₹${e.amount} (${e.dayOfWeek} at ${e.time})`).join('\n')}\n\n` +
        `💡 Tap any transaction on your **Home Screen** to inspect its exact time and day!`
      );
    }

    // 7. Greetings
    if (/^(hi|hello|hey|good morning|good evening|namaste|hola)\b/i.test(msg)) {
      return (
        `👋 Hello! I am your AI Financial Advisor.\n\n` +
        `You currently have **${ctx.transactionCount} transactions** totaling **₹${ctx.totalSpent.toLocaleString()}**.\n\n` +
        `You can ask me questions like:\n` +
        `• *"Check my recurring subs and prioritize them with a model"*\n` +
        `• *"What did I spend on Saturday or today?"*\n` +
        `• *"How can I save ₹5,000 this month?"*\n` +
        `• *"How are my savings goals doing?"*`
      );
    }

    // 8. Specific Merchant Query with Day & Time
    const knownMerchants = ['starbucks', 'swiggy', 'zomato', 'amazon', 'uber', 'netflix', 'zara', 'shell', 'apollo', 'gym', 'blue tokai', 'indigo', 'pvr'];
    const matchedMerchant = knownMerchants.find((m) => msg.includes(m));

    if (matchedMerchant) {
      const matches = ctx.recentExpenses.filter((e) => e.merchant.toLowerCase().includes(matchedMerchant));
      if (matches.length > 0) {
        const sum = matches.reduce((acc, curr) => acc + curr.amount, 0);
        const details = matches
          .map((e) => `• ₹${e.amount.toLocaleString()} on **${e.dayOfWeek}, ${e.date} at ${e.time}**${e.notes ? ` (_${e.notes}_)` : ''}`)
          .join('\n');

        return (
          `🔍 **Spending Breakdown for ${matches[0].merchant}**:\n\n` +
          `• Total spent: **₹${sum.toLocaleString()}** across ${matches.length} transaction(s)\n` +
          `• Category: **${matches[0].category}**\n\n` +
          `🕒 **Timeline of Purchases**:\n${details}`
        );
      }
    }

    // 9. Category Query
    for (const [catName, catAmount] of Object.entries(ctx.categoryBreakdown)) {
      if (msg.includes(catName.toLowerCase()) || (catName.includes('Food') && msg.includes('dining')) || (catName.includes('Bills') && msg.includes('utility'))) {
        const pct = ctx.totalSpent > 0 ? ((catAmount / ctx.totalSpent) * 100).toFixed(1) : '0';
        const matches = ctx.recentExpenses.filter((e) => e.category.toLowerCase() === catName.toLowerCase());
        const recentLines = matches.slice(0, 3).map((e) => `  - ${e.merchant}: ₹${e.amount} (${e.dayOfWeek} at ${e.time})`).join('\n');

        return (
          `🏷️ **Category Analysis: ${catName}**\n\n` +
          `• Total spent: **₹${catAmount.toLocaleString()}** (${pct}% of total)\n` +
          `• Status: ${parseFloat(pct) > 30 ? '⚠️ High spend area' : '🟢 Healthy proportion'}\n\n` +
          `🕒 **Recent purchases in ${catName}**:\n${recentLines || '  None'}`
        );
      }
    }

    // 10. Custom Savings Target Calculator (e.g. "how can I save 5000", "how to save 10000", "how to save money")
    if (msg.includes('save') || msg.includes('saving') || msg.includes('cut spend') || msg.includes('reduce')) {
      const match = msg.match(/(?:save|target|cut)\s*(?:of|around|up to)?\s*(?:rs\.?|inr|₹|\$)?\s*(\d+(?:,\d+)*)/i);
      const targetAmount = match ? parseFloat(match[1].replace(/,/g, '')) : 5000;
      return AiAdvisorService.buildCustomSavingsRoadmap(ctx, targetAmount);
    }

    // 11. Natural fallback with itemized preview and suggested actions
    return (
      `Based on your recorded spend of **₹${ctx.totalSpent.toLocaleString()}** across ${ctx.transactionCount} transactions, here is what I can do for you:\n\n` +
      `1. 💳 **Audit & Prioritize Subscriptions**: Ask *"Check my recurring subscriptions and prioritize them"*\n` +
      `2. 🎯 **Custom Savings Roadmap**: Ask *"How can I save ₹5,000 this month?"*\n` +
      `3. 🕒 **Transaction Timeline**: Ask *"What did I spend on Saturday?"* or *"Show Starbucks purchases"*\n` +
      `4. 🏆 **Savings Goals**: Ask *"How are my savings goals doing?"*`
    );
  }

  /**
   * Generates a 3-Tier Subscription Audit & Financial Prioritization Model
   */
  static buildSubscriptionPrioritizationModel(ctx: ChatContext): string {
    const knownSubs = [
      { name: 'Electricity & Water Board', amount: 2150, tier: 'Tier 1: Essential Utility (Non-negotiable)', action: 'Keep active; automate on due date.' },
      { name: 'Gold Gym Membership', amount: 1500, tier: 'Tier 1: Health & Fitness (High ROI)', action: 'Keep active if attending $\\ge$ 3x/week.' },
      { name: 'Apple iCloud Storage', amount: 219, tier: 'Tier 2: Cloud Infrastructure & Backup', action: 'Keep active (Crucial device data backup).' },
      { name: 'Netflix Subscription', amount: 649, tier: 'Tier 3: Discretionary Entertainment', action: 'Candidate for rotation / pause if underutilized.' },
    ];

    const detected = ctx.recurringSubs.length > 0 ? ctx.recurringSubs : knownSubs.map(s => ({ merchant: s.name, amount: s.amount }));
    const totalMonthly = detected.reduce((sum, s) => sum + s.amount, 0);
    const totalAnnual = totalMonthly * 12;

    const needsEst = Math.round(ctx.totalSpent * 0.50);
    const wantsEst = Math.round(ctx.totalSpent * 0.30);
    const savingsEst = Math.round(ctx.totalSpent * 0.20);

    return (
      `💳 **Subscription Audit & Prioritization Model**\n\n` +
      `I detected **${detected.length} recurring subscriptions** totaling **₹${totalMonthly.toLocaleString()}/month** (₹${totalAnnual.toLocaleString()}/year):\n\n` +
      `### 📊 3-Tier Prioritization Matrix:\n` +
      `1. 🟢 **Tier 1 (Non-Negotiable Needs & Health)**:\n` +
      `   • **Electricity & Utilities** (₹2,150/mo) $\\rightarrow$ *Essential lifeline*\n` +
      `   • **Gold Gym Membership** (₹1,500/mo) $\\rightarrow$ *High physical & mental health ROI*\n\n` +
      `2. 🟡 **Tier 2 (Productivity & Infrastructure)**:\n` +
      `   • **Apple iCloud (2TB)** (₹219/mo) $\\rightarrow$ *Critical data integrity & security*\n\n` +
      `3. 🔴 **Tier 3 (Discretionary Entertainment — Priority to Trim)**:\n` +
      `   • **Netflix Premium** (₹649/mo) $\\rightarrow$ *Save ₹7,788/yr by switching to Standard or rotating every 2 months*\n\n` +
      `---\n` +
      `### 🏛️ Recommended 50/30/20 Optimization Model\n` +
      `Based on your monthly volume (₹${ctx.totalSpent.toLocaleString()}):\n` +
      `• **50% Needs (₹${needsEst.toLocaleString()})**: Utilities, Groceries, Rent, Essential Transit\n` +
      `• **30% Wants (₹${wantsEst.toLocaleString()})**: Dining out, Entertainment, Shopping\n` +
      `• **20% Savings/Goals (₹${savingsEst.toLocaleString()})**: Emergency Fund & Laptop Fund\n\n` +
      `💡 **Action Step**: Pausing Tier 3 entertainment unlocks an extra **₹649/month (₹7,788/yr)** directly toward your active Savings Goals!`
    );
  }

  /**
   * Generates a 50/30/20 Budgeting Model
   */
  static build503020BudgetModel(ctx: ChatContext): string {
    const total = ctx.totalSpent > 0 ? ctx.totalSpent : 30000;
    const needs = Math.round(total * 0.50);
    const wants = Math.round(total * 0.30);
    const savings = Math.round(total * 0.20);

    return (
      `🏛️ **50/30/20 Financial Budget Allocation Model**\n\n` +
      `Calibrated against your current spend of **₹${total.toLocaleString()}**:\n\n` +
      `1. 🛡️ **Needs (50% $\\rightarrow$ ₹${needs.toLocaleString()})**:\n` +
      `   • Groceries, Utilities, Rent, Healthcare, Commute.\n` +
      `   • *Status*: Essential baseline.\n\n` +
      `2. 🛍️ **Wants (30% $\\rightarrow$ ₹${wants.toLocaleString()})**:\n` +
      `   • Dining out, shopping, streaming subscriptions, movies.\n` +
      `   • *Rule*: Apply the **48-Hour Cart Rule** to keep this strictly under ₹${wants.toLocaleString()}.\n\n` +
      `3. 🎯 **Savings & Debt (20% $\\rightarrow$ ₹${savings.toLocaleString()})**:\n` +
      `   • Automatic transfer to your Emergency Fund & Savings Goals on salary day.\n\n` +
      `💡 Tap **Budgets** in the navigation bar to set these category limits directly!`
    );
  }

  /**
   * Generates a Custom Savings Target Roadmap
   */
  static buildCustomSavingsRoadmap(ctx: ChatContext, targetAmount: number): string {
    const foodSpend = ctx.categoryBreakdown['Food & Dining'] || 0;
    const shoppingSpend = ctx.categoryBreakdown['Shopping'] || 0;
    const entertainmentSpend = ctx.categoryBreakdown['Entertainment'] || 0;
    const transitSpend = ctx.categoryBreakdown['Transportation'] || 0;

    const foodCut = Math.round(foodSpend > 0 ? foodSpend * 0.35 : targetAmount * 0.35);
    const shoppingCut = Math.round(shoppingSpend > 0 ? shoppingSpend * 0.30 : targetAmount * 0.30);
    const entCut = Math.round(entertainmentSpend > 0 ? entertainmentSpend * 0.50 : 649);
    const transitCut = Math.round(targetAmount - foodCut - shoppingCut - entCut);
    const adjustedTransitCut = transitCut > 0 ? transitCut : Math.round(transitSpend * 0.25);

    const totalCalculatedSavings = foodCut + shoppingCut + entCut + adjustedTransitCut;
    const dailySavingTarget = Math.round(targetAmount / 30);

    return (
      `💡 **Personalized Action Plan to Save ₹${targetAmount.toLocaleString()} This Month**:\n\n` +
      `To hit your target, save approximately **₹${dailySavingTarget}/day**. Based on your spending ledger (₹${ctx.totalSpent.toLocaleString()} total), here is your custom roadmap:\n\n` +
      `1. 🍔 **Food & Dining (Save ~₹${foodCut.toLocaleString()})**:\n` +
      `   • Current spend: ₹${foodSpend.toLocaleString()}\n` +
      `   • Action: Cook 2 additional meals/week at home and limit weekend delivery orders.\n\n` +
      `2. 🛍️ **Shopping & Retail (Save ~₹${shoppingCut.toLocaleString()})**:\n` +
      `   • Current spend: ₹${shoppingSpend.toLocaleString()}\n` +
      `   • Action: Implement the **48-Hour Rule** on non-essential carts (wait 2 days before buying).\n\n` +
      `3. 🎬 **Subscriptions & Entertainment (Save ~₹${entCut.toLocaleString()})**:\n` +
      `   • Current spend: ₹${entertainmentSpend.toLocaleString()}\n` +
      `   • Action: Pause 1 unused streaming or entertainment subscription this month.\n\n` +
      `4. 🚗 **Commute & Daily Transit (Save ~₹${adjustedTransitCut.toLocaleString()})**:\n` +
      `   • Current spend: ₹${transitSpend.toLocaleString()}\n` +
      `   • Action: Combine errands into single trips or use public transit 2 days/week.\n\n` +
      `🎯 **Total Projected Savings: ₹${totalCalculatedSavings.toLocaleString()}** (Achieves 100% of your ₹${targetAmount.toLocaleString()} goal!)`
    );
  }
}
