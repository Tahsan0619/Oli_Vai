"""Generate updated data.json from output.json and Faculty List data."""
import json, re

# Load output.json
with open('output.json', 'r') as f:
    data = json.load(f)

# Course code -> title mapping
course_titles = {
    'CC 483': 'Capstone Course I',
    'CC 484': 'Capstone Course II',
    'CSE 113': 'Discrete Mathematics',
    'CSE 114': 'Structured Programming Lab',
    'CSE 115': 'Structured Programming',
    'CSE 201': 'Data Structures',
    'CSE 202': 'Data Structures Lab',
    'CSE 203': 'Object Oriented Programming',
    'CSE 204': 'Object Oriented Programming Lab',
    'EDU 4413': 'Educational Research Methods',
    'ENG 407': 'Technical English',
    'ENG 408': 'Technical English Lab',
    'ET 117': 'Fundamentals of Electrical Engineering',
    'ET 118': 'Fundamentals of Electrical Engineering Lab',
    'ET 205': 'Digital Logic Design',
    'ET 207': 'Electronic Devices and Circuits',
    'ET 315': 'Microprocessor and Microcontroller',
    'ET 316': 'Microprocessor and Microcontroller Lab',
    'ET 317': 'Computer Networks',
    'ET 318': 'Computer Networks Lab',
    'ET 401': 'Artificial Intelligence',
    'ET 402': 'Artificial Intelligence Lab',
    'ET 403': 'Database Management Systems',
    'ET 404': 'Database Management Systems Lab',
    'ET 405': 'Software Engineering',
    'ICT 4459': 'ICT in Education I',
    'ICT 4460': 'ICT in Education I Lab',
    'ICT 4461': 'ICT in Education II',
    'ICT 4462': 'ICT in Education II Lab',
    'ICTE 4439': 'ICT in Technical Education',
    'MATH 209': 'Calculus and Linear Algebra',
    'MATH 217': 'Statistics and Probability',
    'NEM 481': 'Numerical and Estimation Methods',
    'NEM 482': 'Numerical and Estimation Methods Lab',
    'PROG 111': 'Introduction to Programming',
    'PROG 112': 'Introduction to Programming Lab',
    'MSC': 'MSC Lecture',
}

# Time slot mapping
time_map = {
    '09:00-10:15': ('09:00', '10:15'),
    '10:15-11:30': ('10:15', '11:30'),
    '11:30-12:45': ('11:30', '12:45'),
    '01:30-02:45': ('13:30', '14:45'),
}

session_to_batch = {
    '2020-2021': '3rd',
    '2021-2022': '4th',
    '2022-2023': '5th',
    '2023-2024': '6th',
    '2024-2025': '7th',
    'MSC': 'MSC',
}

def parse_entry(text, day, session, time_slot):
    text = text.strip()
    if not text or text == 'Break':
        return []
    start, end = time_map.get(time_slot, ('', ''))
    if not start:
        return []
    batch_id = session_to_batch.get(session, session)
    
    # Compound entries
    if ' & ' in text:
        parts = text.rsplit(' Sessional', 1)
        if len(parts) == 2:
            compound = parts[0]
        else:
            compound = text
        sub_parts = compound.split(' & ')
        results = []
        for part in sub_parts:
            part = part.strip()
            m = re.match(r'([A-Z]+\s+\d+)\s+G(\d+)\s+\((\w+)\)\s*-\s*(\w+)', part)
            if m:
                results.append({
                    'day': day[:3],
                    'batch_id': batch_id,
                    'teacher_initial': m.group(3),
                    'course_code': m.group(1),
                    'type': 'Sessional',
                    'group': 'G' + m.group(2),
                    'room_id': m.group(4),
                    'mode': 'Offline',
                    'start': start,
                    'end': end,
                    'is_cancelled': False,
                })
        return results
    
    # MSC format: 'RS [4001]'
    m = re.match(r'^(\w+)\s+\[(\w+)\]$', text)
    if m:
        return [{
            'day': day[:3],
            'batch_id': batch_id,
            'teacher_initial': m.group(1),
            'course_code': 'MSC',
            'type': 'Lecture',
            'group': None,
            'room_id': m.group(2),
            'mode': 'Offline',
            'start': start,
            'end': end,
            'is_cancelled': False,
        }]
    
    # Normalize: GI -> G1
    text = text.replace(' GI-', ' G1-')
    
    # With group: 'COURSE (TEACHER) GROUP-ROOM TYPE' or 'COURSE GROUP (TEACHER)-ROOM TYPE'
    m = re.match(r'([A-Z]+\s+\d+)\s*\((\w+)\)\s+G(\d+)\s*-\s*(\w+)\s+(Sessional|Lecture|Tutorial)(?:\s+Class)?', text)
    if m:
        return [{
            'day': day[:3],
            'batch_id': batch_id,
            'teacher_initial': m.group(2),
            'course_code': m.group(1),
            'type': m.group(5),
            'group': 'G' + m.group(3),
            'room_id': m.group(4),
            'mode': 'Offline',
            'start': start,
            'end': end,
            'is_cancelled': False,
        }]
    # Alternate group format: 'NEM 482 G1 (MA)-4701 Sessional'
    m = re.match(r'([A-Z]+\s+\d+)\s+G(\d+)\s+\((\w+)\)\s*-\s*(\w+)\s+(Sessional|Lecture|Tutorial)(?:\s+Class)?', text)
    if m:
        return [{
            'day': day[:3],
            'batch_id': batch_id,
            'teacher_initial': m.group(3),
            'course_code': m.group(1),
            'type': m.group(5),
            'group': 'G' + m.group(2),
            'room_id': m.group(4),
            'mode': 'Offline',
            'start': start,
            'end': end,
            'is_cancelled': False,
        }]
    
    # Without group: 'COURSE (TEACHER) - ROOM TYPE' or 'COURSE(TEACHER)-ROOM TYPE'
    m = re.match(r'([A-Z]+\s+\d+)\s*\((\w+)\)\s*-\s*(\w+)\s+(Sessional|Lecture|Tutorial)(?:\s+Class)?', text)
    if m:
        return [{
            'day': day[:3],
            'batch_id': batch_id,
            'teacher_initial': m.group(2),
            'course_code': m.group(1),
            'type': m.group(4),
            'group': None,
            'room_id': m.group(3),
            'mode': 'Offline',
            'start': start,
            'end': end,
            'is_cancelled': False,
        }]
    
    print(f'UNPARSED: [{text}] day={day}, session={session}, slot={time_slot}')
    return []

# Parse all entries
entries = []
schedule = data['schedule']
for day, sessions in schedule.items():
    for session, slots in sessions.items():
        for time_slot, entry_text in slots.items():
            parsed = parse_entry(entry_text, day, session, time_slot)
            entries.extend(parsed)

print(f'Total entries parsed: {len(entries)}')

unique_courses = set()
for e in entries:
    unique_courses.add(e['course_code'])
print(f'Unique courses ({len(unique_courses)}): {sorted(unique_courses)}')

# Faculty data from Faculty List.xlsx
teachers = [
    {"id": "T001", "name": "Aditya Rajbongshi", "initial": "AR", "designation": "Assistant Professor", "phone": "+880-1628110523", "email": "aditya0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/AR.png"},
    {"id": "T002", "name": "Farhana Islam", "initial": "FI", "designation": "Assistant Professor", "phone": "+880-1878499660", "email": "farhana0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/FI.png"},
    {"id": "T003", "name": "Md. Ashrafuzzaman", "initial": "AZ", "designation": "Assistant Professor", "phone": "+880-1716504070", "email": "ashraf0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/AZ.png"},
    {"id": "T004", "name": "Munira Akter Lata", "initial": "MA", "designation": "Assistant Professor", "phone": "+880-1728378207", "email": "munira0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/MA.png"},
    {"id": "T005", "name": "Syeda Zakia Nayem", "initial": "SZN", "designation": "Assistant Professor", "phone": "+880-1933351916", "email": "zakia0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/SZN.png"},
    {"id": "T006", "name": "Al Faisal Bin Kashem Kanon", "initial": "AFK", "designation": "Lecturer", "phone": "+880-1521227992", "email": "afkanon1.bd@gmail.com", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/AFK.png"},
    {"id": "T007", "name": "Md. Naimul Pathan", "initial": "NP", "designation": "Lecturer", "phone": "+880-1601713099", "email": "naimulpathan99@gmail.com", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/NP.png"},
    {"id": "T008", "name": "Md. Rabbi Khan", "initial": "MRK", "designation": "Lecturer", "phone": "+880-1989072952", "email": "rabbi0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/MRK.png"},
    {"id": "T009", "name": "Md. Rezaul Islam", "initial": "RI", "designation": "Lecturer", "phone": "+880-1609053106", "email": "rezaul0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/RI.png"},
    {"id": "T010", "name": "Rubel Sheikh", "initial": "RS", "designation": "Lecturer", "phone": "+880-1743502507", "email": "rubel0003@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/RS.png"},
    {"id": "T011", "name": "Sunjida Akter", "initial": "SA", "designation": "Lecturer", "phone": "+880-1761401711", "email": "sunjida0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/SA.png"},
    {"id": "T012", "name": "Zannatul Ferdushie", "initial": "ZF", "designation": "Lecturer", "phone": "+880-1624262374", "email": "zannatul0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/ZF.png"},
    {"id": "T013", "name": "Sujon Chandra Sutradhar", "initial": "SCS", "designation": "Lecturer", "phone": "+880-1568076818", "email": "sujon0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/SCS.png"},
    {"id": "T014", "name": "Md. Sanaullah", "initial": "MS", "designation": "Lecturer", "phone": "+880-1740827561", "email": "sanaullah0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/MS.png"},
    {"id": "T015", "name": "MD. Nahid Hasan", "initial": "NH", "designation": "Lecturer", "phone": "+880-1727228000", "email": "nahid0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/NH.png"},
    {"id": "T016", "name": "Md. Mehedi Hasan", "initial": "MH", "designation": "Lecturer", "phone": "+880-1732279603", "email": "mehedi0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/MH.png"},
    {"id": "T017", "name": "Rabeya Basri", "initial": "RB", "designation": "Lecturer", "phone": "+880-1877031872", "email": "rabeya0001@uftb.ac.bd", "home_department": "Educational Technology and Engineering", "profile_pic": "EdTE/RB.png"},
]

batches = [
    {"id": "3rd", "name": "3rd Batch", "session": "2020-21"},
    {"id": "4th", "name": "4th Batch", "session": "2021-22"},
    {"id": "5th", "name": "5th Batch", "session": "2022-23"},
    {"id": "6th", "name": "6th Batch", "session": "2023-24"},
    {"id": "7th", "name": "7th Batch", "session": "2024-25"},
    {"id": "MSC", "name": "MSC", "session": "MSC"},
]

courses = [{"code": code, "title": title} for code, title in sorted(course_titles.items())]

rooms = [
    {"id": "1001", "name": "1001"},
    {"id": "1002", "name": "1002"},
    {"id": "2001", "name": "2001"},
    {"id": "2002", "name": "2002"},
    {"id": "2701", "name": "2701 (LAB)"},
    {"id": "4001", "name": "4001"},
    {"id": "4002", "name": "4002"},
    {"id": "4701", "name": "4701 (LAB)"},
    {"id": "5001", "name": "5001"},
    {"id": "5002", "name": "5002"},
    {"id": "5701", "name": "5701 (LAB)"},
]

# Admin accounts
admins = [
    {"id": "A001", "username": "chairman", "password": "chairman123", "type": "super_admin", "teacher_initial": None},
]
for i, t in enumerate(teachers):
    admins.append({
        "id": f"A{i+2:03d}",
        "username": t["initial"],
        "password": t["initial"].lower() + "123",
        "type": "teacher_admin",
        "teacher_initial": t["initial"],
    })

result = {
    "meta": {
        "version": "2.0.0",
        "updated_at": "2026-01-21T10:00:00+06:00",
        "tz": "Asia/Dhaka",
        "days_off": ["Fri"],
        "department": "Department of Educational Technology and Engineering",
        "university": "University of Frontier Technology, Bangladesh",
        "slot_labels": ["09:00-10:15", "10:15-11:30", "11:30-12:45", "12:45-13:30", "13:30-14:45"]
    },
    "teachers": teachers,
    "batches": batches,
    "courses": courses,
    "rooms": rooms,
    "students": [],
    "timetable": entries,
    "admins": admins,
}

with open('assets/data.json', 'w') as f:
    json.dump(result, f, indent=2)

print(f'\ndata.json written successfully!')
print(f'  Teachers: {len(teachers)}')
print(f'  Batches: {len(batches)}')
print(f'  Courses: {len(courses)}')
print(f'  Rooms: {len(rooms)}')
print(f'  Timetable entries: {len(entries)}')
print(f'  Admins: {len(admins)}')
