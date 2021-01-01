# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(1)
  end

  def analyze
    assert_equal(@backtrace.last[:operation], 'complete')
    rval = @backtrace.last[:rval]

    test_row = ["P1", "P1", 16, 17, 18, 19, "P2", "P2", 20, 21, 22, 23]
    assert_equal(rval[:layout_table][2], test_row)
  end
end