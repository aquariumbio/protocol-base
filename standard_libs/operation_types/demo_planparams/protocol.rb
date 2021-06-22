# frozen_string_literal: true

# Demo PlanParams
# Written By Devin Strickland <strcklnd@uw.edu> 2020-04-26
# Revised 2021-06-21

needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'

# Protocol class for demo of PlanParams module
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include TestFixtures
  include PlanParams
  include Debug

  # Params that will be added to the plan as a data association
  TEST_PARAMS = {
    who_is_on_first: false
  }.freeze

  # Array of options that will be added to operations
  # Formatted as JSON strings
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
    setup(operations: operations)

    # Show the defaults
    show do
      title 'Default Job and Operation Params'

      note 'From the default_job_params hash'
      default_job_params.each do |k, v|
        bullet "#{k}: #{v}"
      end
      separator
      note 'From the default_operation_params hash'
      default_operation_params.each do |k, v|
        bullet "#{k}: #{v}"
      end
    end

    # Show the plan params
    plan_params = parse_options(operations.first.plan.associations[:options])
    show do
      title 'Params Associated with the Plan'

      note 'From the options hash associated with the plan'
      note 'Should match TEST_PARAMS'
      warning 'These values will override any matching keys in default_job_params'
      plan_params.each do |k, v|
        bullet "#{k}: #{v}"
      end
    end

    # Check the planned operation params
    show do
      title 'Options Associated with Operations'

      note 'From the options input associated with each operation'
      note 'Should match TEST_OPTIONS'
      warning 'These values will override any matching keys in default_operation_params'
      warning 'These values will override any matching keys in default_job_params if they are all the same value'
      operations.each_with_index do |op, i|
        separator if i.positive?
        note "operation #{i + 1} input options"
        op.input(OPTIONS).val.each do |k, v|
          bullet "#{k}: #{v}"
        end
      end
    end

    # Update job and operation params
    # Quit if the update method errors any operations
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    # Show the updated plan params (@job_params)
    # Need to use temp because @job_params isn't available in show block
    temp_job_params = @job_params.dup
    show do
      title 'Final Job Params'

      temp_job_params.each do |k, v|
        bullet "#{k}: #{v}"
      end
    end

    # Check the planned operation params
    show do
      title 'Updated Options for Operations'

      note 'From the updated options associated with each operation'
      operations.each_with_index do |op, i|
        separator if i.positive?
        note "operation #{i + 1} final options"
        op.temporary[:options].each do |k, v|
          bullet "#{k}: #{v}"
        end
      end
    end

    {}
  end

  ########## SETUP ##########

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
end
