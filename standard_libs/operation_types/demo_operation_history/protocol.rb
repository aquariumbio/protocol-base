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
  include TestFixtures
  include TestMetrics
  include ProvenanceFinder
  include Debug

  INPUT_NAME = 'DNA Library'
  STOP_AT = nil # 'Purify Gel Slice (NGS)'

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]
    @metrics = {}

    setup!

    operation_histories = {}
    operations.each do |op|
      item_id = op.input(INPUT_NAME).item.id
      operation_histories[op.id] = get_history(item_id: item_id)
    end
    report_metrics

    operation_histories.each_value { |oh| report_predecessors(oh) }

    rval
  end

  def get_history(item_id:)
    start = Time.now
    operation_history = OperationHistoryFactory.new.from_item(
      item_id: item_id,
      stop_at: STOP_AT
    )
    add_metric(:operation_history, Time.now - start)
    operation_history
  end

  def setup!
    items = get_items
    test_items = items.dup

    raise "This test must be initilaized with <= #{items.length} operations" if operations.length > items.length

    operations.each do |op|
      item = items.shift
      generic_input(operation: op, item: item, name: INPUT_NAME)
    end

    seed_op = operations.first
    operation_type = seed_op.operation_type
    user_id = seed_op.user_id
    status = seed_op.status

    items.each do |item|
      op = operation_type.operations
                         .create(status: status, user_id: user_id)
      generic_input(operation: op, item: item, name: INPUT_NAME)
      operations.append(op)
    end

    test_operations(operations: operations, items: test_items, input_name: INPUT_NAME)
  end

  def test_operations(operations:, items:, input_name:)
    @assertions[:assert_equal].append([operations.length, items.length])
    @assertions[:assert].append(operations.all? { |op| op.inputs.one? && op.outputs.blank? })
    @assertions[:assert].append(operations.all? { |op| op.status == 'running' })
    @assertions[:assert].append(operations.map(&:user_id).uniq.one?)
    @assertions[:assert_equal].append([operations.map { |op| op.input(input_name).item }, items])
  end

  def get_items
    # item_ids = [
    #   503_688,
    #   503_689,
    #   503_690,
    #   503_691,
    #   503_692,
    #   503_693,
    #   503_694,
    #   503_695,
    #   503_696,
    #   503_697,
    #   503_698,
    #   503_699,
    #   503_700,
    #   503_701,
    #   503_702
    # ]

    # item_ids = [
    #   503_688,
    #   503_689,
    #   503_690
    # ]

    item_ids = [
      503_688
    ]
    items = Item.find(item_ids)
    @assertions[:assert_equal].append([item_ids.length, items.length])
    @assertions[:assert].append(items.all? { |i| i.object_type.name == 'Illuminated Fragment Library' })
    items
  end

  def report_predecessors(operation_history)
    show do
      operation_history.each do |om|
        note "#{om.id} #{om.name}: #{om.predecessor_ids}"
      end
    end
  end
end
