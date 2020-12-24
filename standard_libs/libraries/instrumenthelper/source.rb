# frozen_string_literal: true

needs "Standard Libs/Units"

module InstrumentHelper
  INSTRUMENT_NAME = 'instrument_name'.freeze

  # Should check parameters and pair operations with parameters etc
  def pair_ops_with_instruments(operations:, instrument_key:)
    get_available_instruments(instrument_key)

    operations.each_with_index do |op, idx|
      raise 'instrument model is nil' if op.temporary[:options][:instrument_model].nil?
      # TODO FINISH THIS
      op.temporary[INSTRUMENT_NAME] = "Random Name #{idx}"
    end
    operations # should return only paired operations
  end

  def go_to_instrument(instrument_name:, instrument_location: nil)
    show do
      title 'Go to Instrument'
      note "Go to <b>#{instrument_name}</b>" 
      note "Located at #{instrument_location}</b>" if instrument_location
    end
  end

  # wait time should be typical units format
  def wait_for_instrument(instrument_name:, wait_time: nil)
    show do 
      title 'Wait for Instrument'
      note "Please wait for the <b>#{instrument_name}</b> to finish"
      note "Wait is approximately #{qty_display(wait_time)}" if wait_time
    end
  end

  def remove_unpaired_operations(ops)
    ops_to_remove = []
    return if ops.nil?
    ops.each do |op|
      op.error(:instrument_unavailable, 'No instruments were available')
      op.status = 'pending'
      op.save
      ops_to_remove.push(op)
    end
    error_op_warning(ops_to_remove) unless ops_to_remove.empty?
  end

  private

  def error_op_warning(op_to_remove)
    show do
      title 'Some Operations Have Erred'
      note 'The following operations were not paired with an instrument'
      op_to_remove.each do |op|
        note op.id.to_s
      end
    end
  end

  def get_available_instruments(instrument_key)
    instruments = find_instruments(instrument_key)
    available_key = 'available'
    response = show {
      title 'Check Available Instruments'
      note 'Please note which instruments are currently available'
      instruments.each { |thermo|
        select([ available_key, 'unavailable' ],
               var: thermo['name'],
               label: thermo['name'].to_s,
               default: 1)
      }
    }
    available_instro = []
    instruments.map do |thermo|
      next unless response[thermo['name'].to_sym].to_s == available_key || debug

      available_instro.push(thermo)
    end
    available_instro
  end

  def find_instruments(instrument_key)
    Parameter.where(key: instrument_key).map { |thr| JSON.parse(thr.value) }
  end
end
