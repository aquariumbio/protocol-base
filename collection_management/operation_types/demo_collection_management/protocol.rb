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


    #CollectionActions

    #many basic actions can be done with a Collection using CollectionActions

    # A new collection can easily be made and instructions given to retrieve and
    # label the collection with one line.  By default instructions will be given
    # however these instructions can be skipped if label_plate is false
    new_collection = make_new_plate('96 Well Sample Plate', label_plate: true)

    #We can set the location of an array of collections easily using
    set_location([new_collection], "My New Location")

    # If we want to see where all these locations are and diplay this to the tech
    # We can use a short show block and utilize "create_location_table"
    show do
      title "Here we display the location of our collection"
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








    # CollectionLocation
    # ColelctionLocation is primarily for giving and managing locations of items inside of collections
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
      array_of_samples += op.input_array('InputArray').each {|fv| fv.sample}
    end
    example_sample = array_of_samples.first

    # This is a built in colleciton method that will add the array of samples to the collection
    location_collection.add_samples(array_of_samples) #populates the colleciton with samples


    # first if we want to find the location of a sample in the collection we can call
    # collection.find(sample) this will return an array [row, column]
    row_col_location = location_collection.find(example_sample)
    show do 
      note "#{row_col_location}"
    end

    # similarly we could use get_obj_location(collection, object_to_find)
    # You can pass this method either a single object or an array of objects
    # if you pass a single object it will work exactly the same as .find
    # however if an array of objects are passed the method will return a Hash
    # with keys as the searched object and the values as the array of locations
    returned_locations = get_obj_location(collection, array_of_samples)
    show do
      title "The locations of many objects"
      returned_locations.each do |key, array_of_locations|
        note "The object #{key.id} is in locations #{array_of_locations}"
      end
    end

    # If you know that you will want the Alpha Numerical location when you search for an object
    # you can use get_alpha_num_location.   This works exactly the same as get_obj_locations
    # Except it will return alpha numerical locations and not coordinates
    alpha_location = get_alpha_num_location(collection, array_of_samples)




    # The functions above are useful but really dont really expand the standard methods very much
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
      title "Demonstration of convert_coordinates_to_location and convert_location_to_coordinates methods"
      note "#{coordinate}"
      note "#{alpha_location}"
    end



    # A common need is to find the part at a certain location in a collection
    # if we know the coordinate location of the part doin this is easy.  Simple put
    # collection.part(row,location)
    item = location_collection.part(1,1)

    # However if we only know the Alpha Numerical Location then you can use
    item = locate_part(location_collection, 'A1')


    trash_objects(location_collection)

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

    
    #First we need to create a colleciton with some samples
    display_collection = make_new_plate('96 Well Sample Plate', label_plate: false)
    array_of_samples = []
    operations.each do |op|
      array_of_samples += op.input_array('InputArray').each {|fv| fv.sample}
    end
    example_sample = array_of_samples.first
    display_collection.add_samples(array_of_samples)



    # To show all filled slots simply put highlight_non_empty
    #
    # The check option sets the wells as "checkable"
    # this forces the tech to click on each slot before they can click continue.
    # in this case check is set to false
    show do 
      title "This is all the filled slots"
      table highlight_non_empty(display_collection, check: false)
    end

    # To show all empty slots simply put
    show do
      title "This is all the empty slots"
      table highlight_empty(display_collection, check: false)
    end

    # The following two methods work the same as the the previous two
    # The only difference is that they also show a string with the 
    # alpha numerical location
    show do 
      title "Showing the alpha numerical labels as well"
      note "All the filled slots"
      table highlight_alpha_non_empty(display_collection, check: false)
      note "This is all the empty slots"
      table highlight_alpha_empty(display_collection, check: false)
    end
    
    


    # There are many ways to create an RCX list often a protocol will need a custom
    # format depending on what information is to be displayed.  It will be up to you
    # to make these custom RCX lists.  However there are a few basic methods that have been
    # created that make standard/common RCX lists.

    # One common desire is to display a collection and show the Alpha Numerical location
    # of some subset of samples.  This can illustrate a specific number of wells and ensure
    # there is a low chance of misunderstanding.  The following method makes an RCX list of teh
    # form [[row, column, AlphaLocation], ...]
    #
    # This method takes the collection and a list of samples or items that you want displayed
    # if a sample is in the collection multiple times it will create rcx components for each
    # location
    rcx_list = get_rcx_list(collection, array_of_samples)





    

    

  end

end
