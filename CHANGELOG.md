# Changelog

All notable changes to Barcoder are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
