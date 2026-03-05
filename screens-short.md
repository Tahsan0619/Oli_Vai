# EDTE Routine — Screen Reference (Short)

**Stack**: Flutter | Supabase | Provider | Poppins font
**Primary Color**: `#4366F6` | BG: `#F5F6FA` | Cards: `#FFFFFF`

## Roles & Auth
- **Student**: Email+Pass → schedule, rooms, profile
- **Teacher/Admin**: Email+Pass → own schedule, cancel/reschedule, profile+photo
- **Super Admin**: Username+Pass → full CRUD, analytics, PDF export, JSON/CSV import

Auth flow: tries Admin → Teacher → Student sequentially.

## Navigation

```
AuthCheck → saved session? → role portal
           → no session  → UnifiedLoginScreen
```

**Student**: 5-tab bottom nav (Schedule | Teacher | Room | Free Rooms | Profile)
**Teacher**: Header + weekly day-selector schedule
**Super Admin**: 6 horizontal tab pills (Dashboard | Batches | Students | Teachers | Timetable | Analytics)

## Screens

### 1. Login (`unified_login_screen_new.dart`)
Centered card (max 420px): logo, username, password (with toggle), sign-in button. Error banner on failure.

### 2. Student Schedule (`student_screen.dart`)
Search by batch name → today's classes as ScheduleCards. Shows course, time, teacher, room, type, cancelled status.

### 3. Teacher Lookup (`teacher_screen.dart`)
Search by teacher initial → teacher profile card (avatar, name, designation, phone, email) + today's schedule.

### 4. Room Search (`room_screen.dart`)
Input room number + select day + time slot → "Room is free" (green) or occupied classes list.

### 5. Free Rooms (`free_rooms_screen.dart`)
Morning/Afternoon time slot cards → select to see available room chips (green) or "No free rooms" (red).

### 6. Student Profile (`student_profile_screen.dart`)
Gradient header (avatar, name, email, ID). Security card with expandable password change. Logout button (red).

### 7. Teacher Portal (`teacher_admin_portal_screen_new.dart`)
Gradient header (name, profile/logout buttons). Day pills → class cards with actions: Reschedule, Change Room, Cancel. Cancelled classes show restore button. Dialogs for each action.

### 8. Teacher Profile (`teacher_profile_screen.dart`)
Avatar with photo upload/remove. Info card (name, initial, email, phone, designation, dept) — view/edit toggle. Security section for password change.

### 9. Super Admin Portal (`super_admin_portal_screen_new.dart`)

**Dashboard**: 2×2 stat grid (Batches, Students, Teachers, Classes) + 5 quick-action cards.
**Batches**: List with add/edit/delete. Dialog forms for name + session.
**Students**: Batch filter dropdown + list. Add/edit/delete + manage credentials (locked if password changed).
**Teachers**: Search bar + cards (avatar, info rows). Add/edit/delete + manage credentials.
**Timetable**: Day selector + entry cards with detail chips. Add Class dialog (day, batch, teacher, course, type, mode, room, group, times). Export PDF, Import JSON/CSV.
**Analytics**: Metric cards (Total/Online/Onsite/Cancelled). Tables: classes by batch, bar chart by day, cards by type (Lecture/Tutorial/Sessional), table by mode.

### 10. Add/Edit Schedule (`add_edit_schedule_screen.dart`)
Full-page form: day, batch, teacher, course, type, group, mode, room (if onsite), start/end time pickers.

## Data Models
**Admin**: id, username, password, type, teacherInitial? | **Teacher**: id, name, initial, designation, phone, email, dept, profilePic?, hasChangedPassword | **Student**: studentId, name, batchId, email?, hasChangedPassword | **Batch**: id, name, session | **Course**: code, title | **Room**: id, name | **TimetableEntry**: day, batchId, teacherInitial, courseCode, type, group?, roomId?, mode, start, end, isCancelled, cancellationReason?

## Time Slots
| # | Period | Category |
|---|--------|----------|
| 1 | 08:30–10:00 | Morning |
| 2 | 10:00–11:30 | Morning |
| 3 | 11:30–01:00 | Morning |
| 4 | 01:00–02:30 | Afternoon |
| 5 | 02:30–04:00 | Afternoon |

Week: Sat–Thu (Fri off)
