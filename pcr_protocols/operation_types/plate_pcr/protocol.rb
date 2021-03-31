# typed: false
# frozen_string_literal: true

needs 'Standard Libs/PlanParams'
needs 'Standard Libs/Debug'
needs 'Standard Libs/InstrumentHelper'
needs 'Standard Libs/ItemActions'
needs 'Standard Libs/UploadHelper'
needs 'Small Instruments/Centrifuges'
needs 'Small Instruments/Shakers'
needs 'Standard Libs/Units'
needs 'Covid Surveillance/SampleConstants'
needs 'Covid Surveillance/AssociationKeys'
needs 'Liquid Robot Helper/RobotHelper'

needs 'CompositionLibs/AbstractComposition'
needs 'CompositionLibs/CompositionHelper'

needs 'Collection Management/CollectionTransfer'
needs 'Collection Management/CollectionActions'

needs 'ThermocyclerHelper/Thermocyclers'

needs 'Program Libs/Program'

# Protocol for loading samples into a qPCR thermocycler and running it
#
# @author Devin Strickland <strcklnd@uw.edu>
# @todo Decide whether this is actually qPCR specific
class Protocol
  include PlanParams
  include Debug
  include InstrumentHelper
  include ItemActions
  include UploadHelper
  include Centrifuges
  include Shakers
  include Units
  include SampleConstants
  include AssociationKeys
  include RobotHelper
  include CompositionHelper
  include CollectionTransfer
  include CollectionActions
  include ThermocyclerHelper
  

  SAMPlE_PLATE = 'Sample Plate'

  PRIMER_1 = 'Primer 1'
  PRIMER_2 = 'Primer 2'
  WATER = 'Nuclease-free water'
  MASTER_MIX = 'Master Mix'

  PRIMER_PROBE = 'Primer Probe Mix'
  DYE = 'Dye'
  PROBE = 'Probe'
  PCR_PLATE = 'PCR Plate'

  AREA_SEAL = 'Adhesive Plate Seal'

  def get_components
    [
      {
         input_name: SAMPlE_PLATE,
         qty: 5, units: MICROLITERS,
         sample_name: nil,
         object_type: '96-Well Plate'
       },
       {
        input_name: PRIMER_1,
        qty: 1.5, units: MICROLITERS,
        sample_name: PRIMER_1,
        object_type: 'Reagent Bottle'
       },
       {
        input_name: PRIMER_2,
        qty: 1.5, units: MICROLITERS,
        sample_name: PRIMER_2,
        object_type: 'Reagent Bottle'
       },
       {
        input_name: PROBE,
        qty: 1, units: MICROLITERS,
        sample_name: PROBE,
        object_type: 'Reagent Bottle'
       },
       {
        input_name: WATER,
        qty: 1, units: MICROLITERS,
        sample_name: WATER,
        object_type: 'Reagent Bottle'
       },
       {
        input_name: MASTER_MIX,
        qty: 10, units: MICROLITERS,
        sample_name: MASTER_MIX,
        object_type: 'Reagent Bottle'
       }
    ]
  end

  def get_consumables
    [ 
      {
        input_name: AREA_SEAL,
        qty: 1, units: 'Each',
        description: 'Adhesive Plate Seal'
      },
      {
        input_name: '96-well qPCR Plate',
        qty: 1, units: 'Each',
        description: '96-Well Plate'
      }
    ]
  end

  def get_kits
    [
    ]
  end

  def get_program
    {
      program_name: 'Example qPCR',
      steps:[
        { action: 'add', item: MASTER_MIX, to_item: PCR_PLATE },
        { action: 'add', item: PRIMER_1, to_item: PCR_PLATE },
        { action: 'add', item: PRIMER_2, to_item: PCR_PLATE },
        { action: 'add', item: WATER, to_item: PCR_PLATE },
        { action: 'add', item: PROBE, to_item: PCR_PLATE },
        { action: 'add', item: SAMPlE_PLATE, to_item: PCR_PLATE},
        { action: 'seal', item: PCR_PLATE },
       # { action: 'vortex', item: PCR_PLATE },
        { action: 'centrifuge', item: PCR_PLATE },
        {
          action: 'thermocycler',
          item: PCR_PLATE,
          program: {
            program_template_name: 'Example_qPCR',
            layout_template_name: 'NGS_qPCR1',
            volume: 20,
            steps: {
              step1: {
                temperature: { qty: 95, units: DEGREES_C },
                duration: { qty: 3, units: MINUTES }
              },
              step2: {
                temperature: { qty: 98, units: DEGREES_C },
                duration: { qty: 15, units: SECONDS }
              },
              step3: {
                temperature: { qty: 62, units: DEGREES_C },
                duration: { qty: 30, units: SECONDS }
              },
              step4: {
                temperature: { qty: 72, units: DEGREES_C },
                duration: { qty: 30, units: SECONDS }
              },
              step5: { goto: 2, times: 34 },
              step6: {
                temperature: { qty: 12, units: DEGREES_C },
                duration: { qty: 'forever', units: '' }
              }
            }
          }
        }
      ]
    }
  end

  ########## DEFAULT PARAMS ##########

  def constant_composition
    [
      {
        input_name: PCR_PLATE,
        qty: nil, units: MICROLITERS,
        sample_name: nil,
        object_type: '96-well qPCR Plate'
      }
    ]
  end

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

    paired_ops = pair_ops_with_instruments(operations: operations,
                                           instrument_key: THERMOCYCLER_PARAM)

    remove_unpaired_operations(operations - paired_ops)

    return {} if paired_ops.empty?

    paired_ops.make

    paired_ops.each do |op|
      set_up_test(op) if debug
      components = get_components
      consumables = get_consumables
      kits = get_kits

      composition = CompositionFactory.build(components: components + constant_composition,
                                             consumables: consumables,
                                             kits: kits)
      program = ProgramFactory.build(program: get_program)

      composition.input(SAMPlE_PLATE).item = op.input(SAMPlE_PLATE).collection
      composition.input(PCR_PLATE).item = op.output(PCR_PLATE).collection

      sample_plate = composition.input(SAMPlE_PLATE).item
      pcr_plate = composition.input(PCR_PLATE).item

      composition.find_component_items

      copy_wells(from_collection: sample_plate,
                 to_collection: pcr_plate,
                 association_map: one_to_one_association_map(from_collection: sample_plate))

      temporary_options = op.temporary[:options]

      show_get_composition(composition: composition)
      retrieve_materials([sample_plate, pcr_plate])

      vortex_objs(composition.components.map(&:item))

      transfer_map = one_to_one_association_map(from_collection: sample_plate)

      program.steps.each do |step|
        next if step.completed?

        component = composition.input(step.item)

        if step.action == 'add'
          add(component: component, 
              to_component: composition.input(step.to_item),
              map: transfer_map)
        elsif step.action == 'vortex'
          vortex_objs([component.item])
        elsif step.action == 'seal'
          seal_plate(component.item, seal: composition.input(AREA_SEAL).input_name)
        elsif step.action == 'centrifuge'
          spin_down(items: [component.item], speed: {qty: 1200, units: 'x g'})
        elsif step.action == 'thermocycler'
          run_thermocycler(
            item: component.item, program: step.program,
            instrument_model: temporary_options[:instrument_model],
            instrument_name: op.temporary[INSTRUMENT_NAME]
          )
        else
          raise "invalid action #{step.action}"
        end
        step.complete
      end

      store_items([pcr_plate, sample_plate], location: 'trash')
    end
  end

  def add(component:, to_component:, map:)
    if component.item.collection?
      multichannel_collection_to_collection(
        to_collection: component.item,
        from_collection: to_component.item,
        volume: component.volume_hash,
        association_map: map,
        verbose: true
      )
    else
      multichannel_item_to_collection(
        to_collection: to_component.item,
        source: component.item,
        volume: component.volume_hash,
        association_map: map,
        verbose: true
      )
    end
  end

  def run_thermocycler(item:, program:, instrument_model:, instrument_name:)
    thermocycler = ThermocyclerFactory.build(
      model: instrument_model,
      name: instrument_name
    )

    pcr_program = PCRProgramFactory.build(program: program)

    go_to_instrument(instrument_name: thermocycler.name)

    set_up_program(thermocycler: thermocycler,
                   program: pcr_program)

    load_plate_and_start_run(thermocycler: thermocycler,
                             items: [item])
    wait_for_instrument(instrument_name: thermocycler.name)

    go_to_instrument(instrument_name: thermocycler.name)

    export_measurements(thermocycler: thermocycler)

    # TODO associate DATA
  end

  def set_up_test(op)
    sample = op.input(SAMPlE_PLATE).part.sample
    plate = op.input(SAMPlE_PLATE).collection
    samples = Array.new(plate.get_empty.length, sample)
    plate.add_samples(samples)
  end

end
