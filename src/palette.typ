// palette.typ
// Builds a (field-value -> color) dictionary from all entries in a schedule.

#import "types.typ": color-by as _color-by, default-palette

/// Map each used value of the color-by field to a color.
///
/// `palette` is either an array (values take colors in first-seen order,
/// wrapping around) or a dict mapping values to colors by name, e.g.
/// `(Math: red, Phys: blue)`. Named entries always win, so a subject keeps
/// its color no matter the entry order; unmapped values fall back to
/// `default-palette` in first-seen order. Dict keys must be strings
/// matching the color-by field. Returns (:) when color-by is `off`.
#let build-palette(schedule, discriminator, palette) = {
  if discriminator == _color-by.off { return (:) }

  let values = ()
  for (_, entries) in schedule {
    for e in entries {
      let v = e.at(discriminator, default: none)
      if v != none and not (v in values) {
        values.push(v)
      }
    }
  }

  let fixed = if type(palette) == dictionary { palette } else { (:) }
  let auto-colors = if type(palette) == dictionary {
    default-palette
  } else {
    palette
  }

  let out = (:)
  for (k, v) in fixed { out.insert(k, v) }
  let n = auto-colors.len()
  let i = 0
  for v in values {
    if not (v in out) {
      out.insert(v, auto-colors.at(calc.rem(i, n)))
      i += 1
    }
  }
  out
}

/// Resolve the fill color for a single entry given a pre-built palette dict
/// and the discriminator field name. An explicit entry.color always wins.
#let resolve-color(entry, discriminator, palette-dict) = {
  if entry.color != auto { return entry.color }
  if discriminator == _color-by.off { return none }
  let v = entry.at(discriminator, default: none)
  if v == none { return none }
  palette-dict.at(v, default: none)
}
