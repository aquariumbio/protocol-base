# Collection Management

modulesA series of libraries for managing samples in of collections

## Dependencies
- [**Standard Libs**](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs)

    - [ItemActions](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/itemactions)
    - [AssociationManagement](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/associationmanagement)
    - [PartProvenance](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/associationmanagement)
    - [Units](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/units)

- [**Small Instruments**](https://github.com/aquariumbio/protocol-base/tree/main/small_instruments)
    - [Pipettors](https://github.com/aquariumbio/protocol-base/tree/main/small_instruments/libraries/pipettors)


## Modules

### [Collection Actions](https://github.com/aquariumbio/protocol-base/tree/main/collection_management/libraries/collectionactions)

Basic actions with Collections, such as:

- Creating or deleting
- Labeling
- Moving or fetching

#### Usage

To make a new collection:

```Ruby
new_collection = make_new_plate('96 Well Sample Plate')
```
By default instructions will ask the experimenter to retrieve and label the plate. However these instructions can be skipped if `label_plate` is false.

```Ruby
new_collection = make_new_plate('96 Well Sample Plate', label_plate: false)
```
To make a new collection and populate it with samples:
```Ruby
samples = <array of samples>
array_of_plates = make_and_populate_collection(samples, collection_type: '96 Well Sample Plate',
                                                        add_column_wise: true,
                                                        label_plates: false)
```
If there are more samples than one plate can hold additional plates will be created. Defaults to filling row-wise, but column-wise can be specified by setting `add_column_wise: true`.

Some additional methods which may be helpful but which are mostly self explanatory:
```Ruby
add_samples_to_collection(samples, collection, add_column_wise: true)
set_location([collection], "My New Location")

show do
  title "Display the location of our collection"
  table create_location_table([collection])
end

store_items(collection, location: 'Short Term Storage')
trash_objects(collection)
```
### [Collection Location](https://github.com/aquariumbio/protocol-base/tree/main/collection_management/libraries/collectionlocation)
CollectionLocation is primarily for giving and managing locations of items inside of collections. It does not manage the physical location of the Collection its self (thats what CollectionActions is for). Most methods are primarily for internal use.

First if we want to find the location of a sample in the collection we can call `collection.find(sample)` this will return an array [row, column]
```Ruby
row, column = location_collection.find(sample)
```

Similarly we could use `get_obj_location(collection, object_to_find)`.  You can pass this method either a single object or an array of objects if you pass a single object it will work exactly the same as `.find` however if an array of objects are passed the method will return a Hash of the locations `{part: [row, col], part_2: [row, column]}`
```Ruby
returned_locations = get_obj_location(collection, array_of_samples)
```

Alternativly we can call `get_alpha_num_location`.  This works exactly the same except it will return a hash of alpha numerical locations `{part: 'A1', part_2: 'B6}`.
```Ruby
alpha_location = get_alpha_num_location(collection, array_of_samples)
```

### [Collection Display](https://github.com/aquariumbio/protocol-base/tree/main/collection_management/libraries/collectiondisplay)
The [Collection Display](https://github.com/aquariumbio/protocol-base/tree/main/collection_management/libraries/collectiondisplay) library works with the built in Show Blocks to display useful visual representations of collections.

Where ID is the ID of the collection (inclusion of the ID function is optional).
![Example Image](/images/CollectionDisplay/plate.png)

Most methods contain a few important inputs:

- **collection** the collection of interest
- **check** [Boolean] if true any 'highlighted' cells will required the technician to click on that cell before they can move on.  This can become laborious for the technician so use with care.
- **rc_list** a list of `rows` and `columns` that should be highlighted e.g. `[[1,1], [1,2], [1,3]`
- **rcx_list** a list of `rows`, `columns`, and `x` that should be highlighted.  `x` will be displayed (as a string) in the corresponding well e.g. `[[1,1,'This'], [1,2,'is'], [1,3,'displayed']]`

There are really only a few methods in this library that most people will need to use, listed below:

- `highlight_non_empty` highlights all non empty slots in a collection
- `highlight_empty` highlights all empty slots
- `highlight_alpha_non_empty` highlights all non empty and adds alpha numerical location in slot
- `highlight_alpha_empty` highlights all empty and adds alpha numerical location in slot
- `highlight_rc` highlights all slots listed in **rc list**
- `highlight_rcx` highlights all slots and adds `x` in **rcx_list**
- `display_sample_id` highlights all non-empty slots and displays each corresponding sample id
- `display_data` highlights all non-empty slots (or all slots listed in **rc_list**) and any data associated with given key

To show all filled slots simply put highlight_non_empty

The check option sets the wells as "checkable" this forces the tech to click on each slot before they can click continue.
```Ruby
show do
  title "This is all the filled slots"
  table highlight_non_empty(collection, check: false)
end
```

To show all empty slots
```Ruby
show do
  title "This is all the empty slots"
  table highlight_empty(display_collection, check: false)
end
```

To express more specific instructions we need to establish the idea of an `rcx_list`.
An `rcx_list` take the form of `[[row, column, x], [row_1, column_1, x_1], ...]`.
- r = row
- c = column
- x = string

The row and column determin in which well the string `x` will be displayed.  `x` really can be anything so long as it can be displayed as a string.  Keep in mind, however, that the when displayed there isn't alot of space so keep `x` as short as reasonable.

Once an `rcx_list` has been built we can easily display the information as shown below:
```Ruby
show do
  title "Showing RCX list"
  table highlight_collection_rcx(display_collection, rcx_list, check: false)
end
```


### [Collection Transfer](https://github.com/aquariumbio/protocol-base/tree/main/collection_management/libraries/collectiontransfer)
CollectionTransfer gets down to the nitty gritty of the CollectionManagement libraries. Its sole pourpose is to assist in managing the transfer of stuff into and out of a collection. These methods can be very powerful but that also comes with complexity. The methods described here are the most basic uses of CollectionTransfer and to truly use these well time will be needed to further explore and learn about the library.


The following parameters are common within these libraries:

- `to_collection`: the collection that samples are being transferred to.
- `from_collection`: the collection that samples are being transferred from.
- `association_map`: a map displaying **from_location** and the **to_location**.  Both parts are not always required however all `association_maps` follow this format: `[{to_loc: [1,1], from_loc: [1,1]}, {to_loc: [1,2], from_loc: [2,3]}]`. Where `to_loc` is the location in the `to_collection` and `from_collection` is the location in the `from_location`.   `to_loc` and `from_loc` can be any valid coordinate location in a collection.
- `source`: most commonly an item but can be any string e.g. 'reservoir trough'.  This is only ever used for display methods.
- `transfer_vol` must be in the units format from [Standard Libs/Units](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/units)


The following methods are the most useful methods:

- `one_to_one_association_map` creates a map that sets both `to_loc` and `from_loc` to the same location as each existing well in the `from_collection`.  This can be handy when working with exact copies of collections

- `copy_wells` will set all wells of `to_collection` to the same sample as `from_collection`.  This will overwrite any existing samples in `to_collection`.

- `multichannel_item_to_collection`, `single_channel_item_to_collection`, `single_channel_collection_to_collection`, and `multichannel_collection_to_collection` should handle both display and association management in most cases.  Additional methods are provided for more complex transfers.

Often we want to transfer some set of items into a collection.  These items may be in a collection already or may be individual items from somewhere else.  Regardless `transfer_subsamples_to_working_plate` can be a huge help.
This method will automatically populate the collection and track provenance. It can also provide instructions on retrieving and transferring items to the plate
It will return all the collections in an array (will include 'to_collection' if applicable)

If you have already created a collection you want to add to us the `to_collection` option if this collection doesn't have enough space a new collection of the same type will automatically be generated.  Alternatively you can just provide the `collection_type` and all needed collections will be created.
```Ruby
all_new_collections = transfer_subsamples_to_working_plate(fv_array, to_collection: nil,
                                                               collection_type: "96 Well Sample Plate",
                                                               transfer_vol: '13 ul',
                                                               instructions: true)
```
###TODO Add picture here

Sometimes a plate simply needs to be relabeled.
`relabel_plate` will make this very easy to do.
```Ruby
relabeled_collection = relabel_plate(collection)
```


Take some time to explore the following methods.  These methods are more complex and harder to use but they really give you the power to transfer however you want
`transfer_from_collection_to_collection`
`transfer_items_to_collection`
`transfer_from_collection_to_items`

## CollectionData
The primary function is to assist with associating and managing data across a plate.  All the methods in this library are failry self explanatory so they will not be noted here.

The most important concept to understand when working with this library is that of the
`data_map`.  A `data_map` is essentially the same as an `rcx_list` (as mentioned above) with a few specificities.

A data map is in the form of `[[row,colun, x, k(optional)], ...]`
- r = row
- c = column
- x = data
- k = key (optional in many cases)

The row and column say which well the data should be associated with.
The data can be anything! A number, file, another object...
The key is association key that you want to go with the data.  It will be the only link in the future to the data so chose your key carefully!
