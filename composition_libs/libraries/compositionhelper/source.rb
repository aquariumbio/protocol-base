# frozen_string_literal: true

needs 'Standard Libs/ItemActions'
needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/Debug'
needs 'Small Instruments/Centrifuges'
needs 'Small Instruments/Shakers'
needs 'Small Instruments/Pipettors'

module CompositionHelper
  include ItemActions
  include AssociationManagement
  include Debug
  include Shakers
  include Centrifuges

  # Creates the adjusted quantities for components
  #
  # @param components [Components],
  # @param multi [Integer/Double]
  # @param round [Integer] how much to round
  def adjust_volume(components:, multi:, round: 1)
    components.each do |comp|
      comp.adjusted_qty(multi, round)
    end
  end

  # Instructions to create master mixes based on the modified qty
  #
  # @param components [Array<Component>]
  def create_master_mix(components:, master_mix:, adj_qty: false, vortex: true)
    show_block = []
    show_block.append("Add the following volumes to master mix item: #{master_mix}")
    components.each do |comp|
      unless comp.item.present?
        raise CompositionHelperError, "Item #{comp.input_name} not present"
      end

      show_block.append(pipet(volume: comp.volume_hash(adj_qty: adj_qty),
                   source: comp,
                   destination: master_mix)
      )
    end
    show_block += shake(items: [master_mix], type: 'Vortex Mixer') if vortex
    components.each do |comp|
      item_to_item_vol_transfer(volume: comp.volume_hash(adj_qty: adj_qty),
                                key: 'volume_transfer',
                                to_item: comp.item,
                                from_item: master_mix.item)
    end
    show_block
  end

  # Sets the "item" of the components that relate to a specific kit
  # to the item of the kit.
  #
  # @param kit [KitContainer]
  # @param Composition [Composition]
  def set_kit_item(kit, composition)
    kit.components.each do |kit_comp|
      composition.input(kit_comp[:input_name]).item = kit.item
    end
  end

  # =========== Universal Method ========= #
  # Deprecated method
  def location_table(objects, adj_qty: false)
    create_location_table(items, volume_table: true, adj_qty: adj_qty)
  end

  #Deprecated Method
  def show_retrieve_parts(objects, adj_qty: false)
    display(
      title: 'Retrieve Materials',
      show_block: retrieve_materials(
        objects,
        volume_table: true,
        adj_qty: adj_qty
      )
    )
  end
end

class CompositionHelperError < ProtocolError; end