# Symbology — architecture

## Structure

- `lib/symbology/symbology/` — what each family *is*: how many digits, which
  tables, which bars are long, what is printed where.
- `lib/symbology/pattern.rb` — the output of an encoding and the input to a
  renderer, measured entirely in modules.
- `lib/symbology/geometry.rb` — the one place a module becomes a pixel, so both
  formats lay a symbol out identically.
- `lib/symbology/renderer/` — SVG and PNG.
- `lib/symbology/canvas.rb` — the PNG writer, against the specification: a header,
  a two-entry palette, one deflated block of rows, a terminator.
- `lib/symbology/font.rb` — ten five-by-seven digits, because there is no font on
  the other side of a PNG.

## Key decisions

**No dependencies, and never any.** The only thing Symbology needs that it does
not do itself is zlib, to deflate a PNG's image data, and that ships with Ruby.
It draws its own digits rather than depend on an imaging library for ten glyphs.
That constraint is the point of the gem, not an accident of its history.

**A bad check digit is refused, not drawn.** Every symbology here ends in a
digit computed from the ones before it. A code that fails it was mistyped,
mis-scanned or invented, and the symbol drawn from it is a picture no scanner
will read back — worse than no picture, because it looks like it works.
`Symbology.encode` raises `Symbology::InvalidCheckDigit` instead.

**The symbology is inferred, never asked for.** Which family a value belongs to
depends only on how many digits it has, so callers never have to say.

**One place turns a module into a pixel.** `geometry.rb` is shared by both
renderers, so an SVG and a PNG of the same code lay out identically rather than
drifting apart as each format grows its own arithmetic.

**No I/O.** Digits in, string out. What you do with the bytes — write them,
inline them, serve them as a data URL — is yours.
