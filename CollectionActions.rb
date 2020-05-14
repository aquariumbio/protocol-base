# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Module for working with collections
# These actions should involve the WHOLE plate not individual wells.
# NOTE: The collection is doing the whole action
module CollectionActions
  # Store all items used in input operations
  #
  # @param operations [OperationList] the list of operations
  # @param location [String] the storage location
  def store_input_collections(operations, location: nil)
    store_collection_materials(operations, location: location, role: 'input')
    # show do
    #   title 'Put Away the Following Items'
    #   table material_storage_locations(operations, role: 'input',
    #           location: location)
    # end
  end

  # NOTE: Is there a reason these are seperate methods? 
  # Stores all items used in output operations
  #
  # @param operations [OperationList] the operation list where all
  # output collections should be stored
  def store_output_collections(operations, location: nil)
    store_collection_materials(operations, location: location, role: 'output')
    # show do
    #   title 'Put Away the Following Items'
     #  table material_storage_locations(operations, role: 'output',
      #         location: location)
   #  end
  end

  # Sets the location of all objects in array to some given locations
  #
  # @param items Array[Collection] or Array[Items] an array of any objects
  # that extend class Item
  # @param location [String] the location to move object to
  # (String or Wizard if Wizard exists)
  def set_locations(items, location)
    items.each do |item|
      item.move(location)
      item.save
    end
  end

  # Creates table directing technician on where to store materials
  #
  # @param collection [Collection] the materials that are to be put away
  # @return location_table [Array<Array>] of Collections and their locations
  def create_location_table(items)
    location_table = [['ID', 'Object Type', 'Location']]
    items.each do |item|
      location_table.push([item.id, item.object_type.name, item.location])
    end
    location_table
  end

  # Wrapper for old method that was renamed and moved
  #
  # Creates table of locations, object type, and ID
  def get_collection_location_table(obj_array)
    create_location_table(obj_array)
  end

  # Instructions to store a specific item
  #
  # @param obj_item [Item/Object] that extends class item or Array
  #        extends class item all items that need to be stored
  # @param location [String] Sets the location of the items if included
  def store_items(obj_item, location: nil)
    show do
      title 'Put Away the Following Items'
      unless obj_item.is_a? Array
        set_locations([obj_item], location) unless location.nil?
        table create_location_table([obj_item])
      else
        set_locations(obj_item, location) unless location.nil?
        table create_location_table(obj_item)
      end
    end
  end

  # Instructions for tech on how and where to store materials
  #
  # @deprecated wrapper for meterial_storage_locations_table
  def store_collection_materials(operations, location: nil, role: nil, all_items: false)
    material_storage_locations_table(operations, role: role, location: location, all_items: all_items)
  end

  # Stores all items of a certain role in the operations list
  # Creates table for storage
  #
  # @param operations [OperationList] list of Operations 
  # @param role [String] whether material to be stored is an input or an output
  # @param location [String] the location to store the material
  # @param all_items [Boolean] an option to store all items not just collections
  def material_storage_locations_table(operations, role: 'input', location: nil, all_items: false)
    io_objects = []
    operations.each do |op|
      field_values = op.inputs.reject { |fv|
              fv.collection.nil? unless all_items } if role == 'input'
      field_values = op.outputs.reject { |fv|
              fv.collection.nil? unless all_items } if role == 'output'
      io_objects.concat(get_io_objects(field_values))
    end
    store_items(io_objects, location: location)
  end

  # NOTE: is this method meant to tell someone to trash an item or is it to make a table of items with the place to trash them? I am confused as it has a show block, but it returns a table? 
  # Gives directions to throw away an object (collection or item)
  #
  # @param obj or array of Item or Object that extends class Item  eg collection
  # @param hazardous [boolean] if hazardous then true
  def trash_object(obj_array, hazardous: true)
    # toss QC plate
    obj_array = [obj_array] if obj_array.class != Array

    show do
      title 'Trash the following items'
      tab = [['Item', 'Waste Container']]
      obj_array.each do |obj|
        obj.mark_as_deleted
        if hazardous
          waste_container = 'Biohazard Waste'
        else
          waste_container = 'Trash Can'
        end
        tab.push([obj.id, waste_container])
      end
      table tab
    end
  end

  # makes a new plate and provides instructions to label said plate
  #
  # @param c_type [String] the collection type
  # @param label_plate [Boolean] whether to get and label plate or no default true
  # @return working_plate [Collection]
  def make_new_plate(c_type, label_plate: true)
    working_plate = Collection.new_collection(c_type)
    get_and_label_new_plate(working_plate) if label_plate # Is there a reason you wouldn't need to label the plate?
    working_plate
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
  end

  # Wrapper on Old Method in case anyone was using it
  #
  # @param array_of_fv [Array] array of field values
  # @return obj_array [Array] array of objects (either collections or items)
  def get_obj_from_fv_array(array_of_fv)
    get_io_objects(array_of_fv)
  end

    # Replaces operations.make
  # Ensures that all items remain together in one Collection
  # the Collection must already have the samples set in the Collection
  #
  # @param field_values [Array<Field Values>] array of field values
  # @param collection [Collection] the destination collection
  # replaced make_output_plate
  def associate_field_values_to_plate(field_values, collection)
    field_values.each do |fv|
      r_c = collection.find(fv.sample).first
      fv.set(collection: collection, row: r_c[0], column: r_c[1]) unless r_c.first.nil?
    end
  end

  # Get the object (either Item or Collection) from field_value
  #
  # @param field_values [Array] array of Field Values
  # @return io_objects [Array] array of objects (either collections or items)
  def get_io_objects(field_values)
    io_objects = []
    field_values.each do |field_value|
      if !field_value.collection.nil?
        io_objects.push(field_value.collection)
      elsif !field_value.item.nil?
        io_objects.push(field_value.item)
      else
        raise "Invalid class.  Neither collection nor item. Class = #{field_value.class}"
      end
    end
    io_objects.uniq
  end

end
