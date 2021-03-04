module ProvenanceFinder
  # Finds output FieldValues for a given Item id.
  #
  # @param item_id [int] id of an Item
  # @param row [string] the row location if the Item is a collection
  # @param col [string] the column location if the Item is a collection
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
  # @param row [string] the row location if the Item is a collection
  # @param col [string] the column location if the Item is a collection
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
  # @param row [string] the row location if the Item is a collection
  # @param col [string] the column location if the Item is a collection
  # @return [Array] Operations that produced this item
  def predecessor_ops(item_id, row = nil, col = nil, successor_ids = [])
    ops = output_fvs(item_id, row, col).map(&:operation)
    ops.reject { |op| successor_ids.include?(op.id) }
  end

  # Finds Operations for which a given Item is an input.
  #
  # @param item_id [int] id of an Item
  # @param row [string] the row location if the Item is a collection
  # @param col [string] the column location if the Item is a collection
  # @return [Array] Operations that used this item as input
  def successor_ops(item_id, row = nil, col = nil, predecessor_ids = [])
    ops = input_fvs(item_id, row, col).map(&:operation)
    ops.reject { |op| predecessor_ids.include?(op.id) }
  end

  # Recursively finds the Operation backchain for a given item.
  # Goes back to a specified OperationType, then stops.
  #
  # @param stop_at [string] name of the OperationType of the Operation to stop at
  # @param item_id [int] id of an Item
  # @param row [string] the row location if the Item is a collection
  # @param col [string] the column location if the Item is a collection
  # @param operation_history [Array] the list of operations to be returned
  # @return [Array] the Operation backchain
  def walk_back(stop_at, item_id, row: nil, col: nil, successor: nil, operation_history: nil)
    operation_history ||= OperationHistory.new

    successor_ids = operation_history.flatten.map(&:id)
    pred_ops = predecessor_ops(item_id, row, col, successor_ids)
    return operation_history unless pred_ops.present?

    pred_op = pred_ops.max_by { |op| op.jobs.max_by(&:id) }
    operation_map = OperationMap.new(operation: pred_op)
    last = successor || operation_history.last
    last.add_predecessors(operation_map) if last.respond_to?(:add_predecessors)
    operation_history.append(operation_map)
    return operation_history if operation_map.name == stop_at

    begin
      input_fv = get_input_fv(pred_op, item_id)
    rescue InputNotFoundError => e
      puts e.message
      return operation_history
    end

    if input_fv.field_type.array
      branches = OperationHistory.new
      pred_op.input_array(input_fv.name).each do |fv|
        branches.append(walk_back(stop_at, fv.child_item_id,
                                  row: fv.row, col: fv.column, successor: operation_map))
      end
      operation_history.append(branches)
    end

    walk_back(stop_at, input_fv.child_item_id,
              row: input_fv.row, col: input_fv.column, operation_history: operation_history)
  end

  # Gets the completion date for the most recent Job for a given Operation.
  #
  # @param op [Operation]
  # @return [DateTime]
  def job_completed(op)
    jobs = op.jobs.sort_by(&:updated_at)
    jobs.last.updated_at
  end

  # Determines the most likely input FieldValue for a given Operation and output Item.
  #
  # @param op [Operation] the Operation to search within
  # @param output_item_id [int] the id of the output Item
  # @return [FieldValue] the most likely input
  def get_input_fv(op, output_item_id)
    # If only one input, then the answer is obvious
    inputs = op.inputs
    return inputs[0] if inputs.length == 1

    # If more than one input, then it attempts to use routing
    routing_matches = get_routing_matches(op, output_item_id)
    return routing_matches[0] if routing_matches.present?

    # If no routing (bad developer!) then it attempts to match Sample name
    sample_name_matches = get_sample_name_matches(op, output_item_id)
    return sample_name_matches[0] if sample_name_matches.present?

    # Gives up
    raise InputNotFoundError, "No input for output item #{output_item_id} in operation #{op.id}."
  end

  # Returns input FieldValues for the given Operation with the same routing as the given output Item
  #
  # @param op [Operation]
  # @param output_item_id [int]
  # @return [Array] input FieldValues that have the same routing as the output
  def get_routing_matches(op, output_item_id)
    fvs = FieldValue.where(
      role: 'output',
      parent_id: op.id,
      parent_class: 'Operation',
      child_item_id: output_item_id
    )

    fv = fvs.last
    op.inputs.select { |i| i.field_type && i.field_type.routing == fv.field_type.routing }
  end

  # Returns input FieldValues for the given Operation with the same Sample name as the given output Item
  #
  # @param op [Operation]
  # @param output_item_id [int]
  # @return [Array] input FieldValues that have the same sample name as the output
  def get_sample_name_matches(op, output_item_id)
    sn = Item.find(output_item_id).sample&.name
    op.inputs.select { |i| i.sample && i.sample&.name == sn }
  end
end

class OperationHistory < Array
  # def append(operation_map)
  #   unless operation_map.is_a?(OperationMap)
  #     raise ArgumentError, 'Argument is not an OperationMap'

  #   super.append(operation_map)
  # end

  # def concat(operation_maps)
  #   operation_maps.map { |om| append(om) }
  # end
end

class OperationMap
  attr_reader :predecessor_ids

  def initialize(operation:, predecessors: nil)
    if operation.is_a?(Operation)
      @operation = operation
    elsif operation.is_a?(FixNum)
      @operation = Operation.find(operation)
    end

    @predecessor_ids = []
    add_predecessors(predecessors) if predecessors.present?
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
    Operation.find(id).operation_type
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
