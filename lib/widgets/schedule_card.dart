import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/timetable_entry.dart';
import '../services/data_repository.dart';
import '../utils/app_theme.dart';

/// ═══════════════════════════════════════════════════════════════
/// Clean Schedule Card — matches mockup card style
/// Left accent bar · Type chip · Info rows · Cancelled state
/// ═══════════════════════════════════════════════════════════════

class ScheduleCard extends StatelessWidget {
  final TimetableEntry entry;
  final DataRepository repo;
  final VoidCallback? onTap;
  final bool showBatch;
  final bool showTeacher;
  final List<Widget>? actions;

  const ScheduleCard({
    super.key,
    required this.entry,
    required this.repo,
    this.onTap,
    this.showBatch = false,
    this.showTeacher = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final course = repo.courseByCode(entry.courseCode);
    final teacher = repo.teacherByInitial(entry.teacherInitial);
    final room = repo.roomById(entry.roomId);
    final batch = repo.batchById(entry.batchId);
    final typeColor = AppTheme.typeColor(entry.type);
    final isCancelled = entry.isCancelled;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isCancelled
              ? AppTheme.surfaceLight
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(
            color: isCancelled
                ? AppTheme.errorRed.withValues(alpha: 0.2)
                : AppTheme.borderLight,
          ),
          boxShadow: isCancelled ? [] : AppTheme.cardShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: isCancelled
                      ? AppTheme.errorRed.withValues(alpha: 0.5)
                      : typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),

              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: type chip + cancelled badge + three-dot menu
                      Row(
                        children: [
                          // Type chip
                          AppTheme.chip(
                            entry.type,
                            bg: AppTheme.typeBgColor(entry.type),
                            fg: typeColor,
                          ),
                          if (isCancelled) ...[
                            const SizedBox(width: 8),
                            AppTheme.chip(
                              'Cancelled',
                              bg: AppTheme.errorRedLight,
                              fg: AppTheme.errorRed,
                              icon: Icons.cancel_outlined,
                            ),
                          ],
                          const Spacer(),
                          if (onTap != null)
                            Icon(Icons.more_vert, color: AppTheme.textHint, size: 20),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Course title
                      Text(
                        course?.title ?? entry.courseCode,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isCancelled
                              ? AppTheme.textHint
                              : AppTheme.textPrimary,
                          decoration: isCancelled
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      // Course code
                      Text(
                        entry.courseCode,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Info rows
                      _infoRow(
                        Icons.access_time_outlined,
                        '${entry.start} - ${entry.end}',
                      ),
                      if (room != null || entry.mode == 'Online')
                        _infoRow(
                          Icons.location_on_outlined,
                          entry.mode == 'Online'
                              ? 'Online Portal'
                              : room?.name ?? '',
                        ),
                      if (showTeacher && teacher != null)
                        _infoRow(Icons.person_outline, teacher.name),
                      if (showBatch && batch != null)
                        _infoRow(Icons.people_outline, batch.name),
                      if (entry.group != null)
                        _infoRow(Icons.group_outlined, entry.group!),
                      if (entry.mode == 'Online')
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: AppTheme.chip(
                            'Online',
                            bg: AppTheme.infoCyanLight,
                            fg: AppTheme.accentCyan,
                            icon: Icons.videocam_outlined,
                          ),
                        ),

                      // Cancellation reason
                      if (isCancelled && entry.cancellationReason != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRedLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppTheme.errorRed, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entry.cancellationReason!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppTheme.errorRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action buttons
                      if (actions != null && actions!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Divider(color: AppTheme.dividerColor, height: 1),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: actions!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppTheme.textHint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
