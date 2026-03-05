import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../models/batch.dart';
import '../utils/app_theme.dart';
import '../widgets/schedule_card.dart';
import 'monthly_routine_screen.dart';
import 'notification_screen.dart';

class StudentScreen extends StatefulWidget {
  final DataRepository repo;
  const StudentScreen({super.key, required this.repo});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  String? _selectedBatchId;
  String _selectedDay = _currentDay();
  final _searchCtrl = TextEditingController();

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
    final batches = widget.repo.data?.batches ?? [];
    final filtered = _searchCtrl.text.isEmpty
        ? batches
        : batches.where((b) =>
            b.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
            b.id.toLowerCase().contains(_searchCtrl.text.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppTheme.studentGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text('Schedule', style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
            )),
          ],
        ),
        actions: [
          Builder(
            builder: (ctx) {
              final svc = ctx.read<SupabaseService>();
              final studentId = svc.currentStudent?.studentId ?? '';
              if (studentId.isEmpty) return const SizedBox();
              return NotificationBell(
                recipientType: 'student',
                recipientId: studentId,
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search bar + batch selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search batch (e.g. CSE 2024)',
                    hintStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textHint),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textHint, size: 20),
                    filled: true,
                    fillColor: AppTheme.inputFill,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                // Batch pills (if not selected)
                if (_selectedBatchId == null && filtered.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => _batchPill(filtered[i]),
                    ),
                  ),
                ],

                // Selected batch indicator
                if (_selectedBatchId != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              batches.firstWhere((b) => b.id == _selectedBatchId,
                                orElse: () => Batch(id: '', name: _selectedBatchId!, session: '')).name,
                              style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _selectedBatchId = null),
                              child: const Icon(Icons.close, size: 16, color: AppTheme.primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: AppTheme.dividerColor),

          // Day selector + Monthly Routine button
          if (_selectedBatchId != null) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final batch = (widget.repo.data?.batches ?? []).firstWhere(
                          (b) => b.id == _selectedBatchId,
                          orElse: () => Batch(id: _selectedBatchId!, name: _selectedBatchId!, session: ''),
                        );
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MonthlyRoutineScreen(
                            repo: widget.repo,
                            title: '${batch.name} — Monthly Routine',
                            batchId: _selectedBatchId,
                            showTeacher: true,
                            showBatch: false,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('View Monthly Routine'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          ],

          // Schedule list
          Expanded(
            child: _selectedBatchId == null
                ? _emptyState()
                : _scheduleList(),
          ),
        ],
      ),
    );
  }

  Widget _batchPill(Batch batch) {
    return GestureDetector(
      onTap: () => setState(() => _selectedBatchId = batch.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.inputFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text(
          batch.name,
          style: GoogleFonts.poppins(
            fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _dayPill(String day) {
    final isSelected = _selectedDay == day;
    // Get mock date number for visual
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

  Widget _scheduleList() {
    final entries = widget.repo.batchEntriesForDay(_selectedBatchId!, _selectedDay);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_outlined, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 12),
            Text('No classes on $_selectedDay', style: AppTheme.subtitle),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  "Today's Schedule",
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length} Sessions',
                  style: GoogleFonts.poppins(
                    fontSize: 13, color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }
        return ScheduleCard(
          entry: entries[i - 1],
          repo: widget.repo,
          showTeacher: true,
          showBatch: false,
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.school_outlined, size: 56, color: AppTheme.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Select a Batch', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
          )),
          const SizedBox(height: 6),
          Text('Search and select a batch to view schedule', style: AppTheme.caption),
        ],
      ),
    );
  }
}
