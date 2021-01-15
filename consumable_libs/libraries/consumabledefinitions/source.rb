# frozen_string_literal: true

needs 'Standard Libs/Units'

module ConsumableDefinitions

  include Units

  PLATE_96_WELL = '96 Well Plate'
  DEEP_PLATE_96_WELL = '96 Well Deepwell Plate 2 ml'
  QIAAMP_PLATE = 'QIAamp 96 Plate'
  PLATE_384_WELL = '384 Well Plate'
  AREA_SEAL = "Microseal 'B' adhesive seals"
  MICRO_TUBE = '1.7 ml Tube'
  SPARE_PLATE = '96 Well Plate'
  TEST_TUBE = '15 ml Reagent Tube'
  TUBE_500UL = '0.5 ml Tube'
  QBIT_TUBE = 'Qubit Assay Tube'
  TAPE_PAD = 'Tape Pad'

  TIP_BOX_100 = "100 #{MICROLITERS} Pipette Tip Box"

  TYPES = {
    plate: 'Plate', # A multi well plate (24, 96, 384)
    petri_dish: 'Petri Dish', # Sometimes known as a Plate as well
    bottle: 'Bottle', # A standard bottle
    reagent_bottle: 'Reagent Bottle', # A bottle that holds common reagents
    cover: 'Cover', # Aluminum Foil, Cling Wrap
    pipette_tips: 'Pipette Tips' # obvious
  }.freeze

  LOCATIONS = {
    location_1: 'That one spot over by the fridge'
  }

  # A 'consumable' is an item that is not part of a reaction but is required
  #   for the procedure to be performed.

  # A 'Type' is a grouping of consumables.  This needs to be expanded a little
  #    general like 'plates" or 'Pipette tips' or 'containers'

  CONSUMABLES = {
    PLATE_96_WELL => {
      name: PLATE_96_WELL,
      type: TYPES[:plate],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    DEEP_PLATE_96_WELL => {
      name: DEEP_PLATE_96_WELL,
      type: TYPES[:plate],
      location: LOCATIONS[:location_1],
      description: '96 Well Deepwell Plate 2 ml'
    },
    QIAAMP_PLATE => {
      name: QIAAMP_PLATE,
      type: TYPES[:plate],
      location: LOCATIONS[:location_1],
      description: QIAAMP_PLATE
    },
    PLATE_384_WELL => {
      name: PLATE_384_WELL,
      type: TYPES[:plate],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    AREA_SEAL => {
      name: AREA_SEAL,
      type: TYPES[:cover],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    TAPE_PAD => {
      name: TAPE_PAD,
      type: TYPES[:cover],
      location: LOCATIONS[:location_1],
      description: TAPE_PAD
    },
    MICRO_TUBE => {
      name: MICRO_TUBE,
      type: TYPES[:bottle],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    SPARE_PLATE => {
      name: SPARE_PLATE,
      type: TYPES[:bottle],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    TEST_TUBE => {
      name: TEST_TUBE,
      type: TYPES[:bottle],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    TUBE_500UL => {
      name: TUBE_500UL,
      type: TYPES[:bottle],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    QBIT_TUBE => {
      name: QBIT_TUBE,
      type: TYPES[:bottle],
      location: LOCATIONS[:location_1],
      description: 'Description'
    },
    TIP_BOX_100 => {
      name: TIP_BOX_100,
      type: TYPES[:pipette_tips],
      location: LOCATIONS[:location_1],
      description: TIP_BOX_100
    }
  }.freeze
 
end
