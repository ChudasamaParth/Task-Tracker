import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }

extension TaskPriorityX on TaskPriority {
  String get label => switch (this) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  /// Text / dot colour.
  Color get color => switch (this) {
    TaskPriority.low => const Color(0xFF16A34A),
    TaskPriority.medium => const Color(0xFFEA8A0C),
    TaskPriority.high => const Color(0xFFDC2626),
  };

  /// Soft background colour for chips.
  Color get background => color.withValues(alpha: 0.12);
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;

  const TaskModel({
    this.id = '',
    required this.title,
    this.description = '',
    required this.dueDate,
    required this.priority,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory TaskModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return TaskModel(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: (data['isCompleted'] as bool?) ?? false,
      // createdAt is null briefly while the server timestamp is pending.
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Fields written to Firestore. `createdAt` is set once by the service.
  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'dueDate': Timestamp.fromDate(dueDate),
    'priority': priority.name,
    'isCompleted': isCompleted,
  };

  TaskModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}