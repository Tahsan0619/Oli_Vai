-- =====================================================
-- EDTE Routine Scrapper - Supabase Database Schema
-- =====================================================
-- Run this SQL in your Supabase SQL Editor
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- STORAGE BUCKET FOR TEACHER PROFILE PICTURES
-- =====================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('teacher-profiles', 'teacher-profiles', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for teacher profile pictures
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

-- Create index for faster lookups
CREATE INDEX idx_admins_username ON admins(username);
CREATE INDEX idx_admins_type ON admins(type);

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

CREATE INDEX idx_teachers_initial ON teachers(initial);
CREATE INDEX idx_teachers_department ON teachers(home_department);

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

CREATE INDEX idx_batches_session ON batches(session);

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

CREATE INDEX idx_courses_code ON courses(code);

-- =====================================================
-- 5. ROOMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_rooms_name ON rooms(name);

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

CREATE INDEX idx_students_batch ON students(batch_id);
CREATE INDEX idx_students_student_id ON students(student_id);

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
    mode TEXT NOT NULL CHECK (mode IN ('Onsite', 'Online')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_cancelled BOOLEAN DEFAULT FALSE,
    cancellation_reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_timetable_day ON timetable_entries(day);
CREATE INDEX idx_timetable_batch ON timetable_entries(batch_id);
CREATE INDEX idx_timetable_teacher ON timetable_entries(teacher_initial);
CREATE INDEX idx_timetable_course ON timetable_entries(course_code);
CREATE INDEX idx_timetable_room ON timetable_entries(room_id);

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
-- TRIGGERS FOR UPDATED_AT
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_teachers_updated_at BEFORE UPDATE ON teachers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_batches_updated_at BEFORE UPDATE ON batches
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_courses_updated_at BEFORE UPDATE ON courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rooms_updated_at BEFORE UPDATE ON rooms
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_timetable_entries_updated_at BEFORE UPDATE ON timetable_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_metadata ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (you can customize these based on your needs)
-- For simplicity, allowing all operations with anon key
-- In production, you should implement proper authentication

CREATE POLICY "Allow all on admins" ON admins FOR ALL USING (true);
CREATE POLICY "Allow all on teachers" ON teachers FOR ALL USING (true);
CREATE POLICY "Allow all on batches" ON batches FOR ALL USING (true);
CREATE POLICY "Allow all on courses" ON courses FOR ALL USING (true);
CREATE POLICY "Allow all on rooms" ON rooms FOR ALL USING (true);
CREATE POLICY "Allow all on students" ON students FOR ALL USING (true);
CREATE POLICY "Allow all on timetable_entries" ON timetable_entries FOR ALL USING (true);
CREATE POLICY "Allow all on app_metadata" ON app_metadata FOR ALL USING (true);

-- =====================================================
-- INSERT DEFAULT SUPER ADMIN
-- =====================================================
-- Password: SuperAdmin@2026 (you should change this in production)
-- Using a simple hash for demonstration (in production use proper bcrypt/argon2)
INSERT INTO admins (username, password_hash, type, teacher_initial)
VALUES 
    ('superadmin@edte.com', 'SuperAdmin@2026', 'super_admin', NULL),
    ('admin@edte.com', 'Admin@123', 'super_admin', NULL),
    -- Teacher Admin Account (linked to teacher with initial 'AZ')
    ('teacher@edte.com', 'Teacher@123', 'teacher_admin', 'AZ')
ON CONFLICT (username) DO NOTHING;

-- =====================================================
-- INSERT SAMPLE DATA (OPTIONAL - Remove in production)
-- =====================================================

-- Insert sample metadata
INSERT INTO app_metadata (version, institution_name, academic_year)
VALUES ('1.0.0', 'EDTE University', '2025-2026')
ON CONFLICT DO NOTHING;

-- Insert sample teachers
INSERT INTO teachers (name, initial, designation, phone, email, home_department) VALUES
('Dr. Azizur Rahman', 'AZ', 'Professor', '01711-123456', 'aziz@edte.edu', 'CSE'),
('Dr. Mohammad Ali', 'MA', 'Associate Professor', '01722-234567', 'mali@edte.edu', 'CSE'),
('Dr. Fatima Khan', 'FK', 'Assistant Professor', '01733-345678', 'fkhan@edte.edu', 'EEE'),
('Dr.Rahim Uddin', 'RU', 'Professor', '01744-456789', 'rahim@edte.edu', 'CSE')
ON CONFLICT (initial) DO NOTHING;

-- Insert sample courses
INSERT INTO courses (code, title) VALUES
('CSE101', 'Introduction to Programming'),
('CSE201', 'Data Structures'),
('CSE301', 'Database Management Systems'),
('CSE401', 'Software Engineering'),
('EEE101', 'Circuit Theory'),
('MATH101', 'Calculus I')
ON CONFLICT (code) DO NOTHING;

-- Insert sample rooms
INSERT INTO rooms (name) VALUES
('1001'),
('1002'),
('2001'),
('2002'),
('2701 (LAB)'),
('4001'),
('4002'),
('4701 (LAB)'),
('5001'),
('5002'),
('5701 (LAB)')
ON CONFLICT (name) DO NOTHING;

-- Insert sample batches
INSERT INTO batches (name, session) VALUES
('CSE-A', '2023-2024'),
('CSE-B', '2023-2024'),
('EEE-A', '2023-2024'),
('CSE-A', '2024-2025')
ON CONFLICT (name, session) DO NOTHING;

-- =====================================================
-- VIEWS FOR EASIER QUERYING
-- =====================================================

-- View for complete timetable with all related information
CREATE OR REPLACE VIEW v_timetable_complete AS
SELECT 
    te.id,
    te.day,
    te.start_time,
    te.end_time,
    te.type,
    te.group_name,
    te.mode,
    te.is_cancelled,
    te.cancellation_reason,
    b.id as batch_id,
    b.name as batch_name,
    b.session as batch_session,
    t.initial as teacher_initial,
    t.name as teacher_name,
    t.designation as teacher_designation,
    c.code as course_code,
    c.title as course_title,
    r.id as room_id,
    r.name as room_name,
    te.created_at,
    te.updated_at
FROM timetable_entries te
JOIN batches b ON te.batch_id = b.id
JOIN teachers t ON te.teacher_initial = t.initial
JOIN courses c ON te.course_code = c.code
LEFT JOIN rooms r ON te.room_id = r.id;

-- View for student batch information
CREATE OR REPLACE VIEW v_students_with_batch AS
SELECT 
    s.id,
    s.student_id,
    s.name,
    s.email,
    s.phone,
    b.id as batch_id,
    b.name as batch_name,
    b.session as batch_session,
    s.created_at,
    s.updated_at
FROM students s
JOIN batches b ON s.batch_id = b.id;

-- =====================================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- =====================================================

-- Function to get teacher's schedule for a day
CREATE OR REPLACE FUNCTION get_teacher_schedule(
    teacher_initial_param TEXT,
    day_param TEXT
)
RETURNS TABLE (
    id UUID,
    start_time TIME,
    end_time TIME,
    course_code TEXT,
    course_title TEXT,
    batch_name TEXT,
    room_name TEXT,
    type TEXT,
    mode TEXT,
    is_cancelled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        te.id,
        te.start_time,
        te.end_time,
        c.code,
        c.title,
        b.name,
        r.name,
        te.type,
        te.mode,
        te.is_cancelled
    FROM timetable_entries te
    JOIN courses c ON te.course_code = c.code
    JOIN batches b ON te.batch_id = b.id
    LEFT JOIN rooms r ON te.room_id = r.id
    WHERE te.teacher_initial = teacher_initial_param 
      AND te.day = day_param
    ORDER BY te.start_time;
END;
$$ LANGUAGE plpgsql;

-- Function to get batch schedule for a day
CREATE OR REPLACE FUNCTION get_batch_schedule(
    batch_id_param UUID,
    day_param TEXT
)
RETURNS TABLE (
    id UUID,
    start_time TIME,
    end_time TIME,
    course_code TEXT,
    course_title TEXT,
    teacher_name TEXT,
    teacher_initial TEXT,
    room_name TEXT,
    type TEXT,
    mode TEXT,
    is_cancelled BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        te.id,
        te.start_time,
        te.end_time,
        c.code,
        c.title,
        t.name,
        t.initial,
        r.name,
        te.type,
        te.mode,
        te.is_cancelled
    FROM timetable_entries te
    JOIN courses c ON te.course_code = c.code
    JOIN teachers t ON te.teacher_initial = t.initial
    LEFT JOIN rooms r ON te.room_id = r.id
    WHERE te.batch_id = batch_id_param 
      AND te.day = day_param
    ORDER BY te.start_time;
END;
$$ LANGUAGE plpgsql;

-- Function to find free rooms at a specific time
CREATE OR REPLACE FUNCTION get_free_rooms(
    day_param TEXT,
    time_param TIME
)
RETURNS TABLE (
    room_id UUID,
    room_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT r.id, r.name
    FROM rooms r
    WHERE r.id NOT IN (
        SELECT te.room_id
        FROM timetable_entries te
        WHERE te.day = day_param
          AND te.room_id IS NOT NULL
          AND te.is_cancelled = FALSE
          AND time_param >= te.start_time
          AND time_param < te.end_time
    )
    ORDER BY r.name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- MIGRATION: ADD CREDENTIAL COLUMNS (RUN IF UPDATING EXISTING DB)
-- =====================================================
-- Uncomment and run these ALTER TABLE statements if you have an existing database
-- to add the new credential management columns

-- ALTER TABLE teachers
-- ADD COLUMN IF NOT EXISTS password TEXT,
-- ADD COLUMN IF NOT EXISTS has_changed_password BOOLEAN DEFAULT FALSE;

-- ALTER TABLE students
-- ADD COLUMN IF NOT EXISTS password TEXT,
-- ADD COLUMN IF NOT EXISTS has_changed_password BOOLEAN DEFAULT FALSE;

-- =====================================================
-- 9. APPOINTMENTS TABLE (Student ↔ Teacher)
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

CREATE INDEX idx_appointments_teacher ON appointments(teacher_initial);
CREATE INDEX idx_appointments_student ON appointments(student_id);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_date ON appointments(date);

-- Trigger for updated_at
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on appointments" ON appointments FOR ALL USING (true);

-- =====================================================
-- MIGRATION: ADD APPOINTMENTS TABLE (RUN IF UPDATING EXISTING DB)
-- =====================================================
-- If you already have the existing schema, just run the block above
-- (CREATE TABLE appointments ... through CREATE POLICY)

-- =====================================================
-- 10. NOTIFICATIONS TABLE (In-App Notifications)
-- =====================================================
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type TEXT NOT NULL CHECK (type IN (
        'class_cancelled', 'class_rescheduled', 'room_changed',
        'class_restored', 'daily_reminder', 'appointment',
        'general', 'class_assigned', 'class_updated', 'class_removed',
        'teacher_added', 'course_added'
    )),
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    recipient_type TEXT NOT NULL CHECK (recipient_type IN ('super_admin', 'student', 'teacher')),
    recipient_id TEXT NOT NULL, -- student_id, teacher_initial, or 'all_admins'
    related_entry_id UUID,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_type, recipient_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- Trigger for updated_at
CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all on notifications" ON notifications FOR ALL USING (true);

-- =====================================================
-- REALTIME: Enable realtime for all key tables
-- =====================================================
-- Run in Supabase SQL Editor:
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE teachers;
ALTER PUBLICATION supabase_realtime ADD TABLE students;
ALTER PUBLICATION supabase_realtime ADD TABLE courses;
ALTER PUBLICATION supabase_realtime ADD TABLE rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE batches;
ALTER PUBLICATION supabase_realtime ADD TABLE timetable_entries;

-- =====================================================
-- 11. DATABASE TRIGGER: Auto-create notifications on timetable changes
-- =====================================================

-- Function: When a timetable entry is updated (cancelled, rescheduled, room changed, restored)
-- automatically insert notification rows for super_admin + all students in that batch
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
    -- Get related info
    SELECT title INTO course_title_val FROM courses WHERE code = NEW.course_code;
    SELECT name INTO teacher_name_val FROM teachers WHERE initial = NEW.teacher_initial;
    SELECT name INTO batch_name_val FROM batches WHERE id = NEW.batch_id;
    SELECT name INTO room_name_val FROM rooms WHERE id = OLD.room_id;

    -- Determine notification type
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
        -- No significant change
        RETURN NEW;
    END IF;

    -- Notify all super admins
    INSERT INTO notifications (type, title, body, recipient_type, recipient_id, related_entry_id)
    SELECT notif_type, notif_title, notif_body, 'super_admin', username, NEW.id
    FROM admins WHERE type = 'super_admin';

    -- Notify all students in the affected batch (only if notifications_enabled)
    FOR student_rec IN
        SELECT student_id FROM students WHERE batch_id = NEW.batch_id AND notifications_enabled = TRUE
    LOOP
        INSERT INTO notifications (type, title, body, recipient_type, recipient_id, related_entry_id)
        VALUES (notif_type, notif_title, notif_body, 'student', student_rec.student_id, NEW.id);
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER timetable_change_notification
    AFTER UPDATE ON timetable_entries
    FOR EACH ROW
    EXECUTE FUNCTION notify_on_timetable_change();

-- =====================================================
-- 12. DATABASE FUNCTION: Send email via Edge Function
-- =====================================================
-- This function is called by the Edge Functions (not directly from DB)
-- The Edge Functions poll notifications table or use webhooks

-- Helper view: Get students with emails for a batch (used by Edge Functions)
-- Only includes students with email_enabled = true
CREATE OR REPLACE VIEW v_batch_student_emails AS
SELECT
    s.student_id,
    s.name,
    s.email,
    s.batch_id,
    b.name as batch_name,
    s.notifications_enabled,
    s.email_enabled
FROM students s
JOIN batches b ON s.batch_id = b.id
WHERE s.email IS NOT NULL AND s.email != '' AND s.email_enabled = TRUE;

-- Helper view: Get admin emails (used by Edge Functions)
CREATE OR REPLACE VIEW v_admin_emails AS
SELECT username as email, type FROM admins;

-- =====================================================
-- 13. DAILY REMINDER FUNCTION (Called by pg_cron or Edge Function)
-- =====================================================
-- This function creates daily reminder notifications at midnight
-- for all students who have notifications_enabled = true
-- It sends reminders about the next day's schedule

CREATE OR REPLACE FUNCTION create_daily_reminders()
RETURNS void AS $$
DECLARE
    tomorrow_day TEXT;
    student_rec RECORD;
    entry_count INT;
    reminder_body TEXT;
BEGIN
    -- Get tomorrow's day name
    SELECT CASE EXTRACT(DOW FROM (CURRENT_DATE + INTERVAL '1 day'))
        WHEN 0 THEN 'Sun' WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue'
        WHEN 3 THEN 'Wed' WHEN 4 THEN 'Thu' WHEN 5 THEN 'Fri'
        WHEN 6 THEN 'Sat'
    END INTO tomorrow_day;

    -- For each student with notifications enabled
    FOR student_rec IN
        SELECT s.student_id, s.name, s.batch_id, s.email, s.email_enabled
        FROM students s
        WHERE s.notifications_enabled = TRUE
    LOOP
        -- Count tomorrow's classes for this student's batch
        SELECT COUNT(*) INTO entry_count
        FROM timetable_entries te
        WHERE te.batch_id = student_rec.batch_id
          AND te.day = tomorrow_day
          AND te.is_cancelled = FALSE;

        IF entry_count > 0 THEN
            reminder_body := 'You have ' || entry_count || ' class(es) tomorrow (' || tomorrow_day || '). Check your schedule!';
        ELSE
            reminder_body := 'No classes scheduled for tomorrow (' || tomorrow_day || '). Enjoy your day off!';
        END IF;

        -- Create in-app notification
        INSERT INTO notifications (type, title, body, recipient_type, recipient_id)
        VALUES ('daily_reminder', 'Tomorrow''s Schedule', reminder_body, 'student', student_rec.student_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Schedule daily at midnight (Asia/Dhaka = UTC+6, so 18:00 UTC = 00:00 BDT)
-- Requires pg_cron extension enabled in Supabase:
-- SELECT cron.schedule('daily-reminders', '0 18 * * *', 'SELECT create_daily_reminders()');

-- =====================================================
-- MIGRATION: ADD NOTIFICATIONS (RUN IF UPDATING EXISTING DB)
-- =====================================================
-- Run the CREATE TABLE notifications block above
-- Then: ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- =====================================================
-- MIGRATION: ADD PERMISSION COLUMNS (RUN IF UPDATING EXISTING DB)
-- =====================================================
-- ALTER TABLE teachers
-- ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT FALSE,
-- ADD COLUMN IF NOT EXISTS email_enabled BOOLEAN DEFAULT FALSE;

-- ALTER TABLE students
-- ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT FALSE,
-- ADD COLUMN IF NOT EXISTS email_enabled BOOLEAN DEFAULT FALSE;

-- =====================================================
-- COMPLETION MESSAGE
-- =====================================================
DO $$
BEGIN
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Database schema created successfully!';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'Default Super Admin Credentials:';
    RAISE NOTICE 'Username: superadmin@edte.com';
    RAISE NOTICE 'Password: SuperAdmin@2026';
    RAISE NOTICE '';
    RAISE NOTICE 'Alternative Admin:';
    RAISE NOTICE 'Username: admin@edte.com';
    RAISE NOTICE 'Password: Admin@123';
    RAISE NOTICE '========================================';
    RAISE NOTICE 'IMPORTANT - NEW CREDENTIAL COLUMNS:';
    RAISE NOTICE 'If updating existing database, run the';
    RAISE NOTICE 'ALTER TABLE statements in the MIGRATION section';
    RAISE NOTICE '========================================';

    RAISE NOTICE 'IMPORTANT: Change these passwords in production!';
    RAISE NOTICE '========================================';
END $$;
