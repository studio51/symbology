# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Barcoder itself has no dependencies and never will — see the note at the foot
# of the gemspec. Everything below is for working on it, not for using it.
#
group :development, :test do
  gem "rake"
  gem "minitest"

  gem "rubocop", ">= 1.80", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails-omakase", require: false

  # Studio51 house RuboCop cops (doc-block shape + method breathing room).
  #
  gem "rubocop-studio51", github: "studio51/standards",
                          glob: "rubocop-studio51/*.gemspec",
                          require: false,
                          ref: "08cf49d9c3fe8d559d587a4836b36d3e58600e57"
end
