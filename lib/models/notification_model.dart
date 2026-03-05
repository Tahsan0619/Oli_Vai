class AppNotification {
  final String id;
  final String type; // class_cancelled, class_rescheduled, room_changed, class_restored, daily_reminder, appointment
  final String title;
  final String body;
  final String? recipientType; // super_admin, student, teacher
  final String? recipientId; // student_id, teacher_initial, or 'all_admins'
  final String? relatedEntryId; // timetable entry id if applicable
  final bool isRead;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.recipientType,
    this.recipientId,
    this.relatedEntryId,
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'],
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        recipientType: json['recipient_type'],
        recipientId: json['recipient_id'],
        relatedEntryId: json['related_entry_id'],
        isRead: json['is_read'] ?? false,
        createdAt: json['created_at'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'recipient_type': recipientType,
        'recipient_id': recipientId,
        'related_entry_id': relatedEntryId,
        'is_read': isRead,
        'created_at': createdAt,
      };

  /// For inserting new notifications (no id/createdAt)
  Map<String, dynamic> toInsertJson() => {
        'type': type,
        'title': title,
        'body': body,
        'recipient_type': recipientType,
        'recipient_id': recipientId,
        'related_entry_id': relatedEntryId,
        'is_read': false,
      };
}
