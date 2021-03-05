# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/ProvenanceFinder'

class Protocol
  include TestFixtures
  include ProvenanceFinder

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]
    @metrics = {}

    start = Time.now
    operation_history = OperationHistoryFactory.new.from_item(item_id: 463_144)
    add_metric(:operation_history, Time.now - start)
    report_metrics

    # enumerate_data(operation_history)
    # report_metrics

    # enumerate_data(operation_history)
    # report_metrics

    test_found_ops(operation_history.map(&:name))

    test_root(operation_history)

    rval
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
      'Dilute to 4nM', 'Qubit concentration',
      'Purify Gel Slice (NGS)', 'Extract Gel Slice (NGS)',
      'Run Pre-poured Gel', 'Make qPCR Fragment WITH PLATES',
      'Purify Gel Slice (NGS)', 'Extract Gel Slice (NGS)',
      'Run Pre-poured Gel', 'Make qPCR Fragment',
      'Digest Genomic DNA', 'Yeast Plasmid Extraction', 'Treat With Zymolyase',
      'Store Yeast Library Sample', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Make Library Glycerol Stocks', 'High-Efficiency Transformation NEW',
      'Combine and Dry DNA', 'Ethanol Precipitation Cleanup',
      'DNA ethanol precipitation', 'Combine Purified Samples',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR'
    ]
    @assertions[:assert_equal].append([expected, actual])
  end

  def test_root(operation_history)
    show do
      note operation_history.terminal_operations.to_s
    end
    @assertions[:assert].append(operation_history.terminal_operations.length == 1)
  end

  def enumerate_data(operation_history)
    methods = [
      :input_samples,
      :input_parameters,
      :input_data,
      :operation_data,
      :output_samples,
      :output_data
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
end
