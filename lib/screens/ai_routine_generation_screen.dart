import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/teacher_course_preference.dart';
import '../services/data_repository.dart';
import '../services/groq_service.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

/// Screen for super admin to review teacher preferences and generate
/// a timetable using the Groq AI API.
class AiRoutineGenerationScreen extends StatefulWidget {
  final DataRepository repo;
  const AiRoutineGenerationScreen({super.key, required this.repo});

  @override
  State<AiRoutineGenerationScreen> createState() => _AiRoutineGenerationScreenState();
}

class _AiRoutineGenerationScreenState extends State<AiRoutineGenerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isGenerating = false;
  String _statusMessage = '';
  List<Map<String, dynamic>>? _generatedEntries;
  List<TeacherCoursePreference> _allPreferences = [];
  bool _isLoading = true;

  // Generation options
  bool _replaceExisting = true;
  String _routineTitle = 'AI Generated Routine';
  final _titleController = TextEditingController(text: 'AI Generated Routine');

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadPreferences();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final svc = context.read<SupabaseService>();
    final prefs = await svc.getAllCoursePreferences();
    if (mounted) {
      setState(() {
        _allPreferences = prefs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('AI Routine Generator', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadPreferences,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          labelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.5),
          tabs: const [
            Tab(icon: Icon(Icons.list_alt, size: 18), text: 'Preferences'),
            Tab(icon: Icon(Icons.auto_awesome, size: 18), text: 'Generate'),
            Tab(icon: Icon(Icons.history, size: 18), text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _PreferencesReviewTab(
                  preferences: _allPreferences,
                  repo: widget.repo,
                  onStatusUpdate: _loadPreferences,
                ),
                _GenerateTab(
                  repo: widget.repo,
                  preferences: _allPreferences,
                  isGenerating: _isGenerating,
                  statusMessage: _statusMessage,
                  generatedEntries: _generatedEntries,
                  replaceExisting: _replaceExisting,
                  routineTitle: _routineTitle,
                  titleController: _titleController,
                  onReplaceToggle: (v) => setState(() => _replaceExisting = v),
                  onTitleChange: (v) => setState(() => _routineTitle = v),
                  onGenerate: _generateRoutine,
                  onApply: _applyGeneratedRoutine,
                ),
                _HistoryTab(repo: widget.repo),
              ],
            ),
    );
  }

  Future<void> _generateRoutine() async {
    final approvedPrefs = _allPreferences.where((p) => p.status == 'approved').toList();
    if (approvedPrefs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No approved preferences to generate from. Approve some first.')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Preparing data for AI...';
      _generatedEntries = null;
    });

    try {
      final data = widget.repo.data!;

      // Prepare data maps
      final batches = data.batches.map((b) => {'id': b.id, 'name': b.name, 'session': b.session}).toList();
      final rooms = data.rooms.map((r) => {'id': r.id, 'name': r.name}).toList();
      final teachers = data.teachers.map((t) => {
        'initial': t.initial, 'name': t.name, 'designation': t.designation,
      }).toList();
      final courses = data.courses.map((c) => {'code': c.code, 'title': c.title}).toList();
      final preferences = approvedPrefs.map((p) => p.toInsertJson()).toList();

      setState(() => _statusMessage = 'Sending to Groq AI (llama-3.3-70b)...');

      final entries = await GroqService.generateRoutine(
        preferences: preferences,
        batches: batches,
        rooms: rooms,
        teachers: teachers,
        courses: courses,
      );

      setState(() {
        _generatedEntries = entries;
        _statusMessage = 'Generated ${entries.length} entries! Review and apply.';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
        _isGenerating = false;
      });
    }
  }

  Future<void> _applyGeneratedRoutine() async {
    if (_generatedEntries == null || _generatedEntries!.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          _replaceExisting ? 'Replace Entire Timetable?' : 'Append to Timetable?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          _replaceExisting
              ? 'This will DELETE all existing timetable entries and replace them with ${_generatedEntries!.length} AI-generated entries. This cannot be undone.'
              : 'This will ADD ${_generatedEntries!.length} new entries to the existing timetable.',
          style: AppTheme.body,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _replaceExisting ? AppTheme.errorRed : AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(_replaceExisting ? 'Replace All' : 'Append'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isGenerating = true;
      _statusMessage = 'Applying ${_generatedEntries!.length} entries to database...';
    });

    try {
      final svc = context.read<SupabaseService>();

      // Prepare entries for DB insert (ensure correct field names)
      final dbEntries = _generatedEntries!.map((e) {
        return {
          'day': e['day'],
          'batch_id': e['batch_id'],
          'teacher_initial': e['teacher_initial'],
          'course_code': e['course_code'],
          'type': e['type'],
          'group_name': e['group_name'],
          'room_id': e['room_id'],
          'mode': e['mode'] ?? 'Onsite',
          'start_time': e['start_time'] ?? e['start'],
          'end_time': e['end_time'] ?? e['end'],
          'is_cancelled': false,
        };
      }).toList();

      bool success;
      if (_replaceExisting) {
        success = await svc.replaceAllTimetableEntries(dbEntries);
      } else {
        success = await svc.appendTimetableEntries(dbEntries);
      }

      if (success) {
        // Save generation record
        await svc.saveRoutineGeneration(
          generatedBy: svc.currentAdmin?.username ?? 'unknown',
          routineTitle: _routineTitle,
          entryCount: dbEntries.length,
          status: 'applied',
          notes: _replaceExisting ? 'Replaced existing timetable' : 'Appended to existing timetable',
        );

        // --- Send notifications & emails per teacher ---
        // Group entries by teacher_initial
        final Map<String, List<Map<String, dynamic>>> entriesByTeacher = {};
        for (final e in dbEntries) {
          final ti = e['teacher_initial'] as String? ?? '';
          if (ti.isNotEmpty) {
            entriesByTeacher.putIfAbsent(ti, () => []).add(e);
          }
        }

        final action = _replaceExisting ? 'New routine generated' : 'Routine updated';
        for (final entry in entriesByTeacher.entries) {
          final teacherInitial = entry.key;
          final teacherEntries = entry.value;

          // In-app notification per teacher
          await svc.createNotification(AppNotification(
            id: '',
            type: 'routine_generated',
            title: action,
            body: 'You have ${teacherEntries.length} class(es) in the new timetable. Check your schedule.',
            recipientType: 'teacher',
            recipientId: teacherInitial,
            createdAt: '',
          ));

          // Email per unique batch for this teacher
          final batchIds = teacherEntries.map((e) => e['batch_id'] as String).toSet();
          for (final batchId in batchIds) {
            final batchEntries = teacherEntries.where((e) => e['batch_id'] == batchId).toList();
            final batchName = widget.repo.batchById(batchId)?.name ?? batchId;
            final slots = batchEntries.map((e) =>
              '${e['day']} ${e['start_time']}-${e['end_time']}').join(', ');
            await svc.sendTimetableChangeEmail(
              changeType: 'routine_generated',
              courseCode: batchEntries.first['course_code'] as String,
              teacherInitial: teacherInitial,
              batchId: batchId,
              details: '$action with ${batchEntries.length} class(es) for batch $batchName: $slots',
            );
          }
        }

        // Reload the repo
        await widget.repo.load();

        setState(() {
          _statusMessage = 'Successfully applied ${dbEntries.length} entries!';
          _isGenerating = false;
          _generatedEntries = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Timetable ${_replaceExisting ? "replaced" : "updated"} with ${dbEntries.length} entries!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = 'Failed to apply entries. Check logs.';
          _isGenerating = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error applying: $e';
        _isGenerating = false;
      });
    }
  }
}

// ─── Tab 1: Preferences Review ────────────────────────

class _PreferencesReviewTab extends StatelessWidget {
  final List<TeacherCoursePreference> preferences;
  final DataRepository repo;
  final VoidCallback onStatusUpdate;

  const _PreferencesReviewTab({
    required this.preferences,
    required this.repo,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    if (preferences.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text('No preferences submitted yet', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
            )),
            const SizedBox(height: 8),
            Text('Teachers need to submit their\ncourse preferences first.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textHint),
            ),
          ],
        ),
      );
    }

    // Group by status
    final pending = preferences.where((p) => p.status == 'pending').toList();
    final approved = preferences.where((p) => p.status == 'approved').toList();
    final rejected = preferences.where((p) => p.status == 'rejected').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            _SummaryCard(count: pending.length, label: 'Pending', color: AppTheme.warningAmber, icon: Icons.hourglass_empty),
            const SizedBox(width: 8),
            _SummaryCard(count: approved.length, label: 'Approved', color: AppTheme.successGreen, icon: Icons.check_circle),
            const SizedBox(width: 8),
            _SummaryCard(count: rejected.length, label: 'Rejected', color: AppTheme.errorRed, icon: Icons.cancel),
          ],
        ),
        const SizedBox(height: 16),

        // Bulk actions
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _bulkUpdateStatus(context, pending, 'approved'),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text('Approve All Pending'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _bulkUpdateStatus(context, pending, 'rejected'),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject All'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Preference list
        if (pending.isNotEmpty) ...[
          AppTheme.sectionHeader('Pending Review (${pending.length})', icon: Icons.hourglass_empty),
          const SizedBox(height: 8),
          ...pending.map((p) => _preferenceReviewCard(context, p)),
        ],
        if (approved.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppTheme.sectionHeader('Approved (${approved.length})', icon: Icons.check_circle),
          const SizedBox(height: 8),
          ...approved.map((p) => _preferenceReviewCard(context, p)),
        ],
        if (rejected.isNotEmpty) ...[
          const SizedBox(height: 16),
          AppTheme.sectionHeader('Rejected (${rejected.length})', icon: Icons.cancel),
          const SizedBox(height: 8),
          ...rejected.map((p) => _preferenceReviewCard(context, p)),
        ],
      ],
    );
  }

  Widget _preferenceReviewCard(BuildContext context, TeacherCoursePreference pref) {
    final teacher = repo.teacherByInitial(pref.teacherInitial);
    final course = repo.courseByCode(pref.courseCode);
    final batch = repo.batchById(pref.batchId);

    Color statusColor;
    switch (pref.status) {
      case 'approved': statusColor = AppTheme.successGreen; break;
      case 'rejected': statusColor = AppTheme.errorRed; break;
      default: statusColor = AppTheme.warningAmber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                child: Text(
                  pref.teacherInitial,
                  style: GoogleFonts.poppins(
                    fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher?.name ?? pref.teacherInitial,
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${pref.courseCode} (${course?.title ?? "Unknown"}) → ${batch?.name ?? pref.batchId}',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip(pref.classType, AppTheme.primaryBlue),
              _chip('${pref.sessionsPerWeek}x/week', AppTheme.successGreen),
              if (pref.groupName != null) _chip(pref.groupName!, AppTheme.infoCyan),
              if (pref.preferredDay != null) _chip('Pref: ${pref.preferredDay}', AppTheme.accentOrange),
              if (pref.preferredTimeSlot != null) _chip(pref.preferredTimeSlot!, AppTheme.textSecondary),
            ],
          ),
          if (pref.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _updateStatus(context, pref, 'approved'),
                  icon: const Icon(Icons.check, size: 16, color: AppTheme.successGreen),
                  label: Text('Approve', style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.successGreen, fontWeight: FontWeight.w600,
                  )),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _updateStatus(context, pref, 'rejected'),
                  icon: const Icon(Icons.close, size: 16, color: AppTheme.errorRed),
                  label: Text('Reject', style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w500, color: color,
      )),
    );
  }

  Future<void> _updateStatus(BuildContext context, TeacherCoursePreference pref, String status) async {
    if (pref.id == null) return;
    await context.read<SupabaseService>().updateCoursePreferenceStatus(pref.id!, status);
    onStatusUpdate();
  }

  Future<void> _bulkUpdateStatus(BuildContext context, List<TeacherCoursePreference> prefs, String status) async {
    final svc = context.read<SupabaseService>();
    for (final p in prefs) {
      if (p.id != null) {
        await svc.updateCoursePreferenceStatus(p.id!, status);
      }
    }
    onStatusUpdate();
  }
}

class _SummaryCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.count, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text('$count', style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700, color: color,
            )),
            Text(label, style: GoogleFonts.poppins(
              fontSize: 11, color: color,
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 2: Generate ──────────────────────────────────

class _GenerateTab extends StatelessWidget {
  final DataRepository repo;
  final List<TeacherCoursePreference> preferences;
  final bool isGenerating;
  final String statusMessage;
  final List<Map<String, dynamic>>? generatedEntries;
  final bool replaceExisting;
  final String routineTitle;
  final TextEditingController titleController;
  final ValueChanged<bool> onReplaceToggle;
  final ValueChanged<String> onTitleChange;
  final VoidCallback onGenerate;
  final VoidCallback onApply;

  const _GenerateTab({
    required this.repo,
    required this.preferences,
    required this.isGenerating,
    required this.statusMessage,
    required this.generatedEntries,
    required this.replaceExisting,
    required this.routineTitle,
    required this.titleController,
    required this.onReplaceToggle,
    required this.onTitleChange,
    required this.onGenerate,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final approvedCount = preferences.where((p) => p.status == 'approved').length;
    final data = repo.data!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Generation Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Groq AI Timetable Generator',
                      style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Uses Llama 3.3 70B to generate a conflict-free weekly timetable based on approved teacher preferences.',
                style: GoogleFonts.poppins(
                  fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Stats
        Row(
          children: [
            _StatTile(value: '$approvedCount', label: 'Approved Prefs', icon: Icons.check_circle, color: AppTheme.successGreen),
            const SizedBox(width: 8),
            _StatTile(value: '${data.batches.length}', label: 'Batches', icon: Icons.group, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            _StatTile(value: '${data.rooms.length}', label: 'Rooms', icon: Icons.room, color: AppTheme.accentOrange),
          ],
        ),
        const SizedBox(height: 20),

        // Routine title
        TextField(
          controller: titleController,
          onChanged: onTitleChange,
          decoration: AppTheme.inputDecoration(
            label: 'Routine Title',
            hintText: 'e.g. Ramadhan Routine 2026',
            prefixIcon: Icons.title,
          ),
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),

        // Replace vs Append toggle
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generation Mode', style: GoogleFonts.poppins(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
              )),
              const SizedBox(height: 8),
              RadioListTile<bool>(
                value: true,
                groupValue: replaceExisting,
                onChanged: (v) => onReplaceToggle(v!),
                title: Text('Replace entire timetable', style: GoogleFonts.poppins(fontSize: 13)),
                subtitle: Text('Deletes all existing entries first', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint)),
                activeColor: AppTheme.primaryBlue,
                dense: true,
              ),
              RadioListTile<bool>(
                value: false,
                groupValue: replaceExisting,
                onChanged: (v) => onReplaceToggle(v!),
                title: Text('Append to existing', style: GoogleFonts.poppins(fontSize: 13)),
                subtitle: Text('Keeps current entries, adds new ones', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint)),
                activeColor: AppTheme.primaryBlue,
                dense: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Generate button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: isGenerating ? null : onGenerate,
            icon: isGenerating
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              isGenerating ? 'Generating...' : 'Generate Routine with AI',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
          ),
        ),

        // Status message
        if (statusMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusMessage.contains('Error')
                  ? AppTheme.errorRed.withValues(alpha: 0.08)
                  : AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  statusMessage.contains('Error') ? Icons.error_outline : Icons.info_outline,
                  size: 20,
                  color: statusMessage.contains('Error') ? AppTheme.errorRed : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(statusMessage, style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: statusMessage.contains('Error') ? AppTheme.errorRed : AppTheme.textPrimary,
                  )),
                ),
              ],
            ),
          ),
        ],

        // Preview generated entries
        if (generatedEntries != null && generatedEntries!.isNotEmpty) ...[
          const SizedBox(height: 20),
          AppTheme.sectionHeader('Preview (${generatedEntries!.length} entries)', icon: Icons.preview),
          const SizedBox(height: 8),

          // Group by day
          ...['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'].map((day) {
            final dayEntries = generatedEntries!.where((e) => e['day'] == day).toList();
            if (dayEntries.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(day, style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryBlue,
                  )),
                ),
                ...dayEntries.map((e) => _entryPreviewTile(e)),
              ],
            );
          }),

          const SizedBox(height: 16),

          // Apply button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: isGenerating ? null : onApply,
              icon: const Icon(Icons.upload, color: Colors.white),
              label: Text(
                replaceExisting ? 'Apply & Replace Timetable' : 'Apply & Append',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: replaceExisting ? AppTheme.errorRed : AppTheme.successGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _entryPreviewTile(Map<String, dynamic> entry) {
    final time = '${entry['start_time'] ?? entry['start']} – ${entry['end_time'] ?? entry['end']}';
    final roomId = entry['room_id']?.toString();
    final roomName = (roomId != null ? repo.roomById(roomId)?.name : null) ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(time, style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
            )),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${entry['course_code']} (${entry['teacher_initial']}) — ${entry['type']}${entry['group_name'] != null ? ' [${entry['group_name']}]' : ''}',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          if (roomName.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              roomName,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(
              fontSize: 20, fontWeight: FontWeight.w700, color: color,
            )),
            Text(label, style: GoogleFonts.poppins(
              fontSize: 10.5, color: color.withValues(alpha: 0.8),
            )),
          ],
        ),
      ),
    );
  }
}

// ─── Tab 3: History ───────────────────────────────────

class _HistoryTab extends StatefulWidget {
  final DataRepository repo;
  const _HistoryTab({required this.repo});

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final svc = context.read<SupabaseService>();
    final history = await svc.getRoutineGenerations();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue));
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 64, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text('No generation history', style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
            )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final record = _history[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record['routine_title'] ?? 'Untitled Routine',
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${record['entry_count'] ?? 0} entries • ${record['status'] ?? 'unknown'} • by ${record['generated_by'] ?? 'unknown'}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (record['notes'] != null)
                  Text(record['notes'], style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint)),
                Text(
                  record['created_at']?.toString().substring(0, 16) ?? '',
                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
