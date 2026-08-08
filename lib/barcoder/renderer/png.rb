# frozen_string_literal: true

require "barcoder/canvas"
require "barcoder/font"
require "barcoder/renderer"

module Barcoder
  class Renderer

    # Draws a symbol as a PNG.
    #
    # For everywhere an SVG can't go: an email, a PDF, a label printer's spool, a
    # sheet of stickers.
    #
    # A raster puts one constraint on the geometry that vectors don't. A module
    # has to be a whole number of pixels — half a pixel of bar is either rounded
    # away or smeared across two, and both change the width a scanner measures —
    # so the module width and the bar height are rounded to integers here rather
    # than left to the rasteriser. Ask for a fractional module and you get the
    # nearest whole one, which is the size the image actually is.
    #
    class PNG < Renderer

      # PNG's own defaults.
      #
      # A wider module than the SVG default: three pixels is about the narrowest
      # a phone camera reads reliably off a screen, and a raster can't be scaled
      # up afterwards to make up for it.
      #
      DEFAULTS = Renderer::DEFAULTS.merge(module_width: 3).freeze

      MIME_TYPE = "image/png".freeze # what to serve it as
      EXTENSION = "png".freeze # what to name the file

      # @return [Hash] the options this renderer accepts.
      #
      def self.defaults = DEFAULTS

      private

      # Lays the symbol out on whole pixels.
      #
      # @return [Barcoder::Geometry] the layout.
      #
      def build_geometry
        Geometry.new(
          pattern,
          module_width: [ options[:module_width].round, 1 ].max, height: options[:height].round,
          text: options[:text], quiet_zone: options[:quiet_zone],
        )
      end

      # Draws the symbol.
      #
      # @return [String] the PNG, as binary.
      #
      def draw
        canvas = Canvas.new(geometry.width, geometry.height)

        pattern.bars.each do |bar|
          canvas.rectangle(geometry.x(bar.from), 0, bar.width * geometry.module_width, geometry.bar_length(bar.long?))
        end

        digits(canvas)

        canvas.to_png(foreground: colour(options[:foreground]), background: colour(options[:background]))
      end

      # Prints the digits under the symbol.
      #
      # One font pixel to one module, which is what keeps the numbers as crisp as
      # the bars: at three pixels to a module a digit is fifteen pixels wide,
      # inside a cell of twenty-one, with the module of clearance above and below
      # that the text band leaves.
      #
      # @param canvas [Barcoder::Canvas] the raster to draw on.
      #
      # @return [void]
      #
      def digits(canvas)
        return unless geometry.text?

        scale = geometry.module_width
        top   = geometry.bar_height + scale

        pattern.texts.each do |text|
          geometry.each_digit(text) do |digit, centre|
            canvas.glyph(digit, centre - (Font::WIDTH * scale / 2.0), top, scale)
          end
        end
      end

      # Reads a colour into the red, green and blue a palette entry is written as.
      #
      # Hex only. A PNG palette holds numbers, not names, and quietly resolving
      # "rebeccapurple" would mean shipping a colour table for the one format
      # that can't take a CSS colour anyway.
      #
      # @param value [String, Array<Integer>, nil] `#rgb`, `#rrggbb`, an RGB triplet, or nil for transparent.
      #
      # @raise [ArgumentError] when the colour isn't one of those.
      #
      # @return [Array(Integer, Integer, Integer), nil] the components, or nil.
      #
      def colour(value)
        case value
        when nil    then nil
        when Array  then value.map(&:to_i)
        when String then hex(value)
        else raise ArgumentError, "PNG colours are hex strings or [r, g, b], got #{ value.inspect }"
        end
      end

      # Expands a hex colour.
      #
      # @param value [String] `#rgb` or `#rrggbb`, the hash optional.
      #
      # @raise [ArgumentError] when it is neither.
      #
      # @return [Array(Integer, Integer, Integer)] the components.
      #
      def hex(value)
        digits = value.delete_prefix("#")
        digits = digits.chars.flat_map { |character| [ character, character ] }.join if digits.length == 3

        raise ArgumentError, "#{ value.inspect } is not a hex colour" unless /\A\h{6}\z/.match?(digits)

        digits.scan(/\h{2}/).map { |component| component.to_i(16) }
      end
    end
  end
end
