# frozen_string_literal: true

needs 'Standard Libs/Units'

# Consumables Factory

class ConsumablesFactory
  def self.build(consumable_data:)
    Consumables.new(consumable_data: consumable_data)
  end
end

# Consumables class

class Consumables

  attr_reader :consumables

  def initialize(consumable_data: nil)
    @consumables = []
    add_consumables(consumable_data: consumable_data)
  end

  def add_consumables(consumable_data:)
    consumable_data.each do |con|
      existing_input = find_input(con[:consumable][:name])

      if existing_input.present?
        existing_input.add(qty: qty, units: units)
      else
        @consumables.append(Consumable.new(con))
      end
    end
  end

  # Retrieves components by input_name for array of strings or single string
  #
  # @param input_name [String] or [Array<String>]
  # @return [Component] or [Array<Component>]
  def input(input_name)
    if input_name.is_a? Array
      input_name.map{ |iname| find_input(iname) }
    else
      find_input(input_name)
    end
  end

  private

  # Retrieves components by input_name for a single string
  #
  # @param input_name [String] or [Array<String>]
  # @return [Component] or [Array<Component>]
  def find_input(input_name)
    consumables.find { |c| c.input_name == input_name }
  end
end

# Modules a component needed for a biochemical reaction
#
# Super class over both 'reagents'
class Consumable
  include Units

  attr_reader :input_name, :qty, :units, :notes
  attr_accessor :location,
                :description,
                :adj_qty

  def initialize(consumable:, qty:, units:, notes: nil)
    @input_name = consumable[:name]
    @qty = qty
    @units = units
    @location = consumable[:location]
    @description = consumable[:description]
    @type = consumable[:type]
    @adj_qty = qty
    @notes = notes
  end

  # To string method
  #
  # @return [String]
  def to_s
    input_name.to_s
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

  def add(qty:, units:)
    raise 'units dont match' unless units == @units
    @qty += qty
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
    return if qty.nil?

    raise "Multiplier is nil for composition #{input_name}" if mult.nil?

    @adj_qty = (qty * mult).round(round)
  end
end