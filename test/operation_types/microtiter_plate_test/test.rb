# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(1)
  end

  def analyze
    assert_equal(@backtrace.last[:operation], 'complete')
    rval = @backtrace.last[:rval]
    assert_equal(rval[:next_empty_group], [[0,3],[0,4],[0,5]])
  end
end
