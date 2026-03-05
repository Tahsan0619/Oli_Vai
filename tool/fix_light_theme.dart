import 'dart:io';

void main() {
  final files = [
    'lib/screens/student_screen.dart',
    'lib/screens/teacher_screen.dart',
    'lib/screens/room_screen.dart',
    'lib/screens/free_rooms_screen.dart',
    'lib/screens/student_profile_screen.dart',
    'lib/screens/teacher_profile_screen.dart',
    'lib/screens/teacher_admin_portal_screen_new.dart',
    'lib/screens/super_admin_portal_screen_new.dart',
    'lib/widgets/schedule_card.dart',
    'lib/widgets/online_badge.dart',
    'lib/widgets/custom_search_bar.dart',
    'lib/widgets/custom_input_field.dart',
    'lib/widgets/custom_dropdown.dart',
    'lib/widgets/department_dropdown.dart',
    'lib/widgets/teacher_card.dart',
    'lib/widgets/brand_card.dart',
    'lib/widgets/big_nav_button.dart',
    'lib/widgets/gradient_shell.dart',
    'lib/widgets/animated_illustration.dart',
    'lib/screens/manage_batches_screen.dart',
    'lib/screens/manage_rooms_screen.dart',
    'lib/screens/manage_teachers_screen.dart',
    'lib/screens/add_edit_schedule_screen.dart',
  ];

  int totalReplacements = 0;

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('SKIP (not found): $path');
      continue;
    }

    var content = file.readAsStringSync();
    final original = content;

    // ── Body/input text: white → dark ──
    content = content.replaceAll(
      "style: GoogleFonts.poppins(color: Colors.white,",
      "style: GoogleFonts.poppins(color: AppTheme.textPrimary,",
    );
    content = content.replaceAll(
      "style: GoogleFonts.poppins(color: Colors.white)",
      "style: GoogleFonts.poppins(color: AppTheme.textPrimary)",
    );

    // ── Hint/placeholder text ──
    content = content.replaceAll(
      "const Color(0xFF5A5F7E)",
      "AppTheme.textHint",
    );
    content = content.replaceAll(
      "Color(0xFF5A5F7E)",
      "AppTheme.textHint",
    );
    content = content.replaceAll(
      "const Color(0xFF9DA4C5)",
      "AppTheme.textSecondary",
    );
    content = content.replaceAll(
      "Color(0xFF9DA4C5)",
      "AppTheme.textSecondary",
    );
    content = content.replaceAll(
      "const Color(0xFF7A809E)",
      "AppTheme.textSecondary",
    );
    content = content.replaceAll(
      "Color(0xFF7A809E)",
      "AppTheme.textSecondary",
    );
    content = content.replaceAll(
      "const Color(0xFF2A2F55)",
      "AppTheme.textHint",
    );
    content = content.replaceAll(
      "Color(0xFF2A2F55)",
      "AppTheme.textHint",
    );

    // ── Empty state icon colors (was dark blue, now light gray) ──
    content = content.replaceAll(
      "const Color(0xFF2A2A2A)",
      "AppTheme.surfaceLight",
    );
    content = content.replaceAll(
      "Color(0xFF2A2A2A)",
      "AppTheme.surfaceLight",
    );

    // ── Old dark backgrounds ──
    content = content.replaceAll(
      "const Color(0xFF121212)",
      "AppTheme.scaffoldBg",
    );
    content = content.replaceAll(
      "Color(0xFF121212)",
      "AppTheme.scaffoldBg",
    );
    content = content.replaceAll(
      "const Color(0xFF1E1E1E)",
      "AppTheme.cardWhite",
    );
    content = content.replaceAll(
      "Color(0xFF1E1E1E)",
      "AppTheme.cardWhite",
    );
    content = content.replaceAll(
      "backgroundColor: AppTheme.cardDark",
      "backgroundColor: AppTheme.cardWhite",
    );

    // ── Old accent colors ──
    content = content.replaceAll(
      "const Color(0xFF5B7CFF)",
      "AppTheme.primaryBlue",
    );
    content = content.replaceAll(
      "Color(0xFF5B7CFF)",
      "AppTheme.primaryBlue",
    );
    content = content.replaceAll(
      "const Color(0xFF8A5BFF)",
      "AppTheme.primaryDark",
    );
    content = content.replaceAll(
      "Color(0xFF8A5BFF)",
      "AppTheme.primaryDark",
    );

    // ── BottomNav dark bg ──
    content = content.replaceAll(
      "const Color(0xFF0E1333)",
      "Colors.white",
    );
    content = content.replaceAll(
      "Color(0xFF0E1333)",
      "Colors.white",
    );

    // ── Dropdown dark colors ──
    content = content.replaceAll(
      "dropdownColor: AppTheme.cardDark",
      "dropdownColor: Colors.white",
    );
    content = content.replaceAll(
      "dropdownColor: AppTheme.surfaceDark",
      "dropdownColor: Colors.white",
    );

    // ── Free rooms text on colored bg ──
    // Room chip text was white, now should be dark since bg is light  
    // (only for non-gradient backgrounds)

    // ── Colors.white70 in non-gradient contexts → textSecondary ──
    // But keep Colors.white on gradient/colored backgrounds — 
    // We'll handle subtitle.copyWith(color: Colors.white70) → subtitle
    content = content.replaceAll(
      "color: Colors.white70)",
      "color: AppTheme.textSecondary)",
    );

    // ── Grey old references ──
    content = content.replaceAll(
      "Colors.grey[600]",
      "AppTheme.textHint",
    );
    content = content.replaceAll(
      "Colors.grey[400]",
      "AppTheme.textSecondary",
    );
    content = content.replaceAll(
      "Colors.grey[500]",
      "AppTheme.textHint",
    );
    content = content.replaceAll(
      "Colors.grey[700]",
      "AppTheme.textHint",
    );
    content = content.replaceAll(
      "Colors.grey[300]",
      "AppTheme.textSecondary",
    );

    // ── Old dark red refs ──
    content = content.replaceAll(
      "const Color(0xFFFF6B6B)",
      "AppTheme.errorRed",
    );
    content = content.replaceAll(
      "Color(0xFFFF6B6B)",
      "AppTheme.errorRed",
    );

    // ── Old pink ──
    content = content.replaceAll(
      "const Color(0xFFFF6B9D)",
      "AppTheme.primaryBlue",
    );
    content = content.replaceAll(
      "Color(0xFFFF6B9D)",
      "AppTheme.primaryBlue",
    );

    // ── Old teal ──
    content = content.replaceAll(
      "const Color(0xFF4ECDC4)",
      "AppTheme.successGreen",
    );
    content = content.replaceAll(
      "Color(0xFF4ECDC4)",
      "AppTheme.successGreen",
    );

    // ── AppBar with transparent bg ── 
    content = content.replaceAll(
      "backgroundColor: Colors.transparent, elevation: 0,\n        title: Text('My Profile', style: AppTheme.heading3),\n        centerTitle: true,\n        iconTheme: const IconThemeData(color: Colors.white),",
      "backgroundColor: Colors.white, elevation: 0, surfaceTintColor: Colors.transparent,\n        title: Text('My Profile', style: AppTheme.heading3),\n        centerTitle: true,\n        iconTheme: const IconThemeData(color: AppTheme.textPrimary),",
    );

    // ── Free room chips: text should use textPrimary ──
    // Already handled by Colors.white → keep only on gradient bgs

    // ── fillColor old dark refs ──
    content = content.replaceAll(
      "fillColor: const Color(0xFF2A2A2A)",
      "fillColor: AppTheme.inputFill",
    );
    content = content.replaceAll(
      "fillColor: AppTheme.surfaceDark",
      "fillColor: AppTheme.inputFill",
    );

    // ── Add import if missing ──
    if (!content.contains("app_theme.dart") && content.contains("AppTheme")) {
      // Find last import line
      final importRegex = RegExp(r"import '[^']+';");
      final matches = importRegex.allMatches(content).toList();
      if (matches.isNotEmpty) {
        final lastImport = matches.last;
        content = content.substring(0, lastImport.end) +
            "\nimport '../utils/app_theme.dart';" +
            content.substring(lastImport.end);
      }
    }

    if (content != original) {
      file.writeAsStringSync(content);
      print('UPDATED: $path');
      totalReplacements++;
    } else {
      print('NO CHANGES: $path');
    }
  }

  print('\nDone! Updated $totalReplacements files.');
}
