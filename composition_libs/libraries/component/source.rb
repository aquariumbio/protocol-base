# frozen_string_literal: true

needs 'Standard Libs/Units'

# Models a component of a biochemical reaction
# @author Devin Strickland <strcklnd@uw.edu>
class Component
  include Units

  attr_reader :input_name, :qty, :sample,
              :item, :suggested_ot, :notes
  attr_accessor :added, :adj_qty, :units

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
  def initialize(input_name:, qty:, units:, sample_name: nil, suggested_ot: nil, notes: nil)
    @input_name = input_name
    @qty = qty
    @units = units
    @sample = sample_name ? Sample.find_by_name(sample_name) : nil
    @item = nil
    @added = false
    @suggested_ot = suggested_ot
    @notes = notes
  end

  # Sets `item`
  #
  # @param item [Item]
  def item=(item)
    if sample
      raise ProtocolError, "Item / Sample mismatch, #{item.sample.name}, #{sample.name}" unless sample == item.sample
    else
      @sample = item.sample
    end
    @item = item
  end

  # The input name, formatted for display in protocols
  # @return [String]
  def display_name
    return input_name if @item.nil?

    "<b>#{input_name}-#{item}</b>"
  end

  # The volume as a qty, units hash
  #
  # @return [Hash]
  def volume_hash(adj_qty: false)
    if adj_qty && @adj_qty.nil?
      raise "comp_name: #{input_name} has nil 'adj_qty'"
    end

    { qty: adj_qty ? @adj_qty : @qty, units: units }
  end

  # Displays the volume (`qty`) with units
  #
  # @return [String]
  def qty_display(round = 1, adj_quantities: false)
    amount = adj_quantities ? adj_qty : qty

    if amount.nil?
      return 'Unknown'
    else
      amount = amount.round(round)
    end
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
  def adjusted_qty(mult = 1.0, round = 1, checkable = false)
    return if qty.nil?
    
    @adj_qty = (qty * mult).round(round)

    raise "Multiplier is nil for composition #{input_name}" if mult.nil?

    { content: adj_qty, check: true } if checkable
  end

  # provides the `qty` for display in a table, and markes it as `added`
  #
  # @param (see #adjusted_qty)
  # @return (see #adjusted_qty)
  def add_in_table(mult = 1.0, round = 1, checkable = true)
    @added = true
    adjusted_qty(mult, round, checkable)
  end

  # Checks if `self` has been added
  # @return [Boolean]
  def added?
    added
  end
end
