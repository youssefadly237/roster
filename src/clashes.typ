// clashes.typ
// Clash detection across three independent dimensions:
//   - group: same group double-booked at the same time
//   - prof:  same prof teaching two classes simultaneously
//   - room:  same room used by two classes simultaneously
//
// A clash dict: (day, kind, key, a, b)
//   day:  str  - which day
//   kind: str  - "group" | "prof" | "room"
//   key:  str  - the shared value (e.g. "CS-3A", "Dr. Carol", "Lab-2")
//   a:    entry dict
//   b:    entry dict

// Helpers

#let _overlaps(a, b) = {
  a.slot < (b.slot + b.span) and b.slot < (a.slot + a.span)
}

#let _check-field(entries, field) = {
  let found = ()
  let n = entries.len()
  for i in range(n) {
    for j in range(i + 1, n) {
      let a = entries.at(i)
      let b = entries.at(j)
      let va = a.at(field, default: none)
      let vb = b.at(field, default: none)
      if va != none and vb != none and va == vb and _overlaps(a, b) {
        found.push((va, a, b))
      }
    }
  }
  found
}

// Public API

/// Returns an array of clash dicts: (day, kind, key, a, b).
#let find-clashes(schedule) = {
  let clashes = ()
  for (day, entries) in schedule {
    for (kind, field) in (
      ("group", "group"),
      ("prof", "prof"),
      ("room", "room"),
    ) {
      for (key, a, b) in _check-field(entries, field) {
        clashes.push((day: day, kind: kind, key: key, a: a, b: b))
      }
    }
  }
  clashes
}

/// Overlap range (start, end) of two entries known to overlap.
#let _overlap-range(a, b) = {
  let s = if a.slot > b.slot { a.slot } else { b.slot }
  let ae = a.slot + a.span
  let be = b.slot + b.span
  let e = if ae < be { ae } else { be }
  (s, e)
}

#let _is-int(x) = calc.abs(x - calc.round(x)) < 1e-6

/// Human-readable "when" for an overlap: the slot's time label when the
/// overlap is exactly one whole slot, otherwise `slot X-Y`.
#let _when-str(slots, s, e) = {
  let show-num(x) = if _is-int(x) { str(int(calc.round(x))) } else { str(x) }
  if (
    _is-int(s)
      and _is-int(e)
      and e == s + 1
      and slots != none
      and s >= 0
      and s + 1 <= slots.len()
  ) {
    slots.at(int(calc.round(s)))
  } else {
    "slot " + show-num(s) + "-" + show-num(e)
  }
}

#let _entry-str(e) = {
  let name = if e.subject == none { "busy" } else { e.subject }
  let ctx = (e.group, e.prof).filter(v => v != none).map(v => [#v]).join([, ])
  if ctx == [] { [#name] } else { [#name (#ctx)] }
}

/// Easy-to-read clash report: one bullet per clash with day, slot and
/// conflict description. Returns none if no clashes found.
#let format-clashes(schedule, slots: none) = {
  let clashes = find-clashes(schedule)
  if clashes.len() == 0 { return none }
  let items = clashes.map(c => {
    let (s, e) = _overlap-range(c.a, c.b)
    [#c.day, #_when-str(slots, s, e): #c.kind "#c.key" -- #_entry-str(c.a) vs #_entry-str(c.b)]
  })
  let head = strong("Timetable clashes (" + str(clashes.len()) + "):")
  [#head #list(..items)]
}

/// Complete clash report: raw dump of every clash dict for debugging.
/// Returns none if no clashes found.
#let format-clashes-full(schedule) = {
  let clashes = find-clashes(schedule)
  if clashes.len() == 0 { return none }
  [#repr(clashes)]
}
