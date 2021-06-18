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
  def spin_down(items:, speed: nil, time: nil, type: nil)
    is_plate = items.any? { |item| item.collection? }
    centrifuge = get_centrifuge(speed: speed,
                                is_plate: is_plate,
                                type: type)

    show_spin_down(centrifuge, items: items, speed: speed, time: time)
  end

  # Gives directions to use centrifuge
  def show_spin_down(centrifuge, items:, speed: nil, time: nil)
    if speed.present? && speed[:qty] > centrifuge.class::MAX_X_G[:qty]
      raise OverSpeedError, "Speed (#{speed}) is too fast for #{centrifuge.class::NAME}"
    end
    show_array = []
    if centrifuge.class::ADJUSTABLE && speed.present?
      show_array.append("Set <b>#{centrifuge.class::NAME}</b> speed to #{qty_display(speed)}")
    else
      show_array.append("Go to <b>#{centrifuge.class::NAME}</b>")
    end
    show_array.append("Set time to #{qty_display(time)}") if time.present?
    show_array.append("Load the following item into a <b>#{centrifuge.class::NAME}</b>".pluralize(items.length))
    items.each do |item|
      show_array.append("- #{item}")
    end
    show_array.append('<b>Make sure Centrifuge is balanced</b>')
  end


  # Returns a centrifuge
  # 
  # @param speed [{qty: int, unit: string}] the volume per Standard Libs Units
  # @param type [String] the type of pipettor if a specific one is desired
  # @return [Pipet] A class of pipettor
  def get_centrifuge(speed: nil, type: nil, is_plate: false)
    speed = { qty: 1000.0, units: TIMES_G }
    qty = type.present? ? Float::INFINITY : speed[:qty]

    return Large.instance if is_plate && type.nil?

    if type == Small::NAME || qty <= Small::MAX_X_G[:qty]
      Small.instance
    elsif type == Medium::NAME || qty <= Medium::MAX_X_G[:qty]
      Medium.instance
    elsif type == Large::NAME || qty <= Large::MAX_X_G[:qty]
      Large.instance
    elsif type == Qiagenks::NAME || qty <= Qiagenks::MAX_X_G[:qty]
      Qiagenks.instance
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
    NAME = 'Small Centrifuge'.freeze
    MAX_X_G = {qty: 2000.0, units: TIMES_G}
    ADJUSTABLE = false
  end

  class Medium < Centrifuge
    NAME = 'Medium Centrifuge'.freeze
    MAX_X_G = {qty: 3114.0, units: TIMES_G}
    ADJUSTABLE = true
  end

  class Large < Centrifuge
    NAME = 'Large Centrifuge'.freeze
    MAX_X_G = {qty: 4816.0, units: TIMES_G}
    ADJUSTABLE = true
  end

  class Qiagenks < Centrifuge
    NAME = 'QIAGEN 4-16KS Centrifuge'.freeze
    MAX_X_G = {qty: 5788.0, units: TIMES_G}
    ADJUSTABLE = true
  end

  class OverSpeedError < ProtocolError; end
  class NoValidCentrifuge < ProtocolError; end

end
