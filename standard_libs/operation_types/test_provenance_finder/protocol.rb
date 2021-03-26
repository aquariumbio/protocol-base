# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/TestMetrics'
needs 'Standard Libs/ProvenanceFinder'
needs 'Standard Libs/Debug'

class Protocol
  require 'csv'

  include TestFixtures
  include TestMetrics
  include ProvenanceFinder
  include Debug

  CSV_FILE_KEY = :csv_file

  VERBOSE = false

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]
    @metrics = {}

    output_items = setup(operations: operations)

    operation_histories = {}
    output_items.each do |output_item|
      operation_histories[output_item.id] = get_history(item_id: output_item.id)
    end
    report_metrics

    operation_histories.each_value do |operation_history|
      enumerate_data(operation_history)
    end
    report_metrics

    operation_history = operation_histories.values.first

    report_predecessors(operation_history)

    return rval

    csv = get_csv(operation_history, 'T-4A (csv)').first
    test_csv(csv)

    test_found_ops(operation_history.map(&:name))

    test_root(operation_history, operation_type.id)

    rval
  end

  def setup(operations:)
    output_items = []
    operations.each do |predecessor_op|
      # Build the terminal (T-0) operation provided by the ProtocolTest.setup block
      terminal_output = generic_output(operation: predecessor_op)
      output_items.append(terminal_output.item)
      primary_sample = terminal_output.sample
      predecessor_input = generic_input(
        operation: predecessor_op,
        item: generic_item(sample: primary_sample)
      )
      inspect_operation(predecessor_op) if VERBOSE

      # Build T-1 operation having a second input
      successor_input = predecessor_input
      predecessor_op = add_predecessor_op(
        successor_input: successor_input,
        predecessor_name: 'T-1'
      )
      predecessor_input = generic_input(
        operation: predecessor_op,
        item: generic_item(sample: primary_sample)
      )
      secondary_input = generic_input(
        operation: predecessor_op,
        item: generic_item,
        name: 'Secondary Input'
      )
      inspect_operation(predecessor_op) if VERBOSE

      # Build T-2 operation having a pass-through item
      successor_input = predecessor_input
      predecessor_op = add_predecessor_op(
        successor_input: successor_input,
        predecessor_name: 'T-2 (pass-through)'
      )
      predecessor_output = predecessor_op.output(GENERIC_CONTAINER)
      predecessor_input = generic_input(operation: predecessor_op, item: predecessor_output.item)
      inspect_operation(predecessor_op) if VERBOSE

      # Build a T-3 operation having a CSV file attachment
      successor_input = predecessor_input
      predecessor_op = add_predecessor_op(
        successor_input: successor_input,
        predecessor_name: 'T-3 (routing)'
      )
      predecessor_output = predecessor_op.output(GENERIC_CONTAINER)
      routing = 'R'
      set_routing(field_value: predecessor_output, routing: routing)

      # Build two T-4 operations, each with a new sample
      alphabet = ('A'..'Z').to_a
      branch_ends = []
      2.times do |i|
        letter = alphabet[i]
        predecessor_input = generic_input(
          operation: predecessor_op,
          item: generic_item
        )
        set_routing(field_value: predecessor_input, routing: routing)
        inspect_operation(predecessor_op) if VERBOSE

        successor_input = predecessor_input
        branch_op = add_predecessor_op(
          successor_input: successor_input,
          predecessor_name: "T-4#{letter} (csv)"
        )
        branch_op.associate(CSV_FILE_KEY, generic_csv)
        inspect_operation(branch_op) if VERBOSE

        # Build T-5 and T-6 operations for each branch
        branch_ends.append(extend_branch(branch_op: branch_op, n_ops: 2, letter: letter, number: 4))
      end

      # Build a T-7 operation that feeds both branches from separate outputs
      branch_inputs = branch_ends.map { |op| generic_input(operation: op) }
      successor_input = branch_inputs.shift
      predecessor_op = add_predecessor_op(
        successor_input: successor_input,
        predecessor_name: 'T-7 (two output branch)'
      )
      branch_inputs.each { |bi| generic_output(operation: predecessor_op, item: bi.item) }

      # Build a second T-7 operation that feeds both branches from the same output
      shared_item = generic_item
      branch_inputs = []
      branch_ends.each { |op| branch_inputs.append(generic_input(operation: op, item: shared_item)) }
      predecessor_op = add_predecessor_op(
        successor_input: branch_inputs.first,
        predecessor_name: 'T-7 (one output branch)'
      )
      branch_ends.each { |op| inspect_operation(op) } if VERBOSE
      inspect_operation(predecessor_op) if VERBOSE
    end

    output_items
  end

  def extend_branch(branch_op:, n_ops: 1, letter: nil, number: 0)
    n_ops.times do |i|
      predecessor_input = generic_input(
        operation: branch_op,
        item: generic_item
      )

      successor_input = predecessor_input
      branch_op = add_predecessor_op(
        successor_input: successor_input,
        predecessor_name: "T-#{number + i + 1}#{letter}"
      )
      inspect_operation(branch_op) if VERBOSE
    end
    branch_op
  end

  def add_predecessor_op(successor_input:, predecessor_name:)
    predecessor_op = empty_operation(name: predecessor_name)
    generic_output(operation: predecessor_op, item: successor_input.item)
    predecessor_op
  end

  def set_routing(field_value:, routing:)
    field_value.field_type.routing = routing
    field_value.field_type.save
  end

  def inspect_operation(operation)
    show do
      title "Operation #{operation.id}: #{operation.name}"

      note 'Outputs'
      operation.outputs.each { |fv| note "#{fv.name}: #{fv.sample&.name} #{fv.item&.id} (#{fv.routing})" }

      note 'Inputs'
      operation.inputs.each { |fv| note "#{fv.name}: #{fv.sample&.name} #{fv.item&.id}  (#{fv.routing})" }
    end
  end

  def get_history(item_id:)
    start = Time.now
    operation_history = OperationHistoryFactory.new.from_item(item_id: item_id)
    add_metric(:operation_history, Time.now - start)
    operation_history
  end

  def report_predecessors(operation_history)
    show do
      operation_history.each do |om|
        note "#{om.id} #{om.name}: #{om.predecessor_ids}"
      end
    end
  end

  def test_found_ops(actual)
    expected = [
      'Test Provenance Finder',
      'Foo Bar',
      'Foo Baz',
      'Foo Bif',
      'Foo 0',
      'Foo 1',
      'Foo 2',
      'Foo 0',
      'Foo 1',
      'Foo 2'
    ]
    @assertions[:assert_equal].append([expected, actual])
  end

  def test_root(operation_history, operation_type_id)
    term_ops = operation_history.terminal_operations
    @assertions[:assert].append(term_ops.length == 1)
    @assertions[:assert_equal].append([
                                        operation_type_id,
                                        term_ops.first.operation_type.id
                                      ])
  end

  def enumerate_data(operation_history)
    methods = %i[
      input_samples
      input_parameters
      input_data
      operation_data
      output_samples
      output_data
    ]
    start = Time.now
    operation_history.each do |om|
      methods.each do |method|
        s = Time.now
        om.send(method)
        add_metric(method, Time.now - s)
      end
    end
    add_metric(:enumeration, Time.now - start)
  end

  def get_csv(operation_history, operation_name)
    operation_map = operation_history.find { |om| om.name == operation_name }
    operation_map.operation_data[CSV_FILE_KEY]
  end

  def generic_csv
    CSV.generate do |csv|
      csv << %w[Test CSV File]
      csv << [0, 1, 2]
      csv << [4, 5, 6]
      csv << [7, 8, 9]
    end
  end

  def test_csv(actual)
    @assertions[:assert_equal].append([generic_csv, actual])
  end
end
