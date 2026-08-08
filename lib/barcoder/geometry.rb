# frozen_string_literal: true

module Barcoder

  # Where everything sits, once a module is worth a number of pixels.
  #
  # A {Barcoder::Pattern} is measured in modules and knows nothing else; a
  # renderer draws rectangles and glyphs and wants pixels. This does that one
  # conversion, so both renderers lay a symbol out identically and neither
  # repeats the arithmetic.
  #
  # The vertical layout is the printed convention rather than a choice: the bars
  # run to `height`, and below them sits a band that only the guard bars descend
  # into. The digits are printed in that band, in the gaps the guards leave —
  # which is why the band is measured off the guards' descent and not off the
  # text size.
  #
  class Geometry
    TEXT_BAND_MODULES = 9 # how far the guard bars descend past the rest
    TEXT_SIZE_MODULES = 8 # the printed digits' em size
    GLYPH_CELL_MODULES = 7 # the space one printed digit is given

    attr_reader :pattern       # the encoded symbol being laid out
    attr_reader :module_width  # what one module is worth, in pixels
    attr_reader :bar_height    # how tall an ordinary bar is, in pixels
    attr_reader :left_quiet    # the left margin, in modules
    attr_reader :right_quiet   # the right margin, in modules

    # @param pattern [Barcoder::Pattern] the encoded symbol.
    # @param module_width [Numeric] what one module is worth, in pixels.
    # @param height [Numeric] how tall an ordinary bar is, in pixels.
    # @param text [Boolean] whether the digits are printed under the symbol.
    # @param quiet_zone [Integer, Array(Integer, Integer), nil] the margins to use instead of the standard's.
    #
    # @return [void]
    #
    def initialize(pattern, module_width:, height:, text:, quiet_zone: nil)
      @pattern      = pattern
      @module_width = module_width
      @bar_height   = height
      @text         = text

      @left_quiet, @right_quiet = quiet_zones(quiet_zone)
    end

    # Whether the digits are printed with the symbol.
    #
    # @return [Boolean] true when a text band is reserved.
    #
    def text? = @text

    # The image's full width.
    #
    # @return [Numeric] the width in pixels, quiet zones included.
    #
    def width = (left_quiet + pattern.width + right_quiet) * module_width

    # The image's full height.
    #
    # @return [Numeric] the height in pixels, the text band included.
    #
    def height = bar_height + text_band

    # The band below the bars that the guards descend into and the digits are
    # printed in.
    #
    # @return [Numeric] the band's height in pixels, or zero when nothing is printed.
    #
    def text_band = text? ? TEXT_BAND_MODULES * module_width : 0

    # The left edge of a module.
    #
    # Takes negative indices, which is how the quiet zones are addressed: module
    # -1 is the one immediately left of the symbol.
    #
    # @param index [Numeric] the module index.
    #
    # @return [Numeric] the distance from the image's left edge, in pixels.
    #
    def x(index) = (index + left_quiet) * module_width

    # How far down a bar runs.
    #
    # @param long [Boolean] whether it is a guard bar.
    #
    # @return [Numeric] the bar's length in pixels.
    #
    def bar_length(long) = long ? bar_height + text_band : bar_height

    # Where each digit of a printed run is centred.
    #
    # The run's span is divided into one cell per digit and each digit is centred
    # in its own cell, so the digits line up with the bars encoding them rather
    # than merely with each other.
    #
    # @param text [Barcoder::Pattern::Text] the run of digits.
    #
    # @yieldparam digit [String] the digit to draw.
    # @yieldparam centre [Numeric] the centre of its cell, in pixels from the left edge.
    #
    # @return [void]
    #
    def each_digit(text)
      cell = text.width * module_width / text.digits.length.to_f

      text.digits.chars.each_with_index do |digit, index|
        yield digit, x(text.from) + ((index + 0.5) * cell)
      end
    end

    # The em size the digits are drawn at.
    #
    # @return [Numeric] the font size in pixels.
    #
    def text_size = TEXT_SIZE_MODULES * module_width

    # The bottom of the printed digits.
    #
    # One module clear of the image's bottom edge, so a symbol placed against a
    # dark background doesn't read as clipped.
    #
    # @return [Numeric] the baseline, in pixels from the top.
    #
    def baseline = height - module_width

    private

    # Settles the margins: the caller's, or the standard's when they didn't say.
    #
    # @param override [Integer, Array(Integer, Integer), nil] one value for both sides, a left/right pair, or nothing.
    #
    # @return [Array(Integer, Integer)] the left and right margins, in modules.
    #
    def quiet_zones(override)
      case override
      when nil     then [ pattern.left_quiet_zone, pattern.right_quiet_zone ]
      when Numeric then [ override, override ]
      when Array   then [ override.first, override.last ]
      else raise ArgumentError, "quiet_zone takes a number, a [left, right] pair or nil, got #{ override.inspect }"
      end
    end
  end
end
