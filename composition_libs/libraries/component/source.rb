# frozen_string_literal: true

needs 'Standard Libs/Units'

# Models a component of a biochemical reaction
# @author Devin Strickland <strcklnd@uw.edu>
class Component
  include Units

  attr_reader :input_name, :qty, :sample,
              :item, :notes, :description, :suggested_ot
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
  def initialize(input_name:, qty:, units:, sample_name: nil, notes: nil, description: nil, suggested_ot: nil)
    @input_name = input_name
    @qty = qty
    @units = units
    @sample = sample_name ? Sample.find_by_name(sample_name) : nil
    @item = nil
    @added = false
    @notes = notes
    @description = description
    @suggested_ot = suggested_ot
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

  def location
    if @item.nil?
      raise "#{input_name} has nil item"
    end
    @item.location
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
  # @param extra [Double] the fraction extra of total needed (55% = 0.55)
  # @return [Numeric, Hash]
  def adjusted_qty(mult = 1.0, round = 1, extra: 0)
    return if qty.nil?

    raise "Multiplier is nil for composition #{input_name}" if mult.nil?
    tol_qty = qty * mult
    adj_qty = (tol_qty + extra * tol_qty).round(round)
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

  # To string method required since the composition names are super important in
  # protocols.   Debate if including a 'to_s' method is needed or not.
  # Uses the display_name method.
  def to_s
    display_name
  end
end
