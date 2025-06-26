import 'dart:ui';

import 'package:flutter/material.dart';

enum TaskType {
  medication,
  exercise,
  meal,
  health,
  appointment,
  other,
}

class Task {
  final String id;
  final String title;
  final String description;
  final String time;
  final TaskType type;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.type,
    this.isCompleted = false,
  });

  IconData get icon {
    switch (type) {
      case TaskType.medication:
        return Icons.medication;
      case TaskType.exercise:
        return Icons.fitness_center;
      case TaskType.meal:
        return Icons.restaurant;
      case TaskType.health:
        return Icons.favorite;
      case TaskType.appointment:
        return Icons.calendar_today;
      case TaskType.other:
      default:
        return Icons.task_alt;
    }
  }

  Color get color {
    switch (type) {
      case TaskType.medication:
        return Colors.blue;
      case TaskType.exercise:
        return Colors.orange;
      case TaskType.meal:
        return Colors.green;
      case TaskType.health:
        return Colors.red;
      case TaskType.appointment:
        return Colors.purple;
      case TaskType.other:
      default:
        return Colors.grey;
    }
  }
}