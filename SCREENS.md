# EDTE Routine — Screen-by-Screen Design Reference (Figma Handoff)

> **Platform**: Flutter (Android + Web)  
> **Backend**: Supabase (PostgreSQL + Auth + Storage)  
> **State Management**: Provider (`ChangeNotifierProvider`)  
> **Typography**: Google Fonts — Poppins  
> **Key Packages**: `google_fonts`, `provider`, `supabase_flutter`, `image_picker`, `intl`, `pdf`, `printing`, `file_picker`

---
a
## Table of Contents

1. [App Overview](#app-overview)
2. [User Roles](#user-roles)
3. [Design System](#design-system)
4. [Navigation Flow](#navigation-flow)
5. [Screens — Detailed Breakdown](#screens--detailed-breakdown)
   - [Login Screen](#1-unified-login-screen)
   - [Student Screens](#student-screens-5-tabs)
     - [Student Schedule](#2-student-schedule-screen)
     - [Teacher Lookup](#3-teacher-lookup-screen)
     - [Room Search](#4-room-search-screen)
     - [Free Rooms](#5-free-rooms-screen)
     - [Student Profile](#6-student-profile-screen)
   - [Teacher/Admin Screens](#teacheradmin-screens)
     - [Teacher Admin Portal](#7-teacher-admin-portal-screen)
     - [Teacher Profile](#8-teacher-profile-screen)
   - [Super Admin Portal](#super-admin-portal-6-tabs)
     - [Dashboard Tab](#9a-super-admin--dashboard-tab)
     - [Batches Tab](#9b-super-admin--batches-tab)
     - [Students Tab](#9c-super-admin--students-tab)
     - [Teachers Tab](#9d-super-admin--teachers-tab)
     - [Timetable Tab](#9e-super-admin--timetable-tab)
     - [Analytics Tab](#9f-super-admin--analytics-tab)
   - [Add/Edit Schedule](#10-addedit-schedule-screen)
   - [Legacy Screens](#legacy-screens)
6. [Reusable Widgets](#reusable-widgets)
7. [Data Models](#data-models)

---

## App Overview

**EDTE Routine** is a university schedule management application used by the EdTE (Educational Technology and Engineering) department. It allows students to look up class schedules, teachers to manage their own classes, and super admins to manage all system data (batches, students, teachers, timetable entries).

### Core Functionality
- **Students**: Search schedule by batch, look up teacher schedules, check room availability, find free rooms
- **Teachers/Admins**: View their weekly schedule, cancel/reschedule/swap rooms for classes, manage their profile
- **Super Admins**: Full CRUD on batches, students, teachers, and timetable entries. Analytics dashboard. PDF export and JSON/CSV import of timetable data.

---

## User Roles

| Role | Login Credentials | Access Level |
|------|------------------|-------------|
| **Student** | Email + Password | View schedules, search rooms, manage own profile |
| **Teacher / Teacher Admin** | Email + Password | View & manage own schedule, profile editing, photo upload |
| **Super Admin** | Username + Password | Full system management, CRUD all entities, analytics, import/export |

### Authentication Flow
1. User opens the app → `AuthCheck` widget runs
2. If a saved session exists (stored in `SharedPreferences`), the user is routed directly to their portal
3. If no session → `UnifiedLoginScreen` is shown
4. The login screen tries credentials sequentially: **Admin → Teacher → Student**
5. On success, navigates to the appropriate portal with `pushReplacement`

---

## Design System

### Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| `scaffoldBg` | `#F5F6FA` | Page background (light gray) |
| `cardWhite` | `#FFFFFF` | Card surfaces |
| `surfaceLight` | `#F0F2F7` | Subtle surface variant |
| `inputFill` | `#F5F6FA` | Input field backgrounds |
| `dividerColor` | `#E8EAF0` | Borders, dividers |
| **`primaryBlue`** | **`#4366F6`** | **Primary accent — buttons, links, selected states, gradients** |
| `primaryLight` | `#EEF1FE` | Light blue highlight (selected nav items) |
| `primaryDark` | `#2C4BD6` | Darker blue variant |
| `successGreen` | `#34C759` | Success states, free rooms, online indicators |
| `warningAmber` | `#FF9F0A` | Warnings, editing states, afternoon labels |
| `errorRed` | `#FF3B30` | Errors, delete actions, cancelled classes, logout |
| `infoCyan` | `#32ADE6` | Informational highlights |

### Text Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `textPrimary` | `#1E293B` | Main body text, headings (dark navy) |
| `textSecondary` | `#64748B` | Subtitles, captions (medium gray) |
| `textHint` | `#94A3B8` | Placeholder text, hints (light gray) |
| `textOnPrimary` | `#FFFFFF` | Text on colored/gradient backgrounds |

### Gradients

All role-specific gradients use the primary blue family:

| Gradient | Colors | Direction | Usage |
|----------|--------|-----------|-------|
| `studentGradient` | `#4366F6 → #6B8AFF` | Top-left → Bottom-right | Student header icons, logo background |
| `studentCardGradient` | `#4366F6 → #5B7CFF` | Top-left → Bottom-right | Student profile header card |
| `teacherGradient` | `#4366F6 → #6B8AFF` | Top-left → Bottom-right | Teacher header icons |
| `teacherCardGradient` | `#4366F6 → #5B7CFF` | Top-left → Bottom-right | Teacher portal header, teacher profile header |
| `adminGradient` | `#4366F6 → #6B8AFF` | Top-left → Bottom-right | Super admin header |
| `adminCardGradient` | `#4366F6 → #5B7CFF` | Top-left → Bottom-right | Admin card backgrounds |

### Typography

| Style | Font | Size | Weight | Color | Letter-spacing |
|-------|------|------|--------|-------|----------------|
| `heading1` | Poppins | 28px | Bold (700) | `#1E293B` | -0.5 |
| `heading2` | Poppins | 22px | SemiBold (600) | `#1E293B` | — |
| `heading3` | Poppins | 18px | SemiBold (600) | `#1E293B` | — |
| `heading3White` | Poppins | 18px | SemiBold (600) | `#FFFFFF` | — |
| `subtitle` | Poppins | 14px | Regular (400) | `#64748B` | — |
| `body` | Poppins | 14px | Regular (400) | `#1E293B` | — |
| `caption` | Poppins | 12px | Regular (400) | `#64748B` | — |
| `label` | Poppins | 12px | SemiBold (600) | `#64748B` | 1.0 |

### Border Radii

| Token | Value | Usage |
|-------|-------|-------|
| `radiusS` | 8px | Small chips, badges |
| `radiusM` | 12px | Input fields, buttons |
| `radiusL` | 16px | Cards (default) |
| `radiusXL` | 24px | Profile header cards, large containers |

### Shadows

| Type | Description |
|------|-------------|
| `cardShadow` | Subtle double-layer: black 4% at blur 12px offset (0,2) + black 2% at blur 4px offset (0,1) |
| `softShadow(color)` | Color at 15% opacity, blur 16px, offset (0,6) |
| `glowShadow(color)` | Color at 25% opacity, blur 20px, spread -4px, offset (0,8) |

### Card Decorations

| Decoration | Background | Border | Corners | Shadow |
|------------|-----------|--------|---------|--------|
| `cleanCard()` | `#FFFFFF` | `#E8EAF0` 1px | 16px (radiusL) | `cardShadow` |
| `cleanCard(borderColor)` | `#FFFFFF` | Custom color at 30% | 16px | `cardShadow` |
| `glassCard()` | `#FFFFFF` | Optional color at 15% | 16px | `cardShadow` |

---

## Navigation Flow

```
App Launch
  └── AuthCheck (splash with pulsing school icon + "Loading...")
        │
        ├── Saved super_admin session ──────► SuperAdminPortalScreen (6 tabs)
        ├── Saved teacher/teacher_admin ────► TeacherAdminPortalScreen
        ├── Saved student session ──────────► MainNavigationScreen (5 tabs)
        └── No saved session ──────────────► UnifiedLoginScreen
                                                │
                                                ├── Admin credentials ──► SuperAdminPortalScreen
                                                ├── Teacher credentials ► TeacherAdminPortalScreen
                                                └── Student credentials ► MainNavigationScreen
```

### Student Navigation (Bottom Tab Bar)

```
MainNavigationScreen
  ├── Tab 0: StudentScreen       (Schedule search by batch)
  ├── Tab 1: TeacherScreen       (Teacher schedule lookup)
  ├── Tab 2: RoomScreen          (Room occupancy check)
  ├── Tab 3: FreeRoomsScreen     (All free rooms by time slot)
  └── Tab 4: StudentProfileScreen (Profile + password + logout)
```

### Teacher Navigation

```
TeacherAdminPortalScreen
  ├── Header → Profile icon button ──► TeacherProfileScreen (push)
  ├── Header → Logout icon button ──► UnifiedLoginScreen (replace)
  └── Body: Weekly schedule with day selector
```

### Super Admin Navigation

```
SuperAdminPortalScreen (6 horizontal tabs)
  ├── Tab 0: Dashboard     (Stats + quick action cards)
  ├── Tab 1: Batches       (CRUD batch management)
  ├── Tab 2: Students      (CRUD + credentials + batch filter)
  ├── Tab 3: Teachers      (CRUD + credentials + search)
  ├── Tab 4: Timetable     (CRUD + export PDF + import JSON/CSV)
  └── Tab 5: Analytics     (Charts, tables, metrics)
```

---

## Screens — Detailed Breakdown

---

### 1. Unified Login Screen

**File**: `lib/screens/unified_login_screen_new.dart` (209 lines)  
**Role**: All users (pre-authentication)  
**Navigation**: Entry point → routes to appropriate portal on success

#### Layout
```
Scaffold (scaffoldBg background)
  └── SafeArea → Center → SingleChildScrollView → ConstrainedBox (maxWidth: 420)
        └── Column (center-aligned)
              ├── Logo Container
              │     └── 64×64 rounded box (radiusL, studentGradient bg)
              │         └── school icon (32px, white)
              ├── SizedBox(16)
              ├── App Title: "EDTE Routine" (heading1, textPrimary)
              ├── Subtitle: "University Schedule Management" (subtitle, textSecondary)
              ├── SizedBox(32)
              └── Login Card (cleanCard decoration, padding 24)
                    ├── Header Row: login icon (primaryBlue) + "Sign In" (heading3, textPrimary)
                    ├── SizedBox(20)
                    ├── Username TextField
                    │     ├── Decoration: inputFill bg, radiusM corners, dividerColor border
                    │     ├── prefixIcon: person icon (textHint)
                    │     └── hintText: "Enter your username" (textHint)
                    ├── SizedBox(16)
                    ├── Password TextField
                    │     ├── Decoration: same as username
                    │     ├── prefixIcon: lock icon (textHint)
                    │     ├── hintText: "Enter your password" (textHint)
                    │     ├── obscureText: true (togglable)
                    │     └── suffixIcon: visibility/visibility_off toggle (textHint)
                    ├── SizedBox(8)
                    ├── Error Banner (conditional, shown on auth failure)
                    │     └── Container: errorRed bg at 10%, radiusM, padding 12
                    │         └── Row: error icon (errorRed) + message text (errorRed, body)
                    ├── SizedBox(20)
                    └── Sign In Button (full-width ElevatedButton)
                          ├── Style: primaryBlue bg, white text, radiusM pill shape
                          ├── Height: 48px
                          ├── Normal: "Sign In" text (16px, bold, white)
                          └── Loading: white CircularProgressIndicator (size 20)
```

#### States
| State | Visual Change |
|-------|--------------|
| Default | Empty form, no error banner |
| Loading | Button shows spinner, fields disabled |
| Error | Red error banner appears with error icon + message |

#### Interactions
| Element | Action |
|---------|--------|
| Username field | email keyboard type, `onSubmitted` → focus password |
| Password field | `onSubmitted` → trigger login |
| Visibility toggle | Toggles `obscureText` |
| Sign In button | Triggers sequential auth: admin → teacher → student |

---

### Student Screens (5 tabs)

All 5 student screens are hosted inside `MainNavigationScreen`, which provides a custom bottom navigation bar.

#### Main Navigation Screen

**File**: `lib/screens/main_navigation_screen.dart` (117 lines)  
**Role**: Student  
**Purpose**: Tab container with custom bottom navigation

#### Layout
```
Scaffold (scaffoldBg)
  ├── Body: IndexedStack (5 children — all screens stay alive across tab switches)
  └── Bottom Navigation Bar
        └── Container (white bg, top shadow: black 5% at blur 10px offset(0,-2))
              └── SafeArea (bottom) → Row (mainAxisAlignment: spaceAround)
                    └── 5 Nav Items (GestureDetector → Column):
                          ├── [0] Schedule — school icon
                          ├── [1] Teacher — person icon
                          ├── [2] Room — meeting_room icon
                          ├── [3] Free — event_available icon
                          └── [4] Profile — account_circle icon
```

#### Nav Item Design
| State | Background | Icon Color | Text |
|-------|-----------|------------|------|
| Unselected | transparent | `textHint` (#94A3B8) | Label in textHint, 10px |
| Selected | `primaryLight` (#EEF1FE) pill | `primaryBlue` (#4366F6) | Label in primaryBlue, 10px |

- AnimatedContainer with 200ms transition
- Selected pill: horizontal padding 16, vertical padding 8, radiusXL corners

#### States
| State | Visual |
|-------|--------|
| Loading | Centered CircularProgressIndicator (primaryBlue) on all tabs |
| Error | Centered red error text on all tabs |

---

### 2. Student Schedule Screen

**File**: `lib/screens/student_screen.dart` (175 lines)  
**Role**: Student (Tab 0)  
**Purpose**: Search today's class schedule by batch name

#### Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → Column
        ├── Header Row (horizontal padding 16, vertical padding 12)
        │     ├── Gradient Icon Container
        │     │     └── 44×44 circle, studentGradient bg, school icon (22px, white)
        │     ├── SizedBox(12)
        │     ├── "Student Schedule" (heading3, textPrimary)
        │     ├── Spacer
        │     ├── Today Day Abbreviation (caption, textSecondary), e.g. "Mon"
        │     ├── SizedBox(8)
        │     └── Online Status Badge
        │           └── Row: green dot (8px circle, successGreen) + "Online" (caption, successGreen)
        │
        ├── Search Bar (horizontal padding 16, margin bottom 8)
        │     └── Container (cleanCard decoration)
        │           └── TextField
        │                 ├── prefixIcon: search icon (textHint)
        │                 ├── hintText: "Enter Batch e.g. 60_C" (textHint)
        │                 ├── border: none
        │                 └── suffixIcon: Container (36px circle, studentPrimary bg)
        │                       └── arrow_forward icon (white, 20px)
        │
        └── Expanded Content Area (horizontal padding 16)
              ├── [Before search — initial state]:
              │     └── Center → Column
              │           ├── Container (80px circle, primaryLight bg)
              │           │     └── school icon (40px, primaryBlue)
              │           ├── SizedBox(16)
              │           └── "Search for your batch schedule" (subtitle, textSecondary, center)
              │
              ├── [Error — batch not found or no classes]:
              │     └── Center → Column
              │           ├── Container (80px circle, errorRed at 10% bg)
              │           │     └── event_busy icon (40px, errorRed)
              │           ├── SizedBox(16)
              │           └── Error message text (subtitle, textSecondary, center)
              │
              └── [Results — has entries]:
                    └── ListView.builder (itemCount: entries.length)
                          └── ScheduleCard (see Reusable Widgets section)
```

#### Data Displayed per Entry (via ScheduleCard)
| Field | Source |
|-------|--------|
| Course title | `repo.courseByCode(entry.courseCode).title` |
| Time range | `entry.start – entry.end` |
| Teacher name | `repo.teacherByInitial(entry.teacherInitial).name` |
| Room | `repo.roomById(entry.roomId).name` or "Online" |
| Batch name | `repo.batchById(entry.batchId).name` |
| Type | `entry.type` (Lecture/Tutorial/Sessional) |
| Cancelled | `entry.isCancelled` + `entry.cancellationReason` |

---

### 3. Teacher Lookup Screen

**File**: `lib/screens/teacher_screen.dart` (220 lines)  
**Role**: Student (Tab 1)  
**Purpose**: Search teacher's today schedule by initial; shows teacher profile card

#### Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → Column
        ├── Header Row (same pattern as StudentScreen)
        │     ├── Gradient Icon: teacherGradient, person icon
        │     └── "Teacher Schedule" title
        │
        ├── Search Bar (same pattern as StudentScreen)
        │     └── TextField
        │           ├── textCapitalization: characters (auto-uppercase)
        │           ├── hintText: "Enter Teacher Initial e.g. NRC"
        │           └── suffixIcon: blue circle with arrow_forward
        │
        ├── Teacher Profile Card (conditional — shown after successful search)
        │     └── Container (cleanCard, margin 16 horizontal, padding 16)
        │           ├── Row
        │           │     ├── Circle Avatar (48px)
        │           │     │     ├── Container: teacherGradient border (3px), white gap, inner circle
        │           │     │     └── Content: NetworkImage (profile pic) OR Text (first initial letter, white, bold)
        │           │     ├── SizedBox(12)
        │           │     └── Column (crossAxis: start)
        │           │           ├── Teacher Name (body, bold, textPrimary)
        │           │           └── Designation (caption, textSecondary)
        │           ├── SizedBox(12)
        │           └── Row (2 Info Chips)
        │                 ├── Phone Chip: Container (surfaceLight bg, radiusS)
        │                 │     └── Row: phone icon (14px, textSecondary) + phone number (caption)
        │                 └── Email Chip: Container (surfaceLight bg, radiusS)
        │                       └── Row: email icon (14px, textSecondary) + email (caption)
        │
        └── Expanded Content Area
              ├── [Before search]: person_search illustration (same pattern as StudentScreen empty)
              │     └── message: "Search for a teacher's initial"
              ├── [Not found]: Error message
              └── [Results]: ListView.builder of ScheduleCard widgets
```

---

### 4. Room Search Screen

**File**: `lib/screens/room_screen.dart` (164 lines)  
**Role**: Student (Tab 2)  
**Purpose**: Check if a specific room is occupied at a given day + time slot

#### Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → Column
        ├── Header Row (meeting_room icon, studentGradient)
        │     └── "Room Search" title + "Online" badge
        │
        └── Expanded → SingleChildScrollView → Column (padding 16)
              ├── Room Number TextField
              │     └── Container (cleanCard): numeric keyboard, hintText: "Room number"
              │
              ├── SizedBox(12)
              ├── Row (2 Dropdowns, Expanded each, gap 12)
              │     ├── Day Dropdown (cleanCard container)
              │     │     └── DropdownButton: Sat, Sun, Mon, Tue, Wed, Thu, Fri
              │     └── Time Dropdown (cleanCard container)
              │           └── DropdownButton:
              │                 ├── "08:30 - 10:00"
              │                 ├── "10:00 - 11:30"
              │                 ├── "11:30 - 01:00"
              │                 ├── "01:00 - 02:30"
              │                 └── "02:30 - 04:00"
              │
              ├── SizedBox(16)
              ├── "Search Room" ElevatedButton.icon (full width)
              │     └── Style: studentPrimary bg, white text, search icon
              │
              ├── SizedBox(16)
              └── Results Area
                    ├── [Room is free]:
                    │     └── Container (successGreen border, successGreen bg at 10%, radiusM)
                    │           └── Row: check_circle icon (successGreen) + "Room is free at this time!" (successGreen, bold)
                    └── [Room is occupied]:
                          └── ListView of ScheduleCard widgets
```

#### Validation
- SnackBar (errorRed) shown if room number, day, or time is empty when search is tapped

---

### 5. Free Rooms Screen

**File**: `lib/screens/free_rooms_screen.dart` (172 lines)  
**Role**: Student (Tab 3)  
**Purpose**: Find all available rooms for a selected time slot today

#### Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → Column
        ├── Header Row
        │     ├── Gradient Icon: teal/cyan gradient, event_available icon
        │     ├── "Free Rooms" title (heading3, textPrimary)
        │     └── "Today: [day abbreviation]" (caption, textSecondary)
        │
        └── Expanded → ListView (padding 16)
              ├── MORNING Section
              │     ├── Section Header
              │     │     └── Row: vertical bar (4px × 24px, warningAmber) + "MORNING" (label, warningAmber)
              │     ├── SizedBox(8)
              │     ├── Time Slot Card: "08:30 - 10:00"
              │     ├── Time Slot Card: "10:00 - 11:30"
              │     └── Time Slot Card: "11:30 - 01:00"
              │
              ├── SizedBox(16)
              ├── AFTERNOON Section
              │     ├── Section Header
              │     │     └── Row: vertical bar (4px × 24px, accentBlue) + "AFTERNOON" (label, accentBlue)
              │     ├── Time Slot Card: "01:00 - 02:30"
              │     └── Time Slot Card: "02:30 - 04:00"
              │
              └── [When a slot is selected]:
                    ├── SizedBox(16)
                    ├── "Available Rooms" heading + count badge
                    │     └── Badge: successGreen bg, "[N] rooms" text (white)
                    ├── SizedBox(12)
                    ├── [Has free rooms]:
                    │     └── Wrap (spacing 8, runSpacing 8)
                    │           └── Room Chips (per room):
                    │                 └── Container (successGreen border, successGreen bg at 5%, radiusM, padding 12)
                    │                       └── Row: meeting_room icon (successGreen) + "Room [name]" (body, successGreen)
                    └── [No free rooms]:
                          └── Container (errorRed border, errorRed bg at 5%, radiusM, padding 16)
                                └── Row: event_busy icon (errorRed) + "No free rooms at this time" (body, errorRed)
```

#### Time Slot Card Design
```
AnimatedContainer (200ms, cleanCard or selected style)
  └── InkWell → Padding(12)
        └── Row
              ├── access_time icon (20px)
              ├── SizedBox(8)
              ├── Time text (body)
              ├── Spacer
              └── [If selected]: Badge showing free room count (successGreen bg, white text)
```

| State | Background | Border | Icon/Text Color |
|-------|-----------|--------|-----------------|
| Unselected | cardWhite | dividerColor | textSecondary |
| Selected | primaryBlue at 5% | primaryBlue at 30% | primaryBlue |

---

### 6. Student Profile Screen

**File**: `lib/screens/student_profile_screen.dart` (188 lines)  
**Role**: Student (Tab 4)  
**Purpose**: View profile, change password, and logout

#### Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → SingleChildScrollView → Column (padding 16)
        ├── Profile Header Card
        │     └── Container (studentCardGradient bg, radiusXL, padding 24, center-aligned)
        │           ├── Circle Avatar (60px, white border 3px)
        │           │     └── First letter of name (24px, bold, white on primaryBlue bg)
        │           ├── SizedBox(12)
        │           ├── Student Name (18px, bold, white)
        │           ├── SizedBox(4)
        │           ├── Email (14px, white at 70%)
        │           ├── SizedBox(8)
        │           └── ID Badge
        │                 └── Container (white bg at 20%, radiusS, padding h12 v4)
        │                       └── "ID: [studentId]" (12px, white)
        │
        ├── SizedBox(20)
        ├── Security Section
        │     └── Container (cleanCard, padding 16)
        │           ├── Header Row
        │           │     ├── shield icon (24px, accentBlue)
        │           │     ├── SizedBox(8)
        │           │     ├── "Security" (heading3, textPrimary)
        │           │     ├── Spacer
        │           │     └── "Change" TextButton (primaryBlue) — toggles password form
        │           │
        │           └── [When expanded — _changingPw = true]:
        │                 ├── SizedBox(16)
        │                 ├── Current Password TextField (obscured, lock icon prefix)
        │                 ├── SizedBox(12)
        │                 ├── New Password TextField (obscured, lock_outline icon prefix)
        │                 ├── SizedBox(12)
        │                 ├── Confirm Password TextField (obscured, lock_outline icon prefix)
        │                 ├── SizedBox(16)
        │                 └── Row
        │                       ├── Cancel OutlinedButton (Expanded)
        │                       ├── SizedBox(12)
        │                       └── Update ElevatedButton (Expanded, primaryBlue)
        │                             └── Shows CircularProgressIndicator when loading
        │
        ├── SizedBox(20)
        └── Logout Button
              └── ElevatedButton.icon (full width)
                    ├── Style: errorRed bg, white text, radiusM
                    ├── Icon: logout icon (white)
                    └── Label: "Logout" (white, bold)
```

#### Dialogs
**Logout Confirmation**:
```
AlertDialog
  ├── Title: "Logout" (heading3, textPrimary)
  ├── Content: "Are you sure you want to logout?" (body, textSecondary)
  └── Actions:
        ├── "Cancel" TextButton (textSecondary)
        └── "Logout" ElevatedButton (errorRed bg, white text)
```

---

### Teacher/Admin Screens

---

### 7. Teacher Admin Portal Screen

**File**: `lib/screens/teacher_admin_portal_screen_new.dart` (555 lines)  
**Role**: Teacher / Teacher Admin  
**Purpose**: Weekly schedule viewer with class management actions (cancel, reschedule, change room)

#### Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → Column
        ├── Header Container
        │     └── Container (teacherCardGradient bg, borderRadius bottom-left/right 24px, padding 20)
        │           ├── Row
        │           │     ├── Dashboard Icon
        │           │     │     └── Container (48px circle, white border 2px)
        │           │     │           └── dashboard icon (24px, white)
        │           │     ├── SizedBox(12)
        │           │     ├── Column (crossAxis: start)
        │           │     │     ├── "Teacher Panel" (18px, white, bold)
        │           │     │     └── Teacher name (14px, white at 70%)
        │           │     ├── Spacer
        │           │     ├── Profile Icon Button
        │           │     │     └── 40px circle, white bg at 20%, person icon (white)
        │           │     │     └── Navigates to TeacherProfileScreen on tap
        │           │     └── Logout Icon Button
        │           │           └── 40px circle, errorRed bg at 20%, logout icon (white)
        │           │           └── Clears session, navigates to login
        │           │
        │           ├── SizedBox(16)
        │           └── Day Pills Row
        │                 └── SizedBox(height: 36) → ListView.builder (horizontal scroll)
        │                       └── 7 Day Pills: Sat, Sun, Mon, Tue, Wed, Thu, Fri
        │
        └── Expanded Body
              ├── [No entries for selected day]:
              │     └── Center → Column
              │           ├── event_busy icon (64px, textHint)
              │           ├── SizedBox(16)
              │           └── "No classes on [Day]" (subtitle, textSecondary)
              │
              └── [Has entries]:
                    └── ListView.builder (padding 16)
                          └── Entry Cards (one per timetable entry)
```

#### Day Pill Design
| State | Background | Text | Border |
|-------|-----------|------|--------|
| Unselected | white bg at 20% | white at 70% | none |
| Selected | teacherSecondary solid | white, bold | none |
| Pill size | padding h 16, v 8 | 13px | radiusXL corners |

#### Entry Card Design
```
Container (cleanCard, margin bottom 12, padding 16)
  ├── Row
  │     ├── Course Title
  │     │     ├── Normal: heading3, textPrimary
  │     │     └── Cancelled: heading3, textSecondary, line-through decoration
  │     ├── Spacer
  │     └── Time Badge
  │           └── Container (primaryBlue bg at 10%, radiusS, padding h 8 v 4)
  │                 └── "HH:mm-HH:mm" (caption, primaryBlue)
  │
  ├── SizedBox(8)
  ├── Info Row
  │     ├── Batch name chip (group icon + name)
  │     ├── Room/Online chip (meeting_room/wifi icon + text)
  │     └── Type chip (e.g. "Lecture")
  │
  ├── [If cancelled]:
  │     ├── SizedBox(8)
  │     ├── "CANCELLED" Badge
  │     │     └── Container (errorRed bg at 10%, radiusS): cancel icon + "CANCELLED" (errorRed, bold)
  │     └── [If has reason]:
  │           └── Container (errorRed bg at 5%, radiusS, margin top 4): reason text (errorRed, caption)
  │
  ├── SizedBox(12)
  └── Action Buttons Row
        ├── [If NOT cancelled]: 3 OutlinedButtons (Expanded each, gap 8)
        │     ├── "Reschedule" (calendar_today icon, primaryBlue border)
        │     ├── "Room" (meeting_room icon, primaryBlue border)
        │     └── "Cancel" (cancel icon, errorRed border, errorRed text)
        │
        └── [If cancelled]: 1 Button
              └── "Restore Class" ElevatedButton.icon (successGreen bg, white text)
```

#### Dialogs

**Cancel Class Dialog**:
```
AlertDialog (cleanCard style)
  ├── Title Row: cancel icon (errorRed) + "Cancel Class" (heading3)
  ├── Content:
  │     └── TextField (cleanCard bg, hintText: "Enter reason for cancellation")
  └── Actions:
        ├── "Back" TextButton (textSecondary)
        └── "Cancel Class" ElevatedButton (errorRed bg, white text)
```

**Change Room Dialog**:
```
AlertDialog (cleanCard style)
  ├── Title Row: meeting_room icon (primaryBlue) + "Change Room" (heading3)
  ├── Content:
  │     └── DropdownButtonFormField (all rooms, cleanCard bg)
  │           └── Items: room name (body, textPrimary)
  └── Actions:
        ├── "Cancel" TextButton (textSecondary)
        └── "Update" ElevatedButton (primaryBlue bg, white text)
```

**Reschedule Class Dialog**:
```
AlertDialog (cleanCard style)
  ├── Title Row: schedule icon (primaryBlue) + "Reschedule Class" (heading3)
  ├── Content (SingleChildScrollView):
  │     ├── "Start Time" TextField (cleanCard bg)
  │     ├── SizedBox(12)
  │     ├── "End Time" TextField (cleanCard bg)
  │     ├── SizedBox(12)
  │     ├── Day DropdownButtonFormField (Sat-Fri)
  │     ├── SizedBox(12)
  │     ├── Class Type DropdownButtonFormField (Lecture/Tutorial/Sessional)
  │     ├── SizedBox(12)
  │     └── Mode DropdownButtonFormField (Onsite/Online)
  └── Actions:
        ├── "Cancel" TextButton (textSecondary)
        └── "Save" ElevatedButton (primaryBlue bg, white text)
```

---

### 8. Teacher Profile Screen

**File**: `lib/screens/teacher_profile_screen.dart` (268 lines)  
**Role**: Teacher / Teacher Admin  
**Purpose**: View/edit teacher info, upload/remove profile photo, change password

#### Layout
```
Scaffold (scaffoldBg)
  ├── AppBar
  │     ├── Background: white / cardWhite
  │     ├── Title: "My Profile" (heading3, textPrimary, centered)
  │     ├── Leading: back arrow (automatic)
  │     └── Actions (state-dependent):
  │           ├── [View mode]: edit icon button (primaryBlue)
  │           └── [Edit mode]: check icon button (successGreen) + close icon button (errorRed)
  │
  └── SingleChildScrollView → Column (padding 16)
        ├── Avatar Section (center-aligned)
        │     ├── Stack
        │     │     ├── Outer Circle (130px, teacherGradient border 3px, white gap 3px)
        │     │     │     └── Inner Circle: ClipOval
        │     │     │           ├── [Has image]: NetworkImage (fit: cover) or FileImage (selected)
        │     │     │           └── [No image]: Container (teacherGradient bg)
        │     │     │                 └── Initial letter (48px, bold, white)
        │     │     ├── Glow: glowShadow(teacherPrimary) behind circle
        │     │     └── Camera Overlay (positioned bottom-right)
        │     │           └── Container (36px circle, primaryBlue bg, white border 2px)
        │     │                 └── camera_alt icon (18px, white)
        │     │
        │     ├── [Image selected — pending upload]:
        │     │     └── Row (margin top 12):
        │     │           ├── "Upload" ElevatedButton.icon (primaryBlue, cloud_upload icon)
        │     │           └── "Cancel" OutlinedButton (errorRed border)
        │     │
        │     └── [Has existing photo]:
        │           └── "Remove Photo" TextButton (errorRed, delete icon)
        │
        ├── SizedBox(24)
        ├── Teacher Info Card
        │     └── Container (cleanCard, padding 16)
        │           ├── Header Row
        │           │     ├── "Teacher Info" (heading3, textPrimary)
        │           │     └── [If editing]: Badge (warningAmber bg at 10%, radiusS)
        │           │           └── "Editing" (caption, warningAmber)
        │           ├── SizedBox(16)
        │           └── 6 Info Rows (view) OR 6 TextFields (edit):
        │                 ├── Name — person icon
        │                 ├── Initial — badge icon (read-only in edit mode)
        │                 ├── Email — email icon
        │                 ├── Phone — phone icon
        │                 ├── Designation — work icon
        │                 └── Department — business icon
        │
        ├── SizedBox(16)
        └── Security Card
              └── Container (cleanCard, padding 16)
                    ├── Header Row
                    │     ├── shield icon (24px, accentBlue)
                    │     ├── "Security" (heading3, textPrimary)
                    │     ├── Spacer
                    │     └── "Change" TextButton (primaryBlue)
                    │
                    └── [When expanded — _changingPw = true]:
                          ├── SizedBox(16)
                          ├── Current Password TextField (obscured)
                          ├── SizedBox(12)
                          ├── New Password TextField (obscured)
                          ├── SizedBox(12)
                          ├── Confirm Password TextField (obscured)
                          ├── SizedBox(16)
                          └── Row: Cancel (outlined) + Update (primaryBlue filled)
```

#### Info Row Design (View Mode)
```
Padding (vertical 8)
  └── Row
        ├── Icon (20px, textSecondary)
        ├── SizedBox(12)
        ├── Label (caption, textSecondary, width: 100px)
        └── Expanded → Value (body, textPrimary)
```

#### Dialogs
**Remove Photo Confirmation**:
```
AlertDialog
  ├── Title: "Remove Photo" (heading3)
  ├── Content: "Are you sure you want to remove your profile photo?" (body, textSecondary)
  └── Actions: "Cancel" TextButton + "Remove" ElevatedButton (errorRed)
```

---

### Super Admin Portal (6 Tabs)

**File**: `lib/screens/super_admin_portal_screen_new.dart` (4045 lines)  
**Role**: Super Admin only  
**Purpose**: Complete system management dashboard with 6 sections

#### Top-Level Layout
```
Scaffold (scaffoldBg)
  └── SafeArea → Column
        ├── Header
        │     └── Container (adminGradient bg, borderRadius bottom-left/right 24px, padding 20)
        │           ├── Row
        │           │     ├── Admin Icon
        │           │     │     └── Container (48px circle, white border 2px, gold ring accent)
        │           │     │           └── admin_panel_settings icon (24px, white)
        │           │     ├── SizedBox(12)
        │           │     ├── Column
        │           │     │     ├── "Super Admin" (18px, white, bold)
        │           │     │     └── Admin username (14px, white at 70%)
        │           │     ├── Spacer
        │           │     └── Logout Icon Button
        │           │           └── 40px circle, errorRed bg at 20%, logout icon (white)
        │
        ├── Tab Bar (padding 16 h, 8 v)
        │     └── SizedBox(height: 44) → ListView.builder (horizontal scroll)
        │           └── 6 Tab Pills (AnimatedContainer, 200ms):
        │                 ├── [0] dashboard icon + "Dashboard"
        │                 ├── [1] group_work icon + "Batches"
        │                 ├── [2] school icon + "Students"
        │                 ├── [3] person icon + "Teachers"
        │                 ├── [4] calendar_today icon + "Timetable"
        │                 └── [5] analytics icon + "Analytics"
        │
        └── Expanded → [Tab Content widget based on selected index]
```

#### Tab Pill Design
| State | Background | Icon/Text Color | Border |
|-------|-----------|-----------------|--------|
| Unselected | transparent | textSecondary | none |
| Selected | primaryBlue | white | none |
| Pill size | padding h 16, v 10 | icon 18px, text 13px bold | radiusXL |

---

### 9a. Super Admin — Dashboard Tab

#### Layout
```
FutureBuilder → SingleChildScrollView → Column (padding 16)
  ├── "System Overview" (heading2, textPrimary)
  ├── SizedBox(16)
  ├── 2×2 Grid (GridView.count, crossAxisCount 2, gap 12)
  │     ├── Stat Card: Batches (adminSecondary, group_work icon)
  │     ├── Stat Card: Students (adminGold/primaryBlue, school icon)
  │     ├── Stat Card: Teachers (errorRed, person icon)
  │     └── Stat Card: Classes (successGreen, class_ icon)
  │
  ├── SizedBox(24)
  ├── "Quick Actions" (heading3, textPrimary)
  ├── SizedBox(12)
  └── Column of 5 Quick Action Cards:
        ├── "Manage Batches" (group_work icon, adminSecondary) → Tab 1
        ├── "Manage Students" (school icon, primaryBlue) → Tab 2
        ├── "Manage Teachers" (person icon, errorRed) → Tab 3
        ├── "Manage Timetable" (calendar icon, successGreen) → Tab 4
        └── "View Analytics" (analytics icon, warningAmber) → Tab 5
```

#### Stat Card Design
```
Container (cleanCard, padding 16)
  ├── Row
  │     ├── Icon Container (40px circle, statColor bg at 10%)
  │     │     └── icon (20px, statColor)
  │     └── Spacer
  ├── SizedBox(12)
  ├── Count (32px, bold, textPrimary)
  ├── SizedBox(4)
  ├── Label (caption, textSecondary)
  └── Bottom Accent Bar
        └── Container (height 4px, full width, statColor, radiusS corners, margin top 8)
```

#### Quick Action Card Design
```
Container (cleanCard, margin bottom 8)
  └── InkWell → Padding(16)
        └── Row
              ├── Icon Container (40px rounded square radiusM, actionColor bg at 10%)
              │     └── icon (20px, actionColor)
              ├── SizedBox(12)
              ├── Column (crossAxis: start)
              │     ├── Title (body, bold, textPrimary)
              │     └── Subtitle (caption, textSecondary)
              ├── Spacer
              └── chevron_right icon (20px, textHint)
```

#### Loading / Error States
| State | Visual |
|-------|--------|
| Loading | Center CircularProgressIndicator (primaryBlue) |
| Error | Center error text (errorRed) |

---

### 9b. Super Admin — Batches Tab

#### Layout
```
Column
  ├── Header Row (padding 16)
  │     ├── "Manage Batches" (heading2, textPrimary)
  │     ├── Spacer
  │     └── "Add Batch" ElevatedButton.icon
  │           └── primaryBlue bg, white text, add icon, radiusM
  │
  └── Expanded → FutureBuilder → ListView.builder (padding 16 horizontal)
        ├── [Has batches]:
        │     └── Batch Cards (cleanCard, margin bottom 8)
        │           └── ListTile
        │                 ├── Leading: group_work icon in circle (primaryBlue bg at 10%)
        │                 ├── Title: batch name (body, bold, textPrimary)
        │                 ├── Subtitle: session (caption, textSecondary)
        │                 └── Trailing: Row
        │                       ├── edit icon button (primaryBlue)
        │                       └── delete icon button (errorRed)
        │
        └── [Empty]:
              └── Center → Column
                    ├── group_work icon (64px, textHint)
                    ├── "No batches found" (subtitle, textSecondary)
                    └── "Add Your First Batch" TextButton (primaryBlue)
```

#### Dialogs

**Add Batch Dialog**:
```
AlertDialog (shape: radiusL)
  ├── Title Row: add_circle icon (primaryBlue) + "Add Batch" (heading3)
  ├── Content:
  │     ├── "Batch Name" TextField
  │     │     └── (cleanCard bg, hintText: "e.g. 60_A", group_work prefix icon)
  │     ├── SizedBox(12)
  │     └── "Session" TextField
  │           └── (cleanCard bg, hintText: "e.g. 2024-2025", date_range prefix icon)
  └── Actions:
        ├── "Cancel" TextButton (textSecondary)
        └── "Add" ElevatedButton (primaryBlue bg, white text)
```

**Edit Batch Dialog**: Same as Add, pre-filled fields, "Update" button

**Delete Batch Dialog**:
```
AlertDialog
  ├── Title Row: warning icon (errorRed) + "Delete Batch" (heading3)
  ├── Content: "Are you sure you want to delete [batch name]?" (body, textSecondary)
  └── Actions:
        ├── "Cancel" TextButton (textSecondary)
        └── "Delete" ElevatedButton (errorRed bg, white text)
```

---

### 9c. Super Admin — Students Tab

#### Layout
```
Column
  ├── Header Row (padding 16)
  │     ├── "Manage Students" (heading2, textPrimary)
  │     ├── Spacer
  │     └── "Add Student" ElevatedButton.icon (primaryBlue)
  │
  ├── Batch Filter Dropdown (padding 16 horizontal)
  │     └── DropdownButtonFormField (cleanCard bg)
  │           ├── label: "Filter by Batch"
  │           └── Items: "All Batches" + individual batch names
  │
  └── Expanded → FutureBuilder → ListView.builder
        └── Student Cards (cleanCard, margin bottom 8, padding 16 horizontal)
              └── ListTile
                    ├── Leading: school icon in circle (primaryBlue bg at 10%)
                    ├── Title: student name (body, bold, textPrimary)
                    ├── Subtitle: "ID: [studentId]" (caption, textSecondary)
                    └── Trailing: Row
                          ├── key icon button (warningAmber) → Manage Credentials
                          ├── edit icon button (primaryBlue)
                          └── delete icon button (errorRed)
```

#### Dialogs

**Add Student Dialog**:
```
AlertDialog
  ├── Title: person_add icon + "Add Student"
  ├── Content:
  │     ├── "Student ID" TextField (badge prefix icon)
  │     ├── SizedBox(12)
  │     ├── "Name" TextField (person prefix icon)
  │     ├── SizedBox(12)
  │     └── "Batch" DropdownButtonFormField (FutureBuilder loads batches)
  └── Actions: "Cancel" + "Add"
```

**Edit Student Dialog**: Student ID shown as read-only text field, Name editable, Batch dropdown

**Delete Student Dialog**: Confirmation with student name

**Manage Credentials Dialog**:
```
AlertDialog
  ├── Title: key icon (warningAmber) + "Manage Credentials" (heading3)
  ├── Content:
  │     ├── [If hasChangedPassword = true]:
  │     │     └── Container (errorRed bg at 10%, radiusM, padding 16)
  │     │           └── Row: lock icon (errorRed) + Column
  │     │                 ├── "Credentials Locked" (body, bold, errorRed)
  │     │                 └── "This student has changed their password..." (caption, textSecondary)
  │     │
  │     └── [If hasChangedPassword = false]:
  │           ├── "Email" TextField (email prefix icon)
  │           ├── SizedBox(12)
  │           ├── "Initial Password" TextField
  │           │     ├── lock prefix icon
  │           │     └── suffixIcon: visibility toggle
  │           ├── SizedBox(12)
  │           └── Warning Banner
  │                 └── Container (warningAmber bg at 10%, radiusM, padding 12)
  │                       └── Row: warning icon (warningAmber) + warning text (caption, textSecondary)
  │                             └── "Once the student changes their password, these credentials will become non-retrievable"
  └── Actions: "Cancel" + "Set Credentials" (primaryBlue)
```

---

### 9d. Super Admin — Teachers Tab

#### Layout
```
Column
  ├── Header Row (padding 16)
  │     ├── "Manage Teachers" (heading2, textPrimary)
  │     ├── Spacer
  │     └── "Add Teacher" ElevatedButton.icon (primaryBlue)
  │
  ├── Search TextField (padding 16 horizontal)
  │     └── Container (cleanCard)
  │           └── TextField
  │                 ├── prefixIcon: search icon (textHint)
  │                 ├── hintText: "Search teachers..." (textHint)
  │                 └── Filters by: name, initial, email, designation
  │
  └── Expanded → FutureBuilder → ListView.builder
        └── Teacher Cards (cleanCard, margin bottom 12, padding 16)
              ├── Row (top section)
              │     ├── Circle Avatar (50px)
              │     │     ├── [Has profile pic]: NetworkImage in ClipOval
              │     │     └── [No pic]: teacherGradient bg + initial letter (20px, bold, white)
              │     ├── SizedBox(12)
              │     ├── Column
              │     │     ├── Name (body, bold, textPrimary)
              │     │     └── Designation (caption, textSecondary)
              │     ├── Spacer
              │     └── Action Buttons
              │           ├── edit icon button (primaryBlue, 20px)
              │           ├── key icon button (warningAmber, 20px)
              │           └── delete icon button (errorRed, 20px)
              │
              ├── Divider (dividerColor, vertical margin 12)
              └── Info Rows (3 rows, icon + value):
                    ├── email icon → email address (body, textPrimary)
                    ├── phone icon → phone number (body, textPrimary)
                    └── business icon → department (body, textPrimary)
```

#### Dialogs

**Add Teacher Dialog**:
```
AlertDialog (scrollable)
  ├── Title: person_add icon + "Add Teacher"
  ├── Content:
  │     ├── "Name" TextField (person icon)
  │     ├── "Initial" TextField (badge icon, hint: "e.g. NRC")
  │     ├── "Email" TextField (email icon)
  │     ├── "Phone" TextField (phone icon)
  │     ├── "Designation" TextField (work icon)
  │     └── "Home Department" TextField (business icon)
  │     (Each with SizedBox(12) gap)
  └── Actions: "Cancel" + "Add"
```

**Edit Teacher Dialog**: Initial read-only, profile pic preview (read-only note: "Profile picture is managed by the teacher"), all other fields editable

**Manage Credentials Dialog**: Same locked/unlocked pattern as Student credentials

---

### 9e. Super Admin — Timetable Tab

#### Layout
```
Column
  ├── Header Row (padding 16)
  │     ├── "Manage Timetable" (heading2, textPrimary)
  │     ├── Spacer
  │     └── 3 Action Buttons (Row, gap 8):
  │           ├── "Add Class" ElevatedButton.icon (primaryBlue bg, add icon)
  │           ├── "Export" ElevatedButton.icon (successGreen bg, picture_as_pdf icon)
  │           └── "Import" ElevatedButton.icon (warningAmber bg, file_upload icon)
  │
  ├── Day Selector (padding 16 horizontal, margin 8 vertical)
  │     └── SingleChildScrollView (horizontal) → Row
  │           └── 7 ChoiceChips: Sat, Sun, Mon, Tue, Wed, Thu, Fri
  │                 ├── Selected: primaryBlue bg, white text
  │                 └── Unselected: cardWhite bg, textPrimary text, dividerColor border
  │
  └── Expanded → FutureBuilder → ListView.builder (padding 16 horizontal)
        ├── [Has entries]:
        │     └── Timetable Entry Cards (cleanCard, margin bottom 8, padding 12)
        │           ├── Top Row
        │           │     ├── Time Badge
        │           │     │     └── Container (successGreen bg at 10%, radiusS, padding h8 v4)
        │           │     │           └── "HH:mm - HH:mm" (caption, bold, successGreen)
        │           │     ├── Spacer
        │           │     ├── edit icon button (primaryBlue, 18px)
        │           │     └── delete icon button (errorRed, 18px)
        │           │
        │           ├── SizedBox(8)
        │           ├── Course Title (body, bold, textPrimary) — FutureBuilder lookup
        │           ├── Course Code (caption, textSecondary)
        │           ├── SizedBox(8)
        │           └── Wrap of Detail Chips (spacing 6):
        │                 ├── Teacher chip: person icon (12px) + initial (caption)
        │                 │     └── Container (errorRed bg at 10%, errorRed text)
        │                 ├── Batch chip: group icon + batch name
        │                 │     └── Container (primaryBlue bg at 10%, primaryBlue text)
        │                 ├── Type chip: category icon + type name
        │                 │     └── Container (primaryBlue bg at 10%, primaryBlue text)
        │                 ├── Mode/Room chip:
        │                 │     ├── [Online]: wifi icon, successGreen bg at 10%, green text
        │                 │     └── [Onsite]: meeting_room icon, warningAmber bg at 10%, amber text, "Room [name]"
        │                 └── [If group]: Group chip: people icon + group name
        │                       └── Container (purple bg at 10%, purple text)
        │
        └── [Empty]:
              └── Center → Column
                    ├── calendar_today icon (64px, textHint)
                    ├── "No classes scheduled for [day]" (subtitle)
                    └── "Add a Class" TextButton (primaryBlue)
```

#### Detail Chip Design (reusable pattern)
```
Container (colored bg at 10%, radiusS, padding h 8 v 4)
  └── Row: icon (12px, colored) + SizedBox(4) + text (caption, bold, colored)
```

#### Add Class Dialog
```
AlertDialog (scrollable, shape: radiusL)
  ├── Title: "Add Class" (heading3)
  ├── Content (SingleChildScrollView):
  │     ├── Day DropdownButtonFormField (Sat-Fri)
  │     ├── Batch DropdownButtonFormField (FutureBuilder → loads all batches)
  │     ├── Teacher DropdownButtonFormField (FutureBuilder → loads teachers, shows "initial - name")
  │     ├── Course DropdownButtonFormField (FutureBuilder → loads courses, shows "code - title")
  │     ├── Type DropdownButtonFormField (Lecture / Tutorial / Sessional / Online)
  │     ├── Mode DropdownButtonFormField (Onsite / Online)
  │     ├── [If mode = Onsite]:
  │     │     └── Room DropdownButtonFormField (FutureBuilder → loads rooms)
  │     ├── Group DropdownButtonFormField (None / G-1 / G-2)
  │     ├── Row
  │     │     ├── Start Time: OutlinedButton.icon (clock icon)
  │     │     │     └── Shows "HH:mm" or "Select" | Taps → showTimePicker
  │     │     └── End Time: OutlinedButton.icon (clock icon)
  │     │           └── Shows "HH:mm" or "Select" | Taps → showTimePicker
  │     (Each field with SizedBox(12) gap)
  └── Actions: "Cancel" TextButton + "Add" ElevatedButton (primaryBlue)
```

#### Export Feature
- Generates multi-page **PDF** document
- Grouped by day (Saturday → Friday), each day as a section heading
- Table columns: Time, Course, Teacher, Batch, Type, Mode, Room
- Uses `pdf` + `printing` Flutter packages
- Opens system print/share dialog

#### Import Feature
- File picker opens for `.json` or `.csv` files
- **JSON format**:
  - Array: `[{day, batchId, teacherInitial, courseCode, type, mode, start, end, roomId}, ...]`
  - Object: `{"entries": [...]}`
- **CSV format** (header row skipped):
  - Columns: `day,batchId,teacherInitial,courseCode,type,mode,start,end,roomId`
- Confirmation dialog shows count of entries found before import

**Import Confirmation Dialog**:
```
AlertDialog
  ├── Title: "Import Timetable" (heading3)
  ├── Content:
  │     ├── "Found [N] entries to import." (body)
  │     └── "Note: This will add to existing data." (caption, textSecondary)
  └── Actions: "Cancel" + "Import" (primaryBlue)
```

---

### 9f. Super Admin — Analytics Tab

#### Layout
```
FutureBuilder → SingleChildScrollView → Column (padding 16)
  ├── "Analytics Dashboard" (heading2, textPrimary)
  │
  ├── SizedBox(16)
  ├── Key Metrics Row
  │     └── SingleChildScrollView (horizontal) → Row (gap 12)
  │           └── 4 Metric Cards (180px wide):
  │                 ├── "Total Classes" (primaryBlue, class_ icon, count)
  │                 ├── "Online Classes" (successGreen, wifi icon, count)
  │                 ├── "Onsite Classes" (warningAmber, business icon, count)
  │                 └── "Cancelled" (errorRed, cancel icon, count)
  │
  ├── SizedBox(24)
  ├── "Classes by Batch" Section
  │     └── Container (dividerColor border, radiusL, padding 16)
  │           ├── "Classes by Batch" (heading3, textPrimary)
  │           ├── SizedBox(12)
  │           └── DataTable
  │                 ├── Columns: "Batch" | "Count" | "%"
  │                 └── Rows: sorted by count descending
  │                       ├── Batch name (body, textPrimary)
  │                       ├── Count (body, bold, textPrimary)
  │                       └── Percentage (caption, textSecondary)
  │
  ├── SizedBox(24)
  ├── "Classes Distribution by Day" Section
  │     └── Container (dividerColor border, radiusL, padding 16)
  │           ├── "Classes Distribution by Day" (heading3)
  │           ├── SizedBox(16)
  │           └── Horizontal Bar Chart (custom Container-based)
  │                 └── Row (crossAxis: end, mainAxis: spaceEvenly)
  │                       └── 7 Day Columns:
  │                             ├── Count text (caption, bold, on top)
  │                             ├── Colored Bar (Container, width 36px, height proportional to count)
  │                             │     Colors: Sat=blue, Sun=green, Mon=orange,
  │                             │             Tue=purple, Wed=red, Thu=teal, Fri=pink
  │                             └── Day label below (caption, textSecondary)
  │
  ├── SizedBox(24)
  ├── "Classes by Type" Section
  │     └── Container (dividerColor border, radiusL, padding 16)
  │           ├── "Classes by Type" (heading3)
  │           ├── SizedBox(12)
  │           └── Column of 3 Type Cards:
  │                 ├── Lecture: purple bg (#7C3AED), book icon, count, %
  │                 ├── Tutorial: teal bg (#0D9488), edit icon, count, %
  │                 └── Sessional: indigo bg (#4F46E5), computer icon, count, %
  │                 Design per card:
  │                   └── Container (typeColor bg, radiusM, padding 16)
  │                         └── Row: icon (white) + name (white, bold) + Spacer + count (white, bold) + " (" + % + ")"
  │
  ├── SizedBox(24)
  └── "Classes by Mode" Section
        └── Container (dividerColor border, radiusL, padding 16)
              ├── "Classes by Mode" (heading3)
              ├── SizedBox(12)
              └── DataTable
                    ├── Columns: "Mode" | "Total" | "Active" | "Cancelled"
                    └── Rows (one per mode):
                          ├── Mode name (body, textPrimary)
                          ├── Total count (body, bold)
                          ├── Active: green chip (successGreen bg at 10%, green text)
                          └── Cancelled: red chip (errorRed bg at 10%, red text)
```

#### Metric Card Design
```
Container (180px width, cleanCard, padding 16)
  ├── Top Color Bar (height 4px, full width, metricColor, top radiusS)
  ├── SizedBox(12)
  ├── Title (label style, textSecondary)
  ├── SizedBox(8)
  ├── Icon (24px, metricColor)
  ├── SizedBox(8)
  └── Count (28px, bold, textPrimary)
```

---

### 10. Add/Edit Schedule Screen

**File**: `lib/screens/add_edit_schedule_screen.dart` (295 lines)  
**Role**: Admin (Super Admin or Teacher Admin)  
**Purpose**: Full-page form for creating or editing a single timetable entry

#### Layout
```
GradientShell (scaffoldBg bg, AppBar: "Add Schedule" or "Edit Schedule")
  └── SingleChildScrollView → Form → Column (padding 16)
        ├── "Day: [selected day]" (heading3, textPrimary)
        ├── SizedBox(16)
        ├── Batch DropdownButtonFormField* (required, group icon)
        ├── SizedBox(12)
        ├── Teacher DropdownButtonFormField* (required, person icon)
        ├── SizedBox(12)
        ├── Course DropdownButtonFormField* (required, book icon)
        ├── SizedBox(12)
        ├── Row
        │     ├── Type DropdownButtonFormField* (Expanded)
        │     ├── SizedBox(12)
        │     └── Group DropdownButtonFormField (Expanded, optional: None / G-1 / G-2)
        ├── SizedBox(12)
        ├── Mode DropdownButtonFormField* (Onsite / Online)
        ├── SizedBox(12)
        ├── [If mode = Onsite]:
        │     └── Room DropdownButtonFormField
        ├── SizedBox(16)
        ├── Row (Time Pickers)
        │     ├── Start Time: OutlinedButton.icon (clock icon, Expanded)
        │     │     └── Shows selected time "HH:mm" or "Start Time"
        │     │     └── Tap → showTimePicker (primaryBlue)
        │     ├── SizedBox(12)
        │     └── End Time: OutlinedButton.icon (clock icon, Expanded)
        │           └── Shows selected time "HH:mm" or "End Time"
        │           └── Tap → showTimePicker (primaryBlue)
        ├── SizedBox(24)
        └── Row (Action Buttons)
              ├── Cancel: OutlinedButton (Expanded, textSecondary border)
              └── Add/Save: FilledButton (Expanded, primaryBlue bg, white text)
```

#### Validation
- All fields marked with * are required
- Start and End time must be selected
- Room is required only when Mode = Onsite
- Shows SnackBar for validation errors

---

### Legacy Screens

These screens exist in the codebase but are **not part of the primary navigation flow**. They are from an earlier version of the app.

#### Landing Screen
**File**: `lib/screens/landing_screen.dart` (108 lines)  
**Purpose**: Role selection page with 3 large buttons  
**Layout**: GradientShell → BrandCard (department info) + 3 BigNavButtons in a Wrap (Student / Teacher / Login)

#### Admin Login Screen
**File**: `lib/screens/admin_login_screen.dart` (177 lines)  
**Purpose**: Standalone admin login with demo credential hints  
**Layout**: GradientShell → Card with username/password + demo credentials info box (blue bg)

#### Other Legacy Screens
- `lib/screens/student_portal_screen.dart` — Old student portal
- `lib/screens/teacher_portal_screen.dart` — Old teacher portal
- `lib/screens/super_admin_portal_screen.dart` — Old super admin portal

---

## Reusable Widgets

### ScheduleCard
**File**: `lib/widgets/schedule_card.dart` (118 lines)  
**Used in**: StudentScreen, TeacherScreen, RoomScreen

```
Container (cleanCard, border: accentBlue — or errorRed if cancelled)
  └── Padding(16) → Column
        ├── Row: Course Title (body, bold) + Spacer + Time Badge (primaryBlue bg at 10%)
        ├── SizedBox(8)
        ├── Teacher Row: person icon (16px, textSecondary) + teacher name (body, textPrimary)
        ├── SizedBox(4)
        ├── Room Row: meeting_room icon → room name | wifi icon → "Online"
        ├── SizedBox(8)
        ├── Bottom Row: batch name (caption, textSecondary) + Spacer + type chip
        │     └── Type chip: Container (primaryBlue bg at 10%, radiusS) → type text (caption, primaryBlue)
        └── [If cancelled]:
              ├── SizedBox(8)
              └── Cancel Badge: Container (errorRed bg at 10%, radiusS)
                    └── Row: cancel icon + "CANCELLED" (bold) + reason text (if available)
```

### ScheduleList
**File**: `lib/widgets/schedule_list.dart` (85 lines)  
**Purpose**: Titled list of entries as ListTiles (alternative to ScheduleCard)

| Element | Description |
|---------|-------------|
| Container | cleanCard decoration |
| Title | Optional section heading (heading3) |
| ListTile leading | CircleAvatar with start time text (errorRed bg if cancelled, primaryBlue otherwise) |
| ListTile title | "Course · Type (Group)" — line-through if cancelled |
| ListTile subtitle | "Mode/Room · Batch · Time" + cancellation reason |
| ListTile trailing | cancel icon (red) / wifi icon (green) / meeting_room icon (blue) |

### BrandCard
**File**: `lib/widgets/brand_card.dart` (41 lines)  
**Purpose**: Department branding banner (used on legacy landing screen)

| Element | Style |
|---------|-------|
| Background | studentGradient |
| Department | 20px, bold, white |
| University | 14px, white at 70% |
| Updated | 12px, white at 70%, date formatted via `intl` |

### GradientShell
**File**: `lib/widgets/gradient_shell.dart` (36 lines)  
**Purpose**: Scaffold wrapper with gradient or solid background

| Prop | Default | Description |
|------|---------|-------------|
| `child` | (required) | Body content |
| `title` | "SmartRoutine" | AppBar title |
| `useDarkBackground` | false | true = scaffoldBg solid, false = studentGradient |

### TeacherCard
**File**: `lib/widgets/teacher_card.dart` (51 lines)  
**Purpose**: Teacher info display card with 6 info tiles

| Element | Style |
|---------|-------|
| Container | cleanCard, teacherSecondary border |
| Content | Wrap of 6 info tiles (each 260px wide) |
| Info tile | Label (label style, textSecondary) + Value (body, textPrimary) |
| Fields | Name, Initial, Designation, Department, Phone, Email |

### BigNavButton
**File**: `lib/widgets/big_nav_button.dart` (55 lines)  
**Purpose**: Large navigation button (legacy landing screen)

| Property | Value |
|----------|-------|
| Size | 260 × 120px |
| Background | cardWhite |
| Border | accentBlue, 1px, with shadow |
| Content | Row: icon (28px, accentBlue) + label (17px, bold, textPrimary) |
| Corner radius | radiusL (16px) |

### CustomInputField
**File**: `lib/widgets/custom_input_field.dart` (42 lines)  
Container (inputFill bg, radiusM, dividerColor border) → TextField (Poppins, textPrimary, no border)

### CustomDropdown
**File**: `lib/widgets/custom_dropdown.dart` (51 lines)  
Container (inputFill bg, radiusM, dividerColor border) → DropdownButton\<T\> (Poppins, no underline)

### CustomSearchBar
**File**: `lib/widgets/custom_search_bar.dart` (40 lines)  
Container (inputFill bg, radiusM, dividerColor border) → TextField with search prefix icon + onSubmitted

### DepartmentDropdown
**File**: `lib/widgets/department_dropdown.dart` (47 lines)  
Hardcoded department picker: **EdTE**, **IRE**, **DSE**, **SWE**, **CySE**

---

## Data Models

### Admin
| Field | Type | Notes |
|-------|------|-------|
| `id` | int | Primary key |
| `username` | String | Login username |
| `password` | String | Hashed password |
| `type` | String | `super_admin` or `teacher_admin` |
| `teacherInitial` | String? | Links to Teacher (for teacher_admin role) |

### Teacher
| Field | Type | Notes |
|-------|------|-------|
| `id` | int | Primary key |
| `name` | String | Full name |
| `initial` | String | Unique identifier (e.g., "NRC") — used as foreign key in timetable |
| `designation` | String | e.g., "Lecturer", "Assistant Professor" |
| `phone` | String | Contact phone |
| `email` | String | Login email |
| `homeDepartment` | String | e.g., "EdTE", "IRE" |
| `profilePic` | String? | Supabase Storage URL |
| `password` | String? | Only available before first change |
| `hasChangedPassword` | bool | If true, credentials are locked and non-editable |

### Student
| Field | Type | Notes |
|-------|------|-------|
| `studentId` | String | Unique student ID (e.g., "2024-01-001") |
| `name` | String | Full name |
| `batchId` | int | Foreign key → Batch |
| `email` | String? | Login email |
| `hasChangedPassword` | bool | Locks credential management in admin panel |

### Batch
| Field | Type | Notes |
|-------|------|-------|
| `id` | int | Primary key |
| `name` | String | Batch identifier (e.g., "60_A", "60_C") |
| `session` | String | Academic session (e.g., "2024-2025") |

### Course
| Field | Type | Notes |
|-------|------|-------|
| `code` | String | Unique course code (primary key) |
| `title` | String | Course full title |

### Room
| Field | Type | Notes |
|-------|------|-------|
| `id` | int | Primary key |
| `name` | String | Room number/name |

### TimetableEntry
| Field | Type | Notes |
|-------|------|-------|
| `day` | String | Day abbreviation: Sat/Sun/Mon/Tue/Wed/Thu/Fri |
| `batchId` | int | Foreign key → Batch |
| `teacherInitial` | String | Foreign key → Teacher (by initial) |
| `courseCode` | String | Foreign key → Course (by code) |
| `type` | String | Lecture / Tutorial / Sessional / Online |
| `group` | String? | G-1 / G-2 / null |
| `roomId` | int? | Foreign key → Room (null if online) |
| `mode` | String | Onsite / Online |
| `start` | String | Start time in "HH:mm" format |
| `end` | String | End time in "HH:mm" format |
| `isCancelled` | bool | Whether the class is currently cancelled |
| `cancellationReason` | String? | Reason text (set when cancelling) |

### AppMeta
| Field | Type | Notes |
|-------|------|-------|
| `version` | String | App/data version |
| `updatedAt` | DateTime | Last data update timestamp |
| `tz` | String | Timezone identifier |
| `daysOff` | List\<String\> | Non-class days |
| `department` | String | Department display name |
| `university` | String | University display name |
| `slotLabels` | Map | Time slot label mappings |

---

## Time Slots Reference

| Slot | Period | Category |
|------|--------|----------|
| 1 | 08:30 – 10:00 | Morning |
| 2 | 10:00 – 11:30 | Morning |
| 3 | 11:30 – 01:00 | Morning |
| 4 | 01:00 – 02:30 | Afternoon |
| 5 | 02:30 – 04:00 | Afternoon |

## Academic Week

Saturday → Friday (6 working days + Friday off)

Days: `Sat`, `Sun`, `Mon`, `Tue`, `Wed`, `Thu`, `Fri`
