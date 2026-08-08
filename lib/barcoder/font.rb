# frozen_string_literal: true

module Barcoder

  # The digits, as bitmaps.
  #
  # A raster renderer has to draw its own text: there is no font on the other
  # side of a PNG, and pulling in a font library to print ten glyphs would make a
  # dependency-free gem depend on one for the least important part of the
  # picture.
  #
  # Ten digits is all that is needed, because every symbology here is numeric. So
  # the font is ten five-by-seven grids — legible at one pixel per module, and
  # sharp at any whole multiple of it, which no scalable font can promise.
  #
  module Font
    WIDTH = 5 # a glyph's width, in font pixels
    HEIGHT = 7 # a glyph's height, in font pixels

    # The glyphs, a row of the grid per string, `1` where the ink goes.
    #
    GLYPHS = {
      "0" => %w[01110 10001 10011 10101 11001 10001 01110].freeze,
      "1" => %w[00100 01100 00100 00100 00100 00100 01110].freeze,
      "2" => %w[01110 10001 00001 00010 00100 01000 11111].freeze,
      "3" => %w[11111 00010 00100 00010 00001 10001 01110].freeze,
      "4" => %w[00010 00110 01010 10010 11111 00010 00010].freeze,
      "5" => %w[11111 10000 11110 00001 00001 10001 01110].freeze,
      "6" => %w[00110 01000 10000 11110 10001 10001 01110].freeze,
      "7" => %w[11111 00001 00010 00100 01000 01000 01000].freeze,
      "8" => %w[01110 10001 10001 01110 10001 10001 01110].freeze,
      "9" => %w[01110 10001 10001 01111 00001 00010 01100].freeze,
    }.freeze

    module_function

    # A digit's bitmap.
    #
    # @param digit [String] a single character, `0` to `9`.
    #
    # @return [Array<String>, nil] the glyph's rows, or nil for anything that isn't a digit.
    #
    def glyph(digit) = GLYPHS[digit]
  end
end
