# frozen_string_literal: true

# Assists with basic actions of items (eg trashing, moving, etc)

needs 'Standard Libs/Units'
needs 'Standard Libs/TextDisplayHelper'

module ItemActions
  include Units
  include TextDisplayHelper

  # Directions to label objects with labels
  # Will display exactly labels and exactly objects
  #
  # @param objects [String able object]
  def label_items(objects:, labels:)
    show_block = []
    objects.zip(labels).each do |obj, label|
      show_block.append("Label <b>#{obj}</b> with: <b> #{label}</b>")
    end
    show_block
  end

  # Instructions on getting and labeling new plate
  #
  # @param plate [Collection] the plate to be retrieved and labeled
  def get_and_label_new_item(item)
    if item.is_a? Component
      ot = item.item.object_type.name
      label = item.display_name
    else
      ot = item.object_type.name
      label = item
    end
    "Get a <b>#{ot}</b> and label it ID: <b>#{label}</b>"
  end

  # Tell the experimenter to discard all items that have been marked as deleted.
  #
  # @param operations [Array<Operations>] operations from which to collect
  #   marked items
  # @return [void]
  def discard_deleted_inputs(operations:)
    input_items = operations.map { |op| op.inputs.map(&:item) }.flatten.compact
    deleted_items = input_items.select(&:deleted?)
    discard_items(items: deleted_items) if deleted_items.present?
  end

  # Tell the experimenter to discard a list of items
  #
  # @param items [Array<Item>] the list of items to discard
  # @return [void]
  def discard_items(items:)
    item_display = items.map { |i| [i.object_type.name, i.to_s] }.sort


    dis = [{ display: 'Dispose of all the following items', type: 'note' }]
    item_display.each do |name, id|
      dis.append({ display: "#{name} #{id}", type: 'bullet' })
    end
  end

  # Instructs tech to remove supernatant and discard
  #
  # @param item [Item]
  def remove_item_supernatant(items)
    return unless items.present?
    dis = [{ display: 'Remove and discard supernatant from:', type: 'note' }]
    items.each do |item|
      dis.append({ display: item.to_s, type: 'bullet' })
    end
    dis
  end

  # Instructs tech to check items for bubbles
  #
  # @param items [Array<item>]
  # @param responses [Array<[boolean, item]>]
  def show_inspect_for_bubbles(item)
    responses = show do
      title 'Check For Bubbles'
      note 'Check following item for bubbles'
      select(['true', 'false'],
              var: 'bubbles'.to_sym,
              label: item.to_s,
              default: 2)
    end
    response = responses['bubbles'.to_sym].to_s
    response = ['true', 'false'].sample if debug
    if response == 'true'
      true
    elsif response == 'false'
      false
    end
  end

    # instructions to thaw items
  #
  # @param items [Item, Collection, String]
  def show_thaw_items(items)
    dis = [{ display: 'Thaw the following items', type: 'note' }]
    items.each do |item|
      dis.append({ display: item.to_s, type: 'bullet' })
    end
  end

  # Instructions to incubate items
  #
  # @param
  def show_incubate_items(items:, time:, temperature:)
    dis = [{ display: 'Incubate the following items per instructions below', type: 'note' },
           { display: "Temperature: <b>#{qty_display(temperature)}</b>", type: 'note' },
           { display: "Time: <b>#{qty_display(time)}</b>", type: 'note' },
           { display: 'Items:', type: 'note' },]
    items.each do |item|
      dis.append({ display: item.to_s, type: 'bullet' })
    end
    dis
  end

  # Store all items used in input operations
  # Assumes all inputs are non nil
  #
  # @param operations [OperationList] the list of operations
  # @param location [String] the storage location
  # @param type [String] the type of items to be stored('item', 'collection')
  def store_inputs(operations, location: nil, type: nil)
    store_io(operations, role: 'input', location: location, type: type)
  end

  # Stores all items used in output operations
  # Assumes all outputs are non nil
  #
  # @param operations [OperationList] the operation list where all
  #     output collections should be stored
  # @param location [String] the storage location
  # @param type [String] the type of items to be stored ('item', 'collection')
  def store_outputs(operations, location: nil, type: nil)
    store_io(operations, role: 'output', location: location, type: type)
  end

  # Stores all items of a certain role in the operations list
  # Creates instructions to store items as well
  #
  # @param operations [OperationList] list of Operations
  # @param role [String] whether material to be stored is an input or an output
  # @param location [String] the location to store the material
  # @param all_items [Boolean] an option to store all items not just collections
  # @param type [String] the type of items to be stored ('item', 'collection')
  def store_io(operations, role: 'all', location: nil, type: nil)
    items = Set[]; role.downcase!; type.downcase!
    operations.each do |op|
      field_values = if role == 'input'
                       yield op.inputs
                     elsif role == 'output'
                       yield op.outputs
                     else
                       yield (op.outputs + op.inputs)
                     end

      unless type.nil?
        if type == 'collection'
          field_values.reject! { |fv| fv.object_type.handler == 'collection' }
        elsif type == 'item'
          field_values.select! { |fv| fv.object_type.handler == 'collection' }
        end
      end

      items.concat(field_values.map(&:item))
    end
    store_items(items, location: location)
  end

  # Instructions to store a specific item
  # TODO have them move the items first then move location in AQ
  #
  # @param items [Array<items>] the things to be stored
  # @param location [String] Sets the location of the items if included
  def store_items(items, location: nil)
    set_locations(items, location) unless location.nil?
    tab = create_location_table(items)
    show do
      title 'Put Away the Following Items'
      table tab
    end
  end

  # Sets the location of all objects in array to some given locations
  #
  # @param items Array[Collection] or Array[Items] an array of any objects
  # that extend class Item
  # @param location [String] the location to move object to
  # (String or Wizard if Wizard exists)
  def set_locations(items, location)
    items.each do |item|
      item = item.containing_collection if item.is_a? Part
      next unless item.is_a?(Item) || item.is_a?(Collection)
      item.move_to(location)
      item.save
    end
  end

  # Directions to retrieve materials
  #
  # @materials [Array<items>]
  def retrieve_materials(materials, volume_table: false, adj_qty: false)
    return nil unless materials.present?
    dis = [ { display: 'Please get the following items', type: 'note'  }]
    if adj_qty.present? || volume_table.present?
      dis.append({ display: volume_location_table(materials, adj_qty: adj_qty),
                   type: 'table'})
    else
      dis.append({ display: create_location_table(materials), type: 'table'})
    end
  end

  # Creates table directing technician on where to store materials
  #
  # @param item [Items, Consumables, Compositions] the materials that are to be put away
  # @return location_table [Array<Array>] of Collections and their locations
  def create_location_table(items)
    location_table = [%w(Name Description Location)]

    items.each do |obj|
      if obj.is_a? Item
        row = [Item.to_s, obj.object_type.name.to_s, obj.location]
        location_table.push(row)
      elsif obj.is_a?(Component) || obj.is_a?(Consumable)
        name = obj.input_name.to_s
        name += "-#{obj.item}" if obj.respond_to? :item
        description = obj.description || '-'
        location_table.push([name, description, obj.location])
      else
        location_table.push([obj.to_s, nil, nil])
      end
    end
    location_table
  end

  # Creates a location table including volumes
  # Uses the create_location_table to create initial table
  #
  # @param item [Items, Consumables, Compositions] the materials that are to be put away
  # @return location_table [Array<Array>] of Collections and their locations
  def volume_location_table(objects, adj_qty: false)
    location_table = create_location_table(objects)

    location_table.first.concat(['Quantity', 'Notes'])

    objects.each_with_index do |obj, idx|
      row = location_table[idx + 1]
      qty = obj.qty_display(adj_quantities: adj_qty)

      row.concat([qty, obj.notes || '-'])
    end
    location_table
  end

  # Gives directions to throw away objects (collection or item)
  #
  # @param items [Array<items>] Items to be trashed
  # @param hazardous [boolean] if hazardous then true
  def trash_object(items, waste_container: 'Biohazard Waste')
    set_locations(items, location: waste_container)
    tab = create_location_table(items)
    dis = [ { display: 'Properly Dispose of the following items:', type: 'note'  },
            { display: create_location_table(items), type: 'table'} ]
    items.each { |item| item.mark_as_deleted }
    dis
  end

  # Instructions to fill media reservoir
  #
  # @param media (item)
  # @param volume [Volume]
  def show_fill_reservoir(media, unit_volume, number_items)
    total_vol = { units: unit_volume[:units], qty: calculate_volume_extra(unit_volume, number_items) }
    [ { display:  'Fill Media Reservoir', type: 'note'},
      { display: 'Get a media reservoir', type: 'check' },
      { display: pipet(volume: total_vol,
                       source: "<b>#{media.id}</b>",
                       destination: '<b>Media Reservoir</b>'), type: 'check' } ]
  end

  # Extra_ratio 0.15 = 15% 
  def calculate_volume_extra(unit_volume, number_items, extra_ratio: 0.15)
    raw_vol = (unit_volume[:qty] * number_items)
    addition = raw_vol * extra_ratio
    (raw_vol + addition).ceil
  end


  # Finds an item unless item is already specified
  #
  # @param sample [Sample] the sample
  # @param object_type [ObjectType] object type
  # @return [Item]
  def find_random_item(sample:, object_type:)
    raise ItemActionError, 'Sample is nil' unless sample.present?

    raise ItemActionError, 'Object type is nil' unless object_type.present?

    ot = object_type.is_a?(ObjectType) ? object_type : ObjectType.find_by_name(object_type)

    unless ot.is_a? ObjectType
      raise ItemActionError, "Object Type is Nil #{object_type}"
    end

    ite = Item.where(sample_id: sample.id,
                     object_type: ot).sample

    return ite if ite.present?

    raise ItemActionError, "Item Not found sample: #{sample.id}, ot: #{ot.name}"
  end

  # Makes an Item or fills a collection with that samples
  #
  # @param sample [Sample]
  # @param object_type [ObjectType]
  # @param lot_number [String]
  # @param association_map [AssociationMap] same as in collection management
  # @return [Item]
  def make_item(sample:, object_type:, lot_number: nil, association_map: nil)
    raise ItemActionError, 'Sample ID is nil' if sample.nil?

    ot = ObjectType.find_by_name(object_type) if object_type.is_a? String
    if ot.nil?
      raise "Object Type for #{object_type} is nil"
    end
    item = nil
    if ot.handler == 'collection'
      item = Collection.new_collection(object_type)
      length = association_map.present? ? association_map.length : item.get_empty.length
      samples = Array.new(length, sample)
      zipped_map = if association_map.present?
                     samples.zip(association_map)
                   else
                     samples
                   end
      zipped_map.each do |samp, map|
        next if samp.nil?

        if map.nil?
          item.add_one(samp)
          next
        end
        item.set(map[:to_loc][0], map[:to_loc][1], samp)
      end
    else
      item = sample.make_item(ot.name.to_s)
    end
    item.associate(LOT_NUM, lot_number) if lot_number.present?
    item
  end

  def flick_to_remove_bubbles(objs)
    unless objs.is_a? Array
      objs = [objs]
    end

    dis = [ { display: 'Carefully flick to breakdown and remove bubbles', type: 'note' }]
    
    objs.each do |obj|
      dis.append({ display: obj.to_s, type: 'bullet' })
    end
  end

  ###### Deprecated ########
  def label_containers(container_name:, labels: nil, items: nil)
    label_items(container_name: nil, labels: labels||items)
  end
end

class ItemActionError < ProtocolError; end