# frozen_string_literal: true

require "zlib"

require "barcoder/font"

module Barcoder

  # A two-colour raster, and the PNG it serialises to.
  #
  # Two colours is not a limitation being worked around — it is what a barcode
  # is. Which means the image can be written as a one-bit-per-pixel indexed PNG:
  # a whole symbol lands in well under a kilobyte, every pixel is exactly the
  # colour asked for, and there is no anti-aliasing to soften an edge a scanner
  # is trying to find.
  #
  # Written by hand against the PNG specification rather than through an imaging
  # library, because this is the entire format for this one case: a header, a
  # two-entry palette, one deflated block of rows and a terminator.
  #
  class Canvas
    SIGNATURE = [ 137, 80, 78, 71, 13, 10, 26, 10 ].pack("C*").freeze # the eight bytes that say "PNG"
    BIT_DEPTH = 1 # one bit per pixel: paper or ink
    COLOUR_TYPE = 3 # indexed, so the palette carries the two colours

    attr_reader :width  # the raster's width, in pixels
    attr_reader :height # the raster's height, in pixels

    # A row is held as a string of `0` and `1` characters rather than as an array
    # of pixels.
    #
    # Not a curiosity: it is what makes drawing and serialising a symbol string
    # operations instead of per-pixel Ruby ones. Inking a bar is one range
    # assignment, and packing a row into bits is `pack("B*")` — which is exactly
    # the transformation a one-bit PNG scanline needs, done in C. Drawing the
    # same symbol pixel by pixel costs about sixteen times as much — 18ms a
    # barcode against 1ms — which is the difference between a page of them being
    # free and being noticed.
    #
    # @param width [Integer] the raster's width, in pixels.
    # @param height [Integer] the raster's height, in pixels.
    #
    # @return [void]
    #
    def initialize(width, height)
      @width  = width.to_i
      @height = height.to_i
      @rows   = Array.new(@height) { "0" * @width }
    end

    # Inks a rectangle, clipped to the raster.
    #
    # @param x [Numeric] the left edge.
    # @param y [Numeric] the top edge.
    # @param width [Numeric] how wide.
    # @param height [Numeric] how tall.
    #
    # @return [void]
    #
    def rectangle(x, y, width, height)
      left   = [ x.round, 0 ].max
      top    = [ y.round, 0 ].max
      right  = [ x.round + width.round, @width ].min
      bottom = [ y.round + height.round, @height ].min

      return if right <= left || bottom <= top

      ink = "1" * (right - left)

      (top...bottom).each { |row| @rows[row][left, right - left] = ink }
    end

    # Inks a digit from {Barcoder::Font}.
    #
    # @param digit [String] a single character, `0` to `9`.
    # @param x [Numeric] the glyph's left edge.
    # @param y [Numeric] the glyph's top edge.
    # @param scale [Integer] how many pixels wide one font pixel is drawn.
    #
    # @return [void]
    #
    def glyph(digit, x, y, scale)
      rows = Font.glyph(digit)
      return if rows.nil?

      rows.each_with_index do |row, line|
        row.chars.each_with_index do |pixel, column|
          next unless pixel == "1"

          rectangle(x + (column * scale), y + (line * scale), scale, scale)
        end
      end
    end

    # Serialises the raster as a PNG.
    #
    # @param foreground [Array(Integer, Integer, Integer)] the ink's red, green and blue.
    # @param background [Array(Integer, Integer, Integer), nil] the paper's, or nil to leave it transparent.
    #
    # @return [String] the PNG, as binary.
    #
    def to_png(foreground:, background:)
      paper = background || [ 255, 255, 255 ]

      png = SIGNATURE.dup.b
      png << chunk("IHDR", [ width, height ].pack("N2") + [ BIT_DEPTH, COLOUR_TYPE, 0, 0, 0 ].pack("C5"))
      png << chunk("PLTE", (paper + foreground).pack("C6"))
      # Palette entry 0 is the paper, so one byte of alpha is the whole
      # transparency story: make the paper invisible and leave the ink alone.
      #
      png << chunk("tRNS", [ 0 ].pack("C")) if background.nil?
      png << chunk("IDAT", Zlib::Deflate.deflate(scanlines))
      png << chunk("IEND", "")

      png
    end

    private

    # The rows, filtered and packed the way an IDAT block wants them.
    #
    # Every row is prefixed with filter type 0 — none. The filters exist to make
    # photographic rows compress; a barcode row is a handful of long identical
    # runs, which deflate already handles about as well as it can be handled.
    #
    # `pack("B*")` packs the row's characters into bits most-significant first,
    # padding the last byte with zeroes — which is the bit order and the padding
    # a one-bit-per-pixel scanline is defined to use.
    #
    # @return [String] the raw image data.
    #
    def scanlines
      @rows.map { |row| "\x00".b + [ row ].pack("B*") }.join
    end

    # One PNG chunk: length, type, data, checksum.
    #
    # @param type [String] the four-character chunk type.
    # @param data [String] the chunk's payload.
    #
    # @return [String] the chunk, as binary.
    #
    def chunk(type, data)
      body = "#{ type }#{ data }".b

      [ data.bytesize ].pack("N") + body + [ Zlib.crc32(body) ].pack("N")
    end
  end
end
