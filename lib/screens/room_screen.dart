import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/data_repository.dart';
import '../utils/app_theme.dart';
import '../widgets/schedule_card.dart';

class RoomScreen extends StatefulWidget {
  final DataRepository repo;
  const RoomScreen({super.key, required this.repo});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  String? _selectedRoomId;
  String _selectedDay = _currentDay();
  String _selectedSlot = '08:00-09:30';
  final _searchCtrl = TextEditingController();

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Sat'];

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
    final rooms = widget.repo.data?.rooms ?? [];
    final meta = widget.repo.data?.meta;
    final slots = meta?.slotLabels ?? ['08:00-09:30', '09:30-11:00', '11:00-12:30', '12:30-14:00', '14:00-15:30', '15:30-17:00'];
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? rooms
        : rooms.where((r) => r.name.toLowerCase().contains(q) || r.id.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Rooms', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search room...',
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

          // Day pills
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = _days[i];
                  final isSelected = _selectedDay == day;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected ? null : Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Time slots
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: slots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final slot = slots[i];
                  final isSelected = _selectedSlot == slot;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSlot = slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlueLight : AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Text(
                        slot,
                        style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w500,
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Divider(height: 1, color: AppTheme.dividerColor),

          // Room list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final room = filtered[i];
                final entries = widget.repo.roomEntriesForDayTime(room.id, _selectedDay, _selectedSlot);
                final isOccupied = entries.isNotEmpty;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(color: AppTheme.borderLight),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    shape: const Border(),
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: isOccupied ? AppTheme.errorRedLight : AppTheme.successGreenLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOccupied ? Icons.meeting_room : Icons.meeting_room_outlined,
                        color: isOccupied ? AppTheme.errorRed : AppTheme.successGreen,
                        size: 20,
                      ),
                    ),
                    title: Text(room.name, style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                    )),
                    subtitle: Text(
                      isOccupied ? 'Occupied · ${entries.length} class(es)' : 'Available',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isOccupied ? AppTheme.errorRed : AppTheme.successGreen,
                      ),
                    ),
                    children: entries.map((e) => ScheduleCard(
                      entry: e,
                      repo: widget.repo,
                      showTeacher: true,
                      showBatch: true,
                    )).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
