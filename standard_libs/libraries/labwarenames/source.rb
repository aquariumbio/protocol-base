needs 'Standard Libs/Units'

module LabwareNames
  include Units

  # Tubes
  TUBE_50_ML_CONICAL = "50 #{MILLILITERS} conical tube".freeze
  TUBE_15_ML_CONICAL = "15 #{MILLILITERS} conical tube".freeze
  TUBE_MICROFUGE = "1.5 #{MILLILITERS} microcentrifuge tube".freeze
  TUBE_MICROCENTRIFUGE = TUBE_MICROFUGE

  # Plates
  PCR_PLATE = "0.2 #{MILLILITERS} PCR plate".freeze
end
