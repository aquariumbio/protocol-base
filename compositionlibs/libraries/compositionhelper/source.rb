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

  # def show_get_composition(composition:)
  #   show_retrieve_parts(composition.components + composition.consumables)
  # end

  # # =========== Component Methods =========#

  # def show_retrieve_components(components)
  #   existing_items = []
  #   non_existing_items = []
  #   components.each do |component|
  #     if component.item.nil?
  #       non_existing_items.append(component)
  #     else
  #       existing_items.append(component)
  #     end
  #   end
  #   retrieve_materials(existing_items.map(&:item))
  #   show_retrieve_parts(non_existing_items)
  # end

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
  # @param vessel [consumable] the vessel 
  def create_master_mix(components:, master_mix:, adj_qty: false, vortex: true)
    show_block = []
    show_block.append("Add the following volumes to master mix item: #{master_mix}")
    components.each do |comp|
      unless comp.item.present?
        raise CompositionHelperError, "Item #{comp.input_name} not present"
      end

      show_block.append(pipet(volume: comp.volume_hash(adj_qty: adj_qty),
                   source: comp.item,
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

  # Sets the "item" key of the components that relate to a specific kit
  # to the item of the kit.
  def set_kit_item(kit, composition)
    kit.components.each do |kit_comp|
      composition.input(kit_comp[:input_name]).item = kit.item
    end
  end

  # # =========== Kit Methods  ==============#
  # def show_retrieve_kits(kits, record_lot_number: true)
  #   return nil unless kits.present?
  #   show_retrieve_parts(kits)
  #   kits.each do |kit|
  #     show_record_lot_number(kit) if record_lot_number
  #     show_check_kit_components(kit)
  #   end
  # end

  # def show_check_kit_components(kit)
  #   kit_name = kit.input_name.to_s
  #   kit_name + ' ' + kit.lot_number unless kit.lot_number.nil?
  #   show do
  #     title 'Check Kit Contents'
  #     note "Please check the Contents of kit <b> #{kit_name}</b>"
  #     if kit.composition.components.present?
  #       note 'Components:'
  #       table location_table(kit.composition.components)
  #     end

  #     if kit.composition.consumables.present?
  #       note 'Consumables:'
  #       table location_table(kit.composition.consumables)
  #     end
  #   end
  # end

  # # Instructions to record lot number of kit
  # def show_record_lot_number(kit)
  #   kit_name = kit.input_name.to_s
  #   responses = show do
  #     title "Record <b>#{kit_name}</b> Lot Number"
  #     note "Please note <b>#{kit_name}</b> lot number below"
  #     get('number',
  #       var: "lot_number",
  #       label: "#{kit_name} Lot Number",
  #       default: 0)
  #     end
  #   kit.lot_number = if debug
  #                      rand(100)
  #                    else
  #                      kit.lot_number = responses.get_response('lot_number')
  #                    end
  # end

  # =========== Universal Method ========= #
  def location_table(objects, adj_qty: false)
    location_table = [%w(Name Description Location Quantity Note)]
    objects.each do |obj|
      name = obj.input_name.to_s
      name += "-#{obj.item}" if obj.respond_to? :item
      qty = obj.qty_display(adj_quantities: adj_qty)
      location_table.push([name, obj.description, obj.location, qty, obj.notes])
    end
    location_table
  end

  private

  def show_retrieve_parts(objects, adj_qty: false)
    return unless objects.present?
    show do
      title 'Retrieve Materials'
      note 'Please get the following materials'
      table location_table(objects, adj_qty: adj_qty)
    end
  end
end

class CompositionHelperError < ProtocolError; end