import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/timetable_entry.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final DataRepository repo;
  final TimetableEntry? existing;
  const AddEditScheduleScreen({super.key, required this.repo, this.existing});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  bool get _isEditing => widget.existing != null;
  final _days = ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  final _types = ['Lecture', 'Tutorial', 'Sessional', 'Online'];
  final _groups = ['None', 'G-1', 'G-2'];
  final _modes = ['Onsite', 'Online'];

  late String _selectedDay;
  late String _selectedType;
  late String _selectedGroup;
  late String _selectedMode;
  String? _selectedBatchId;
  String? _selectedCourseCode;
  String? _selectedTeacherInitial;
  String? _selectedRoomId;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _selectedDay = e?.day ?? 'Sat';
    _selectedType = e?.type ?? 'Lecture';
    _selectedGroup = e?.group ?? 'None';
    _selectedMode = e?.mode ?? 'Onsite';
    _selectedBatchId = e?.batchId;
    _selectedCourseCode = e?.courseCode;
    _selectedTeacherInitial = e?.teacherInitial;
    _selectedRoomId = e?.roomId;
    _startTime = _parseTime(e?.start ?? '08:00');
    _endTime = _parseTime(e?.end ?? '09:30');
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (_selectedBatchId == null || _selectedCourseCode == null || _selectedTeacherInitial == null) {
      _snack('Please fill all required fields', isError: true);
      return;
    }
    if (_selectedMode == 'Onsite' && _selectedRoomId == null) {
      _snack('Room is required for onsite classes', isError: true);
      return;
    }
    setState(() => _saving = true);

    final entry = TimetableEntry(
      day: _selectedDay,
      batchId: _selectedBatchId!,
      teacherInitial: _selectedTeacherInitial!,
      courseCode: _selectedCourseCode!,
      type: _selectedType,
      group: _selectedGroup == 'None' ? null : _selectedGroup,
      roomId: _selectedMode == 'Online' ? null : _selectedRoomId,
      mode: _selectedMode,
      start: _formatTime(_startTime),
      end: _formatTime(_endTime),
    );

    try {
      if (_isEditing) {
        await widget.repo.updateTimetableEntry(widget.existing!, entry);
      } else {
        await widget.repo.addTimetableEntry(entry);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.repo.data!;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditing ? 'Edit Schedule Entry' : 'Add Schedule Entry',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ───── Class Identity ─────
          _SectionCard(
            title: 'Class Identity',
            icon: Icons.class_outlined,
            children: [
              // Batch
              _LabeledDropdown<String>(
                label: 'BATCH',
                value: _selectedBatchId,
                hint: 'Select batch',
                items: data.batches.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.name} (${b.id})'))).toList(),
                onChanged: (v) => setState(() => _selectedBatchId = v),
              ),
              const SizedBox(height: 14),
              // Course
              _LabeledDropdown<String>(
                label: 'COURSE',
                value: _selectedCourseCode,
                hint: 'Select course',
                items: data.courses.map((c) => DropdownMenuItem(value: c.code, child: Text('${c.title} (${c.code})'))).toList(),
                onChanged: (v) => setState(() => _selectedCourseCode = v),
              ),
              const SizedBox(height: 14),
              // Type selector pills
              Text('CLASS TYPE', style: AppTheme.labelUpper),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((t) {
                  final active = t == _selectedType;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.typeColor(t).withValues(alpha: 0.15) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppTheme.typeColor(t) : AppTheme.borderLight),
                      ),
                      child: Text(t, style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: active ? AppTheme.typeColor(t) : AppTheme.textSecondary,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // Group
              Text('GROUP', style: AppTheme.labelUpper),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _groups.map((g) {
                  final active = g == _selectedGroup;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGroup = g),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: active ? AppTheme.primaryBlue : AppTheme.borderLight),
                      ),
                      child: Text(g, style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      )),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ───── Assignment ─────
          _SectionCard(
            title: 'Assignment',
            icon: Icons.person_outline,
            children: [
              _LabeledDropdown<String>(
                label: 'TEACHER',
                value: _selectedTeacherInitial,
                hint: 'Select teacher',
                items: data.teachers.map((t) => DropdownMenuItem(value: t.initial, child: Text('${t.name} (${t.initial})'))).toList(),
                onChanged: (v) => setState(() => _selectedTeacherInitial = v),
              ),
              const SizedBox(height: 14),
              // Mode toggle
              Text('CLASS MODE', style: AppTheme.labelUpper),
              const SizedBox(height: 8),
              Row(
                children: _modes.map((m) {
                  final active = m == _selectedMode;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: m == 'Onsite' ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMode = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primaryBlue : Colors.white,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(color: active ? AppTheme.primaryBlue : AppTheme.borderLight),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                m == 'Onsite' ? Icons.location_on_outlined : Icons.wifi_outlined,
                                size: 18,
                                color: active ? Colors.white : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(m, style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: active ? Colors.white : AppTheme.textSecondary,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedMode == 'Onsite') ...[
                const SizedBox(height: 14),
                _LabeledDropdown<String>(
                  label: 'ROOM',
                  value: _selectedRoomId,
                  hint: 'Select room',
                  items: data.rooms.map((r) => DropdownMenuItem(value: r.id, child: Text('${r.name} (${r.id})'))).toList(),
                  onChanged: (v) => setState(() => _selectedRoomId = v),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ───── Schedule & Timing ─────
          _SectionCard(
            title: 'Schedule & Timing',
            icon: Icons.schedule_outlined,
            children: [
              // Day of week pills
              Text('DAY OF WEEK', style: AppTheme.labelUpper),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _days.map((d) {
                  final active = d == _selectedDay;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = d),
                    child: Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: active ? AppTheme.primaryBlue : AppTheme.borderLight),
                      ),
                      alignment: Alignment.center,
                      child: Text(d, style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppTheme.textSecondary,
                      )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Time pickers
              Row(
                children: [
                  Expanded(
                    child: _TimePicker(
                      label: 'START TIME',
                      time: _startTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _startTime,
                        );
                        if (t != null) setState(() => _startTime = t);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePicker(
                      label: 'END TIME',
                      time: _endTime,
                      onTap: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _endTime,
                        );
                        if (t != null) setState(() => _endTime = t);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ───── Confirm Button ─────
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEditing ? 'Update Entry' : 'Confirm Entry'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ───── Helper widgets ─────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cleanCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTheme.sectionHeader(title, icon: icon),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _LabeledDropdown({
    required this.label, required this.value, required this.hint,
    required this.items, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelUpper),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              hint: Text(hint, style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textHint)),
              isExpanded: true,
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
              items: items,
              onChanged: onChanged,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimePicker({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.labelUpper),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
