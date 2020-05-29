# This is to show the basic uses of the Collection Management library
needs 'Collection_Management/CollectionDisplay'
needs 'Collection_Management/CollectionTransfer'
needs 'Collection_Management/CollectionActions'
needs 'Collection_Management/CollectionLocation'

class Protocol
  include CollectionDisplay
  include CollectionTransfer
  include CollectionLocation
  include CollectionActions


  def main


    # CollectionActions

    # Many basic actions can be done with a Collection using CollectionActions

    # A new collection can easily be made and instructions given to retrieve and
    # label the collection with one line.  By default instructions will be given
    # however these instructions can be skipped if label_plate is false
    new_collection = make_new_plate('96 Well Sample Plate', label_plate: true)

    # Often we may want to make and populate a collection(or collections) quickly.
    # the make_and_populate_collection  method will create, label,
    # and fill a plate(or plates) with the array of samples or field values all in one line.
    # If there are more samples than one plate can hold additional plates will be created.
    #
    # You can either give the method the collection_type as shown or
    # pass along "first_collection: collection" which will be completely filled
    # before more collections of the same object_type will be created and populated
    #
    # You can fill either column_wise or row wise
    samples = operations.first.input_array('InputArray')
    array_of_plates = make_and_populate_collection(samples, collection_type: '96 Well Sample Plate', 
                                                             add_column_wise: true,
                                                             label_plates: false)

    # if you already have the collection and you want to fill it full of samples
    # you can use add_samples_to_collection it can take an array of samples
    # or field values and will populate the plate either column wise or row wise
    add_samples_to_collection(samples, new_collection, add_column_wise: true)

    # We can set the location of an array of collections easily using
    set_location([new_collection], "My New Location")

    # If we want to see where all these locations are and display this to the tech
    # We can use a short show block and utilize "create_location_table"
    show do
      title 'Here we display the location of our collection'
      table create_location_table([new_collection])
    end

    # We can then store the collections using "store_items"
    # This will provide instructions for the storage of items as well as
    # set their location if a location string is provided
    # This either can be an array of items or an individual item
    store_items(new_collection, location: 'Short Term Storage')

    # Lastly we trash the collection (or a group of items) using 'trash_objects'
    # This will create instructions for trashing the object and set its status to 'deleted'
    # It will take either a single item or an array of items
    trash_objects(new_collection)





    #-----------------------------------------------------------------------------#


    # CollectionLocation
    # CollectionLocation is primarily for giving and managing locations of items inside of collections
    #   It does not manage the physical location of the Collection its self (thats what CollectionActions
    #   is for).

    # To look at and deal with the locations of items in a collection we must first create and populate
    # a collection with items.   There are nice methods that assist with this that will be described
    # later but for now we will just fill the collection using standard Aquarium methods

    # this time we will create a new collection but will not provide instructions to fetch
    # and label the collection.  In this case this does exactly the same thing as 
    # Collection.new_collection('96 Well Sample Plate')
    location_collection = make_new_plate('96 Well Sample Plate', label_plate: false)

    array_of_samples = []

    operations.each do |op|
      array_of_samples += op.input_array('InputArray').each { |fv| fv = fv.sample }
    end
    example_sample = array_of_samples.first

    # This is a built in collection method that will add the array of samples to the collection
    location_collection.add_samples(array_of_samples) # populates the colleciton with samples


    # first if we want to find the location of a sample in the collection we can call
    # collection.find(sample) this will return an array [row, column]
    row_col_location = location_collection.find(example_sample)
    show do 
      note row_col_location.to_s
    end

    # similarly we could use get_obj_location(collection, object_to_find)
    # You can pass this method either a single object or an array of objects
    # if you pass a single object it will work exactly the same as .find
    # however if an array of objects are passed the method will return a Hash
    # with keys as the searched object and the values as the array of locations
    returned_locations = get_obj_location(collection, array_of_samples)
    show do
      title 'The locations of many objects'
      returned_locations.each do |key, array_of_locations|
        note "The object #{key.id} is in locations #{array_of_locations}"
      end
    end

    # If you know that you will want the Alpha Numerical location when you search for an object
    # you can use get_alpha_num_location.   This works exactly the same as get_obj_locations
    # Except it will return alpha numerical locations and not coordinates
    alpha_location = get_alpha_num_location(collection, array_of_samples)




    # The functions above are useful but really don't really expand the standard methods very much
    # The CollectionLocations library really helps out when dealing with locations listed in both
    # the [row, column] format as well as the AlphaNumerical format (e.g. A1, B12)

    # Two methods to help with conversion between Alpha Numerical location and coordinates are
    # convert_location_to_coordinates and convert_coordinates_to_location wich do exactly as the name 
    # describes

    # convert_location_to_coordinates will convert an alpha numerical string into rows and coordinates
    coordinates = convert_location_to_coordinates('A1')

    # convert_coordinates_to_location will conver a coordinate into a alpha numerical string
    alpha_location = convert_coordinates_to_location([1,1])

    show do
      title 'Demonstration of convert_coordinates_to_location and convert_location_to_coordinates methods'
      note coordinates.to_s
      note alpha_location.to_s
    end



    # A common need is to find the part at a certain location in a collection
    # if we know the coordinate location of the part, doing this is easy.
    # Simple put collection.part(row,location)
    item = location_collection.part(1,1)

    # However if we only know the Alpha Numerical Location then you can use
    item = locate_part(location_collection, 'A1')


    trash_objects(location_collection)


    #------------------------------------------------------------------------------#

    # CollectionDisplay
    # One thing that is always important when writing protocols is displaying to the
    # tech what they need to do.  To assist with this CollectionDisplay was developed.

    # Before we get into the nitty gritty of CollectionDisplay a few ideas must be established
    # first.
    #
    # Most methods must be passed a Collection and an 'RCX' list.  RCX list stands for a list of the
    # format [[row, column, x], [row, column, x], ...]  where x is some extra information that affects 
    # what is displayed at the well (row, column).  Often x is just a string but in some case it can be
    # more to help influence how it is displayed.


    # First we need to create a collection with some samples
    display_collection = make_new_plate('96 Well Sample Plate', label_plate: false)
    array_of_samples = []
    operations.each do |op|
      array_of_samples += op.input_array('InputArray').each {|fv| fv = fv.sample}
    end
    display_collection.add_samples(array_of_samples)



    # To show all filled slots simply put highlight_non_empty
    #
    # The check option sets the wells as "checkable"
    # this forces the tech to click on each slot before they can click continue.
    # in this case check is set to false
    show do 
      title 'This is all the filled slots'
      table highlight_non_empty(display_collection, check: false)
    end

    # To show all empty slots
    show do
      title 'This is all the empty slots'
      table highlight_empty(display_collection, check: false)
    end


    # The following two methods work the same as the the previous two
    # The only difference is that they also show a string with the
    # alpha numerical location
    show do 
      title 'Showing the alpha numerical labels as well'
      note 'All the filled slots'
      table highlight_alpha_non_empty(display_collection, check: false)
      note 'This is all the empty slots'
      table highlight_alpha_empty(display_collection, check: false)
    end


    # There are many ways to create an RCX list often a protocol will need a custom
    # format depending on what information is to be displayed.  It will be up to you
    # to make these custom RCX lists.  However there are a few basic methods that have been
    # created that make standard/common RCX lists.

    # One common desire is to display a collection and show the Alpha Numerical location
    # of some subset of samples. The following method makes an RCX list of the
    # form [[row, column, AlphaLocation], ...]
    #
    # This method takes the collection and a list of samples or items that you want displayed
    # if a sample is in the collection multiple times it will create rcx components for each
    # location
    rcx_list = get_rcx_list(collection, array_of_samples)

    # We can then use highlight_collection_rcx to create a table
    # Check is set to false so the tech can click ok without checking
    # every box
    show do 
      title 'Showing RCX list'
      table highlight_collection_rcx(display_collection, rcx_list, check: false)
    end

    trash_objects(display_collection)

    #-------------------------------------------------------------------------#

    # CollectionTransfer
    #
    # IMPORTANT!  Take extra care when multiple items are being mixed into a well.
    #
    # CollectionTransfer is intended to assist with the transfer of items into, from, and
    #   between collections.   It will help track provenance, automatically provide instructions
    #   and generally help make transfers consistent and easy to do.
    #
    #
    # The examples included here are the basic uses of CollectionTransfer.  If you are doing
    #   more complex transfers be sure to checkout the actual library and read about 
    #   association_maps which help coordinate transfers.  There are tools to help build the maps
    #   but most often the maps will need to be custom built.




    # Often you may need to establish a list of all the in coming or outgoing plates in a job
    # using get_array_of_collections will give you a list of all uniq collections either
    # entering or exiting the job.
    #
    # the role key can either be 'input' or 'output'
    array_of_collections = get_array_of_collections(operations, 'input')



    # Additional information can quickly be found out about input or output collections using
    # the following.  Their use should be self evident
    multiple_plates?(operations, 'input') 
    number_of_plates = get_num_plates(operations, 'output')



    # Often we want to transfer some set of items into a collection.  These items may be in
    #   a collection already or may be individual items from somewhere else.  Regardless
    #   transfer_subsamples_to_working_plate can be a huge help.
    #
    # This method will automatically populate the collection and track provenance.
    # It can also provide instructions on retrieving and transferring items to the plate
    #
    # It will return all the collections in an array (will include 'to_collection' if applicable)
    # 
    # If you have already created a collection you want to add to us the "to_collection" option
    #   if this collection doesn't have enough space a new collection of the same type will
    #   automatically be generated.  Alternatively you can just provide the collection_type
    #   and all needed collections will be created.
    all_new_collections = transfer_subsamples_to_working_plate(fv_array, to_collection: nil,
                                                               collection_type: "96 Well Sample Plate",
                                                               transfer_vol: '13 ul',
                                                               instructions: true)



    # Take some time to explore the following methods.  
    # These methods are more complex  and harder to use
    #     but they really give you the power to transfer however you want
    # - transfer_from_collection_to_collection
    # - transfer_items_to_collection
    # - transfer_from_collection_to_items



    # Sometimes a plate simply needs to be relabeled.
    # In Aquarium relabeling a plate is the same as transferring it to a new plate of 
    #   the same object_type.
    #
    # relabel_plate will help with this.
    #
    # If you have already created the "to_collection" you can pass this through
    # else relabel_plate will automatically generate a new plate and populate it.
    # 
    # Remember! the 'to_collection' must be the same type of collection as the 'from_collection'
    first_collection = collections_made.first
    new_relabeled_collection = relabel_plate(first_collection)


    # -----------------------------------------------------------------------------------------------#

    # CollectionData has a handful of useful tools all of which should be fairly self explanatory.
    #
    # The primary function is to assist with associating and managing data across a plate.
    # 
    # The most important concept to understand when working with this library is that of the 
    #   'data_map'.  A 'data_map' is essentially the same as an RCX list (as mentioned above) with
    #   a few specificities.
    #
    # A data map is in the form of Array< Array<r,c,x,k(optional)>, ...>
    # r = row
    # c = column
    # x = data
    # k = key (optional in many cases)
    #
    # The row and column say which well the data should be associated with.
    # The data can be anything! A number, file, another object...
    # The key is association key that you want to go with the data.  It will be the only link
    #   in the future to the data so chose your key carefully!

  end #main
end #module
