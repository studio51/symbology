# frozen_string_literal: true

require_relative "lib/barcoder/version"

Gem::Specification.new do |spec|
  spec.name        = "barcoder"
  spec.version     = Barcoder::VERSION
  spec.authors     = [ "Vlad Radulescu" ]
  spec.email       = [ "vlad@studio51.solutions" ]
  spec.homepage    = "https://github.com/studio51/barcoder"
  spec.summary     = "Draws EAN-13, EAN-8 and UPC-A barcodes as SVG and PNG."
  spec.description = <<~TEXT.freeze
    Barcoder turns the number printed on a box back into the barcode it was
    printed as. It encodes EAN-13, EAN-8 and UPC-A, lays a symbol out to the
    proportions the standards specify — quiet zones, guard bars descending
    through the printed digits, the leading digit set in the margin — and renders
    it as SVG or as a one-bit indexed PNG it writes itself. It refuses to draw a
    code that fails its own check digit, because a symbol no scanner will read
    back is worse than no symbol at all. No dependencies, no I/O: digits in,
    image out.
  TEXT
  # Inherited from the host repository. Publishing this as an open-source gem is
  # a deliberate decision for the maintainer to take at extraction time; until
  # then it carries the same terms as everything else in games.directory.
  #
  spec.license = "Nonstandard"

  # `Data.define`, used for the value objects an encoded symbol is made of.
  #
  spec.required_ruby_version = ">= 3.2"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"]   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir[
    "lib/**/*",
    "README.md",
    "CHANGELOG.md",
  ]

  # None, deliberately. The only thing Barcoder needs that it doesn't do itself
  # is zlib, to deflate a PNG's image data, and that ships with Ruby. It draws
  # its own digits (lib/barcoder/font.rb) rather than depend on an imaging
  # library for ten glyphs.
end
