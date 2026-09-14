/// Centralized object/registry for all backend API endpoints.
/// If route paths, API versions, or endpoint patterns change, update them here.
abstract final class ApiEndpoints {
  // --- Authentication Endpoints ---
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/me';
  static const String refreshToken = '/auth/refresh';

  // --- Expenses & Transactions Endpoints ---
  static const String expenses = '/expenses';
  static String expenseById(String id) => '/expenses/$id';
  static const String expenseStats = '/expenses/stats';
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // --- Bills & Recurring Subscriptions Endpoints ---
  static const String bills = '/bills';
  static String billById(String id) => '/bills/$id';
  static const String billStats = '/bills/stats';
  static const String scanBill = '/bills/scan';
  static const String analyzeBill = '/bills/analyze';

  // --- Notifications & Smart Alerts Endpoints ---
  static const String notifications = '/notifications';
  static const String notificationUnreadCount = '/notifications/unread-count';
  static const String notificationGenerateAlerts = '/notifications/generate-alerts';
  static const String notificationReadAll = '/notifications/read-all';
  static String notificationRead(String id) => '/notifications/$id/read';
  static String notificationById(String id) => '/notifications/$id';

  // --- Savings Goals & Targets Endpoints ---
  static const String goals = '/goals';
  static String goalById(String id) => '/goals/$id';
  static String goalDeposit(String id) => '/goals/$id/deposit';

  // --- AI Wealth Advisor & Chat Endpoints ---
  static const String aiChat = '/ai/chat';
  static const String aiConversations = '/ai/conversations';
  static String aiConversationById(String id) => '/ai/conversations/$id';
  static const String aiInsights = '/ai/insights';
  static const String aiBudgetForecast = '/ai/forecast';

  // --- Analytics & Financial Reports Endpoints ---
  static const String analytics = '/analytics';
  static const String analyticsSummary = '/analytics/summary';
  static const String analyticsTrends = '/analytics/trends';
  static const String analyticsCashFlow = '/analytics/cashflow';
}
