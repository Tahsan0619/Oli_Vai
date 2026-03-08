import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/app_meta.dart';
import '../models/notification_model.dart';
import '../models/teacher.dart';
import '../models/teacher_course_preference.dart';
import '../models/batch.dart';
import '../models/course.dart';
import '../models/room.dart';
import '../models/student.dart';
import '../models/timetable_entry.dart';
import 'supabase_service.dart';

/// Data Repository for managing app data (Supabase-backed)
class DataRepository extends ChangeNotifier {
  final SupabaseService _supabaseService;

  final AppMeta _meta = AppMeta(
    version: '1.0.0',
    updatedAt: '2026-01-21T10:00:00+06:00',
    tz: 'Asia/Dhaka',
    daysOff: ['Fri'],
    department: 'Department of Educational Technology and Engineering',
    university: 'University of Frontier Technology, Bangladesh',
    slotLabels: [
      '08:00-09:30',
      '09:30-11:00',
      '11:00-12:30',
      '12:30-14:00',
      '14:00-15:30',
      '15:30-17:00',
    ],
  );

  // Cached data from Supabase
  List<Teacher> _teachers = [];
  List<Batch> _batches = [];
  List<Course> _courses = [];
  List<Room> _rooms = [];
  List<Student> _students = [];
  List<TimetableEntry> _timetableEntries = [];
  List<TeacherCoursePreference> _coursePreferences = [];
  
  // Map to store timetable entry IDs (for updates)
  final Map<String, String> _entryIdMap = {}; // key -> entry_id

  DataRepository(this._supabaseService);

  /// Legacy compatibility for screens expecting AppData
  AppData? get data => AppData(
        meta: _meta,
        teachers: _teachers,
        batches: _batches,
        courses: _courses,
        rooms: _rooms,
        students: _students,
        timetable: _timetableEntries,
        admins: const [],
      );

  /// Load data from Supabase
  Future<void> load() async {
    try {
      // Load all data from Supabase in parallel
      final results = await Future.wait([
        _supabaseService.getTeachers(forceRefresh: true),
        _supabaseService.getBatches(forceRefresh: true),
        _supabaseService.getCourses(forceRefresh: true),
        _supabaseService.getRooms(forceRefresh: true),
        _supabaseService.getStudents(forceRefresh: true),
        _supabaseService.getTimetableEntries(forceRefresh: true),
        _supabaseService.getAllCoursePreferences(),
      ]);

      _teachers = results[0] as List<Teacher>;
      _batches = results[1] as List<Batch>;
      _courses = results[2] as List<Course>;
      _rooms = results[3] as List<Room>;
      _students = results[4] as List<Student>;
      _timetableEntries = results[5] as List<TimetableEntry>;
      _coursePreferences = results[6] as List<TeacherCoursePreference>;

      // Build entry ID map for efficient lookups
      _buildEntryIdMap();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data from Supabase: $e');
    }
  }

  /// Build entry ID map for timetable updates
  Future<void> _buildEntryIdMap() async {
    for (var entry in _timetableEntries) {
      final key = _getEntryKey(entry);
      final id = await _supabaseService.getTimetableEntryId(entry);
      if (id != null) {
        _entryIdMap[key] = id;
      }
    }
  }

  /// Generate unique key for timetable entry
  String _getEntryKey(TimetableEntry entry) {
    return '${entry.day}_${entry.batchId}_${entry.teacherInitial}_${entry.courseCode}_${entry.start}';
  }

  /// Get teacher entries for a specific day
  List<TimetableEntry> teacherEntriesForDay(String initial, String day) {
    final list = _timetableEntries
        .where((e) => e.teacherInitial == initial && e.day == day)
        .toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  /// Get all teacher entries for the entire week
  Map<String, List<TimetableEntry>> teacherWeeklyEntries(String initial) {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final Map<String, List<TimetableEntry>> weekMap = {};
    
    for (final day in days) {
      weekMap[day] = teacherEntriesForDay(initial, day);
    }
    return weekMap;
  }

  /// Get batch entries for a specific day
  List<TimetableEntry> batchEntriesForDay(String batchId, String day) {
    final list = _timetableEntries
        .where((e) => e.batchId == batchId && e.day == day)
        .toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  /// Get teacher by initial
  Teacher? teacherByInitial(String initial) {
    try {
      return _teachers.firstWhere((t) => t.initial == initial);
    } catch (e) {
      return null;
    }
  }

  /// Get batch by ID
  Batch? batchById(String id) {
    try {
      return _batches.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get course by code
  Course? courseByCode(String code) {
    try {
      return _courses.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get room by ID
  Room? roomById(String? id) {
    if (id == null) return null;
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get student by ID
  Student? studentById(String sid) {
    try {
      return _students.firstWhere((s) => s.studentId == sid);
    } catch (e) {
      return null;
    }
  }

  /// Get all allowed teacher initials
  Set<String> allowedTeacherInitials() {
    return _teachers.map((t) => t.initial).toSet();
  }

  /// Cancel a class
  Future<void> cancelClass(TimetableEntry entry, String reason) async {
    final key = _getEntryKey(entry);
    final entryId = _entryIdMap[key];
    if (entryId != null) {
      await _supabaseService.cancelTimetableEntry(entryId, reason);
      await load(); // Reload data
    }
  }

  /// Un-cancel a class
  Future<void> uncancelClass(TimetableEntry entry) async {
    final key = _getEntryKey(entry);
    final entryId = _entryIdMap[key];
    if (entryId != null) {
      await _supabaseService.uncancelTimetableEntry(entryId);
      await load(); // Reload data
    }
  }

  /// Change room for a class
  Future<void> changeRoom(TimetableEntry entry, String newRoomId) async {
    final key = _getEntryKey(entry);
    final entryId = _entryIdMap[key];
    if (entryId != null) {
      final updated = entry.copyWith(roomId: newRoomId);
      await _supabaseService.updateTimetableEntry(entryId, updated);
      await load(); // Reload data
    }
  }

  /// Reschedule class (change time, day, type, and mode)
  Future<void> rescheduleClass(
    TimetableEntry entry, {
    String? newStart,
    String? newEnd,
    String? newDay,
    String? newType,
    String? newMode,
  }) async {
    final key = _getEntryKey(entry);
    final entryId = _entryIdMap[key];
    if (entryId != null) {
      final updated = entry.copyWith(
        start: newStart,
        end: newEnd,
        day: newDay,
        type: newType,
        mode: newMode,
      );
      await _supabaseService.updateTimetableEntry(entryId, updated);
      await load(); // Reload data
    }
  }

  /// Add new timetable entry (super admin only)
  Future<void> addTimetableEntry(TimetableEntry entry) async {
    await _supabaseService.addTimetableEntry(entry);
    final batchName = batchById(entry.batchId)?.name ?? entry.batchId;
    // Send in-app notification to the assigned teacher
    await _supabaseService.createNotification(AppNotification(
      id: '',
      type: 'general',
      title: 'New Class Assigned',
      body: 'You have been assigned ${entry.courseCode} on ${entry.day} (${entry.start}-${entry.end}) for batch $batchName.',
      recipientType: 'teacher',
      recipientId: entry.teacherInitial,
      createdAt: '',
    ));
    // Notify all students in the batch
    final batchStudents = await _supabaseService.getStudentsByBatchId(entry.batchId);
    for (final student in batchStudents) {
      await _supabaseService.createNotification(AppNotification(
        id: '',
        type: 'general',
        title: 'New Class Added',
        body: '${entry.courseCode} has been added to your schedule on ${entry.day} (${entry.start}-${entry.end}).',
        recipientType: 'student',
        recipientId: student.studentId,
        createdAt: '',
      ));
    }
    // Send email notification
    await _supabaseService.sendTimetableChangeEmail(
      changeType: 'class_assigned',
      courseCode: entry.courseCode,
      teacherInitial: entry.teacherInitial,
      batchId: entry.batchId,
      details: 'New class assigned: ${entry.day} ${entry.start}-${entry.end} (${entry.mode}) for batch $batchName.',
    );
    await load(); // Reload data
  }

  /// Update an existing timetable entry
  Future<void> updateTimetableEntry(TimetableEntry original, TimetableEntry updated) async {
    final key = _getEntryKey(original);
    final entryId = _entryIdMap[key];
    if (entryId != null) {
      final batchName = batchById(updated.batchId)?.name ?? updated.batchId;
      await _supabaseService.updateTimetableEntry(entryId, updated);
      // Notify the teacher about the update
      await _supabaseService.createNotification(AppNotification(
        id: '',
        type: 'general',
        title: 'Class Schedule Updated',
        body: '${updated.courseCode} on ${updated.day} (${updated.start}-${updated.end}) for batch $batchName has been updated.',
        recipientType: 'teacher',
        recipientId: updated.teacherInitial,
        createdAt: '',
      ));
      // If the teacher changed, also notify the old teacher
      if (original.teacherInitial != updated.teacherInitial) {
        await _supabaseService.createNotification(AppNotification(
          id: '',
          type: 'general',
          title: 'Class Removed',
          body: '${original.courseCode} on ${original.day} (${original.start}-${original.end}) has been reassigned from you.',
          recipientType: 'teacher',
          recipientId: original.teacherInitial,
          createdAt: '',
        ));
      }
      // Notify all students in the batch about the update
      final batchStudents = await _supabaseService.getStudentsByBatchId(updated.batchId);
      for (final student in batchStudents) {
        await _supabaseService.createNotification(AppNotification(
          id: '',
          type: 'general',
          title: 'Class Schedule Updated',
          body: '${updated.courseCode} on ${updated.day} (${updated.start}-${updated.end}) has been updated.',
          recipientType: 'student',
          recipientId: student.studentId,
          createdAt: '',
        ));
      }
      // If batch changed, also notify students in the old batch
      if (original.batchId != updated.batchId) {
        final oldBatchStudents = await _supabaseService.getStudentsByBatchId(original.batchId);
        for (final student in oldBatchStudents) {
          await _supabaseService.createNotification(AppNotification(
            id: '',
            type: 'general',
            title: 'Class Removed From Schedule',
            body: '${original.courseCode} on ${original.day} (${original.start}-${original.end}) has been removed from your batch schedule.',
            recipientType: 'student',
            recipientId: student.studentId,
            createdAt: '',
          ));
        }
      }
      // Send email notification
      await _supabaseService.sendTimetableChangeEmail(
        changeType: 'class_updated',
        courseCode: updated.courseCode,
        teacherInitial: updated.teacherInitial,
        batchId: updated.batchId,
        details: 'Class updated: ${updated.day} ${updated.start}-${updated.end} (${updated.mode}) for batch $batchName.',
      );
      await load(); // Reload data
    }
  }

  /// Remove timetable entry (super admin only)
  Future<void> removeTimetableEntry(TimetableEntry entry) async {
    final key = _getEntryKey(entry);
    final entryId = _entryIdMap[key];
    if (entryId != null) {
      await _supabaseService.deleteTimetableEntry(entryId);
      final batchName = batchById(entry.batchId)?.name ?? entry.batchId;
      // Notify the teacher about the removal
      await _supabaseService.createNotification(AppNotification(
        id: '',
        type: 'general',
        title: 'Class Removed',
        body: '${entry.courseCode} on ${entry.day} (${entry.start}-${entry.end}) for batch $batchName has been removed from the schedule.',
        recipientType: 'teacher',
        recipientId: entry.teacherInitial,
        createdAt: '',
      ));
      // Notify all students in the batch
      final batchStudents = await _supabaseService.getStudentsByBatchId(entry.batchId);
      for (final student in batchStudents) {
        await _supabaseService.createNotification(AppNotification(
          id: '',
          type: 'general',
          title: 'Class Removed From Schedule',
          body: '${entry.courseCode} on ${entry.day} (${entry.start}-${entry.end}) has been removed from your schedule.',
          recipientType: 'student',
          recipientId: student.studentId,
          createdAt: '',
        ));
      }
      await load(); // Reload data
    }
  }

  /// Get all timetable entries (including modifications)
  List<TimetableEntry> getAllTimetableEntries() {
     return _timetableEntries;
  }

  /// Get room entries for a specific day and time
  List<TimetableEntry> roomEntriesForDayTime(String roomId, String day, String timeSlot) {
    // Parse timeSlot (e.g., "08:30-10:00")
    final parts = timeSlot.split('-');
    if (parts.length != 2) return const [];
    
    final slotStart = parts[0];
    final slotEnd = parts[1];
    
     final list = _timetableEntries.where((e) {
      if (e.roomId != roomId || e.day != day || e.isCancelled) return false;
      
      // Check if times overlap
      return e.start == slotStart || (e.start.compareTo(slotStart) < 0 && e.end.compareTo(slotStart) > 0);
    }).toList();
    
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  /// Get teacher by ID (using initial as ID)
  Teacher? teacherById(String? id) {
     if (id == null) return null;
    return teacherByInitial(id);
  }

  /// Get course by ID (using code as ID)
  Course? courseById(String? id) {
       if (id == null) return null;
    return courseByCode(id);
  }

  // =====================================================
  // TEACHER COURSE PREFERENCES
  // =====================================================

  /// All course preferences
  List<TeacherCoursePreference> get coursePreferences => _coursePreferences;

  /// Get preferences for a specific teacher
  List<TeacherCoursePreference> preferencesForTeacher(String teacherInitial) {
    return _coursePreferences
        .where((p) => p.teacherInitial == teacherInitial)
        .toList();
  }

  /// Get approved preferences (for AI generation)
  List<TeacherCoursePreference> get approvedPreferences {
    return _coursePreferences.where((p) => p.status == 'approved').toList();
  }

  /// Get pending preferences (for super admin review)
  List<TeacherCoursePreference> get pendingPreferences {
    return _coursePreferences.where((p) => p.status == 'pending').toList();
  }
}
