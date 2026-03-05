import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';
import 'unified_login_screen_new.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _changingPassword = false;
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPwCtrl.text.trim().isEmpty || _newPwCtrl.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _showSnackBar('Passwords do not match', isError: true);
      return;
    }
    final svc = context.read<SupabaseService>();
    final student = svc.currentStudent;
    if (student == null) return;

    // Verify current password
    final verified = await svc.authenticateStudent(
      student.email ?? student.studentId,
      _currentPwCtrl.text,
    );
    if (verified == null) {
      if (mounted) _showSnackBar('Current password is incorrect', isError: true);
      return;
    }

    final ok = await svc.updateStudentPassword(student.studentId, _newPwCtrl.text);
    if (!mounted) return;
    if (ok) {
      _showSnackBar('Password updated successfully');
      setState(() => _changingPassword = false);
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
    } else {
      _showSnackBar('Failed to update password', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorRed : AppTheme.successGreen,
    ));
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to sign out?', style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<SupabaseService>().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(
          value: context.read<SupabaseService>(),
          child: const UnifiedLoginScreen(),
        )),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<SupabaseService>();
    final student = svc.currentStudent;
    if (student == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: Center(child: Text('Not logged in', style: AppTheme.subtitle)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Profile', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryBlueLight,
                  child: Text(
                    student.name.isNotEmpty ? student.name[0].toUpperCase() : 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 28, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  student.name,
                  style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppTheme.chip(student.studentId, bg: AppTheme.primaryBlueLight, fg: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text('•', style: AppTheme.caption),
                    const SizedBox(width: 8),
                    Text(student.batchId, style: AppTheme.caption),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Student Info section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sectionHeader('Student Info', icon: Icons.school_outlined),
                const SizedBox(height: 8),
                _infoTile('STUDENT ID', student.studentId, Icons.badge_outlined),
                _infoTile('FULL NAME', student.name, Icons.person_outline),
                _infoTile('BATCH', student.batchId, Icons.group_outlined),
                if (student.email != null && student.email!.isNotEmpty)
                  _infoTile('EMAIL', student.email!, Icons.email_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Security section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sectionHeader('Security', icon: Icons.lock_outline),
                const SizedBox(height: 4),
                Text(
                  'Manage your account password and security settings',
                  style: AppTheme.caption,
                ),
                const SizedBox(height: 16),

                if (!_changingPassword)
                  InkWell(
                    onTap: () => setState(() => _changingPassword = true),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.inputFill,
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Update Password', style: AppTheme.bodyMedium)),
                          const Icon(Icons.edit_outlined, color: AppTheme.textHint, size: 18),
                        ],
                      ),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _currentPwCtrl,
                    obscureText: _obscureCurrent,
                    decoration: AppTheme.inputDecoration(
                      label: 'Current Password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: AppTheme.textHint,
                        ),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPwCtrl,
                    obscureText: _obscureNew,
                    decoration: AppTheme.inputDecoration(
                      label: 'New Password',
                      prefixIcon: Icons.lock_reset_outlined,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 20, color: AppTheme.textHint,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPwCtrl,
                    obscureText: true,
                    decoration: AppTheme.inputDecoration(
                      label: 'Confirm New Password',
                      prefixIcon: Icons.lock_outline,
                    ),
                    style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _changingPassword = false),
                          style: AppTheme.outlineButton(color: AppTheme.textSecondary),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _changePassword,
                          style: AppTheme.pillButton(),
                          child: const Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign out button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out from Device'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textHint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.labelUpper),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary,
                )),
              ],
            ),
          ),
          Icon(Icons.check_circle_outline, size: 18, color: AppTheme.successGreen.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
