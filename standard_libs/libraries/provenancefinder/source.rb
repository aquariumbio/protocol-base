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
  # @param successor_ids [Array] a list of IDs to ignore because they are not
  #   predecessors
  # @return [Array] Operations that produced this item
  def predecessor_ops(item_id, row = nil, col = nil, successor_ids = [])
    ops = output_fvs(item_id, row, col).map(&:operation)
    ops.reject { |op| successor_ids.include?(op.id) }
  end

  # Finds Operations for which a given Item is an input.
  #
  # @param item_id [int] id of an Item
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @param successor_ids [Array] a list of IDs to ignore because they are not
  #   successors
  # @return [Array] Operations that used this item as input
  def successor_ops(item_id, row = nil, col = nil, predecessor_ids = [])
    ops = input_fvs(item_id, row, col).map(&:operation)
    ops.reject { |op| predecessor_ids.include?(op.id) }
  end

  # Recursively finds the Operation backchain for a given item.
  #   Goes back to a specified OperationType, or until it can't go any further.
  #
  # @param stop_at [string] name of the OperationType of the Operation to stop at
  # @param item_id [int] id of an Item
  # @param row [int] the row location if the Item is a collection
  # @param col [int] the column location if the Item is a collection
  # @param successor [OperationMap] the successor to an OperationMap created by this method
  # @param operation_maps [Array<OperationMap>] the list of OperationMaps to be returned
  # @return [Array] the Operation backchain
  def walk_back(stop_at, item_id, row: nil, col: nil, successor: nil, operation_maps: nil)
    operation_maps ||= []

    successor_ids = operation_maps.flatten.map(&:id)
    pred_ops = predecessor_ops(item_id, row, col, successor_ids)
    return operation_maps unless pred_ops.present?

    pred_op = pred_ops.max_by { |op| op.jobs.max_by(&:id) }
    operation_map = OperationMap.new(operation: pred_op)
    last = successor || operation_maps.last
    last.add_predecessors(operation_map) if last.respond_to?(:add_predecessors)
    operation_maps.append(operation_map)
    return operation_maps if operation_map.name == stop_at

    begin
      input_fv = get_input_fv(pred_op, item_id)
    rescue InputNotFoundError => e
      puts e.message
      return operation_maps
    end

    if input_fv.field_type.array
      pred_op.input_array(input_fv.name).each do |fv|
        operation_maps.concat(walk_back(stop_at, fv.child_item_id,
                                        row: fv.row, col: fv.column,
                                        successor: operation_map))
      end
    end

    walk_back(stop_at, input_fv.child_item_id,
              row: input_fv.row, col: input_fv.column,
              operation_maps: operation_maps)
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
  # @param operation [Operation] the Operation to search within
  # @param output_item_id [int] the id of the output Item
  # @return [FieldValue] the most likely input
  def get_input_fv(operation, output_item_id)
    # If only one input, then the answer is obvious
    inputs = operation.inputs
    return inputs[0] if inputs.length == 1

    # If more than one input, then it attempts to use routing
    routing_matches = get_routing_matches(operation, output_item_id)
    return routing_matches[0] if routing_matches.present?

    # If no routing (bad developer!) then it attempts to match Sample name
    sample_name_matches = get_sample_name_matches(operation, output_item_id)
    return sample_name_matches[0] if sample_name_matches.present?

    # Gives up
    raise InputNotFoundError, "No input for output item #{output_item_id} in operation #{operation.id}."
  end

  # Returns input FieldValues for the given Operation with the same routing as the given output Item
  #
  # @param operation [Operation]
  # @param output_item_id [int]
  # @return [Array] input FieldValues that have the same routing as the output
  def get_routing_matches(operation, output_item_id)
    fvs = FieldValue.where(
      role: 'output',
      parent_id: operation.id,
      parent_class: 'Operation',
      child_item_id: output_item_id
    )

    fv = fvs.last
    operation.inputs.select { |i| i.field_type && i.field_type.routing == fv.field_type.routing }
  end

  # Returns input FieldValues for the given Operation with the same Sample name as the given output Item
  #
  # @param operation [Operation]
  # @param output_item_id [int]
  # @return [Array] input FieldValues that have the same sample name as the output
  def get_sample_name_matches(operation, output_item_id)
    sn = Item.find(output_item_id).sample&.name
    operation.inputs.select { |i| i.sample && i.sample&.name == sn }
  end
end

class OperationHistoryFactory
  include ProvenanceFinder

  def from_item(item_id:, stop_at: nil, row: nil, col: nil)
    operation_maps = walk_back(stop_at, item_id, row: row, col: col)
    OperationHistory.new(operation_maps: operation_maps)
  end
end

class OperationHistory < Array
  def initialize(operation_maps:)
    raise ArgumentError, 'Argument is not an OperationMap' unless operation_maps.all?(OperationMap)

    super(operation_maps)
  end

  def append(operation_map)
    raise ArgumentError, 'Argument is not an OperationMap' unless operation_map.is_a?(OperationMap)

    super.append(operation_map)
  end

  def concat(operation_maps)
    operation_maps.each { |om| append(om) }
  end
end

class OperationMap
  attr_reader :operation, :predecessor_ids

  def initialize(operation:, predecessors: nil)
    if operation.is_a?(Operation)
      @operation = operation
    elsif operation.is_a?(FixNum)
      @operation = Operation.find(operation)
    end

    @predecessor_ids = []
    add_predecessors(predecessors) if predecessors.present?

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
    string.to_s.strip.downcase.gsub(/[^a-z0-9?]+/, '_')
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
