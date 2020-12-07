# frozen_string_literal: true

module LayoutMethods
  def row_wise
    lyt = []
    8.times { |r| 12.times { |c| lyt << [r, c] } }
    lyt
  end

  def cdc_sample_layout
    lyt = []
    [0, 4].each do |j|
      cols = Array.new(12) { |c| c }
      cols.each { |c| @group_size.times { |i| lyt << [i + j, c] } }
    end
    lyt
  end

  # @todo make this responsive to @group_size
  def cdc_primer_layout
    lyt = []
    3.times { |i| [0, 4].each { |j| 12.times { |k| lyt << [i + j, k] } } }
    lyt
  end

  #==================Modified CDC Methods ====================#

  def modified_sample_layout
    lyt = []
    make_modified_start_array(@group_size).each do |j|
      cols = Array.new(@columns) { |c| c }
      cols.each { |c| @group_size.times { |i| lyt << [i + j, c] } }
    end
    lyt
  end

  def modified_primer_layout
    lyt = []
    make_modified_start_array(1).each do |j|
      @columns.times { |k| lyt << [j, k] }
    end
    lyt
  end

  # This allows the modified CDC protocol to be run on flexible plate sizes
  # It may be needed in cases when 96 well plates are turned sideways or if
  # run at lower/higher throughput
  #
  # @param size [Int] usually is the same as group size. I wanted to hard code
  #   this in... still debating if thats the right call... easy to change tho
  def make_modified_start_array(size)
    rem = @rows % size
    size += 1 unless rem.zero?
    start_array = []
    @rows.times do |idx|
      start_row = size * idx
      break if start_row == @rows && size != 1

      start_array.push(start_row)
    end
    start_array
  end

  #================= Skip row methods =========================#

  def skip_sample_layout
    lyt = []
    make_skip_start_array(@group_size).each do |j|
      cols = Array.new(@columns) { |c| c }
      cols.each { |c| @group_size.times { |i| lyt << [i + j, c] } }
    end
    lyt
  end

  def skip_primer_layout
    lyt = []
    make_skip_start_array(1).each do |j|
      @columns.times { |k| lyt << [j, k] }
    end
    lyt
  end

  # This allows the modified CDC protocol to be run on flexible plate sizes
  # but skip every other row.
  # It may be needed in cases when 96 well plates are turned sideways or if
  # run at lower/higher throughput
  #
  # @param size [Int] usually is the same as group size. I wanted to hard code
  #   this in... still debating if thats the right call... easy to change tho
  def make_skip_start_array(size)
    rem = @rows % size
    size += 1 unless rem.zero?
    start_array = []
    @rows.times do |idx|
      next unless idx.even?

      start_row = size * idx
      break if start_row == @rows && size != 1

      start_array.push(start_row)
    end
    start_array
  end
end
