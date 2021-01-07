# CollectionData

needs 'Standard Libs/AssociationManagement'

# for managing data associations of collections
# and ensuring that samples/item data is handled correctly
module CollectionData
  include AssociationManagement
  include PartProvenance

  # Associates data to every part in a plate
  #
  # @param plate [Collection] the collection
  # @param data [Anything] the data to be associated
  def associate_to_all(plate:, data:, key:)
    data_map = []
    plate.get_non_empty.each do |idx|
      data_map.push({ idx: idx, data: data, key: key })
    end
    associate_data_to_parts(plate: plate, data_map: data_map)
  end

  # Creates a DataAssociation for each entry with Key :part_data and
  # Value "well" (saved as DataAssociation.object)
  # Each value is associated to its respective key
  #
  # @param plate [Collection] the plate that contains the parts (items)
  # @param data_map [Array<Hash{idx: [r,c], data:, key:}>, ...>]
  def associate_data_to_parts(plate:, data_map:)
    data_map.each do |hash|
      associate(index: hash[:idx],
                key: hash[:key],
                data: hash[:data],
                collection: plate)
    end
  end

  # Make a simple data association on a part
  #
  # @param index [Array<Fixnum>] the row, column pair pointing to the part
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param data [serializable object]  the data for the association
  # @return [void]
  def associate(index:, key:, data:, collection:)
    part = collection.part(index[0], index[1])
    associate_data(part, key, data)
  end

  # Creates table for the data associated with key
  #
  # @param collection [Collection] the plate being used
  # @param keys [Array<String>] an array of keys that the data is
  #        associated with.
  # @return table of parts with data information
  def display_all_data(collection, key)
    display_data(collection, rc_list.get_non_empty, key)
  end

  # Returns data for all non empty slots if data is not nil
  #
  # @param collection [Collection]
  # @param key [String]
  # @return [Array<Hash{idx: ,data: ,key: }]
  def get_all_data_key(collection, key)
    data_map = []
    collection.get_non_empty.each do |idx|
      data = collection.part(idx[0], idx[1]).associations[key]
      next unless data.present?

      data_map.push({idx: index, data: data, key: key})
    end
    data_map
  end

  # Creates an array of samples that are the same in two different Collections
  #
  # @param collection_a [Collection] a collection
  # @param collection_b [Collection] a collection
  # @return [Array<Sample>]
  def find_like_samples(collection_a, collection_b)
    collection_a.parts.map!(&:sample) & collection_b.parts.map!(&:sample)
  end
end
