# frozen_string_literal: true

module Barcoder

  # Base class for everything Barcoder raises, so a caller can rescue the whole
  # library with one class.
  #
  class Error < StandardError; end

  # Raised when the digits given don't belong to any symbology Barcoder draws.
  #
  # A code of the wrong length, one carrying anything other than digits, or a
  # blank value.
  #
  class UnsupportedValue < Error; end

  # Raised when the digits are the right shape but the last one doesn't check
  # out.
  #
  # Deliberately fatal rather than a warning. Every symbology here carries its
  # own check digit, so a code failing it is a mistyped or mis-scanned number;
  # drawing it anyway produces a symbol no scanner will accept, which is worse
  # than drawing nothing.
  #
  class InvalidCheckDigit < Error; end

  # Raised when asked for an image format that isn't rendered.
  #
  class UnknownFormat < Error; end
end
