import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/data_repository.dart';
import '../models/admin.dart';
import 'main_navigation_screen.dart';
import 'super_admin_portal_screen_new.dart';
import 'teacher_admin_portal_screen_new.dart';
import '../utils/app_theme.dart';

class UnifiedLoginScreen extends StatefulWidget {
  const UnifiedLoginScreen({super.key});

  @override
  State<UnifiedLoginScreen> createState() => _UnifiedLoginScreenState();
}

class _UnifiedLoginScreenState extends State<UnifiedLoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMessage;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both username and password');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final service = context.read<SupabaseService>();

    // Try admin
    final admin = await service.authenticateAdmin(username, password);
    if (!mounted) return;
    if (admin != null) {
      setState(() => _isLoading = false);
      if (admin.isSuperAdmin) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: service,
            child: const SuperAdminPortalScreenNew(),
          ),
        ));
      } else {
        final repo = DataRepository(service);
        await repo.load();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: service,
            child: TeacherAdminPortalScreen(repo: repo, admin: admin),
          ),
        ));
      }
      return;
    }

    // Try teacher
    final teacher = await service.authenticateTeacherByEmail(username, password);
    if (!mounted) return;
    if (teacher != null) {
      setState(() => _isLoading = false);
      final teacherAdmin = Admin(
        id: teacher.id,
        username: teacher.name,
        password: teacher.password ?? '',
        type: 'teacher_admin',
        teacherInitial: teacher.initial,
      );
      final repo = DataRepository(service);
      await repo.load();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: service,
          child: TeacherAdminPortalScreen(repo: repo, admin: teacherAdmin),
        ),
      ));
      return;
    }

    // Try student
    final student = await service.authenticateStudent(username, password);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (student != null) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: service,
          child: const MainNavigationScreen(),
        ),
      ));
      return;
    }
    setState(() => _errorMessage = 'Invalid credentials. Try again.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Logo
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppTheme.studentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow(AppTheme.primaryBlue),
                        ),
                        child: const Icon(Icons.bolt_rounded, size: 36, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'EDTE Routine',
                        style: GoogleFonts.poppins(
                          fontSize: 26, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your campus schedule, simplified.',
                        style: AppTheme.subtitle,
                      ),

                      const SizedBox(height: 40),

                      // Login Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: AppTheme.cardShadowMedium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign In',
                              style: GoogleFonts.poppins(
                                fontSize: 20, fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Access your student, teacher, or admin account',
                              style: AppTheme.caption,
                            ),
                            const SizedBox(height: 24),

                            // Username
                            TextField(
                              controller: _usernameController,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary, fontSize: 14,
                              ),
                              decoration: AppTheme.inputDecoration(
                                label: 'Username / Email',
                                prefixIcon: Icons.person_outline_rounded,
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textPrimary, fontSize: 14,
                              ),
                              decoration: AppTheme.inputDecoration(
                                label: 'Password',
                                prefixIcon: Icons.lock_outline_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppTheme.textHint,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                              ),
                              onSubmitted: (_) => _login(),
                            ),

                            // Error
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorRedLight,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                                  border: Border.all(
                                    color: AppTheme.errorRed.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded,
                                        color: AppTheme.errorRed, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.errorRed, fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                                  ),
                                  textStyle: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),
                      Text(
                        'Students  •  Teachers  •  Admins',
                        style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textHint,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
