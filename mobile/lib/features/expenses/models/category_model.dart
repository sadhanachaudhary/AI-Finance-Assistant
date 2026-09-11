import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String? icon;
  final String? color;

  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
    };
  }

  Color get parsedColor {
    if (color == null || color!.isEmpty) return const Color(0xFF6C63FF);
    try {
      final hex = color!.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF6C63FF);
    }
  }

  IconData get parsedIcon {
    switch (icon?.toLowerCase()) {
      case 'shopping':
      case 'shopping_bag':
        return Icons.shopping_bag_outlined;
      case 'food':
      case 'restaurant':
      case 'dining':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'directions_car':
      case 'commute':
        return Icons.directions_car_outlined;
      case 'bills':
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'entertainment':
      case 'movie':
        return Icons.movie_outlined;
      case 'health':
      case 'medical':
        return Icons.medical_services_outlined;
      case 'travel':
      case 'flight':
        return Icons.flight_takeoff_outlined;
      case 'education':
      case 'school':
        return Icons.school_outlined;
      case 'investment':
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'salary':
      case 'work':
        return Icons.work_outline_rounded;
      default:
        return Icons.category_outlined;
    }
  }
}
