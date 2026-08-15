# frozen_string_literal: true

require_relative "lib/symbology/version"

Gem::Specification.new do |spec|
  # "Symbology" is what the barcode industry calls a family — EAN-13 is a
  # symbology, UPC-A is another — so it names the whole of what this does rather
  # than one part of it, and it is the vocabulary the code already used.
  #
  spec.name        = "symbology"
  spec.version     = Symbology::VERSION
  spec.authors     = [ "Vlad Radulescu" ]
  spec.email       = [ "vlad@studio51.solutions" ]
  spec.homepage    = "https://github.com/studio51/symbology"
  spec.summary     = "Draws EAN-13, EAN-8 and UPC-A barcodes as SVG and PNG."
  spec.description = <<~TEXT.freeze
    Symbology turns the number printed on a box back into the barcode it was
    printed as. It encodes EAN-13, EAN-8 and UPC-A, lays a symbol out to the
    proportions the standards specify — quiet zones, guard bars descending
    through the printed digits, the leading digit set in the margin — and renders
    it as SVG or as a one-bit indexed PNG it writes itself. It refuses to draw a
    code that fails its own check digit, because a symbol no scanner will read
    back is worse than no symbol at all. No dependencies, no I/O: digits in,
    image out.
  TEXT
  spec.license = "Apache-2.0"

  # `Data.define`, used for the value objects an encoded symbol is made of.
  #
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "LICENSE",
    "NOTICE",
    "README.md",
    "CHANGELOG.md",
  ]

  # None, deliberately. The only thing Symbology needs that it doesn't do itself
  # is zlib, to deflate a PNG's image data, and that ships with Ruby. It draws
  # its own digits (lib/symbology/font.rb) rather than depend on an imaging
  # library for ten glyphs.
end
