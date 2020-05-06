# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Methods for transferring items into and out of collections
# Currently it only has collection --> collection transfers

# TODO: Item --> collection and collection --> item transfers.
# (not applicable for current project so not added)
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
  VOL_TRANSFER = 'Volume Transfered'.to_sym

  # Provides instructions to transfer samples.  If samples to transfer are not given then it will assume that all
  # parts of the from_collection will be transfered.
  #
  # @param input_collection [Collection] the collection samples come from
  # @param to_collection[Collection] the collection samples will move to
  # @param transfer_vol [String] volume of sample to transfer (INCLUDE UNITS)
  # @param populate_collection [Boolean] true if the to_collection needs to be populated
  #     false if the to_collection has already been populated.
  # @param array_of_samples [Array<Sample>] Optional
  #
  # TODO Below
  # This should really be three methods:
  # 1. get the item locations
  # 2. make Data associations  (done)
  # 3. give instructions  (done)
  def transfer_from_collection_to_collection(from_collection, to_collection, transfer_vol, 
                populate_collection: true, array_of_samples: nil)

    # gets samples to transfer if not explicitly given
    if array_of_samples.nil?
      array_of_samples = from_collection.parts.map { |part| part.sample if part.class != 'Sample' }
    end

    add_samples_to_collection(array_of_samples, to_collection) if populate_collection

    association_map = make_one_to_many_association_map(to_collection: to_collection,
                                from_collection: from_collection, samples: array_of_samples)
    associate_plate_to_plate(to_collection: to_collection, from_collection: from_collection,
                               association_map: association_map, transfer_vol: transfer_vol)
    collection_transfer_instructions(to_collection: to_collection, from_collection: from_collection,
                                      association_map: association_map, transfer_vol: transfer_vol)
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
    return one_to_one_association_map(to_collectiion: to_collection, from_collection: from_collection) if one_to_one
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

      if to_loc.length.zero? || from_loc.zero?
        samples_with_no_location.push(sample)
      end

      if from_loc.length == 1
        to_loc.each do |t_loc|
          association_map.push({TO_LOC: t_loc, FROM_LOC: from_loc.first})
        end
      else
        from_loc.each do |from_loc|
          match = false
          to_loc.each do |to_loc|
            if to_loc[0] == from_loc[0] && to_loc[1] == from_loc[1]
              match = true
              association_map.push({TO_LOC: to_loc, FROM_LOC: from_loc})
            end
          end
          raise "AssociationMap was not properly created.  There were multiple possible from locations and none of
                these locations exactly matched to locations.  Please contact Cannon Mallory for assistance
              or explore 'CollectionManagement/CollectionTransfer/make_association_map 
              to recify the situation." unless match
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
        raise "I am sorry this module doesn't currently support continuing with existing samples
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
    raise "Collection Demensions do not match" unless to_row_dem == from_row_dem && to_col_dem == from_col_dem
    association_map = []
    to_row_dem.times do |row|
      to_col_dem.times do |col|
        unless to_collection.part(row, col).nil? || from_collection.part(row, col).nil?
          loc = [row,col]
          association_map.push({TO_LOC: loc, FROM_LOC: loc})
        end
      end
    end
    association_map
  end

  # provides instructions to technition for transfering items from one collection to another
  #
  # @param to_collection [Collection] the collection that items are being transfered to
  # @param from_collection [Collection] the collection that items are being transered from
  # @param association_map [Array<{TO_LOC: loc, FROM_LOC: loc}] maps the location relationship
  #     between the two plates.  If not given will assume one to one collection transfer
  # @param transfer_vol [String] Optional the volume to be transfered WITH UNITS
  #       (if nil no volume instructions)
  def collection_transfer_instructions(to_collection:, from_collection:,
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

  # Instructions to transfer physical samples from input plates to to_collections
  # Groups samples by collection for easier transfer
  # Uses transfer_to_to_collection method
  #
  # @param input_fv_array [Array<FieldValues>] an array of field values of collections
  # @param to_collection [Collection] (Should have samples already associated to it)
  # @param transfer_vol [String] volume in sample to transfer INCLUDE UNITS
  def transfer_subsamples_to_working_plate(input_fv_array, to_collection, transfer_vol)
    # was transfer_to_collection_from_fv_array
    sample_array_by_collection = input_fv_array.group_by { |fv| fv.collection }
    sample_array_by_collection.each do |from_collection, fv_array|
      sample_array = fv_array.map { |fv| fv.sample }
      transfer_from_collection_to_collection(from_collection, to_collection, transfer_vol, array_of_samples: sample_array)
    end
  end

  # Instructions on relabeling plates to new plate ID
  # Tracks provenance properly though transfer
  #
  # @param plate1 [Collection] plate to relabel
  # @param plate2 [Collection] new plate label
  def relabel_plate(from_collection, to_collection)
    to_col_map = AssociationMap.new(to_collection)
    from_col_map = AssocaitionMap.new(from_collection)
 
    to_collection.associate(plate_key, input_plate)
    add_provenance(from: from_collection, from_map: from_col_map,
                    to: to_collection, to_map: to_col_map)
    to_col_map.save
    from_col_map.save
    show do
      title 'Rename Plate'
      note "Relabel plate <b>#{from_collection.id}</b> with <b>#{to_collection.id}</b>"
    end
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


  # Assigns samples to specific well locations, they are added in order of the list
  #
  # @param samples [Array<FieldValue>] or [Array<Samples>]
  # @param to_collection [Collection]
  # @param add_row_wise [Boolean] default true will add samples by column and not row
  # @raise if not enough space in collection
  def add_samples_to_collection(samples, to_collection, add_column_wise: true)
    samples.map! { |fv| fv = fv.sample } if samples.first.is_a? FieldValue
    slots_left = to_collection.get_empty.length
    raise 'Not enough space in in collection for all samples' if samples.length > slots_left

    if add_column_wise
      add_samples_column_wise(samples, to_collection)
    else
      to_collection.add_samples(samples)
    end
  end

  # Makes the required number of collections and populates the collections with samples
  # returns an array of of collections created
  #
  # @param samples [Array<FieldValue>] or [Array<Samples>]
  # @param collection_type [String] the type of collection that is to be made and populated
  # @param add_column_wise [Boolean] default true.  Will add samples by column and not row
  # @param label_plates [Booelan] default false, Mark as true if you want instructions to label plates to be shown
  # @param first_colleciton [Collection] a starting collection to be completely filled first before moving on to
  #         making new collections.
  # @return [Array<Collection>] an array of the collections that are now populated
  #
  # TODO Probably needs to move from collection Transfer
  def make_and_populate_collection(samples, collection_type, add_column_wise: true, label_plates: false)
    obj_type = ObjectType.find_by_name(collection_type)
    capacity = obj_type.columns * obj_type.rows
    collections = []
    grouped_samples = samples.in_groups_of(capacity, false)
    #TODO This if else thing could totally be removed if I figured out a way to get the capacity
    # of the collection without making the collection first.  I am sure there is a way to do this
    # however I haven't the time rn to figure it out.
    grouped_samples.each_with_index do |sub_samples, idx|
      collection =  make_new_plate(collection_type, label_plate: label_plates)
      add_samples_to_collection(sub_samples, collection, add_column_wise: add_column_wise)
      collections.push(collection)
    end
    collections
  end

  # Adds samples to the first slot in the first available column
  # as opposed to column wise that the base version does.
  #
  # @param samples_to_add [Array<Samples>] an array of samples
  # @param collection [Collection] the collection to include samples
  def add_samples_column_wise(samples_to_add, collection)
    col_matrix = collection.matrix
    collumns = col_matrix.first.size
    rows = col_matrix.size
    samples_to_add.each do |sample|
      break_patern = false
      collumns.times do |col|
        rows.times do |row|
          if collection.part(row, col).nil?
            collection.set(row, col, sample)
            break_patern = true
            break
          end
        end
        break if break_patern
      end
    end
  end

  # Creates Data Association between working plate items and input items
  # Associates corrosponding well locations that contain a part.
  #
  # @param to_collection [Collection] the plate that is getting the association
  # @param from_collection [Collection] the plate that is transfering the association
  # @param Association_map [Array<Hash<from_loc: loc1, to_loc: loc2>] 
  #             Assiciation map of where items were coming from
  # @param transfer_vol [Integer] the volume transfered if applicable default nil
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

      associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_part, 
                    from_part: from_part) unless transfer_vol.nil?

      from_obj_to_obj_provenance(to_part, from_part)
    end
  end


  # Creates data association based on plate map for transfer of sample from one item to wells
  # in the collection.  Additionally tracks provenance through items.
  #
  #
  # @param to_collection [Collection] the plate that is getting the association
  # @param from_item [item] the item that is transfering the association
  # @param Association_map [Array<row, column>] Assiciation map of where items 
  #     are coming from.  If nil will assume transfered to all wells.  Can take standard 
  #     Array of Hashes as used in other methods in this library
  # @param transfer_vol [Integer] the volume transfered if applicable default nil
  #   if nil then will state unknow transfer vol
  def associate_item_to_wells(from_item:, to_collection:, association_map: nil, transfer_vol: nil)
    if association_map.nil?
      association_map = to_collection.get_non_empty
    end
    association_map.each do |to_loc|
      to_loc = to_loc[:TO_LOC] if to_loc.is_a? Hash
      to_loc = convert_alpha_to_rc if to_loc.is_a? String

      to_part = to_collection.part(to_loc[0],to_loc[1])
      associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_part, 
                from_part: from_item) unless transfer_vol.nil?
      from_obj_to_obj_provenance(to_part, from_item)
    end
  end



  # Creates data association based on plate map for transfer of sample from one/many wells to
  # one item
  # Additionally tracks provenance through items.
  #
  #
  # @param from_collection [Collection] the is transfereing the association
  # @param to_item [item] the item that is getting_the association
  # @param Association_map [Array<row, column>] Assiciation map of where items 
  #     are coming from.  If nil will assume transfered from all wells.  Can take standard 
  #     Array of Hashes as used in other methods in this library
  # @param transfer_vol [String] the volume transfered if applicable
  def associate_wells_to_item(to_item:, from_collection:, association_map: nil, transfer_vol: nil)
    if association_map.nil?
      association_map = from_collection.get_non_empty
    end
    association_map.each do |to_loc|
      from_loc = loc[:TO_LOC] if loc.is_a? Hash
      from_loc = convert_alpha_to_rc if from_loc.is_a? String

      from_part = from_collection.part(from_loc[0],from_loc[1])
      associate_transfer_vol(transfer_vol, VOL_TRANSFER, to_part: to_item, 
                from_part: from_part) unless transfer_vol.nil?
      from_obj_to_obj_provenance(to_item, from_part)
    end
  end



  # Creates associations from wells to items based on the association map.
  # The map directs wich wells and what items are associated.   Should be in the form
  # Array<Array<to_item, [r,c]>>  where [r,c] is the location in the collection that the
  # item should be from.
  #
  # @param from_collection [Collection] the collection that the item should be from
  # @param assocaition_map [Array<Array<item, [row, col]>>] or 
  #           [Array<Array<item, Hash{FROM_LOC: [r,c]}>>]
  # @param transfer_vol [String] the volume transfered INCLUDE UNITS
  def associate_wells_to_multiple_items(from_collection:, association_map:, transfer_vol: nil)
    association_map.each do |to_item, loc|
      associate_wells_to_item(to_item: to_item, from_collection: from_collection, 
                association_map:[loc], transfer_vol: transfer_vol)
    end
  end





  # Records the volume of an item that was transfered (or at least what the code)
  # instructed the technition to transfer.   Creates an array of all the transfered volumes
  # for future use Array<Array<from_part_id, volume>, ...>
  # @param vol the volume transfered
  # @param to_part: part that is being transfered to
  # @param from_part: part that is being transfered from
  def associate_transfer_vol(vol, key, to_part:, from_part:)
    vol_transfer_array = get_associated_data(to_part, key)
    vol_transfer_array = [] if vol_transfer_array.nil?
    vol_transfer_array.push([from_part.id, vol])
    associate_data(to_part, key, vol_transfer_array)
  end
end