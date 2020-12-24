# Aquarium Sample Models

Aquarium Sample properties can be awkward to work with. For example, Primer sequences are stored in our instance as two sub-sequences:

```ruby
primer = Sample.find_by_name("My Primer")
overhang_seq = primer.properties.fetch("Overhang Sequence")
anneal_seq = primer.properties.fetch("Anneal Sequence")
seq = overhang_seq + anneal_seq
length = seq.length
```

The Primer model makes this much easier:
```ruby
needs "Sample Models/Primer"
.
.
.
# Instantiate the Primer by passing an Aquarium Sample (of SampleType Primer)
primer = Primer.new(sample: Sample.find_by_name("My Primer"))

# Get the length of the primer
length = primer.length
```
## Making new model classes
It's easy to make new classes that model your Aquarium `Samples`. First, define the class so that it inherits `AbstractSample`:

```ruby
needs "Sample Models/AbstractSample"

# Defines the MySample with methods to manage its properties,
#   such as....
class MySample < AbstractSample
```

By convention, we define private constants to store the string names of the `SampleType` and its attributes:

```ruby
    THIS_SAMPLE_TYPE = "MySample"
    MY_ATTRIBUTE = "My Attribute"

    private_constant(
      :MY_ATTRIBUTE
    )
```

Add methods to initialize from a `Sample` object (and an `Item` object if desired)

```ruby
    # Instantiates a new MySample
    #
    # @param sample [Sample] Sample of SampleType "MySample"
    # @return [MySample] instance of MySample
    def initialize(sample:)
        super(sample: sample, expected_sample_type: THIS_SAMPLE_TYPE)
    end

    # Instantiates a new MySample from an Item
    #
    # @param item [Item] Item of a Sample of SampleType "MySample"
    # @return [MySample]
    def self.from_item(item)
        MySample.new(sample: item.sample)
    end
```

That's enough to have a functional wrapper that you can use like so:

```ruby
# Instantiate MySample by passing an Aquarium Sample (of SampleType MySample)
this_sample = MySample.new(sample: Sample.find_by_name("The Sample I Want"))

# Get the attribute called "My Attribute"
attribute = this_sample.fetch("My Attribute")
```

That's OK, but doesn't make for the the best coding experience, especially if there are common computations that need to be done on the attribute. You can add methods like this to the `MySample` class:
```ruby
# My attribute
#
# @return [Fixnum]
def my_attribute
  fetch("My Attribute")
end

# My computed attribute
#
# @return [Fixnum]
def my_computed_attribute
  my_attribute * 5
end
```

These are used as:

```ruby
this_sample.my_attribute
this_sample.my_computed_attribute
```