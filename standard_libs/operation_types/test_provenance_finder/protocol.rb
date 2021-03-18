# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/ProvenanceFinder'
needs 'Standard Libs/Debug'

class Protocol
  require 'csv'

  include TestFixtures
  include ProvenanceFinder
  include Debug

  CSV_FILE_KEY = :csv_file

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]
    @metrics = {}

    output_items = setup(operations: operations)

    operation_history = get_history(item_id: output_items.first.id)
    report_metrics

    enumerate_data(operation_history)
    report_metrics

    csv = get_csv(operation_history, 'Foo Baz').first
    test_csv(csv)

    report_predecessors(operation_history)

    test_found_ops(operation_history.map(&:name))

    test_root(operation_history, operation_type.id)

    rval
  end

  def setup(operations:)
    output_items = []
    operations.each do |op|
      terminal_fv = generic_output(operation: op)
      output_items.append(terminal_fv.item)

      primary_sample = terminal_fv.sample
      pred_op = add_predecessor_op(successor_op: op, sample: primary_sample,
                                   predecessor_name: 'Foo Bar')
      generic_input(operation: pred_op, item: generic_item, name: 'Secondary Input')

      pred_op = add_predecessor_op(successor_op: pred_op, sample: primary_sample,
                                   predecessor_name: 'Foo Baz')
      pred_op.associate(CSV_FILE_KEY, generic_csv)

      Array.new(2) { generic_sample }.each do |sample|
        add_predecessor_op(successor_op: pred_op, sample: sample,
                           predecessor_name: 'Foo Bif')
      end
    end
    output_items
  end

  def add_predecessor_op(successor_op:, sample:, predecessor_name:)
    shared_item = generic_item(sample: sample)
    in_fv = generic_input(operation: successor_op, item: shared_item)
    pred_op = empty_operation(name: predecessor_name)
    generic_output(operation: pred_op, item: in_fv.item)
    pred_op
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
        note "#{om.id}: #{om.predecessor_ids}"
      end
    end
  end

  def add_metric(key, value)
    @metrics[key] = [] unless @metrics[key]
    @metrics[key].append(value)
  end

  def report_metrics(clear: true)
    metrics = @metrics
    show do
      metrics.each do |k, v|
        note "#{k}: #{average_in_milliseconds(v)} ms"
      end
    end
    @metrics = {} if clear
  end

  def average_in_milliseconds(values)
    ((values.sum(0.0) / values.length) * 1000).round(2)
  end

  def test_found_ops(actual)
    expected = [
      'Test Provenance Finder',
      'Foo Bar',
      'Foo Baz',
      'Foo Bif',
      'Foo Bif'
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
      csv << ['Test', 'CSV', 'File']
      csv << [0, 1, 2]
      csv << [4, 5, 6]
      csv << [7, 8, 9]
    end
  end

  def test_csv(actual)
    @assertions[:assert_equal].append([generic_csv, actual])
  end
end
