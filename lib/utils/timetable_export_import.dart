import 'dart:convert';
import '../models/timetable_entry.dart';

/// Utility class for exporting and importing timetable data
class TimetableExportImport {
  /// Convert timetable entries to JSON format for export
  static String toJSON(List<TimetableEntry> entries) {
    final json = entries.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'entries': json,
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  /// Convert timetable entries to CSV format for export
  static String toCSV(List<TimetableEntry> entries) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('day,batch_id,teacher_initial,course_code,type,mode,start,end,room_id,group,is_cancelled,cancellation_reason');
    
    // Data rows
    for (var entry in entries) {
      buffer.writeln([
        entry.day,
        entry.batchId,
        entry.teacherInitial,
        entry.courseCode,
        entry.type,
        entry.mode,
        entry.start,
        entry.end,
        entry.roomId ?? '',
        entry.group ?? '',
        entry.isCancelled.toString(),
        entry.cancellationReason ?? '',
      ].map((v) => '"$v"').join(','));
    }
    
    return buffer.toString();
  }

  /// Parse CSV string into timetable entries
  static List<TimetableEntry> fromCSV(String csv) {
    final lines = csv.split(RegExp(r'\r?\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return [];

    // Parse header to determine column order
    final header = _parseCSVRow(lines[0]);
    final colMap = <String, int>{};
    for (int i = 0; i < header.length; i++) {
      colMap[_normalizeKey(header[i])] = i;
    }

    final entries = <TimetableEntry>[];
    for (int i = 1; i < lines.length; i++) {
      final cols = _parseCSVRow(lines[i]);
      if (cols.length < 8) continue; // skip malformed rows

      String col(String key) {
        final idx = colMap[key];
        if (idx == null || idx >= cols.length) return '';
        return cols[idx];
      }

      entries.add(TimetableEntry(
        day: col('day'),
        batchId: col('batch_id'),
        teacherInitial: col('teacher_initial'),
        courseCode: col('course_code'),
        type: col('type'),
        mode: col('mode').isEmpty ? 'Offline' : col('mode'),
        start: col('start'),
        end: col('end'),
        roomId: col('room_id').isEmpty ? null : col('room_id'),
        group: col('group').isEmpty ? null : col('group'),
        isCancelled: col('is_cancelled').toLowerCase() == 'true',
        cancellationReason: col('cancellation_reason').isEmpty ? null : col('cancellation_reason'),
      ));
    }
    return entries;
  }

  /// Parse JSON string into timetable entries (handles both snake_case and camelCase keys)
  static List<TimetableEntry> fromJSON(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    final List<dynamic> entriesJson = decoded['entries'];
    return entriesJson.map((e) {
      final map = Map<String, dynamic>.from(e);
      // Normalize camelCase keys to snake_case for TimetableEntry.fromJson
      final normalized = <String, dynamic>{};
      for (final entry in map.entries) {
        normalized[_normalizeKey(entry.key)] = entry.value;
      }
      return TimetableEntry.fromJson(normalized);
    }).toList();
  }

  /// Parse a single CSV row handling quoted fields
  static List<String> _parseCSVRow(String row) {
    final result = <String>[];
    int i = 0;
    while (i < row.length) {
      if (row[i] == '"') {
        // Quoted field
        final end = row.indexOf('"', i + 1);
        if (end == -1) {
          result.add(row.substring(i + 1));
          break;
        }
        result.add(row.substring(i + 1, end));
        i = end + 1;
        if (i < row.length && row[i] == ',') i++; // skip comma
      } else {
        final end = row.indexOf(',', i);
        if (end == -1) {
          result.add(row.substring(i));
          break;
        }
        result.add(row.substring(i, end));
        i = end + 1;
      }
    }
    return result;
  }

  /// Normalize key: camelCase or mixed to snake_case
  static String _normalizeKey(String key) {
    final k = key.trim();
    // Map known camelCase variants to snake_case
    const aliases = {
      'batchid': 'batch_id',
      'batch_id': 'batch_id',
      'teacherinitial': 'teacher_initial',
      'teacher_initial': 'teacher_initial',
      'coursecode': 'course_code',
      'course_code': 'course_code',
      'roomid': 'room_id',
      'room_id': 'room_id',
      'iscancelled': 'is_cancelled',
      'is_cancelled': 'is_cancelled',
      'cancellationreason': 'cancellation_reason',
      'cancellation_reason': 'cancellation_reason',
      'groupname': 'group',
      'group_name': 'group',
      'group': 'group',
      'starttime': 'start',
      'start_time': 'start',
      'start': 'start',
      'endtime': 'end',
      'end_time': 'end',
      'end': 'end',
      'day': 'day',
      'type': 'type',
      'mode': 'mode',
    };
    return aliases[k.toLowerCase()] ?? k;
  }

  /// Get template for JSON import
  static String getJSONTemplate() {
    final template = [
      {
        'day': 'Mon',
        'batch_id': '<batch-uuid>',
        'teacher_initial': 'AR',
        'course_code': 'ET 401',
        'type': 'Lecture',
        'mode': 'Offline',
        'start': '09:00',
        'end': '10:15',
        'room_id': '<room-uuid>',
        'group': null,
        'is_cancelled': false,
        'cancellation_reason': null,
      },
    ];

    return const JsonEncoder.withIndent('  ').convert({
      'entries': template,
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  /// Get template for CSV import
  static String getCSVTemplate() {
    return 'day,batch_id,teacher_initial,course_code,type,mode,start,end,room_id,group,is_cancelled,cancellation_reason\n'
        '"Mon","<batch-uuid>","AR","ET 401","Lecture","Offline","09:00","10:15","<room-uuid>","","false",""\n'
        '"Tue","<batch-uuid>","FI","PROG 111","Tutorial","Offline","10:15","11:30","<room-uuid>","G1","false",""';
  }

  /// Validate timetable entries
  static List<String> validateEntries(List<TimetableEntry> entries) {
    final errors = <String>[];
    
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      
      if (entry.day.isEmpty) {
        errors.add('Row ${i + 1}: Day is required');
      }
      
      if (entry.batchId.isEmpty) {
        errors.add('Row ${i + 1}: Batch ID is required');
      }
      
      if (entry.teacherInitial.isEmpty) {
        errors.add('Row ${i + 1}: Teacher initial is required');
      }
      
      if (entry.courseCode.isEmpty) {
        errors.add('Row ${i + 1}: Course code is required');
      }
      
      final validTypes = ['Lecture', 'Tutorial', 'Sessional', 'Online'];
      if (!validTypes.contains(entry.type)) {
        errors.add('Row ${i + 1}: Invalid type "${entry.type}". Must be: ${validTypes.join(', ')}');
      }
      
      final validModes = ['Onsite', 'Online', 'Offline'];
      if (!validModes.contains(entry.mode)) {
        errors.add('Row ${i + 1}: Invalid mode "${entry.mode}". Must be: ${validModes.join(', ')}');
      }
      
      if (!_isValidTime(entry.start)) {
        errors.add('Row ${i + 1}: Invalid start time "${entry.start}". Use HH:mm format');
      }
      
      if (!_isValidTime(entry.end)) {
        errors.add('Row ${i + 1}: Invalid end time "${entry.end}". Use HH:mm format');
      }
    }
    
    return errors;
  }

  static bool _isValidTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return false;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
    } catch (e) {
      return false;
    }
  }
}
