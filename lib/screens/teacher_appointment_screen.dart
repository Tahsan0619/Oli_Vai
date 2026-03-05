import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

/// Teacher-side screen to manage appointment requests from students.
class TeacherAppointmentScreen extends StatefulWidget {
  final String teacherInitial;
  const TeacherAppointmentScreen({super.key, required this.teacherInitial});

  @override
  State<TeacherAppointmentScreen> createState() => _TeacherAppointmentScreenState();
}

class _TeacherAppointmentScreenState extends State<TeacherAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<Appointment> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = context.read<SupabaseService>();
    _appointments = await svc.getTeacherAppointments(widget.teacherInitial);
    if (mounted) setState(() => _loading = false);
  }

  List<Appointment> _filtered(String status) =>
      _appointments.where((a) => a.status == status).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Appointments', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textHint,
          indicatorColor: AppTheme.primaryBlue,
          labelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: 'Pending (${_filtered('pending').length})'),
            Tab(text: 'Accepted (${_filtered('accepted').length})'),
            Tab(text: 'Rejected (${_filtered('rejected').length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primaryBlue,
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildList('pending'),
                  _buildList('accepted'),
                  _buildList('rejected'),
                ],
              ),
            ),
    );
  }

  Widget _buildList(String status) {
    final list = _filtered(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.hourglass_empty_rounded
                  : status == 'accepted'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
              size: 48,
              color: AppTheme.textHint,
            ),
            const SizedBox(height: 12),
            Text('No $status appointments', style: AppTheme.subtitle),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _appointmentCard(list[i]),
    );
  }

  Widget _appointmentCard(Appointment appt) {
    final isPending = appt.status == 'pending';
    final isAccepted = appt.status == 'accepted';

    Color statusColor;
    IconData statusIcon;
    if (isPending) {
      statusColor = AppTheme.warningAmber;
      statusIcon = Icons.schedule;
    } else if (isAccepted) {
      statusColor = AppTheme.successGreen;
      statusIcon = Icons.check_circle_outline;
    } else {
      statusColor = AppTheme.errorRed;
      statusIcon = Icons.cancel_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Icon(statusIcon, size: 18, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appt.studentName,
                      style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'ID: ${appt.studentId}',
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
                ),
              ),
              AppTheme.chip(
                appt.status.toUpperCase(),
                bg: statusColor.withValues(alpha: 0.12),
                fg: statusColor,
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: 12),

          // Date & time
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Text(appt.date, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 14, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Text(appt.time, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
            ],
          ),

          // Purpose
          if (appt.purpose.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.subject, size: 14, color: AppTheme.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    appt.purpose,
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Remarks (if any)
          if (appt.teacherRemarks != null && appt.teacherRemarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.inputFill,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.comment_outlined, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appt.teacherRemarks!,
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions for pending
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respondDialog(appt, 'accepted'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successGreen,
                      side: BorderSide(color: AppTheme.successGreen.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respondDialog(appt, 'rejected'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(color: AppTheme.errorRed.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _respondDialog(Appointment appt, String newStatus) async {
    final remarksCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          newStatus == 'accepted' ? 'Accept Appointment' : 'Reject Appointment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${appt.studentName} — ${appt.date} at ${appt.time}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: remarksCtrl,
              decoration: InputDecoration(
                hintText: 'Add remarks (optional)',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textHint),
                filled: true,
                fillColor: AppTheme.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  borderSide: BorderSide.none,
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textPrimary),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'accepted' ? AppTheme.successGreen : AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(newStatus == 'accepted' ? 'Accept' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final svc = context.read<SupabaseService>();
      await svc.updateAppointmentStatus(
        appt.id,
        newStatus,
        remarks: remarksCtrl.text.trim().isEmpty ? null : remarksCtrl.text.trim(),
      );
      await _load();
    }
  }
}
