# frozen_string_literal: true

needs 'Standard Libs/Units'

# Modules a component needed for a biochemical reaction
#
# Super class over both 'reagents' and 'consumables'
class Component
  include Units

  attr_reader :input_name, :qty, :units
  attr_accessor :added, :location, :description, :lot_number, :adj_qty

  LOT_NUM = 'Lot_Number'

  def initialize(input_name:, qty:, units:, location: 'unknown', description: nil)
    @input_name = input_name
    @qty = qty
    @units = units
    @added = false
    @location = location
    @description = description
    @adj_qty = qty
    @lot_number = nil
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
  # @param adj_qty [Boolean] true if show adjusted quantity
  # @return [Hash]
  def volume_hash(adj_qty: false)
    { qty: adj_qty ? @adj_qty : @qty, units: units }
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
    amount = amount.round(round) unless amount.nil?
    Units.qty_display({ qty: amount, units: units })
  end

  # Adjusts the qty by a given factor and, if needed, makes it checkable
  #   in a table
  #
  # @param mult [Float] the factor to multiply `qty` by
  # @param round [FixNum] the number of places to round the result to
  # @param checkable [Boolean] whether to make the result checkable
  #   in a table
  # @return [Numeric, Hash]
  def adjusted_qty(mult = 1.0, round = 1)
    @adj_qty = (qty * mult).round(round)
  end
end

# Models a kit of parts in a biochemical reaction
#
# @author Cannon Mallory <malloc3@uw.edu>
class KitComponent < Component

  attr_reader :composition

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
    set_default_part_location(components)
    set_default_part_location(consumables)
    @composition = CompositionFactory.build(components: components,
                                            consumables: consumables)
    @lot_number = lot_number
    set_lot_numbers
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

  # Sets all components lot numbers to the kit lot number
  #
  def set_lot_numbers
    @composition.components.each do |comp|
      comp.lot_number = @lot_number
    end
  end

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
  attr_reader :sample, :item, :adj_qty, :object_type

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
    @object_type = object_type ? ObjectType.find_by_name(object_type) : nil
    @description = @object_type
    @item = nil
    @added = false
  end

  # Sets the description to the object_type string
  def description
    raise ReactionComponentError, "object_type for #{@input_name} is nil" unless @object_type.present?
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

  # Sets `item`
  #
  # @param item [Item]
  def item=(item)
    if item.collection?
      @item = item
    else
      if @sample
        unless @sample == item.sample
          raise ReactionComponentError, "Item / Sample mismatch, #{item.sample.name}, #{@sample.name}"
        end
      else
        @sample = item.sample
      end
      @item = item
    end
  end

end

class ReactionComponentError < ProtocolError; end
