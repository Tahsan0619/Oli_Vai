import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class FreeRoomsScreen extends StatefulWidget {
  final dynamic repo;
  const FreeRoomsScreen({super.key, required this.repo});

  @override
  State<FreeRoomsScreen> createState() => _FreeRoomsScreenState();
}

class _FreeRoomsScreenState extends State<FreeRoomsScreen> {
  String _selectedDay = _currentDay();
  String _selectedSlot = '08:00-09:30';
  List<dynamic> _freeRooms = [];
  bool _isLoading = false;

  static const _days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Sat'];
  static const _slots = [
    '08:00-09:30', '09:30-11:00', '11:00-12:30',
    '12:30-14:00', '14:00-15:30', '15:30-17:00',
  ];

  static String _currentDay() {
    const dayMap = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return dayMap[DateTime.now().weekday] ?? 'Sun';
  }

  @override
  void initState() {
    super.initState();
    _loadFreeRooms();
  }

  Future<void> _loadFreeRooms() async {
    setState(() => _isLoading = true);
    try {
      final svc = context.read<SupabaseService>();
      final parts = _selectedSlot.split('-');
      final rooms = await svc.getFreeRooms(_selectedDay, parts[0]);
      if (mounted) {
        setState(() {
          _freeRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text('Free Rooms', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
      ),
      body: Column(
        children: [
          // Day selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
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
                    onTap: () {
                      setState(() => _selectedDay = day);
                      _loadFreeRooms();
                    },
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

          // Time slot selector
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _slots.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final slot = _slots[i];
                  final isSelected = _selectedSlot == slot;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSlot = slot);
                      _loadFreeRooms();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.successGreenLight : AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(Icons.access_time, size: 13, color: AppTheme.successGreen),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            slot,
                            style: GoogleFonts.poppins(
                              fontSize: 11, fontWeight: FontWeight.w500,
                              color: isSelected ? AppTheme.successGreen : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Divider(height: 1, color: AppTheme.dividerColor),

          // Results header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Available Rooms',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  AppTheme.chip(
                    '${_freeRooms.length} rooms',
                    bg: AppTheme.successGreenLight,
                    fg: AppTheme.successGreen,
                  ),
              ],
            ),
          ),

          // Room list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _freeRooms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.meeting_room_outlined, size: 48, color: AppTheme.textHint),
                            const SizedBox(height: 12),
                            Text('No free rooms at this time', style: AppTheme.subtitle),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _freeRooms.length,
                        itemBuilder: (_, i) {
                          final room = _freeRooms[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(color: AppTheme.borderLight),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.successGreenLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.meeting_room_outlined,
                                    color: AppTheme.successGreen, size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14, fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Available for booking',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12, color: AppTheme.successGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.check_circle_outlined, color: AppTheme.successGreen, size: 22),
                              ],
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
