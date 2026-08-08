# Barcoder

> The number on the back of the box, drawn as the barcode it was printed as.

Barcoder is a self-contained Ruby gem. It currently lives in-tree at
`gems/barcoder` inside games.directory and is loaded as a path gem; it depends on
nothing in that application — or on any other gem — so extracting it is a
directory move.

```ruby
Barcoder.svg("5901234123457")             #=> "<?xml version=\"1.0\"…"
Barcoder.png("5901234123457", height: 40) #=> "\x89PNG\r\n…"
```

## What it draws

| Symbology | Digits | Where it turns up |
| --------- | ------ | ----------------- |
| EAN-13    | 13     | Every game sold outside North America |
| UPC-A     | 12     | North American releases |
| EAN-8     | 8      | Boxes too small for a full EAN-13, and the things inside them |

Which one a value is depends only on how many digits it has, so you never have
to say:

```ruby
Barcoder.symbology_for("036000291452") #=> Barcoder::Symbology::UPCA
Barcoder.symbology_for("96385074")     #=> Barcoder::Symbology::EAN8
```

## What it refuses to draw

A code that fails its own check digit.

Every symbology here ends in a digit computed from the ones before it. A code
that fails it was mistyped, mis-scanned or invented, and the symbol drawn from it
is a picture no scanner will read back — worse than no picture, because it looks
like it works. `Barcoder.encode` raises `Barcoder::InvalidCheckDigit` rather than
draw one.

Ask first if you hold numbers of uncertain provenance:

```ruby
Barcoder.encodable?("5901234123457") #=> true
Barcoder.encodable?("5901234123456") #=> false — check digit should be 7
Barcoder.encodable?("DOOM")          #=> false
```

## Options

Both formats take the same ones:

| Option         | Default     | |
| -------------- | ----------- | - |
| `module_width` | `2` (SVG), `3` (PNG) | What the narrowest bar is worth, in pixels. |
| `height`       | `60`        | How tall the **bars** are. The printed digits are added below that. |
| `text`         | `true`      | Print the digits under the symbol. |
| `foreground`   | `"#000000"` | The bars and the digits. |
| `background`   | `"#FFFFFF"` | The paper. `nil` leaves it transparent. |
| `quiet_zone`   | `nil`       | Override the standard's margins, in modules. One number, or a `[left, right]` pair. |

SVG also takes `font_family` (default `"monospace"`).

The defaults are the proportions a printed symbol has: guard bars descending
through the text band, the digits set in the gaps between them, the leading digit
of an EAN-13 in the left quiet zone, and — on a UPC-A — the number-system and
check digits outside the bars with their own bars extended to match the guards.

```ruby
Barcoder.png("5901234123457", module_width: 4, height: 120, background: nil)
Barcoder.svg("5901234123457", text: false, foreground: "#1f2937")
```

### A module has to be a whole number of pixels

In a raster it does, anyway. Half a pixel of bar is either rounded away or
smeared across two, and a bar of the wrong width is a digit of a different value
— so the PNG renderer rounds `module_width` and `height` to whole pixels itself
rather than leave it to chance. The SVG renderer doesn't have the problem and
doesn't round.

That is also why the PNG is drawn one bit per pixel through a two-colour palette:
every pixel is exactly the colour asked for, nothing is anti-aliased, and a whole
symbol is well under a kilobyte.

## Reading the code

- `lib/barcoder/symbology/` — what each family *is*: how many digits, which
  tables, which bars are long, what is printed where.
- `lib/barcoder/pattern.rb` — the output of an encoding and the input to a
  renderer, measured entirely in modules.
- `lib/barcoder/geometry.rb` — the one place a module becomes a pixel, so both
  formats lay a symbol out identically.
- `lib/barcoder/renderer/` — SVG and PNG.
- `lib/barcoder/canvas.rb` — the PNG writer, against the specification: a header,
  a two-entry palette, one deflated block of rows, a terminator.
- `lib/barcoder/font.rb` — ten five-by-seven digits, because there is no font on
  the other side of a PNG.

## Tests

The gem's tests live with the host application's, at `test/lib/barcoder`, and
run with the rest of the suite:

```sh
bin/rails test test/lib/barcoder
```

They assert the encodings against the reference patterns published for
`5901234123457`, `036000291452` and `96385074`, and read the modules back out of
a rendered PNG to check the picture says what the pattern does.

## License

Proprietary, © 2015–2026 Studio51 Solutions. All rights reserved.
