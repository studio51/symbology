# frozen_string_literal: true

module Symbology

  # An encoded symbol: the bars, where they are long, and what is printed under
  # them.
  #
  # The output of a {Symbology::Base} and the input to a renderer, and the
  # only thing the two share. It is measured entirely in *modules* — the width of
  # the narrowest bar, the unit every barcode standard specifies its geometry in
  # — so nothing here knows about pixels, and a renderer is free to choose what a
  # module is worth.
  #
  # Module 0 is the first bar of the symbol proper. The quiet zones sit outside
  # that: negative indices to the left, indices past {#width} to the right. That
  # is why {Text} spans can be negative — the leading digit of an EAN-13 is
  # printed in the left quiet zone, beside the bars rather than under them.
  #
  class Pattern

    # A run of digits printed under (or beside) a span of the symbol.
    #
    # The renderer divides the span into one cell per digit and centres each
    # digit in its cell, which is how a printed EAN spaces its numbers: evenly
    # across the bars they encode, not evenly across the whole symbol.
    #
    # `digits` is what to print, and `from` and `to` are the first and last
    # module of the span it labels, both inclusive.
    #
    Text = Data.define(:digits, :from, :to) do
      # The span's width.
      #
      # @return [Integer] the number of modules covered.
      #
      def width = to - from + 1
    end

    # A drawable bar: a run of adjacent dark modules of the same length.
    #
    # `from` is the bar's first module and `width` how many it covers; `long`
    # says whether it is a guard bar, drawn past the others.
    #
    Bar = Data.define(:from, :width, :long) do
      # Whether the bar descends through the text band.
      #
      # @return [Boolean] true for a guard bar.
      #
      def long? = long
    end

    attr_reader :value      # the digits this symbol encodes, as a string
    attr_reader :symbology  # the Symbology::Base that encoded them
    attr_reader :modules    # one boolean per module, true where the symbol is dark
    attr_reader :texts      # the Text runs printed with the symbol

    # @param value [String] the complete digits, check digit included.
    # @param symbology [Class] the symbology that produced the pattern.
    # @param modules [Array<Boolean>] one entry per module, true where dark.
    # @param long_ranges [Array<Range>] the module ranges drawn at full length.
    # @param texts [Array<Symbology::Pattern::Text>] what is printed, and where.
    # @param quiet_zone [Array(Integer, Integer)] the left and right quiet zones, in modules.
    #
    # @return [void]
    #
    def initialize(value:, symbology:, modules:, long_ranges:, texts:, quiet_zone:)
      @value       = value
      @symbology   = symbology
      @modules     = modules.freeze
      @long_ranges = long_ranges.freeze
      @texts       = texts.freeze
      @quiet_zone  = quiet_zone.freeze
    end

    # The symbol's width, quiet zones excluded.
    #
    # @return [Integer] the number of modules.
    #
    def width = modules.length

    # The quiet zone the standard requires to the left of the symbol.
    #
    # @return [Integer] the number of modules.
    #
    def left_quiet_zone = @quiet_zone.first

    # The quiet zone the standard requires to the right of the symbol.
    #
    # @return [Integer] the number of modules.
    #
    def right_quiet_zone = @quiet_zone.last

    # Whether a module is dark.
    #
    # @param index [Integer] the module index.
    #
    # @return [Boolean] true when the module is part of a bar.
    #
    def dark?(index) = modules[index] == true

    # Whether a module belongs to a bar drawn at full length.
    #
    # The guard bars, plus — on a UPC-A — the number-system and check digits,
    # which are printed outside the bars and have their bars extended to keep the
    # symbol's two halves visually separated.
    #
    # @param index [Integer] the module index.
    #
    # @return [Boolean] true when the module's bar descends through the text band.
    #
    def long?(index) = @long_ranges.any? { |range| range.cover?(index) }

    # The bars to draw, left to right.
    #
    # Adjacent dark modules are merged into one bar, and a run is split wherever
    # its length changes so no bar is half long and half short.
    #
    # @return [Array<Symbology::Pattern::Bar>] the bars.
    #
    def bars
      @bars ||= begin
        bars = []

        width.times do |index|
          next unless dark?(index)

          last = bars.last

          if last && last.from + last.width == index && last.long == long?(index)
            bars[-1] = Bar.new(from: last.from, width: last.width + 1, long: last.long)
          else
            bars << Bar.new(from: index, width: 1, long: long?(index))
          end
        end

        bars.freeze
      end
    end

    # The symbol as the string of ones and zeroes the standards are written in.
    #
    # Nothing renders from this — it exists because it is the form every EAN
    # reference table and worked example is published in, which makes it the form
    # a test asserts against and a bug is read in.
    #
    # @return [String] one character per module, `1` dark and `0` light.
    #
    def to_s = modules.map { |dark| dark ? "1" : "0" }.join
  end
end
