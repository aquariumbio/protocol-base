# typed: false
# frozen_string_literal: true

# Provides fixures for testing such as Samples and Collections
#
module TestFixtures
  PROJECT = "Protocol Testing"
  DESCRIPTION = 'No description'
  GENERIC_SAMPLE = 'Generic Sample'
  GENERIC_SAMPLE_TYPE = "#{GENERIC_SAMPLE} Type"
  GENERIC_CONTAINER = 'Generic Container'
  GENERIC_COLLECTION = 'Generic Collection'
  GENERIC_COLLECTION_TYPE = "#{GENERIC_COLLECTION} Type"

  def generic_input(operation:)
    generic_io(operation: operation, role: 'input')
  end

  def generic_output(operation:)
    generic_io(operation: operation, role: 'output')
  end

  def generic_io(operation:, role:)
    sample = generic_sample
    item = generic_item(sample: sample)

    field_type = FieldType.new(
      name: GENERIC_CONTAINER,
      ftype: 'sample',
      parent_class: 'OperationType',
      parent_id: nil
    )
    field_type.save

    field_value = FieldValue.new(
      name: GENERIC_CONTAINER,
      child_item_id: item.id,
      child_sample_id: sample.id,
      role: role,
      parent_class: 'Operation',
      parent_id: operation.id,
      field_type_id: field_type.id
    )
    field_value.save
    field_value
  end

  def generic_part_input(operation:)
    generic_part_io(operation: operation, role: 'input')
  end

  def generic_part_output(operation:)
    generic_part_io(operation: operation, role: 'output')
  end

  def generic_part_io(operation:, role:)
    sample = generic_sample
    collection = generic_collection
    collection.assign_sample_to_pairs(sample, [[0,0]])

    field_type = FieldType.new(
      name: GENERIC_COLLECTION,
      ftype: 'sample',
      parent_class: 'OperationType',
      parent_id: nil
    )
    field_type.save

    field_value = FieldValue.new(
      name: GENERIC_COLLECTION,
      child_item_id: collection.id,
      child_sample_id: sample.id,
      role: role,
      parent_class: 'Operation',
      parent_id: operation.id,
      field_type_id: field_type.id,
      row: 0,
      column: 0
    )
    field_value.save
    field_value
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

  # Provides a generic Collection with 8 rows and 12 columns.
  #    Creates a generic ObjectType if none exists.
  #
  # @return [Collection]
  def generic_collection
    Collection.new_collection(generic_collection_type)
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
        handler: "collection",
        safety: "No safety information",
        clean_up: "No cleanup information",
        data: "No data",
        vendor: "No vendor information",
        unit: "each",
        cost: 0.01,
        release_method: "return",
        release_description: "",
        image: "",
        prefix: "",
        rows: 8,
        columns: 12
      }
    )
    object_type.save
    object_type
  end

  def generic_item(sample: generic_sample)
    item = Item.new(
      quantity: 1, inuse: 0,
      object_type_id: generic_container_type.id,
      sample_id: sample.id
    )
    item.save
    item
  end

  def generic_container_type
    object_type = ObjectType.find_by_name("Generic Container Type")
    return object_type if object_type.present?

    ObjectType.create_from(
      {
        name: "Generic Container Type",
        description: "A generic container for testing purposes",
        min: 0,
        max: 1,
        handler: "sample_container",
        safety: "No safety information",
        clean_up: "No cleanup information",
        data: "No data",
        vendor: "No vendor information",
        unit: "each",
        cost: 0.01,
        release_method: "return",
        release_description: "",
        image: "",
        prefix: "",
        rows: nil,
        columns: nil
      }
    )
  end

  # Random string for giving fixture objects unique names.
  #
  # @return [String]
  def random_id
    SecureRandom.hex(3)
  end

  # Provides a standard hash for recording assertions to be tested
  #   in the analyze block of test.rb. This hash should be merged with
  #   the protocols return value.
  #
  # @return [Hash]
  def assertions_framework
    {
      assertions: {
        assert: [],
        assert_equal: [],
        assert_not_equal: [],
        assert_match: [],
        assert_no_match: [],
        assert_nil: [],
        assert_not_nil: []
      }
    }
  end
end