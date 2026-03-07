"""Generate comprehensive Supabase SQL with real data, new tables, and inserts."""
import json

# Load parsed data.json
with open('assets/data.json', 'r') as f:
    data = json.load(f)

teachers = data['teachers']
batches = data['batches']
courses = data['courses']
rooms = data['rooms']
timetable = data['timetable']
admins = data['admins']

sql_parts = []

# ========================================
# HEADER
# ========================================
sql_parts.append("""-- =====================================================
-- EDTE Routine Scrapper - Complete Supabase Schema v2.0
-- =====================================================
-- Includes: All tables, new AI routine tables, real faculty data,
-- real courses from output.json, timetable entries, RLS, triggers,
-- realtime subscriptions, views, and functions.
-- =====================================================
-- IMPORTANT: Run this AFTER dropping existing tables or on a fresh DB.
-- If upgrading, see the migration section at the bottom.
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- STORAGE BUCKET FOR TEACHER PROFILE PICTURES
-- =====================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('teacher-profiles', 'teacher-profiles', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Teachers can upload profile pictures"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'teacher-profiles');

CREATE POLICY "Anyone can view profile pictures"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'teacher-profiles');

CREATE POLICY "Teachers can update profile pictures"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'teacher-profiles');

CREATE POLICY "Teachers can delete profile pictures"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'teacher-profiles');

-- =====================================================
-- 1. ADMINS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('super_admin', 'teacher_admin')),
    teacher_initial TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admins_username ON admins(username);
CREATE INDEX IF NOT EXISTS idx_admins_type ON admins(type);

-- =====================================================
-- 2. TEACHERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    initial TEXT UNIQUE NOT NULL,
    designation TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    home_department TEXT NOT NULL,
    profile_pic TEXT,
    password TEXT,
    has_changed_password BOOLEAN DEFAULT FALSE,
    notifications_enabled BOOLEAN DEFAULT FALSE,
    email_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_teachers_initial ON teachers(initial);
CREATE INDEX IF NOT EXISTS idx_teachers_department ON teachers(home_department);

-- =====================================================
-- 3. BATCHES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    session TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(name, session)
);

CREATE INDEX IF NOT EXISTS idx_batches_session ON batches(session);

-- =====================================================
-- 4. COURSES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_courses_code ON courses(code);

-- =====================================================
-- 5. ROOMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_rooms_name ON rooms(name);

-- =====================================================
-- 6. STUDENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    email TEXT,
    phone TEXT,
    password TEXT,
    has_changed_password BOOLEAN DEFAULT FALSE,
    notifications_enabled BOOLEAN DEFAULT FALSE,
    email_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_students_batch ON students(batch_id);
CREATE INDEX IF NOT EXISTS idx_students_student_id ON students(student_id);

-- =====================================================
-- 7. TIMETABLE ENTRIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS timetable_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    day TEXT NOT NULL CHECK (day IN ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat')),
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    teacher_initial TEXT NOT NULL REFERENCES teachers(initial) ON DELETE CASCADE,
    course_code TEXT NOT NULL REFERENCES courses(code) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('Lecture', 'Tutorial', 'Sessional', 'Online')),
    group_name TEXT,
    room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
    mode TEXT NOT NULL CHECK (mode IN ('Onsite', 'Online', 'Offline')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_timetable_day ON timetable_entries(day);
CREATE INDEX IF NOT EXISTS idx_timetable_batch ON timetable_entries(batch_id);
CREATE INDEX IF NOT EXISTS idx_timetable_teacher ON timetable_entries(teacher_initial);
CREATE INDEX IF NOT EXISTS idx_timetable_course ON timetable_entries(course_code);
CREATE INDEX IF NOT EXISTS idx_timetable_room ON timetable_entries(room_id);

-- =====================================================
-- 8. APP METADATA TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS app_metadata (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version TEXT NOT NULL,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    institution_name TEXT,
    academic_year TEXT
);

-- =====================================================
-- 9. APPOINTMENTS TABLE (Student <-> Teacher)
-- =====================================================
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_initial TEXT NOT NULL REFERENCES teachers(initial) ON DELETE CASCADE,
    student_id TEXT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    student_name TEXT NOT NULL,
    date DATE NOT NULL,
    time TIME NOT NULL,
    purpose TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    teacher_remarks TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_appointments_teacher ON appointments(teacher_initial);
CREATE INDEX IF NOT EXISTS idx_appointments_student ON appointments(student_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(date);

-- =====================================================
-- 10. NOTIFICATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL CHECK (type IN (
        'class_cancelled', 'class_rescheduled', 'room_changed',
        'class_restored', 'daily_reminder', 'appointment',
        'general', 'class_assigned', 'class_updated', 'class_removed',
        'teacher_added', 'course_added', 'preference_approved',
        'preference_rejected', 'routine_generated'
    )),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    recipient_type TEXT NOT NULL CHECK (recipient_type IN ('super_admin', 'student', 'teacher')),
    recipient_id TEXT NOT NULL,
    related_entry_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient ON notifications(recipient_type, recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- =====================================================
-- 11. TEACHER COURSE PREFERENCES TABLE (NEW)
-- =====================================================
-- Teachers submit their course/batch preferences here.
-- Super admin reviews and approves/rejects before AI generation.
CREATE TABLE IF NOT EXISTS teacher_course_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_initial TEXT NOT NULL REFERENCES teachers(initial) ON DELETE CASCADE,
    course_code TEXT NOT NULL REFERENCES courses(code) ON DELETE CASCADE,
    batch_id UUID NOT NULL REFERENCES batches(id) ON DELETE CASCADE,
    class_type TEXT NOT NULL CHECK (class_type IN ('Lecture', 'Tutorial', 'Sessional')),
    sessions_per_week INT NOT NULL DEFAULT 1 CHECK (sessions_per_week BETWEEN 1 AND 5),
    preferred_day TEXT CHECK (preferred_day IN ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Sat')),
    preferred_time_slot TEXT,
    preferred_room_id UUID REFERENCES rooms(id) ON DELETE SET NULL,
    group_name TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_preferences_teacher ON teacher_course_preferences(teacher_initial);
CREATE INDEX IF NOT EXISTS idx_preferences_course ON teacher_course_preferences(course_code);
CREATE INDEX IF NOT EXISTS idx_preferences_batch ON teacher_course_preferences(batch_id);
CREATE INDEX IF NOT EXISTS idx_preferences_status ON teacher_course_preferences(status);

-- =====================================================
-- 12. ROUTINE GENERATIONS TABLE (NEW)
-- =====================================================
-- Tracks AI-generated routine history.
CREATE TABLE IF NOT EXISTS routine_generations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    generated_by TEXT NOT NULL,
    routine_title TEXT NOT NULL,
    entry_count INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'applied' CHECK (status IN ('applied', 'draft', 'reverted')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_routine_gen_by ON routine_generations(generated_by);
CREATE INDEX IF NOT EXISTS idx_routine_gen_status ON routine_generations(status);
""")

# ========================================
# TRIGGERS
# ========================================
sql_parts.append("""
-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_admins_updated_at') THEN
        CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_teachers_updated_at') THEN
        CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_batches_updated_at') THEN
        CREATE TRIGGER update_batches_updated_at BEFORE UPDATE ON batches FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_courses_updated_at') THEN
        CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_rooms_updated_at') THEN
        CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_students_updated_at') THEN
        CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_timetable_entries_updated_at') THEN
        CREATE TRIGGER update_timetable_entries_updated_at BEFORE UPDATE ON timetable_entries FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_appointments_updated_at') THEN
        CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_notifications_updated_at') THEN
        CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_preferences_updated_at') THEN
        CREATE TRIGGER update_preferences_updated_at BEFORE UPDATE ON teacher_course_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_routine_gen_updated_at') THEN
        CREATE TRIGGER update_routine_gen_updated_at BEFORE UPDATE ON routine_generations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;
""")

# ========================================
# RLS
# ========================================
sql_parts.append("""
-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_course_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE routine_generations ENABLE ROW LEVEL SECURITY;

-- Allow all (anon key) — customize for production
DO $$ BEGIN
    -- Drop existing policies first to avoid conflicts
    DROP POLICY IF EXISTS "Allow all on admins" ON admins;
    DROP POLICY IF EXISTS "Allow all on teachers" ON teachers;
    DROP POLICY IF EXISTS "Allow all on batches" ON batches;
    DROP POLICY IF EXISTS "Allow all on courses" ON courses;
    DROP POLICY IF EXISTS "Allow all on rooms" ON rooms;
    DROP POLICY IF EXISTS "Allow all on students" ON students;
    DROP POLICY IF EXISTS "Allow all on timetable_entries" ON timetable_entries;
    DROP POLICY IF EXISTS "Allow all on app_metadata" ON app_metadata;
    DROP POLICY IF EXISTS "Allow all on appointments" ON appointments;
    DROP POLICY IF EXISTS "Allow all on notifications" ON notifications;
    DROP POLICY IF EXISTS "Allow all on teacher_course_preferences" ON teacher_course_preferences;
    DROP POLICY IF EXISTS "Allow all on routine_generations" ON routine_generations;
END $$;

CREATE POLICY "Allow all on admins" ON admins FOR ALL USING (true);
CREATE POLICY "Allow all on teachers" ON teachers FOR ALL USING (true);
CREATE POLICY "Allow all on batches" ON batches FOR ALL USING (true);
CREATE POLICY "Allow all on courses" ON courses FOR ALL USING (true);
CREATE POLICY "Allow all on rooms" ON rooms FOR ALL USING (true);
CREATE POLICY "Allow all on students" ON students FOR ALL USING (true);
CREATE POLICY "Allow all on timetable_entries" ON timetable_entries FOR ALL USING (true);
CREATE POLICY "Allow all on app_metadata" ON app_metadata FOR ALL USING (true);
CREATE POLICY "Allow all on appointments" ON appointments FOR ALL USING (true);
CREATE POLICY "Allow all on notifications" ON notifications FOR ALL USING (true);
CREATE POLICY "Allow all on teacher_course_preferences" ON teacher_course_preferences FOR ALL USING (true);
CREATE POLICY "Allow all on routine_generations" ON routine_generations FOR ALL USING (true);
""")

# ========================================
# REALTIME
# ========================================
sql_parts.append("""
-- =====================================================
-- REALTIME SUBSCRIPTIONS
-- =====================================================
ALTER PUBLICATION supabase_realtime ADD TABLE teachers;
ALTER PUBLICATION supabase_realtime ADD TABLE students;
ALTER PUBLICATION supabase_realtime ADD TABLE courses;
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE batches;
ALTER PUBLICATION supabase_realtime ADD TABLE timetable_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;
ALTER PUBLICATION supabase_realtime ADD TABLE teacher_course_preferences;
ALTER PUBLICATION supabase_realtime ADD TABLE routine_generations;
""")

# ========================================
# DATA INSERTS
# ========================================

# Teachers
teacher_values = []
for t in teachers:
    name = t['name'].replace("'", "''")
    email = t['email'].replace("'", "''")
    phone = t['phone'].replace("'", "''")
    pp = t.get('profile_pic', '').replace("'", "''") if t.get('profile_pic') else None
    pp_sql = f"'{pp}'" if pp else "NULL"
    teacher_values.append(
        f"('{name}', '{t['initial']}', '{t['designation']}', '{phone}', '{email}', "
        f"'Educational Technology and Engineering', {pp_sql})"
    )

sql_parts.append(f"""
-- =====================================================
-- INSERT REAL DATA: TEACHERS ({len(teachers)} faculty members)
-- =====================================================
INSERT INTO teachers (name, initial, designation, phone, email, home_department, profile_pic) VALUES
{',\n'.join(teacher_values)}
ON CONFLICT (initial) DO UPDATE SET
    name = EXCLUDED.name,
    designation = EXCLUDED.designation,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    home_department = EXCLUDED.home_department,
    profile_pic = EXCLUDED.profile_pic;
""")

# Batches
batch_values = []
for b in batches:
    batch_values.append(f"('{b['name']}', '{b['session']}')")

sql_parts.append(f"""
-- =====================================================
-- INSERT REAL DATA: BATCHES ({len(batches)} batches)
-- =====================================================
INSERT INTO batches (name, session) VALUES
{',\n'.join(batch_values)}
ON CONFLICT (name, session) DO NOTHING;
""")

# Courses
course_values = []
for c in courses:
    title = c['title'].replace("'", "''")
    course_values.append(f"('{c['code']}', '{title}')")

sql_parts.append(f"""
-- =====================================================
-- INSERT REAL DATA: COURSES ({len(courses)} courses)
-- =====================================================
INSERT INTO courses (code, title) VALUES
{',\n'.join(course_values)}
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title;
""")

# Rooms
room_values = []
for r in rooms:
    room_values.append(f"('{r['name']}')")

sql_parts.append(f"""
-- =====================================================
-- INSERT REAL DATA: ROOMS ({len(rooms)} rooms)
-- =====================================================
INSERT INTO rooms (name) VALUES
{',\n'.join(room_values)}
ON CONFLICT (name) DO NOTHING;
""")

# Admins
admin_values = []
for a in admins:
    ti = f"'{a['teacher_initial']}'" if a['teacher_initial'] else "NULL"
    admin_values.append(f"('{a['username']}', '{a['password']}', '{a['type']}', {ti})")

sql_parts.append(f"""
-- =====================================================
-- INSERT REAL DATA: ADMINS ({len(admins)} accounts)
-- =====================================================
-- Super admin + teacher admin accounts
INSERT INTO admins (username, password_hash, type, teacher_initial) VALUES
{',\n'.join(admin_values)}
ON CONFLICT (username) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    type = EXCLUDED.type,
    teacher_initial = EXCLUDED.teacher_initial;
""")

# App metadata
sql_parts.append("""
-- =====================================================
-- INSERT APP METADATA
-- =====================================================
INSERT INTO app_metadata (version, institution_name, academic_year)
VALUES ('2.0.0', 'University of Frontier Technology, Bangladesh', '2025-2026')
ON CONFLICT DO NOTHING;
""")

# Timetable entries via DO block (need batch/room UUIDs)
# We need to look up batch_id and room_id since they're UUIDs
batch_map = {b['id']: b['name'] for b in batches}  # '3rd' -> '3rd Batch'
room_name_map = {}
for r in rooms:
    room_name_map[r['id']] = r['name']  # '1001' -> '1001', '2701' -> '2701 (LAB)'

# Build timetable insert
timetable_inserts = []
for entry in timetable:
    day = entry['day']
    batch_id = entry['batch_id']
    teacher = entry['teacher_initial']
    course = entry['course_code']
    etype = entry['type']
    group = entry.get('group')
    room = entry.get('room_id', '')
    mode = entry.get('mode', 'Offline')
    start = entry['start']
    end = entry['end']
    
    # Find batch name
    batch_name = None
    for b in batches:
        if b['id'] == batch_id:
            batch_name = b['name']
            break
    if not batch_name:
        continue
    
    # Find room name
    room_name = room_name_map.get(room, room)
    
    # Build the room lookup
    group_sql = f"'{group}'" if group else "NULL"
    
    timetable_inserts.append(
        f"    ('{day}', "
        f"(SELECT id FROM batches WHERE name = '{batch_name}' LIMIT 1), "
        f"'{teacher}', '{course}', '{etype}', {group_sql}, "
        f"(SELECT id FROM rooms WHERE name = '{room_name}' LIMIT 1), "
        f"'{mode}', '{start}', '{end}', FALSE)"
    )

sql_parts.append(f"""
-- =====================================================
-- INSERT REAL DATA: TIMETABLE ENTRIES ({len(timetable_inserts)} entries)
-- Ramadhan Routine 2026 from output.json
-- =====================================================
INSERT INTO timetable_entries (day, batch_id, teacher_initial, course_code, type, group_name, room_id, mode, start_time, end_time, is_cancelled) VALUES
{',\n'.join(timetable_inserts)};
""")

# ========================================
# VIEWS
# ========================================
sql_parts.append("""
-- =====================================================
-- VIEWS
-- =====================================================
CREATE OR REPLACE VIEW v_timetable_complete AS
SELECT 
    te.id, te.day, te.start_time, te.end_time, te.type, te.group_name, te.mode,
    te.is_cancelled, te.cancellation_reason,
    b.id as batch_id, b.name as batch_name, b.session as batch_session,
    t.initial as teacher_initial, t.name as teacher_name, t.designation as teacher_designation,
    c.code as course_code, c.title as course_title,
    r.id as room_id, r.name as room_name,
    te.created_at, te.updated_at
FROM timetable_entries te
JOIN batches b ON te.batch_id = b.id
JOIN teachers t ON te.teacher_initial = t.initial
JOIN courses c ON te.course_code = c.code
LEFT JOIN rooms r ON te.room_id = r.id;

CREATE OR REPLACE VIEW v_students_with_batch AS
SELECT 
    s.id, s.student_id, s.name, s.email, s.phone,
    b.id as batch_id, b.name as batch_name, b.session as batch_session,
    s.created_at, s.updated_at
FROM students s
JOIN batches b ON s.batch_id = b.id;

CREATE OR REPLACE VIEW v_preferences_complete AS
SELECT
    tcp.id, tcp.teacher_initial, t.name as teacher_name,
    tcp.course_code, c.title as course_title,
    tcp.batch_id, b.name as batch_name,
    tcp.class_type, tcp.sessions_per_week,
    tcp.preferred_day, tcp.preferred_time_slot,
    tcp.preferred_room_id, r.name as preferred_room_name,
    tcp.group_name, tcp.status,
    tcp.created_at, tcp.updated_at
FROM teacher_course_preferences tcp
JOIN teachers t ON tcp.teacher_initial = t.initial
JOIN courses c ON tcp.course_code = c.code
JOIN batches b ON tcp.batch_id = b.id
LEFT JOIN rooms r ON tcp.preferred_room_id = r.id;

CREATE OR REPLACE VIEW v_batch_student_emails AS
SELECT
    s.student_id, s.name, s.email, s.batch_id, b.name as batch_name,
    s.notifications_enabled, s.email_enabled
FROM students s
JOIN batches b ON s.batch_id = b.id
WHERE s.email IS NOT NULL AND s.email != '' AND s.email_enabled = TRUE;

CREATE OR REPLACE VIEW v_admin_emails AS
SELECT username as email, type FROM admins;
""")

# ========================================
# FUNCTIONS
# ========================================
sql_parts.append("""
-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Get teacher schedule for a day
CREATE OR REPLACE FUNCTION get_teacher_schedule(
    teacher_initial_param TEXT, day_param TEXT
) RETURNS TABLE (
    id UUID, start_time TIME, end_time TIME,
    course_code TEXT, course_title TEXT, batch_name TEXT,
    room_name TEXT, type TEXT, mode TEXT, is_cancelled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT te.id, te.start_time, te.end_time, c.code, c.title, b.name, r.name,
           te.type, te.mode, te.is_cancelled
    FROM timetable_entries te
    JOIN courses c ON te.course_code = c.code
    JOIN batches b ON te.batch_id = b.id
    LEFT JOIN rooms r ON te.room_id = r.id
    WHERE te.teacher_initial = teacher_initial_param AND te.day = day_param
    ORDER BY te.start_time;
END;
$$ LANGUAGE plpgsql;

-- Get batch schedule for a day
CREATE OR REPLACE FUNCTION get_batch_schedule(
    batch_id_param UUID, day_param TEXT
) RETURNS TABLE (
    id UUID, start_time TIME, end_time TIME,
    course_code TEXT, course_title TEXT, teacher_name TEXT,
    teacher_initial TEXT, room_name TEXT, type TEXT, mode TEXT, is_cancelled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT te.id, te.start_time, te.end_time, c.code, c.title, t.name, t.initial,
           r.name, te.type, te.mode, te.is_cancelled
    FROM timetable_entries te
    JOIN courses c ON te.course_code = c.code
    JOIN teachers t ON te.teacher_initial = t.initial
    LEFT JOIN rooms r ON te.room_id = r.id
    WHERE te.batch_id = batch_id_param AND te.day = day_param
    ORDER BY te.start_time;
END;
$$ LANGUAGE plpgsql;

-- Find free rooms at a specific time
CREATE OR REPLACE FUNCTION get_free_rooms(day_param TEXT, time_param TIME)
RETURNS TABLE (room_id UUID, room_name TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.name FROM rooms r
    WHERE r.id NOT IN (
        SELECT te.room_id FROM timetable_entries te
        WHERE te.day = day_param AND te.room_id IS NOT NULL
          AND te.is_cancelled = FALSE
          AND time_param >= te.start_time AND time_param < te.end_time
    )
    ORDER BY r.name;
END;
$$ LANGUAGE plpgsql;

-- Daily reminders function
CREATE OR REPLACE FUNCTION create_daily_reminders()
RETURNS void AS $$
DECLARE
    tomorrow_day TEXT;
    student_rec RECORD;
    entry_count INT;
    reminder_body TEXT;
BEGIN
    SELECT CASE EXTRACT(DOW FROM (CURRENT_DATE + INTERVAL '1 day'))
        WHEN 0 THEN 'Sun' WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue'
        WHEN 3 THEN 'Wed' WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri'
        WHEN 6 THEN 'Sat'
    END INTO tomorrow_day;

    FOR student_rec IN
        SELECT s.student_id, s.name, s.batch_id
        FROM students s WHERE s.notifications_enabled = TRUE
    LOOP
        SELECT COUNT(*) INTO entry_count
        FROM timetable_entries te
        WHERE te.batch_id = student_rec.batch_id AND te.day = tomorrow_day AND te.is_cancelled = FALSE;

        IF entry_count > 0 THEN
            reminder_body := 'You have ' || entry_count || ' class(es) tomorrow (' || tomorrow_day || '). Check your schedule!';
        ELSE
            reminder_body := 'No classes scheduled for tomorrow (' || tomorrow_day || '). Enjoy your day off!';
        END IF;

        INSERT INTO notifications (type, title, body, recipient_type, recipient_id)
        VALUES ('daily_reminder', 'Tomorrow''s Schedule', reminder_body, 'student', student_rec.student_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;
""")

# ========================================
# NOTIFICATION TRIGGER
# ========================================
sql_parts.append("""
-- =====================================================
-- TIMETABLE CHANGE NOTIFICATION TRIGGER
-- =====================================================
CREATE OR REPLACE FUNCTION notify_on_timetable_change()
RETURNS TRIGGER AS $$
DECLARE
    course_title_val TEXT;
    teacher_name_val TEXT;
    batch_name_val TEXT;
    room_name_val TEXT;
    new_room_name_val TEXT;
    notif_type TEXT;
    notif_title TEXT;
    notif_body TEXT;
    student_rec RECORD;
BEGIN
    SELECT title INTO course_title_val FROM courses WHERE code = NEW.course_code;
    SELECT name INTO teacher_name_val FROM teachers WHERE initial = NEW.teacher_initial;
    SELECT name INTO batch_name_val FROM batches WHERE id = NEW.batch_id;
    SELECT name INTO room_name_val FROM rooms WHERE id = OLD.room_id;

    IF NEW.is_cancelled = TRUE AND OLD.is_cancelled = FALSE THEN
        notif_type := 'class_cancelled';
        notif_title := 'Class Cancelled';
        notif_body := course_title_val || ' (' || NEW.course_code || ') on ' || NEW.day ||
                      ' ' || NEW.start_time::TEXT || '-' || NEW.end_time::TEXT ||
                      ' by ' || teacher_name_val ||
                      COALESCE(' — Reason: ' || NEW.cancellation_reason, '');
    ELSIF NEW.is_cancelled = FALSE AND OLD.is_cancelled = TRUE THEN
        notif_type := 'class_restored';
        notif_title := 'Class Restored';
        notif_body := course_title_val || ' (' || NEW.course_code || ') on ' || NEW.day ||
                      ' ' || NEW.start_time::TEXT || '-' || NEW.end_time::TEXT ||
                      ' by ' || teacher_name_val || ' has been restored.';
    ELSIF NEW.day != OLD.day OR NEW.start_time != OLD.start_time OR NEW.end_time != OLD.end_time OR NEW.mode != OLD.mode THEN
        notif_type := 'class_rescheduled';
        notif_title := 'Class Rescheduled';
        notif_body := course_title_val || ' (' || NEW.course_code || ') moved from ' ||
                      OLD.day || ' ' || OLD.start_time::TEXT || '-' || OLD.end_time::TEXT ||
                      ' to ' || NEW.day || ' ' || NEW.start_time::TEXT || '-' || NEW.end_time::TEXT ||
                      ' (' || NEW.mode || ') by ' || teacher_name_val;
    ELSIF NEW.room_id IS DISTINCT FROM OLD.room_id THEN
        SELECT name INTO new_room_name_val FROM rooms WHERE id = NEW.room_id;
        notif_type := 'room_changed';
        notif_title := 'Room Changed';
        notif_body := course_title_val || ' (' || NEW.course_code || ') on ' || NEW.day ||
                      ': Room changed from ' || COALESCE(room_name_val, 'N/A') ||
                      ' to ' || COALESCE(new_room_name_val, 'N/A') ||
                      ' by ' || teacher_name_val;
    ELSE
        RETURN NEW;
    END IF;

    -- Notify super admins
    INSERT INTO notifications (type, title, body, recipient_type, recipient_id, related_entry_id)
    SELECT notif_type, notif_title, notif_body, 'super_admin', username, NEW.id
    FROM admins WHERE type = 'super_admin';

    -- Notify students in the batch
    FOR student_rec IN
        SELECT student_id FROM students WHERE batch_id = NEW.batch_id AND notifications_enabled = TRUE
    LOOP
        INSERT INTO notifications (type, title, body, recipient_type, recipient_id, related_entry_id)
        VALUES (notif_type, notif_title, notif_body, 'student', student_rec.student_id, NEW.id);
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS timetable_change_notification ON timetable_entries;
CREATE TRIGGER timetable_change_notification
    AFTER UPDATE ON timetable_entries
    FOR EACH ROW EXECUTE FUNCTION notify_on_timetable_change();

-- =====================================================
-- PREFERENCE NOTIFICATION TRIGGER (NEW)
-- =====================================================
-- When a preference status changes, notify the teacher
CREATE OR REPLACE FUNCTION notify_on_preference_change()
RETURNS TRIGGER AS $$
DECLARE
    course_title_val TEXT;
    batch_name_val TEXT;
    notif_body TEXT;
BEGIN
    IF NEW.status != OLD.status AND NEW.status IN ('approved', 'rejected') THEN
        SELECT title INTO course_title_val FROM courses WHERE code = NEW.course_code;
        SELECT name INTO batch_name_val FROM batches WHERE id = NEW.batch_id;

        notif_body := 'Your preference for ' || COALESCE(course_title_val, NEW.course_code) ||
                      ' (' || NEW.class_type || ') for ' || COALESCE(batch_name_val, 'batch') ||
                      ' has been ' || NEW.status || '.';

        INSERT INTO notifications (type, title, body, recipient_type, recipient_id)
        VALUES (
            CASE WHEN NEW.status = 'approved' THEN 'preference_approved' ELSE 'preference_rejected' END,
            'Course Preference ' || INITCAP(NEW.status),
            notif_body,
            'teacher',
            NEW.teacher_initial
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS preference_status_notification ON teacher_course_preferences;
CREATE TRIGGER preference_status_notification
    AFTER UPDATE ON teacher_course_preferences
    FOR EACH ROW EXECUTE FUNCTION notify_on_preference_change();
""")

# ========================================
# MIGRATION SECTION
# ========================================
sql_parts.append("""
-- =====================================================
-- MIGRATION: Run these if upgrading from v1.0 schema
-- =====================================================
-- If you already have the base tables and just need the new ones:
--
-- 1. Add new notification types:
-- ALTER TABLE notifications DROP CONSTRAINT IF EXISTS notifications_type_check;
-- ALTER TABLE notifications ADD CONSTRAINT notifications_type_check CHECK (type IN (
--     'class_cancelled', 'class_rescheduled', 'room_changed',
--     'class_restored', 'daily_reminder', 'appointment',
--     'general', 'class_assigned', 'class_updated', 'class_removed',
--     'teacher_added', 'course_added', 'preference_approved',
--     'preference_rejected', 'routine_generated'
-- ));
--
-- 2. Add 'Offline' to timetable mode check:
-- ALTER TABLE timetable_entries DROP CONSTRAINT IF EXISTS timetable_entries_mode_check;
-- ALTER TABLE timetable_entries ADD CONSTRAINT timetable_entries_mode_check CHECK (mode IN ('Onsite', 'Online', 'Offline'));
--
-- 3. Create new tables (teacher_course_preferences, routine_generations)
--    Copy the CREATE TABLE statements from sections 11 and 12 above.
--
-- 4. Run the realtime subscriptions for new tables:
-- ALTER PUBLICATION supabase_realtime ADD TABLE teacher_course_preferences;
-- ALTER PUBLICATION supabase_realtime ADD TABLE routine_generations;
--
-- 5. Run the new triggers (preference_status_notification).
-- =====================================================
""")

# Write the SQL file
sql_content = '\n'.join(sql_parts)
with open('supabase_schema.sql', 'w', encoding='utf-8') as f:
    f.write(sql_content)

print(f'supabase_schema.sql generated successfully!')
print(f'  Tables: 12 (admins, teachers, batches, courses, rooms, students, timetable_entries, app_metadata, appointments, notifications, teacher_course_preferences, routine_generations)')
print(f'  Teachers: {len(teachers)}')
print(f'  Batches: {len(batches)}')
print(f'  Courses: {len(courses)}')
print(f'  Rooms: {len(rooms)}')
print(f'  Admins: {len(admins)}')
print(f'  Timetable entries: {len(timetable_inserts)}')
print(f'  Views: 5')
print(f'  Functions: 4')
print(f'  Triggers: 14')
