import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/batch.dart';
import '../models/course.dart';
import '../models/room.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/timetable_entry.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import '../utils/timetable_export_import.dart';
import '../models/notification_model.dart';
import 'add_edit_schedule_screen.dart';
import 'ai_routine_generation_screen.dart';
import 'notification_screen.dart';
import '../widgets/teacher_avatar.dart';

class SuperAdminPortalScreenNew extends StatefulWidget {
  const SuperAdminPortalScreenNew({super.key});

  @override
  State<SuperAdminPortalScreenNew> createState() => _SuperAdminPortalScreenNewState();
}

class _SuperAdminPortalScreenNewState extends State<SuperAdminPortalScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late DataRepository _repo;
  bool _isLoading = true;
  final List<RealtimeChannel> _channels = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _debounce?.cancel();
    // Unsubscribe from all realtime channels
    for (final ch in _channels) {
      Supabase.instance.client.removeChannel(ch);
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    final svc = context.read<SupabaseService>();
    _repo = DataRepository(svc);
    await _repo.load();
    if (mounted) {
      setState(() => _isLoading = false);
      _subscribeRealtime();
    }
  }

  /// Subscribe to realtime changes on key tables.
  /// When any row is inserted/updated/deleted, silently reload data.
  void _subscribeRealtime() {
    final client = Supabase.instance.client;
    final tables = ['teachers', 'students', 'courses', 'rooms', 'batches', 'timetable_entries'];
    for (final table in tables) {
      final channel = client
          .channel('superadmin_$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              debugPrint('[REALTIME] Change on $table: ${payload.eventType}');
              _debouncedRefresh();
            },
          )
          .subscribe();
      _channels.add(channel);
    }
  }

  /// Debounced refresh — prevents rapid-fire reloads when multiple events arrive.
  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _refresh());
  }

  Future<void> _refresh() async {
    // Silent refresh — do NOT set _isLoading = true.
    // Setting _isLoading = true replaces TabBarView with a spinner,
    // destroying all child widget state (permission toggles, search, etc.).
    await _repo.load();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Super Admin', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        actions: [
          Builder(
            builder: (ctx) {
              final svc = ctx.read<SupabaseService>();
              final adminEmail = svc.currentAdmin?.username ?? '';
              return NotificationBell(
                recipientType: 'super_admin',
                recipientId: adminEmail,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _refresh,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            onPressed: () => _confirmLogout(),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: false,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryBlue,
          indicatorWeight: 2.5,
          labelPadding: EdgeInsets.zero,
          labelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Dashboard'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.calendar_month_outlined, size: 18), text: 'Timetable'),
            Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Academic'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _DashboardTab(repo: _repo, onNavigate: (i) => _tabCtrl.animateTo(i)),
                _UsersTab(repo: _repo, svc: context.read<SupabaseService>(), onRefresh: _refresh),
                _TimetableTab(repo: _repo, svc: context.read<SupabaseService>(), onRefresh: _refresh),
                _AcademicTab(repo: _repo, svc: context.read<SupabaseService>(), onRefresh: _refresh),
              ],
            ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text('Logout', style: AppTheme.heading3),
        content: Text('Are you sure you want to sign out?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SupabaseService>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ───────── DASHBOARD TAB ─────────
class _DashboardTab extends StatelessWidget {
  final DataRepository repo;
  final void Function(int) onNavigate;
  const _DashboardTab({required this.repo, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final data = repo.data!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Welcome
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryBlue, Color(0xFF6366F1)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, Super Admin', style: GoogleFonts.poppins(
                fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white,
              )),
              const SizedBox(height: 6),
              Text(data.meta.department, style: GoogleFonts.poppins(
                fontSize: 12.5, color: Colors.white.withValues(alpha: 0.85),
              )),
              Text(data.meta.university, style: GoogleFonts.poppins(
                fontSize: 11.5, color: Colors.white.withValues(alpha: 0.7),
              )),
            ],
          ),
        ),

        const SizedBox(height: 20),
        AppTheme.sectionHeader('System Metrics', icon: Icons.analytics_outlined),
        const SizedBox(height: 12),

        // Stats grid
        Row(
          children: [
            _MetricCard(label: 'Teachers', value: '${data.teachers.length}',
              icon: Icons.school_outlined, color: AppTheme.primaryBlue),
            const SizedBox(width: 12),
            _MetricCard(label: 'Students', value: '${data.students.length}',
              icon: Icons.people_outline, color: AppTheme.successGreen),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard(label: 'Courses', value: '${data.courses.length}',
              icon: Icons.menu_book_outlined, color: AppTheme.warningAmber),
            const SizedBox(width: 12),
            _MetricCard(label: 'Rooms', value: '${data.rooms.length}',
              icon: Icons.meeting_room_outlined, color: AppTheme.infoCyan),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricCard(label: 'Batches', value: '${data.batches.length}',
              icon: Icons.group_work_outlined, color: const Color(0xFF8B5CF6)),
            const SizedBox(width: 12),
            _MetricCard(label: 'Schedule Entries', value: '${data.timetable.length}',
              icon: Icons.calendar_today_outlined, color: const Color(0xFFEC4899)),
          ],
        ),

        const SizedBox(height: 24),
        AppTheme.sectionHeader('Quick Actions', icon: Icons.flash_on_outlined),
        const SizedBox(height: 12),

        _QuickAction(icon: Icons.person_add_outlined, label: 'Manage Users',
          onTap: () => onNavigate(1)),
        const SizedBox(height: 8),
        _QuickAction(icon: Icons.edit_calendar_outlined, label: 'Manage Timetable',
          onTap: () => onNavigate(2)),
        const SizedBox(height: 8),
        _QuickAction(icon: Icons.school_outlined, label: 'Manage Academic',
          onTap: () => onNavigate(3)),
        const SizedBox(height: 8),
        _QuickAction(icon: Icons.auto_awesome_outlined, label: 'AI Routine Generator',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ChangeNotifierProvider.value(
              value: context.read<SupabaseService>(),
              child: AiRoutineGenerationScreen(repo: repo),
            ),
          ))),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cleanCardDecoration,
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary,
                  )),
                  Text(label, style: AppTheme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.cleanCardDecoration,
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppTheme.bodyMedium)),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}

// ───────── USERS TAB ─────────
class _UsersTab extends StatefulWidget {
  final DataRepository repo;
  final SupabaseService svc;
  final VoidCallback onRefresh;
  const _UsersTab({required this.repo, required this.svc, required this.onRefresh});

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  int _section = 0; // 0=teachers, 1=students, 2=batches
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _SectionPill(label: 'Teachers', isActive: _section == 0, onTap: () => setState(() => _section = 0)),
              const SizedBox(width: 8),
              _SectionPill(label: 'Students', isActive: _section == 1, onTap: () => setState(() => _section = 1)),
              const SizedBox(width: 8),
              _SectionPill(label: 'Batches', isActive: _section == 2, onTap: () => setState(() => _section = 2)),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: AppTheme.inputDecoration(
              label: 'Search...',
              prefixIcon: Icons.search_rounded,
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        Expanded(
          child: _section == 0
              ? _buildTeacherList()
              : _section == 1
                  ? _buildStudentList()
                  : _buildBatchList(),
        ),
      ],
    );
  }

  Widget _buildTeacherList() {
    final data = widget.repo.data!;
    final filtered = data.teachers.where((t) =>
      t.name.toLowerCase().contains(_search) ||
      t.initial.toLowerCase().contains(_search) ||
      t.email.toLowerCase().contains(_search)).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final t = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cleanCardDecoration,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: TeacherAvatar(
                      initial: t.initial,
                      profilePicUrl: t.profilePic,
                      radius: 20,
                    ),
                    title: Text(t.name, style: AppTheme.bodyMedium),
                    subtitle: Text('${t.initial} • ${t.designation}', style: AppTheme.caption),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editTeacher(t);
                        if (v == 'credentials') _setTeacherCredentials(t);
                        if (v == 'delete') _confirmDeleteTeacher(t);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'credentials', child: Text('Set Credentials')),
                        PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        _permissionChip(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          enabled: t.notificationsEnabled,
                          onToggle: () {
                            final newVal = !t.notificationsEnabled;
                            debugPrint('[UI] Teacher ${t.initial} notif toggle: ${t.notificationsEnabled} -> $newVal');
                            final idx = widget.repo.data!.teachers.indexWhere((x) => x.id == t.id);
                            if (idx != -1) {
                              widget.repo.data!.teachers[idx] = t.copyWith(notificationsEnabled: newVal);
                              setState(() {});
                            }
                            widget.svc.setTeacherNotificationsEnabled(t.id, newVal);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Teacher ${t.initial} notifications: $newVal'),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                        ),
                        const SizedBox(width: 8),
                        _permissionChip(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          enabled: t.emailEnabled,
                          onToggle: () {
                            final newVal = !t.emailEnabled;
                            debugPrint('[UI] Teacher ${t.initial} email toggle: ${t.emailEnabled} -> $newVal');
                            final idx = widget.repo.data!.teachers.indexWhere((x) => x.id == t.id);
                            if (idx != -1) {
                              widget.repo.data!.teachers[idx] = t.copyWith(emailEnabled: newVal);
                              setState(() {});
                            }
                            widget.svc.setTeacherEmailEnabled(t.id, newVal);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Teacher ${t.initial} email: $newVal'),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'addTeacher',
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: _addTeacher,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList() {
    final data = widget.repo.data!;
    final filtered = data.students.where((s) =>
      s.name.toLowerCase().contains(_search) ||
      s.studentId.toLowerCase().contains(_search)).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final s = filtered[i];
            final batch = widget.repo.batchById(s.batchId);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cleanCardDecoration,
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.successGreen.withValues(alpha: 0.1),
                      child: Text(s.name.isNotEmpty ? s.name[0] : '?',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.successGreen)),
                    ),
                    title: Text(s.name, style: AppTheme.bodyMedium),
                    subtitle: Text('${s.studentId} • ${batch?.name ?? s.batchId}', style: AppTheme.caption),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editStudent(s);
                        if (v == 'credentials') _setStudentCredentials(s);
                        if (v == 'delete') _confirmDeleteStudent(s);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'credentials', child: Text('Set Credentials')),
                        PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        _permissionChip(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          enabled: s.notificationsEnabled,
                          onToggle: () {
                            final newVal = !s.notificationsEnabled;
                            debugPrint('[UI] Student ${s.studentId} notif toggle: ${s.notificationsEnabled} -> $newVal');
                            final idx = widget.repo.data!.students.indexWhere((x) => x.studentId == s.studentId);
                            if (idx != -1) {
                              widget.repo.data!.students[idx] = s.copyWith(notificationsEnabled: newVal);
                              setState(() {});
                            }
                            widget.svc.setStudentNotificationsEnabled(s.studentId, newVal);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Student ${s.studentId} notifications: $newVal'),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                        ),
                        const SizedBox(width: 8),
                        _permissionChip(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          enabled: s.emailEnabled,
                          onToggle: () {
                            final newVal = !s.emailEnabled;
                            debugPrint('[UI] Student ${s.studentId} email toggle: ${s.emailEnabled} -> $newVal');
                            final idx = widget.repo.data!.students.indexWhere((x) => x.studentId == s.studentId);
                            if (idx != -1) {
                              widget.repo.data!.students[idx] = s.copyWith(emailEnabled: newVal);
                              setState(() {});
                            }
                            widget.svc.setStudentEmailEnabled(s.studentId, newVal);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Student ${s.studentId} email: $newVal'),
                              duration: const Duration(seconds: 2),
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'addStudent',
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: _addStudent,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchList() {
    final data = widget.repo.data!;
    final filtered = data.batches.where((b) =>
      b.name.toLowerCase().contains(_search) ||
      b.id.toLowerCase().contains(_search)).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final b = filtered[i];
            final studentCount = data.students.where((s) => s.batchId == b.id).length;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cleanCardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  child: const Icon(Icons.group_work_outlined, color: Color(0xFF8B5CF6), size: 20),
                ),
                title: Text(b.name, style: AppTheme.bodyMedium),
                subtitle: Text('ID: ${b.id} • Session: ${b.session} • $studentCount students', style: AppTheme.caption),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editBatch(b);
                    if (v == 'delete') _confirmDeleteBatch(b);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'addBatch',
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: _addBatch,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  // ── PERMISSION CHIP WIDGET ──

  Widget _permissionChip({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onToggle,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: enabled
                ? AppTheme.successGreen.withValues(alpha: 0.08)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: enabled
                  ? AppTheme.successGreen.withValues(alpha: 0.3)
                  : AppTheme.borderLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enabled ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: enabled ? AppTheme.successGreen : AppTheme.textHint,
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 14, color: enabled ? AppTheme.successGreen : AppTheme.textHint),
              const SizedBox(width: 4),
              Flexible(
                child: Text(label, style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppTheme.successGreen : AppTheme.textHint,
                ), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── TEACHER CRUD DIALOGS ──

  void _addTeacher() {
    final nameC = TextEditingController();
    final initialC = TextEditingController();
    final desigC = TextEditingController();
    final phoneC = TextEditingController();
    final emailC = TextEditingController();
    final deptC = TextEditingController();
    _showFormDialog(
      title: 'Add Teacher',
      fields: [
        _FormField('Name', nameC, Icons.person_outline),
        _FormField('Initial', initialC, Icons.badge_outlined),
        _FormField('Designation', desigC, Icons.school_outlined),
        _FormField('Department', deptC, Icons.business_outlined),
        _FormField('Email', emailC, Icons.email_outlined),
        _FormField('Phone', phoneC, Icons.phone_outlined),
      ],
      onConfirm: () async {
        final t = Teacher(
          id: initialC.text.trim(),
          name: nameC.text.trim(),
          initial: initialC.text.trim(),
          designation: desigC.text.trim(),
          phone: phoneC.text.trim(),
          email: emailC.text.trim(),
          homeDepartment: deptC.text.trim(),
        );
        await widget.svc.addTeacher(t);
        // Send welcome notification to the new teacher
        await widget.svc.createNotification(AppNotification(
          id: '',
          type: 'general',
          title: 'Welcome to SomoySutro!',
          body: 'You have been added as a teacher by Super Admin. Initial: ${t.initial}',
          recipientType: 'teacher',
          recipientId: t.initial,
          createdAt: '',
        ));
        widget.onRefresh();
      },
    );
  }

  void _editTeacher(Teacher t) {
    final nameC = TextEditingController(text: t.name);
    final desigC = TextEditingController(text: t.designation);
    final phoneC = TextEditingController(text: t.phone);
    final emailC = TextEditingController(text: t.email);
    final deptC = TextEditingController(text: t.homeDepartment);
    _showFormDialog(
      title: 'Edit Teacher',
      fields: [
        _FormField('Name', nameC, Icons.person_outline),
        _FormField('Designation', desigC, Icons.school_outlined),
        _FormField('Department', deptC, Icons.business_outlined),
        _FormField('Email', emailC, Icons.email_outlined),
        _FormField('Phone', phoneC, Icons.phone_outlined),
      ],
      onConfirm: () async {
        final updated = t.copyWith(
          name: nameC.text.trim(),
          designation: desigC.text.trim(),
          phone: phoneC.text.trim(),
          email: emailC.text.trim(),
          homeDepartment: deptC.text.trim(),
        );
        debugPrint('[UI] editTeacher: before -> notif=${t.notificationsEnabled}, email=${t.emailEnabled}');
        debugPrint('[UI] editTeacher: updated -> notif=${updated.notificationsEnabled}, email=${updated.emailEnabled}');
        // Optimistic local update — preserves permission fields via copyWith
        final idx = widget.repo.data!.teachers.indexWhere((x) => x.id == t.id);
        if (idx != -1) {
          widget.repo.data!.teachers[idx] = updated;
          setState(() {});
        }
        await widget.svc.updateTeacher(t.id, updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Teacher ${t.initial} updated (notif=${updated.notificationsEnabled}, email=${updated.emailEnabled})'),
            duration: const Duration(seconds: 3),
          ));
        }
      },
    );
  }

  void _setTeacherCredentials(Teacher t) {
    final emailC = TextEditingController(text: t.email);
    final passC = TextEditingController();
    _showFormDialog(
      title: 'Set Teacher Credentials',
      fields: [
        _FormField('Email', emailC, Icons.email_outlined),
        _FormField('Password', passC, Icons.lock_outline),
      ],
      onConfirm: () async {
        await widget.svc.setTeacherCredentials(
          t.id,
          emailC.text.trim(),
          passC.text,
        );
        widget.onRefresh();
      },
    );
  }

  void _confirmDeleteTeacher(Teacher t) {
    _showDeleteDialog('Delete Teacher', 'Remove "${t.name}" (${t.initial})?', () async {
      await widget.svc.deleteTeacher(t.id);
      widget.onRefresh();
    });
  }

  // ── STUDENT CRUD DIALOGS ──

  void _addStudent() {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    final batchC = TextEditingController();
    final emailC = TextEditingController();
    _showFormDialog(
      title: 'Add Student',
      fields: [
        _FormField('Student ID', idC, Icons.badge_outlined),
        _FormField('Name', nameC, Icons.person_outline),
        _FormField('Batch ID', batchC, Icons.group_work_outlined),
        _FormField('Email', emailC, Icons.email_outlined),
      ],
      onConfirm: () async {
        final s = Student(
          studentId: idC.text.trim(),
          name: nameC.text.trim(),
          batchId: batchC.text.trim(),
          email: emailC.text.trim(),
        );
        await widget.svc.addStudent(s);
        widget.onRefresh();
      },
    );
  }

  void _editStudent(Student s) {
    final nameC = TextEditingController(text: s.name);
    final batchC = TextEditingController(text: s.batchId);
    final emailC = TextEditingController(text: s.email ?? '');
    _showFormDialog(
      title: 'Edit Student',
      fields: [
        _FormField('Name', nameC, Icons.person_outline),
        _FormField('Batch ID', batchC, Icons.group_work_outlined),
        _FormField('Email', emailC, Icons.email_outlined),
      ],
      onConfirm: () async {
        final updated = s.copyWith(
          name: nameC.text.trim(),
          batchId: batchC.text.trim(),
          email: emailC.text.trim(),
        );
        debugPrint('[UI] editStudent: before -> notif=${s.notificationsEnabled}, email=${s.emailEnabled}');
        debugPrint('[UI] editStudent: updated -> notif=${updated.notificationsEnabled}, email=${updated.emailEnabled}');
        // Optimistic local update — preserves permission fields via copyWith
        final idx = widget.repo.data!.students.indexWhere((x) => x.studentId == s.studentId);
        if (idx != -1) {
          widget.repo.data!.students[idx] = updated;
          setState(() {});
        }
        await widget.svc.updateStudent(s.studentId, updated);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Student ${s.studentId} updated (notif=${updated.notificationsEnabled}, email=${updated.emailEnabled})'),
            duration: const Duration(seconds: 3),
          ));
        }
      },
    );
  }

  void _setStudentCredentials(Student s) {
    final emailC = TextEditingController(text: s.email ?? '');
    final passC = TextEditingController();
    _showFormDialog(
      title: 'Set Student Credentials',
      fields: [
        _FormField('Email', emailC, Icons.email_outlined),
        _FormField('Password', passC, Icons.lock_outline),
      ],
      onConfirm: () async {
        await widget.svc.setStudentCredentials(
          s.studentId,
          emailC.text.trim(),
          passC.text,
        );
        widget.onRefresh();
      },
    );
  }

  void _confirmDeleteStudent(Student s) {
    _showDeleteDialog('Delete Student', 'Remove "${s.name}" (${s.studentId})?', () async {
      await widget.svc.deleteStudent(s.studentId);
      widget.onRefresh();
    });
  }

  // ── BATCH CRUD DIALOGS ──

  void _addBatch() {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    final sessionC = TextEditingController();
    _showFormDialog(
      title: 'Add Batch',
      fields: [
        _FormField('Batch ID', idC, Icons.tag_outlined),
        _FormField('Batch Name', nameC, Icons.group_work_outlined),
        _FormField('Session', sessionC, Icons.calendar_today_outlined),
      ],
      onConfirm: () async {
        final b = Batch(id: idC.text.trim(), name: nameC.text.trim(), session: sessionC.text.trim());
        await widget.svc.addBatch(b);
        widget.onRefresh();
      },
    );
  }

  void _editBatch(Batch b) {
    final nameC = TextEditingController(text: b.name);
    final sessionC = TextEditingController(text: b.session);
    _showFormDialog(
      title: 'Edit Batch',
      fields: [
        _FormField('Batch Name', nameC, Icons.group_work_outlined),
        _FormField('Session', sessionC, Icons.calendar_today_outlined),
      ],
      onConfirm: () async {
        final updated = Batch(id: b.id, name: nameC.text.trim(), session: sessionC.text.trim());
        await widget.svc.updateBatch(b.id, updated);
        widget.onRefresh();
      },
    );
  }

  void _confirmDeleteBatch(Batch b) {
    _showDeleteDialog('Delete Batch', 'Remove "${b.name}" (${b.id})?', () async {
      await widget.svc.deleteBatch(b.id);
      widget.onRefresh();
    });
  }

  // ── GENERIC DIALOGS ──

  void _showFormDialog({
    required String title,
    required List<_FormField> fields,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text(title, style: AppTheme.heading3),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: f.ctrl,
                  decoration: AppTheme.inputDecoration(label: f.label, prefixIcon: f.icon),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String title, String msg, Future<void> Function() onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text(title, style: AppTheme.heading3),
        content: Text(msg, style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FormField {
  final String label;
  final TextEditingController ctrl;
  final IconData icon;
  const _FormField(this.label, this.ctrl, this.icon);
}

class _SectionPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _SectionPill({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: isActive ? AppTheme.primaryBlue : AppTheme.borderLight),
          ),
          alignment: Alignment.center,
          child: Text(label, style: GoogleFonts.poppins(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          )),
        ),
      ),
    );
  }
}

// ───────── TIMETABLE TAB ─────────
class _TimetableTab extends StatefulWidget {
  final DataRepository repo;
  final SupabaseService svc;
  final VoidCallback onRefresh;
  const _TimetableTab({required this.repo, required this.svc, required this.onRefresh});

  @override
  State<_TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<_TimetableTab> {
  String _dayFilter = 'All';
  String _search = '';
  final _days = ['All', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];

  @override
  Widget build(BuildContext context) {
    final all = widget.repo.getAllTimetableEntries();
    var filtered = _dayFilter == 'All' ? all : all.where((e) => e.day == _dayFilter).toList();
    if (_search.isNotEmpty) {
      filtered = filtered.where((e) =>
        e.courseCode.toLowerCase().contains(_search) ||
        e.teacherInitial.toLowerCase().contains(_search) ||
        e.batchId.toLowerCase().contains(_search)).toList();
    }
    filtered.sort((a, b) {
      final d = a.day.compareTo(b.day);
      return d != 0 ? d : a.start.compareTo(b.start);
    });

    return Column(
      children: [
        // Day filter
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            itemCount: _days.length,
            itemBuilder: (_, i) {
              final d = _days[i];
              final active = d == _dayFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _dayFilter = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.primaryBlue : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? AppTheme.primaryBlue : AppTheme.borderLight),
                    ),
                    child: Text(d, style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: active ? Colors.white : AppTheme.textSecondary,
                    )),
                  ),
                ),
              );
            },
          ),
        ),

        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: AppTheme.inputDecoration(label: 'Search by course, teacher, batch...', prefixIcon: Icons.search),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),

        // Action bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('${filtered.length} entries', style: AppTheme.caption),
              const Spacer(),
              _SmallBtn(icon: Icons.auto_awesome_outlined, label: 'AI Generate', onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: context.read<SupabaseService>(),
                    child: AiRoutineGenerationScreen(repo: widget.repo),
                  ),
                ));
              }),
              const SizedBox(width: 8),
              _SmallBtn(icon: Icons.upload_outlined, label: 'Import', onTap: _importTimetable),
              const SizedBox(width: 8),
              _SmallBtn(icon: Icons.picture_as_pdf_outlined, label: 'Export PDF', onTap: _exportTimetable),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Entry list
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('No entries found', style: AppTheme.subtitle))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final e = filtered[i];
                    final course = widget.repo.courseByCode(e.courseCode);
                    final teacher = widget.repo.teacherByInitial(e.teacherInitial);
                    final batch = widget.repo.batchById(e.batchId);
                    final room = widget.repo.roomById(e.roomId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: AppTheme.cleanCardDecoration,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        leading: Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.typeColor(e.type),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        title: Text(
                          '${course?.title ?? e.courseCode} (${e.courseCode})',
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${e.day} • ${e.start}-${e.end} • ${teacher?.name ?? e.teacherInitial} • ${batch?.name ?? e.batchId}${room != null ? ' • ${room.name}' : ''}',
                          style: AppTheme.caption,
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'edit') _editEntry(e);
                            if (v == 'delete') _confirmDeleteEntry(e);
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // FAB to add
        Padding(
          padding: const EdgeInsets.only(bottom: 16, right: 16),
          child: Align(
            alignment: Alignment.bottomRight,
            child: FloatingActionButton(
              heroTag: 'addEntry',
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              onPressed: _addEntry,
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ],
    );
  }

  void _addEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScheduleScreen(repo: widget.repo)),
    );
    if (result == true) widget.onRefresh();
  }

  void _editEntry(TimetableEntry entry) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScheduleScreen(repo: widget.repo, existing: entry)),
    );
    if (result == true) widget.onRefresh();
  }

  void _confirmDeleteEntry(TimetableEntry e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text('Delete Entry', style: AppTheme.heading3),
        content: Text('Remove ${e.courseCode} on ${e.day} ${e.start}-${e.end}?', style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.repo.removeTimetableEntry(e);
              widget.onRefresh();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _exportTimetable() {
    final entries = widget.repo.getAllTimetableEntries();
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No entries to export'), backgroundColor: AppTheme.errorRed),
      );
      return;
    }
    _exportAsPdf(entries);
  }

  Future<void> _exportAsPdf(List<TimetableEntry> entries) async {
    final pdf = pw.Document();
    const days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
    const slotHeaders = ['09:00-10:15', '10:15-11:30', '11:30-12:45', '13:30-14:45'];
    const slotStarts = ['09:00', '10:15', '11:30', '13:30'];

    // Group entries by batch
    final batchIds = entries.map((e) => e.batchId).toSet().toList();
    batchIds.sort((a, b) {
      final ba = widget.repo.batchById(a);
      final bb = widget.repo.batchById(b);
      return (ba?.name ?? a).compareTo(bb?.name ?? b);
    });

    final titleStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);
    final headerStyle = pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold);
    const cellPad = pw.EdgeInsets.all(3);

    // Build all batch sections as widgets
    final sections = <pw.Widget>[];

    for (int bi = 0; bi < batchIds.length; bi++) {
      final batchId = batchIds[bi];
      final batch = widget.repo.batchById(batchId);
      final batchName = batch?.name ?? batchId;
      final batchSession = batch?.session ?? '';
      final batchEntries = entries.where((e) => e.batchId == batchId).toList();

      // Build grid: day -> startTime -> list of entries
      final grid = <String, Map<String, List<TimetableEntry>>>{};
      for (final d in days) {
        grid[d] = {};
        for (final s in slotStarts) {
          grid[d]![s] = [];
        }
      }
      for (final e in batchEntries) {
        final closest = slotStarts.lastWhere(
          (s) => s.compareTo(e.start) <= 0,
          orElse: () => slotStarts.first,
        );
        grid[e.day]?[closest]?.add(e);
      }

      if (bi > 0) {
        sections.add(pw.SizedBox(height: 20));
      }

      sections.add(
        pw.Text(
          'Batch: $batchName${batchSession.isNotEmpty ? ' ($batchSession)' : ''} - ${batchEntries.length} entries',
          style: titleStyle,
        ),
      );
      sections.add(pw.SizedBox(height: 6));

      sections.add(
        pw.TableHelper.fromTextArray(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
          headerStyle: headerStyle,
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellPadding: cellPad,
          headerAlignment: pw.Alignment.center,
          cellAlignment: pw.Alignment.center,
          columnWidths: {
            0: const pw.FixedColumnWidth(50),
            for (int i = 0; i < slotHeaders.length; i++)
              i + 1: const pw.FlexColumnWidth(),
          },
          headers: ['Day', ...slotHeaders],
          data: days.map((day) {
            return [
              day,
              ...slotStarts.map((slot) {
                final cellEntries = grid[day]?[slot] ?? [];
                if (cellEntries.isEmpty) return '';
                return cellEntries.map((e) {
                  final course = widget.repo.courseByCode(e.courseCode);
                  final room = widget.repo.roomById(e.roomId);
                  final courseName = course?.code ?? e.courseCode;
                  final roomName = room?.name ?? '';
                  final group = e.group != null ? ' (${e.group})' : '';
                  return '$courseName$group\n${e.teacherInitial}\n${roomName.isNotEmpty ? roomName : e.type}';
                }).join('\n---\n');
              }),
            ];
          }).toList(),
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('EdTE - Weekly Routine', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  'Exported: ${DateTime.now().toString().split('.').first}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${batchIds.length} batch(es)  |  ${entries.length} total entries  |  Break: 12:45-13:30  |  Friday: Off',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Divider(thickness: 0.5),
            pw.SizedBox(height: 4),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Dept. of Educational Technology & Engineering',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
          ],
        ),
        build: (context) => sections,
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'EdTE_Timetable_${DateTime.now().toIso8601String().split('T').first}',
    );
  }

  void _importTimetable() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Import Timetable', style: AppTheme.heading3),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.file_upload_outlined, color: AppTheme.primaryBlue),
                title: Text('Import from file (JSON / CSV)', style: AppTheme.body),
                subtitle: Text('Pick a .json or .csv file', style: AppTheme.caption),
                onTap: () { Navigator.pop(ctx); _importFromFile(); },
              ),
              ListTile(
                leading: const Icon(Icons.paste_outlined, color: AppTheme.primaryBlue),
                title: Text('Paste JSON data', style: AppTheme.body),
                subtitle: Text('Paste timetable JSON from clipboard', style: AppTheme.caption),
                onTap: () { Navigator.pop(ctx); _importFromPaste(); },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.grey),
                title: Text('Copy CSV template', style: AppTheme.body),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: TimetableExportImport.getCSVTemplate()));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('CSV template copied to clipboard'), backgroundColor: AppTheme.successGreen),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Colors.grey),
                title: Text('Copy JSON template', style: AppTheme.body),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: TimetableExportImport.getJSONTemplate()));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('JSON template copied to clipboard'), backgroundColor: AppTheme.successGreen),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final String content;
      if (file.bytes != null) {
        content = utf8.decode(file.bytes!);
      } else if (file.path != null) {
        content = await File(file.path!).readAsString();
      } else {
        throw Exception('Could not read file');
      }

      final ext = file.extension?.toLowerCase() ?? '';
      List<TimetableEntry> entries;
      if (ext == 'csv') {
        entries = TimetableExportImport.fromCSV(content);
      } else {
        entries = TimetableExportImport.fromJSON(content);
      }

      await _processImport(entries);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  void _importFromPaste() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text('Import Timetable JSON', style: AppTheme.heading3),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paste JSON data below:', style: AppTheme.caption),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 8,
                decoration: AppTheme.inputDecoration(label: 'JSON data'),
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final entries = TimetableExportImport.fromJSON(ctrl.text);
                await _processImport(entries);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: AppTheme.errorRed),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _processImport(List<TimetableEntry> entries) async {
    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No entries found in file'), backgroundColor: AppTheme.errorRed),
        );
      }
      return;
    }

    final errors = TimetableExportImport.validateEntries(entries);
    if (errors.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Validation: ${errors.first}${errors.length > 1 ? ' (+${errors.length - 1} more)' : ''}'),
          backgroundColor: AppTheme.errorRed,
          duration: const Duration(seconds: 4),
        ));
      }
      return;
    }

    // Show progress dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text('Importing ${entries.length} entries...', style: AppTheme.body),
            ],
          ),
        ),
      );
    }

    try {
      final count = await widget.svc.bulkAddTimetableEntries(entries);
      if (mounted) Navigator.of(context).pop(); // close progress
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Imported $count entries successfully'),
          backgroundColor: AppTheme.successGreen,
        ));
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop(); // close progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppTheme.errorRed,
        ));
      }
    }
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryBlueLight,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryBlue),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }
}

// ───────── ACADEMIC TAB ─────────
class _AcademicTab extends StatefulWidget {
  final DataRepository repo;
  final SupabaseService svc;
  final VoidCallback onRefresh;
  const _AcademicTab({required this.repo, required this.svc, required this.onRefresh});

  @override
  State<_AcademicTab> createState() => _AcademicTabState();
}

class _AcademicTabState extends State<_AcademicTab> {
  int _section = 0; // 0=courses, 1=rooms
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Section pills
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              _SectionPill(label: 'Courses', isActive: _section == 0, onTap: () => setState(() => _section = 0)),
              const SizedBox(width: 8),
              _SectionPill(label: 'Rooms', isActive: _section == 1, onTap: () => setState(() => _section = 1)),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: AppTheme.inputDecoration(label: 'Search...', prefixIcon: Icons.search_rounded),
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        Expanded(
          child: _section == 0 ? _buildCourseList() : _buildRoomList(),
        ),
      ],
    );
  }

  Widget _buildCourseList() {
    final data = widget.repo.data!;
    final filtered = data.courses.where((c) =>
      c.code.toLowerCase().contains(_search) ||
      c.title.toLowerCase().contains(_search)).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final c = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cleanCardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.warningAmber.withValues(alpha: 0.1),
                  child: const Icon(Icons.menu_book_outlined, color: AppTheme.warningAmber, size: 20),
                ),
                title: Text(c.title, style: AppTheme.bodyMedium),
                subtitle: Text('Code: ${c.code}', style: AppTheme.caption),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editCourse(c);
                    if (v == 'delete') _confirmDeleteCourse(c);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'addCourse',
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: _addCourse,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomList() {
    final data = widget.repo.data!;
    final filtered = data.rooms.where((r) =>
      r.name.toLowerCase().contains(_search) ||
      r.id.toLowerCase().contains(_search)).toList();

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final r = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: AppTheme.cleanCardDecoration,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: AppTheme.infoCyan.withValues(alpha: 0.1),
                  child: const Icon(Icons.meeting_room_outlined, color: AppTheme.infoCyan, size: 20),
                ),
                title: Text(r.name, style: AppTheme.bodyMedium),
                subtitle: Text('ID: ${r.id}', style: AppTheme.caption),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _editRoom(r);
                    if (v == 'delete') _confirmDeleteRoom(r);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16, bottom: 16,
          child: FloatingActionButton(
            heroTag: 'addRoom',
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            onPressed: _addRoom,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  // ── COURSE CRUD ──

  void _addCourse() {
    final codeC = TextEditingController();
    final titleC = TextEditingController();
    _showFormDialog(
      title: 'Add Course',
      fields: [
        _FormField('Course Code', codeC, Icons.code_outlined),
        _FormField('Course Title', titleC, Icons.menu_book_outlined),
      ],
      onConfirm: () async {
        final code = codeC.text.trim();
        final title = titleC.text.trim();
        await widget.svc.addCourse(Course(code: code, title: title));
        // Notify all teachers who have notifications enabled
        final teachers = widget.repo.data?.teachers ?? [];
        for (final t in teachers) {
          if (t.notificationsEnabled) {
            await widget.svc.createNotification(AppNotification(
              id: '',
              type: 'general',
              title: 'New Course Added',
              body: 'Course "$title" ($code) has been added by Super Admin.',
              recipientType: 'teacher',
              recipientId: t.initial,
              createdAt: '',
            ));
          }
        }
        widget.onRefresh();
      },
    );
  }

  void _editCourse(Course c) {
    final titleC = TextEditingController(text: c.title);
    _showFormDialog(
      title: 'Edit Course',
      fields: [
        _FormField('Course Title', titleC, Icons.menu_book_outlined),
      ],
      onConfirm: () async {
        await widget.svc.updateCourse(c.code, Course(code: c.code, title: titleC.text.trim()));
        widget.onRefresh();
      },
    );
  }

  void _confirmDeleteCourse(Course c) {
    _showDeleteDialog('Delete Course', 'Remove "${c.title}" (${c.code})?', () async {
      await widget.svc.deleteCourse(c.code);
      widget.onRefresh();
    });
  }

  // ── ROOM CRUD ──

  void _addRoom() {
    final idC = TextEditingController();
    final nameC = TextEditingController();
    _showFormDialog(
      title: 'Add Room',
      fields: [
        _FormField('Room ID', idC, Icons.tag_outlined),
        _FormField('Room Name', nameC, Icons.meeting_room_outlined),
      ],
      onConfirm: () async {
        await widget.svc.addRoom(Room(id: idC.text.trim(), name: nameC.text.trim()));
        widget.onRefresh();
      },
    );
  }

  void _editRoom(Room r) {
    final nameC = TextEditingController(text: r.name);
    _showFormDialog(
      title: 'Edit Room',
      fields: [
        _FormField('Room Name', nameC, Icons.meeting_room_outlined),
      ],
      onConfirm: () async {
        await widget.svc.updateRoom(r.id, Room(id: r.id, name: nameC.text.trim()));
        widget.onRefresh();
      },
    );
  }

  void _confirmDeleteRoom(Room r) {
    _showDeleteDialog('Delete Room', 'Remove "${r.name}" (${r.id})?', () async {
      await widget.svc.deleteRoom(r.id);
      widget.onRefresh();
    });
  }

  // ── GENERIC DIALOGS ──

  void _showFormDialog({
    required String title,
    required List<_FormField> fields,
    required Future<void> Function() onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text(title, style: AppTheme.heading3),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: f.ctrl,
                  decoration: AppTheme.inputDecoration(label: f.label, prefixIcon: f.icon),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await onConfirm();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String title, String msg, Future<void> Function() onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        title: Text(title, style: AppTheme.heading3),
        content: Text(msg, style: AppTheme.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              await onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
