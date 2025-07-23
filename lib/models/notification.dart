class AppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isRead;
  final String type; // 'order', 'promotion', 'system', 'feedback'
  final String? actionData; // JSON string for navigation or action data

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.actionData,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
      type: json['type'],
      actionData: json['actionData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'actionData': actionData,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    String? actionData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      actionData: actionData ?? this.actionData,
    );
  }
} 
