class Student {
  final String studentId;
  final String name;
  final String batchId;
  final String? email; // Added for login
  final bool hasChangedPassword; // Track if user changed password
  final bool notificationsEnabled; // Super admin permission
  final bool emailEnabled; // Super admin permission

  Student({
    required this.studentId,
    required this.name,
    required this.batchId,
    this.email,
    this.hasChangedPassword = false,
    this.notificationsEnabled = false,
    this.emailEnabled = false,
  });

  factory Student.fromJson(Map<String, dynamic> json) => Student(
        studentId: json['student_id'],
        name: json['name'] ?? '',
        batchId: json['batch_id'],
        email: json['email'],
        hasChangedPassword: json['has_changed_password'] ?? false,
        notificationsEnabled: json['notifications_enabled'] ?? false,
        emailEnabled: json['email_enabled'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'name': name,
        'batch_id': batchId,
        'email': email,
        'has_changed_password': hasChangedPassword,
        'notifications_enabled': notificationsEnabled,
        'email_enabled': emailEnabled,
      };

  Student copyWith({
    String? studentId,
    String? name,
    String? batchId,
    String? email,
    bool? hasChangedPassword,
    bool? notificationsEnabled,
    bool? emailEnabled,
  }) {
    return Student(
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      batchId: batchId ?? this.batchId,
      email: email ?? this.email,
      hasChangedPassword: hasChangedPassword ?? this.hasChangedPassword,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
    );
  }
}
