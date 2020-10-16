# frozen_string_literal: true

needs 'Standard Libs/Units'

# Modules a component needed for a biochemical reaction
#
# Super class over both 'reagents' and 'consumables'
class Component
  include Units

  attr_reader :input_name, :qty, :units
  attr_accessor :added, :location, :description

  LOT_NUM = 'Lot_Number'

  def initialize(input_name:, qty:, units:, location: 'unknown', description: nil)
    @input_name = input_name
    @qty = qty
    @units = units
    @added = false
    @location = location
    @description = description
    @adj_qty = qty
  end

  # Returns if component is a kit
  #
  # @return [Boolean]
  def kit?
    false
  end

  # Checks if `self` has been added
  # @return [Boolean]
  def added?
    added
  end

  # The input name, formatted for display in protocols
  # @return [String]
  def display_name
    input_name
  end

  # The volume as a qty, units hash
  #
  # @return [Hash]
  def volume_hash
    { qty: qty, units: units }
  end

  # Displays the volume (`qty`) with units
  #
  # @return [String]
  def qty_display(round = 1, adj_quantities: false)
    amount = if adj_quantities
               adj_qty
             else
               qty
             end
    Units.qty_display({ qty: amount.round(round), units: units })
  end

  # provides the `qty` for display in a table, and markes it as `added`
  #
  # @param (see #adjusted_qty)
  # @return (see #adjusted_qty)
  def add_in_table(mult = 1.0, round = 1, checkable = true)
    @added = true
    adjusted_qty(mult, round, checkable)
  end

end

# Models a kit of parts in a biochemical reaction
#
# @author Cannon Mallory <malloc3@uw.edu>
class KitComponent < Component

  attr_reader :composition, :lot_number

  # Initializes the KitComponent and creates sub components
  # for the kit.
  def initialize(input_name:,
                 qty: 1,
                 units: 'Kits',
                 components: [],
                 consumables: [],
                 lot_number: nil,
                 description: nil,
                 location: 'unknown')
    super(input_name: input_name, 
          qty: qty, units: units,
          location: location,
          description: description)
    @lot_number = lot_number
    set_default_part_location(components)
    set_default_part_location(consumables)
    @composition = CompositionFactory.build(components: components,
                                            consumables: consumables)
  end

  # passes through the input to composition
  def input(string)
    @composition.input(string)
  end

  # returns the components of the kit
  def components
    @composition.components
  end

  def consumables
    @composition.consumables
  end

  # Tells if the composition is a kit
  #
  # @return [Boolean]
  def kit?
    true
  end

  def lot_number=(lot_num)
    @lot_num = lot_num
  end

  private

  # Sets the default location for kit parts to the kit name. 
  # Will not reset user defined locations.  
  def set_default_part_location(parts)
    name = @input_name.to_s
    name += "-#{@lot_num}" unless @lot_num.nil?
    parts.each do |part|
      existing_loc = part[:location]
      next unless existing_loc.nil? || existing_loc == 'unknown'

      part[:location] = name + ' Parts'
    end
  end

end

# Models a consumable component of a biochemical reaction
# These are things like Pipette Tips, spin columns, etc that
# people will use and dispose of.
#
# @author Cannon Mallory <malloc3@uw.edu>
class ConsumableComponent < Component

  attr_reader :description

  # initializes the ConsumableComponent
  def initialize(input_name:, qty:, units:,
                 description: nil, location: 'unknown')
    super(input_name: input_name, qty: qty,
          units: units, location: location, description: description)
  end

end


# Models a component of a biochemical reaction
# @author Devin Strickland <strcklnd@uw.edu>
# @author Cannon Mallory <strcklnd@uw.edu>
class ReactionComponent < Component
  attr_reader :sample, :item, :adj_qty

  # Instantiates the class
  #
  # @param input_name [String] the name of the component
  # @param qty [Numeric] the quantity of this component to be added to
  #   a single reaction
  # @param units [String] the units of `qty`
  # @param sample_name [String] the name of the Aquarium Sample to be
  #   used for this component
  # @param object_name [String] the ObjectType (Container) that this
  #   component should be found in
  def initialize(input_name:, qty:, units:,
                 sample_name: nil, object_type: nil,
                 location: 'unknown')
    super(input_name: input_name, qty: qty, units: units, location: location)
    @sample = sample_name ? Sample.find_by_name(sample_name) : nil
    @object_type = object_type ? get_object_type(object_type: object_type) : nil
    @description = @object_type
    @item = nil
    @added = false
  end


  # Sets the description to the object_type string
  def description
    if @object_type.is_a? String
      @object_type
    else
      @object_type.name.to_s
    end
  end

  # gets the location of the component
  def location
    @item&.location unless @item.nil?
    @location
  end

  # sets the location of the component item
  def location=(location)
    @item&.location = location
    @location = location
  end

  # Finds an item unless item is already specified
  # @return [Item]
  def find_random_item(object_type: nil)
    return @item if @item

    ot = @object_type || object_type
    raise 'Sample Id is nil' if @sample.nil?

    ot = get_object_type(object_type: ot)
    ite = Item.where(sample_id: @sample.id,
                     object_type: ot).first

    unless ite.present?
      raise "Item Not found sample: #{sample.id}, ot: #{ot.name}"
    end

    self.item = ite

    @item
  end

  # Makes an item unless the item is already created
  # @return [Item]
  def make_item(object_type: nil, lot_number: nil)
    return @item if @item

    ot = @object_type || object_type
    raise 'Sample ID is nil' if @sample.nil?

    ot = ObjectType.find_by_name(ot) if ot.is_a? String

    if ot.collection_type?
      col = Collection.new_collection(ot.name.to_s)
      samples = Array.new(col.get_empty.length, @sample)
      col.add_samples(samples)
      self.item = col
    else
      self.item = @sample.make_item(ot.name.to_s)
    end
    @item.associate(LOT_NUM, lot_number) if lot_number.present?
    @item
  end

  # Sets `item`
  #
  # @param item [Item]
  def item=(item)
    if item.collection?
      @item = item
    else
      if @sample
        unless @sample == item.sample
          raise ProtocolError, "Item / Sample mismatch, #{item.sample.name}, #{@sample.name}"
        end
      else
        @sample = item.sample
      end
      @item = item
    end
  end

  # Adjusts the qty by a given factor and, if needed, makes it checkable
  #   in a table
  #
  # @param mult [Float] the factor to multiply `qty` by
  # @param round [FixNum] the number of places to round the result to
  # @param checkable [Boolean] whether to make the result checkable
  #   in a table
  # @return [Numeric, Hash]
  def adjusted_qty(mult = 1.0, round = 1, checkable = true)
    @adj_qty = (qty * mult).round(round)
    return { content: adj_qty, check: true } if checkable

    @adj_qty
  end

  private

  # Finds the right object type depending on if given string or object type
  def get_object_type(object_type:)
    raise 'Object Type is Nil' if object_type.nil?

    return object_type if object_type.is_a? ObjectType

    ObjectType.find_by_name(object_type)
  end
end