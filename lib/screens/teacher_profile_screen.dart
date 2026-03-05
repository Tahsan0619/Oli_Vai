import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/teacher.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class TeacherProfileScreen extends StatefulWidget {
  final String teacherInitial;
  const TeacherProfileScreen({super.key, required this.teacherInitial});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Teacher? _teacher;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _changingPassword = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _deptCtrl;
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _designationCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _deptCtrl = TextEditingController();
    _loadTeacher();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _designationCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _deptCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeacher() async {
    final svc = context.read<SupabaseService>();
    final t = await svc.getTeacherByInitial(widget.teacherInitial);
    if (mounted) {
      setState(() {
        _teacher = t;
        _isLoading = false;
        if (t != null) {
          _nameCtrl.text = t.name;
          _designationCtrl.text = t.designation;
          _phoneCtrl.text = t.phone;
          _emailCtrl.text = t.email;
          _deptCtrl.text = t.homeDepartment;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_teacher == null) return;
    final svc = context.read<SupabaseService>();
    final updated = Teacher(
      id: _teacher!.id,
      name: _nameCtrl.text.trim(),
      initial: _teacher!.initial,
      designation: _designationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      homeDepartment: _deptCtrl.text.trim(),
      profilePic: _teacher!.profilePic,
      password: _teacher!.password,
      hasChangedPassword: _teacher!.hasChangedPassword,
    );
    final ok = await svc.updateTeacher(_teacher!.id, updated);
    if (!mounted) return;
    if (ok) {
      _showSnackBar('Profile updated');
      setState(() {
        _isEditing = false;
        _teacher = updated;
      });
    } else {
      _showSnackBar('Failed to update', isError: true);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked == null || _teacher == null) return;
    final svc = context.read<SupabaseService>();
    final url = await svc.uploadTeacherProfilePic(_teacher!.initial, picked.path);
    if (url != null) {
      await svc.updateTeacherProfilePic(_teacher!.id, url);
      await _loadTeacher();
    }
  }

  Future<void> _changePassword() async {
    if (_newPwCtrl.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }
    final svc = context.read<SupabaseService>();
    // Verify current password
    if (_teacher?.email != null && _teacher!.email.isNotEmpty) {
      final verified = await svc.authenticateTeacherByEmail(_teacher!.email, _currentPwCtrl.text);
      if (verified == null) {
        if (mounted) _showSnackBar('Current password is incorrect', isError: true);
        return;
      }
    }
    final ok = await svc.updateTeacherPassword(_teacher!.id, _newPwCtrl.text);
    if (!mounted) return;
    if (ok) {
      _showSnackBar('Password updated');
      setState(() => _changingPassword = false);
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }
    if (_teacher == null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: Center(child: Text('Teacher not found', style: AppTheme.subtitle)),
      );
    }

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
        title: Text('Teacher Profile', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        actions: [
          if (!_isEditing)
            TextButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('Edit', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500)),
            )
          else
            TextButton.icon(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save_outlined, size: 16, color: AppTheme.primaryBlue),
              label: Text('Save', style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue,
              )),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isEditing ? _pickImage : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppTheme.primaryBlueLight,
                        backgroundImage: _teacher!.profilePic != null
                            ? NetworkImage(_teacher!.profilePic!)
                            : null,
                        child: _teacher!.profilePic == null
                            ? Text(
                                _teacher!.initial.substring(0, _teacher!.initial.length > 2 ? 2 : _teacher!.initial.length),
                                style: GoogleFonts.poppins(
                                  fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(_teacher!.name, style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                )),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppTheme.chip(_teacher!.initial, bg: AppTheme.primaryBlueLight, fg: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text('•', style: AppTheme.caption),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_teacher!.homeDepartment, style: AppTheme.caption, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Professional Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sectionHeader('Professional Info', icon: Icons.work_outline),
                const SizedBox(height: 8),
                _profileField('FULL NAME', _nameCtrl, Icons.person_outline),
                _profileField('TEACHER INITIAL', null, Icons.badge_outlined, value: _teacher!.initial),
                _profileField('DESIGNATION', _designationCtrl, Icons.school_outlined),
                _profileField('DEPARTMENT', _deptCtrl, Icons.business_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Contact & Communication
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sectionHeader('Contact & Communication', icon: Icons.mail_outline),
                const SizedBox(height: 8),
                _profileField('OFFICIAL EMAIL', _emailCtrl, Icons.email_outlined),
                _profileField('PHONE NUMBER', _phoneCtrl, Icons.phone_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Security
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cleanCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTheme.sectionHeader('Security', icon: Icons.lock_outline),
                const SizedBox(height: 4),
                Text('Manage your account password and security settings', style: AppTheme.caption),
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
                          child: const Text('Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _profileField(String label, TextEditingController? ctrl, IconData icon, {String? value}) {
    final isReadOnly = ctrl == null || !_isEditing;
    final displayValue = value ?? ctrl?.text ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: isReadOnly
          ? Row(
              children: [
                Icon(icon, size: 18, color: AppTheme.textHint),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTheme.labelUpper),
                      const SizedBox(height: 2),
                      Text(
                        displayValue,
                        style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle_outline, size: 18,
                    color: AppTheme.successGreen.withValues(alpha: 0.5)),
              ],
            )
          : TextField(
              controller: ctrl,
              decoration: AppTheme.inputDecoration(label: label, prefixIcon: icon),
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
            ),
    );
  }
}
