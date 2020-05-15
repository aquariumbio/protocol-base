# Cannon Mallory
# malloc3@uw.edu
#
# Methods for transferring items into and out of collections

# TODO Make 'mix in' methods

needs 'Standard Libs/Units'
needs 'Standard Libs/Debug'
needs 'Standard Libs/AssociationManagement'
needs 'Collection_Management/CollectionLocation'
needs 'Collection_Management/CollectionData'

module CollectionTransfer
  include Units
  include Debug
  include CollectionLocation
  include AssociationManagement
  include PartProvenance
  include CollectionData

  TO_LOC = 'To Loc'.to_sym
  FROM_LOC = 'From Loc'.to_sym
  VOL_TRANSFER = 'Volume Transferred'.to_sym

  # gets the number of plates
  #
  # @param operations [OperationList] list of operations in job
  # @param role [String] indicates whether it's an input or output collection
  # @returns Array[collection] the number of plates
  def get_array_of_collections(operations, role)
    collection_array = []
    operations.each do |op|
      obj_array = op.inputs if role == 'input'
      obj_array = op.outputs if role == 'output'
      obj_array.each do |fv|
        if !fv.collection.nil?
          collection_array.push(fv.collection)
        end
      end
    end
    collection_array.uniq
  end

  # Determines if there are multiple plates
  #
  # @param operations [OperationList] list of operations in job
  # @param role [String], whether plates are for input or output
  # @returns boolean true if multiple plates
  def multiple_plates?(operations, role: 'input')
    return true if get_num_plates(operations, role) > 1
  end

  # gets the number of plates
  #
  # @param operations [OperationList] list of operations in job
  # @param role [String] indicates whether it's an input or output collection
  # @returns [Int] the number of plates
  def get_num_plates(operations, role)
    get_array_of_collections(operations, role).length
  end

  # Provides instructions to transfer samples.  
  # If samples to transfer are not given then it will assume that all 
  #   parts of the from_collection will be transferred.
  #
  # @param input_collection [Collection] the collection samples come from
  # @param to_collection[Collection] the collection samples will move to
  # @param transfer_vol [String] volume of sample to transfer (INCLUDE UNITS)
  # @param populate_collection [Boolean] true if the to_collection needs to be
  #   populated false if the to_collection has already been populated.
  # @param array_of_samples [Array<Sample>] Optional
  # @param instructions [Boolean] default true to include instructions
  def transfer_from_collection_to_collection(from_collection, 
                                             to_collection: nil,
                                             collection_type: nil,
                                             transfer_vol: nil,
                                             populate_collection: true,
                                             array_of_samples: nil,
                                             instructions: true,
                                             one_to_one: false)

    # gets samples to transfer if not explicitly given
    if array_of_samples.nil?
      array_of_samples = from_collection.parts.map { |part| part.sample 
                                                    if part.class != 'Sample' }
    end

    if populate_collection || to_collection.nil?
      collections = make_and_populate_collection(samples, first_collection: to_collection,
                                                          collection_type: collection_type)
    else
      collections = [to_collection]
    end

    collections.each do |collection|
      association_map = make_one_to_many_association_map(to_collection: collection,
                                                        from_collection: from_collection,
                                                        samples: array_of_samples,
                                                        one_to_one: one_to_one,
                                                        label_plates: instructions)
      associate_plate_to_plate(to_collection: collection, from_collection: from_collection,
                              association_map: association_map, transfer_vol: transfer_vol)
      unless instructions
        collection_to_collection_transfer_instructions(to_collection: collection, from_collection: from_collection,
                                       association_map: association_map, transfer_vol: transfer_vol)
      end
    end
    collections
  end


  # Generates a fills a collection with all samples in the fv_array and produces instructions
  #   on transferring to the collection.
  #
  # @param fv_array [Array<item or field values>] the samples to be transferred
  # @param to_collection [Collection] the collection that things are being transferred to (optional)
  # @param collection_type [String] the name of the collection type to be made (optional)
  #    exactly one to_collection or collection_type must be given
  # @param transfer_volume [Float] the volume that is to be transferred
  # @param instructions [Boolean] true if instructions are to be displayed
  # @return collections [Array<Collections>] the collections created/used
  def transfer_items_to_collection(fv_array, to_collection: to_collection,
                                             collection_type: collection_type,
                                             transfer_vol: transfer_vol,
                                             instructions: true)
    sample_array = fv_array.map( |fv| fv.sample )
    collections = make_and_populate_collection(sample_array, first_collection: to_collection,
                                                        collection_type: collection_type,
                                                        label_plates: instructions)
    association_map = make_item_to_collection_association_map(fv_array, collection: to_collection)
    associate_items_to_wells(to_collection: collection, association_map: association_map,
                             transfer_vol: transfer_vol)
    unless instructions
      item_to_collection_transfer_instructions(to_collection: collection, association_map: association_map,
                                               transfer_vol: transfer_vol)
    end
  end

  # Creates an association map of items to a collection
  #
  # @param fv_array [Array<FieldValue or Items>] field values or items
  # @param collection [to_collection] the collection that things are in
  # @return [Array<{to_loc: lcoation, from_loc: location}, ...]
  def make_item_to_collection_association_map(fv_array, collection:)
    association_map = []
    fv_array.each do |item|
      ProtocolError 'Can not use samples' if item.is_a Sample
      item = item.item if item.is_a FieldValue

      to_location = to_collection.find(item.sample)
      from_location = item.id

      association_map.push{to_loc: to_location, from_loc: from_location}
    end
    association_map
  end


  # Instructions on relabeling plates to new plate ID
  # Tracks provenance properly though transfer
  #
  # @param plate1 [Collection] plate to relabel
  # @param plate2 [Collection] new plate label
  def relabel_plate(from_collection, to_collection: nil)
    if to_collection.nil?
      to_collection = make_new_plate(from_collection.object_type.name, label_plate: false)
    end

    unless from_collection.object_type == to_collection.object_type
      ProtocolError 'Object Types do not match'
    end
    

    transfer_from_collection_to_collection(from_collection, 
                                           to_collection: to_collection,
                                           instructions: false,
                                           one_to_one: true)
    show do
      title 'Rename Plate'
      note "Relabel plate <b>#{from_collection.id}</b> with <b>#{to_collection.id}</b>"
    end
    from_collection.mark_as_deleted
    from_collection.save
    to_collection
  end


  # Instructions to transfer physical samples from input plates to to_collections
  # Groups samples by collection for easier transfer
  # Uses transfer_to_to_collection method
  #
  # @param input_fv_array [Array<FieldValues>] an array of field values of collections
  # @param to_collection [Collection] (Should have samples already associated to it)
  # @param transfer_vol [String] volume in sample to transfer INCLUDE UNITS
  def transfer_subsamples_to_working_plate(fv_array, to_collection: nil, collection_type: nil, transfer_vol: nil)
    # was transfer_to_collection_from_fv_array
    part_grouping = fv_array.group_by{|fv| fv.part?}
    part_grouping.each do |is_part, fv_array|
      if is_part
        transfer_collection_subsample(fv_array, to_collection: to_collection,
                                                collection_type: collection_type,
                                                transfer_vol: transfer_vol)
      else
        transfer_items_to_collection(fv_array, to_collection: to_collection,
                                               collection_type: collection_type,
                                               transfer_vol: transfer_vol)
      end
    end
  end




  def transfer_collection_subsample(fv_array, to_collection: nil, collection_type: nil, transfer_vol: nil)
    sample_array_by_collection = fv_array.group_by { |fv| fv.collection }
    sample_array_by_collection.each do |from_collection, fv_array|
      sample_array = fv_array.map { |fv| fv.sample }
      transfer_from_collection_to_collection(from_collection, to_collection: to_collection,
                                                              collection_type: collection_type,
                                                              transfer_vol: transfer_vol,
                                                              array_of_samples: sample_array)
    end
  end

  # Tracks provenance and adds transfer vol association
  # for item to well transfers
  #
  #
  # @param to_collection [Collection] the plate that is getting the association
  # @param from_item [item] the item that is transferring the association
  # @param Association_map [Array<{to_loc: loc, from_loc: item}>] Association map of where items
  #       are coming from.
  #     If nil will assume transferred to all wells.
  #     Can take standard Array of Hashes as used in other methods in this
  #       library
  # @param transfer_vol [Integer] the volume transferred if applicable default
  #   nil if nil then will state unknown transfer vol
  def associate_items_to_wells(to_collection:, association_map: nil,
                              transfer_vol: nil)
    association_map.each do |map|
      to_loc = map[:to_loc]
      from_item = map[:from_loc]
      from_item = Item.find(from_item) unless from_item.is_a? Item

      to_part = to_collection.part(to_loc[0], to_loc[1])

      unless transfer_vol.nil?
        associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_part,
                                                           from_part: from_item)
      end
      from_obj_to_obj_provenance(to_part, from_item)
    end
  end


  # makes proper association_map between to_collection and from_collection for use in other methods
  # all samples in samples: must exist in both collections.  This method only works if the sample
  # exists in the from_collection exactly 1 time.  If the sample exists in the from_collection more
  # than one time then it is impossible to know with the information given which well the end sample came
  # from (unless its a one to one location match)
  #
  # @param to_collection [Collection] the collection that things are moving to
  # @param from_collection [Collection] the collection that things are coming from
  # @param samples [Array<{to_loc: loc, from_loc: loc}>] array of samples that exists in both collections
  # @param one_to_one [Boolean] if true then will make an exact one to one location map from the to_collection
  # (if not given then will assume all similar samples are being associated)
  def make_one_to_many_association_map(to_collection:, from_collection:, samples: nil, one_to_one: false)
    return one_to_one_association_map(to_collection: to_collection, from_collection: from_collection) if one_to_one

    if samples.nil?
      samples = find_like_samples(to_collection, from_collection)
    end
    # Array<{to_loc: loc, from_loc: loc}
    association_map = []
    samples_with_no_location = []

    samples.each do |sample|
      to_loc = to_collection.find(sample)
      from_loc = from_collection.find(sample)
      # TODO: figure out how the associations will work if there are multiple
      # to and from locations (works partially may could use improvement)

      if to_loc.length.zero? || from_loc.length.zero?
        samples_with_no_location.push(sample)
      end

      if from_loc.length == 1
        to_loc.each do |t_loc|
          association_map.push({ TO_LOC: t_loc, FROM_LOC: from_loc.first })
        end
      else
        from_loc.each do |from_loc|
          match = false
          to_loc.each do |to_loc|
            if to_loc[0] == from_loc[0] && to_loc[1] == from_loc[1]
              match = true
              association_map.push({ TO_LOC: to_loc, FROM_LOC: from_loc })
            end
          end
          ProtocolError "AssociationMap was not properly created." unless match
          # TODO: Create a better error handle here (make it so it shows them the issue more explicitly)
        end
      end
    end

    unless samples_with_no_location.length == 0
      cancel_plan = show do
        title 'Some Samples were not found'
        warning 'Some samples there were expected were not found in the given plates'
        note 'The samples that could not be found are listed below'
        select ['Cancel', 'Continue'], var: 'cancel', label: 'Do you want to cancel the plan?', default: 1
        samples_with_no_location.each do |sample|
          note "#{sample.id}"
        end
      end

      # TODO: Fail softly/continue with samples that were found
      if cancel_plan[:'cancel'] == 'Cancel'
        raise 'User Canceled plan because many samples could not be found'
      else
        ProtocolError "I am sorry this module doesn't currently support continuing with existing samples
        hopefully this feature will be added soon."
      end
    end

    association_map
  end

  # Creates a one to one association map for all filled slots of both to and from collection
  # if a slot is full in both collections that location is included in the association map
  # regardless if the samples are the same or not, Collections must be the same dimensions
  #
  # @param to_collection [Collection] the collection that things are moving to
  # @param from_collection [Collection] the collection that things are coming from
  # @param samples [Array<{to_loc: loc, from_loc: loc}>] array of samples that exists in both collections
  def one_to_one_association_map(to_collection:, from_collection:)
    to_row_dem, to_col_dem = to_collection.dimensions
    from_row_dem, from_col_dem = from_collection.dimensions
    unless to_row_dem == from_row_dem && to_col_dem == from_col_dem
      ProtocolError "Collection Dimensions do not match"
    end

    association_map = []
    to_row_dem.times do |row|
      to_col_dem.times do |col|
        unless to_collection.part(row, col).nil? || from_collection.part(row, col).nil?
          loc = [row, col]
          association_map.push({ TO_LOC: loc, FROM_LOC: loc })
        end
      end
    end
    association_map
  end



  # Creates Data Association between working plate items and input items
  # Associates corresponding well locations that contain a part.
  #
  # @param to_collection [Collection] the plate that is getting the association
  # @param from_collection [Collection] the plate that is transferring the association
  # @param Association_map [Array<Hash<from_loc: loc1, to_loc: loc2>]
  #             Association map of where items were coming from
  # @param transfer_vol [Integer] the volume transferred if applicable default nil
  #   if nil then will associate all common samples
  def associate_plate_to_plate(to_collection:, from_collection:, association_map: nil, transfer_vol: nil)
    # map = [[loc1_to, loc2_from], [loc1,loc2], [loc1, loc2]]

    # if there is no association map given it will assume they came one to one
    # and will build association map of right format based on how many items are
    # in the "to_collection"
    if association_map.nil?
      association_map = one_to_one_association_map(to_collection: to_collection,
                                                   from_collection: from_collection)
    end

    from_obj_to_obj_provenance(to_collection, from_collection)

    association_map.each do |loc_hash|
      to_loc = loc_hash[:TO_LOC]
      from_loc = loc_hash[:FROM_LOC]

      to_loc = convert_alpha_to_rc(to_loc) if to_loc.is_a? String
      from_loc = convert_alpha_to_rc(from_loc) if from_loc.is_a? String

      to_part = to_collection.part(to_loc[0], to_loc[1])
      from_part = from_collection.part(from_loc[0], from_loc[1])

      unless transfer_vol.nil?
        associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_part,
                                                           from_part: from_part)
      end

      from_obj_to_obj_provenance(to_part, from_part)
    end
  end

  # Creates data association based on plate map for transfer of sample from one
  # /many wells to unless transfer_vol.nil?
  # Additionally tracks provenance through items.
  #
  #
  # @param from_collection [Collection] the is transferring the association
  # @param to_item [item] the item that is getting_the association
  # @param Association_map [Array<row, column>] Association map of where items
  #       are coming from.  If nil will assume transferred from all wells.
  #     Can take standard Array of Hashes as used in other methods in this
  #        library
  # @param transfer_vol [String] the volume transferred if applicable
  def associate_wells_to_item(to_item:, from_collection:, association_map: nil,
                              transfer_vol: nil)
    association_map = from_collection.get_non_empty if association_map.nil?

    association_map.each do |from_loc|
      from_loc = from_loc[:FROM_LOC] if from_loc.is_a? Hash
      from_loc = convert_alpha_to_rc if from_loc.is_a? String

      from_part = from_collection.part(from_loc[0], from_loc[1])
      unless transfer_vol.nil?
        associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_item,
                                                           from_part: from_part)
      end
      from_obj_to_obj_provenance(to_item, from_part)
    end
  end

  # Creates associations from wells to items based on the association map.
  # The map directs which wells and what items are associated.
  # Should be in the form Array<Array<to_item, [r,c]>>  where [r,c]
  #   is the location in the collection that the item should be from.
  #
  # @param from_collection [Collection] the collection item is from
  # @param association_map [Array<Array<item, [row, col]>>] or
  #           [Array<Array<item, Hash{FROM_LOC: [r,c]}>>]
  # @param transfer_vol [String] the volume transferred INCLUDE UNITS
  def associate_wells_to_multiple_items(from_collection:, association_map:, 
                                        transfer_vol: nil)
    association_map.each do |to_item, loc|
      associate_wells_to_item(to_item: to_item, from_collection: from_collection,
                              association_map: [loc], transfer_vol: transfer_vol)
    end
  end

  # Records the volume of an item that was transferred
  #   (or at least what the code) instructed the technician to transfer.
  # Creates an array of all the transferred volumes for future use
  #   Array<Array<from_part_id, volume>, ...>
  #
  # @param vol the volume transferred
  # @param to_part: part that is being transferred to
  # @param from_part: part that is being transferred from
  def associate_transfer_vol(vol, key, to_part:, from_part:)
    vol_transfer_array = get_associated_data(to_part, key)
    vol_transfer_array = [] if vol_transfer_array.nil?
    vol_transfer_array.push([from_part.id, vol])
    associate_data(to_part, key, vol_transfer_array)
  end

  # provides instructions to technician for transferring items from one collection to another
  #
  # @param to_collection [Collection] the collection that items are being transferred to
  # @param from_collection [Collection] the collection that items are being transferred from
  # @param association_map [Array<{TO_LOC: loc, FROM_LOC: loc}] maps the location relationship
  #     between the two plates.  If not given will assume one to one collection transfer
  # @param transfer_vol [String] Optional the volume to be transferred WITH UNITS
  #       (if nil no volume instructions)
  def collection_to_collection_transfer_instructions(to_collection:, from_collection:,
                                       association_map: nil, transfer_vol: nil)
    if transfer_vol.nil?
      amount_to_transfer = "everything"
    else
      amount_to_transfer = "#{transfer_vol}"
    end

    association_map = one_to_one_association_map(to_collection: to_collection,
                                                 from_collection: from_collection) if association_map.nil?

    from_rcx = []
    to_rcx = []
    association_map.each do |loc_hash|
      from_location = loc_hash[:FROM_LOC]
      to_location = loc_hash[:TO_LOC]
      from_alpha_location = convert_rc_to_alpha(to_location)
      from_rcx.push(append_x_to_rcx(from_location, from_alpha_location))
      to_rcx.push(append_x_to_rcx(to_location, from_alpha_location))
    end

    show do
      title 'Transfer from one plate to another'
      note "Please transfer <b>#{amount_to_transfer}</b> from Plate
           (<b>ID:#{from_collection.id}</b>) to plate
           (<b>ID:#{to_collection.id}</b>) per tables below"
      separator
      note "Stock Plate (ID: <b>#{from_collection.id}</b>):"
      table highlight_collection_rcx(from_collection, from_rcx,
                                     check: false)
      note "Working Plate (ID: <b>#{to_collection}</b>):"
      table highlight_collection_rcx(to_collection, to_rcx,
                                     check: false)
    end
  end

  # Instructions to transfer items to wells in a collection
  #
  # @param to_collection [Collection] the plate that is getting the association
  # @param from_item [item] the item that is transferring the association
  # @param Association_map [Array<{to_loc: loc, from_loc: item}>] Association map of where items
  #       are coming from.
  #     If nil will assume transferred to all wells.
  #     Can take standard Array of Hashes as used in other methods in this
  #       library
  # @param transfer_vol [Integer] the volume transferred if applicable default
  #   nil if nil then will state unknown transfer vol
  def item_to_collection_transfer_instructions(to_collection:, association_map: nil,
    transfer_vol: nil)
    if transfer_vol.nil?
      amount_to_transfer = "everything"
    else
      amount_to_transfer = "#{transfer_vol}"
    end
    list_of_items = [to_collection]
    rcx_list = []
    association_map.each do |map|
      to_location = map[:to_loc]
      convert_location_to_coordinates(to_location) if to_location.is_a? String

      from_item = map[:from_loc]
      from_item = Item.find(from_item) unless from_item.is_a? Item
      list_of_items.push(from_item)

      rcx_list.push([to_location[0], to_location[1], from_item.id])
    end

    show do
      title "Get items for transfer"
      note 'Please get the following items'
      table create_location_table(list_of_items)
    end


    show do
      title 'Transfer from items to the plate'
      note "Please transfer <b>#{amount_to_transfer}</b> from the items 
            listed to Plate #{to_collection.id}"
      separator
      note "Plate (ID: <b>#{to_collection.id}</b>):"
      table highlight_collection_rcx(to_collection, rcx_list,
                                     check: true)
    end
  end


  # Instructions to transfer wells in a collection to items
  #
  # @param to_collection [Collection] the plate that is getting the association
  # @param from_item [item] the item that is transferring the association
  # @param Association_map [Array<{to_loc: loc, from_loc: item}>] Association map of where items
  #       are coming from.
  #     If nil will assume transferred to all wells.
  #     Can take standard Array of Hashes as used in other methods in this
  #       library
  # @param transfer_vol [Integer] the volume transferred if applicable default
  #   nil if nil then will state unknown transfer vol
  def item_to_collection_transfer_instructions(from_collection:, association_map: nil,
    transfer_vol: nil)
    if transfer_vol.nil?
      amount_to_transfer = "everything"
    else
      amount_to_transfer = "#{transfer_vol}"
    end
    list_of_items = [to_collection]
    rcx_list = []

    association_map.each do |map|
      from_location = map[:from_loc]
      convert_location_to_coordinates(from_location) if from_location.is_a? String

      to_item = map[:to_loc]
      to_item = Item.find(to_item) unless to_item.is_a? Item
      list_of_items.push(to_item)

      rcx_list.push([from_location[0], from_location[1], to_item.id])
    end

    show do
      title "Get items for transfer"
      note 'Please get the following items'
      table create_location_table(list_of_items)
    end


    show do
      title 'Transfer from one plate to another'
      note "Please transfer <b>#{amount_to_transfer}</b> from Plate 
            #{from_collection.id} to the items listed"
      separator
      note "Plate (ID: <b>#{from_collection.id}</b>):"
      table highlight_collection_rcx(from_collection, rcx_list,
                                     check: true)
    end
  end
end