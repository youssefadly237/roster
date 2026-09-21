// render.typ
// Grid model: each slot is refined into `subdiv` sub-cells, where `subdiv`
// is the smallest common denominator of all slot/span fractions in the
// schedule (auto-detected, override with `subdiv:`). Entries are snapped to
// integer grid columns and merged back with `colspan`.
//
// A day with overlapping entries is split into lane sub-rows (greedy
// interval partitioning): every entry keeps its own box at its own span,
// overlapping entries land on different lanes, and the day label spans all
// lanes via `rowspan`. Entries with no overlap at all stretch over the full
// day height. Entries that share a scarce resource with a time-overlapping
// entry get the red clash outline.

#import "types.typ": (
  _is-near-int, auto-subdiv, color-by as _color-by, default-palette, to-grid,
)
#import "palette.typ": build-palette, resolve-color
#import "clashes.typ": format-clashes, format-clashes-full

// Default cell renderer

#let default-render-entry(e, show-prof, show-room, show-group) = {
  let parts = ()
  if e.subject != none { parts.push([*#e.subject*]) }
  if show-prof and e.prof != none { parts.push([#e.prof]) }
  if show-group and e.group != none { parts.push(emph(e.group)) }
  if show-room and e.room != none { parts.push([#e.room]) }
  // Optional `note` field (see `entry`). Other extras need a custom renderer.
  let note = e.at("note", default: none)
  if note != none {
    parts.push(text(size: 0.85em, style: "italic", fill: luma(60))[#note])
  }
  parts.join([\ ])
}

// Overlap helpers

#let _overlap(a, b) = {
  a.slot < (b.slot + b.span) and b.slot < (a.slot + a.span)
}

/// Indices of entries that share a scarce resource (group / prof / room)
/// with another time-overlapping entry. Those get the red clash outline;
/// plain time-overlaps (e.g. parallel groups) render as neutral boxes.
#let _clash-idx(entries) = {
  let hit = ()
  let n = entries.len()
  for i in range(n) {
    for j in range(i + 1, n) {
      let a = entries.at(i)
      let b = entries.at(j)
      if _overlap(a, b) {
        for f in ("group", "prof", "room") {
          let va = a.at(f, default: none)
          let vb = b.at(f, default: none)
          if va != none and va == vb {
            if not (i in hit) { hit.push(i) }
            if not (j in hit) { hit.push(j) }
            break
          }
        }
      }
    }
  }
  hit
}

/// Indices of entries that time-overlap at least one other entry,
/// regardless of shared resources. Entries with no overlap stretch over
/// the full day height instead of leaving blank space on other lanes.
#let _overlap-idx(entries) = {
  let hit = ()
  let n = entries.len()
  for i in range(n) {
    for j in range(i + 1, n) {
      if _overlap(entries.at(i), entries.at(j)) {
        if not (i in hit) { hit.push(i) }
        if not (j in hit) { hit.push(j) }
      }
    }
  }
  hit
}

// Greedy lane assignment: each item takes the first lane whose last item
// ends at or before its start, so touching intervals share a lane and
// overlapping ones split. Input must be sorted by start.
#let _lanes(sorted-items) = {
  let lanes = ()
  for it in sorted-items {
    let done = false
    let next = ()
    for lane in lanes {
      if not done and it.start >= lane.last().end {
        next.push(lane + (it,))
        done = true
      } else {
        next.push(lane)
      }
    }
    if not done { next.push((it,)) }
    lanes = next
  }
  lanes
}

// Row renderer

#let _day-row(
  day,
  entries,
  n-slots,
  subdiv,
  discriminator,
  palette-dict,
  show-prof,
  show-room,
  show-group,
  render-entry,
  focus-map,
) = {
  let total = n-slots * subdiv

  let grid = entries
    .enumerate()
    .map(((idx, e)) => {
      let (s, en) = to-grid(e.slot, e.span, subdiv)
      assert(s >= 0, message: "timetable: entry slot < 0 on " + day)
      assert(
        en <= total,
        message: "timetable: entry on "
          + day
          + " exceeds n-slots "
          + "(slot "
          + str(e.slot)
          + " + span "
          + str(e.span)
          + " > "
          + str(n-slots)
          + ")",
      )
      (start: s, end: en, entry: e, idx: idx)
    })
    .sorted(key: it => it.start)
  let lanes = _lanes(grid)
  let clash = _clash-idx(entries)
  let nl = lanes.len()
  // Entries with no time-overlap at all stretch over the full day height.
  // (Greedy lane assignment always places those on lane 0.)
  let ov = _overlap-idx(entries)

  let rows = ()
  if lanes.len() == 0 {
    rows.push(table.cell(
      align: center + horizon,
      stroke: 0.5pt + luma(180),
    )[*#day*])
    rows.push(table.cell(
      colspan: total,
      fill: none,
      stroke: 0.5pt + luma(200),
    )[])
    return rows
  }

  // Grid intervals already covered by a full-height cell above.
  // Lower lanes skip these columns instead of emitting cells there.
  let spans = ()
  for (li, lane) in lanes.enumerate() {
    let row = ()
    if li == 0 {
      row.push(table.cell(
        rowspan: lanes.len(),
        align: center + horizon,
        stroke: 0.5pt + luma(180),
      )[*#day*])
    }
    // Walk lane items and covered intervals left to right as one segment
    // list. Covered intervals never intersect lane items: a full-height
    // cell only exists where nothing overlaps.
    let segs = lane.map(it => (start: it.start, end: it.end, it: it))
    if li > 0 {
      for s in spans { segs.push((start: s.start, end: s.end, it: none)) }
      segs = segs.sorted(key: s => s.start)
    }
    // Gap cells skip borders toward other lanes, so vacant stretches stay
    // seamless. Entries draw their own outline; outer frame always kept.
    let gap-stroke = (
      left: 0.5pt + luma(200),
      right: 0.5pt + luma(200),
      top: if li == 0 { 0.5pt + luma(200) } else { none },
      bottom: if li == nl - 1 { 0.5pt + luma(200) } else { none },
    )
    let col = 0
    for s in segs {
      if s.start > col {
        row.push(table.cell(
          colspan: s.start - col,
          fill: none,
          stroke: gap-stroke,
        )[])
      }
      if s.it == none {
        col = s.end
      } else {
        let it = s.it
        let e = it.entry
        let body = render-entry(e, show-prof, show-room, show-group)
        let dimmed = false
        for (field, allowed) in focus-map {
          if not (e.at(field, default: none) in allowed) {
            dimmed = true
            break
          }
        }
        let body = if dimmed { text(fill: luma(110))[#body] } else { body }
        let full-height = li == 0 and not (it.idx in ov)
        if full-height { spans.push((start: it.start, end: it.end)) }
        let rs = if full-height { nl } else { 1 }
        if it.idx in clash {
          // Cell strokes get painted over by neighbors, so the red outline
          // is an inner rect to stay visible on all four sides.
          row.push(table.cell(
            rowspan: rs,
            colspan: it.end - it.start,
            fill: none,
            align: center + horizon,
            stroke: 0.5pt + luma(180),
          )[#rect(
            width: 100%,
            fill: rgb("#f38ba8").lighten(40%),
            stroke: 1.5pt + rgb("#d20f39"),
            inset: 5pt,
          )[#align(center)[#body]]])
        } else if dimmed {
          row.push(table.cell(
            rowspan: rs,
            colspan: it.end - it.start,
            fill: luma(235),
            align: center + horizon,
            stroke: 0.5pt + luma(180),
          )[#body])
        } else {
          row.push(table.cell(
            rowspan: rs,
            colspan: it.end - it.start,
            fill: resolve-color(e, discriminator, palette-dict),
            align: center + horizon,
            stroke: 0.5pt + luma(180),
          )[#body])
        }
        col = it.end
      }
    }
    if col < total {
      row.push(table.cell(
        colspan: total - col,
        fill: none,
        stroke: gap-stroke,
      )[])
    }
    rows += row
  }

  rows
}


// Header row

#let _header-row(slots, n-slots, subdiv) = {
  assert(
    slots.len() == n-slots,
    message: "timetable: slots.len() must equal n-slots, got "
      + str(slots.len())
      + " vs "
      + str(n-slots),
  )
  let cells = (
    table.cell(
      align: center + horizon,
      fill: luma(230),
      stroke: 0.5pt + luma(180),
    )[],
  )
  for label in slots {
    cells.push(table.cell(
      colspan: subdiv,
      align: center + horizon,
      fill: luma(230),
      stroke: 0.5pt + luma(180),
    )[*#label*])
  }
  cells
}

// Public API

/// Build the timetable grid.
///
/// `slots` labels the columns, `days` the rows, `schedule` maps each day to
/// its entries, and `n-slots` is the column count. Days with overlapping
/// entries split into lane sub-rows; entries sharing a group, prof or room
/// with an overlapping entry get a red outline and a clash report prints
/// below the table (`clash-report: "easy"` bullets by default, `"full"`
/// raw dump, `warn-clashes: false` hides it).
///
/// `color-by` picks the fill field. `palette` is an array (first-seen
/// order, wraps) or a dict pinning colors by name: `(Math: red)`. `color:`
/// on an entry beats everything: `entry("Math", slot: 0, color: red)`.
/// `show-prof/room/group` toggle cell
/// lines, `render-entry` overrides cell content, and `subdiv` overrides
/// the auto-detected grid refinement (see `auto-subdiv`). `focus` dims
/// everything outside one teacher, group, subject or room, e.g.
/// `focus: (prof: "Dr. Simon")`. Lists focus several of the same field
/// (`focus: (prof: ("Dr. Simon", "TA Alex"))`) and several fields combine
/// with AND. Clash outlines still apply to dimmed entries.
///
/// Example:
///   timetable(
///     slots: ("08:00-09:00", "09:00-10:00"),
///     days: ("Monday",),
///     n-slots: 2,
///     schedule: (Monday: (entry("Math", "Dr. Carol", "CS-3A", slot: 0),)),
///   )
#let timetable(
  slots: none,
  days: none,
  schedule: none,
  n-slots: none,
  color-by: _color-by.subject,
  palette: default-palette,
  show-prof: true,
  show-room: true,
  show-group: true,
  warn-clashes: true,
  render-entry: default-render-entry,
  subdiv: auto,
  max-subdiv: 12,
  clash-report: "easy",
  focus: none,
) = {
  assert(slots != none, message: "timetable: slots is required")
  assert(days != none, message: "timetable: days is required")
  assert(schedule != none, message: "timetable: schedule is required")
  assert(n-slots != none, message: "timetable: n-slots is required")

  let div = if subdiv == auto {
    auto-subdiv(schedule, max-subdiv: max-subdiv)
  } else {
    assert(
      type(subdiv) == int and subdiv >= 1,
      message: "timetable: subdiv must be a positive integer, got "
        + repr(subdiv),
    )
    for (_, entries) in schedule {
      for e in entries {
        assert(
          _is-near-int(e.slot * subdiv)
            and _is-near-int((e.slot + e.span) * subdiv),
          message: "timetable: subdiv "
            + str(subdiv)
            + " does not fit "
            + "slot "
            + str(e.slot)
            + " span "
            + str(e.span)
            + " (try a multiple of the auto-detected refinement)",
        )
      }
    }
    subdiv
  }

  let palette-dict = build-palette(schedule, color-by, palette)
  let col-sizes = (auto,) + (1fr,) * (n-slots * div)
  let header-cells = _header-row(slots, n-slots, div)

  // Personal view: `focus: (prof: "Dr. Simon")` dims every entry outside
  // the focus. Values take lists for several of the same field:
  // `focus: (prof: ("Dr. Simon", "TA Alex"))`. Several fields combine
  // with AND: `focus: (prof: "Dr. Simon", group: "CS-3A")`.
  let focus-map = if focus == none { (:) } else {
    assert(
      type(focus) == dictionary and focus.keys().len() >= 1,
      message: "timetable: focus must be a dict like "
        + "(prof: \"Dr. Simon\"), got "
        + repr(focus),
    )
    let fields = ("subject", "prof", "group", "room")
    let out = (:)
    for (field, value) in focus {
      assert(
        field in fields,
        message: "timetable: focus field must be subject, prof, group or "
          + "room, got "
          + repr(field),
      )
      let allowed = if type(value) == array { value } else { (value,) }
      assert(
        allowed.len() >= 1,
        message: "timetable: focus value list must not be empty, got "
          + repr(field),
      )
      out.insert(field, allowed)
    }
    out
  }
  let day-cells = ()
  for day in days {
    let entries = schedule.at(day, default: ())
    day-cells += _day-row(
      day,
      entries,
      n-slots,
      div,
      color-by,
      palette-dict,
      show-prof,
      show-room,
      show-group,
      render-entry,
      focus-map,
    )
  }

  assert(
    clash-report == "easy" or clash-report == "full",
    message: "timetable: clash-report must be \"easy\" or \"full\", got "
      + repr(clash-report),
  )

  show table.cell: it => {
    set text(hyphenate: true)
    it
  }

  table(
    columns: col-sizes,
    stroke: 0.5pt + luma(180),
    inset: (x: 5pt, y: 4pt),
    ..header-cells,
    ..day-cells,
  )

  let clash-content = if warn-clashes {
    if clash-report == "full" { format-clashes-full(schedule) } else {
      format-clashes(schedule, slots: slots)
    }
  } else { none }

  if clash-content != none {
    parbreak()
    clash-content
  }
}
