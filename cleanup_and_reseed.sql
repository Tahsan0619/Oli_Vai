-- =====================================================
-- CLEANUP & RE-SEED: Delete old data, insert fresh routine
-- from output.json (Ramadhan Routine 2026)
-- =====================================================
-- Run this in the Supabase SQL Editor at:
-- https://supabase.com/dashboard → your project → SQL Editor
-- =====================================================

-- =====================================================
-- STEP 1: CLEAR ALL OLD TIMETABLE ENTRIES
-- =====================================================
DELETE FROM timetable_entries;

-- =====================================================
-- STEP 2: CLEAR OLD NOTIFICATIONS & APPOINTMENTS
-- (they reference old data)
-- =====================================================
DELETE FROM notifications;
DELETE FROM appointments;
DELETE FROM teacher_course_preferences;
DELETE FROM routine_generations;

-- =====================================================
-- STEP 3: DELETE OLD STUDENTS (they reference batches)
-- =====================================================
DELETE FROM students;

-- =====================================================
-- STEP 4: DELETE ALL OLD BATCHES
-- =====================================================
DELETE FROM batches;

-- =====================================================
-- STEP 5: DELETE ALL OLD TEACHERS & ADMINS
-- =====================================================
DELETE FROM admins;
DELETE FROM teachers;

-- =====================================================
-- STEP 6: DELETE ALL OLD COURSES & ROOMS
-- =====================================================
DELETE FROM courses;
DELETE FROM rooms;

-- =====================================================
-- STEP 7: INSERT CORRECT TEACHERS (17 faculty members)
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
('Rabeya Basri', 'RB', 'Lecturer', '+880-1877031872', 'rabeya0001@uftb.ac.bd', 'Educational Technology and Engineering', 'EdTE/RB.png');

-- =====================================================
-- STEP 8: INSERT CORRECT BATCHES (6 batches)
-- =====================================================
INSERT INTO batches (name, session) VALUES
('3rd Batch', '2020-21'),
('4th Batch', '2021-22'),
('5th Batch', '2022-23'),
('6th Batch', '2023-24'),
('7th Batch', '2024-25'),
('MSC', 'MSC');

-- =====================================================
-- STEP 9: INSERT CORRECT COURSES (37 courses)
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
('PROG 112', 'Introduction to Programming Lab');

-- =====================================================
-- STEP 10: INSERT CORRECT ROOMS (11 rooms)
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
('5701 (LAB)');

-- =====================================================
-- STEP 11: INSERT ADMIN ACCOUNTS
-- =====================================================
INSERT INTO admins (username, password_hash, type, teacher_initial) VALUES
('superadmin@edte.com', 'SuperAdmin@2026', 'super_admin', NULL),
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
('RB', 'rb123', 'teacher_admin', 'RB');

-- =====================================================
-- STEP 12: INSERT APP METADATA
-- =====================================================
DELETE FROM app_metadata;
INSERT INTO app_metadata (version, institution_name, academic_year)
VALUES ('2.0.0', 'University of Frontier Technology, Bangladesh', '2025-2026');

-- =====================================================
-- STEP 13: INSERT ALL 76 TIMETABLE ENTRIES
-- (Ramadhan Routine 2026 from output.json)
-- =====================================================
INSERT INTO timetable_entries (day, batch_id, teacher_initial, course_code, type, group_name, room_id, mode, start_time, end_time, is_cancelled) VALUES
-- SATURDAY
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
-- SUNDAY
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
-- MONDAY
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
-- TUESDAY
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
-- WEDNESDAY
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
-- STEP 14: RE-INSERT STUDENTS (run insert_students.sql after this)
-- =====================================================
-- After running this script, also run insert_students.sql 
-- to add students back for each batch.

-- =====================================================
-- VERIFICATION: Check counts
-- =====================================================
SELECT 'teachers' AS table_name, COUNT(*) AS count FROM teachers
UNION ALL SELECT 'batches', COUNT(*) FROM batches
UNION ALL SELECT 'courses', COUNT(*) FROM courses
UNION ALL SELECT 'rooms', COUNT(*) FROM rooms
UNION ALL SELECT 'timetable_entries', COUNT(*) FROM timetable_entries
UNION ALL SELECT 'admins', COUNT(*) FROM admins;
