import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with Groq AI API to generate timetable routines.
class GroqService {
  // Loaded from .env file at runtime.
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  /// Generate a timetable routine using Groq AI.
  ///
  /// [preferences] — list of teacher course preference maps
  /// [batches] — list of batch maps {id, name, session}
  /// [rooms] — list of room maps {id, name}
  /// [teachers] — list of teacher maps {initial, name, designation}
  /// [courses] — list of course maps {code, title}
  /// [constraints] — optional dict of scheduling constraints
  ///
  /// Returns a list of timetable entry maps ready to insert into the DB.
  static Future<List<Map<String, dynamic>>> generateRoutine({
    required List<Map<String, dynamic>> preferences,
    required List<Map<String, dynamic>> batches,
    required List<Map<String, dynamic>> rooms,
    required List<Map<String, dynamic>> teachers,
    required List<Map<String, dynamic>> courses,
    Map<String, dynamic>? constraints,
  }) async {
    final systemPrompt = _buildSystemPrompt();
    final userPrompt = _buildUserPrompt(
      preferences: preferences,
      batches: batches,
      rooms: rooms,
      teachers: teachers,
      courses: courses,
      constraints: constraints,
    );

    debugPrint('[GROQ] Sending routine generation request...');

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.3,
        'max_tokens': 8000,
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('[GROQ] Error: ${response.statusCode} ${response.body}');
      throw Exception('Groq API error: ${response.statusCode} — ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['choices'][0]['message']['content'] as String;

    debugPrint('[GROQ] Response received, parsing...');

    final parsed = jsonDecode(content) as Map<String, dynamic>;
    final entries = (parsed['entries'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    debugPrint('[GROQ] Generated ${entries.length} timetable entries');
    return entries;
  }

  static String _buildSystemPrompt() {
    return '''You are an expert university timetable scheduler for the Department of Educational Technology and Engineering at University of Frontier Technology, Bangladesh.

Your job is to create a conflict-free weekly class schedule. You MUST follow these rules strictly:

HARD CONSTRAINTS (never violate):
1. A teacher cannot be in two places at the same time — no overlapping time slots for the same teacher.
2. A room cannot host two classes at the same time — no room conflicts.
3. A batch cannot have two classes at the same time — no batch conflicts.
4. Labs (rooms ending in "01" like 2701, 4701, 5701) should only be used for Sessional classes.
5. Break time (12:45–13:30) must be kept free for all batches.
6. Friday is a day off — no classes.
7. Each sessional/lab class that has groups (G-1, G-2) must be scheduled in consecutive slots.

SOFT CONSTRAINTS (try to satisfy):
1. Respect teacher preferred days/times when specified.
2. Spread classes evenly across the week for each batch.
3. Try to limit each teacher to max 4 teaching hours per day.
4. Try to give each batch at most 4 classes per day.
5. Prefer morning slots for lectures, afternoon for sessionals.

TIME SLOTS AVAILABLE (each 1h 15min):
- 09:00–10:15
- 10:15–11:30
- 11:30–12:45
- 12:45–13:30 (BREAK — never schedule here)
- 13:30–14:45

DAYS: Sat, Sun, Mon, Tue, Wed (Thu optional if needed)

OUTPUT FORMAT — return a JSON object with a single key "entries" containing an array. Each entry:
{
  "day": "Sat|Sun|Mon|Tue|Wed|Thu",
  "batch_id": "<batch UUID or name>",
  "teacher_initial": "<2-3 letter initial>",
  "course_code": "<course code>",
  "type": "Lecture|Tutorial|Sessional",
  "group_name": null or "G-1" or "G-2",
  "room_id": "<room UUID or name>",
  "mode": "Onsite",
  "start_time": "HH:MM",
  "end_time": "HH:MM"
}

Return ONLY valid JSON. No explanation, no markdown.''';
  }

  static String _buildUserPrompt({
    required List<Map<String, dynamic>> preferences,
    required List<Map<String, dynamic>> batches,
    required List<Map<String, dynamic>> rooms,
    required List<Map<String, dynamic>> teachers,
    required List<Map<String, dynamic>> courses,
    Map<String, dynamic>? constraints,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('Generate a complete weekly timetable for the following setup:\n');

    buffer.writeln('=== BATCHES ===');
    for (final b in batches) {
      buffer.writeln('- ${b['name']} (session: ${b['session']}, id: ${b['id']})');
    }

    buffer.writeln('\n=== ROOMS ===');
    for (final r in rooms) {
      buffer.writeln('- ${r['name']} (id: ${r['id']})');
    }

    buffer.writeln('\n=== TEACHERS ===');
    for (final t in teachers) {
      buffer.writeln('- ${t['name']} (${t['initial']}) — ${t['designation']}');
    }

    buffer.writeln('\n=== COURSES ===');
    for (final c in courses) {
      buffer.writeln('- ${c['code']}: ${c['title']}');
    }

    buffer.writeln('\n=== TEACHER COURSE ASSIGNMENTS (preferences) ===');
    for (final p in preferences) {
      buffer.write('- Teacher ${p['teacher_initial']} teaches ${p['course_code']}');
      buffer.write(' for batch ${p['batch_id']}');
      buffer.write(' (${p['class_type']}, ${p['sessions_per_week']}x/week)');
      if (p['group_name'] != null) buffer.write(' [${p['group_name']}]');
      if (p['preferred_day'] != null) buffer.write(' pref-day: ${p['preferred_day']}');
      if (p['preferred_time_slot'] != null) buffer.write(' pref-time: ${p['preferred_time_slot']}');
      if (p['preferred_room_id'] != null) buffer.write(' pref-room: ${p['preferred_room_id']}');
      buffer.writeln();
    }

    if (constraints != null && constraints.isNotEmpty) {
      buffer.writeln('\n=== ADDITIONAL CONSTRAINTS ===');
      constraints.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
    }

    buffer.writeln(
        '\nPlease generate a conflict-free weekly timetable using ALL the assignments above. '
        'Use the exact batch IDs, room IDs, teacher initials, and course codes provided. '
        'Return ONLY the JSON object with "entries" array.');

    return buffer.toString();
  }
}
