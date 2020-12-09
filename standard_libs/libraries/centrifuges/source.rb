needs "Standard Libs/Units"

module Centrifuges

  include Units

  # opts: [Hash] default {}, single channel pipettor
  # Creates string with directions on which pipet to use and what
  # to pipet to/from
  #
  # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param source: [String] the source to pipet from
  # @param destination: [String]the destination to pipet
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [String] directions
  def spin_down(items:, speed:, type: nil)
    is_plate = items.any?(&:collection?)
    centrifuge = get_centrifuge(speed: speed,
                                is_plate: is_plate,
                                type: type)

    show_spin_down(centrifuge, items: items, speed: speed)
  end

      # Gives directions to use centrifuge
  def show_spin_down(centrifuge, items:, speed:)
    if speed[:qty] > centrifuge.class::MAX_X_G
      raise OverSpeedError, 'Speed is too fast'
    end
    show do
      title 'Load Samples to Centrifuge'
      note "Load the following items into a\n
            <b>#{centrifuge.class::NAME} Centrifuge</b>"
      note "Set speed to #{qty_display(speed)}" if centrifuge.class::ADJUSTABLE
      items.each do |item|
        note item
      end
      warning '<b>Make sure Centrifuge is balanced</b>'
    end
  end


  # Returns a single channel pipet depending on the volume
  # 
  # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [Pipet] A class of pipettor
  def get_centrifuge(speed:, type: nil, is_plate: false)
    qty = type.present? ? Float::INFINITY : speed[:qty]

    return Large.instance if is_plate

    if type == Small::NAME || qty <= Small::MAX_X_G
      Small.instance
    elsif type == Medium::NAME || qty <= Medium::MAX_X_G
      Medium.instance
    elsif type == Large::NAME || qty <= Large::MAX_X_G
      Large.instance
    else
      raise NoValidCentrifuge, 'No centrifuges match requested parameters'
    end
  end

  # TODO add comment
  class Centrifuge
    include Singleton
    include Units
  end

  class Small < Centrifuge
    NAME = 'Small'.freeze
    MAX_X_G = 2000.0
    ADJUSTABLE = false
  end

  class Medium < Centrifuge
    NAME = 'Medium'.freeze
    MAX_X_G = 3,114.0
    ADJUSTABLE = true
  end

  class Large < Centrifuge
    NAME = 'Large'.freeze
    MAX_X_G = 4816.0
    ADJUSTABLE = true
  end

  class OverSpeedError < ProtocolError; end
  class NoValidCentrifuge < ProtocolError; end

end
