# frozen_string_literal: true

require "barcoder/symbology"

module Barcoder
  class Symbology

    # UPC-A — the twelve digits on a North American release.
    #
    # The same bars as an EAN-13 whose leading digit is zero, and a different
    # number printed under them. Only the printing differs, and it differs in a
    # way worth honouring: the number-system digit and the check digit are set
    # outside the bars, their own bars extended to full length so the eye reads
    # the symbol as ten digits between two guards rather than twelve in a row.
    #
    # A scanner reports a UPC-A as twelve digits. So does CeX, and so does a
    # member typing what is on the case. Storing it as the thirteen-digit EAN it
    # is equivalent to would be a lie about what is printed, which is why this is
    # a symbology of its own rather than a prefix.
    #
    class UPCA < Symbology
      LABEL = "UPC-A".freeze # what it is called
      LENGTH = 12 # digits in a complete code
      QUIET_ZONE = [ 9, 9 ].freeze # left and right margins, in modules

      class << self

        private

        # Draws the twelve digits.
        #
        # @param digits [String] the validated digits.
        #
        # @return [Barcoder::Pattern] the encoded symbol.
        #
        def pattern(digits)
          modules = [
            NORMAL_GUARD,
            encode_digits(digits[0..5], "LLLLLL"),
            CENTRE_GUARD,
            encode_digits(digits[6..11], "RRRRRR"),
            NORMAL_GUARD,
          ].join

          Pattern.new(
            value: digits, symbology: self, modules: to_modules(modules),
            # The guards, plus the bars of the two digits printed in the margins:
            # extending those is what separates the ten digits under the symbol
            # from the two beside it.
            #
            long_ranges: [ 0..2, 3..9, 45..49, 85..91, 92..94 ],
            texts: [
              Pattern::Text.new(digits: digits[0], from: -8, to: -2),
              Pattern::Text.new(digits: digits[1..5], from: 10, to: 44),
              Pattern::Text.new(digits: digits[6..10], from: 50, to: 84),
              Pattern::Text.new(digits: digits[11], from: 96, to: 102),
            ],
            quiet_zone: QUIET_ZONE,
          )
        end
      end
    end
  end
end
