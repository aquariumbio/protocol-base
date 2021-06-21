# frozen_string_literal: true

# Test PlanParams
# Written By Devin Strickland <strcklnd@uw.edu> 2020-04-26
# Revised 2021-06-21

needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'

# Protocol class for testing PlanParams module
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include TestFixtures
  include PlanParams
  include Debug

  TEST_PARAMS = {
    who_is_on_first: false
  }.freeze

  # JSON strings
  TEST_OPTIONS = [
    '{ "magic_number": 24 }',
    '{ "magic_number": 24 }',
    '{ "magic_number": 24, "foo": "baz" }'
  ].freeze

  OPTIONS = 'Options'

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`. These inputs will override both
  #     the defaults and any inputs that have been applied to the `Plan` ONLY IF
  #     all the values for a given key are the same for all `Operations` in
  #     a `Job`. If non-matching params are detected, an exception will
  #     be raised.
  #
  # @example "options": "{"my_option": 2.0}"
  def default_job_params
    {
      magic_number: 42,
      who_is_on_first: true
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`. These inputs will override
  #     the defaults. Operations options are accessed in the protocol using
  #     `op.temporary[:options]`.
  #
  def default_operation_params
    {
      foo: 'bar'
    }
  end

  ########## MAIN ##########

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    setup(operations: operations)

    test_planned_operation_params(operations: operations)

    test_default_job_params
    test_default_operation_params
    test_plan_params(plan: operations.last.plan)

    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    test_final_job_params

    test_final_operation_params(operations: operations)

    rval
  end

  # Set everything up for testing using options
  #
  # @param operations [OperationList] the operations
  # @param options [Hash] the options
  # @return [void]
  def setup(operations:)
    unless operations.length == TEST_OPTIONS.length
      raise "Please modify the test.rb file to add #{TEST_OPTIONS.length} random operations."
    end

    operations.zip(TEST_OPTIONS).each do |op, opt|
      generic_parameter_input(name: OPTIONS, operation: op, value: opt)
    end

    associate_plan_options(operations: operations, opts: TEST_PARAMS)
    unify_plans(operations: operations)
  end

  # Add options to the `Plan` for testing purposes
  #
  # @param operations [OperationList] the operations
  # @param options [Hash] the options
  # @return [void]
  def associate_plan_options(operations:, opts:)
    plan = operations.first.plan
    plan.associate(:options, opts.to_json)
  end

  # Make all operations have the same plan
  #
  # @param operations [OperationList] the operations
  # @return [void]
  def unify_plans(operations:)
    plan_associations = operations.map { |op| op.plan_associations.first }
    plan = operations.first.plan
    plan_associations.each do |pa|
      pa.plan = plan
      pa.save
    end

    # Needed to refresh plan associations for weird Rails reasons
    Operation.find(operations.map(&:id))
  end

  def test_default_job_params
    @assertions[:assert_equal].append([
      default_job_params[:magic_number],
      42
    ])
    @assertions[:assert_equal].append([
      default_job_params[:who_is_on_first],
      true
    ])
  end

  def test_default_operation_params
    @assertions[:assert_equal].append([
      default_operation_params[:foo],
      'bar'
    ])
  end

  def test_plan_params(plan:)
    plan_params = parse_options(plan.associations[:options])
    @assertions[:assert_equal].append([
      plan_params[:who_is_on_first],
      false
    ])
  end

  def test_final_job_params
    @assertions[:assert_equal].append([
      @job_params[:magic_number],
      24
    ])
    @assertions[:assert_equal].append([
      @job_params[:who_is_on_first],
      false
    ])
  end

  def test_planned_operation_params(operations:)
    pairs = operations.map { |op| op.input(OPTIONS).val[:foo] }.zip([nil, nil, 'baz'])
    pairs.each { |pair| @assertions[:assert_equal].append(pair) }
  end

  def test_final_operation_params(operations:)
    pairs = get_options(operations: operations, key: :foo).zip(['bar', 'bar', 'baz'])
    pairs.each { |pair| @assertions[:assert_equal].append(pair) }
  end
end
