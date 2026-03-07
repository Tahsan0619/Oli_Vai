import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════════
/// SomoySutro — Clean Light Design System
/// Inspired by modern educational app UIs
/// ═══════════════════════════════════════════════════════════════

class AppTheme {
  AppTheme._();

  // ─── Core Light Surfaces ───────────────────────────────────
  static const Color scaffoldBg = Color(0xFFF8F9FC);
  static const Color cardWhite = Colors.white;
  static const Color surfaceLight = Color(0xFFF1F3F8);
  static const Color inputFill = Color(0xFFF4F5F9);
  static const Color dividerColor = Color(0xFFE8ECF2);
  static const Color borderLight = Color(0xFFE2E6ED);

  // Legacy aliases for compatibility
  static const Color scaffoldDark = scaffoldBg;
  static const Color cardDark = cardWhite;
  static const Color surfaceDark = surfaceLight;
  static const Color primaryLight = Color(0xFFEEF0FF);

  // ─── Primary Accent ────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF4F46E5);
  static const Color primaryBlueLight = Color(0xFFEEF0FF);
  static const Color primaryBlueDark = Color(0xFF3730A3);

  // ─── Accent Colors ─────────────────────────────────────────
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFF43F5E);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color neonGreen = Color(0xFF22D3EE);
  static const Color primaryDark = Color(0xFF3730A3);

  // ─── Status Colors ─────────────────────────────────────────
  static const Color successGreen = Color(0xFF10B981);
  static const Color successGreenLight = Color(0xFFECFDF5);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningAmberLight = Color(0xFFFFFBEB);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorRedLight = Color(0xFFFEF2F2);
  static const Color infoCyan = Color(0xFF06B6D4);
  static const Color infoCyanLight = Color(0xFFECFEFF);

  // ─── Text Colors ───────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;

  // ─── Role Colors & Gradients ───────────────────────────────
  static const Color studentPrimary = Color(0xFF4F46E5);
  static const Color studentSecondary = Color(0xFF818CF8);
  static const LinearGradient studentGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient studentCardGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color teacherPrimary = Color(0xFF4F46E5);
  static const Color teacherSecondary = Color(0xFF818CF8);
  static const LinearGradient teacherGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient teacherCardGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color adminPrimary = Color(0xFF4F46E5);
  static const Color adminSecondary = Color(0xFF818CF8);
  static const Color adminGold = Color(0xFFF97316);
  static const LinearGradient adminGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  static const LinearGradient adminCardGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Extra Gradients ───────────────────────────────────────
  static const LinearGradient purplePink = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient cyanBlue = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient greenCyan = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient pinkRose = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient orangeRed = LinearGradient(
    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Typography ────────────────────────────────────────────
  static TextStyle heading1 = GoogleFonts.poppins(
    fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5,
  );
  static TextStyle heading2 = GoogleFonts.poppins(
    fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static TextStyle heading3 = GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
  );
  static TextStyle heading3White = GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white,
  );
  static TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary,
  );
  static TextStyle body = GoogleFonts.poppins(fontSize: 14, color: textPrimary);
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary,
  );
  static TextStyle caption = GoogleFonts.poppins(fontSize: 12, color: textSecondary);
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w600, color: textSecondary, letterSpacing: 0.8,
  );
  static TextStyle labelUpper = GoogleFonts.poppins(
    fontSize: 10, fontWeight: FontWeight.w600, color: textHint, letterSpacing: 1.2,
  );

  // ─── Border Radius ─────────────────────────────────────────
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 24;

  // ─── Card Shadows ──────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> get cardShadowMedium => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> softShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.2),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  static List<BoxShadow> neonGlowShadow(Color color) => glowShadow(color);

  // ─── Card Decorations ──────────────────────────────────────
  static BoxDecoration get cleanCardDecoration => BoxDecoration(
    color: cardWhite,
    borderRadius: BorderRadius.circular(radiusL),
    border: Border.all(color: borderLight, width: 1),
    boxShadow: cardShadow,
  );

  static BoxDecoration glassCard({
    Color? borderColor,
    double borderOpacity = 1.0,
    double bgOpacity = 1.0,
    double radius = radiusL,
  }) {
    return BoxDecoration(
      color: cardWhite,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (borderColor ?? borderLight).withValues(alpha: borderOpacity),
        width: 1,
      ),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration cleanCard({double radius = radiusL, Color? borderColor}) {
    return glassCard(borderColor: borderColor, radius: radius);
  }

  // ─── Responsive Helpers ────────────────────────────────────
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1024;
  static double responsivePadding(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 24;
    return 16;
  }
  static int responsiveGridCount(BuildContext context) {
    if (isDesktop(context)) return 4;
    if (isTablet(context)) return 3;
    return 2;
  }

  // ─── Input Decoration ──────────────────────────────────────
  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
    Color accentColor = primaryBlue,
    Widget? suffixIcon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      labelStyle: GoogleFonts.poppins(color: textHint, fontSize: 14),
      hintStyle: GoogleFonts.poppins(color: textHint, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: accentColor, size: 20) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: BorderSide(color: accentColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusM),
        borderSide: const BorderSide(color: errorRed),
      ),
    );
  }

  // ─── Pill Button Style ─────────────────────────────────────
  static ButtonStyle pillButton({Color bg = primaryBlue, Color fg = Colors.white}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXL)),
      textStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  static ButtonStyle outlineButton({Color color = primaryBlue}) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
    );
  }

  // ─── Section Header ────────────────────────────────────────
  static Widget sectionHeader(String title, {IconData? icon, Color? iconColor, Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? primaryBlue, size: 20),
            const SizedBox(width: 8),
          ],
          Text(title, style: GoogleFonts.poppins(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary,
          )),
          if (trailing != null) ...[const Spacer(), trailing],
        ],
      ),
    );
  }

  // ─── Chip/Tag Builder ──────────────────────────────────────
  static Widget chip(String text, {Color? bg, Color? fg, IconData? icon}) {
    final bgColor = bg ?? primaryBlueLight;
    final fgColor = fg ?? primaryBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: fgColor, size: 12),
            const SizedBox(width: 4),
          ],
          Text(text, style: GoogleFonts.poppins(
            fontSize: 11, fontWeight: FontWeight.w600, color: fgColor,
          )),
        ],
      ),
    );
  }

  // ─── Type Color Helper ─────────────────────────────────────
  static Color typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lecture': return primaryBlue;
      case 'lab': case 'sessional': return const Color(0xFF7C3AED);
      case 'tutorial': return accentCyan;
      case 'online': return successGreen;
      default: return textSecondary;
    }
  }

  static Color typeBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'lecture': return primaryBlueLight;
      case 'lab': case 'sessional': return const Color(0xFFF3F0FF);
      case 'tutorial': return infoCyanLight;
      case 'online': return successGreenLight;
      default: return surfaceLight;
    }
  }

  // ─── ThemeData (Light) ─────────────────────────────────────
  static ThemeData get darkTheme => lightTheme;

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryBlue,
      secondary: accentBlue,
      surface: cardWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      error: errorRed,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        labelStyle: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.poppins(color: primaryBlue, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textHint),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
          side: BorderSide(color: borderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: pillButton()),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXL)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: dividerColor, thickness: 1),
      popupMenuTheme: PopupMenuThemeData(
        color: cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(fillColor: inputFill, filled: true),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryBlue,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryBlue,
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
