# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'

class Protocol
  include TestFixtures

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    test_assertions

    test_generic_sample

    test_generic_item

    test_generic_collection

    op = operations.first

    test_generic_input(operation: op)

    test_generic_part_input(operation: op)

    test_generic_output(operation: op)

    test_generic_part_output(operation: op)

    test_empty_operation_type

    test_empty_operation

    rval
  end

  def test_assertions
    @assertions[:assert].append([
      true
    ])
    @assertions[:refute].append([
      false
    ])
    @assertions[:assert_equal].append([
      'foo',
      'foo'
    ])
    @assertions[:refute_equal].append([
      'foo',
      'bar'
    ])
    @assertions[:assert_nil].append([
      nil
    ])
    @assertions[:refute_nil].append([
      1
    ])
  end

  def test_generic_sample
    s1 = generic_sample
    s2 = generic_sample
    @assertions[:assert].append([
      s1.class == Sample
    ])
    @assertions[:assert].append([
      s1.name.start_with?(GENERIC_SAMPLE)
    ])
    @assertions[:assert_equal].append([
      s1.sample_type.name,
      GENERIC_SAMPLE_TYPE
    ])
    @assertions[:assert_equal].append([
      s1.sample_type.description,
      DESCRIPTION
    ])
    @assertions[:assert_equal].append([
      s1.project,
      PROJECT
    ])
    @assertions[:refute_equal].append([
      s1,
      s2
    ])
  end

  def test_generic_item
    item = generic_item
    @assertions[:assert].append([
      item.class == Item,
    ])
    @assertions[:assert_equal].append([
      item.object_type.name,
      GENERIC_CONTAINER_TYPE
    ])
  end

  def test_generic_collection
    collection = generic_collection
    @assertions[:assert].append([
      collection.class == Collection
    ])
    @assertions[:assert_equal].append([
      collection.object_type.name,
      GENERIC_COLLECTION_TYPE
    ])
    @assertions[:assert_equal].append([
      collection.dimensions[0],
      8
    ])
    @assertions[:assert_equal].append([
      collection.dimensions[1],
      12
    ])
  end

  def test_generic_input(operation:)
    fv = generic_input(operation: operation)
    @assertions[:assert_equal].append([
      fv.role,
      'input'
    ])
    @assertions[:assert_equal].append([
      fv.name,
      GENERIC_CONTAINER
    ])
    @assertions[:assert].append([
      fv.item.class == Item
    ])
    # TODO: Why does this fail?
    # @assertions[:assert_nil].append([
    #   fv.collection
    # ])
    @assertions[:assert].append([
      fv.sample.class == Sample
    ])
    @assertions[:assert_equal].append([
      fv.row,
      nil
    ])
    @assertions[:assert_equal].append([
      fv.column,
      nil
    ])
    @assertions[:assert_equal].append([
      fv.parent_class,
      'Operation'
    ])
    @assertions[:assert_equal].append([
      fv.parent_id,
      operation.id
    ])
  end

  def test_generic_part_input(operation:)
    fv = generic_part_input(operation: operation)
    @assertions[:assert_equal].append([
      fv.role,
      'input'
    ])
    @assertions[:assert_equal].append([
      fv.collection.class,
      Collection
    ])
    @assertions[:assert_equal].append([
      fv.row,
      0
    ])
    @assertions[:assert_equal].append([
      fv.column,
      0
    ])
  end

  def test_generic_output(operation:)
    fv = generic_output(operation: operation)
    @assertions[:assert_equal].append([
      fv.role,
      'output'
    ])
  end

  def test_generic_part_output(operation:)
    fv = generic_part_output(operation: operation)
    @assertions[:assert_equal].append([
      fv.role,
      'output'
    ])
    @assertions[:assert_equal].append([
      fv.row,
      0
    ])
    @assertions[:assert_equal].append([
      fv.column,
      0
    ])
  end

  def test_empty_operation_type
    name = 'Foo Bar'
    operation_type1 = empty_operation_type(name: name)
    operation_type2 = empty_operation_type(name: name)
    @assertions[:assert_equal].append([
      operation_type1.id,
      operation_type2.id
    ])

    operation_type3 = empty_operation_type(name: 'Foo Baz')
    @assertions[:refute_equal].append([
      operation_type1.id,
      operation_type3.id
    ])
  end

  def test_empty_operation
    name = 'Foo Bar'
    operation = empty_operation(name: name)
    @assertions[:assert].append([
      operation.class == Operation
    ])
    @assertions[:assert].append([
      operation.name == name
    ])
    @assertions[:assert].append([
      operation.operation_type.category == 'Test Fixtures'
    ])
    @assertions[:assert].append([
      operation.status == 'done'
    ])
  end
end