# frozen_string_literal: true

needs 'ThermocyclerHelper/Thermocyclers'

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/UploadHelper'
needs 'Standard Libs/ItemActions'
needs 'Small Instruments/Centrifuges'
needs 'Standard Libs/Units'
needs 'Standard Libs/InstrumentHelper'

needs 'Collection Management/CollectionActions'

needs 'Tube Rack/TubeRack'
needs 'Tube Rack/TubeRackHelper'
needs 'Standard Libs/TextDisplayHelper'

# Protocol for loading samples into a qPCR thermocycler and running it
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo Decide whether this is actually qPCR specific
module RunThermocycler
  include ThermocyclerHelper
  include PlanParams
  include Debug
  include UploadHelper
  include Centrifuges
  include Units
  include ItemActions
  include InstrumentHelper
  include TubeRackHelper
  include TextDisplayHelper

  def run_qpcr(op:, plates:)

    temporary_options = op.temporary[:options]

    thermocycler = ThermocyclerFactory.build(
      model: temporary_options[:thermocycler_model],
      name: op.temporary[:thermocycler_model]
    )

    program = PCRProgramFactory.build(
      program_name: temporary_options[:program_name]
    )

    display(
      title: 'Run Thermocycler',
      show_block: [
        "Set up #{plates.length} <b>#{thermocycler.model}</b> thermocyclers",
        set_up_program(thermocycler: thermocycler,
                       program: program),
        load_plate_and_start_run(thermocycler: thermocycler,
                                 items: plates,
                                 expert: true)
      ]
    )

    {}
  end
end
