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
    setup_test_options(operations: operations) if debug

    # Check the initial state
    inspect default_job_params, 'default_job_params'
    inspect default_operation_params, 'default_operation_params'
    opts = operations.first.plan.associations[:options]
    inspect parse_options(opts), 'plan options'

    @job_params = update_job_params(
      operations: operations,
      default_job_params: default_job_params
    )
    return {} if operations.errored.any?

    # Check the updated job_params
    inspect @job_params, 'final job_params'
    # Check the operation options
    operations.each_with_index do |op, i|
      inspect op.input('Options').val, "Operation #{i + 1} input options"
    end

    update_operation_params(
      operations: operations,
      default_operation_params: default_operation_params
    )

    # Check the updated operation options
    operations.each_with_index do |op, i|
      inspect op.temporary[:options], "Operation #{i + 1} final options"
    end
  end
end
