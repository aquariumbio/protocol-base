# frozen_string_literal: true

# Methods for finding the chain of Operations that produced an Item.
#
# @author Devin Strickland <strcklnd@uw.edu>
module ProvenanceFinder
  # Finds output FieldValues for a given Item id.
  #
  # @param item_id [int] id of an Item
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @return [ActiveRecord::Relation] FieldValues
  def output_fvs(item_id, row = nil, col = nil)
    FieldValue.where(
      parent_class: 'Operation', role: 'output',
      child_item_id: item_id, row: row, column: col
    )
  end

  # Finds input FieldValues for a given Item id.
  #
  # @param item_id [int] id of an Item
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @return [ActiveRecord::Relation] FieldValues
  def input_fvs(item_id, row = nil, col = nil)
    FieldValue.where(
      parent_class: 'Operation', role: 'input',
      child_item_id: item_id, row: row, column: col
    )
  end

  # Finds Operations for which a given Item is an output.
  #
  # @param item_id [int] id of an Item
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @param ignore_ids [Array] a list of IDs to ignore
  # @return [Array] Operations that produced this item (may be multiple because
  #   Items can pass through Operations)
  def predecessor_ops(item_id, row = nil, col = nil, ignore_ids = [])
    ops = output_fvs(item_id, row, col).map(&:operation)
    ops.reject { |op| ignore_ids.include?(op.id) }
  end

  # Finds Operations for which a given Item is an input.
  #
  # @param item_id [int] id of an Item
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @param ignore_ids [Array] a list of IDs to ignore
  # @return [Array] Operations that used this item as input
  def successor_ops(item_id, row = nil, col = nil, ignore_ids = [])
    ops = input_fvs(item_id, row, col).map(&:operation)
    ops.reject { |op| ignore_ids.include?(op.id) }
  end

  def last_predecessor_op(item_id, row = nil, col = nil, ignore_ids = [])
    ops = predecessor_ops(item_id, row, col, ignore_ids)
    return unless ops.present?

    ops.max_by { |op| op.jobs.max_by(&:id) }
  end

  # Recursively finds the Operation backchain for a given item. Travels each branch
  #   until finding a specified OperationType, or until it can't go any further.
  #
  # @param stop_at [string] name of the OperationType of the Operation to stop at
  # @param item_id [int] id of an Item to start with
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @return [OperationHistory] the Operation backchain
  def walk_back(stop_at, item_id, row: nil, col: nil)
    visited = []
    to_visit = []
    ignore_map = Hash.new { |h,k| h[k] = [] }

    operation_map, new_to_visit = step_back(
      item_id: item_id,
      row: row, col: col
    )
    return visited unless operation_map

    visited.append(operation_map)
    new_to_visit.each { |ntv| ignore_map[ntv[:input].id].append(operation_map.id) }
    return visited if operation_map.name == stop_at

    to_visit += new_to_visit

    while to_visit.present?
      tv = to_visit.pop
      item_id = tv[:input].child_item_id
      operation_map, new_to_visit = step_back(
        item_id: item_id,
        row: tv[:input].row, col: tv[:input].column,
        ignore_ids: ignore_map[tv[:input].id] || []
      )
      next unless operation_map

      tv[:operation_map].try(:add_predecessors, operation_map)
      visited.append(operation_map)
      new_to_visit.each { |ntv| ignore_map[ntv[:input].id].append(operation_map.id) }
      next if operation_map.name == stop_at

      to_visit += new_to_visit
    end

    OperationHistory.new(operation_maps: visited)
  end

  # Finds the Operation that produced a given item. If multiple Operations have the
  #   Item as output, then returns the last one except for ones to ignore.
  #
  # @param item_id [int] id of an Item to start with
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @param ignore_ids [Array<FixNum>] IDs of operations to ignore
  # @return [OperationMap] a new OperationMap object for the found Operation
  # @return [Array<Hash>] a mapping of primary inputs for the found Operation
  def step_back(item_id:, row: nil, col: nil, ignore_ids: [])
    pred_op = last_predecessor_op(item_id, row, col, ignore_ids)
    return unless pred_op

    operation_map = OperationMapFactory.create(operation: pred_op)
    inputs = get_primary_inputs(operation_map, item_id)
    [
      operation_map,
      inputs.map { |input| { operation_map: operation_map, input: input } }
    ]
  end

  # Gets the completion date for the most recent Job for a given Operation.
  #
  # @param operation [Operation]
  # @return [DateTime]
  def job_completed(operation)
    jobs = operation.jobs.sort_by(&:updated_at)
    jobs.last.updated_at
  end

  # Determines the most likely input FieldValue for a given Operation and output Item.
  #
  # @param operation_map [OperationMap] the OperationMap to search within
  # @param output_item_id [int] the id of the output Item
  # @return [FieldValue] the most likely input
  def get_primary_inputs(operation_map, output_item_id)
    # If only one input, then the answer is obvious
    item_inputs = operation_map.item_inputs
    return item_inputs if item_inputs.length == 1

    # If more than one input, then it attempts to use routing
    routing_matches = get_routing_matches(operation_map, output_item_id)
    return routing_matches if routing_matches.present?

    # If no routing (bad developer!) then it attempts to match Sample name
    sample_name_matches = get_sample_name_matches(operation_map, output_item_id)
    return sample_name_matches if sample_name_matches.present?

    item_inputs
  end

  # Returns input FieldValues for the given Operation with the same routing as the given output Item
  #
  # @param operation_map [OperationMap] the OperationMap to search within
  # @param output_item_id [int]
  # @return [Array] input FieldValues that have the same routing as the output
  def get_routing_matches(operation_map, output_item_id)
    ofv = operation_map.output_for(output_item_id)
    operation_map.item_inputs.select { |ifv| ifv.field_type&.routing == ofv.field_type&.routing }
  end

  # Returns input FieldValues for the given Operation with the same Sample name as the given output Item
  #
  # @param operation_map [OperationMap] the OperationMap to search within
  # @param output_item_id [int]
  # @return [Array] input FieldValues that have the same sample name as the output
  def get_sample_name_matches(operation_map, output_item_id)
    sn = Item.find(output_item_id).sample&.name
    operation_map.item_inputs.select { |i| i.sample&.name == sn }
  end
end

# Factory class for OperationHistory. Takes an Item and finds the chain
#   of Operations that produced it, then converts this list of Operations into
#   an OperationHistory object. The Operations are encapsulated in
#   OperationMap objects.
#
# @author Devin Strickland <strcklnd@uw.edu>
class OperationHistoryFactory
  include ProvenanceFinder

  def from_item(item_id:, stop_at: '', row: nil, col: nil)
    walk_back(stop_at, item_id, row: row, col: col)
  end
end

# An Array of Operations collectively produced an Item. Includes methods for
#   collating and extracting specific metadata from the provenance.
#
# @author Devin Strickland <strcklnd@uw.edu>
class OperationHistory < Array
  include ActionView::Helpers::NumberHelper

  def initialize(operation_maps:)
    raise ArgumentError, 'Argument is not an array of OperationMaps' unless operation_maps.all?(OperationMap)

    super(operation_maps)
  end

  def append(operation_map)
    raise ArgumentError, 'Argument is not an OperationMap' unless operation_map.is_a?(OperationMap)

    super.append(operation_map)
  end

  def concat(operation_maps)
    operation_maps.each { |om| append(om) }
  end

  def predecessor_ids
    map(&:predecessor_ids).flatten
  end

  def operation_ids
    map(&:id)
  end

  def terminal_operations
    select { |om| (operation_ids - predecessor_ids).include?(om.id) }
  end

  def terminal_operation
    tops = terminal_operations
    raise MultipleRootsError if tops.length > 1

    tops.first
  end

  def all_keys
    map(&:all_keys)
  end

  def display_data(key)
    data = fetch_data(key)
    data.map { |d| display_datum(d) }.join(' | ')
  end

  def display_datum(datum)
    if datum.is_a?(Numeric)
      number_with_precision(datum, precision: 4, strip_insignificant_zeros: true)
    else
      datum
    end
  end

  def fetch_data(key)
    map { |om| om.fetch_data(key) }.flatten.compact
  end
end

# Factory class for OperationMap.
#
# @author Devin Strickland <strcklnd@uw.edu>
class OperationMapFactory
  def self.create(operation:)
    OperationMap.new(operation: operation)
  end
end

# An wrapper for Operations that includes methods for collating and reporting metadata.
#
# @author Devin Strickland <strcklnd@uw.edu>
class OperationMap
  attr_reader :operation, :predecessor_ids

  def initialize(operation:)
    if operation.is_a?(Operation)
      @operation = operation
    elsif operation.is_a?(FixNum)
      @operation = Operation.find(operation)
    end

    @predecessor_ids = []
    @input_samples = nil
    @input_parameters = nil
    @input_data = nil
    @output_samples = nil
    @output_data = nil
    @operation_data = nil
  end

  def name
    @operation.name
  end

  def id
    @operation.id
  end

  def add_predecessors(predecessors)
    predecessors = [predecessors] unless predecessors.is_a?(Array)
    predecessors.each { |p| add_predecessor(p) }
  end

  def add_predecessor(predecessor)
    unless predecessor.is_a?(OperationMap) || predecessor.is_a?(FixNum)
      raise ArgumentError, 'Argument must be an OperationMap or an ID'
    end

    predecessor = predecessor.id if predecessor.respond_to?(:id)
    @predecessor_ids.append(predecessor)
  end

  def operation_type
    @operation.operation_type
  end

  def make_key(string)
    string.to_s.strip.downcase.gsub(OperationMap.key_replace, '_')
  end

  def self.key_replace
    /[^a-z0-9?]+/
  end

  def self.key_pattern
    /[a-z0-9?_]+/
  end

  def all_keys
    [
      input_samples.keys,
      input_parameters.keys,
      input_data.keys,
      output_samples.keys,
      output_data.keys,
      operation_data.keys
    ].flatten.uniq.sort
  end

  def fetch_data(key)
    [
      input_samples[key],
      input_parameters[key],
      input_data[key],
      output_samples[key],
      output_data[key],
      operation_data[key]
    ].flatten.compact
  end

  def input_samples
    return @input_samples if @input_samples

    @input_samples = samples_for(@operation.inputs)
  end

  def output_samples
    return @output_samples if @output_samples

    @output_samples = samples_for(@operation.outputs)
  end

  def input_parameters
    return @input_parameters if @input_parameters

    @input_parameters = parameters_for(@operation.inputs)
  end

  def input_data
    return @input_data if @input_data

    @input_data = data_for(@operation.inputs)
  end

  def output_data
    return @output_data if @output_data

    @output_data = data_for(@operation.outputs)
  end

  def operation_data
    return @operation_data if @operation_data

    data = HashWithIndifferentAccess.new
    add_associations(data, @operation)
    @operation_data = data
  end

  def item_inputs
    @operation.inputs.select(&:child_item_id)
  end

  def output_for(item_id)
    @operation.outputs.find { |fv| fv.child_item_id == item_id }
  end

  private

  def samples_for(field_values)
    samples = HashWithIndifferentAccess.new
    field_values.each do |fv|
      next unless fv.sample

      add_data(samples, fv.name, fv.sample.name)
    end
    samples
  end

  def parameters_for(field_values)
    parameters = HashWithIndifferentAccess.new
    field_values.each do |fv|
      next unless fv.value

      params = fv.value.is_a?(Hash) ? fv.value : { fv.name => fv.value }

      params.each do |key, value|
        add_data(parameters, key, value)
      end
    end
    parameters
  end

  def data_for(field_values)
    data = HashWithIndifferentAccess.new
    field_values.each do |fv|
      next unless fv.child_item_id

      add_associations(data, fv.item)
    end
    data
  end

  def add_associations(hsh, object)
    object.associations.each do |key, value|
      value = value[:upload_file_name] if value.is_a?(Hash) && value[:upload_file_name]
      add_data(hsh, key, value)
    end
  end

  def add_data(hsh, key, value)
    key = make_key(key)
    hsh[key] = [] unless hsh[key]
    hsh[key].append(value)
    hsh
  end
end

class InputNotFoundError < StandardError
  def message
    'Could not find an input for this operation'
  end
end

class NoPredecessorsError < StandardError
  def message
    'No predecessor was found where one was expected'
  end
end

class MultipleRootsError < StandardError
  def message
    'Moltiple roots were found for this OperationHistory'
  end
end
