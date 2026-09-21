// types.typ

#let default-palette = (
  rgb("#89b4fa"),
  rgb("#a6e3a1"),
  rgb("#fab387"),
  rgb("#f38ba8"),
  rgb("#cba6f7"),
  rgb("#94e2d5"),
  rgb("#f9e2af"),
  rgb("#89dceb"),
  rgb("#b4befe"),
  rgb("#eba0ac"),
  rgb("#a6adc8"),
  rgb("#f2cdcd"),
)

#let color-by = (
  off: "off",
  subject: "subject",
  prof: "prof",
  group: "group",
  room: "room",
)

/// Construct a timetable entry.
///
/// `slot` and `span` are in slot units (`slot: 0` is the first slot,
/// `span: 1` is one slot). Halves, thirds, quarters and other fractions all
/// work: the grid refines to the smallest common denominator of the whole
/// schedule (see `auto-subdiv`) and merges cells with `colspan`.
///
/// Only `slot` is required. Subject, prof, group, room and color default to
/// none and `span` defaults to 1. Missing fields are skipped when rendering,
/// ignored by the palette, and never clash.
///
/// A `note` field is shown by the default renderer as a small italic line
/// under the entry (content or plain string). Any other extra fields are
/// stored untouched for custom `render-entry` functions.
///
/// Examples:
///   entry("Math", "Dr. Carol", "CS-3A", slot: 0)
///   entry("Math", slot: 1, span: 1.5, room: "B2", note: [Quiz week])
///   entry(slot: 2, room: "Lab-1")
#let entry(..args) = {
  // Subject/prof/group stay positional-friendly but optional. Typst rejects
  // positionals on default-valued params (and `..extra` would swallow them
  // silently), so the first three positionals are mapped by hand; an
  // explicit named argument wins.
  let pos = args.pos()
  let named = args.named()
  assert(
    pos.len() <= 3,
    message: "entry: at most 3 positional arguments (subject, prof, group), got "
      + str(pos.len()),
  )
  let subject = named.at("subject", default: if pos.len() > 0 {
    pos.at(0)
  } else { none })
  let prof = named.at("prof", default: if pos.len() > 1 { pos.at(1) } else {
    none
  })
  let group = named.at("group", default: if pos.len() > 2 { pos.at(2) } else {
    none
  })
  let slot = named.at("slot", default: none)
  let span = named.at("span", default: 1)
  let room = named.at("room", default: none)
  let color = named.at("color", default: auto)

  assert(slot != none, message: "entry: slot is required")
  assert(
    type(slot) == int or type(slot) == float,
    message: "entry: slot must be a number (in slot units), got " + repr(slot),
  )
  assert(
    type(span) == int or type(span) == float,
    message: "entry: span must be a number (in slot units), got " + repr(span),
  )
  assert(slot >= 0, message: "entry: slot must be >= 0, got " + str(slot))
  assert(span > 0, message: "entry: span must be > 0, got " + str(span))

  let known = ("subject", "prof", "group", "slot", "span", "room", "color")
  let extra = (:)
  for (k, v) in named {
    if not (k in known) { extra.insert(k, v) }
  }

  (
    (
      subject: subject,
      prof: prof,
      group: group,
      room: room,
      slot: slot,
      span: span,
      color: color,
    )
      + extra
  )
}

// Grid helpers
// The renderer refines each slot into `subdiv` sub-cells (the smallest common
// denominator of the schedule) and merges them back with `colspan`.
// slot s with span p occupies grid columns [round(s*subdiv), round((s+p)*subdiv)).

/// True if `x` is within `eps` of an integer (tolerates float error).
#let _is-near-int(x, eps: 1e-6) = calc.abs(x - calc.round(x)) < eps

/// Find the smallest grid refinement `subdiv` in 1..max-subdiv such that
/// every `slot` and every `slot + span` in the schedule lands on a grid line.
/// Returns 1 for an empty schedule.
#let auto-subdiv(schedule, max-subdiv: 12, eps: 1e-6) = {
  let vals = ()
  for (_, entries) in schedule {
    for e in entries {
      vals.push(e.slot)
      vals.push(e.slot + e.span)
    }
  }
  if vals.len() == 0 { return 1 }
  for subdiv in range(1, max-subdiv + 1) {
    let ok = true
    for v in vals {
      if not _is-near-int(v * subdiv, eps: eps) {
        ok = false
        break
      }
    }
    if ok { return subdiv }
  }
  assert(
    false,
    message: "timetable: schedule needs subdiv > "
      + str(max-subdiv)
      + ": slots/spans have incompatible fractions. Pass a larger max-subdiv"
      + " or round slots/spans to a coarser granularity.",
  )
}

/// Snap `slot`/`span` to integer grid columns for a given `subdiv`.
/// Returns (start, end) with 0 <= start < end.
#let to-grid(slot, span, subdiv) = {
  let start = int(calc.round(slot * subdiv))
  let end = int(calc.round((slot + span) * subdiv))
  assert(
    end > start,
    message: "entry: span too small for subdiv "
      + str(subdiv)
      + " (slot "
      + str(slot)
      + ", span "
      + str(span)
      + ")",
  )
  (start, end)
}
