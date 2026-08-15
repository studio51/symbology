require "test_helper"

# Covers the encoding half of Barcoder (gems/barcoder): which symbology a value
# is, whether it may be drawn at all, and the bars it becomes.
#
# The three patterns asserted against are the reference encodings published for
# the standards' own worked examples, so this file is what proves Barcoder draws
# EAN and UPC rather than something that merely looks like them.
#
class BarcoderEncodingTest < Minitest::Test
  EAN13 = "5901234123457".freeze
  EAN13_MODULES = "10100010110100111011001100100110111101001110101010110011011011001000010101110010011101000100101".freeze

  UPCA = "036000291452".freeze
  UPCA_MODULES = "10100011010111101010111100011010001101000110101010110110011101001100110101110010011101101100101".freeze

  EAN8 = "96385074".freeze
  EAN8_MODULES = "1010001011010111101111010110111010101001110111001010001001011100101".freeze

  # --- What a value is -------------------------------------------------------

  test "a symbology is chosen by digit count" do
    assert_equal Barcoder::Symbology::EAN13, Barcoder.symbology_for(EAN13)
    assert_equal Barcoder::Symbology::UPCA,  Barcoder.symbology_for(UPCA)
    assert_equal Barcoder::Symbology::EAN8,  Barcoder.symbology_for(EAN8)
  end

  test "nothing draws a code of an unknown length" do
    assert_nil Barcoder.symbology_for("12345")
    assert_nil Barcoder.symbology_for("")
    assert_nil Barcoder.symbology_for(nil)
  end

  # A code is copied off a case, out of a spreadsheet or from a supplier's feed,
  # and all three punctuate it differently while meaning the same number.
  #
  test "spaces and hyphens are punctuation, not digits" do
    assert_equal EAN13, Barcoder.digits(" 590-1234 123457 ")
    assert_equal EAN13, Barcoder.encode("590-1234-123457").value
  end

  test "anything that isn't digits isn't a barcode" do
    assert_nil Barcoder.digits("DOOM")
    assert_nil Barcoder.digits("59012341234S7")
    assert_nil Barcoder.digits(nil)
  end

  test "an integer is as good as a string" do
    assert_equal Barcoder::Symbology::EAN8, Barcoder.symbology_for(96_385_074)
    assert_equal EAN8, Barcoder.encode(96_385_074).value
  end

  # --- Check digits ----------------------------------------------------------

  test "the check digit is computed the same way for every symbology" do
    assert_equal 7, Barcoder::Checksum.for("590123412345".chars.map(&:to_i))
    assert_equal 2, Barcoder::Checksum.for("03600029145".chars.map(&:to_i))
    assert_equal 4, Barcoder::Checksum.for("9638507".chars.map(&:to_i))
  end

  test "a code that fails its check digit is not drawn" do
    assert_not Barcoder.encodable?("5901234123456")

    error = assert_raises(Barcoder::InvalidCheckDigit) { Barcoder.encode("5901234123456") }

    assert_match "expected 7", error.message
  end

  test "asking whether a code is drawable never raises" do
    assert Barcoder.encodable?(EAN13)
    assert Barcoder.encodable?(UPCA)
    assert Barcoder.encodable?(EAN8)

    assert_not Barcoder.encodable?("DOOM")
    assert_not Barcoder.encodable?("12345")
    assert_not Barcoder.encodable?(nil)
  end

  test "a code nothing takes is refused by name" do
    error = assert_raises(Barcoder::UnsupportedValue) { Barcoder.encode("12345") }

    assert_match "EAN-13", error.message
  end

  # --- The bars themselves ---------------------------------------------------

  test "an EAN-13 encodes to its reference pattern" do
    assert_equal EAN13_MODULES, Barcoder.encode(EAN13).to_s
  end

  test "a UPC-A encodes to its reference pattern" do
    assert_equal UPCA_MODULES, Barcoder.encode(UPCA).to_s
  end

  test "an EAN-8 encodes to its reference pattern" do
    assert_equal EAN8_MODULES, Barcoder.encode(EAN8).to_s
  end

  # The leading digit of an EAN-13 has no bars of its own: it is carried by which
  # table each of the six left-hand digits was encoded from. So two codes with
  # the same digits 2 to 7 draw those six differently when the digit in front of
  # them differs — which is the whole trick, and the reason an EAN-13 cannot be
  # drawn one digit at a time.
  #
  test "the leading digit changes the bars of the six that follow it" do
    five = Barcoder.encode("5901234123457").to_s
    zero = Barcoder.encode("0901234123452").to_s

    assert_not_equal five[3..44], zero[3..44]
  end

  test "a symbol is the width the standard says" do
    assert_equal 95, Barcoder.encode(EAN13).width
    assert_equal 95, Barcoder.encode(UPCA).width
    assert_equal 67, Barcoder.encode(EAN8).width
  end

  test "the quiet zones are the standard's" do
    pattern = Barcoder.encode(EAN13)

    assert_equal 11, pattern.left_quiet_zone
    assert_equal 7,  pattern.right_quiet_zone
  end

  test "the guard bars are the long ones" do
    pattern = Barcoder.encode(EAN13)

    assert pattern.long?(0)
    assert pattern.long?(47)
    assert pattern.long?(94)

    assert_not pattern.long?(10)
    assert_not pattern.long?(60)
  end

  # UPC-A prints its number-system and check digits outside the bars, and extends
  # their bars to match the guards so the eye reads ten digits between them.
  #
  test "a UPC-A extends the bars of the two digits printed in the margins" do
    pattern = Barcoder.encode(UPCA)

    assert pattern.long?(5)
    assert pattern.long?(88)

    assert_not pattern.long?(20)
  end

  test "adjacent dark modules become one bar, never one that is half long" do
    pattern = Barcoder.encode(EAN13)

    assert_equal pattern.to_s.count("1"), pattern.bars.sum(&:width)

    pattern.bars.each do |bar|
      assert (bar.from...(bar.from + bar.width)).all? { |index| pattern.long?(index) == bar.long? }
    end
  end

  # --- What is printed under them --------------------------------------------

  test "an EAN-13 prints its leading digit in the left quiet zone" do
    leading, left, right = Barcoder.encode(EAN13).texts

    assert_equal "5", leading.digits
    assert leading.to.negative?

    assert_equal "901234", left.digits
    assert_equal "123457", right.digits
  end

  test "a UPC-A prints its first and last digits outside the bars" do
    leading, left, right, trailing = Barcoder.encode(UPCA).texts

    assert_equal "0", leading.digits
    assert_equal "36000", left.digits
    assert_equal "29145", right.digits
    assert_equal "2", trailing.digits

    assert leading.to.negative?
    assert_operator trailing.from, :>=, 95
  end

  test "an EAN-8 prints every digit under the bars" do
    left, right = Barcoder.encode(EAN8).texts

    assert_equal "9638", left.digits
    assert_equal "5074", right.digits
    assert_operator left.from, :>, 0
  end

  # --- Forcing a symbology ---------------------------------------------------

  test "a symbology can be named instead of inferred" do
    pattern = Barcoder.encode(UPCA, symbology: Barcoder::Symbology::UPCA)

    assert_equal UPCA_MODULES, pattern.to_s

    assert_raises(Barcoder::UnsupportedValue) do
      Barcoder.encode(UPCA, symbology: Barcoder::Symbology::EAN13)
    end
  end

  test "a symbology says what it is called, hyphen and all" do
    assert_equal "EAN-13", Barcoder::Symbology::EAN13.label
    assert_equal "EAN-8",  Barcoder::Symbology::EAN8.label
    assert_equal "UPC-A",  Barcoder::Symbology::UPCA.label
  end
end
