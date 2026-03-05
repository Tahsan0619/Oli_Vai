import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin.dart';
import '../models/timetable_entry.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import '../widgets/schedule_card.dart';
import 'monthly_routine_screen.dart';
import 'teacher_appointment_screen.dart';
import 'notification_screen.dart';
import 'teacher_profile_screen.dart';
import 'unified_login_screen_new.dart';

class TeacherAdminPortalScreen extends StatefulWidget {
  final DataRepository repo;
  final Admin admin;
  const TeacherAdminPortalScreen({super.key, required this.repo, required this.admin});

  @override
  State<TeacherAdminPortalScreen> createState() => _TeacherAdminPortalScreenState();
}

class _TeacherAdminPortalScreenState extends State<TeacherAdminPortalScreen> {
  String _selectedDay = _currentDay();
  bool _isLoading = false;
  final List<RealtimeChannel> _channels = [];
  Timer? _debounce;

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static String _currentDay() {
    const dayMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return dayMap[DateTime.now().weekday] ?? 'Sun';
  }

  String get _teacherInitial => widget.admin.teacherInitial ?? '';

  @override
  void initState() {
    super.initState();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final ch in _channels) {
      Supabase.instance.client.removeChannel(ch);
    }
    super.dispose();
  }

  /// Subscribe to realtime changes on timetable entries so schedule updates automatically.
  void _subscribeRealtime() {
    final client = Supabase.instance.client;
    final tables = ['timetable_entries', 'courses', 'rooms'];
    for (final table in tables) {
      final channel = client
          .channel('teacher_$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              debugPrint('[REALTIME-TEACHER] Change on $table: ${payload.eventType}');
              _debouncedRefresh();
            },
          )
          .subscribe();
      _channels.add(channel);
    }
  }

  /// Debounced refresh — prevents rapid-fire reloads.
  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _refresh());
  }

  Future<void> _refresh() async {
    // Silent refresh — don't show loading spinner to preserve UI state
    await widget.repo.load();
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    await context.read<SupabaseService>().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SupabaseService>(),
        child: const UnifiedLoginScreen(),
      )),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final teacher = widget.repo.teacherByInitial(_teacherInitial);
    final entries = widget.repo.teacherEntriesForDay(_teacherInitial, _selectedDay);

    // Calculate stats
    double totalHours = 0;
    for (final e in entries) {
      final startParts = e.start.split(':');
      final endParts = e.end.split(':');
      if (startParts.length == 2 && endParts.length == 2) {
        final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        totalHours += (endMin - startMin) / 60.0;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.studentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.bolt_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Teacher Portal', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
            )),
          ],
        ),
        actions: [
          NotificationBell(
            recipientType: 'teacher',
            recipientId: _teacherInitial,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 22),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: context.read<SupabaseService>(),
                child: TeacherProfileScreen(teacherInitial: _teacherInitial),
              ),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: _logout,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppTheme.primaryBlue,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Welcome banner
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.studentGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: AppTheme.softShadow(AppTheme.primaryBlue),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.poppins(
                            fontSize: 13, color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          teacher?.name ?? widget.admin.username,
                          style: GoogleFonts.poppins(
                            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          teacher?.designation ?? 'Teacher',
                          style: GoogleFonts.poppins(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    backgroundImage: teacher?.profilePic != null
                        ? NetworkImage(teacher!.profilePic!)
                        : null,
                    child: teacher?.profilePic == null
                        ? Text(
                            _teacherInitial.length >= 2
                                ? _teacherInitial.substring(0, 2)
                                : _teacherInitial,
                            style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),

            // Quick action row: Monthly Routine + Appointments
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      Icons.calendar_month,
                      'Monthly Routine',
                      AppTheme.primaryBlue,
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => MonthlyRoutineScreen(
                          repo: widget.repo,
                          title: '$_teacherInitial — Monthly Routine',
                          teacherInitial: _teacherInitial,
                          showTeacher: false,
                          showBatch: true,
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      Icons.event_available,
                      'Appointments',
                      AppTheme.accentOrange,
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<SupabaseService>(),
                          child: TeacherAppointmentScreen(teacherInitial: _teacherInitial),
                        ),
                      )),
                    ),
                  ),
                ],
              ),
            ),

            // Day selector
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _days.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _dayPill(_days[i]),
                ),
              ),
            ),

            Divider(height: 1, color: AppTheme.dividerColor),

            // Schedule header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text("Today's Schedule", style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                  )),
                  const Spacer(),
                  Text('${entries.length} Sessions', style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary,
                  )),
                ],
              ),
            ),

            // Loading
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
              ),

            // Schedule entries
            if (!_isLoading && entries.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.free_breakfast_outlined, size: 48, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text('No classes on $_selectedDay', style: AppTheme.subtitle),
                    ],
                  ),
                ),
              ),

            if (!_isLoading)
              ...entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScheduleCard(
                  entry: entry,
                  repo: widget.repo,
                  showTeacher: false,
                  showBatch: true,
                  actions: _buildActions(entry),
                ),
              )),

            // Stats row
            if (!_isLoading && entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _statCard(
                      Icons.access_time_outlined,
                      'Teaching Hours',
                      '${totalHours.toStringAsFixed(1)}h',
                      AppTheme.primaryBlueLight,
                      AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      Icons.people_outline,
                      'Sessions',
                      '${entries.where((e) => !e.isCancelled).length}',
                      AppTheme.successGreenLight,
                      AppTheme.successGreen,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w600, color: color,
            )),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(TimetableEntry entry) {
    if (entry.isCancelled) {
      return [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _restoreClass(entry),
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('Restore Class'),
            style: AppTheme.outlineButton(color: AppTheme.successGreen),
          ),
        ),
      ];
    }
    return [
      OutlinedButton.icon(
        onPressed: () => _showRescheduleDialog(entry),
        icon: const Icon(Icons.calendar_today_outlined, size: 14),
        label: const Text('Reschedule'),
        style: AppTheme.outlineButton(),
      ),
      OutlinedButton.icon(
        onPressed: () => _showChangeRoomDialog(entry),
        icon: const Icon(Icons.swap_horiz, size: 14),
        label: const Text('Room'),
        style: AppTheme.outlineButton(),
      ),
      GestureDetector(
        onTap: () => _showCancelDialog(entry),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppTheme.errorRed),
            const SizedBox(width: 4),
            Text('Cancel', style: GoogleFonts.poppins(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.errorRed,
            )),
          ],
        ),
      ),
    ];
  }

  Widget _dayPill(String day) {
    final isSelected = _selectedDay == day;
    final now = DateTime.now();
    final dayIndex = _days.indexOf(day);
    final currentDayIndex = _days.indexOf(_currentDay());
    final diff = dayIndex - currentDayIndex;
    final date = now.add(Duration(days: diff));

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: isSelected ? null : Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppTheme.textHint,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 11, color: fg.withValues(alpha: 0.7))),
            Text(value, style: GoogleFonts.poppins(
              fontSize: 22, fontWeight: FontWeight.w700, color: fg,
            )),
          ],
        ),
      ),
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────

  Future<void> _showCancelDialog(TimetableEntry entry) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Class', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to cancel this class?', style: AppTheme.body),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: AppTheme.inputDecoration(
                label: 'Reason',
                hintText: 'e.g. Faculty meeting',
                prefixIcon: Icons.info_outline,
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('No', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed, foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Class'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final reason = reasonCtrl.text.trim().isEmpty ? 'Cancelled by teacher' : reasonCtrl.text.trim();
      await widget.repo.cancelClass(entry, reason);
      // Trigger email notification to all students in batch + super admins + teacher
      await context.read<SupabaseService>().sendTimetableChangeEmail(
        changeType: 'cancelled',
        courseCode: entry.courseCode,
        teacherInitial: entry.teacherInitial,
        batchId: entry.batchId,
        details: 'Class cancelled. Reason: $reason',
      );
      if (mounted) setState(() {});
    }
  }

  Future<void> _restoreClass(TimetableEntry entry) async {
    await widget.repo.uncancelClass(entry);
    // Trigger email notification to all students in batch + super admins + teacher
    await context.read<SupabaseService>().sendTimetableChangeEmail(
      changeType: 'restored',
      courseCode: entry.courseCode,
      teacherInitial: entry.teacherInitial,
      batchId: entry.batchId,
      details: 'Class has been restored.',
    );
    if (mounted) setState(() {});
  }

  Future<void> _showRescheduleDialog(TimetableEntry entry) async {
    String newDay = entry.day;
    String newStart = entry.start;
    String newEnd = entry.end;
    String newMode = entry.mode;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Reschedule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAY', style: AppTheme.labelUpper),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _days.map((d) => ChoiceChip(
                    label: Text(d),
                    selected: newDay == d,
                    onSelected: (_) => setDialogState(() => newDay = d),
                    selectedColor: AppTheme.primaryBlueLight,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: newDay == d ? AppTheme.primaryBlue : AppTheme.textSecondary,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: AppTheme.inputDecoration(label: 'Start', prefixIcon: Icons.access_time),
                        controller: TextEditingController(text: newStart),
                        onChanged: (v) => newStart = v,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: AppTheme.inputDecoration(label: 'End', prefixIcon: Icons.access_time),
                        controller: TextEditingController(text: newEnd),
                        onChanged: (v) => newEnd = v,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('MODE', style: AppTheme.labelUpper),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _modeChip('Onsite', Icons.location_on_outlined, newMode == 'Onsite', () => setDialogState(() => newMode = 'Onsite')),
                    const SizedBox(width: 8),
                    _modeChip('Online', Icons.videocam_outlined, newMode == 'Online', () => setDialogState(() => newMode = 'Online')),
                  ],
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await widget.repo.rescheduleClass(
        entry,
        newDay: newDay,
        newStart: newStart,
        newEnd: newEnd,
        newMode: newMode,
      );
      // Trigger email notification to all students in batch + super admins + teacher
      await context.read<SupabaseService>().sendTimetableChangeEmail(
        changeType: 'rescheduled',
        courseCode: entry.courseCode,
        teacherInitial: entry.teacherInitial,
        batchId: entry.batchId,
        details: 'Class moved to $newDay $newStart-$newEnd ($newMode).',
      );
      if (mounted) setState(() {});
    }
  }

  Widget _modeChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryBlueLight : AppTheme.inputFill,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: selected
                ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
                : Border.all(color: AppTheme.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? AppTheme.primaryBlue : AppTheme.textHint),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500,
                color: selected ? AppTheme.primaryBlue : AppTheme.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangeRoomDialog(TimetableEntry entry) async {
    final rooms = widget.repo.data?.rooms ?? [];
    String? newRoomId = entry.roomId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Change Room', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select new room:', style: AppTheme.body),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: rooms.length,
                    itemBuilder: (_, i) {
                      final room = rooms[i];
                      final isSelected = room.id == newRoomId;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        selected: isSelected,
                        selectedTileColor: AppTheme.primaryBlueLight,
                        leading: Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textHint,
                          size: 20,
                        ),
                        title: Text(room.name, style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
                        )),
                        onTap: () => setDialogState(() => newRoomId = room.id),
                      );
                    },
                  ),
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && newRoomId != null && newRoomId != entry.roomId) {
      final newRoom = rooms.firstWhere((r) => r.id == newRoomId, orElse: () => rooms.first);
      await widget.repo.changeRoom(entry, newRoomId!);
      // Trigger email notification to all students in batch + super admins + teacher
      await context.read<SupabaseService>().sendTimetableChangeEmail(
        changeType: 'room_changed',
        courseCode: entry.courseCode,
        teacherInitial: entry.teacherInitial,
        batchId: entry.batchId,
        details: 'Room changed to ${newRoom.name}.',
      );
      if (mounted) setState(() {});
    }
  }
}
