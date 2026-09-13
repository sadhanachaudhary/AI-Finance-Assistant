import '../../../networking/api_client.dart';
import '../models/expense_model.dart';
import '../models/category_model.dart';

class ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepository(this._apiClient);

  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    String? search,
    String? sortBy,
    String? order,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        if (minAmount != null) 'minAmount': minAmount,
        if (maxAmount != null) 'maxAmount': maxAmount,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sortBy != null) 'sortBy': sortBy,
        if (order != null) 'order': order,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
      };

      final response = await _apiClient.dio.get(
        '/expenses',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final list = response.data['data']['expenses'] as List;
        final result = list.map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
        if (result.isNotEmpty) return result;
      }
      return _getDemoExpenses();
    } catch (_) {
      // Return realistic demo expenses if backend is not running or unauthenticated
      return _getDemoExpenses();
    }
  }

  Future<Expense> createExpense({
    required double amount,
    String currency = 'INR',
    required DateTime date,
    String? merchant,
    String? notes,
    String? categoryId,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/expenses',
        data: {
          'amount': amount,
          'currency': currency,
          'date': date.toIso8601String(),
          if (merchant != null && merchant.isNotEmpty) 'merchant': merchant,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        },
      );

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        return Expense.fromJson(response.data['data']['expense'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback for local demo
    }

    return Expense(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'demo_user',
      amount: amount,
      currency: currency,
      date: date,
      merchant: merchant,
      notes: notes,
      categoryId: categoryId,
    );
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _apiClient.dio.delete('/expenses/$id');
    } catch (_) {
      // Allowed in demo mode
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final list = response.data['data']['categories'] as List;
        final result = list.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
        if (result.isNotEmpty) return result;
      }
      return _getDemoCategories();
    } catch (_) {
      return _getDemoCategories();
    }
  }

  Future<Category> createCategory({
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/categories',
        data: {
          'name': name,
          if (icon != null) 'icon': icon,
          if (color != null) 'color': color,
        },
      );

      if (response.statusCode == 201 && response.data['status'] == 'success') {
        return Category.fromJson(response.data['data']['category'] as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback for local demo
    }

    return Category(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      icon: icon,
      color: color,
    );
  }

  // Built-in Demo Data for immediate preview
  static List<Category> _getDemoCategories() {
    return const [
      Category(id: 'cat_food', name: 'Food & Dining', icon: 'restaurant', color: '#FF7043'),
      Category(id: 'cat_shop', name: 'Shopping', icon: 'shopping_bag', color: '#AB47BC'),
      Category(id: 'cat_trans', name: 'Transportation', icon: 'directions_car', color: '#42A5F5'),
      Category(id: 'cat_ent', name: 'Entertainment', icon: 'movie', color: '#EC407A'),
      Category(id: 'cat_bills', name: 'Bills & Utilities', icon: 'receipt', color: '#26A69A'),
      Category(id: 'cat_health', name: 'Health & Fitness', icon: 'health', color: '#FFA726'),
      Category(id: 'cat_groc', name: 'Groceries', icon: 'shopping', color: '#66BB6A'),
      Category(id: 'cat_travel', name: 'Travel', icon: 'flight', color: '#7E57C2'),
    ];
  }

  static List<Expense> _getDemoExpenses() {
    final now = DateTime.now();
    final cats = {for (final c in _getDemoCategories()) c.id: c};

    return [
      Expense(
        id: 'exp_1',
        userId: 'demo_user',
        merchant: 'Amazon Marketplace',
        amount: 3499.00,
        currency: 'INR',
        date: now.subtract(const Duration(hours: 3)),
        notes: 'Noise cancelling headphones',
        categoryId: 'cat_shop',
        category: cats['cat_shop'],
      ),
      Expense(
        id: 'exp_2',
        userId: 'demo_user',
        merchant: 'Starbucks Coffee',
        amount: 450.00,
        currency: 'INR',
        date: now.subtract(const Duration(hours: 6)),
        notes: 'Caramel Macchiato & Croissant',
        categoryId: 'cat_food',
        category: cats['cat_food'],
      ),
      Expense(
        id: 'exp_3',
        userId: 'demo_user',
        merchant: 'Uber Ride',
        amount: 320.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        notes: 'Commute back from office',
        categoryId: 'cat_trans',
        category: cats['cat_trans'],
      ),
      Expense(
        id: 'exp_4',
        userId: 'demo_user',
        merchant: 'Swiggy Gourmet',
        amount: 890.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 1, hours: 5)),
        notes: 'Weekend dinner with friends',
        categoryId: 'cat_food',
        category: cats['cat_food'],
      ),
      Expense(
        id: 'exp_5',
        userId: 'demo_user',
        merchant: 'Whole Foods Market',
        amount: 4820.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 2)),
        notes: 'Weekly fresh groceries & organic fruit',
        categoryId: 'cat_groc',
        category: cats['cat_groc'],
      ),
      Expense(
        id: 'exp_6',
        userId: 'demo_user',
        merchant: 'Netflix Subscription',
        amount: 649.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 3)),
        notes: 'Premium 4K Family plan',
        categoryId: 'cat_ent',
        category: cats['cat_ent'],
      ),
      Expense(
        id: 'exp_7',
        userId: 'demo_user',
        merchant: 'Electricity & Water Board',
        amount: 2150.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 4)),
        notes: 'Monthly utility bill payment',
        categoryId: 'cat_bills',
        category: cats['cat_bills'],
      ),
      Expense(
        id: 'exp_8',
        userId: 'demo_user',
        merchant: 'Gold Gym Membership',
        amount: 1500.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 5)),
        notes: 'Monthly fitness subscription',
        categoryId: 'cat_health',
        category: cats['cat_health'],
      ),
      Expense(
        id: 'exp_9',
        userId: 'demo_user',
        merchant: 'Zara Fashion',
        amount: 4200.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 7)),
        notes: 'Casual jackets and shirts',
        categoryId: 'cat_shop',
        category: cats['cat_shop'],
      ),
      Expense(
        id: 'exp_10',
        userId: 'demo_user',
        merchant: 'Shell Petrol Station',
        amount: 1800.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 8)),
        notes: 'Full tank refuel',
        categoryId: 'cat_trans',
        category: cats['cat_trans'],
      ),
      Expense(
        id: 'exp_11',
        userId: 'demo_user',
        merchant: 'PVR IMAX Cinemas',
        amount: 750.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 10)),
        notes: '2 tickets + Popcorn combo',
        categoryId: 'cat_ent',
        category: cats['cat_ent'],
      ),
      Expense(
        id: 'exp_12',
        userId: 'demo_user',
        merchant: 'Apollo Pharmacy',
        amount: 680.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 12)),
        notes: 'Vitamins & first aid supplies',
        categoryId: 'cat_health',
        category: cats['cat_health'],
      ),
      Expense(
        id: 'exp_13',
        userId: 'demo_user',
        merchant: 'IndiGo Airlines',
        amount: 6500.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 15)),
        notes: 'Roundtrip flight for conference',
        categoryId: 'cat_travel',
        category: cats['cat_travel'],
      ),
      Expense(
        id: 'exp_14',
        userId: 'demo_user',
        merchant: 'Apple iCloud Storage',
        amount: 219.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 18)),
        notes: '2TB Cloud Storage subscription',
        categoryId: 'cat_bills',
        category: cats['cat_bills'],
      ),
      Expense(
        id: 'exp_15',
        userId: 'demo_user',
        merchant: 'Blue Tokai Coffee Roasters',
        amount: 520.00,
        currency: 'INR',
        date: now.subtract(const Duration(days: 22)),
        notes: 'Roasted coffee beans & pour over',
        categoryId: 'cat_food',
        category: cats['cat_food'],
      ),
    ];
  }
}
