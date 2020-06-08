# frozen_string_literal: true

needs 'Collection Management/CollectionLocation'

# Factory class for instantiating `CollectionLayoutGenerator`
#
# @author Devin Strickland <strcklnd@uw.edu>
class CollectionLayoutGeneratorFactory
  # Instantiates `CollectionLayoutGenerator`
  #
  # @param group_size [FixNum] the size of groups of wells, e.g., correspinding
  #   to replicates
  # @return [CollectionLayoutGenerator]
  def self.build(group_size: 1)
    CollectionLayoutGenerator.new(group_size: group_size)
  end
end

# Provides individual indices or batches of indices from a collection, in
#   order from top left ,and yielding each index only once
#
# @author Devin Strickland <strcklnd@uw.edu>
class CollectionLayoutGenerator
  include CollectionLocation

  def initialize(group_size: 1)
    @group_size = group_size
    @layout = cdc_layout
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

  def cdc_layout
    lyt = []
    [0, 4].each do |j|
      cols = Array.new(12) { |c| c }
      cols.each { |c| @group_size.times { |i| lyt << [i + j, c] } }
    end
    lyt
  end
end
