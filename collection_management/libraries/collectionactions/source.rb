# Cannon Mallory
# malloc3@uw.edu
#
# Module for working with collections
# These actions should involve the WHOLE plate not individual wells.
# NOTE: The collection is doing the whole action

needs 'Standard Libs/ItemActions'
needs 'Collection Management/CollectionTransfer'
needs 'Collection Management/CollectionDisplay'

module CollectionActions
  include ItemActions
  include CollectionTransfer
  include CollectionDisplay

  # Instructions to remove supernatant from a collection
  # USE 'remove_discard_supernatant' instead
  #
  # @param plates [Array<Collection>]
  # @param amap [Hash<from_loc: [r,c]]
  def remove_collection_supernatant(plates, amaps: [])
    return unless plates.present?
    plates.each_with_index do |plate, idx|
      amap = amaps[idx]

      unless amap.present?
        amap = one_to_one_association_map(from_collection: plate)
      end

      rc_list = amap.map { |hash| hash[:from_loc] }

      show do
        title 'Remove Supernatant'
        note "Remove and discard supernatant from plate #{plate}:"
        table highlight_collection_rc(plate, rc_list)
      end
    end
  end

  def remove_supernatant(objects, amaps: nil)
    items = objects.reject(&:collection?)
    collections = objects.select(&:collection?)
    remove_collection_supernatant(collections, amaps: amaps)
    remove_item_supernatant(items)
  end

  # Creates new collection.  Instructions to tech optional
  #
  # @param c_type [String] the collection type
  # @param label_plate [Boolean] instructs tech to label if true
  # @return working_plate [Collection]
  def make_new_plate(c_type, label_plate: true)
    working_plate = Collection.new_collection(c_type)
    if label_plate
      show do
        title 'Get and Label new Plate'
        note get_and_label_new_item(working_plate) if label_plate
      end
    end
    working_plate
  end

  # Makes the required number of collections and populates with samples
  # returns an array of of collections created
  #
  # @param samples [Array<FieldValue>] or [Array<Samples>]
  # @param collection_type [String] the type of collection that is to be made
  # @param first_collection [Collection] optional a collection to start with
  # @param add_column_wise [Boolean] default false add samples by column
  # @param label_plates [Boolean] default false, provides instructions
  # @return [Array<Collection>] array of collections created
  def make_and_populate_collection(samples, collection_type: nil,
                                   first_collection: nil,
                                   label_plates: false)

    if collection_type.nil? && first_collection.nil?
      raise 'Either collection_type or first_collection must be given'
    end

    unless collection_type.nil? || first_collection.nil?
      raise 'Both collection_type and first_collection cannot be given'
    end

    capacity = nil
    if collection_type.nil?
      collection_type = first_collection.object_type.name
      capacity = first_collection.capacity
      remaining_space = first_collection.get_empty.length
      add_samples_to_collection(samples[0...remaining_space - 1],
                                first_collection)
      samples = samples.drop(remaining_space)
    else
      obj_type = ObjectType.find_by_name(collection_type)
      raise collection_type.to_s unless obj_type.present?
      capacity = obj_type.columns * obj_type.rows
    end

    collections = []
    collections.push(first_collection) unless first_collection.nil?
    grouped_samples = samples.in_groups_of(capacity, false)
    grouped_samples.each do |sub_samples|
      collection = make_new_plate(collection_type, label_plate: label_plates)
      add_samples_to_collection(sub_samples, collection)
      collections.push(collection)
    end
    collections
  end

  # Assigns samples to specific well locations
  # The order of the samples and the order of the association map should be
  # the same
  #
  # @param samples [Array<FieldValue>] or [Array<Samples>]
  # @param to_collection [Collection]
  # @param association_map map of where samples should go
  # @raise if not enough space in collection
  def add_samples_to_collection(samples, to_collection, association_map: nil)
    slots_left = to_collection.get_empty.length
    if samples.length > slots_left
      raise "Not enough space in in collection #{to_collection}"
    end

    unless association_map.present?
      to_collection.add_samples(samples)
      return to_collection
    end

    samples.zip(association_map).each do |sample, map|
      next if sample.nil?

      if map.nil?
        to_collection.add(sample)
      else
        rc = map[:to_loc]
        to_collection.set(rc[0], rc[1], sample)
      end
    end
    to_collection
  end
  
  # Provides instructions to cover plate
  #
  # @param collection [Collection]
  # @param rc_list [Array<[r,c]>] specify certain wells to cover
  def seal_plate(collections, seal: nil)
    unless collections.is_a? Array
      collections = [collections]
    end

    seal = 'area seal' if seal.nil?
    string = "Using a/an <b>#{seal}</b> carefully seal plate/s "
    collections.each do |collection|
      string += "<b>#{collection}</b> "
    end
    string
  end

    # Provides instructions to cover plate
  #
  # @param collection [Collection]
  # @param rc_list [Array<[r,c]>] specify certain wells to cover
  def remove_seal(collections)
    unless collections.is_a? Array
      collections = [collections]
    end

    string = 'Remove seal from plate/s'
    collections.each do |collection|
      string += "<b>#{collection}</b> "
    end
    string
  end

end
