# frozen_string_literal: true

require "symbology/base"

module Symbology

  # EAN-13 — the thirteen digits printed on the back of every game box sold
  # outside North America, and the symbology all but a handful of the codes in
  # a games.directory shelf are.
  #
  # Twelve of its digits are drawn; the first is not. Six left-hand digits are
  # each encoded from one of two tables, and the *sequence* of tables — which
  # digit used `L` and which used `G` — is what carries the thirteenth. That is
  # also why an EAN-13 cannot be drawn one digit at a time: the first digit
  # changes the bars of the six that follow it, not its own.
  #
  class EAN13 < Base
    LABEL = "EAN-13".freeze # what it is called
    LENGTH = 13 # digits in a complete code
    QUIET_ZONE = [ 11, 7 ].freeze # left and right margins, in modules

    # Which table each of the six left-hand digits is encoded from, indexed by
    # the leading digit.
    #
    # A leading zero is all-`L`, which is what makes a UPC-A — twelve digits
    # with no leading digit printed — the same symbol as an EAN-13 beginning
    # with one.
    #
    PARITIES = %w[
      LLLLLL LLGLGG LLGGLG LLGGGL LGLLGG
      LGGLLG LGGGLL LGLGLG LGLGGL LGGLGL
    ].freeze

    class << self

      private

      # Draws the thirteen digits.
      #
      # @param digits [String] the validated digits.
      #
      # @return [Symbology::Pattern] the encoded symbol.
      #
      def pattern(digits)
        modules = [
          Base::NORMAL_GUARD,
          encode_digits(digits[1..6], PARITIES[digits[0].to_i]),
          Base::CENTRE_GUARD,
          encode_digits(digits[7..12], "RRRRRR"),
          Base::NORMAL_GUARD,
        ].join

        Pattern.new(
          value: digits, symbology: self, modules: to_modules(modules),
          long_ranges: [ 0..2, 45..49, 92..94 ],
          texts: [
            # The leading digit has no bars of its own, so it is printed in the
            # left quiet zone rather than under the symbol — which is exactly
            # where it belongs, since the margin it sits in is as much a part of
            # the symbol as the bars are.
            #
            Pattern::Text.new(digits: digits[0], from: -8, to: -2),
            Pattern::Text.new(digits: digits[1..6], from: 3, to: 44),
            Pattern::Text.new(digits: digits[7..12], from: 50, to: 91),
          ],
          quiet_zone: QUIET_ZONE,
        )
      end
    end
  end
end
