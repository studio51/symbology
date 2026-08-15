# Symbology

> The number on the back of the box, drawn as the barcode it was printed as.

[![License: Apache-2.0](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)
[![CI](https://github.com/studio51/symbology/actions/workflows/ci.yml/badge.svg)](https://github.com/studio51/symbology/actions/workflows/ci.yml)

A *symbology* is what the barcode industry calls a family: EAN-13 is one, UPC-A
is another. This gem draws them — a self-contained Ruby library with **no
dependencies**, not on Rails, not on an imaging library, not on anything.
Digits in, image out.

```ruby
gem "symbology"
```

```ruby
Symbology.svg("5901234123457")             #=> "<svg xmlns=\"http://www.w3.org/2000/svg\"…"
Symbology.png("5901234123457", height: 40) #=> "\x89PNG\r\n…"

Symbology.of("036000291452")               #=> Symbology::UPCA
```

It encodes EAN-13, UPC-A and EAN-8, lays a symbol out to the proportions the
standards specify — quiet zones, guard bars descending through the printed
digits, the leading digit set in the margin — and refuses to draw a code that
fails its own check digit, because a symbol no scanner will read back is worse
than no symbol at all.

Which symbology a value is depends only on how many digits it has, so you never
have to say.

It was built in-tree at `gems/barcoder` inside
[games.directory](https://games.directory) and extracted here with its history.

## Navigation

This repository adheres to the [Studio51 Solutions Common Standard v1](https://github.com/studio51/standards/blob/main/standards/common/v1/STANDARD.md), with each section documented properly in its own file.

- [Architecture](docs/ARCHITECTURE.md) — how a symbol is built, file by file
- [Install & setup](docs/INSTALL.md)
- [Usage](docs/USAGE.md) — what it draws, what it refuses to draw, and the options
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
- [Security](SECURITY.md)

## License

[Apache-2.0](LICENSE), © 2026 Studio51 Solutions. See [NOTICE](NOTICE).
