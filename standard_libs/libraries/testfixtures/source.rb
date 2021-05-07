# typed: false
# frozen_string_literal: true

# Provides fixures for testing such as Samples and Collections
#
module TestFixtures
  PROJECT = 'Protocol Testing'
  DESCRIPTION = 'No description'
  GENERIC_SAMPLE = 'Generic Sample'
  GENERIC_SAMPLE_TYPE = "#{GENERIC_SAMPLE} Type"
  GENERIC_CONTAINER = 'Generic Container'
  GENERIC_CONTAINER_TYPE = "#{GENERIC_CONTAINER} Type"
  GENERIC_COLLECTION = 'Generic Collection'
  GENERIC_COLLECTION_TYPE = "#{GENERIC_COLLECTION} Type"

  # Provides a generic Item of generic ObjectType. If no Sample is provided,
  #   a new generic Sample with no properties is created.
  #
  # @return [Item]
  def generic_item(sample: generic_sample)
    item = Item.new(
      quantity: 1, inuse: 0,
      object_type_id: generic_container_type.id,
      sample_id: sample.id
    )
    item.save
    item
  end

  # Provides a generic Sample with no properties. Creates a generic
  #   SampleType if none exists. Includes a random name so that each call
  #   will produce a new Sample instance.
  #
  # @return [Sample]
  def generic_sample
    Sample.creator(
      {
        name: "#{GENERIC_SAMPLE} #{random_id}",
        description: DESCRIPTION,
        sample_type_id: generic_sample_type.id,
        project: PROJECT,
        field_values: []
      }, User.find(1)
    )
  end

  # Provides a generic Collection with 8 rows and 12 columns.
  #    Creates a generic ObjectType if none exists.
  #
  # @return [Collection]
  def generic_collection
    Collection.new_collection(generic_collection_type)
  end

  def generic_input(operation:, item: nil, sample: nil, name: nil, make_item: true)
    generic_io(operation: operation, role: 'input',
               item: item, sample: sample, name: name, make_item: make_item)
  end

  def generic_output(operation:, item: nil, sample: nil, name: nil, make_item: true)
    generic_io(operation: operation, role: 'output',
               item: item, sample: sample, name: name, make_item: make_item)
  end

  def generic_part_input(operation:)
    generic_part_io(operation: operation, role: 'input')
  end

  def generic_part_output(operation:)
    generic_part_io(operation: operation, role: 'output')
  end

  # Provides a standard hash for recording assertions to be tested
  #   in the analyze block of test.rb. This hash should be merged with
  #   the protocols return value. Supports the following methods from
  #   MiniTest::Assertions:
  #     - assert
  #     - refute
  #     - assert_equal
  #     - refute_equal
  #     - assert_nil
  #     - refute_nil
  #
  # @return [Hash]
  def assertions_framework
    {
      assertions: {
        assert: [],
        refute: [],
        assert_equal: [],
        refute_equal: [],
        assert_nil: [],
        refute_nil: []
      }
    }
  end

  def empty_operation(name:)
    operation_type = empty_operation_type(name: name)
    operation_type.operations
                  .create(status: 'done', user_id: 1)
  end

  # if params[:field_types]
  #   params[:field_types].each do |ft|
  #     ot.add_new_field_type(ft)
  #   end
  # end

  def empty_operation_type(name:, category: 'Test Fixtures')
    operation_type = OperationType.find_by_name(name)
    return operation_type if operation_type

    operation_type = OperationType.new(
      name: name,
      category: category,
      deployed: true,
      on_the_fly: false
    )
    operation_type.save
    operation_type
  end

  # Random string for giving fixture objects unique names.
  #
  # @return [String]
  def random_id
    SecureRandom.hex(3)
  end

  # A generic SampleType with no properties. Creates the SampleType if
  #   it does not exist.
  #
  # @return [SampleType]
  def generic_sample_type
    sample_type = SampleType.find_by_name(GENERIC_SAMPLE_TYPE)
    return sample_type if sample_type.present?

    SampleType.create_from_raw(
      {
        name: GENERIC_SAMPLE_TYPE,
        description: DESCRIPTION
      }
    )
  end

  def generic_container_type
    object_type = ObjectType.find_by_name('Generic Container Type')
    return object_type if object_type.present?

    object_type = ObjectType.create_from(
      {
        name: GENERIC_CONTAINER_TYPE,
        description: 'A generic container for testing purposes',
        min: 0,
        max: 1,
        handler: 'sample_container',
        safety: 'No safety information',
        clean_up: 'No cleanup information',
        data: 'No data',
        vendor: 'No vendor information',
        unit: 'each',
        cost: 0.01,
        release_method: 'return',
        release_description: '',
        image: '',
        prefix: '',
        rows: nil,
        columns: nil
      }
    )
    object_type.save
    object_type
  end

  # Provides a generic Collection ObjectType with 8 rows and 12 columns.
  #   Creates the ObjectType if none exists.
  #
  # @return [ObjectType]
  def generic_collection_type
    object_type = ObjectType.find_by_name(GENERIC_COLLECTION_TYPE)
    return object_type if object_type.present?

    object_type = ObjectType.create_from(
      {
        name: GENERIC_COLLECTION_TYPE,
        description: DESCRIPTION,
        min: 0,
        max: 1,
        handler: 'collection',
        safety: 'No safety information',
        clean_up: 'No cleanup information',
        data: 'No data',
        vendor: 'No vendor information',
        unit: 'each',
        cost: 0.01,
        release_method: 'return',
        release_description: '',
        image: '',
        prefix: '',
        rows: 8,
        columns: 12
      }
    )
    object_type.save
    object_type
  end

  def generic_io(operation:, role:, item: nil, name: nil, sample: nil, make_item: true)
    if item && sample
      msg = 'If item and sample are provided the item must be of the sample.'
      raise msg unless item.sample == sample
    elsif item
      sample = item.sample
    else
      sample ||= generic_sample
      item = make_item ? generic_item(sample: sample) : nil
    end

    generic_field_value(
      name: name || GENERIC_CONTAINER,
      item: item,
      sample: sample,
      role: role,
      operation: operation
    )
  end

  def generic_part_io(operation:, role:)
    sample = generic_sample
    collection = generic_collection
    collection.assign_sample_to_pairs(sample, [[0, 0]])

    generic_field_value(
      name: GENERIC_COLLECTION,
      item: collection,
      sample: sample,
      role: role,
      operation: operation,
      row: 0,
      column: 0
    )
  end

  # Currently only supports JSON inputs
  def generic_parameter_input(name:, operation:, value: '{}')
    fv = generic_field_value(name: name, operation: operation, role: 'input')
    fv.value = value
    fv.save
  end

  # Currently only supports sample and JSON field_types
  def generic_field_value(name:, operation:, role:, item: nil, sample: nil, row: nil, column: nil)
    type = sample ? 'sample' : 'json'
    field_type = generic_field_type(name: name, type: type)

    field_value = FieldValue.new(
      name: name,
      child_item_id: item&.id,
      child_sample_id: sample&.id,
      role: role,
      parent_class: 'Operation',
      parent_id: operation.id,
      field_type_id: field_type.id,
      row: row,
      column: column
    )
    field_value.save
    field_value
  end

  def generic_field_type(name:, type: 'sample')
    field_type = FieldType.new(
      name: name,
      ftype: type,
      parent_class: 'OperationType',
      parent_id: nil
    )
    field_type.save
    field_type
  end
end
