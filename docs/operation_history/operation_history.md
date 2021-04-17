# Operation History
A module for finding the history of `Operation`s that produced an `Item` and retrieving
data about that history.

## Usage
The preferred way to use this module is through the `OperationHistoryFactory` class:
```ruby
operation_history = OperationHistoryFactory.new.from_item(item_id: item_id)
operation_history.all_keys
=> ["exonucleased_sample", "forward_primer", "frac_positive", "fragment", "gel"]
```

To get all the data associated with a given key:
```ruby
operation_history.fetch_data("frac_positive")
=> [0.2988, 0.0256]
```
Note that all keys, including input and output names are converted to `camel_case`. Thus, `"forward_primer"`
returns DataAssociations with the key `"forward_primer"` as well as inputs with the name "Forward Primer".

For more examples, see [Test Operation History](test_operation_history/protocol.rb) and [Demo Operation History](demo_operation_history/protocol.rb).

## Tests
The Test Operation History protocol contains automated integration tests for this module and
runs uisng [pfish](https://github.com/aquariumbio/pfish) without needing to load any
sample types or object types.

