import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/data_repository.dart';
import 'services/local_notification_service.dart';
import 'models/admin.dart';
import 'models/student.dart';
import 'models/teacher.dart';
import 'screens/unified_login_screen_new.dart';
import 'screens/super_admin_portal_screen_new.dart';
import 'screens/teacher_admin_portal_screen_new.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yofrdlyzetcezbhhbkdb.supabase.co',
    anonKey: 'sb_publishable_YEooiBZGo8WjkgFu5mfqlw_mC-6d0YM',
  );

  // Initialize local push notifications
  await LocalNotificationService.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const RoutineScrapperApp());
}

class RoutineScrapperApp extends StatelessWidget {
  const RoutineScrapperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final service = SupabaseService();
        service.initialize();
        return service;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EDTE Routine',
        theme: AppTheme.lightTheme,
        home: const AuthCheck(),
        onGenerateRoute: (settings) {
          if (settings.name == '/') {
            return MaterialPageRoute(builder: (_) => const AuthCheck());
          }
          return null;
        },
      ),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck>
    with SingleTickerProviderStateMixin {
  late DataRepository _repo;
  bool _repoInitialized = false;
  bool _serviceInitialized = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _initializeRepo();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initializeRepo() async {
    final service = context.read<SupabaseService>();
    await service.initialize();
    _repo = DataRepository(service);
    await _repo.load();
    if (mounted) {
      setState(() {
        _repoInitialized = true;
        _serviceInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_repoInitialized || !_serviceInitialized) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.studentGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppTheme.softShadow(AppTheme.primaryBlue),
                      ),
                      child: const Icon(Icons.school_rounded, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    Text('Loading...', style: AppTheme.subtitle),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Use Selector instead of Consumer to only rebuild when login state changes.
    // Consumer rebuilds on EVERY notifyListeners() call (including CRUD ops),
    // which destroys the entire widget tree and loses permission toggles, etc.
    return Selector<SupabaseService, ({Admin? admin, Student? student, Teacher? teacher})>(
      selector: (_, svc) => (admin: svc.currentAdmin, student: svc.currentStudent, teacher: svc.currentTeacher),
      builder: (context, state, _) {
        final supabaseService = context.read<SupabaseService>();
        if (state.admin != null) {
          final admin = state.admin!;
          if (admin.type == 'super_admin') {
            return const SuperAdminPortalScreenNew();
          } else if (admin.type == 'teacher_admin') {
            return TeacherAdminPortalScreen(
              repo: _repo,
              admin: admin,
            );
          }
        }
        if (state.student != null) {
          return const MainNavigationScreen();
        }
        if (state.teacher != null) {
          return TeacherAdminPortalScreen(
            repo: _repo,
            admin: Admin(
              id: state.teacher!.id,
              username: state.teacher!.name,
              password: state.teacher!.password ?? '',
              type: 'teacher_admin',
              teacherInitial: state.teacher!.initial,
            ),
          );
        }
        return const UnifiedLoginScreen();
      },
    );
  }
}
