// Batch fix: Change Colors.white text to dark text for light theme
// Also fix old hardcoded dark-theme colors

import 'dart:io';

void main() {
  final base = 'lib';
  int totalUpdated = 0;

  // ─── Super Admin Portal: targeted fixes ─────────────────────
  {
    final f = File('$base/screens/super_admin_portal_screen_new.dart');
    var src = f.readAsStringSync();
    final original = src;

    // Section headings pattern: fontSize 20-24, fontWeight, color: Colors.white
    // These are on light cardWhite/scaffoldBg backgrounds
    // 'System Overview', 'Quick Actions', 'Manage Batches', 'Manage Students',
    // 'Manage Teachers', 'Manage Timetable'
    // Also stat card values (fontSize: 32), quick action titles (fontSize: 16),
    // list tile titles, dialog titles (fontSize: 18)

    // Strategy: replace ALL color: Colors.white in GoogleFonts.poppins text styles
    // Then restore the specific ones that need to stay white

    // First, store protected lines content
    // Lines that should KEEP Colors.white:
    // 1. Header gradient: 'Super Admin' text + caption (already .copyWith correct)
    // 2. Tab bar selected text
    // 3. Teacher initial on gradient avatar (line ~2222)
    // 4. ChoiceChip selected label
    // 5. Heatmap count on colored box
    // 6. Stats type cards on colored background
    // 7. Icon colors on gradient containers

    // Replace patterns for TEXT that should be dark:

    // Pattern 1: Section headings
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                  fontSize: 24,\n                  fontWeight: FontWeight.w600,\n                  color: Colors.white,\n                ),",
      "style: GoogleFonts.poppins(\n                  fontSize: 24,\n                  fontWeight: FontWeight.w600,\n                  color: AppTheme.textPrimary,\n                ),",
    );

    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                  fontSize: 20,\n                  fontWeight: FontWeight.w600,\n                  color: Colors.white,\n                ),",
      "style: GoogleFonts.poppins(\n                  fontSize: 20,\n                  fontWeight: FontWeight.w600,\n                  color: AppTheme.textPrimary,\n                ),",
    );

    // Pattern 2: Stat card value (fontSize 32)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n              fontSize: 32,\n              fontWeight: FontWeight.w700,\n              color: Colors.white,\n            ),",
      "style: GoogleFonts.poppins(\n              fontSize: 32,\n              fontWeight: FontWeight.w700,\n              color: AppTheme.textPrimary,\n            ),",
    );

    // Pattern 3: Quick action card title + teacher/student name (fontSize 16)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: Colors.white,\n                      ),",
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: AppTheme.textPrimary,\n                      ),",
    );

    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                    fontSize: 16,\n                    fontWeight: FontWeight.w600,\n                    color: Colors.white,\n                  ),",
      "style: GoogleFonts.poppins(\n                    fontSize: 16,\n                    fontWeight: FontWeight.w600,\n                    color: AppTheme.textPrimary,\n                  ),",
    );

    // Pattern 4: List tile titles (fontWeight w600, no fontSize)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                    fontWeight: FontWeight.w600,\n                    color: Colors.white,\n                  ),",
      "style: GoogleFonts.poppins(\n                    fontWeight: FontWeight.w600,\n                    color: AppTheme.textPrimary,\n                  ),",
    );

    // Pattern 5: Dialog titles (fontSize 18)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n          fontSize: 18,\n          fontWeight: FontWeight.w600,\n          color: Colors.white,\n        ),",
      "style: GoogleFonts.poppins(\n          fontSize: 18,\n          fontWeight: FontWeight.w600,\n          color: AppTheme.textPrimary,\n        ),",
    );

    // Pattern 6: Course title in timetable entry card (fontSize 16 different indent)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: Colors.white,\n                      ),",
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: AppTheme.textPrimary,\n                      ),",
    );

    // Pattern 7: 4-space indent list title
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                fontWeight: FontWeight.w600,\n                color: Colors.white,\n              ),",
      "style: GoogleFonts.poppins(\n                fontWeight: FontWeight.w600,\n                color: AppTheme.textPrimary,\n              ),",
    );

    // Pattern 8: Section heading with different indentation (6 spaces)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n              fontSize: 20,\n              fontWeight: FontWeight.w600,\n              color: Colors.white,\n            ),",
      "style: GoogleFonts.poppins(\n              fontSize: 20,\n              fontWeight: FontWeight.w600,\n              color: AppTheme.textPrimary,\n            ),",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: super_admin_portal_screen_new.dart');
    } else {
      print('NO CHANGES: super_admin_portal_screen_new.dart');
    }
  }

  // ─── Manage Batches ─────────────────────────────────────────
  {
    final f = File('$base/screens/manage_batches_screen.dart');
    var src = f.readAsStringSync();
    final original = src;

    // AppBar title
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n            fontSize: 20,\n            fontWeight: FontWeight.w600,\n            color: Colors.white,\n          ),",
      "style: GoogleFonts.poppins(\n            fontSize: 20,\n            fontWeight: FontWeight.w600,\n            color: AppTheme.textPrimary,\n          ),",
    );
    // Search field text
    src = src.replaceAll(
      "style: const TextStyle(color: Colors.white),",
      "style: TextStyle(color: AppTheme.textPrimary),",
    );
    // Batch card name (not on gradient, on surfaceDark)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: Colors.white,\n                      ),",
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: AppTheme.textPrimary,\n                      ),",
    );
    // Old hardcoded colors
    src = src.replaceAll("color: Color(0xFFB0B0B0)", "color: AppTheme.textSecondary");
    src = src.replaceAll("color: Color(0xFF808080)", "color: AppTheme.textHint");
    src = src.replaceAll("BorderSide(color: Color(0xFF404040))", "BorderSide(color: AppTheme.dividerColor)");
    src = src.replaceAll("color: Colors.grey[800]", "color: AppTheme.dividerColor");
    src = src.replaceAll("Divider(color: Colors.grey[800])", "Divider(color: AppTheme.dividerColor)");

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: manage_batches_screen.dart');
    } else {
      print('NO CHANGES: manage_batches_screen.dart');
    }
  }

  // ─── Manage Teachers ────────────────────────────────────────
  {
    final f = File('$base/screens/manage_teachers_screen.dart');
    var src = f.readAsStringSync();
    final original = src;

    // AppBar title
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n            fontSize: 20,\n            fontWeight: FontWeight.w600,\n            color: Colors.white,\n          ),",
      "style: GoogleFonts.poppins(\n            fontSize: 20,\n            fontWeight: FontWeight.w600,\n            color: AppTheme.textPrimary,\n          ),",
    );
    // Search field text
    src = src.replaceAll(
      "style: const TextStyle(color: Colors.white),",
      "style: TextStyle(color: AppTheme.textPrimary),",
    );
    // Teacher card name (on surfaceDark, not gradient)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: Colors.white,\n                      ),",
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: AppTheme.textPrimary,\n                      ),",
    );
    // Old hardcoded colors
    src = src.replaceAll("color: Color(0xFFB0B0B0)", "color: AppTheme.textSecondary");
    src = src.replaceAll("color: Color(0xFF808080)", "color: AppTheme.textHint");
    src = src.replaceAll("BorderSide(color: Color(0xFF404040))", "BorderSide(color: AppTheme.dividerColor)");
    src = src.replaceAll("color: Colors.grey[800]", "color: AppTheme.dividerColor");
    src = src.replaceAll("Divider(color: Colors.grey[800])", "Divider(color: AppTheme.dividerColor)");

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: manage_teachers_screen.dart');
    } else {
      print('NO CHANGES: manage_teachers_screen.dart');
    }
  }

  // ─── Manage Rooms ───────────────────────────────────────────
  {
    final f = File('$base/screens/manage_rooms_screen.dart');
    var src = f.readAsStringSync();
    final original = src;

    // AppBar title
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n            fontSize: 20,\n            fontWeight: FontWeight.w600,\n            color: Colors.white,\n          ),",
      "style: GoogleFonts.poppins(\n            fontSize: 20,\n            fontWeight: FontWeight.w600,\n            color: AppTheme.textPrimary,\n          ),",
    );
    // Search field text
    src = src.replaceAll(
      "style: const TextStyle(color: Colors.white),",
      "style: TextStyle(color: AppTheme.textPrimary),",
    );
    // Room card name
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: Colors.white,\n                      ),",
      "style: GoogleFonts.poppins(\n                        fontSize: 16,\n                        fontWeight: FontWeight.w600,\n                        color: AppTheme.textPrimary,\n                      ),",
    );
    // Old hardcoded colors
    src = src.replaceAll("color: Color(0xFFB0B0B0)", "color: AppTheme.textSecondary");
    src = src.replaceAll("color: Color(0xFF808080)", "color: AppTheme.textHint");
    src = src.replaceAll("BorderSide(color: Color(0xFF404040))", "BorderSide(color: AppTheme.dividerColor)");
    src = src.replaceAll("color: Colors.grey[800]", "color: AppTheme.dividerColor");
    src = src.replaceAll("Divider(color: Colors.grey[800])", "Divider(color: AppTheme.dividerColor)");

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: manage_rooms_screen.dart');
    } else {
      print('NO CHANGES: manage_rooms_screen.dart');
    }
  }

  // ─── Schedule List Widget ───────────────────────────────────
  {
    final f = File('$base/widgets/schedule_list.dart');
    var src = f.readAsStringSync();
    final original = src;

    // ListTile title text (on light background)
    // Keep CircleAvatar child text white (on colored bg)
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                    color: Colors.white,",
      "style: GoogleFonts.poppins(\n                    color: AppTheme.textPrimary,",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: schedule_list.dart');
    } else {
      print('NO CHANGES: schedule_list.dart');
    }
  }

  // ─── Department Dropdown ────────────────────────────────────
  {
    final f = File('$base/widgets/department_dropdown.dart');
    var src = f.readAsStringSync();
    final original = src;

    // Text style
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n          color: Colors.white,\n          fontSize: 14,\n          fontWeight: FontWeight.w600,\n        ),",
      "style: GoogleFonts.poppins(\n          color: AppTheme.textPrimary,\n          fontSize: 14,\n          fontWeight: FontWeight.w600,\n        ),",
    );
    // Icon
    src = src.replaceAll(
      "icon: const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),",
      "icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textHint, size: 20),",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: department_dropdown.dart');
    } else {
      print('NO CHANGES: department_dropdown.dart');
    }
  }

  // ─── Custom Dropdown ────────────────────────────────────────
  {
    final f = File('$base/widgets/custom_dropdown.dart');
    var src = f.readAsStringSync();
    final original = src;

    // Icon
    src = src.replaceAll(
      "icon: const Icon(Icons.arrow_drop_down, color: Colors.white),",
      "icon: const Icon(Icons.arrow_drop_down, color: AppTheme.textHint),",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: custom_dropdown.dart');
    } else {
      print('NO CHANGES: custom_dropdown.dart');
    }
  }

  // ─── Brand Card (fix: textPrimary on gradient → white) ─────
  {
    final f = File('$base/widgets/brand_card.dart');
    var src = f.readAsStringSync();
    final original = src;

    // Department name on gradient should be white, not textPrimary
    src = src.replaceAll(
      "style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w600),",
      "style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: brand_card.dart');
    } else {
      print('NO CHANGES: brand_card.dart');
    }
  }

  // ─── Gradient Shell ─────────────────────────────────────────
  {
    final f = File('$base/widgets/gradient_shell.dart');
    var src = f.readAsStringSync();
    final original = src;

    // When useDarkBackground, AppBar bg is cardDark (white) so text must be dark
    // Current: foregroundColor: Colors.white always
    // Fix: make foreground conditional
    src = src.replaceAll(
      "appBar: AppBar(\n          backgroundColor: useDarkBackground ? AppTheme.cardDark : Colors.transparent,\n          foregroundColor: Colors.white,\n          elevation: 0,\n          title: Text(title, style: const TextStyle(color: Colors.white)),",
      "appBar: AppBar(\n          backgroundColor: useDarkBackground ? AppTheme.cardDark : Colors.transparent,\n          foregroundColor: useDarkBackground ? AppTheme.textPrimary : Colors.white,\n          elevation: 0,\n          title: Text(title, style: TextStyle(color: useDarkBackground ? AppTheme.textPrimary : Colors.white)),",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: gradient_shell.dart');
    } else {
      print('NO CHANGES: gradient_shell.dart');
    }
  }

  // ─── Add/Edit Schedule Screen ───────────────────────────────
  {
    final f = File('$base/screens/add_edit_schedule_screen.dart');
    var src = f.readAsStringSync();
    final original = src;

    // Replace dark theme override with light-compatible styling
    src = src.replaceAll(
      "data: ThemeData.dark().copyWith(\n          colorScheme: ThemeData.dark().colorScheme.copyWith(\n                primary: AppTheme.accentBlue,\n                secondary: AppTheme.accentBlue,\n              ),\n          scaffoldBackgroundColor: Colors.transparent,\n          inputDecorationTheme: const InputDecorationTheme(\n            filled: true,\n            fillColor: Color(0xFF1F1F1F),\n            border: OutlineInputBorder(),\n            enabledBorder: OutlineInputBorder(\n              borderSide: BorderSide(color: Color(0xFF424242)),\n            ),\n            focusedBorder: OutlineInputBorder(\n              borderSide: BorderSide(color: AppTheme.accentBlue),\n            ),\n            labelStyle: TextStyle(color: AppTheme.textSecondary),\n          ),\n          outlinedButtonTheme: OutlinedButtonThemeData(\n            style: OutlinedButton.styleFrom(\n              foregroundColor: Colors.white,\n              side: const BorderSide(color: AppTheme.textSecondary),\n            ),\n          ),\n          filledButtonTheme: FilledButtonThemeData(\n            style: FilledButton.styleFrom(\n              backgroundColor: AppTheme.accentBlue,\n              foregroundColor: Colors.white,\n            ),\n          ),\n        ),",
      "data: AppTheme.lightTheme.copyWith(\n          scaffoldBackgroundColor: Colors.transparent,\n          outlinedButtonTheme: OutlinedButtonThemeData(\n            style: OutlinedButton.styleFrom(\n              foregroundColor: AppTheme.textPrimary,\n              side: const BorderSide(color: AppTheme.textSecondary),\n            ),\n          ),\n          filledButtonTheme: FilledButtonThemeData(\n            style: FilledButton.styleFrom(\n              backgroundColor: AppTheme.accentBlue,\n              foregroundColor: Colors.white,\n            ),\n          ),\n        ),",
    );

    // Day heading
    src = src.replaceAll(
      "style: GoogleFonts.poppins(\n                    fontSize: 20,\n                    fontWeight: FontWeight.bold,\n                    color: Colors.white,\n                  ),",
      "style: GoogleFonts.poppins(\n                    fontSize: 20,\n                    fontWeight: FontWeight.bold,\n                    color: AppTheme.textPrimary,\n                  ),",
    );

    if (src != original) {
      f.writeAsStringSync(src);
      totalUpdated++;
      print('UPDATED: add_edit_schedule_screen.dart');
    } else {
      print('NO CHANGES: add_edit_schedule_screen.dart');
    }
  }

  print('\n✅ UPDATED: $totalUpdated files. Done!');
}
