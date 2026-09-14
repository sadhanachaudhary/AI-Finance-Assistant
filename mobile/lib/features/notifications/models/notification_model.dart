import 'package:flutter/material.dart';

enum NotificationType {
  budgetAlert,
  goalMilestone,
  subscriptionReminder,
  systemSecurity,
  generalTip,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  NotificationType get type {
    final lower = title.toLowerCase();
    if (lower.contains('spending') || lower.contains('budget') || lower.contains('overrun') || lower.contains('alert')) {
      return NotificationType.budgetAlert;
    }
    if (lower.contains('goal') || lower.contains('milestone') || lower.contains('achieved')) {
      return NotificationType.goalMilestone;
    }
    if (lower.contains('recurring') || lower.contains('subscription') || lower.contains('audit')) {
      return NotificationType.subscriptionReminder;
    }
    if (lower.contains('shield') || lower.contains('security') || lower.contains('privacy')) {
      return NotificationType.systemSecurity;
    }
    return NotificationType.generalTip;
  }

  IconData get icon {
    switch (type) {
      case NotificationType.budgetAlert:
        return Icons.warning_amber_rounded;
      case NotificationType.goalMilestone:
        return Icons.emoji_events_rounded;
      case NotificationType.subscriptionReminder:
        return Icons.autorenew_rounded;
      case NotificationType.systemSecurity:
        return Icons.shield_rounded;
      case NotificationType.generalTip:
        return Icons.lightbulb_outline_rounded;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.budgetAlert:
        return const Color(0xFFF59E0B); // Amber
      case NotificationType.goalMilestone:
        return const Color(0xFF10B981); // Emerald Mint
      case NotificationType.subscriptionReminder:
        return const Color(0xFF8B5CF6); // Violet
      case NotificationType.systemSecurity:
        return const Color(0xFF3B82F6); // Blue
      case NotificationType.generalTip:
        return const Color(0xFF06B6D4); // Cyan
    }
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
