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

  # Instructs tech to remove supernatant and discard
  #
  # @param item [Array<Item>]
  # @param amap [Hash<from_loc: [r,c]]
  def remove_discard_supernatant(items, association_map: nil)
    group = items.group_by(&:collection?)
    if group[false].present?
      remove_item_supernatant(group[false])
    elsif group[true].present?
      remove_collection_supernatant(group[true], amap: association_map)
    end
  end

  # Instructions to remove supernatant from a collection
  # USE 'remove_discard_supernatant' instead
  #
  # @param plates [Array<Collection>]
  # @param amap [Hash<from_loc: [r,c]]
  def remove_collection_supernatant(plates, amap: nil)
    plates.each do |plate|
      unless amap.present?
        amap = one_to_one_association_map(from_collection: plate)
      end

      rc_list = amap.map { |hash| hash[:from_loc] }

      show do
        title 'Remove Supernatant'
        note 'Remove and discard supernatant from the following wells:'
        table highlight_collection_rc(plate, rc_list)
      end
    end
  end

  # Instructions to remove supernatant from an item
  # Needed to be here to replace the Item Action version
  #
  # @param items [Array<item>]
  def remove_item_supernatant(items)
    show do
      title 'Remove Supernatant'
      note 'Remove and discard supernatant from:'
      items.each do |item|
        bullet item.to_s
      end
    end
  end

  # Creates new collection.  Instructions to tech optional
  #
  # @param c_type [String] the collection type
  # @param label_plate [Boolean] instructs tech to label if true
  # @return working_plate [Collection]
  def make_new_plate(c_type, label_plate: true)
    working_plate = Collection.new_collection(c_type)
    get_and_label_new_plate(working_plate) if label_plate
    working_plate
  end

  # TODO This is the same as 'copy_wells' in CollectionTransfer
  # Makes an exact copy of the from collection.
  # Will make the to_collection if needed
  #
  # @param from_collection [Collection]
  # @param to_collection [Collection]
  # @param label_plates [Boolean]
  # @return to_Collection [Collection]
  def exact_copy(from_collection, to_collection: nil, label_plates: false)
    collection_type = from_collection.object_type
    if to_collection.nil?
      to_collection = make_new_plate(collection_type, label_plate: label_plates)
    end

    to_collection
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
      ProtocolError 'Either collection_type or first_collection must be given'
    end

    unless collection_type.nil? || first_collection.nil?
      ProtocolError 'Both collection_type and first_collection cannot be given'
    end

    capacity = nil
    if collection_type.nil?
      collection_type = first_collection.object_type.name
      capacity = first_collection.capacity
      remaining_space = first_collection.get_empty.length
      add_samples_to_collection(samples[0...remaining_space - 1],
                                first_collection,
                                label_plates: label_plates)
      samples = samples.drop(remaining_space)
    else
      obj_type = ObjectType.find_by_name(collection_type)
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
        next
      end

      to_collection.set(rc[0], rc[1], sample)
    end
    to_collection
  end

  # Instructions on getting and labeling new plate
  #
  # @param plate [Collection] the plate to be retrieved and labeled
  def get_and_label_new_plate(plate)
    show do
      title 'Get and Label Working Plate'
      note "Get a <b>#{plate.object_type.name}</b> and
           label it ID: <b>#{plate.id}</b>"
    end
    plate
  end

  # Associates field_values to corresponding samples in a collection
  # TODO not sure multiples of samples is handled in the best way...
  #
  # @param field_values [Array<Field Values>] array of field values
  # @param collection [Collection] the destination collection
  # replaced make_output_plate
  def associate_field_values_to_plate(field_values, collection)
    already_associated_parts = []
    field_values.each do |fv|
      r_c = nil
      collection.find(fv.sample).each do |loc|
        r_c = loc
        break unless already_associated_parts.include?(loc)
      end
      r_c = collection.find(fv.sample).first
      unless r_c.nil?
        fv.set(collection: collection, row: r_c[0], column: r_c[1])
      end
    end
  end
  
  # Provides instructions to cover plate
  #
  # @param collection [Collection]
  # @param rc_list [Array<[r,c]>] specify certain wells to cover
  def seal_plate(collections, rc_list: nil, seal: nil)
    unless collections.is_a? Array
      collections = [collections]
    end

    seal = 'area seal' if seal.nil?

    collections.each do |collection|
      show do
        title 'Seal Wells'
        note "Using a/an <b> #{seal} </b> carefully seal plate #{collection.id}"
        unless rc_list.nil?
          warning 'ONLY seal the highlighted wells'
          table highlight_collection_rc(collection, rc_list)
        end
      end
    end
  end

end
