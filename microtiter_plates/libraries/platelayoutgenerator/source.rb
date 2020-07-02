# frozen_string_literal: true

# Factory class for instantiating `PlateLayoutGenerator`
#
# @author Devin Strickland <strcklnd@uw.edu>
class PlateLayoutGeneratorFactory
  # Instantiates `PlateLayoutGenerator`
  #
  # @param group_size [FixNum] the size of groups of wells, e.g., correspinding
  #   to replicates
  # @return [PlateLayoutGenerator]
  def self.build(group_size: 1, method: nil)
    PlateLayoutGenerator.new(group_size: group_size, method: method)
  end
end

# Provides individual indices or batches of indices from a microtiter plate, in
#   order from top left ,and yielding each index only once
#
# @author Devin Strickland <strcklnd@uw.edu>
class PlateLayoutGenerator
  def initialize(group_size: 1, method: nil)
    @group_size = group_size
    method ||= :cdc_sample_layout
    @layout = send(method)
  end

  def next(column: nil)
    i = column ? first_index_in(column) : 0
    @layout.slice!(i)
  end

  def next_group(column: nil)
    i = column ? first_index_in(column) : 0
    @layout.slice!(i, @group_size)
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
end
