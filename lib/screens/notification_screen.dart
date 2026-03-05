import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_model.dart';
import '../services/local_notification_service.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  final String recipientType; // super_admin, student, teacher
  final String recipientId;   // username, student_id, teacher_initial

  const NotificationScreen({
    super.key,
    required this.recipientType,
    required this.recipientId,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    if (_channel != null) {
      context.read<SupabaseService>().unsubscribeChannel(_channel!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final svc = context.read<SupabaseService>();
    final list = await svc.getNotifications(
      recipientType: widget.recipientType,
      recipientId: widget.recipientId,
    );
    if (mounted) setState(() { _notifications = list; _isLoading = false; });
  }

  void _subscribeRealtime() {
    final svc = context.read<SupabaseService>();
    _channel = svc.subscribeToNotifications(
      recipientType: widget.recipientType,
      recipientId: widget.recipientId,
      channelSuffix: 'screen',
      onNewNotification: (notif) {
        if (mounted) {
          if (notif.id.isNotEmpty) {
            // Normal realtime payload — insert directly
            setState(() => _notifications.insert(0, notif));
          } else {
            // Trigger-inserted or parse-failed — reload from DB
            _load();
          }
        }
      },
    );
  }

  Future<void> _markAllRead() async {
    final svc = context.read<SupabaseService>();
    await svc.markAllNotificationsRead(
      recipientType: widget.recipientType,
      recipientId: widget.recipientId,
    );
    if (mounted) {
      setState(() {
        _notifications = _notifications.map((n) => AppNotification(
          id: n.id, type: n.type, title: n.title, body: n.body,
          recipientType: n.recipientType, recipientId: n.recipientId,
          relatedEntryId: n.relatedEntryId, isRead: true, createdAt: n.createdAt,
        )).toList();
      });
    }
  }

  Future<void> _markRead(AppNotification notif) async {
    if (notif.isRead) return;
    final svc = context.read<SupabaseService>();
    await svc.markNotificationRead(notif.id);
    if (mounted) {
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == notif.id);
        if (idx != -1) {
          _notifications[idx] = AppNotification(
            id: notif.id, type: notif.type, title: notif.title, body: notif.body,
            recipientType: notif.recipientType, recipientId: notif.recipientId,
            relatedEntryId: notif.relatedEntryId, isRead: true, createdAt: notif.createdAt,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: Text('Notifications', style: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary,
        )),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text('Mark all read', style: GoogleFonts.poppins(
                fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500,
              )),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _notifications.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primaryBlue,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _notifCard(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 56, color: AppTheme.textHint.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No Notifications', style: GoogleFonts.poppins(
            fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
          )),
          const SizedBox(height: 6),
          Text('You\'re all caught up!', style: AppTheme.caption),
        ],
      ),
    );
  }

  Widget _notifCard(AppNotification notif) {
    final icon = _iconForType(notif.type);
    final color = _colorForType(notif.type);
    final timeAgo = _formatTimeAgo(notif.createdAt);

    return GestureDetector(
      onTap: () => _markRead(notif),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: notif.isRead ? AppTheme.borderLight : color.withValues(alpha: 0.3),
          ),
          boxShadow: notif.isRead ? [] : AppTheme.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(notif.title, style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w600,
                          color: AppTheme.textPrimary,
                        )),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(notif.body, style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.4,
                  )),
                  const SizedBox(height: 6),
                  Text(timeAgo, style: GoogleFonts.poppins(
                    fontSize: 11, color: AppTheme.textHint,
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'class_cancelled': return Icons.cancel_outlined;
      case 'class_rescheduled': return Icons.schedule_outlined;
      case 'room_changed': return Icons.swap_horiz_outlined;
      case 'class_restored': return Icons.restore_outlined;
      case 'daily_reminder': return Icons.alarm_outlined;
      case 'appointment': return Icons.event_available_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'class_cancelled': return AppTheme.errorRed;
      case 'class_rescheduled': return AppTheme.warningAmber;
      case 'room_changed': return AppTheme.accentCyan;
      case 'class_restored': return AppTheme.successGreen;
      case 'daily_reminder': return AppTheme.primaryBlue;
      case 'appointment': return AppTheme.accentOrange;
      default: return AppTheme.textSecondary;
    }
  }

  String _formatTimeAgo(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

/// Notification bell widget with unread badge — drop into any AppBar
class NotificationBell extends StatefulWidget {
  final String recipientType;
  final String recipientId;

  const NotificationBell({
    super.key,
    required this.recipientType,
    required this.recipientId,
  });

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  int _unreadCount = 0;
  RealtimeChannel? _channel;
  RealtimeChannel? _triggerChannel; // Listens to timetable_entries for super_admin
  Timer? _pollTimer;
  late final SupabaseService _svc;

  @override
  void initState() {
    super.initState();
    _svc = context.read<SupabaseService>();
    _loadCount();
    _subscribeRealtime();
    // For super_admin: also listen to timetable_entries changes because
    // super_admin notifications are created by a DB trigger (not REST API),
    // and Supabase Realtime is unreliable for trigger-inserted rows.
    if (widget.recipientType == 'super_admin') {
      _subscribeTimetableTrigger();
    }
    // Periodic polling fallback
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadCount());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    final client = Supabase.instance.client;
    if (_channel != null) {
      try { client.removeChannel(_channel!); } catch (_) {}
    }
    if (_triggerChannel != null) {
      try { client.removeChannel(_triggerChannel!); } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _loadCount() async {
    try {
      final count = await _svc.getUnreadNotificationCount(
        recipientType: widget.recipientType,
        recipientId: widget.recipientId,
      );
      if (mounted && count != _unreadCount) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('[BELL] _loadCount error: $e');
    }
  }

  void _subscribeRealtime() {
    _channel = _svc.subscribeToNotifications(
      recipientType: widget.recipientType,
      recipientId: widget.recipientId,
      channelSuffix: 'bell',
      onNewNotification: (notif) {
        if (mounted) {
          setState(() => _unreadCount++);
          // Show mobile popup notification
          LocalNotificationService.instance.show(notif);
          // Also do a full count reload to stay in sync with DB
          _loadCount();
        }
      },
    );
  }

  /// Super-admin notifications are created by a DB trigger on timetable_entries.
  /// Supabase Realtime reliably delivers the UPDATE event on timetable_entries
  /// (because it's a direct REST API call), so we use that as a cue to reload
  /// the notification count after a short delay (giving the trigger time to run).
  void _subscribeTimetableTrigger() {
    final client = Supabase.instance.client;
    _triggerChannel = client
        .channel('bell_timetable_trigger_${widget.recipientId}'.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_'))
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'timetable_entries',
          callback: (payload) {
            debugPrint('[BELL] timetable_entries changed (${payload.eventType}), will reload count');
            // Wait 1.5s for the DB trigger to finish inserting notification rows
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                _loadCount();
                // Fetch latest notification to show as popup
                _showLatestAsPopup();
              }
            });
          },
        )
        .subscribe();
  }

  /// Fetch the most recent unread notification and show it as a mobile popup.
  Future<void> _showLatestAsPopup() async {
    try {
      final list = await _svc.getNotifications(
        recipientType: widget.recipientType,
        recipientId: widget.recipientId,
        limit: 1,
      );
      if (list.isNotEmpty && !list.first.isRead) {
        LocalNotificationService.instance.show(list.first);
      }
    } catch (e) {
      debugPrint('[BELL] _showLatestAsPopup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            _unreadCount > 0 ? Icons.notifications_active : Icons.notifications_outlined,
            size: 22,
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: context.read<SupabaseService>(),
                  child: NotificationScreen(
                    recipientType: widget.recipientType,
                    recipientId: widget.recipientId,
                  ),
                ),
              ),
            );
            _loadCount(); // Refresh count after returning
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppTheme.errorRed,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _unreadCount > 99 ? '99+' : '$_unreadCount',
                style: GoogleFonts.poppins(
                  fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
