# frozen_string_literal: true

module Symbology

  # The modulo-10 check digit every symbology in the UPC/EAN family carries.
  #
  # One implementation for all three: EAN-13, EAN-8 and UPC-A weight their digits
  # 3 and 1 alternately *from the right*, which is the same rule written from
  # different ends. Anchoring on the right rather than the left is what makes it
  # one method — the weight a digit gets depends on its distance from the check
  # digit, not on how many digits precede it.
  #
  module Checksum
    module_function

    # The check digit that completes a payload.
    #
    # @param payload [Array<Integer>] the digits *without* the check digit.
    #
    # @return [Integer] the check digit, 0-9.
    #
    def for(payload)
      sum = payload.each_with_index.sum do |digit, index|
        digit * ((payload.length - index).odd? ? 3 : 1)
      end

      (10 - (sum % 10)) % 10
    end

    # Whether a complete code checks out.
    #
    # @param digits [Array<Integer>] the digits *including* the trailing check digit.
    #
    # @return [Boolean] true when the last digit is the one the rest imply.
    #
    def valid?(digits)
      return false if digits.length < 2

      digits.last == self.for(digits[0..-2])
    end
  end
end
