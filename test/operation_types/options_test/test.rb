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
    log('Hello from Nemo')
    assert_equal(@backtrace.last[:operation], 'complete')
  end

end