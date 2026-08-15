# Install & setup

## Requirements

Ruby 3.2+ — `Data.define` is used for the value objects an encoded symbol is
made of. Nothing else. Barcoder has no dependencies and never will: the only
thing it needs that it does not do itself is zlib, to deflate a PNG's image
data, and that ships with Ruby.

## Quick start

```ruby
gem "studio51-barcoder"
```

```ruby
require "barcoder"

Barcoder.svg("5901234123457")             #=> "<svg xmlns=…"
Barcoder.png("5901234123457", height: 40) #=> "\x89PNG\r\n…"
```

## Development

```sh
bundle install
bundle exec rake
bundle exec rubocop
```

The tests assert the encodings against the reference patterns published for
`5901234123457`, `036000291452` and `96385074`, and read the modules back out of
a rendered PNG to check the picture says what the pattern does.

Minitest is the only test dependency. The two `ActiveSupport::TestCase`
conveniences the suite was written against — `test "…" do` and `assert_not*` —
are carried in `test/test_helper.rb` rather than pulling Rails into the
development bundle of a gem whose whole claim is that it needs nothing.

