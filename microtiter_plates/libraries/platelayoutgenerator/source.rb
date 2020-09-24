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

end
