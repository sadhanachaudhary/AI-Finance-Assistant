import 'package:flutter/material.dart';

class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String currency;
  final DateTime? deadline;
  final String? category;
  final String? color;
  final String? icon;
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.currency = 'INR',
    this.deadline,
    this.category,
    this.color,
    this.icon,
    required this.createdAt,
  });

  double get percentage => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
  double get remainingAmount => (targetAmount - currentAmount).clamp(0.0, double.infinity);
  bool get isCompleted => currentAmount >= targetAmount;

  int? get daysRemaining {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff >= 0 ? diff : 0;
  }

  Color get parsedColor {
    if (color != null && color!.isNotEmpty) {
      try {
        final hex = color!.replaceAll('#', '').replaceAll('0x', '');
        return Color(int.parse(hex.length == 6 ? 'FF$hex' : hex, radix: 16));
      } catch (_) {}
    }
    return const Color(0xFF10B981); // Default mint emerald
  }

  IconData get parsedIcon {
    if (icon != null && icon!.isNotEmpty) {
      switch (icon!.toLowerCase()) {
        case 'shield':
        case 'emergency':
          return Icons.shield_outlined;
        case 'flight':
        case 'vacation':
        case 'travel':
          return Icons.flight_takeoff_rounded;
        case 'laptop':
        case 'tech':
        case 'gadget':
          return Icons.laptop_mac_rounded;
        case 'car':
        case 'vehicle':
          return Icons.directions_car_rounded;
        case 'home':
        case 'house':
          return Icons.home_rounded;
        case 'school':
        case 'education':
          return Icons.school_rounded;
        case 'savings':
        case 'piggy':
          return Icons.savings_outlined;
        case 'shopping':
          return Icons.shopping_bag_outlined;
      }
    }
    return Icons.flag_rounded;
  }

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      deadline: json['deadline'] != null ? DateTime.tryParse(json['deadline']) : null,
      category: json['category'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'currency': currency,
      'deadline': deadline?.toIso8601String(),
      'category': category,
      'color': color,
      'icon': icon,
    };
  }
}
