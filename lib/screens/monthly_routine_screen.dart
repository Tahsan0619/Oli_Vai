import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timetable_entry.dart';
import '../services/data_repository.dart';
import '../utils/app_theme.dart';
import '../widgets/schedule_card.dart';

/// Reusable monthly calendar that populates a weekly timetable
/// across the entire month. Works for both teacher & batch views.
class MonthlyRoutineScreen extends StatefulWidget {
  final DataRepository repo;
  final String title;

  /// Provide exactly ONE of these:
  final String? teacherInitial; // teacher routine
  final String? batchId; // batch/student routine

  final bool showTeacher;
  final bool showBatch;

  const MonthlyRoutineScreen({
    super.key,
    required this.repo,
    required this.title,
    this.teacherInitial,
    this.batchId,
    this.showTeacher = true,
    this.showBatch = false,
  });

  @override
  State<MonthlyRoutineScreen> createState() => _MonthlyRoutineScreenState();
}

class _MonthlyRoutineScreenState extends State<MonthlyRoutineScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  static const _weekDayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const _dayNameMap = {
    DateTime.sunday: 'Sun',
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _selectedDate = now;
  }

  /// Get entries for a particular day-of-week name (e.g. "Mon")
  List<TimetableEntry> _entriesForDayName(String dayName) {
    if (widget.teacherInitial != null) {
      return widget.repo.teacherEntriesForDay(widget.teacherInitial!, dayName);
    } else if (widget.batchId != null) {
      return widget.repo.batchEntriesForDay(widget.batchId!, dayName);
    }
    return [];
  }

  /// Check if a date has classes
  bool _dateHasClasses(DateTime date) {
    final dayName = _dayNameMap[date.weekday] ?? '';
    return _entriesForDayName(dayName).isNotEmpty;
  }

  /// Count sessions for a date
  int _sessionCount(DateTime date) {
    final dayName = _dayNameMap[date.weekday] ?? '';
    return _entriesForDayName(dayName).length;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7; // 0=Sun

    // Build calendar grid dates
    final List<DateTime?> calendarDays = [];
    for (int i = 0; i < firstWeekday; i++) {
      calendarDays.add(null); // empty cells before month starts
    }
    for (int d = 1; d <= daysInMonth; d++) {
      calendarDays.add(DateTime(_currentMonth.year, _currentMonth.month, d));
    }

    final selectedDayName = _selectedDate != null
        ? _dayNameMap[_selectedDate!.weekday] ?? ''
        : '';
    final selectedEntries = _selectedDate != null
        ? _entriesForDayName(selectedDayName)
        : <TimetableEntry>[];

    final now = DateTime.now();
    final isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text(widget.title, style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
      ),
      body: Column(
        children: [
          // ── Month header ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.textPrimary),
                  onPressed: _prevMonth,
                  splashRadius: 20,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _monthYearString(_currentMonth),
                      style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppTheme.textPrimary),
                  onPressed: _nextMonth,
                  splashRadius: 20,
                ),
              ],
            ),
          ),

          // ── Weekday labels ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _weekDayLabels.map((d) => Expanded(
                child: Center(
                  child: Text(
                    d.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: d == 'Fri' ? AppTheme.errorRed.withValues(alpha: 0.5) : AppTheme.textHint,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ── Calendar grid ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.0,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: calendarDays.length,
              itemBuilder: (_, i) {
                final date = calendarDays[i];
                if (date == null) return const SizedBox();
                return _calendarCell(date, now);
              },
            ),
          ),

          Divider(height: 1, color: AppTheme.dividerColor),

          // ── Selected day schedule ──
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    isToday
                        ? "Today's Schedule"
                        : '$selectedDayName, ${_selectedDate!.day} ${_monthName(_selectedDate!.month)}',
                    style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (selectedEntries.isNotEmpty)
                    Text(
                      '${selectedEntries.length} Sessions',
                      style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),

          // ── Entries list ──
          Expanded(
            child: _selectedDate == null
                ? Center(
                    child: Text('Tap a date to see schedule', style: AppTheme.subtitle),
                  )
                : selectedEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              selectedDayName == 'Fri'
                                  ? Icons.weekend_outlined
                                  : Icons.free_breakfast_outlined,
                              size: 44, color: AppTheme.textHint,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedDayName == 'Fri' ? 'Day Off' : 'No classes',
                              style: AppTheme.subtitle,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: selectedEntries.length,
                        itemBuilder: (_, i) => ScheduleCard(
                          entry: selectedEntries[i],
                          repo: widget.repo,
                          showTeacher: widget.showTeacher,
                          showBatch: widget.showBatch,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _calendarCell(DateTime date, DateTime now) {
    final isSelected = _selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day;
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final hasClasses = _dateHasClasses(date);
    final isFriday = date.weekday == DateTime.friday;
    final count = _sessionCount(date);

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : isToday
                  ? AppTheme.primaryBlueLight
                  : isFriday
                      ? AppTheme.errorRedLight.withValues(alpha: 0.4)
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: isToday && !isSelected
              ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.4), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isFriday
                        ? AppTheme.errorRed.withValues(alpha: 0.5)
                        : AppTheme.textPrimary,
              ),
            ),
            if (hasClasses && !isFriday)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.successGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _monthYearString(DateTime date) {
    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month];
  }
}
