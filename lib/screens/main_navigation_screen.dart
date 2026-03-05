import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/data_repository.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import 'student_screen.dart';
import 'teacher_screen.dart';
import 'room_screen.dart';
import 'free_rooms_screen.dart';
import 'student_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late DataRepository _repo;
  bool _loaded = false;
  final List<RealtimeChannel> _channels = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initRepo();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final ch in _channels) {
      Supabase.instance.client.removeChannel(ch);
    }
    super.dispose();
  }

  Future<void> _initRepo() async {
    final svc = context.read<SupabaseService>();
    _repo = DataRepository(svc);
    await _repo.load();
    if (mounted) {
      setState(() => _loaded = true);
      _subscribeRealtime();
    }
  }

  /// Subscribe to realtime changes so schedule updates automatically.
  void _subscribeRealtime() {
    final client = Supabase.instance.client;
    final tables = ['timetable_entries', 'teachers', 'courses', 'rooms', 'batches'];
    for (final table in tables) {
      final channel = client
          .channel('student_$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              _debouncedRefresh();
            },
          )
          .subscribe();
      _channels.add(channel);
    }
  }

  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _silentRefresh());
  }

  Future<void> _silentRefresh() async {
    await _repo.load();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text('Loading schedule...', style: AppTheme.subtitle),
            ],
          ),
        ),
      );
    }

    final screens = [
      StudentScreen(repo: _repo),
      TeacherScreen(repo: _repo),
      RoomScreen(repo: _repo),
      FreeRoomsScreen(repo: _repo),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.dividerColor, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_outlined, Icons.home_rounded, 'Schedule'),
                _navItem(1, Icons.people_outline, Icons.people_rounded, 'Teachers'),
                _navItem(2, Icons.meeting_room_outlined, Icons.meeting_room_rounded, 'Rooms'),
                _navItem(3, Icons.event_available_outlined, Icons.event_available_rounded, 'Free'),
                _navItem(4, Icons.person_outline, Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textHint,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primaryBlue : AppTheme.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
