# frozen_string_literal: true

# Factory class for instantiating `PlateLayoutGenerator`
#
# @author Devin Strickland <strcklnd@uw.edu>
class PlateLayoutGeneratorFactory
  # Instantiates `PlateLayoutGenerator`
  #
  # @param group_size [FixNum] the size of groups of wells, e.g., corresponding
  #   to replicates
  # @return [PlateLayoutGenerator]
  def self.build(group_size: 1, method: nil, dimensions: [8, 12])
    PlateLayoutGenerator.new(group_size: group_size,
                             method: method,
                             dimensions: dimensions)
  end
end

# Provides individual indices or batches of indices from a microtiter plate, in
#   order from top left ,and yielding each index only once
#
# @author Devin Strickland <strcklnd@uw.edu>
class PlateLayoutGenerator
  def initialize(group_size: 1, method: nil, dimensions: [8, 12])
    @rows = dimensions[0]
    @columns = dimensions[1]
    @group_size = group_size
    method ||= :cdc_sample_layout
    @layout = send(method)
    @ii = []
    @column = []
    @first_index = []
  end

  def next(column: nil)
    i = column ? first_index_in(column) : 0
    @layout.slice!(i)
  end

  def next_group(column: nil)
    i = column ? first_index_in(column) : 0
    @layout.slice!(i, @group_size)
  end

  def iterate_column(column)
    return nil if column.blank?
    if column < @columns
      column += 1
    else
      column = 0
    end
    column
  end

  private

  def first_index_in(column)
    @layout.index { |x| x[1] == column }
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
      cols.each { |c| @group_size.times { |i| lyt << [i*2 + j, c] } }
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
