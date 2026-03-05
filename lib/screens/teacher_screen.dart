import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../models/teacher.dart';
import '../utils/app_theme.dart';
import '../widgets/schedule_card.dart';
import 'book_appointment_screen.dart';
import 'monthly_routine_screen.dart';

class TeacherScreen extends StatefulWidget {
  final DataRepository repo;
  const TeacherScreen({super.key, required this.repo});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  final _searchCtrl = TextEditingController();
  Teacher? _selectedTeacher;
  String _selectedDay = _currentDay();

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static String _currentDay() {
    const dayMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return dayMap[DateTime.now().weekday] ?? 'Sun';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTeachers = widget.repo.data?.teachers ?? [];
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? allTeachers
        : allTeachers.where((t) =>
            t.initial.toLowerCase().contains(q) ||
            t.name.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Teacher Lookup', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        leading: _selectedTeacher != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => setState(() => _selectedTeacher = null),
              )
            : null,
      ),
      body: _selectedTeacher != null
          ? _teacherDetail(_selectedTeacher!)
          : _teacherSearch(filtered),
    );
  }

  Widget _teacherSearch(List<Teacher> filtered) {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by teacher initial (e.g. SAF)',
              hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textHint),
              prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 20),
              filled: true,
              fillColor: AppTheme.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Divider(height: 1, color: AppTheme.dividerColor),

        // Teacher list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_search_outlined, size: 48, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text('No teachers found', style: AppTheme.subtitle),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _teacherCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _teacherCard(Teacher teacher) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTeacher = teacher),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Profile avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryBlueLight,
                  backgroundImage: teacher.profilePic != null
                      ? NetworkImage(teacher.profilePic!)
                      : null,
                  child: teacher.profilePic == null
                      ? Text(
                          teacher.initial.substring(0, teacher.initial.length > 2 ? 2 : teacher.initial.length),
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        teacher.designation,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        teacher.homeDepartment,
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),
                AppTheme.chip(teacher.initial, bg: AppTheme.primaryBlueLight, fg: AppTheme.primaryBlue),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: AppTheme.dividerColor),
            const SizedBox(height: 12),

            // Contact info
            if (teacher.email.isNotEmpty)
              _infoRow(Icons.email_outlined, teacher.email),
            if (teacher.phone.isNotEmpty)
              _infoRow(Icons.phone_outlined, teacher.phone),
          ],
        ),
      ),
    );
  }

  Widget _teacherDetail(Teacher teacher) {
    final entries = widget.repo.teacherEntriesForDay(teacher.initial, _selectedDay);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Teacher header card
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryBlueLight,
                    backgroundImage: teacher.profilePic != null
                        ? NetworkImage(teacher.profilePic!)
                        : null,
                    child: teacher.profilePic == null
                        ? Text(
                            teacher.initial.substring(0, teacher.initial.length > 2 ? 2 : teacher.initial.length),
                            style: GoogleFonts.poppins(
                              fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teacher.name, style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                        )),
                        Text(teacher.designation, style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textSecondary,
                        )),
                        Text(teacher.homeDepartment, style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textHint,
                        )),
                      ],
                    ),
                  ),
                  AppTheme.chip(teacher.initial, bg: AppTheme.primaryBlueLight, fg: AppTheme.primaryBlue),
                ],
              ),
              const SizedBox(height: 16),
              // Contact pills
              Row(
                children: [
                  if (teacher.email.isNotEmpty)
                    Expanded(
                      child: _contactPill(Icons.email_outlined, teacher.email),
                    ),
                  if (teacher.email.isNotEmpty && teacher.phone.isNotEmpty)
                    const SizedBox(width: 8),
                  if (teacher.phone.isNotEmpty)
                    Expanded(
                      child: _contactPill(Icons.phone_outlined, teacher.phone),
                    ),
                ],
              ),
            ],
          ),
        ),

        Divider(height: 1, color: AppTheme.dividerColor),

        // Action buttons: Monthly Routine + Book Appointment
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MonthlyRoutineScreen(
                        repo: widget.repo,
                        title: '${teacher.initial} — Monthly Routine',
                        teacherInitial: teacher.initial,
                        showTeacher: false,
                        showBatch: true,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month, size: 16),
                  label: const Text('Monthly Routine'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: context.read<SupabaseService>(),
                        child: BookAppointmentScreen(teacher: teacher),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.event_available, size: 16),
                  label: const Text('Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        Divider(height: 1, color: AppTheme.dividerColor),

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

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text("Today's Schedule", style: GoogleFonts.poppins(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
              )),
              const Spacer(),
              if (entries.isNotEmpty)
                Text('${entries.length} Sessions', style: GoogleFonts.poppins(
                  fontSize: 13, color: AppTheme.textSecondary,
                )),
            ],
          ),
        ),

        // Schedule cards
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.free_breakfast_outlined, size: 40, color: AppTheme.textHint),
                  const SizedBox(height: 8),
                  Text('No classes on $_selectedDay', style: AppTheme.subtitle),
                ],
              ),
            ),
          )
        else
          ...entries.map((e) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScheduleCard(
              entry: e,
              repo: widget.repo,
              showTeacher: false,
              showBatch: true,
            ),
          )),

        // Footer note
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '* Schedule updates automatically every 15 minutes',
            style: GoogleFonts.poppins(
              fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textHint,
            ),
          ),
        ),
      ],
    );
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

  Widget _contactPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textHint),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(
              fontSize: 13, color: AppTheme.textSecondary,
            )),
          ),
        ],
      ),
    );
  }
}
