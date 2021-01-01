# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'

class Protocol
  include TestFixtures

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    test_generic_item(item: generic_item)

    rval
  end

  # Example method for performing assertions. To use different assertions,
  #   replace :assert with one of the following:
  #     - :assert_equal
  #     - :assert_not_equal
  #     - :assert_match
  #     - :assert_no_match
  #     - :assert_nil
  #     - :assert_not_nil
  #
  def test_generic_item(item:)
    @assertions[:assert].append([
      item.class == Item,
      'generic_item is not working'
    ])
  end
end