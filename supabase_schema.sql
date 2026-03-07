-- =====================================================
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


-- =====================================================
-- INSERT REAL DATA: TEACHERS (17 faculty members)
-- =====================================================
INSERT INTO teachers (name, initial, designation, phone, email, home_department, profile_pic) VALUES
('Aditya Rajbongshi', 'AR', 'Assistant Professor', '+880-1628110523', 'aditya0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/AR.png'),
('Farhana Islam', 'FI', 'Assistant Professor', '+880-1878499660', 'farhana0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/FI.png'),
('Md. Ashrafuzzaman', 'AZ', 'Assistant Professor', '+880-1716504070', 'ashraf0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/AZ.png'),
('Munira Akter Lata', 'MA', 'Assistant Professor', '+880-1728378207', 'munira0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/MA.png'),
('Syeda Zakia Nayem', 'SZN', 'Assistant Professor', '+880-1933351916', 'zakia0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/SZN.png'),
('Al Faisal Bin Kashem Kanon', 'AFK', 'Lecturer', '+880-1521227992', 'afkanon1.bd@gmail.com', 'Educational Technology and Engineering', 'EdTE/AFK.png'),
('Md. Naimul Pathan', 'NP', 'Lecturer', '+880-1601713099', 'naimulpathan99@gmail.com', 'Educational Technology and Engineering', 'EdTE/NP.png'),
('Md. Rabbi Khan', 'MRK', 'Lecturer', '+880-1989072952', 'rabbi0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/MRK.png'),
('Md. Rezaul Islam', 'RI', 'Lecturer', '+880-1609053106', 'rezaul0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/RI.png'),
('Rubel Sheikh', 'RS', 'Lecturer', '+880-1743502507', 'rubel0003@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/RS.png'),
('Sunjida Akter', 'SA', 'Lecturer', '+880-1761401711', 'sunjida0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/SA.png'),
('Zannatul Ferdushie', 'ZF', 'Lecturer', '+880-1624262374', 'zannatul0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/ZF.png'),
('Sujon Chandra Sutradhar', 'SCS', 'Lecturer', '+880-1568076818', 'sujon0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/SCS.png'),
('Md. Sanaullah', 'MS', 'Lecturer', '+880-1740827561', 'sanaullah0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/MS.png'),
('MD. Nahid Hasan', 'NH', 'Lecturer', '+880-1727228000', 'nahid0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/NH.png'),
('Md. Mehedi Hasan', 'MH', 'Lecturer', '+880-1732279603', 'mehedi0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/MH.png'),
('Rabeya Basri', 'RB', 'Lecturer', '+880-1877031872', 'rabeya0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/RB.png')
ON CONFLICT (initial) DO UPDATE SET
    name = EXCLUDED.name,
    designation = EXCLUDED.designation,
    phone = EXCLUDED.phone,
    email = EXCLUDED.email,
    home_department = EXCLUDED.home_department,
    profile_pic = EXCLUDED.profile_pic;


-- =====================================================
-- INSERT REAL DATA: BATCHES (6 batches)
-- =====================================================
INSERT INTO batches (name, session) VALUES
('3rd Batch', '2020-21'),
('4th Batch', '2021-22'),
('5th Batch', '2022-23'),
('6th Batch', '2023-24'),
('7th Batch', '2024-25'),
('MSC', 'MSC')
ON CONFLICT (name, session) DO NOTHING;


-- =====================================================
-- INSERT REAL DATA: COURSES (37 courses)
-- =====================================================
INSERT INTO courses (code, title) VALUES
('CC 483', 'Capstone Course I'),
('CC 484', 'Capstone Course II'),
('CSE 113', 'Discrete Mathematics'),
('CSE 114', 'Structured Programming Lab'),
('CSE 115', 'Structured Programming'),
('CSE 201', 'Data Structures'),
('CSE 202', 'Data Structures Lab'),
('CSE 203', 'Object Oriented Programming'),
('CSE 204', 'Object Oriented Programming Lab'),
('EDU 4413', 'Educational Research Methods'),
('ENG 407', 'Technical English'),
('ENG 408', 'Technical English Lab'),
('ET 117', 'Fundamentals of Electrical Engineering'),
('ET 118', 'Fundamentals of Electrical Engineering Lab'),
('ET 205', 'Digital Logic Design'),
('ET 207', 'Electronic Devices and Circuits'),
('ET 315', 'Microprocessor and Microcontroller'),
('ET 316', 'Microprocessor and Microcontroller Lab'),
('ET 317', 'Computer Networks'),
('ET 318', 'Computer Networks Lab'),
('ET 401', 'Artificial Intelligence'),
('ET 402', 'Artificial Intelligence Lab'),
('ET 403', 'Database Management Systems'),
('ET 404', 'Database Management Systems Lab'),
('ET 405', 'Software Engineering'),
('ICT 4459', 'ICT in Education I'),
('ICT 4460', 'ICT in Education I Lab'),
('ICT 4461', 'ICT in Education II'),
('ICT 4462', 'ICT in Education II Lab'),
('ICTE 4439', 'ICT in Technical Education'),
('MATH 209', 'Calculus and Linear Algebra'),
('MATH 217', 'Statistics and Probability'),
('MSC', 'MSC Lecture'),
('NEM 481', 'Numerical and Estimation Methods'),
('NEM 482', 'Numerical and Estimation Methods Lab'),
('PROG 111', 'Introduction to Programming'),
('PROG 112', 'Introduction to Programming Lab')
ON CONFLICT (code) DO UPDATE SET title = EXCLUDED.title;


-- =====================================================
-- INSERT REAL DATA: ROOMS (11 rooms)
-- =====================================================
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


-- =====================================================
-- INSERT REAL DATA: ADMINS (18 accounts)
-- =====================================================
-- Super admin + teacher admin accounts
INSERT INTO admins (username, password_hash, type, teacher_initial) VALUES
('chairman', 'chairman123', 'super_admin', NULL),
('AR', 'ar123', 'teacher_admin', 'AR'),
('FI', 'fi123', 'teacher_admin', 'FI'),
('AZ', 'az123', 'teacher_admin', 'AZ'),
('MA', 'ma123', 'teacher_admin', 'MA'),
('SZN', 'szn123', 'teacher_admin', 'SZN'),
('AFK', 'afk123', 'teacher_admin', 'AFK'),
('NP', 'np123', 'teacher_admin', 'NP'),
('MRK', 'mrk123', 'teacher_admin', 'MRK'),
('RI', 'ri123', 'teacher_admin', 'RI'),
('RS', 'rs123', 'teacher_admin', 'RS'),
('SA', 'sa123', 'teacher_admin', 'SA'),
('ZF', 'zf123', 'teacher_admin', 'ZF'),
('SCS', 'scs123', 'teacher_admin', 'SCS'),
('MS', 'ms123', 'teacher_admin', 'MS'),
('NH', 'nh123', 'teacher_admin', 'NH'),
('MH', 'mh123', 'teacher_admin', 'MH'),
('RB', 'rb123', 'teacher_admin', 'RB')
ON CONFLICT (username) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    type = EXCLUDED.type,
    teacher_initial = EXCLUDED.teacher_initial;


-- =====================================================
-- INSERT APP METADATA
-- =====================================================
INSERT INTO app_metadata (version, institution_name, academic_year)
VALUES ('2.0.0', 'University of Frontier Technology, Bangladesh', '2025-2026')
ON CONFLICT DO NOTHING;


-- =====================================================
-- INSERT REAL DATA: TIMETABLE ENTRIES (76 entries)
-- Ramadhan Routine 2026 from output.json
-- =====================================================
INSERT INTO timetable_entries (day, batch_id, teacher_initial, course_code, type, group_name, room_id, mode, start_time, end_time, is_cancelled) VALUES
    ('Sat', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'AZ', 'ET 118', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'AZ', 'ET 118', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'NP', 'CSE 203', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'RS', 'CSE 201', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'SA', 'CC 483', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'AFK', 'ET 316', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'AFK', 'ET 316', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AR', 'ET 402', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AR', 'ET 402', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AZ', 'ET 403', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = 'MSC' LIMIT 1), 'RS', 'MSC', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = 'MSC' LIMIT 1), 'RS', 'MSC', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = 'MSC' LIMIT 1), 'NP', 'MSC', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sat', (SELECT id FROM batches WHERE name = 'MSC' LIMIT 1), 'NP', 'MSC', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'AZ', 'ET 117', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'FI', 'PROG 111', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'RI', 'CSE 114', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'RI', 'CSE 114', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'MH', 'MATH 217', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'MRK', 'ET 205', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'NP', 'CSE 203', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'SA', 'CC 484', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'SA', 'CC 484', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'AFK', 'ET 315', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MRK', 'ET 317', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'NH', 'ENG 407', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AFK', 'EDU 4413', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Sun', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'MA', 'ET 405', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'RI', 'CSE 115', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'RI', 'CSE 113', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'FI', 'PROG 112', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'FI', 'PROG 112', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'AFK', 'ET 207', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'MH', 'MATH 217', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'SA', 'CC 483', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'AFK', 'ET 315', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MA', 'NEM 481', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AZ', 'ET 404', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AZ', 'ET 404', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AR', 'ET 401', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'SA', 'ICTE 4439', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'FI', 'ICT 4461', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'AR', 'ICT 4459', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Mon', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'AFK', 'EDU 4413', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'AZ', 'ET 117', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'RI', 'CSE 113', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'MH', 'MATH 209', 'Lecture', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'RS', 'CSE 201', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'AFK', 'ET 207', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MRK', 'ET 318', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MRK', 'ET 318', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MA', 'NEM 481', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'NH', 'ENG 407', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AZ', 'ET 403', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'MA', 'ET 405', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'AR', 'ICT 4460', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'AR', 'ICT 4460', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'FI', 'ICT 4462', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Tue', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'FI', 'ICT 4462', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'RI', 'CSE 115', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'FI', 'PROG 111', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '7th Batch' LIMIT 1), 'MH', 'MATH 209', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'RS', 'CSE 202', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'NP', 'CSE 204', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'RS', 'CSE 202', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'NP', 'CSE 204', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '6th Batch' LIMIT 1), 'MRK', 'ET 205', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MRK', 'ET 317', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MA', 'NEM 482', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '5th Batch' LIMIT 1), 'MA', 'NEM 482', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '4701 (LAB)' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'AR', 'ET 401', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '2001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'NH', 'ENG 408', 'Sessional', 'G1', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '11:30', '12:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '4th Batch' LIMIT 1), 'NH', 'ENG 408', 'Sessional', 'G2', (SELECT id FROM rooms WHERE name = '2701 (LAB)' LIMIT 1), 'Offline', '13:30', '14:45', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'SA', 'ICTE 4439', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '09:00', '10:15', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'AR', 'ICT 4459', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '1001' LIMIT 1), 'Offline', '10:15', '11:30', FALSE),
    ('Wed', (SELECT id FROM batches WHERE name = '3rd Batch' LIMIT 1), 'FI', 'ICT 4461', 'Tutorial', NULL, (SELECT id FROM rooms WHERE name = '4001' LIMIT 1), 'Offline', '11:30', '12:45', FALSE);


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
