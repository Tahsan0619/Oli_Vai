import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/teacher_course_preference.dart';
import '../models/batch.dart';
import '../models/course.dart';
import '../models/room.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

/// Screen for teachers to submit their course preferences
/// (which courses they teach, for which batch, preferred schedule).
class TeacherCoursePreferenceScreen extends StatefulWidget {
  final String teacherInitial;
  final DataRepository repo;

  const TeacherCoursePreferenceScreen({
    super.key,
    required this.teacherInitial,
    required this.repo,
  });

  @override
  State<TeacherCoursePreferenceScreen> createState() =>
      _TeacherCoursePreferenceScreenState();
}

class _TeacherCoursePreferenceScreenState
    extends State<TeacherCoursePreferenceScreen> {
  List<TeacherCoursePreference> _prefs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final svc = context.read<SupabaseService>();
    final prefs = await svc.getTeacherCoursePreferences(widget.teacherInitial);
    if (mounted) {
      setState(() {
        _prefs = prefs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = widget.repo.teacherByInitial(widget.teacherInitial);
    final data = widget.repo.data!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('My Course Preferences', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadPreferences,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPreferenceDialog(data.batches, data.courses, data.rooms),
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Course', style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600, color: Colors.white,
        )),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _prefs.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadPreferences,
                  color: AppTheme.primaryBlue,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppTheme.studentGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.white, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Submit your course assignments below. The chairman will review and use them to generate the routine with AI.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Teacher info
                      if (teacher != null) ...[
                        Text(
                          '${teacher.name} (${teacher.initial})',
                          style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          teacher.designation,
                          style: GoogleFonts.poppins(
                            fontSize: 13, color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Preference cards
                      ..._prefs.map((pref) => _preferenceCard(pref)),
                    ],
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text(
            'No course preferences yet',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to add courses\nyou will teach this semester.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13, color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferenceCard(TeacherCoursePreference pref) {
    final course = widget.repo.courseByCode(pref.courseCode);
    final batch = widget.repo.batchById(pref.batchId);
    final room = widget.repo.roomById(pref.preferredRoomId);

    Color statusColor;
    IconData statusIcon;
    switch (pref.status) {
      case 'approved':
        statusColor = AppTheme.successGreen;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = AppTheme.errorRed;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppTheme.warningAmber;
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Course + status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pref.courseCode,
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                      ),
                    ),
                    if (course != null)
                      Text(
                        course.title,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5, color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      pref.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11, fontWeight: FontWeight.w600, color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(Icons.group, batch?.name ?? pref.batchId, AppTheme.primaryBlue),
              _infoChip(Icons.class_, pref.classType, AppTheme.accentOrange),
              _infoChip(Icons.repeat, '${pref.sessionsPerWeek}x/week', AppTheme.successGreen),
              if (pref.groupName != null)
                _infoChip(Icons.people, pref.groupName!, AppTheme.infoCyan),
              if (pref.preferredDay != null)
                _infoChip(Icons.calendar_today, pref.preferredDay!, AppTheme.warningAmber),
              if (pref.preferredTimeSlot != null)
                _infoChip(Icons.access_time, pref.preferredTimeSlot!, AppTheme.textSecondary),
              if (room != null)
                _infoChip(Icons.room, room.name, AppTheme.errorRed),
            ],
          ),

          // Actions
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (pref.status == 'pending') ...[
                TextButton.icon(
                  onPressed: () => _showEditPreferenceDialog(pref),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                ),
              ],
              TextButton.icon(
                onPressed: () => _confirmDelete(pref),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Remove'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500, color: color,
          )),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(TeacherCoursePreference pref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Preference', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Remove ${pref.courseCode} for batch ${widget.repo.batchById(pref.batchId)?.name ?? pref.batchId}?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && pref.id != null) {
      await context.read<SupabaseService>().deleteCoursePreference(pref.id!);
      _loadPreferences();
    }
  }

  // ─── Add/Edit Dialog ───────────────────────────────────

  Future<void> _showAddPreferenceDialog(
    List<Batch> batches, List<Course> courses, List<Room> rooms,
  ) async {
    await _showPreferenceForm(
      batches: batches,
      courses: courses,
      rooms: rooms,
    );
  }

  Future<void> _showEditPreferenceDialog(TeacherCoursePreference existing) async {
    final data = widget.repo.data!;
    await _showPreferenceForm(
      batches: data.batches,
      courses: data.courses,
      rooms: data.rooms,
      existing: existing,
    );
  }

  Future<void> _showPreferenceForm({
    required List<Batch> batches,
    required List<Course> courses,
    required List<Room> rooms,
    TeacherCoursePreference? existing,
  }) async {
    String? selectedCourseCode = existing?.courseCode;
    String? selectedBatchId = existing?.batchId;
    String selectedType = existing?.classType ?? 'Lecture';
    int sessionsPerWeek = existing?.sessionsPerWeek ?? 1;
    String? preferredDay = existing?.preferredDay;
    String? preferredTime = existing?.preferredTimeSlot;
    String? preferredRoomId = existing?.preferredRoomId;
    String? groupName = existing?.groupName;

    const classTypes = ['Lecture', 'Tutorial', 'Sessional'];
    const days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
    const timeSlots = ['09:00-10:15', '10:15-11:30', '11:30-12:45', '13:30-14:45'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            existing != null ? 'Edit Preference' : 'Add Course Preference',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Course dropdown
                DropdownButtonFormField<String>(
                  value: selectedCourseCode,
                  decoration: AppTheme.inputDecoration(
                    label: 'Course *',
                    prefixIcon: Icons.menu_book,
                  ),
                  items: courses.map((c) => DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.code} — ${c.title}', style: GoogleFonts.poppins(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCourseCode = v),
                ),
                const SizedBox(height: 12),

                // Batch dropdown
                DropdownButtonFormField<String>(
                  value: selectedBatchId,
                  decoration: AppTheme.inputDecoration(
                    label: 'Batch *',
                    prefixIcon: Icons.group,
                  ),
                  items: batches.map((b) => DropdownMenuItem(
                    value: b.id,
                    child: Text('${b.name} (${b.session})', style: GoogleFonts.poppins(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedBatchId = v),
                ),
                const SizedBox(height: 12),

                // Class type
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: AppTheme.inputDecoration(
                    label: 'Class Type *',
                    prefixIcon: Icons.class_,
                  ),
                  items: classTypes.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: GoogleFonts.poppins(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 'Lecture'),
                ),
                const SizedBox(height: 12),

                // Sessions per week
                Row(
                  children: [
                    Expanded(
                      child: Text('Sessions/week', style: GoogleFonts.poppins(
                        fontSize: 13, color: AppTheme.textSecondary,
                      )),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: sessionsPerWeek > 1
                          ? () => setDialogState(() => sessionsPerWeek--)
                          : null,
                    ),
                    Text('$sessionsPerWeek', style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600,
                    )),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: sessionsPerWeek < 5
                          ? () => setDialogState(() => sessionsPerWeek++)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Group (for sessional)
                if (selectedType == 'Sessional') ...[
                  DropdownButtonFormField<String?>(
                    value: groupName,
                    decoration: AppTheme.inputDecoration(
                      label: 'Group (optional)',
                      prefixIcon: Icons.people,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No group')),
                      const DropdownMenuItem(value: 'G-1', child: Text('G-1')),
                      const DropdownMenuItem(value: 'G-2', child: Text('G-2')),
                    ],
                    onChanged: (v) => setDialogState(() => groupName = v),
                  ),
                  const SizedBox(height: 12),
                ],

                // Preferred day (optional)
                DropdownButtonFormField<String?>(
                  value: preferredDay,
                  decoration: AppTheme.inputDecoration(
                    label: 'Preferred Day (optional)',
                    prefixIcon: Icons.calendar_today,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No preference')),
                    ...days.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                  ],
                  onChanged: (v) => setDialogState(() => preferredDay = v),
                ),
                const SizedBox(height: 12),

                // Preferred time (optional)
                DropdownButtonFormField<String?>(
                  value: preferredTime,
                  decoration: AppTheme.inputDecoration(
                    label: 'Preferred Time (optional)',
                    prefixIcon: Icons.access_time,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No preference')),
                    ...timeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (v) => setDialogState(() => preferredTime = v),
                ),
                const SizedBox(height: 12),

                // Preferred room (optional)
                DropdownButtonFormField<String?>(
                  value: preferredRoomId,
                  decoration: AppTheme.inputDecoration(
                    label: 'Preferred Room (optional)',
                    prefixIcon: Icons.room,
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No preference')),
                    ...rooms.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name, style: GoogleFonts.poppins(fontSize: 13)),
                    )),
                  ],
                  onChanged: (v) => setDialogState(() => preferredRoomId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: (selectedCourseCode != null && selectedBatchId != null)
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(existing != null ? 'Update' : 'Submit'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedCourseCode != null && selectedBatchId != null) {
      final svc = context.read<SupabaseService>();
      final pref = TeacherCoursePreference(
        teacherInitial: widget.teacherInitial,
        courseCode: selectedCourseCode!,
        batchId: selectedBatchId!,
        classType: selectedType,
        sessionsPerWeek: sessionsPerWeek,
        preferredDay: preferredDay,
        preferredTimeSlot: preferredTime,
        preferredRoomId: preferredRoomId,
        groupName: groupName,
        status: 'pending',
      );

      if (existing?.id != null) {
        await svc.updateCoursePreference(existing!.id!, pref);
      } else {
        await svc.addCoursePreference(pref);
      }
      _loadPreferences();
    }
  }
}
