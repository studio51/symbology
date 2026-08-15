require "test_helper"

# Covers the drawing half of Symbology: the SVG, the PNG, and the
# options both take.
#
# The assertion that matters most is the round trip — the modules are read back
# out of the rendered PNG's pixels and compared to the pattern that produced
# them. Everything else here checks the picture is well formed; that one checks
# it still says the number.
#
class RenderingTest < Minitest::Test
  VALUE = "5901234123457".freeze

  # --- SVG -------------------------------------------------------------------

  test "an SVG is the size the geometry says" do
    svg = Symbology.svg(VALUE)

    # (11 left quiet + 95 symbol + 7 right quiet) modules at 2px, and 60px of
    # bars over a 9-module text band.
    #
    assert_includes svg, %(width="226" height="78")
    assert_includes svg, %(viewBox="0 0 226 78")
  end

  test "an SVG draws one rectangle per bar, plus the paper" do
    pattern = Symbology.encode(VALUE)
    svg     = Symbology.svg(VALUE)

    assert_equal pattern.bars.length + 1, svg.scan("<rect").length
  end

  test "an SVG names the symbol for anything that cannot see it" do
    assert_includes Symbology.svg(VALUE), %(aria-label="EAN-13 barcode 5901234123457")
  end

  # An XML declaration is optional in a standalone .svg and read as a bogus
  # comment the moment the markup is inlined into a page — which is exactly what
  # the Vault landing page does with it.
  #
  test "an SVG opens with the symbol, so it can be inlined into a page" do
    assert Symbology.svg(VALUE).start_with?("<svg ")
  end

  test "an SVG prints every digit, and none when asked not to" do
    printed = Symbology.svg(VALUE).scan(%r{<text[^>]*>(\d)</text>}).flatten.join

    assert_equal VALUE, printed
    assert_not_includes Symbology.svg(VALUE, text: false), "<text"
  end

  test "an SVG without text is only as tall as its bars" do
    assert_includes Symbology.svg(VALUE, text: false, height: 40), %(height="40")
  end

  test "an SVG takes its colours and its font" do
    svg = Symbology.svg(VALUE, foreground: "#1f2937", font_family: "Inter")

    assert_includes svg, %(fill="#1f2937")
    assert_includes svg, %(font-family="Inter")
  end

  test "a transparent SVG has no paper at all" do
    assert_not_includes Symbology.svg(VALUE, background: nil), "<rect width=\"226\""
    assert_includes Symbology.svg(VALUE), %(fill="#FFFFFF")
  end

  test "a fractional module width is written out, not rounded" do
    assert_includes Symbology.svg(VALUE, module_width: 1.5), %(width="169.5")
  end

  # --- PNG -------------------------------------------------------------------

  test "a PNG is a PNG" do
    png = Symbology.png(VALUE)

    assert_equal [ 137, 80, 78, 71, 13, 10, 26, 10 ].pack("C*"), png[0, 8]
    assert_equal Encoding::BINARY, png.encoding
  end

  test "a PNG is the size the geometry says" do
    header = png_header(Symbology.png(VALUE))

    # 113 modules at 3px, and 60px of bars over a 9-module text band.
    #
    assert_equal 339, header[:width]
    assert_equal 87,  header[:height]
    assert_equal 1,   header[:bit_depth]
    assert_equal 3,   header[:colour_type]
  end

  # The picture has to say what the pattern says. Sampling a row of pixels back
  # into modules is the only assertion that checks the whole chain — encoding,
  # geometry, rasterising, bit packing and deflating — against the one thing that
  # matters about a barcode, which is that a scanner reads the number back.
  #
  test "the modules read back out of the pixels are the modules that went in" do
    pattern = Symbology.encode(VALUE)
    pixels  = png_pixels(Symbology.png(VALUE))

    read = (0...pattern.width).map do |index|
      # The middle of the module, in the middle of the bars, at 3px a module and
      # 11 modules of left quiet zone.
      #
      pixels[10][((index + 11) * 3) + 1]
    end

    assert_equal pattern.to_s, read.join
  end

  test "a PNG scales by whole pixels, because half a bar is a different digit" do
    header = png_header(Symbology.png(VALUE, module_width: 2.4, height: 40.6))

    assert_equal 226, header[:width]  # 113 modules at 2px
    assert_equal 59,  header[:height] # 41px of bars over a 9-module text band
  end

  test "a PNG carries its colours in a two-entry palette" do
    png = Symbology.png(VALUE, foreground: "#123", background: "#ffffff")

    assert_equal [ 255, 255, 255, 17, 34, 51 ], png_chunk(png, "PLTE").bytes
  end

  test "a transparent PNG says so, and an opaque one doesn't" do
    assert_equal [ 0 ], png_chunk(Symbology.png(VALUE, background: nil), "tRNS").bytes
    assert_nil png_chunk(Symbology.png(VALUE), "tRNS")
  end

  test "a PNG colour has to be a colour" do
    assert_raises(ArgumentError) { Symbology.png(VALUE, foreground: "rebeccapurple") }
  end

  # --- Options ---------------------------------------------------------------

  test "the quiet zones can be overridden, together or apart" do
    assert_equal 285, png_header(Symbology.png(VALUE, quiet_zone: 0))[:width]        # the 95-module symbol alone, at 3px
    assert_equal 303, png_header(Symbology.png(VALUE, quiet_zone: [ 4, 2 ]))[:width] # 101 modules at 3px
  end

  test "an option nobody has is a mistake, not a shrug" do
    error = assert_raises(ArgumentError) { Symbology.svg(VALUE, colour: "#000") }

    assert_match "unknown option: colour", error.message
  end

  test "a format nobody draws is refused by name" do
    error = assert_raises(Symbology::UnknownFormat) { Symbology.render(VALUE, format: :gif) }

    assert_match "svg or png", error.message
  end

  test "an undrawable code is refused before anything is drawn" do
    assert_raises(Symbology::InvalidCheckDigit) { Symbology.svg("5901234123456") }
    assert_raises(Symbology::UnsupportedValue) { Symbology.png("12345") }
  end

  test "each format knows what to be served as" do
    assert_equal "image/svg+xml", Symbology.mime_type(:svg)
    assert_equal "image/png", Symbology.mime_type("png")
  end

  private

  # --- Reading a PNG back ----------------------------------------------------

  # The header a PNG opens with.
  #
  # @param png [String] the image.
  #
  # @return [Hash] its width, height, bit depth and colour type.
  #
  def png_header(png)
    width, height, depth, colour = png_chunk(png, "IHDR").unpack("N2C2")

    { width:, height:, bit_depth: depth, colour_type: colour }
  end

  # A PNG's pixels, one row of palette indices per line.
  #
  # Only has to understand what Symbology writes: one bit a pixel, filter type 0
  # on every row.
  #
  # @param png [String] the image.
  #
  # @return [Array<Array<Integer>>] the rows.
  #
  def png_pixels(png)
    header = png_header(png)
    stride = ((header[:width] + 7) / 8) + 1
    raw    = Zlib::Inflate.inflate(png_chunk(png, "IDAT"))

    raw.bytes.each_slice(stride).map do |row|
      row.drop(1).flat_map { |byte| 7.downto(0).map { |bit| (byte >> bit) & 1 } }.first(header[:width])
    end
  end

  # The payload of the first chunk of a type.
  #
  # @param png [String] the image.
  # @param type [String] the four-character chunk type.
  #
  # @return [String, nil] the payload, or nil when the image carries no such chunk.
  #
  def png_chunk(png, type)
    offset = 8 # past the signature

    while offset < png.bytesize
      length = png[offset, 4].unpack1("N")
      name   = png[offset + 4, 4]

      return png[offset + 8, length] if name == type

      offset += 12 + length # length, type, payload and checksum
    end

    nil
  end
end
