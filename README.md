# CollectionManagement
A series of libraries for managing and controlling collection and samples inside of collections

This document is meant to as a guide to the basic uses of this library.  It does not, however, cover everything that can be done.  Please explore the library or the <b>HowToCollectionManagement</b> to learn more.

## CollectionActions

Many basic actions can be done with a Collection using CollectionActions

A new collection can easily be made and instructions given to retrieve and label the collection with one line.  By default instructions will be given however these instructions can be skipped if ```label_plate``` is false.
```Ruby
new_collection = make_new_plate('96 Well Sample Plate', label_plate: true)
```


Often we may want to make and populate a collection (or collections) quickly.
the ```make_and_populate_collection```  method will create, label,
and fill a plate (or plates) with the array of samples or field values all in one line.
If there are more samples than one plate can hold additional plates will be created.

You can either give the method the collection_type as shown or 
pass along the ```first_collection:``` which will be completely filled
before more collections of the same ```object_typ``` will be created and populated

You can fill either column_wise or row wise
```Ruby
samples = operations.first.input_array('InputArray')
array_of_plates = make_and_populate_collection(samples, collection_type: '96 Well Sample Plate', 
                                                        add_column_wise: true,
                                                        label_plates: false)
```
Some additional methods which may be helpful but which are mostly self explanatory:
```Ruby
add_samples_to_collection(samples, new_collection, add_column_wise: true)
set_location([new_collection], "My New Location")

show do
  title "Here we display the location of our collection"
  table create_location_table([new_collection])
end

store_items(new_collection, location: 'Short Term Storage')
trash_objects(new_collection)
```
## CollectionLocation
CollectionLocation is primarily for giving and managing locations of items inside of collections.  It does not manage the physical location of the Collection its self (thats what CollectionActions is for).

First if we want to find the location of a sample in the collection we can call ```collection.find(sample)``` this will return an array [row, column]
```Ruby
row, column = location_collection.find(sample)
```

Similarly we could use ```get_obj_location(collection, object_to_find)```.  You can pass this method either a single object or an array of objects if you pass a single object it will work exactly the same as ```.find``` however if an array of objects are passed the method will return a Hash of the locations ```{part: [row, col], part_2: [row, column]}```
```Ruby
returned_locations = get_obj_location(collection, array_of_samples)
```

Alternativly we can call ```get_alpha_num_location```.  This works exactly the same except it will return a hash of alpha numerical locations ```{part: 'A1', part_2: 'B6}```.
```Ruby
alpha_location = get_alpha_num_location(collection, array_of_samples)
```

## CollectionDisplay
It is very important to display information to techs in a clear, consistant manner.  CollectionDisplay has been built to assist in this edevour.  The primary focus is to display the layout of a collection and make highlighting or noting cells as easy as possible.

To show all filled slots simply put highlight_non_empty

The check option sets the wells as "checkable" this forces the tech to click on each slot before they can click continue.
```Ruby
show do 
  title "This is all the filled slots"
  table highlight_non_empty(collection, check: false)
end
```

###TODO insert example image here

To show all empty slots
```Ruby
show do
  title "This is all the empty slots"
  table highlight_empty(display_collection, check: false)
end
```
###TODO insert example image here


To express more specific instructions we need to establish the idea of an ```rcx_list```.
An ```rcx_list``` take the form of ```[[row, column, x], [row_1, column_1, x_1], ...]```.
- r = row
- c = column
- x = string

The row and column determin in which well the string ```x``` will be displayed.  ```x``` really can be anything so long as it can be displayed as a string.  Keep in mind, however, that the when displayed there isn't alot of space so keep ```x``` as short as reasonable.

Once an `rcx_list` has been built we can easily display the information as shown below:
```Ruby
show do 
  title "Showing RCX list"
  table highlight_collection_rcx(display_collection, rcx_list, check: false)
end
```


## CollectionTransfer
CollectionTransfer gets down to the nitty gritty of the CollectionManagement libraries.   Its sole pourpose is to assist in managing the transfer of stuff into and out of a collection.  These methods can be very powerful but that also comes with complexity.  The methods described here are the most basic uses of CollectionTransfer and to truly use these well time will be needed to further explore and learn about the library.

Often we want to transfer some set of items into a collection.  These items may be in a collection already or may be individual items from somewhere else.  Regardless ```transfer_subsamples_to_working_plate``` can be a huge help.
This method will automatically populate the collection and track provenance. It can also provide instructions on retrieving and transferring items to the plate
It will return all the collections in an array (will include 'to_collection' if applicable)

If you have already created a collection you want to add to us the ```to_collection``` option if this collection doesn't have enough space a new collection of the same type will automatically be generated.  Alternatively you can just provide the ```collection_type``` and all needed collections will be created.
```Ruby
all_new_collections = transfer_subsamples_to_working_plate(fv_array, to_collection: nil,
                                                               collection_type: "96 Well Sample Plate",
                                                               transfer_vol: '13 ul',
                                                               instructions: true)
```
###TODO Add picture here

Sometimes a plate simply needs to be relabeled.
```relabel_plate``` will make this very easy to do.
```Ruby
relabeled_collection = relabel_plate(collection)
```


Take some time to explore the following methods.  These methods are more complex and harder to use but they really give you the power to transfer however you want
```transfer_from_collection_to_collection```
```transfer_items_to_collection```
```transfer_from_collection_to_items```

## CollectionData
The primary function is to assist with associating and managing data across a plate.  All the methods in this library are failry self explanatory so they will not be noted here.

The most important concept to understand when working with this library is that of the 
```data_map```.  A ```data_map``` is essentially the same as an ```rcx_list``` (as mentioned above) with a few specificities.

A data map is in the form of ```[[row,colun, x, k(optional)], ...]```
- r = row
- c = column
- x = data
- k = key (optional in many cases)

The row and column say which well the data should be associated with.
The data can be anything! A number, file, another object...
The key is association key that you want to go with the data.  It will be the only link in the future to the data so chose your key carefully!
