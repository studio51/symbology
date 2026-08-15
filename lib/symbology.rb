# frozen_string_literal: true

require "symbology/version"
require "symbology/errors"
require "symbology/checksum"
require "symbology/pattern"
require "symbology/base"
require "symbology/ean13"
require "symbology/ean8"
require "symbology/upca"
require "symbology/geometry"
require "symbology/renderer"
require "symbology/renderer/svg"
require "symbology/renderer/png"

# Draws the number on the back of a box as the barcode it was printed as.
#
# Symbology takes digits and gives back a picture of them — an SVG or a PNG of the
# EAN-13, EAN-8 or UPC-A symbol those digits are, ready to be shown on a page,
# put in an email or sent to a label printer.
#
#   Symbology.svg("5030917236075")             #=> "<svg xmlns=…"
#   Symbology.png("5030917236075", height: 40) #=> "\x89PNG\r\n…"
#
#   Symbology.encodable?("5030917236075") #=> true
#   Symbology.of("036000291452") #=> Symbology::UPCA
#
# ## What it will not do
#
# It will not draw a code that fails its own check digit. Every symbology here
# carries one, so a code failing it was mistyped, mis-scanned or invented — and a
# symbol drawn from it is a picture no scanner will read back. {.encodable?}
# answers that question without raising, so a caller who holds numbers of
# uncertain provenance can ask before drawing.
#
# It has no dependencies, and nothing in it knows what a barcode is *for*: it
# never reads a database, makes a request, or writes a file. Digits in, image
# out.
#
module Symbology

  # The symbologies drawn, in the order a value is offered to them.
  #
  # The order is only cosmetic — each takes a different number of digits, so at
  # most one of them ever recognises a value.
  #
  SYMBOLOGIES = [ Symbology::EAN13, Symbology::UPCA, Symbology::EAN8 ].freeze

  # The image formats rendered.
  #
  FORMATS = { svg: Renderer::SVG, png: Renderer::PNG }.freeze

  class << self

    # The digits of a value, whatever it arrived as.
    #
    # Spaces and hyphens are dropped: a code is copied off a case, out of a
    # spreadsheet, or from a supplier's feed, and all three punctuate it
    # differently while meaning the same number. Nothing else is: a value with a
    # letter in it is not a punctuated barcode, it is not a barcode.
    #
    # @param value [String, Integer, nil] the printed digits.
    #
    # @return [String, nil] the digits, or nil when the value isn't digits.
    #
    def digits(value)
      return if value.nil?

      normalised = value.to_s.gsub(/[\s-]/, "")

      normalised.match?(/\A\d+\z/) ? normalised : nil
    end

    # Which symbology a value belongs to.
    #
    # Decided on the digit count alone, so it answers for a mistyped code too —
    # "an EAN-13 that doesn't check out" is a far more useful thing to be able to
    # say than "not a barcode".
    #
    # @param value [String, Integer] the printed digits.
    #
    # @return [Class, nil] the symbology, or nil when nothing takes that many digits.
    #
    def of(value) = SYMBOLOGIES.find { |symbology| symbology.handles?(value) }

    # Whether a value can be drawn.
    #
    # @param value [String, Integer] the printed digits.
    #
    # @return [Boolean] true when some symbology takes it and its check digit holds.
    #
    def encodable?(value) = of(value)&.encodable?(value) || false

    # Encodes a value into the pattern its symbology says it is.
    #
    # @param value [String, Integer] the printed digits.
    # @param symbology [Class, nil] force a symbology, instead of choosing by digit count.
    #
    # @raise [Symbology::UnsupportedValue] when nothing draws that many digits.
    # @raise [Symbology::InvalidCheckDigit] when the last digit isn't the one the rest imply.
    #
    # @return [Symbology::Pattern] the encoded symbol.
    #
    def encode(value, symbology: nil)
      symbology ||= of(value)

      if symbology.nil?
        raise UnsupportedValue, "#{ value.inspect } is not an EAN-13, EAN-8 or UPC-A"
      end

      symbology.encode(value)
    end

    # Draws a value.
    #
    # @param value [String, Integer] the printed digits.
    # @param format [Symbol] `:svg` or `:png`.
    # @param symbology [Class, nil] force a symbology, instead of choosing by digit count.
    # @param options [Hash] see {Symbology::Renderer::DEFAULTS}.
    #
    # @raise [Symbology::UnknownFormat] when asked for a format that isn't drawn.
    # @raise [Symbology::UnsupportedValue] when nothing draws that many digits.
    # @raise [Symbology::InvalidCheckDigit] when the last digit isn't the one the rest imply.
    #
    # @return [String] the image — SVG markup, or binary for a raster format.
    #
    def render(value, format: :svg, symbology: nil, **options)
      renderer(format).render(encode(value, symbology:), **options)
    end

    # Draws a value as SVG.
    #
    # @param value [String, Integer] the printed digits.
    # @param options [Hash] see {Symbology::Renderer::SVG::DEFAULTS}.
    #
    # @return [String] the SVG document.
    #
    def svg(value, **options) = render(value, format: :svg, **options)

    # Draws a value as a PNG.
    #
    # @param value [String, Integer] the printed digits.
    # @param options [Hash] see {Symbology::Renderer::PNG::DEFAULTS}.
    #
    # @return [String] the PNG, as binary.
    #
    def png(value, **options) = render(value, format: :png, **options)

    # The renderer for a format.
    #
    # @param format [Symbol, String] the format's name.
    #
    # @raise [Symbology::UnknownFormat] when it isn't drawn.
    #
    # @return [Class] the renderer.
    #
    def renderer(format)
      FORMATS.fetch(format.to_sym) do
        raise UnknownFormat, "#{ format.inspect } is not drawn; try #{ FORMATS.keys.join(" or ") }"
      end
    end

    # What to serve a format as.
    #
    # @param format [Symbol, String] the format's name.
    #
    # @raise [Symbology::UnknownFormat] when it isn't drawn.
    #
    # @return [String] the MIME type.
    #
    def mime_type(format) = renderer(format)::MIME_TYPE
  end
end
