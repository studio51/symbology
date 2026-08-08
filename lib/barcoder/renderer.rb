# frozen_string_literal: true

require "barcoder/errors"
require "barcoder/geometry"

module Barcoder

  # What every image format has in common: the options it accepts and the
  # layout it draws.
  #
  # A subclass supplies a file extension, a MIME type and a `#draw`; everything
  # about *where* a bar goes is settled by {Barcoder::Geometry}, so two formats
  # of the same symbol are the same picture.
  #
  class Renderer

    # The options every renderer takes.
    #
    # `height` is the height of the bars, not of the image — the text band is
    # added below it, so asking for the same height with and without digits gives
    # a symbol whose bars are the same length, which is the thing a scanner
    # cares about.
    #
    DEFAULTS = {
      module_width: 2,          # what one module is worth, in pixels
      height: 60,               # how tall the bars are, in pixels
      text: true,               # print the digits under the symbol
      foreground: "#000000",    # the bars and the digits
      background: "#FFFFFF",    # the paper; nil for none
      quiet_zone: nil,          # override the standard's margins, in modules
    }.freeze

    attr_reader :pattern   # the symbol being drawn
    attr_reader :options   # the settled options
    attr_reader :geometry  # where everything goes

    class << self

      # Draws a symbol.
      #
      # @param pattern [Barcoder::Pattern] the encoded symbol.
      # @param options [Hash] see {DEFAULTS}.
      #
      # @return [String] the image.
      #
      def render(pattern, **options) = new(pattern, **options).render

      # The options this renderer accepts, its own included.
      #
      # @return [Hash] the defaults.
      #
      def defaults = DEFAULTS
    end

    # @param pattern [Barcoder::Pattern] the encoded symbol.
    # @param options [Hash] see {DEFAULTS}.
    #
    # @raise [ArgumentError] when given an option this renderer doesn't have.
    #
    # @return [void]
    #
    def initialize(pattern, **options)
      unknown = options.keys - self.class.defaults.keys
      raise ArgumentError, "unknown option#{ "s" if unknown.length > 1 }: #{ unknown.join(", ") }" unless unknown.empty?

      # A plain merge, so `background: nil` reaches the renderer as the answer it
      # is — "no paper" — rather than being read as an option nobody gave and
      # replaced with the default.
      #
      @pattern = pattern
      @options = self.class.defaults.merge(options)

      @geometry = build_geometry
    end

    # Draws the symbol.
    #
    # @return [String] the image.
    #
    def render = draw

    private

    # Lays the symbol out for this format.
    #
    # @return [Barcoder::Geometry] the layout.
    #
    def build_geometry
      Geometry.new(
        pattern,
        module_width: options[:module_width], height: options[:height],
        text: options[:text], quiet_zone: options[:quiet_zone],
      )
    end

    # Draws the image. Subclasses implement this.
    #
    # @raise [NotImplementedError] always.
    #
    # @return [String] the image.
    #
    def draw = raise(NotImplementedError, "#{ self.class } must implement #draw")
  end
end
