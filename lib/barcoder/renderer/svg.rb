# frozen_string_literal: true

require "barcoder/renderer"
require "barcoder/version"

module Barcoder
  class Renderer

    # Draws a symbol as SVG.
    #
    # The format to reach for by default. A barcode is a handful of rectangles
    # and it stays sharp at any size, which matters more here than anywhere else:
    # a symbol rasterised at the wrong scale has bars that round to the wrong
    # width, and a bar of the wrong width is a digit of a different value.
    #
    # The markup is deliberately plain — rectangles and text, no defs, no CSS, no
    # transforms — so it survives being inlined into a page, opened in an editor,
    # or handed to a printer.
    #
    class SVG < Renderer

      # SVG's own options, on top of {Barcoder::Renderer::DEFAULTS}.
      #
      DEFAULTS = Renderer::DEFAULTS.merge(
        font_family: "monospace", # the family the digits are set in
      ).freeze

      MIME_TYPE = "image/svg+xml".freeze # what to serve it as
      EXTENSION = "svg".freeze # what to name the file

      # @return [Hash] the options this renderer accepts.
      #
      def self.defaults = DEFAULTS

      private

      # Draws the symbol.
      #
      # @return [String] the SVG document.
      #
      def draw
        <<~SVG
          <?xml version="1.0" encoding="UTF-8"?>
          <svg xmlns="http://www.w3.org/2000/svg" width="#{ number(geometry.width) }" height="#{ number(geometry.height) }" viewBox="0 0 #{ number(geometry.width) } #{ number(geometry.height) }" role="img" aria-label="#{ label }" data-barcoder="#{ Barcoder::VERSION }">
          #{ paper }#{ bars }#{ digits }</svg>
        SVG
      end

      # The background rectangle, when there is a background.
      #
      # @return [String] the markup, or nothing at all for a transparent symbol.
      #
      def paper
        return "" if options[:background].nil?

        %(  <rect width="#{ number(geometry.width) }" height="#{ number(geometry.height) }" fill="#{ attribute(options[:background]) }"/>\n)
      end

      # The bars.
      #
      # @return [String] the markup.
      #
      def bars
        rectangles = pattern.bars.map do |bar|
          %(    <rect x="#{ number(geometry.x(bar.from)) }" y="0" ) +
            %(width="#{ number(bar.width * geometry.module_width) }" height="#{ number(geometry.bar_length(bar.long?)) }"/>)
        end

        %(  <g fill="#{ attribute(options[:foreground]) }" shape-rendering="crispEdges">\n#{ rectangles.join("\n") }\n  </g>\n)
      end

      # The printed digits.
      #
      # @return [String] the markup, or nothing at all when the symbol carries no text.
      #
      def digits
        return "" unless geometry.text?

        texts = pattern.texts.flat_map do |text|
          [].tap do |elements|
            geometry.each_digit(text) do |digit, centre|
              elements << %(    <text x="#{ number(centre) }" y="#{ number(geometry.baseline) }">#{ digit }</text>)
            end
          end
        end

        %(  <g fill="#{ attribute(options[:foreground]) }" font-family="#{ attribute(options[:font_family]) }" ) +
          %(font-size="#{ number(geometry.text_size) }" text-anchor="middle">\n#{ texts.join("\n") }\n  </g>\n)
      end

      # Writes a value into an attribute without letting it become markup.
      #
      # The colours and the font family are the only things a caller supplies
      # that reach the document as text, and a library has no idea how far from
      # a controller's params it is being called. Escaping them costs nothing and
      # means a page that inlines this markup can't be made to inline anything
      # else.
      #
      # @param value [Object] the attribute's value.
      #
      # @return [String] the value, safe to sit between quotes.
      #
      def attribute(value)
        value.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;").gsub('"', "&quot;")
      end

      # What a screen reader reads out.
      #
      # The symbology as well as the digits: a barcode's whole purpose is being
      # the number in a form a machine reads, and a reader that says only the
      # number has dropped the half a sighted user gets for free.
      #
      # @return [String] the label.
      #
      def label = "#{ pattern.symbology.label } barcode #{ pattern.value }"

      # Writes a coordinate the way SVG reads best.
      #
      # Whole numbers stay whole — a symbol drawn at an integer module width
      # should not be full of `.0` — and anything else is rounded to three
      # decimals, which is finer than any device renders and short enough to read.
      #
      # @param value [Numeric] the coordinate.
      #
      # @return [String] the number.
      #
      def number(value)
        rounded = value.round(3)

        rounded == rounded.to_i ? rounded.to_i.to_s : rounded.to_s
      end
    end
  end
end
