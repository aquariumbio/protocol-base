# typed: false
# frozen_string_literal: true

needs 'Microtiter Plates/MicrotiterPlates'
needs 'Standard Libs/TestFixtures'

class Protocol
  include TestFixtures

  KEY = 'foo'
  GROUP_SIZE = 3
  METHOD = nil

  def main
    rval = {}
    collection = setup_test_plate

    microtiter_plate = MicrotiterPlateFactory.build(
      collection: collection,
      group_size: GROUP_SIZE,
      method: METHOD
    )

    rval[:next_empty_group] = microtiter_plate.next_empty_group(key: KEY)
    rval
  end

  # Simulates an incoming collection that already has several
  #   data associations.
  #
  def setup_test_plate
    sample = generic_sample
    collection = generic_collection
    collection.get_empty.each { |r, c| collection.set(r, c, sample) }

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: GROUP_SIZE,
      method: METHOD
    )

    layout_generator.next_group.each do |r, c|
      collection.part(r, c).associate(KEY, 'bar')
    end

    collection
  end
end
