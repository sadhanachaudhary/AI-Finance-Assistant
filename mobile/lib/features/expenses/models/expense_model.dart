import 'category_model.dart';

class Expense {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final DateTime date;
  final String? merchant;
  final String? notes;
  final String? categoryId;
  final Category? category;

  const Expense({
    required this.id,
    required this.userId,
    required this.amount,
    this.currency = 'INR',
    required this.date,
    this.merchant,
    this.notes,
    this.categoryId,
    this.category,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'INR',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      merchant: json['merchant'] as String?,
      notes: json['notes'] as String?,
      categoryId: json['categoryId'] as String?,
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      if (merchant != null) 'merchant': merchant,
      if (notes != null) 'notes': notes,
      if (categoryId != null) 'categoryId': categoryId,
    };
  }
}
