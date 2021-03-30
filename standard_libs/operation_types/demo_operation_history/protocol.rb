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
  STOP_AT = 'High-Efficiency Transformation NEW'

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]
    @metrics = {}

    setup!

    items = operations.map { |op| op.input(INPUT_NAME).item }

    search_again = true

    while search_again
      responses = show do
        title 'Demo Protocol for Data Retrieval from Operation History'

        note "This protocol demonstrates the retrieval of data for items #{items.to_sentence}"
        note "The search will not retrieve data for operations preceeding \"#{STOP_AT}\". " \
          'If you would like to specify a different stopping point, do so below.'
        label = 'Enter the name of the operation type you would like to stop at:'
        get 'text', var: :stop_at, label: label, default: STOP_AT
      end

      stop_at = responses.get_response(:stop_at)
      stop_at = STOP_AT if debug

      operation_histories = {}
      operations.each do |op|
        item_id = op.input(INPUT_NAME).item.id
        operation_histories[op.id] = get_history(item_id: item_id, stop_at: stop_at)
      end

      all_keys = operation_histories.values.map(&:all_keys).flatten.uniq.sort
      tbl = all_keys.in_groups_of(5, '')
      responses = show do
        title 'Select Data Keys'

        note 'The following data keys have been detected:'
        table tbl
        label = 'Enter the keys that you would like to retrieve:'
        get 'text', var: :data_keys, label: label
      end

      keys = responses.get_response(:data_keys)
      keys = 'protease protease_concentration frac_positive' if debug
      keys = keys.scan(OperationMap.key_pattern)

      data_table = [['Item'] + keys]
      operation_histories.each do |op_id, operation_history|
        operation = operations.find { |op| op.id == op_id }
        row = [operation.input(INPUT_NAME).item.to_s]
        keys.each { |key| row.append(operation_history.display_data(key)) }
        data_table.append(row)
      end

      responses = show do
        title 'Found Data'

        table data_table
        select %w[no yes], var: :search_again, label: 'Would you like to search again?'
      end

      search_again = responses.get_response(:search_again) == 'yes'
      search_again = false if debug
    end

    rval
  end

  def get_history(item_id:, stop_at:)
    start = Time.now
    operation_history = OperationHistoryFactory.new.from_item(
      item_id: item_id,
      stop_at: stop_at
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

    item_ids = [
      503_688,
      503_689,
      503_690
    ]

    # item_ids = [
    #   503_688
    # ]
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
