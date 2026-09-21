// Gallery shots. One file, one SVG per #document (`just gallery`).
#import "@local/roster:0.1.0": color-by, entry, timetable

// Preview fallback: plain preview targets paged output, where bare
// #document is an error. Bodies render inline there; bundle export still
// collects the elements untouched. (No `title:` args: SVG ignores metadata
// and they break this fallback.)
#show document: it => context if target() == "bundle" { it } else { it.body }

// Shared page size for every shot in this bundle.
#set page(width: 17cm, height: auto, margin: 8pt)
#set text(size: 9pt)

#document("normal.svg")[
  #timetable(
    n-slots: 4,
    slots: ("08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"),
    days: ("Monday", "Tuesday", "Wednesday"),
    warn-clashes: false,
    schedule: (
      Monday: (
        entry("Algorithms", "Dr. Carol", "CS-3A", slot: 0, room: "B2"),
        entry(
          "Databases",
          "Dr. Dave",
          "CS-3B",
          slot: 1,
          span: 1.5,
          room: "Lab-2",
        ),
        entry("Seminar", "TA Alex", "CS-3A", slot: 2.5, span: 0.5),
        entry("Networks", "TA Alex", "CS-3B", slot: 3, room: "Lab-1"),
      ),
      Tuesday: (
        entry("OS", "Potato", "CS-3A", slot: 0, span: 1.5),
        entry("OS", "Dr. SomeOneElse", "CS-3B", slot: 1.5, span: 1.5),
        entry("Seminar", "TA Alex", "CS-3A", slot: 3, span: 0.5),
      ),
      Wednesday: (
        entry("Compilers", "Dr. Simon", "CS-3A", slot: 0),
        entry("Databases", "Dr. Dave", "CS-4A", slot: 1, room: "Lab-2"),
        entry("Seminar", "TA Alex", "CS-3B", slot: 2, span: 0.5),
        entry("Networks", "TA Alex", "CS-3A", slot: 3),
      ),
    ),
  )
]

#document("conflict.svg")[
  #timetable(
    n-slots: 4,
    slots: ("08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"),
    days: ("Sunday", "Monday", "Tuesday"),
    schedule: (
      Sunday: (
        entry("Algorithms", "Dr. Carol", "CS-3A", slot: 0),
        entry("Databases", "Dr. Dave", "CS-3B", slot: 1, room: "Lab-2"),
        entry("Networks", "TA Alex", "CS-3A", slot: 3),
      ),
      Monday: (
        entry("Seminar", "TA Alex", "CS-3A", slot: 0, span: 0.5),
        entry("Databases", "Dr. Dave", "CS-3A", slot: 1, room: "Lab-1"),
        entry(
          "Compilers",
          "Dr. Simon",
          "CS-4A",
          slot: 1,
          span: 1.5,
          room: "Lab-1",
        ),
        entry("OS", "Dr. Simon", "CS-3B", slot: 3),
      ),
      Tuesday: (
        entry("OS", "Dr. Simon", "CS-3A", slot: 0, span: 1.5),
        entry("OS", "Dr. Simon", "CS-3B", slot: 1.5, span: 1.5),
        entry("Seminar", "TA Alex", "CS-3A", slot: 3, span: 0.5),
      ),
    ),
  )
]

#document("focus.svg")[
  #timetable(
    n-slots: 4,
    slots: ("08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"),
    days: ("Monday", "Tuesday", "Wednesday"),
    warn-clashes: false,
    focus: (prof: "Dr. Simon"),
    schedule: (
      Monday: (
        entry("Compilers", "Dr. Simon", "CS-4A", slot: 0, span: 2),
        entry("Networks", "TA Alex", "CS-3A", slot: 2, room: "Lab-1"),
        entry("Databases", "Dr. Dave", "CS-3B", slot: 3),
      ),
      Tuesday: (
        entry("OS", "Dr. Simon", "CS-3A", slot: 0, span: 1.5),
        entry("OS", "Dr. Simon", "CS-3B", slot: 1.5, span: 1.5),
        entry("Seminar", "TA Alex", "CS-3A", slot: 3, span: 0.5),
      ),
      Wednesday: (
        entry("Algorithms", "Dr. Carol", "CS-3A", slot: 0),
        entry("Databases", "Dr. Dave", "CS-3B", slot: 1),
        entry("Compilers", "Dr. Simon", "CS-4A", slot: 2, span: 2),
      ),
    ),
  )
]

#document("overlap.svg")[
  #timetable(
    n-slots: 4,
    slots: ("08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"),
    days: ("Monday", "Tuesday", "Wednesday"),
    warn-clashes: false,
    schedule: (
      Monday: (
        entry("Algorithms", "Dr. Carol", "CS-3A", slot: 0),
        entry(
          "Databases",
          "Dr. Dave",
          "CS-3B",
          slot: 1,
          span: 2,
          room: "Lab-2",
        ),
        entry("Networks", "TA Alex", "CS-3A", slot: 3),
      ),
      Tuesday: (
        entry("Seminar", "TA Alex", "CS-3A", slot: 0.5, span: 0.5),
        entry(
          "Networks",
          "Dr. Dave",
          "CS-3B",
          slot: 0.7,
          span: 0.5,
          room: "Lab-1",
        ),
        entry("OS", "Dr. Simon", "CS-3A", slot: 2, span: 2),
      ),
      Wednesday: (
        entry("OS", "Dr. Simon", "CS-3A", slot: 0, span: 1.5),
        entry("OS", "Dr. Simon", "CS-3B", slot: 1.5, span: 1.5),
        entry("Compilers", "Dr. Simon", "CS-4A", slot: 3),
      ),
    ),
  )
]

#document("palette.svg")[
  #timetable(
    n-slots: 4,
    slots: ("08:00-09:00", "09:00-10:00", "10:00-11:00", "11:00-12:00"),
    days: ("Monday", "Tuesday", "Wednesday"),
    warn-clashes: false,
    palette: (Algorithms: red, OS: blue),
    schedule: (
      Monday: (
        entry("Algorithms", "Dr. Carol", "CS-3A", slot: 0),
        entry("Databases", "Dr. Dave", "CS-3B", slot: 1),
        entry("Networks", "TA Alex", "CS-3A", slot: 2),
        entry("Seminar", "TA Alex", "CS-3B", slot: 3, span: 0.5),
      ),
      Tuesday: (
        entry("OS", "Dr. Simon", "CS-3A", slot: 0, span: 1.5),
        entry("OS", "Dr. Simon", "CS-3B", slot: 1.5, span: 1.5),
        entry("Gym", slot: 3, color: green),
      ),
      Wednesday: (
        entry("Databases", "Dr. Dave", "CS-3A", slot: 0),
        entry("Algorithms", "Dr. Carol", "CS-3B", slot: 1),
        entry("Seminar", "TA Alex", "CS-3A", slot: 2, span: 0.5),
        entry("OS", "Dr. Simon", "CS-3A", slot: 3),
      ),
    ),
  )
]
