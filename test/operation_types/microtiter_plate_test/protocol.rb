# typed: false
# frozen_string_literal: true

needs 'Microtiter Plates/MicrotiterPlates'
needs 'Collection Management/CollectionDisplay'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/debug'

class Protocol
  include CollectionDisplay
  include AssociationManagement
  include Debug

  VERBOSE = false

  KEY = 'patient_sample'
  GROUP_SIZE = 3
  METHOD = :cdc_sample_layout

  def main
    op = operations.first
    collection = op.input('PCR Plate').collection
    setup_test_plate(collection: collection)

    microtiter_plate = MicrotiterPlateFactory.build(
      collection: collection,
      group_size: GROUP_SIZE,
      method: METHOD
    )

    # Should skip the first column becasue it has `patient_sample` filled:
    # [[0, 1], [1, 1], [2, 1]]
    # NOT
    # [[0, 0], [1, 0], [2, 0]]
    #
    inspect microtiter_plate.next_empty_group(key: KEY).to_s

    {}

  end

  # Populate test plate with qPCR Reactions and one no template control (NTC)
  #
  def setup_test_plate(collection:)
    qpcr_reaction = Sample.find_by_name('Test qPCR Reaction')
    ntc_item = Item.find(258)

    layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: GROUP_SIZE,
      method: METHOD
    )

    i = 0
    loop do
      layout_group = layout_generator.next_group
      break unless layout_group.present?

      layout_group.each do |r, c|
        collection.set(r, c, qpcr_reaction)
        next if i.positive?

        part = collection.part(r, c)
        inspect part, "part at #{[r, c]}" if VERBOSE
        part.associate(KEY, ntc_item)
        inspect part.associations, "#{KEY} at #{[r, c]}" if VERBOSE
      end
      i += 1
    end

    show_result(collection: collection) if VERBOSE
    inspect collection.parts.to_s if VERBOSE
  end

  def show_result(collection:)
    show do
      table highlight_non_empty(collection)
    end
  end
end
