# typed: false
# frozen_string_literal: true

# This is a default, one-size-fits all protocol that shows how you can
# access the inputs and outputs of the operations associated with a job.
# Add specific instructions for this protocol!
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/Units'
needs 'Collection Management/CollectionTransfer'
needs 'Collection Management/CollectionActions'
class Protocol
  include TestFixtures
  include Units
  include CollectionTransfer
  include CollectionActions

  def main
    test_add_samples_to_collection

    gcol = generic_collection
    gcol2 = generic_collection

    test_get_and_label_new_plate(gcol)

    fill_collection(gcol)
    fill_collection(gcol2)

    test_remove_supernatant([gcol, gcol2])

    test_make_new_plate(gcol)

    test_make_and_populate(sample_type: gcol.object_type.name,
                           samples: gcol.parts.map(&:sample))

    test_seal_plate(gcol, gcol2)
    
    {}
  end

  def test_seal_plate(gcol, gcol2)
    show do
      note seal_plate([gcol, gcol2])
      note seal_plate([gcol, gcol2], seal: 'test seal')
      note remove_seal([gcol, gcol2])
    end
  end

  def test_get_and_label_new_plate(plate)
    show do
      note get_and_label_new_plate(plate)
    end
  end

  def test_add_samples_to_collection
    gcol = generic_collection
    gcol2 = generic_collection
    samples = gcol.get_empty.map{generic_sample}.sample(rand(gcol.get_empty.length))
    association_map = one_to_one_association_map(
      from_collection: gcol,
      skip_nil: false
    )
    col1 = add_samples_to_collection(samples, gcol, association_map: association_map)
    col2 = add_samples_to_collection(samples, gcol2)
    show do
      title 'Test add samples'
      note col1.parts.map(&:id).to_s
      note col2.parts.map(&:id).to_s
    end
  end

  def test_make_and_populate(sample_type:, samples:)
    samples = samples.sample(rand(samples.length))
    col1 = make_and_populate_collection(samples, collection_type: sample_type,
                                        label_plates: true)
    col2 = make_and_populate_collection(
      samples + samples,
      first_collection: col1[0],
      label_plates: true
    )
    show do
      title 'Check Make and Populate'
      note 'Single'
      note col1.map(&:id).to_s
      note 'Multiple Collections'
      note col2.map(&:id).to_s
    end
  end

  def test_make_new_plate(col)
    col_type = col.object_type
    make_new_plate(col_type, label_plate: true)
  end

  def test_remove_supernatant(collections)
    amaps = collections.map do |col|
      one_to_one_association_map(from_collection: col).sample(rand(col.capacity))
    end

    remove_supernatant(collections, amaps: amaps)
  end

  def fill_collection(gcol)
    samples = gcol.get_empty.map{generic_sample}
    gcol.add_samples(samples)
  end

end
