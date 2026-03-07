class TeacherCoursePreference {
  final String? id;
  final String teacherInitial;
  final String courseCode;
  final String batchId;
  final String classType; // Lecture, Tutorial, Sessional
  final int sessionsPerWeek; // how many times per week
  final String? preferredDay; // optional preferred day
  final String? preferredTimeSlot; // optional preferred time
  final String? preferredRoomId; // optional preferred room
  final String? groupName; // G-1, G-2, or null
  final String status; // pending, approved, rejected
  final String createdAt;
  final String updatedAt;

  TeacherCoursePreference({
    this.id,
    required this.teacherInitial,
    required this.courseCode,
    required this.batchId,
    required this.classType,
    this.sessionsPerWeek = 1,
    this.preferredDay,
    this.preferredTimeSlot,
    this.preferredRoomId,
    this.groupName,
    this.status = 'pending',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory TeacherCoursePreference.fromJson(Map<String, dynamic> json) {
    return TeacherCoursePreference(
      id: json['id'],
      teacherInitial: json['teacher_initial'],
      courseCode: json['course_code'],
      batchId: json['batch_id'],
      classType: json['class_type'] ?? 'Lecture',
      sessionsPerWeek: json['sessions_per_week'] ?? 1,
      preferredDay: json['preferred_day'],
      preferredTimeSlot: json['preferred_time_slot'],
      preferredRoomId: json['preferred_room_id'],
      groupName: json['group_name'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'teacher_initial': teacherInitial,
        'course_code': courseCode,
        'batch_id': batchId,
        'class_type': classType,
        'sessions_per_week': sessionsPerWeek,
        'preferred_day': preferredDay,
        'preferred_time_slot': preferredTimeSlot,
        'preferred_room_id': preferredRoomId,
        'group_name': groupName,
        'status': status,
      };

  Map<String, dynamic> toInsertJson() => {
        'teacher_initial': teacherInitial,
        'course_code': courseCode,
        'batch_id': batchId,
        'class_type': classType,
        'sessions_per_week': sessionsPerWeek,
        'preferred_day': preferredDay,
        'preferred_time_slot': preferredTimeSlot,
        'preferred_room_id': preferredRoomId,
        'group_name': groupName,
        'status': status,
      };

  TeacherCoursePreference copyWith({
    String? id,
    String? teacherInitial,
    String? courseCode,
    String? batchId,
    String? classType,
    int? sessionsPerWeek,
    String? preferredDay,
    String? preferredTimeSlot,
    String? preferredRoomId,
    String? groupName,
    String? status,
  }) {
    return TeacherCoursePreference(
      id: id ?? this.id,
      teacherInitial: teacherInitial ?? this.teacherInitial,
      courseCode: courseCode ?? this.courseCode,
      batchId: batchId ?? this.batchId,
      classType: classType ?? this.classType,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      preferredDay: preferredDay ?? this.preferredDay,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      preferredRoomId: preferredRoomId ?? this.preferredRoomId,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
