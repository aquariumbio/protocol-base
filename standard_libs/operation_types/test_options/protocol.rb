# frozen_string_literal: true

# Options Test Protocol
# Written By Devin Strickland <strcklnd@uw.edu> 2020-04-26

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'

# Protocol class for testing PlanParams module
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include PlanParams
  include Debug

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
    rval = {}

    setup_test_options(operations: operations) if debug

    # Check the defaults
    inspect default_job_params, 'default_job_params'
    rval[:default_job_params] = default_job_params

    inspect default_operation_params, 'default_operation_params'
    rval[:default_operation_params] = default_operation_params

    # Check the plan params
    plan_params = parse_options(operations.first.plan.associations[:options])
    inspect plan_params, 'plan_params'
    rval[:plan_params] = plan_params

    # Check the planned operation params
    operations.each_with_index do |op, i|
      key = "operation_#{i + 1}_input_options"
      val = op.input('Options').val
      inspect val, key
      rval[key.to_sym] = val
    end

    @job_params = update_job_params(
      operations: operations,
      default_job_params: default_job_params
    )
    return {} if operations.errored.any?

    # Check the final job params
    inspect @job_params, 'final_job_params'
    rval[:final_job_params] = @job_params

    update_operation_params(
      operations: operations,
      default_operation_params: default_operation_params
    )

    # Check the final operation params
    operations.each_with_index do |op, i|
      key = "operation_#{i + 1}_final_options"
      val = op.temporary[:options]
      inspect val, key
      rval[key.to_sym] = val
    end

    rval
  end
end
