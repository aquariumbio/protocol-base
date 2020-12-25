# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(1)
  end

  def analyze
    assert_equal(@backtrace.last[:operation], 'complete')
  end
end
