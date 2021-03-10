# frozen_string_literal: true

needs "Standard Libs/Units"

module Pipettors

  include Units

  # Creates string with directions on which pipet to use and what
  # to pipet to/from
  #
  # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param source: [String] the source to pipet from
  # @param destination: [String]the destination to pipet
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [String] directions
  def pipet(volume:, source:, destination:, type: nil)
    pipettor = get_single_channel_pipettor(volume: volume,
                                           type: type)
    pipettor.pipet(
      volume: volume,
      source: source,
      destination: destination
    )
  end

  # Creates string with directions on which multi channel pipet to use and what
  # to pipet to/from
  #
  # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param source: [String] the source to pipet from
  # @param destination: [String]the destination to pipet
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [String] directions
  def multichannel_pipet(volume:, source:, destination:, type: nil)
    pipettor = get_multi_channel_pipettor(volume: volume, type: type)
    pipettor.pipet(
      volume: volume,
      source: source,
      destination: destination,
    )
  end

  # Returns a single channel pipet depending on the volume
  #
  # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [Pipet] A class of pipettor
  def get_single_channel_pipettor(volume:, type: nil)
    qty = type.present? ? Float::INFINITY : volume[:qty]

    if type == P2::NAME || qty <= 2
      P2.instance
    elsif type == P20::NAME || qty <= 20
      P20.instance
    elsif type == P200::NAME || qty <= 200
      P200.instance
    elsif type == P1000::NAME || qty <= 1000
      P1000.instance
    elsif qty <= 2000
      P1000.instance
    elsif type == PipetController::NAME || qty > 2000
      PipetController.instance
    end
  end

  # Returns a multi channel pipet depending on the volume
  # TODO Make it smart to decide if 12 Channel or 8 CHannel is needed
  #
  # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [Pipet] A class of pipettor
  def get_multi_channel_pipettor(volume:, type: nil)
    qty = type.present? ? Float::INFINITY : volume[:qty]
    if type == PA12X300::NAME || qty <= 300
      PA12X300.instance
    # if type == P8X20::NAME || qty <= 20
    #   P8X20.instance
    # elsif type == P8X200::NAME || qty <= 200
    #   P8X200.instance
    elsif type == PA6X1200::NAME || qty <= 1000
      PA6X1200.instance
    end
  end

  # TODO add comment
  class Pipettor
    include Singleton
    include Units

    # Gives directions to use pipet
    #
    # @param volume [{qty: int, unit: string}] the volume per Standard Libs Units
    # @param source: [String] the source to pipet from
    # @param destination: [String]the destination to pipet
    # @return [String] directions
    def pipet(volume:, source:, destination:)
      max_volume = self.class::MAX_VOLUME
      if volume[:qty] <= max_volume
        volume[:qty] = volume[:qty].round(self.class::ROUND_TO)
        "Use a <b>#{self.class::NAME}</b> to pipet <b>#{qty_display(volume)}</b>"\
          " from <b>#{source}</b> into <b>#{destination}</b>"
      else
        sub_volume = {qty: nil, units: volume[:units]}
        times = (volume[:qty].to_f/max_volume).ceil.to_f
        sub_volume[:qty] = (volume[:qty] / times).round(self.class::ROUND_TO)
        "Use a <b>#{self.class::NAME}</b> #{times.round} times"\
          " to pipet <b>#{qty_display(volume)}</b> from <b>#{source}</b>"\
          " into <b>#{destination}</b>"
      end
    end

    # Returns the number of channels a pipettor has
    #
    # @return Int
    def channels
      self.class::CHANNELS
    end
  end

  class PA12X300 < Pipettor
    NAME = '12 Channel P300'.freeze
    MIN_VOLUME = 30
    MAX_VOLUME = 300
    ROUND_TO = 0
    CHANNELS = 12
  end

  class PA6X1200 < Pipettor
    NAME = '6 Channel Adjustable Space P1200'.freeze
    MIN_VOLUME = 200.0
    MAX_VOLUME = 1000.0
    ROUND_TO = 0
    CHANNELS = 6
  end
  
  class P8X20 < Pipettor
    NAME = '8 Channel P20'.freeze
    MIN_VOLUME = 2.0
    MAX_VOLUME = 20.0
    ROUND_TO = 0
    CHANNELS = 8
  end

  class P8X200 < Pipettor
    NAME = '8 Channel P200'.freeze
    MIN_VOLUME = 20.0
    MAX_VOLUME = 200.0
    ROUND_TO = 0
    CHANNELS = 8
  end

  class P2 < Pipettor
    NAME = 'P2'.freeze
    MIN_VOLUME = 0.0
    MAX_VOLUME = 2.0
    ROUND_TO = 1
    CHANNELS = 1
  end

  class P20 < Pipettor
    NAME = 'P20'.freeze
    MIN_VOLUME = 2.0
    MAX_VOLUME = 20.0
    ROUND_TO = 1
    CHANNELS = 1
  end

  class P200 < Pipettor
    NAME = 'P200'.freeze
    MIN_VOLUME = 20.0
    MAX_VOLUME = 200.0
    ROUND_TO = 0
    CHANNELS = 1
  end

  class P1000 < Pipettor
    NAME = 'P1000'.freeze
    MIN_VOLUME = 200.0
    MAX_VOLUME = 1000.0
    ROUND_TO = 0
    CHANNELS = 1
  end

  class PipetController < Pipettor
    NAME = 'Pipet controller'.freeze
    MIN_VOLUME = 2000.0
    MAX_VOLUME = 50000.0
    ROUND_TO = 0
    CHANNELS = 1
  end

end
