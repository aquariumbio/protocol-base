class ProtocolTest < ProtocolTestBase

  def setup

    add_operation
      .with_property("Options", '{ "magic_number": 24 }')

    add_operation
      .with_property("Options", '{ "magic_number": 24 }')

    add_operation
      .with_property("Options", '{ "magic_number": 24, "foo": "baz" }')

  end

  def analyze
    assert_equal(@backtrace.last[:operation], 'complete')
    rval = @backtrace.last[:rval]

    # Check the defaults
    assert_equal(rval[:default_job_params][:magic_number], 42)
    assert_equal(rval[:default_job_params][:who_is_on_first], true)
    assert_equal(rval[:default_operation_params][:foo], 'bar')

    # Check the plan params
    assert_equal(rval[:plan_params][:who_is_on_first], false)

    # Check the final job_params
    assert_equal(rval[:final_job_params][:magic_number], 24)
    assert_equal(rval[:final_job_params][:who_is_on_first], false)

    # Check the planned operation params
    assert_equal(rval[:operation_1_input_options][:foo], nil)
    assert_equal(rval[:operation_2_input_options][:foo], nil)
    assert_equal(rval[:operation_3_input_options][:foo], 'baz')

    # Check the final operation params
    assert_equal(rval[:operation_1_final_options][:foo], 'bar')
    assert_equal(rval[:operation_2_final_options][:foo], 'bar')
    assert_equal(rval[:operation_3_final_options][:foo], 'baz')

  end

end