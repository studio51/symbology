# frozen_string_literal: true

require "barcoder/symbology"

module Barcoder
  class Symbology

    # EAN-8 — the short code, used where a box is too small to carry a full
    # EAN-13.
    #
    # Rare on a game case and common on the things that come in one, which is why
    # it is here: a boxed collector's edition's parts carry their own codes.
    #
    # Every digit is drawn, four to a side, so there is no parity sequence to
    # read — the left half is always `L`, the right always `R`.
    #
    class EAN8 < Symbology
      LABEL = "EAN-8".freeze # what it is called
      LENGTH = 8 # digits in a complete code
      QUIET_ZONE = [ 7, 7 ].freeze # left and right margins, in modules

      class << self

        private

        # Draws the eight digits.
        #
        # @param digits [String] the validated digits.
        #
        # @return [Barcoder::Pattern] the encoded symbol.
        #
        def pattern(digits)
          modules = [
            NORMAL_GUARD,
            encode_digits(digits[0..3], "LLLL"),
            CENTRE_GUARD,
            encode_digits(digits[4..7], "RRRR"),
            NORMAL_GUARD,
          ].join

          Pattern.new(
            value: digits, symbology: self, modules: to_modules(modules),
            long_ranges: [ 0..2, 31..35, 64..66 ],
            texts: [
              Pattern::Text.new(digits: digits[0..3], from: 3, to: 30),
              Pattern::Text.new(digits: digits[4..7], from: 36, to: 63),
            ],
            quiet_zone: QUIET_ZONE,
          )
        end
      end
    end
  end
end
