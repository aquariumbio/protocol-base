# frozen_string_literal: true

needs 'Standard Libs/Units'
needs 'Standard Libs/CommonInputOutputNames'

needs 'CompositionLibs/ReactionComponent'

# module AbstractCompositionDefinitions
#   include Units
#   include CommonInputOutputNames

#   ABSTRACT_COMPONENT = {
#     input_name: ABSTRACT_NAME,
#     qty: 5, units: MICROLITERS,
#     sample_name: 'Optional Sample Name'
#   }
# end


# Factory class for instantiating
# @author Cannon Mallory <malloc3@uw.edu>
# @author Devin Strickland <strklnd@uw.edu>

class CompositionFactory

  # Instantiates 'Composition' class
  #
  def self.build(components: nil,
                 consumables: nil,
                 kits: nil,
                 composition_class: AbstractComposition::NAME)

    if composition_class == AbstractComposition::NAME && !kits.nil?
      composition_class = AbstractKitComposition::NAME
    end

    case composition_class
    when AbstractComposition::NAME
      AbstractComposition.new(component_data: components,
                              consumable_data: consumables)
    when AbstractKitComposition::NAME
      AbstractKitComposition.new(component_data: components,
                                 consumable_data: consumables,
                                 kit_data: kits)
    else
      msg = "Unknown composition class #{composition_class}"
      raise UnknownCompositionError, msg
    end
  end
end

# Models the composition of a reaction
# @author Cannon Mallory <malloc3@ue.edu>
# @author Devin Strickland <strklnd@uw.edu>
#
# @note As much as possible, Protocols using this class should draw
#  input names from 'CommonInputOutputNames'
class AbstractComposition

  attr_reader :components, :consumables, :kits

  NAME = 'AbstractComposition'.freeze

  # Instantiates the class
  #
  def initialize(component_data: nil, consumable_data: nil)
    @components = []
    @consumables = []
    add_components(component_data: component_data)
    add_consumable(consumable_data: consumable_data)
  end

  # ========= Components =========#

  # Adds components to the component array
  #
  # @input component_data [Array<hash>]] per the standard # TODO link to example
  def add_components(component_data:)
    component_data&.each { |c| @components.append(ReactionComponent.new(c)) }
    check_duplicate_names
  end

  # Find random items for all components that haven't been assigned an item
  def find_component_items
    @components.each(&:find_random_item)
  end

  # Makes items for all components that haven't been assigned an item
  def make_component_items
    @components.each(&:make_item)
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
  def component_items
    components.map(&:item)
  end

  # The total reaction volume
  # @note Rounds to one decimal place
  # @return [Float]
  def volume
    sum_components
  end

  # The total reaction volume
  # @param round [Fixnum] the number of decimal places to round to
  # @return [Float]
  def sum_components(round = 1)
    components.map(&:qty).reduce(:+).round(round)
  end

  # The total volume of all components that have been added
  # @param (see #sum_components)
  # @return (see #sum_components)
  def sum_added_components(round = 1)
    added_components.map(&:qty).reduce(:+).round(round)
  end

  # ============= Consumable Methods ============#

  # Adds consumable to the consumable array
  #
  # @input component_data [Array<hash>]] per the standard # TODO link to example
  def add_consumable(consumable_data:)
    consumable_data&.each { |c| @consumables.append(ConsumableComponent.new(c)) }
    check_duplicate_names
  end

  #======== Universal/Common Methods ========#

  # Retrieves components by input_name
  # Will check components first and if nil then
  #   checks in consumables.   No two things should
  #   share input name
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [Component]
  def input(input_name)
    component = component_input(input_name)
    consumable = consumable_input(input_name)
    return component || consumable
  end

  # Displays the total reaction volume with units
  #
  # @todo Make this work better with units other than microliters
  # @return [String]
  def qty_display
    Units.qty_display({ qty: volume, units: MICROLITERS })
  end

  # Returns all input names
  #
  # @return [Array<String>]
  def all_input_names
    names = self.component_input_names
    names.append(self.consumable_input_names)
  end

  # returns a list of all component input_names
  #
  # @return [Array<String>]
  def component_input_names
    names = []
    @components&.each { |c| names.append(c.input_name) }
    names
  end

  # returns a list of all consumable input_names
  #
  # @return [Array<String>]
  def consumable_input_names
    names = []
    @consumables&.each { |c| names.append(c.input_name) }
    names
  end

  private

  # checks if any names are duplicated
  # Duplicate input names can cause serious issue
  def check_duplicate_names
    names = self.all_input_names
    unless names.uniq.length == names.length
      raise DuplicateNamesError, 'There are duplicate input names'
    end
  end

    # Retrieves consumables by input_name
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [ConsumableComponent]
  def consumable_input(input_name)
    consumables.find { |c| c.input_name == input_name }
  end

  # Retrieves components by input name
  # Generally the named methods should be used.
  # However, this method can be convenient in loops, especially when
  #   the Protocol draws input names from `CommonInputOutputNames`
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [ReactionComponent]
  def component_input(input_name)
    components.find { |c| c.input_name == input_name }
  end

end

class AbstractKitComposition < AbstractComposition
  attr_reader :kits
  NAME = 'AbstractKit'.freeze

  def initialize(component_data: nil, consumable_data: nil, kit_data: nil)
    @kits = []
    add_kit(kit_data: kit_data)
    super(component_data: component_data, consumable_data: consumable_data)
  end

  # Find random items for all components that haven't been assigned an item
  def find_kit_component_items
    @kits.each { |kit| kit.components.each(&:find_random_item) }
  end

  # Makes items for all components that haven't been assigned an item
  def make_kit_component_items
    @kits.each do |kit| 
      kit.components.each do |c| 
        c.make_item(lot_number: kit.lot_number)
      end
    end
  end

  # Adds kit to the composition
  #
  # @param kit_data [Array<Hash>] follow standard TODO Add example
  def add_kit(kit_data:)
    kit_data&.each { |c| @kits.append(KitComponent.new(c)) }
    check_duplicate_names
  end

  # Retrieves components by input_name
  # Will check components first and if nil then
  #   checks in consumables.   No two things should
  #   share input name
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [Component]
  def input(input_name)
    sup = super(input_name)
    kits = kit_input(input_name)
    return sup || kits
  end

  # Returns all input names
  #
  # @return [Array<String>]
  def all_input_names
    super.append(self.kit_input_names)
  end

  # returns a list of all kit input_names
  #
  # @return [Array<String>]
  def kit_input_names
    names = []
    @kits&.each { |c| names.append(c.input_name) }
    names
  end

  private

  # Retrieves kit by input_name
  #
  # @param input_name [String] the name of the component to be retrieved
  # @return [KitComponent]
  def kit_input(input_name)
    kits.find { |c| c.input_name == input_name }
  end

end

class DuplicateNamesError < ProtocolError; end
class UnknownCompositionError < ProtocolError; end