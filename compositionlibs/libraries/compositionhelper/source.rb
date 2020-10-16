# frozen_string_literal: true

needs 'Standard Libs/ItemActions'
needs 'Standard Libs/Debug'
needs 'Small Instruments/Centrifuges'
needs 'Small Instruments/Shakers'

module CompositionHelper
  include ItemActions
  include Debug
  include Shakers
  include Centrifuges

  def show_get_composition(composition:)
    show_retrieve_components(composition.components)
    show_retrieve_consumables(composition.consumables)
    show_retrieve_kits(composition.kits)
  end

  # =========== Component Methods =========#

  def show_retrieve_components(components)
    existing_items = []
    non_existing_items = []
    components.each do |component| 
      if component.item.nil?
        non_existing_items.append(component)
      else
        existing_items.append(component)
      end
    end
    retrieve_materials(existing_items.map(&:item))
    show_retrieve_parts(non_existing_items)
  end

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
  def create_master_mix(components:, vessel:)
    show do
      title 'Create Master Mix'
      note "Add the following to a #{vessel.input_name}"
      components.each do |comp|
        note "#{comp.qty_display(adj_quantities: true)} - #{comp.item} #{comp.item.sample.name}"
      end
    end

    shake(items: [vessel.input_name], type: 'Vortex Mixer')
  end

  #========= Consumable Methods ===========#

  def show_retrieve_consumables(consumables)
    show_retrieve_parts(consumables)
  end

  # =========== Kit Methods  ==============#
  def show_retrieve_kits(kits, record_lot_number: true)
    show_retrieve_parts(kits)
    kits.each do |kit|
      show_record_lot_number(kit) if record_lot_number
      show_check_kit_components(kit)
    end
  end

  def show_check_kit_components(kit)
    kit_name = kit.input_name.to_s
    kit_name + ' ' + kit.lot_number unless kit.lot_number.nil?
    show do
      title 'Check Kit Contents'
      note "Please check the Contents of kit <b> #{kit_name}</b>"
      if kit.composition.components.present?
        note 'Components:'
        table location_table(kit.composition.components)
      end

      if kit.composition.consumables.present?
        note 'Consumables:'
        table location_table(kit.composition.consumables)
      end
    end
  end

  # Instructions to record lot number of kit
  def show_record_lot_number(kit)
    kit_name = kit.input_name.to_s
    responses = show do
      title "Record <b>#{kit_name}</b> Lot Number"
      note "Please note <b>#{kit_name}</b> lot number below"
      get('number',
        var: "lot_number",
        label: "#{kit_name} Lot Number",
        default: 0)
      end
    return rand(100) if debug
    kit.lot_number = responses.get_response('lot_number')
  end

  # =========== Universal Method ========= #
  def location_table(objects)
    location_table = [%w(Name Desctiption Location Quantity)]
    objects.each do |obj|
      location_table.push([obj.input_name, obj.description, obj.location, obj.qty_display])
    end
    location_table
  end

  private

  def show_retrieve_parts(objects)
    return unless objects.present?
    show do
      title 'Retrieve Materials'
      note 'Please get the following materials'
      table location_table(objects)
    end
  end
end