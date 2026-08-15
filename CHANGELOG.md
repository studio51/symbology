# Changelog

All notable changes to Symbology are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Extracted from games.directory, where it was built in-tree at `gems/barcoder`.
  History is preserved.
- Apache-2.0 licence, replacing the placeholder that deliberately deferred the
  decision to extraction time.

### Changed

- Renamed to `Symbology`, from `Barcoder`. `barcoder` on RubyGems is a dormant
  2010 GBarcode wrapper, and rather than carry a vendor prefix the gem took the
  industry's own word for a barcode family — which was already its internal
  vocabulary. The abstract base that subclasses inherit from is `Symbology::Base`
  (it held the name `Symbology` before), and `Barcoder.symbology_for` is
  `Symbology.of`; `for` is a Ruby keyword and cannot be a method name here.
- The suite runs on plain Minitest. It was written against
  `ActiveSupport::TestCase`, and the two conveniences it used — `test "…" do` and
  the `assert_not*` spellings — are now carried in `test/test_helper.rb`. A gem
  whose entire claim is that it depends on nothing should not put Rails in
  anyone's development bundle to run its own tests.

## [0.1.0]

### Added

- EAN-13, UPC-A and EAN-8 encoding, with the symbology chosen from the digit
  count and the check digit verified before anything is drawn.
- SVG rendering — plain rectangles and text, no defs or CSS, so it survives being
  inlined into a page or opened in an editor.
- PNG rendering — one bit per pixel through a two-colour palette, written against
  the specification with no imaging dependency, and with an optional transparent
  background.
- Printed digits laid out the way the standards specify: guard bars descending
  through the text band, an EAN-13's leading digit in the left quiet zone, and a
  UPC-A's number-system and check digits set outside the bars.
