class Appointment {
  final String id;
  final String teacherInitial;
  final String studentId;
  final String studentName;
  final String date; // "yyyy-MM-dd"
  final String time; // "HH:mm"
  final String purpose;
  final String status; // pending, accepted, rejected
  final String? teacherRemarks;
  final String createdAt;

  Appointment({
    required this.id,
    required this.teacherInitial,
    required this.studentId,
    required this.studentName,
    required this.date,
    required this.time,
    required this.purpose,
    required this.status,
    this.teacherRemarks,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'],
        teacherInitial: json['teacher_initial'],
        studentId: json['student_id'],
        studentName: json['student_name'] ?? '',
        date: json['date'],
        time: json['time'],
        purpose: json['purpose'] ?? '',
        status: json['status'] ?? 'pending',
        teacherRemarks: json['teacher_remarks'],
        createdAt: json['created_at'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_initial': teacherInitial,
        'student_id': studentId,
        'student_name': studentName,
        'date': date,
        'time': time,
        'purpose': purpose,
        'status': status,
        'teacher_remarks': teacherRemarks,
        'created_at': createdAt,
      };

  /// For inserting new appointment (no id/createdAt)
  Map<String, dynamic> toInsertJson() => {
        'teacher_initial': teacherInitial,
        'student_id': studentId,
        'student_name': studentName,
        'date': date,
        'time': time,
        'purpose': purpose,
        'status': status,
      };
}
