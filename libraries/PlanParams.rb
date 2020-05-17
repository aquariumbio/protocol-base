# frozen_string_literal: true

# Module for handling options passed to a `Plan` or to `Operations`
# @author Devin Strickland <strcklnd@uw.edu>
module PlanParams
  # Gets `:options` from the `Plan` associations and the `Operations` and uses
  #   them to override `default_job_params`
  #
  # @param operations [OperationList] the operations
  # @param default_job_params [Hash] the default parameters to be applied to all
  #   `Operations` in the `Job`
  # @return [Hash] the updated parameters to be applied to all
  #   `Operations` in the `Job`
  def update_job_params(operations:, default_job_params:)
    opts = strict_plan_options(operations)
    job_params = update_plan_params(plan_params: default_job_params, opts: opts)
    return job_params unless options_for?(operations)

    update_from_operations(
      operations: operations,
      job_params: job_params
    )
  rescue IncompatibleParametersError => e
    error_operations(operations: operations, err: e)
  end

  # Get Plan options from a list of Operations; raised an exception unless all
  #   Operations come from the same Plan
  #
  # @param operations [Array<Operation>] the Operations
  # @return [String] the options
  def strict_plan_options(operations)
    plans = operations.map(&:plan).uniq

    if plans.length > 1
      plan_ids = plans.map(&:id)
      msg = 'Operations must all be from a single Plan.' \
      " #{plan_ids.length} Plans found: #{plan_ids.to_sentence}"
      raise IncompatibleParametersError, msg
    end

    operations.first.plan.associations[:options]
  end

  # Check to see if any of the `Operations` have `Options` set
  #
  def options_for?(operations)
    operations.any? { |op| op.input('Options').try(:val).present? }
  end

  # Gets :options from the plan associations and uses it to override
  #   default_plan_params
  #
  # @return [Hash] plan_params
  def update_plan_params(plan_params:, opts:)
    plan_params.update(parse_options(opts)) if opts.present?
    plan_params
  end

  # Parses JSON formatted options
  #
  # @param opts [String] JSON-formatted string
  # @return [Hash]
  def parse_options(opts)
    JSON.parse(opts, { symbolize_names: true })
  end

  # Gets `Options` from each `Operation` and uses them to update
  #   `default_operation_params`, then applies the result to each
  #   `Operation` at `op.temporary[:options]`
  #
  # @param operations [OperationList] the operations
  # @param default_operation_params [Hash] the default parameters to be applied
  #   to all `Operations` in the `Job`
  # @return [void]
  def update_operation_params(operations:, default_operation_params:)
    operations.each do |op|
      opts = default_operation_params.dup.update(op.input('Options').val)
      op.temporary[:options] = opts
    end
  end

  ########## TESTING METHODS ##########

  TEST_PARAMS = {
    who_is_on_first: false
  }.freeze

  # Set everything up for testing using options
  #
  # @param operations [OperationList] the operations
  # @param options [Hash] the options
  # @return [void]
  def setup_test_options(operations:, opts: TEST_PARAMS)
    associate_plan_options(operations: operations, opts: opts)
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

  private

  # Update job_params based on options for the given operations
  #
  def update_from_operations(operations:, job_params:)
    job_params.keys.each do |key|
      val = collate_options(operations: operations, key: key)
      apply_update(job_params: job_params, key: key, val: val)
    end
    job_params
  end

  # Get a list of option values for a given key from the given operations list,
  #   or raise exception if there is more than one unique value
  #
  def collate_options(operations:, key:)
    val = operations.map { |op| get_option(operation: op, key: key) }
    unless val.uniq.length == 1
      msg = "More than one value given in Operation Options for #{key}:" \
            " #{val}"
      raise IncompatibleParametersError, msg
    end
    val.first
  end

  # Get an option value for a given key from the given operation
  #
  def get_option(operation:, key:)
    operation.input('Options').val.fetch(key, :no_key)
  end

  # Update the job_params if the value is meaningful
  #
  def apply_update(job_params:, key:, val:)
    job_params[key] = val unless val == :no_key
  end

  # Say you're quitting due to an error and error all the operations
  #
  def error_operations(operations:, err:)
    show do
      title 'Incompatible Parameters Detected'
      warning err.message
    end

    operations.each { |op| op.error(:incompatible_parameters, err.message) }
  end

  class IncompatibleParametersError < ProtocolError; end
end
