# for managing data associations of collections
# and ensuring that samples/item data is handled correctly
needs 'Standard Libs/AssociationManagement'

module CollectionData
  include AssociationManagement

  # Adds Key to data map with information about Items (parts) of a Collection
  # Creates Data Association for each Item using this Key
  #
  # @param plate [Collection] the plate containing the Items (parts)
  # @param data_map [Array<Array<row, column, value>, ...>] data about
  # Items (parts) that will have a DataAssociation created for them
  # @param key [String] the Data Association Key
  def associate_value_to_parts(plate:, data_map:, key:)
    data_map.each do |loc_val_array|
      loc_val_array[3] = key
    end
    associate_value_key_to_parts(plate: plate, data_map: data_map)
  end

  # Creates a DataAssociation for each entry with Key :part_data and
  # Value "well" (saved as DataAssociation.object)
  # Each value is associated to its respective key
  #
  # @param plate [Collection] the plate that contains the parts (items)
  # @param data_map [Array<Array<r,c, value, key>, ...>] data map of all parts
  def associate_value_key_to_parts(plate:, data_map:)
    data_map.each do |key_value_map|
      part = plate.part(key_value_map[0], key_value_map[1])
      data_value = key_value_map[2]
      key = key_value_map[3]
      associate_data(part, key.to_sym, data_value) unless part.nil?
    end
  end

  # Is this being used?
  # Associates data to every part in a plate
  #
  # @param plate [Collection] the collection
  # @param data [Anything] the data to be associated
  def associate_to_all(plate:, data:, key:)
    data_map = []
    parts.each do |part|
      loc = plate.find(part)
      loc[2] = data
      loc[3] = key
      data_map.push(loc)
    end
    associate_value_key_to_parts(plate: plate, data_map: data_map)
  end

  # Adds provenance history to to_object from from_object
  # Creates two DataAssociations:
  # One, for the from_obj, will have key :to and the Item id of the to_obj
  # in its DataAssociation.object field
  # The other, for the to_obj, will have key :from and the Item id of the to_obj
  # in its DataAssociation.object field
  #
  # @param from_obj [Item] object that provenance is coming from
  # @param to_obj [Item] the object that provenance is going to
  def from_obj_to_obj_provenance(to_obj, from_obj)
    raise "Object #{to_obj.id} is not an item" unless to_obj.is_a? Item
    raise "Object #{from_obj.id} is not an item" unless from_obj.is_a? Item

    from_obj_map = AssociationMap.new(from_obj)
    to_obj_map = AssociationMap.new(to_obj)
    add_provenance(from: from_obj, from_map: from_obj_map,
                   to: to_obj, to_map: to_obj_map)
    from_obj_map.save
    to_obj_map.save
  end

  # Creates an array of samples that are the same in two different Collections
  #
  # @param collection_a [Collection] a collection
  # @param collection_b [Collection] a collection
  # @return [Array<Sample>]
  def find_like_samples(collection_a, collection_b)
    collection_a.parts.map!(&:sample) & collection_b.parts.map!(&:sample)
  end

  # Adds data to list of coordinates
  # If there is already a data value present, the new data value will
  # either replace it, or be appended to it
  # based on the value of the append boolean
  #
  # @param coordinates [Array<Row(int), Column(int), Optional(String)] the
  #       coordinate list to be modified
  # @param data [String] string to be added to the list data
  # @param append: [Boolean] default true.  Replace if false
  def append_x_to_rcx(coordinates, data, append: true)
    data = data.to_s
    if coordinates[2].nil? || !append
      coordinates[2] = data
    else
      coordinates[2] += ', ' + data
    end
  end

  # Returns an array of parts in the Collection that match the right Sample
  #
  # @param collection [Collection] the Collection that the Item (part) is in
  # @param sample [Sample] the Sample searched for
  def parts_from_sample(collection, sample)
    part_location = collection.find(sample)
    parts = []
    part_location.each do |coordinates|
      parts.push(collection.part(coordinates[0], coordinates[1]))
    end
  end
end
