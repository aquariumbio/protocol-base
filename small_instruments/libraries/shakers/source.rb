needs "Standard Libs/Units"

module Shakers

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
  def shake(items:, speed: nil, time: nil, type: nil)
    shaker = get_shaker(speed: speed,
                        type: type)
    check_speed(speed: speed, shaker: shaker) if speed.present?

    if shaker.class::NAME == Vortex::NAME
      vortex(items)
    elsif shaker.class::NAME == Inversion::NAME
      invert_to_mix(items)
    else
      show_shake(shaker, items: items, speed: speed, time: time)
    end
  end

  # Checks that the speed isn't too great for shaker
  def check_speed(speed:, shaker:)
    return unless shaker.class::MAX_SPEED.present?

    return unless speed[:qty] > shaker.class::MAX_SPEED[:qty]

    raise OverSpeedError, 'Speed is too fast'
  end

  # Gives directions to use centrifuge
  #
  # @return show_array [Array<String>]
  def show_shake(shaker, items:, speed: nil, time: nil)
    show_array = []
    if shaker.class::ADJUSTABLE
      show_array.append("Set <b>#{shaker.class::NAME}</b> speed to #{qty_display(speed)}")
    else
      show_array.append("Go to <b>#{shaker.class::NAME}</b>")
    end
    show_array.append("Set time to #{qty_display(time)}") if time.present?
    show_array.append("Load the following item into a <b>#{shaker.class::NAME}</b>".pluralize(items.length))
    items.each do |item|
      show_array.append("- #{item}")
    end
    show_array
  end

  # Gives directions to use vortexer
  # 
  # @param items [Array<>] array of things that have a to_s (typically items)
  def vortex(items)
    show_arry = []
    show_arry.append('Please vortex the following Items')
    items.each do |obj|
      show_arry.append("  - #{obj}")
    end
    show_arry
  end

  # Gives directions to mix by inversion
  # 
  # @param items [Array<>] array of things that have a to_s (typically items)
  def invert_to_mix(items)
    show_arry = []
    show_arry.append('Please mix by inversion')
    items.each do |obj|
      show_arry.append("  - #{obj}")
    end
    show_arry
  end

  # Returns a Shaker
  # 
  # @param speed [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [Pipet] A class of pipettor
  def get_shaker(speed: nil, type: nil)
    if type == Inversion::NAME
      return Inversion.instance
    elsif type == Vortex::NAME || !speed.present?
      return Vortex.instance
    end

    qty = type.present? ? Float::INFINITY : speed[:qty]

    if type == BasicShaker::NAME || qty <= BasicShaker::MAX_SPEED[:qty]
      BasicShaker.instance
    # Leave space for more shakers to be added
    else
      raise NoValidShaker, 'No centrifuges match requested parameters'
    end
  end

  # TODO add comment
  class Shaker
    include Singleton
    include Units
  end

  class Vortex < Shaker
    NAME = 'Vortex Mixer'.freeze
    MAX_SPEED = nil
    ADJUSTABLE = true
  end

  class Inversion < Shaker
    NAME = 'Mix by inversion'.freeze
    MAX_SPEED = nil
    ADJUSTABLE = false
  end

  class BasicShaker < Shaker
    NAME = 'Shaker'.freeze
    MAX_SPEED = {qty: 4000, units: RPM}
    ADJUSTABLE = true
  end

  class OverSpeedError < ProtocolError; end
  class NoValidShaker < ProtocolError; end

end
