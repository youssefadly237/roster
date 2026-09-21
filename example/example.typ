// example.typ
#import "@local/roster:0.1.0": color-by, entry, find-clashes, timetable

#set page(paper: "a3", flipped: true, margin: 1.5cm)
#set text(size: 9pt, font: "JetBrains Mono")


= Fictional CS Department - Spring 2026

#timetable(
  n-slots: 6,
  slots: (
    "08:00-09:00",
    "09:00-10:00",
    "10:00-11:00",
    "11:00-12:00",
    "13:00-14:00",
    "14:00-15:00",
  ),
  days: ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday"),
  color-by: color-by.group,
  show-prof: true,
  show-room: true,
  show-group: true,
  focus: (group: "CS-3A"),
  warn-clashes: true,
  schedule: (
    Sunday: (
      // Whole slot: 08:00-09:00
      entry("Algorithms", "Dr. Carol", "CS-3A", slot: 0),
      // 1.5 slots: 09:00-10:30
      entry(
        "Databases",
        "Dr. Dave",
        "CS-3B",
        slot: 1,
        span: 1.5,
        room: "Lab-2",
      ),
      // Half slot: 10:30-11:00
      entry("Seminar", "TA Alex", "CS-3A", slot: 2.5, span: 0.5),
      entry("Seminar", "TA Alex", "CS-3A", slot: 3.7, span: 0.5),
      // Whole slot at 13:00
      entry("Algorithms", "Dr. Carol", "CS-3B", slot: 4),
    ),
    Monday: (
      entry("Compilers", "Dr. Simon", "CS-4A", slot: 0, span: 2),
      entry("Networks", "TA Alex", "CS-3A", slot: 2, room: "Lab-1"),
      entry("Networks", "TA Alex", "CS-3B", slot: 3, room: "Lab-1"),
      // Intentional room clash to demo warning - same room, same time
      entry("Databases", "Dr. Dave", "CS-3A", slot: 4, room: "Lab-1"),
      entry(
        "Compilers",
        "Dr. Simon",
        "CS-4A",
        slot: 4,
        span: 1.5,
        room: "Lab-1",
      ),
    ),
    Tuesday: (
      entry("OS", "Dr. Simon", "CS-3A", slot: 0, span: 1.5),
      entry("OS", "Dr. Simon", "CS-3B", slot: 1.5, span: 1.5),
      entry("Algorithms", "Dr. Carol", "CS-4A", slot: 4, span: 2),
    ),
    Wednesday: (
      entry("Compilers", "Dr. Simon", "CS-3A", slot: 0),
      entry("Databases", "Dr. Dave", "CS-4A", slot: 1, room: "Lab-2"),
      entry("Seminar", "TA Alex", "CS-3B", slot: 2, span: 0.5),
      entry("Networks", "TA Alex", "CS-3A", slot: 4),
    ),
    Thursday: (
      entry("OS", "Dr. Simon", "CS-4A", slot: 0),
      entry("Algorithms", "Dr. Carol", "CS-3B", slot: 1, span: 0.5),
      entry(
        "Databases",
        "Dr. Dave",
        "CS-3A",
        slot: 1.5,
        span: 1.5,
        room: "Lab-2",
      ),
      entry("Compilers", "Dr. Simon", "CS-3B", slot: 4, span: 2),
    ),
  ),
)
