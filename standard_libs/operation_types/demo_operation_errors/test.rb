# typed: false
# frozen_string_literal: true

# This is a default ProtocolTest that uses
#   TestFixtures::assertions_framework
#
class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(3)
  end

  def analyze
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end