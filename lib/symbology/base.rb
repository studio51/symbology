# frozen_string_literal: true

require "symbology/checksum"
require "symbology/errors"
require "symbology/pattern"

module Symbology

  # What a family of barcodes is: how many digits it takes, how they become
  # bars, and how they are printed underneath.
  #
  # Every symbology Symbology draws is a subclass, and every subclass is used as a
  # class rather than instantiated — a symbology has no state, only rules.
  #
  # The rules a subclass supplies:
  #
  # - `LENGTH` — how many digits the complete code carries.
  # - `QUIET_ZONE` — the blank margins the standard requires, in modules.
  # - `#encode` — the modules, the long-bar ranges and the printed text.
  #
  # Validation, check digits and the digit tables are settled here, because they
  # are the same for the whole UPC/EAN family.
  #
  class Base

    # The bar patterns for a digit, seven modules each.
    #
    # Three of them, and which is used carries information of its own. `L` and
    # `G` both encode a left-hand digit, and the *sequence* of L and G across the
    # six left-hand digits is what encodes an EAN-13's thirteenth digit — the one
    # with no bars of its own. `R` is the inverse of `L`, so a right-hand digit
    # always starts dark, which is how a scanner reading the symbol backwards
    # knows it did.
    #
    ENCODINGS = {
      "L" => %w[0001101 0011001 0010011 0111101 0100011 0110001 0101111 0111011 0110111 0001011].freeze,
      "G" => %w[0100111 0110011 0011011 0100001 0011101 0111001 0000101 0010001 0001001 0010111].freeze,
      "R" => %w[1110010 1100110 1101100 1000010 1011100 1001110 1010000 1000100 1001000 1110100].freeze,
    }.freeze

    NORMAL_GUARD = "101".freeze  # opens and closes a symbol
    CENTRE_GUARD = "01010".freeze # separates the two halves
    DIGIT_MODULES = 7 # how wide one encoded digit is

    class << self

      # Encodes a value into a drawable pattern.
      #
      # @param value [String, Integer] the printed digits.
      #
      # @raise [Symbology::UnsupportedValue] when the digits are the wrong shape for this symbology.
      # @raise [Symbology::InvalidCheckDigit] when the last digit isn't the one the rest imply.
      #
      # @return [Symbology::Pattern] the encoded symbol.
      #
      def encode(value)
        digits = validate!(value)

        pattern(digits)
      end

      # Whether this symbology can draw a value, without raising to find out.
      #
      # @param value [String, Integer] the printed digits.
      #
      # @return [Boolean] true when the value is the right length and checks out.
      #
      def encodable?(value)
        digits = Symbology.digits(value)

        return false if digits.nil? || digits.length != self::LENGTH

        Checksum.valid?(digits.chars.map(&:to_i))
      end

      # Whether a value is this symbology's shape, check digit aside.
      #
      # Length alone. It is what picks the symbology for a value — a code that
      # doesn't check out is still recognisably an EAN-13, and reporting it as an
      # EAN-13 with a bad check digit says far more than reporting it as nothing
      # at all.
      #
      # @param value [String, Integer] the printed digits.
      #
      # @return [Boolean] true when the digit count matches.
      #
      def handles?(value)
        Symbology.digits(value)&.length == self::LENGTH
      end

      # The symbology's name, as it is written on a specification — hyphen and
      # all, since that is how it is read out and how an error naming it should
      # read.
      #
      # @return [String] e.g. "EAN-13".
      #
      def label = self::LABEL

      private

      # Checks a value is this symbology's, and hands back its digits.
      #
      # @param value [String, Integer] the printed digits.
      #
      # @raise [Symbology::UnsupportedValue] when the digits are the wrong shape for this symbology.
      # @raise [Symbology::InvalidCheckDigit] when the last digit isn't the one the rest imply.
      #
      # @return [String] the digits.
      #
      def validate!(value)
        digits = Symbology.digits(value)

        if digits.nil? || digits.length != self::LENGTH
          raise UnsupportedValue, "#{ label } takes #{ self::LENGTH } digits, got #{ value.inspect }"
        end

        unless Checksum.valid?(digits.chars.map(&:to_i))
          expected = Checksum.for(digits.chars.map(&:to_i)[0..-2])

          raise InvalidCheckDigit, "#{ digits } fails its check digit (expected #{ expected }, got #{ digits[-1] })"
        end

        digits
      end

      # Encodes digits with a pattern of L, G and R tables.
      #
      # @param digits [String] the digits to encode.
      # @param parities [String] one of `L`, `G` or `R` per digit.
      #
      # @return [String] the modules, as ones and zeroes.
      #
      def encode_digits(digits, parities)
        digits.chars.each_with_index.map do |digit, index|
          ENCODINGS.fetch(parities[index])[digit.to_i]
        end.join
      end

      # Turns a string of ones and zeroes into the module array a pattern holds.
      #
      # @param modules [String] one character per module.
      #
      # @return [Array<Boolean>] true where the symbol is dark.
      #
      def to_modules(modules) = modules.chars.map { |character| character == "1" }
    end
  end
end
