# frozen_string_literal: true

needs 'ThermocyclerHelper/Thermocyclers'

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/UploadHelper'
needs 'Standard Libs/ItemActions'
needs 'Standard Libs/Centrifuges'
needs 'Standard Libs/Units'
needs 'Standard Libs/InstrumentHelper'

needs 'Collection Management/CollectionActions'

needs 'Tube Rack/TubeRack'
needs 'Tube Rack/TubeRackHelper'

# Protocol for loading samples into a qPCR thermocycler and running it
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo Decide whether this is actually qPCR specific
class Protocol
  include ThermocyclerHelper
  include PlanParams
  include Debug
  include UploadHelper
  include Centrifuges
  include Units
  include ItemActions
  include InstrumentHelper
  include TubeRackHelper

  PLATE = 'PCR Plate'

  ########## DEFAULT PARAMS ##########

  # Default parameters that are applied equally to all operations.
  #   Can be overridden by:
  #   * Associating a JSON-formatted list of key, value pairs to the `Plan`.
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_job_params
    {
    }
  end

  # Default parameters that are applied to individual operations.
  #   Can be overridden by:
  #   * Adding a JSON-formatted list of key, value pairs to an `Operation`
  #     input of type JSON and named `Options`.
  #
  def default_operation_params
    {
      instrument_model: TestThermocycler::MODEL,
      program_name: 'CDC_TaqPath_CG',
      qpcr: true
    }
  end

  ########## MAIN ##########

  def main
    @job_params = update_all_params(
      operations: operations,
      default_job_params: default_job_params,
      default_operation_params: default_operation_params
    )
    return {} if operations.errored.any?

    paired_ops = pair_ops_with_instruments(operations: operations,
                                           instrument_key: THERMOCYCLER_PARAM)

    remove_unpaired_operations(operations - paired_ops)

    return {} if paired_ops.empty?

    paired_ops.make

    plates = paired_ops.map { |op| op.input(PLATE).collection }

    retrieve_materials(plates)

    vortex_objs(plates)

    flick_to_remove_bubbles(plates)

    spin_down(items: plates, speed: create_qty(qty: 1200.0, units: 'xG'))

    paired_ops.each do |op|
      temporary_options = op.temporary[:options]

      thermocycler = ThermocyclerFactory.build(
        model: temporary_options[:instrument_model],
        name: op.temporary[INSTRUMENT_NAME]
      )

      program = PCRProgramFactory.build(
        program_name: temporary_options[:program_name]
      )

      op.temporary[:active_thermocycler] = thermocycler

      go_to_instrument(instrument_name: thermocycler.name)

      set_up_program(thermocycler: thermocycler,
                     program: program)

      load_plate_and_start_run(thermocycler: thermocycler,
                               items: [op.input(PLATE).collection])

    end

    wait_for_instrument(instrument_name: 'Thermocyclers')

    store_items(plates)

    {}
  end
end
