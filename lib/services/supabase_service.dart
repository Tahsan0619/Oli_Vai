import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../models/admin.dart';
import '../models/appointment.dart';
import '../models/notification_model.dart';
import '../models/teacher.dart';
import '../models/teacher_course_preference.dart';
import '../models/batch.dart';
import '../models/course.dart';
import '../models/room.dart';
import '../models/student.dart';
import '../models/timetable_entry.dart';

/// Supabase Service for all backend operations
class SupabaseService extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  
  Admin? _currentAdmin;
  Admin? get currentAdmin => _currentAdmin;

  Student? _currentStudent;
  Student? get currentStudent => _currentStudent;

  Teacher? _currentTeacher;
  Teacher? get currentTeacher => _currentTeacher;

  // Cache for frequently accessed data
  List<Teacher>? _cachedTeachers;
  List<Batch>? _cachedBatches;
  List<Course>? _cachedCourses;
  List<Room>? _cachedRooms;
  List<Student>? _cachedStudents;

  static const String _adminCacheKey = 'somoysutro_current_admin';

  // =====================================================
  // AUTHENTICATION
  // =====================================================

  /// Initialize service and restore saved session
  Future<void> initialize() async {
    await restoreSession();
    await restoreStudentSession();
    await restoreTeacherSession();
  }

  /// Restore saved student session
  Future<void> restoreStudentSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentJson = prefs.getString('student_session');
      
      if (studentJson != null) {
        final studentData = jsonDecode(studentJson) as Map<String, dynamic>;
        _currentStudent = Student.fromJson(studentData);
        debugPrint('Student session restored for: ${_currentStudent?.name}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring student session: $e');
    }
  }

  /// Save student session
  Future<void> _saveStudentSession(Student student) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentJson = jsonEncode(student.toJson());
      await prefs.setString('student_session', studentJson);
      debugPrint('Student session saved for: ${student.name}');
    } catch (e) {
      debugPrint('Error saving student session: $e');
    }
  }

  /// Restore saved teacher session
  Future<void> restoreTeacherSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherJson = prefs.getString('teacher_session');
      
      if (teacherJson != null) {
        final teacherData = jsonDecode(teacherJson) as Map<String, dynamic>;
        _currentTeacher = Teacher.fromJson(teacherData);
        debugPrint('Teacher session restored for: ${_currentTeacher?.name}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring teacher session: $e');
    }
  }

  /// Save teacher session
  Future<void> _saveTeacherSession(Teacher teacher) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherJson = jsonEncode(teacher.toJson());
      await prefs.setString('teacher_session', teacherJson);
      debugPrint('Teacher session saved for: ${teacher.name}');
    } catch (e) {
      debugPrint('Error saving teacher session: $e');
    }
  }

  /// Restore saved admin session
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminJson = prefs.getString(_adminCacheKey);
      
      if (adminJson != null) {
        final adminData = jsonDecode(adminJson) as Map<String, dynamic>;
        _currentAdmin = Admin(
          id: adminData['id'],
          username: adminData['username'],
          password: adminData['password'],
          type: adminData['type'],
          teacherInitial: adminData['teacherInitial'],
        );
        debugPrint('Session restored for user: ${_currentAdmin?.username}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  /// Save admin session
  Future<void> _saveSession(Admin admin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final adminJson = jsonEncode({
        'id': admin.id,
        'username': admin.username,
        'password': admin.password,
        'type': admin.type,
        'teacherInitial': admin.teacherInitial,
      });
      await prefs.setString(_adminCacheKey, adminJson);
      debugPrint('Session saved for user: ${admin.username}');
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// Authenticate admin user
  Future<Admin?> authenticateAdmin(String username, String password) async {
    try {
      final response = await _client
          .from('admins')
          .select()
          .eq('username', username)
          .eq('password_hash', password)
          .maybeSingle();

      if (response == null) return null;

      _currentAdmin = Admin.fromJson(response);
      await _saveSession(_currentAdmin!);
      notifyListeners();
      return _currentAdmin;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return null;
    }
  }

  /// Logout current user (admin, teacher, or student)
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminCacheKey);
      await prefs.remove('student_session');
      await prefs.remove('teacher_session');
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
    _currentAdmin = null;
    _currentStudent = null;
    _currentTeacher = null;
    _clearCache();
    notifyListeners();
  }

  /// Authenticate a student with email and password
  /// Returns the student if credentials are valid, null otherwise
  Future<Student?> authenticateStudent(String email, String password) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('email', email)
          .single();

      final student = Student.fromJson(response);
      
      // Verify password (in production, this should be hashed)
      // For now, we store and compare plain passwords
      final storedPassword = response['password'] as String?;
      if (storedPassword == password) {
        _currentStudent = student;
        await _saveStudentSession(student);
        notifyListeners();
        return student;
      }
      return null;
    } catch (e) {
      debugPrint('Error authenticating student: $e');
      return null;
    }
  }
  /// Update student password
  Future<bool> updateStudentPassword(String studentId, String newPassword) async {
    try {
      await _client
          .from('students')
          .update({
            'password': newPassword,
            'has_changed_password': true,
          })
          .eq('student_id', studentId);
      
      // Update the current student's flag if it's the same student
      if (_currentStudent?.studentId == studentId) {
        _currentStudent = Student(
          studentId: _currentStudent!.studentId,
          name: _currentStudent!.name,
          batchId: _currentStudent!.batchId,
          email: _currentStudent!.email,
          hasChangedPassword: true,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error updating student password: $e');
      return false;
    }
  }

  /// Set initial credentials for a student (super admin only)
  /// password_hash is stored but after first change, it's not retrievable
  Future<void> setStudentCredentials(
      String studentId, String email, String initialPassword) async {
    try {
      await _client.from('students').update({
        'email': email,
        'password': initialPassword,
        'has_changed_password': false,
      }).eq('student_id', studentId);
    } catch (e) {
      debugPrint('Error setting student credentials: $e');
      rethrow;
    }
  }

  /// Student changes their own password
  /// After this, super admin cannot retrieve the password
  Future<void> changeStudentPassword(String studentId, String newPassword) async {
    try {
      await _client.from('students').update({
        'password': newPassword,
        'has_changed_password': true,
      }).eq('student_id', studentId);
    } catch (e) {
      debugPrint('Error changing student password: $e');
      rethrow;
    }
  }

  /// Set initial credentials for a teacher (super admin only)
  Future<void> setTeacherCredentials(
      String teacherId, String email, String initialPassword) async {
    try {
      await _client.from('teachers').update({
        'email': email,
        'password': initialPassword,
        'has_changed_password': false,
      }).eq('id', teacherId);
    } catch (e) {
      debugPrint('Error setting teacher credentials: $e');
      rethrow;
    }
  }

  /// Teacher changes their own password
  Future<void> changeTeacherPassword(String teacherId, String newPassword) async {
    try {
      await _client.from('teachers').update({
        'password': newPassword,
        'has_changed_password': true,
      }).eq('id', teacherId);
    } catch (e) {
      debugPrint('Error changing teacher password: $e');
      rethrow;
    }
  }

  /// Authenticate a teacher with email and password
  Future<Teacher?> authenticateTeacherByEmail(
      String email, String password) async {
    try {
      final response = await _client
          .from('teachers')
          .select()
          .eq('email', email)
          .single();

      final teacher = Teacher.fromJson(response);
      
      // Verify password
      final storedPassword = response['password'] as String?;
      if (storedPassword == password) {
        _currentTeacher = teacher;
        await _saveTeacherSession(teacher);
        notifyListeners();
        return teacher;
      }
      return null;
    } catch (e) {
      debugPrint('Error authenticating teacher: $e');
      return null;
    }
  }


  /// Clear all cached data
  void _clearCache() {
    _cachedTeachers = null;
    _cachedBatches = null;
    _cachedCourses = null;
    _cachedRooms = null;
    _cachedStudents = null;
  }

  // =====================================================
  // TEACHERS
  // =====================================================

  /// Get all teachers
  Future<List<Teacher>> getTeachers({bool forceRefresh = false}) async {
    if (_cachedTeachers != null && !forceRefresh) {
      return _cachedTeachers!;
    }

    try {
      final response = await _client
          .from('teachers')
          .select()
          .order('name', ascending: true);

      _cachedTeachers = (response as List)
          .map((json) => Teacher.fromJson(json))
          .toList();

      return _cachedTeachers!;
    } catch (e) {
      debugPrint('Error fetching teachers: $e');
      return [];
    }
  }

  /// Get teacher by initial
  Future<Teacher?> getTeacherByInitial(String initial) async {
    try {
      final response = await _client
          .from('teachers')
          .select()
          .eq('initial', initial)
          .maybeSingle();

      if (response == null) return null;

      return Teacher.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching teacher: $e');
      return null;
    }
  }

  /// Add new teacher
  Future<bool> addTeacher(Teacher teacher) async {
    try {
      await _client.from('teachers').insert({
        'name': teacher.name,
        'initial': teacher.initial,
        'designation': teacher.designation,
        'phone': teacher.phone,
        'email': teacher.email,
        'home_department': teacher.homeDepartment,
      });
      
      _cachedTeachers = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding teacher: $e');
      return false;
    }
  }

  /// Update teacher
  Future<bool> updateTeacher(String id, Teacher teacher) async {
    try {
      debugPrint('[SVC] updateTeacher($id): name=${teacher.name}, notif=${teacher.notificationsEnabled}, email=${teacher.emailEnabled}');
      await _client.from('teachers').update({
        'name': teacher.name,
        'initial': teacher.initial,
        'designation': teacher.designation,
        'phone': teacher.phone,
        'email': teacher.email,
        'home_department': teacher.homeDepartment,
      }).eq('id', id);
      debugPrint('[SVC] updateTeacher($id): DB update done (only name/desig/phone/email/dept sent)');
      _cachedTeachers = null;
      // NOTE: Do NOT call notifyListeners() here — it causes Consumer<SupabaseService> in main.dart
      // to rebuild the entire widget tree, destroying the SuperAdminPortal and losing local state.
      return true;
    } catch (e) {
      debugPrint('[SVC] Error updating teacher: $e');
      return false;
    }
  }

  /// Upload teacher profile picture to storage
  Future<String?> uploadTeacherProfilePic(String teacherInitial, String filePath) async {
    try {
      final fileName = '${teacherInitial}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _readFileBytes(filePath);
      
      await _client.storage
          .from('teacher-profiles')
          .uploadBinary(fileName, bytes);
      
      final publicUrl = _client.storage
          .from('teacher-profiles')
          .getPublicUrl(fileName);
      
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading profile pic: $e');
      return null;
    }
  }

  /// Delete old profile picture from storage
  Future<void> deleteTeacherProfilePic(String profilePicUrl) async {
    try {
      if (profilePicUrl.isEmpty) return;
      
      // Extract filename from URL
      final uri = Uri.parse(profilePicUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final fileName = pathSegments.last;
        await _client.storage
            .from('teacher-profiles')
            .remove([fileName]);
      }
    } catch (e) {
      debugPrint('Error deleting old profile pic: $e');
    }
  }

  /// Helper to read file bytes (works on all platforms)
  Future<Uint8List> _readFileBytes(String filePath) async {
    if (kIsWeb) {
      // For web, filePath is already bytes in base64 or similar
      throw UnimplementedError('Web upload not implemented yet');
    } else {
      // For mobile/desktop
      final file = await File(filePath).readAsBytes();
      return file;
    }
  }

  /// Update teacher profile picture URL in database
  Future<bool> updateTeacherProfilePic(String id, String? profilePicUrl) async {
    try {
      await _client.from('teachers').update({
        'profile_pic': profilePicUrl,
      }).eq('id', id);
      
      _cachedTeachers = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating teacher profile pic: $e');
      return false;
    }
  }

  /// Update teacher password
  Future<bool> updateTeacherPassword(String teacherId, String newPassword) async {
    try {
      await _client
          .from('teachers')
          .update({
            'password': newPassword,
            'has_changed_password': true,
          })
          .eq('id', teacherId);
      
      _cachedTeachers = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating teacher password: $e');
      return false;
    }
  }

  /// Delete teacher
  Future<bool> deleteTeacher(String id) async {
    try {
      await _client.from('teachers').delete().eq('id', id);
      _cachedTeachers = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting teacher: $e');
      return false;
    }
  }

  // =====================================================
  // BATCHES
  // =====================================================

  /// Get all batches
  Future<List<Batch>> getBatches({bool forceRefresh = false}) async {
    if (_cachedBatches != null && !forceRefresh) {
      return _cachedBatches!;
    }

    try {
      final response = await _client
          .from('batches')
          .select()
          .order('session', ascending: false)
          .order('name', ascending: true);

      _cachedBatches = (response as List)
          .map((json) => Batch(
                id: json['id'],
                name: json['name'],
                session: json['session'],
              ))
          .toList();

      return _cachedBatches!;
    } catch (e) {
      debugPrint('Error fetching batches: $e');
      return [];
    }
  }

  /// Get batch by ID
  Future<Batch?> getBatchById(String id) async {
    try {
      final response = await _client
          .from('batches')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Batch(
        id: response['id'],
        name: response['name'],
        session: response['session'],
      );
    } catch (e) {
      debugPrint('Error fetching batch: $e');
      return null;
    }
  }

  /// Resolve batch name from cache (synchronous, returns ID if not found)
  String batchNameById(String id) {
    if (_cachedBatches == null) return id;
    try {
      return _cachedBatches!.firstWhere((b) => b.id == id).name;
    } catch (_) {
      return id;
    }
  }

  /// Add new batch
  Future<String?> addBatch(Batch batch) async {
    try {
      final response = await _client.from('batches').insert({
        'name': batch.name,
        'session': batch.session,
      }).select().single();
      
      _cachedBatches = null;
      notifyListeners();
      return response['id'];
    } catch (e) {
      debugPrint('Error adding batch: $e');
      return null;
    }
  }

  /// Update batch
  Future<bool> updateBatch(String id, Batch batch) async {
    try {
      await _client.from('batches').update({
        'name': batch.name,
        'session': batch.session,
      }).eq('id', id);
      
      _cachedBatches = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating batch: $e');
      return false;
    }
  }

  /// Delete batch
  Future<bool> deleteBatch(String id) async {
    try {
      await _client.from('batches').delete().eq('id', id);
      _cachedBatches = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting batch: $e');
      return false;
    }
  }

  // =====================================================
  // COURSES
  // =====================================================

  /// Get all courses
  Future<List<Course>> getCourses({bool forceRefresh = false}) async {
    if (_cachedCourses != null && !forceRefresh) {
      return _cachedCourses!;
    }

    try {
      final response = await _client
          .from('courses')
          .select()
          .order('code', ascending: true);

      _cachedCourses = (response as List)
          .map((json) => Course(
                code: json['code'],
                title: json['title'],
              ))
          .toList();

      return _cachedCourses!;
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      return [];
    }
  }

  /// Get course by code
  Future<Course?> getCourseByCode(String code) async {
    try {
      final response = await _client
          .from('courses')
          .select()
          .eq('code', code)
          .maybeSingle();

      if (response == null) return null;

      return Course(
        code: response['code'],
        title: response['title'],
      );
    } catch (e) {
      debugPrint('Error fetching course: $e');
      return null;
    }
  }

  /// Add new course
  Future<bool> addCourse(Course course) async {
    try {
      await _client.from('courses').insert({
        'code': course.code,
        'title': course.title,
      });
      
      _cachedCourses = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding course: $e');
      return false;
    }
  }

  /// Update course
  Future<bool> updateCourse(String code, Course course) async {
    try {
      await _client.from('courses').update({
        'title': course.title,
      }).eq('code', code);
      
      _cachedCourses = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating course: $e');
      return false;
    }
  }

  /// Delete course
  Future<bool> deleteCourse(String code) async {
    try {
      await _client.from('courses').delete().eq('code', code);
      _cachedCourses = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting course: $e');
      return false;
    }
  }

  // =====================================================
  // ROOMS
  // =====================================================

  /// Get all rooms
  Future<List<Room>> getRooms({bool forceRefresh = false}) async {
    if (_cachedRooms != null && !forceRefresh) {
      return _cachedRooms!;
    }

    try {
      final response = await _client
          .from('rooms')
          .select()
          .order('name', ascending: true);

      _cachedRooms = (response as List)
          .map((json) => Room(
                id: json['id'],
                name: json['name'],
              ))
          .toList();

      return _cachedRooms!;
    } catch (e) {
      debugPrint('Error fetching rooms: $e');
      return [];
    }
  }

  /// Get room by ID
  Future<Room?> getRoomById(String id) async {
    try {
      final response = await _client
          .from('rooms')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Room(
        id: response['id'],
        name: response['name'],
      );
    } catch (e) {
      debugPrint('Error fetching room: $e');
      return null;
    }
  }

  /// Add new room
  Future<String?> addRoom(Room room) async {
    try {
      final response = await _client.from('rooms').insert({
        'name': room.name,
      }).select().single();
      
      _cachedRooms = null;
      notifyListeners();
      return response['id'];
    } catch (e) {
      debugPrint('Error adding room: $e');
      return null;
    }
  }

  /// Update room
  Future<bool> updateRoom(String id, Room room) async {
    try {
      await _client.from('rooms').update({
        'name': room.name,
      }).eq('id', id);
      
      _cachedRooms = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating room: $e');
      return false;
    }
  }

  /// Delete room
  Future<bool> deleteRoom(String id) async {
    try {
      await _client.from('rooms').delete().eq('id', id);
      _cachedRooms = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting room: $e');
      return false;
    }
  }

  // =====================================================
  // STUDENTS
  // =====================================================

  /// Get all students
  Future<List<Student>> getStudents({bool forceRefresh = false}) async {
    if (_cachedStudents != null && !forceRefresh) {
      return _cachedStudents!;
    }

    try {
      final response = await _client
          .from('students')
          .select()
          .order('name', ascending: true);

      _cachedStudents = (response as List)
          .map((json) => Student.fromJson(json))
          .toList();

      return _cachedStudents!;
    } catch (e) {
      debugPrint('Error fetching students: $e');
      return [];
    }
  }

  /// Get students by batch ID
  Future<List<Student>> getStudentsByBatchId(String batchId) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('batch_id', batchId)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Student.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching students by batch: $e');
      return [];
    }
  }

  /// Get a specific student by ID
  Future<Student?> getStudentById(String studentId) async {
    try {
      final response = await _client
          .from('students')
          .select()
          .eq('student_id', studentId)
          .single();

      return Student.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching student: $e');
      return null;
    }
  }

  /// Get a specific teacher by ID
  Future<Teacher?> getTeacherById(String teacherId) async {
    try {
      final response = await _client
          .from('teachers')
          .select()
          .eq('id', teacherId)
          .single();

      return Teacher.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching teacher: $e');
      return null;
    }
  }

  /// Add new student
  Future<bool> addStudent(Student student) async {
    try {
      await _client.from('students').insert({
        'student_id': student.studentId,
        'name': student.name,
        'batch_id': student.batchId,
      });
      
      _cachedStudents = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding student: $e');
      return false;
    }
  }

  /// Update student
  Future<bool> updateStudent(String studentId, Student student) async {
    try {
      debugPrint('[SVC] updateStudent($studentId): name=${student.name}, notif=${student.notificationsEnabled}, email=${student.emailEnabled}');
      await _client.from('students').update({
        'name': student.name,
        'batch_id': student.batchId,
      }).eq('student_id', studentId);
      debugPrint('[SVC] updateStudent($studentId): DB update done (only name/batch_id sent)');
      _cachedStudents = null;
      // NOTE: Do NOT call notifyListeners() here — same reason as updateTeacher.
      return true;
    } catch (e) {
      debugPrint('[SVC] Error updating student: $e');
      return false;
    }
  }

  /// Delete student
  Future<bool> deleteStudent(String studentId) async {
    try {
      await _client.from('students').delete().eq('student_id', studentId);
      _cachedStudents = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting student: $e');
      return false;
    }
  }

  // =====================================================
  // TIMETABLE ENTRIES
  // =====================================================

  /// Get all timetable entries
  Future<List<TimetableEntry>> getAllTimetableEntries() async {
    try {
      final response = await _client
          .from('timetable_entries')
          .select()
          .order('day', ascending: true)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => _timetableEntryFromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching timetable entries: $e');
      return [];
    }
  }

  /// Get timetable entries for a teacher on a specific day
  Future<List<TimetableEntry>> getTeacherSchedule(
    String teacherInitial,
    String day,
  ) async {
    try {
      final response = await _client
          .from('timetable_entries')
          .select()
          .eq('teacher_initial', teacherInitial)
          .eq('day', day)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => _timetableEntryFromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching teacher schedule: $e');
      return [];
    }
  }

  /// Get timetable entries for a batch on a specific day
  Future<List<TimetableEntry>> getBatchSchedule(
    String batchId,
    String day,
  ) async {
    try {
      final response = await _client
          .from('timetable_entries')
          .select()
          .eq('batch_id', batchId)
          .eq('day', day)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => _timetableEntryFromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching batch schedule: $e');
      return [];
    }
  }

  /// Add new timetable entry
  Future<bool> addTimetableEntry(TimetableEntry entry) async {
    try {
      await _client.from('timetable_entries').insert({
        'day': entry.day,
        'batch_id': entry.batchId,
        'teacher_initial': entry.teacherInitial,
        'course_code': entry.courseCode,
        'type': entry.type,
        'group_name': entry.group,
        'room_id': entry.roomId,
        'mode': entry.mode,
        'start_time': entry.start,
        'end_time': entry.end,
        'is_cancelled': entry.isCancelled,
        'cancellation_reason': entry.cancellationReason,
      });
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding timetable entry: $e');
      return false;
    }
  }

  /// Bulk add timetable entries in a single insert
  Future<int> bulkAddTimetableEntries(List<TimetableEntry> entries) async {
    try {
      final rows = entries.map((entry) => {
        'day': entry.day,
        'batch_id': entry.batchId,
        'teacher_initial': entry.teacherInitial,
        'course_code': entry.courseCode,
        'type': entry.type,
        'group_name': entry.group,
        'room_id': entry.roomId,
        'mode': entry.mode,
        'start_time': entry.start,
        'end_time': entry.end,
        'is_cancelled': entry.isCancelled,
        'cancellation_reason': entry.cancellationReason,
      }).toList();

      await _client.from('timetable_entries').insert(rows);
      notifyListeners();
      return entries.length;
    } catch (e) {
      debugPrint('Error bulk adding timetable entries: $e');
      return 0;
    }
  }

  /// Update timetable entry
  Future<bool> updateTimetableEntry(String id, TimetableEntry entry) async {
    try {
      await _client.from('timetable_entries').update({
        'day': entry.day,
        'batch_id': entry.batchId,
        'teacher_initial': entry.teacherInitial,
        'course_code': entry.courseCode,
        'type': entry.type,
        'group_name': entry.group,
        'room_id': entry.roomId,
        'mode': entry.mode,
        'start_time': entry.start,
        'end_time': entry.end,
        'is_cancelled': entry.isCancelled,
        'cancellation_reason': entry.cancellationReason,
      }).eq('id', id);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating timetable entry: $e');
      return false;
    }
  }

  /// Delete timetable entry
  Future<bool> deleteTimetableEntry(String id) async {
    try {
      await _client.from('timetable_entries').delete().eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting timetable entry: $e');
      return false;
    }
  }

  /// Cancel a class
  Future<bool> cancelClass(String id, String reason) async {
    try {
      await _client.from('timetable_entries').update({
        'is_cancelled': true,
        'cancellation_reason': reason,
      }).eq('id', id);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error cancelling class: $e');
      return false;
    }
  }

  /// Uncancel a class
  Future<bool> uncancelClass(String id) async {
    try {
      await _client.from('timetable_entries').update({
        'is_cancelled': false,
        'cancellation_reason': null,
      }).eq('id', id);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error uncancelling class: $e');
      return false;
    }
  }

  /// Change room for a class
  Future<bool> changeRoom(String id, String newRoomId) async {
    try {
      await _client.from('timetable_entries').update({
        'room_id': newRoomId,
      }).eq('id', id);
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error changing room: $e');
      return false;
    }
  }

  /// Get free rooms at a specific day and time
  Future<List<Room>> getFreeRooms(String day, String time) async {
    try {
      // First get all rooms
      final allRooms = await getRooms();
      
      // Get occupied rooms at this time
      final response = await _client
          .from('timetable_entries')
          .select('room_id')
          .eq('day', day)
          .eq('is_cancelled', false)
          .lte('start_time', time)
          .gte('end_time', time);

      final occupiedRoomIds = (response as List)
          .map((json) => json['room_id'] as String?)
          .where((id) => id != null)
          .toSet();

      return allRooms
          .where((room) => !occupiedRoomIds.contains(room.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching free rooms: $e');
      return [];
    }
  }

  // =====================================================
    // TIMETABLE ENTRIES
  // =====================================================

    /// Get all timetable entries
    Future<List<TimetableEntry>> getTimetableEntries({bool forceRefresh = false}) async {
      try {
        final response = await _client
            .from('timetable_entries')
            .select()
            .order('day')
            .order('start_time');

        return (response as List)
            .map((json) => _timetableEntryFromJson(json))
            .toList();
      } catch (e) {
        debugPrint('Error fetching timetable entries: $e');
        return [];
      }
    }

    /// Cancel timetable entry
    Future<bool> cancelTimetableEntry(String id, String reason) async {
      try {
        await _client.from('timetable_entries').update({
          'is_cancelled': true,
          'cancellation_reason': reason,
        }).eq('id', id);
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error cancelling timetable entry: $e');
        return false;
      }
    }

    /// Uncancel timetable entry
    Future<bool> uncancelTimetableEntry(String id) async {
      try {
        await _client.from('timetable_entries').update({
          'is_cancelled': false,
          'cancellation_reason': null,
        }).eq('id', id);
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint('Error uncancelling timetable entry: $e');
        return false;
      }
    }

    // =====================================================
    // HELPER METHODS
    // =====================================================

  TimetableEntry _timetableEntryFromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      day: json['day'],
      batchId: json['batch_id'],
      teacherInitial: json['teacher_initial'],
      courseCode: json['course_code'],
      type: json['type'],
      group: json['group_name'],
      roomId: json['room_id'],
      mode: json['mode'],
      start: json['start_time'].toString().substring(0, 5), // Convert time to HH:mm
      end: json['end_time'].toString().substring(0, 5),
      isCancelled: json['is_cancelled'] ?? false,
      cancellationReason: json['cancellation_reason'],
    );
  }

  /// Get entry ID from entry details (for finding entries to update)
  Future<String?> getTimetableEntryId(TimetableEntry entry) async {
    try {
      final response = await _client
          .from('timetable_entries')
          .select('id')
          .eq('day', entry.day)
          .eq('batch_id', entry.batchId)
          .eq('teacher_initial', entry.teacherInitial)
          .eq('course_code', entry.courseCode)
          .eq('start_time', entry.start)
          .maybeSingle();

      return response?['id'];
    } catch (e) {
      debugPrint('Error getting timetable entry ID: $e');
      return null;
    }
  }

  // =====================================================
  // ANALYTICS
  // =====================================================

  /// Get analytics data for dashboard
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Fetch all timetable entries
      final entries = await getAllTimetableEntries();
      final teachers = await getTeachers();
      final batches = await getBatches();

      // Calculate statistics
      int totalClasses = entries.length;
      int cancelledClasses = entries.where((e) => e.isCancelled).length;
      int activeClasses = totalClasses - cancelledClasses;
      int onlineClasses = entries.where((e) => e.mode == 'Online').length;
      int onsiteClasses = entries.where((e) => e.mode == 'Onsite').length;

      // Classes by department
      Map<String, int> classesByDept = {};
      for (var entry in entries) {
        // Find batch
        final batch = batches.firstWhere(
          (b) => b.id == entry.batchId,
          orElse: () => Batch(id: '', name: 'Unknown', session: ''),
        );
        classesByDept[batch.name] = (classesByDept[batch.name] ?? 0) + 1;
      }

      // Classes by type
      Map<String, int> classesByType = {};
      for (var entry in entries) {
        classesByType[entry.type] = (classesByType[entry.type] ?? 0) + 1;
      }

      // Classes by day
      Map<String, int> classesByDay = {};
      for (var entry in entries) {
        classesByDay[entry.day] = (classesByDay[entry.day] ?? 0) + 1;
      }

      // Classes per teacher
      Map<String, int> classesPerTeacher = {};
      for (var entry in entries) {
        classesPerTeacher[entry.teacherInitial] =
            (classesPerTeacher[entry.teacherInitial] ?? 0) + 1;
      }

      // Average classes per teacher
      double avgClassesPerTeacher =
          teachers.isNotEmpty ? totalClasses / teachers.length : 0;

      return {
        'totalClasses': totalClasses,
        'cancelledClasses': cancelledClasses,
        'activeClasses': activeClasses,
        'onlineClasses': onlineClasses,
        'onsiteClasses': onsiteClasses,
        'classesByDept': classesByDept,
        'classesByType': classesByType,
        'classesByDay': classesByDay,
        'classesPerTeacher': classesPerTeacher,
        'avgClassesPerTeacher': avgClassesPerTeacher.toStringAsFixed(2),
        'totalTeachers': teachers.length,
        'totalBatches': batches.length,
      };
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
      return {};
    }
  }

  // =====================================================
  // APPOINTMENT SYSTEM
  // =====================================================

  /// Create a new appointment request (student -> teacher)
  Future<Appointment> createAppointment(Appointment appt) async {
    try {
      final response = await _client
          .from('appointments')
          .insert(appt.toInsertJson())
          .select()
          .single();
      return Appointment.fromJson(response);
    } catch (e) {
      debugPrint('Error creating appointment: $e');
      rethrow;
    }
  }

  /// Get all appointments for a teacher (by initial)
  Future<List<Appointment>> getTeacherAppointments(String teacherInitial) async {
    try {
      final response = await _client
          .from('appointments')
          .select()
          .eq('teacher_initial', teacherInitial)
          .order('date', ascending: true)
          .order('time', ascending: true);
      return (response as List).map((e) => Appointment.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching teacher appointments: $e');
      return [];
    }
  }

  /// Get all appointments made by a student
  Future<List<Appointment>> getStudentAppointments(String studentId) async {
    try {
      final response = await _client
          .from('appointments')
          .select()
          .eq('student_id', studentId)
          .order('date', ascending: true)
          .order('time', ascending: true);
      return (response as List).map((e) => Appointment.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching student appointments: $e');
      return [];
    }
  }

  /// Accept or reject an appointment (teacher action)
  Future<void> updateAppointmentStatus(
      String appointmentId, String status, {String? remarks}) async {
    try {
      final data = <String, dynamic>{'status': status};
      if (remarks != null) data['teacher_remarks'] = remarks;
      await _client.from('appointments').update(data).eq('id', appointmentId);
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      rethrow;
    }
  }

  /// Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    try {
      await _client.from('appointments').delete().eq('id', appointmentId);
    } catch (e) {
      debugPrint('Error deleting appointment: $e');
      rethrow;
    }
  }

  // =====================================================
  // PERMISSION MANAGEMENT (Super Admin)
  // =====================================================

  /// Toggle notifications permission for a teacher
  Future<void> setTeacherNotificationsEnabled(String teacherId, bool enabled) async {
    try {
      debugPrint('[SVC] setTeacherNotificationsEnabled($teacherId, $enabled)');
      await _client.from('teachers').update({
        'notifications_enabled': enabled,
      }).eq('id', teacherId);
      debugPrint('[SVC] setTeacherNotificationsEnabled: DB updated OK');
      _cachedTeachers = null;
    } catch (e) {
      debugPrint('[SVC] Error setting teacher notifications: $e');
      rethrow;
    }
  }

  /// Toggle email permission for a teacher
  Future<void> setTeacherEmailEnabled(String teacherId, bool enabled) async {
    try {
      debugPrint('[SVC] setTeacherEmailEnabled($teacherId, $enabled)');
      await _client.from('teachers').update({
        'email_enabled': enabled,
      }).eq('id', teacherId);
      debugPrint('[SVC] setTeacherEmailEnabled: DB updated OK');
      _cachedTeachers = null;
    } catch (e) {
      debugPrint('[SVC] Error setting teacher email: $e');
      rethrow;
    }
  }

  /// Toggle notifications permission for a student
  Future<void> setStudentNotificationsEnabled(String studentId, bool enabled) async {
    try {
      debugPrint('[SVC] setStudentNotificationsEnabled($studentId, $enabled)');
      await _client.from('students').update({
        'notifications_enabled': enabled,
      }).eq('student_id', studentId);
      debugPrint('[SVC] setStudentNotificationsEnabled: DB updated OK');
      _cachedStudents = null;
    } catch (e) {
      debugPrint('[SVC] Error setting student notifications: $e');
      rethrow;
    }
  }

  /// Toggle email permission for a student
  Future<void> setStudentEmailEnabled(String studentId, bool enabled) async {
    try {
      debugPrint('[SVC] setStudentEmailEnabled($studentId, $enabled)');
      await _client.from('students').update({
        'email_enabled': enabled,
      }).eq('student_id', studentId);
      debugPrint('[SVC] setStudentEmailEnabled: DB updated OK');
      _cachedStudents = null;
    } catch (e) {
      debugPrint('[SVC] Error setting student email: $e');
      rethrow;
    }
  }

  /// Bulk-enable notifications for all students in a batch
  Future<void> setBatchNotificationsEnabled(String batchId, bool enabled) async {
    try {
      await _client.from('students').update({
        'notifications_enabled': enabled,
      }).eq('batch_id', batchId);
      _cachedStudents = null;
    } catch (e) {
      debugPrint('Error batch-updating notifications: $e');
      rethrow;
    }
  }

  /// Bulk-enable email for all students in a batch
  Future<void> setBatchEmailEnabled(String batchId, bool enabled) async {
    try {
      await _client.from('students').update({
        'email_enabled': enabled,
      }).eq('batch_id', batchId);
      _cachedStudents = null;
    } catch (e) {
      debugPrint('Error batch-updating email: $e');
      rethrow;
    }
  }

  // =====================================================
  // IN-APP NOTIFICATIONS
  // =====================================================

  /// Get notifications for a specific recipient
  Future<List<AppNotification>> getNotifications({
    required String recipientType,
    required String recipientId,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('recipient_type', recipientType)
          .eq('recipient_id', recipientId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (response as List).map((e) => AppNotification.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount({
    required String recipientType,
    required String recipientId,
  }) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('recipient_type', recipientType)
          .eq('recipient_id', recipientId)
          .eq('is_read', false);
      return (response as List).length;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark a notification as read
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Error marking notification read: $e');
    }
  }

  /// Mark all notifications as read for a recipient
  Future<void> markAllNotificationsRead({
    required String recipientType,
    required String recipientId,
  }) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_type', recipientType)
          .eq('recipient_id', recipientId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all read: $e');
    }
  }

  /// Create a notification manually (for appointment events, etc.)
  Future<void> createNotification(AppNotification notification) async {
    try {
      await _client.from('notifications').insert(notification.toInsertJson());
    } catch (e) {
      debugPrint('Error creating notification: $e');
    }
  }

  /// Subscribe to realtime notifications (returns a RealtimeChannel)
  /// [channelSuffix] makes channel names unique so bell & screen don't conflict.
  RealtimeChannel subscribeToNotifications({
    required String recipientType,
    required String recipientId,
    required void Function(AppNotification) onNewNotification,
    String channelSuffix = '',
  }) {
    final suffix = channelSuffix.isNotEmpty ? '_$channelSuffix' : '_${DateTime.now().millisecondsSinceEpoch}';
    // Sanitise channel name — only allow alphanumerics, hyphens, underscores
    final safeName = 'notifications_${recipientType}_$recipientId$suffix'
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final channel = _client
        .channel(safeName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          // No server-side filter — trigger-inserted rows (used for super_admin)
          // may not be delivered when a PostgresChangeFilter is applied.
          // We filter client-side instead.
          callback: (payload) {
            try {
              debugPrint('[REALTIME-NOTIF] INSERT on notifications for $recipientType');
              final newRec = payload.newRecord;
              if (newRec.isEmpty) {
                // Trigger-inserted rows sometimes arrive with empty newRecord;
                // treat as a signal to reload count from DB.
                onNewNotification(AppNotification(
                  id: '', type: '', title: '', body: '', createdAt: '',
                  recipientType: recipientType, recipientId: recipientId,
                ));
                return;
              }
              final notif = AppNotification.fromJson(newRec);
              // Filter client-side by recipientType and recipientId
              if (notif.recipientType == recipientType &&
                  notif.recipientId == recipientId) {
                onNewNotification(notif);
              }
            } catch (e) {
              debugPrint('Error processing realtime notification: $e');
              // On parse failure, still signal so the bell can reload count
              onNewNotification(AppNotification(
                id: '', type: '', title: '', body: '', createdAt: '',
                recipientType: recipientType, recipientId: recipientId,
              ));
            }
          },
        )
        .subscribe((status, [err]) {
          debugPrint('[REALTIME-NOTIF] Channel $safeName status: $status ${err ?? ""}');
        });
    return channel;
  }

  /// Unsubscribe from realtime channel
  Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }

  /// Invoke Supabase Edge Function to send email.
  /// Returns a short error string on failure, or null on success.
  Future<String?> invokeEmailFunction({
    required String functionName,
    required Map<String, dynamic> body,
  }) async {
    try {
      debugPrint('[EMAIL] >>> Invoking edge function: $functionName');
      debugPrint('[EMAIL] >>> Payload: $body');
      final response = await _client.functions.invoke(
        functionName,
        body: body,
      );
      debugPrint('[EMAIL] <<< Response status: ${response.status}');
      debugPrint('[EMAIL] <<< Response data: ${response.data}');

      // Parse the response to check for warnings (e.g. 0 recipients)
      if (response.data is Map) {
        final data = response.data as Map;
        final sent = data['sent'] ?? 0;
        final total = data['total'] ?? 0;
        final warning = data['warning'];
        final errors = data['errors'];
        debugPrint('[EMAIL] <<< Sent: $sent/$total');
        if (warning != null) {
          debugPrint('[EMAIL] !!! WARNING from edge function: $warning');
          return 'No recipients: $warning';
        }
        if (errors != null) {
          debugPrint('[EMAIL] !!! Partial failures: $errors');
          return 'Sent $sent/$total emails. Errors: $errors';
        }
        if (sent == 0 && total == 0) {
          return 'No email recipients found. Check email_enabled and email fields.';
        }
      }
      return null; // success
    } on FunctionException catch (e) {
      debugPrint('[EMAIL] !!! FunctionException invoking $functionName');
      debugPrint('[EMAIL] !!! Status: ${e.status}');
      debugPrint('[EMAIL] !!! Details: ${e.details}');
      debugPrint('[EMAIL] !!! reasonPhrase: ${e.reasonPhrase}');
      if (e.status == 404) {
        return 'Edge function not deployed. Deploy with: supabase functions deploy send-notification-email';
      }
      return e.reasonPhrase ?? 'Email function error (status ${e.status})';
    } catch (e) {
      debugPrint('[EMAIL] !!! Error invoking edge function $functionName: $e');
      return 'Email error: $e';
    }
  }

  /// Trigger email notification for a timetable change.
  /// Returns null on success, or an error message string on failure.
  Future<String?> sendTimetableChangeEmail({
    required String changeType,
    required String courseCode,
    required String teacherInitial,
    required String batchId,
    required String details,
  }) async {
    debugPrint('[EMAIL] sendTimetableChangeEmail called: type=$changeType, course=$courseCode, teacher=$teacherInitial, batch=$batchId');
    final err = await invokeEmailFunction(
      functionName: 'send-notification-email',
      body: {
        'change_type': changeType,
        'course_code': courseCode,
        'teacher_initial': teacherInitial,
        'batch_id': batchId,
        'details': details,
      },
    );
    if (err != null) {
      debugPrint('[EMAIL] !!! sendTimetableChangeEmail FAILED: $err');
    } else {
      debugPrint('[EMAIL] sendTimetableChangeEmail completed successfully');
    }
    return err;
  }

  // =====================================================
  // TEACHER COURSE PREFERENCES
  // =====================================================

  /// Get all course preferences
  Future<List<TeacherCoursePreference>> getAllCoursePreferences() async {
    try {
      final response = await _client
          .from('teacher_course_preferences')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => TeacherCoursePreference.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all course preferences: $e');
      return [];
    }
  }

  /// Get course preferences for a specific teacher
  Future<List<TeacherCoursePreference>> getTeacherCoursePreferences(
      String teacherInitial) async {
    try {
      final response = await _client
          .from('teacher_course_preferences')
          .select()
          .eq('teacher_initial', teacherInitial)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => TeacherCoursePreference.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching teacher course preferences: $e');
      return [];
    }
  }

  /// Add a new course preference
  Future<TeacherCoursePreference?> addCoursePreference(
      TeacherCoursePreference pref) async {
    try {
      final response = await _client
          .from('teacher_course_preferences')
          .insert(pref.toInsertJson())
          .select()
          .single();
      notifyListeners();
      return TeacherCoursePreference.fromJson(response);
    } catch (e) {
      debugPrint('Error adding course preference: $e');
      return null;
    }
  }

  /// Update a course preference
  Future<bool> updateCoursePreference(
      String id, TeacherCoursePreference pref) async {
    try {
      await _client
          .from('teacher_course_preferences')
          .update(pref.toInsertJson())
          .eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating course preference: $e');
      return false;
    }
  }

  /// Delete a course preference
  Future<bool> deleteCoursePreference(String id) async {
    try {
      await _client.from('teacher_course_preferences').delete().eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting course preference: $e');
      return false;
    }
  }

  /// Update preference status (super admin: approve/reject)
  Future<bool> updateCoursePreferenceStatus(String id, String status) async {
    try {
      await _client
          .from('teacher_course_preferences')
          .update({'status': status})
          .eq('id', id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating preference status: $e');
      return false;
    }
  }

  // =====================================================
  // AI ROUTINE GENERATION — BULK OPS
  // =====================================================

  /// Replace entire timetable with AI-generated entries.
  /// Deletes all existing entries and inserts the new ones.
  Future<bool> replaceAllTimetableEntries(
      List<Map<String, dynamic>> entries) async {
    try {
      // Delete all existing entries
      await _client.from('timetable_entries').delete().neq('id', '00000000-0000-0000-0000-000000000000');

      // Insert all new entries
      if (entries.isNotEmpty) {
        await _client.from('timetable_entries').insert(entries);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error replacing timetable entries: $e');
      return false;
    }
  }

  /// Insert AI-generated entries (append mode — keeps existing, adds new).
  Future<bool> appendTimetableEntries(
      List<Map<String, dynamic>> entries) async {
    try {
      if (entries.isNotEmpty) {
        await _client.from('timetable_entries').insert(entries);
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error appending timetable entries: $e');
      return false;
    }
  }

  /// Save a routine generation history record
  Future<bool> saveRoutineGeneration({
    required String generatedBy,
    required String routineTitle,
    required int entryCount,
    required String status,
    String? notes,
  }) async {
    try {
      await _client.from('routine_generations').insert({
        'generated_by': generatedBy,
        'routine_title': routineTitle,
        'entry_count': entryCount,
        'status': status,
        'notes': notes,
      });
      return true;
    } catch (e) {
      debugPrint('Error saving routine generation: $e');
      return false;
    }
  }

  /// Get routine generation history
  Future<List<Map<String, dynamic>>> getRoutineGenerations() async {
    try {
      final response = await _client
          .from('routine_generations')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error fetching routine generations: $e');
      return [];
    }
  }
}
