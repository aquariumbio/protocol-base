# frozen_string_literal: true

needs 'Standard Libs/Units'
needs 'Composition Libs/Component'

# Factory class for instantiating `Composition`
# @author Devin Strickland <strcklnd@uw.edu>
class CompositionFactory
  # Instantiates `Composition`
  #
  # @param component_data [Hash] a hash enumerating the components
  # @return [Composition]
  def self.build(component_data:)
    Composition.new(
      component_data: component_data
    )
  end
end

# Models the composition of a reaction
# @author Cannon Mallory <malloc3@ue.edu>
# @author Devin Strickland <strklnd@uw.edu>
#
class Composition
  attr_reader :components

  # Instantiates the class
  #
  def initialize(component_data:)
    @components = []
    add_components(component_data: component_data)
  end

  # Adds components to the component array
  #
  # @input component_data [Array<hash>]] per the standard # TODO link to example
  def add_components(component_data:)
    component_data&.each do |c|
      @components.append(Component.new(c))
    end
    check_duplicate_names
  end

  # Gets the components that have been added
  # @return [Array<ReactionComponent>]
  def added_components
    components.select(&:added?)
  end

  # Gets the components that have NOT been added
  # @return [Array<ConsumableComponents>]
  def not_added_components
    components.reject(&:added?)
  end

  # Gets the `Item`s from `ReactionComponent`s and returns them as an array
  # @return [Array<Item>]
  def items
    components.map(&:item)
  end

  # The total reaction volume
  # @param round [Fixnum] the number of decimal places to round to
  # @return [Float]
  def sum_components(round = 1)
    components.map(&:qty).reduce(:+).round(round)
  end

  alias volume sum_components

  # The total volume of all components that have been added
  # @param (see #sum_components)
  # @return (see #sum_components)
  def sum_added_components(round = 1)
    added_components.map(&:qty).reduce(:+).round(round)
  end

  # Retrieves components by input_name
  # Will check components first and if nil then
  #    No two things should
  #      share input name
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [Component]
  def input(input_name)
    components.find { |c| c.input_name == input_name }
  end

  # Displays the total reaction volume with units
  #
  # @todo Make this work better with units other than microliters
  # @return [String]
  def qty_display
    Units.qty_display({ qty: volume, units: MICROLITERS })
  end

  # returns a list of all component input_names
  #
  # @return [Array<String>]
  def component_input_names
    @components&.map(&:input_name)
  end

  def set_adj_qty(mult = 1.0, round = 1, extra: 0)
    components.each do |comp|
      comp.adjusted_qty(mult, round, extra: extra)
    end
  end

  alias all_input_names component_input_names

  private

  # checks if any names are duplicated
  # Duplicate input names can cause serious issue
  def check_duplicate_names
    names = all_input_names
    unless names.uniq.length == names.length
      repeated_names = names.detect{ |name| names.count(name) > 1 }
      raise DuplicateNamesError, "There are duplicate input names #{repeated_names}"
    end
  end

end

class DuplicateNamesError < ProtocolError; end
class UnknownCompositionError < ProtocolError; end