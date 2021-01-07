# frozen_string_literal: true

# Library for handling thermocyclers, including qPCR thermocyclers
# @author Devin Strickland <strcklnd@uw.edu>

needs 'ThermocyclerHelper/ThermocyclerConstants'
needs 'ThermocyclerHelper/PCRProgram'

needs 'Thermocyclers/TestThermocycler'
needs 'Thermocyclers/BioRadCFX96'
needs 'Thermocyclers/MiniPCRMini16'

# Helper module for standard thermocycler procedures
#
# @author Devin Strickland <strcklnd@uw.edu>
# @author Eriberto Lopez <elopez3@uw.edu>
# @note methods originally deployed as `QPCR_ThermocyclerLib`
#   on UW BIOFAB production 10/05/18
module ThermocyclerHelper

  include ThermocyclerConstants

  # Steps for setting up a program in a thermocycler
  #
  # @param thermocycler [Thermocycler]
  # @param program [PCRProgram]
  # @param composition [PCRComposition]
  # @param qpcr [Boolean] whether to call setup methods specific to a
  #   qPCR experiment: `open_software`, `set_dye`, `select_layout_template`,...
  # @return [void]
  def set_up_program(thermocycler:, program:, qpcr: false)
    show_block = []
      if qpcr
        show_block.append(thermocycler.open_software)
      end

      show_block.append(thermocycler.select_program_template(program: program))

      if qpcr
        show_block.append(thermocycler.select_layout_template(program: program))
      end
    show_block
  end

  # Steps for loading physical tubes or plates into a thermocycler
  #
  # @param thermocycler [Thermocycler]
  # @param items [Item, Array<Item>]
  # @param filename [String] the filename to safe the experiment file
  # @return [void]
  def load_plate_and_start_run(thermocycler:, items: [],
                               experiment_filename: nil,
                               expert: false)
    show_block = []
    # Normalize the presentation of `items`
    items = [items] if items.respond_to?(:collection?)
    plate = items.all?{ |item| is_plate?(item) }

    show_block.append(thermocycler.open_lid) unless expert

    # TODO: Make this work for plates, stripwells, and individual tubes
    if plate
      items.each do |item|
        show_block.append(thermocycler.place_plate_in_instrument(plate: item))
      end
      show_block.append("<b>#{thermocycler.confirm_plate_orientation}</b>") unless expert
    else
      # TODO handle stripwells and other formats here (utilize TubeRack)
      show_block.append('Load the PCR tubes into the metal block')
    end

    show_block.append(thermocycler.close_lid) unless expert

    show_block.append(thermocycler.start_run)
    if experiment_filename.present?
      show_block.append(thermocycler.save_experiment_file(filename: experiment_filename))
    end
    show_block
  end

  # Plate mapping from Mark
  # Add the GC STS to experiment request to the experimental schedule.

  # Export the measurements, if a qPCR thermocycler
  #
  # @param thermocycler [Thermocycler]
  # @return [void]
  def export_measurements(thermocycler:)
    show_block = []
    show_block.append('Once the run has finished, export the measurements')
    show_block.append(thermocycler.export_measurements)
    show_block.append(thermocycler.export_measurements_image)
    show_block
  end

  # TODO: A method from Eriberto Lopez's code that I haven't implemented yet
  # def upload_measurments(experiment_name)
  #   upload_filename = experiment_name + " - Quantification Summary_0.csv" # Suffix of file will always be the same
  #   up_show, up_sym = upload_show(upload_path = EXPORT_FILEPATH, upload_filename)
  #   if debug
  #     upload = Upload.find(11278) # Dummy data set
  #   else
  #     upload = find_upload_from_show(up_show, up_sym)
  #   end
  #   return upload
  # end

  private

  # Test whether an item is a 96 well plate
  #
  # @param item [Item]
  # @return [Boolean]
  def is_plate?(item)
    if item.collection?
      item.capacity == 96 || item.capacity == 384
    else
      false
    end
  end
end

# Factory class for building thermocycler objects
#
# @author Devin Strickland <strcklnd@uw.edu>
class ThermocyclerFactory
  # Instantiates a new `Thermocycler`
  #
  # @param model [String] the `MODEL` of the thermocycler. Must match the
  #   constant `MODEL` in an exisiting thermocycler class.
  # @return [Thermocycler]
  def self.build(model:, name:)
    case model
    when TestThermocycler::MODEL
      TestThermocycler.new(name: name)
    when BioRadCFX96::MODEL
      BioRadCFX96.new(name: name)
    when MiniPCRMini16::MODEL
      MiniPCRMini16.new(name: name)
    else
      msg = "Unrecognized Thermocycler Model: #{model}"
      raise ThermocyclerInputError, msg
    end
  end
end

class ThermocyclerInputError < ProtocolError; end
