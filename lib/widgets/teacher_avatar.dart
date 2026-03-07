import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

/// Known teacher initials that have static images in the EdTE/ assets folder.
const _assetInitials = {
  'AFK', 'AR', 'AZ', 'FI', 'MA', 'MH', 'MRK', 'MS',
  'NH', 'NP', 'RB', 'RI', 'RS', 'SA', 'SCS', 'SZN', 'ZF',
};

/// Reusable avatar for teachers.
///
/// Priority: uploaded [profilePicUrl] > static asset from EdTE/{initial}.png > text initials.
class TeacherAvatar extends StatelessWidget {
  final String initial;
  final String? profilePicUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const TeacherAvatar({
    super.key,
    required this.initial,
    this.profilePicUrl,
    this.radius = 26,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppTheme.primaryBlueLight;
    final fg = textColor ?? AppTheme.primaryBlue;
    final diameter = radius * 2;
    final shortInitial = initial.length > 2 ? initial.substring(0, 2) : initial;
    final fontSize = radius * 0.54;

    Widget fallback() => Text(
          shortInitial,
          style: GoogleFonts.poppins(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        );

    Widget child;

    if (profilePicUrl != null && profilePicUrl!.isNotEmpty) {
      // Teacher uploaded a custom profile pic
      child = ClipOval(
        child: Image.network(
          profilePicUrl!,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            // Network image failed — try static asset
            if (_assetInitials.contains(initial)) {
              return ClipOval(
                child: Image.asset(
                  'EdTE/$initial.png',
                  width: diameter,
                  height: diameter,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => fallback(),
                ),
              );
            }
            return fallback();
          },
        ),
      );
    } else if (_assetInitials.contains(initial)) {
      // No uploaded pic — use static asset from EdTE folder
      child = ClipOval(
        child: Image.asset(
          'EdTE/$initial.png',
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    } else {
      child = fallback();
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: child,
    );
  }
}
