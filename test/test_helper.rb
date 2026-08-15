# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "barcoder"

require "minitest/autorun"

# The two conveniences these tests were written against.
#
# They came from `ActiveSupport::TestCase`, which Barcoder will not depend on: a
# gem whose entire claim is "no dependencies, no I/O" should not pull Rails into
# anyone's development bundle to run its own suite. They are small enough to
# carry, and carrying them keeps the tests exactly as they were written.
#
class Minitest::Test

  # `test "does a thing" do … end` — a readable name instead of a method name.
  #
  # @param name [String] what the test asserts.
  #
  # @return [void]
  #
  def self.test(name, &block)
    define_method("test_#{ name.gsub(/\s+/, '_') }", &block)
  end

  # `assert_not*` — Rails' spelling of Minitest's `refute*`.
  #
  def assert_not(object, message = nil)          = refute(object, message)
  def assert_not_equal(expected, actual, msg = nil)  = refute_equal(expected, actual, msg)
  def assert_not_includes(collection, object, msg = nil) = refute_includes(collection, object, msg)
  def assert_not_nil(object, message = nil)      = refute_nil(object, message)
  def assert_not_empty(object, message = nil)    = refute_empty(object, message)
end
