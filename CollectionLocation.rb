# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Methods to facilitate sample management within collections
module CollectionLocation

  ALPHA26 = ('A'...'Z').to_a

  # Gets the location string of a sample in a collection
  #
  # @param collection [Collection] the collection containing the sample
  # @param sample [Sample] the Sample that you want to locate
  # @return [String] the Alpha Numeric location(s) e.g. A1, A2
  def get_alpha_num_location(collection, sample)
    coordinates = get_item_sample_location(collection, sample) # [[r0, c0],[r1, c0], [r2,c0]]
    alpha_num_locations = []
    coordinates.each do |coordinate_set| # takes coords [2, 0] index=0
      alpha_num_locations << convert_rc_to_alpha(coordinate_set) # 2,0 -> C1, 4,0 -> E1
    end
    locations.join(',') # removes the ["A1"] the brackets and parantheses
  end

  # converts an array containing one set of row and column values coordinates to alpha numerical locations
  #
  # @param coordinates [Array<row,column>] set of coordinates
  # @return [String] alpha numerical location
  def convert_rc_to_alpha(coordinates)
    ALPHA26[coordinates[0]] + (coordinates[1] + 1).to_s
  end

  # Converts alpha numerical location to Array<r,c>
  #
  # @param alpha [String] alpha numerical location
  # @return [Arrray<r,c>] array of row and column
  def convert_alpha_to_rc(alpha)
    row = ALPHA26.find_index(alpha[0, 1])
    # TODO: check this next line -- weird error
    # col = alpha[1...].to_i - 1
    [row, col]
  end

  # Finds the location coordinates of an Item or Sample
  #
  # @param collection [Collection] the Collection containing the Item or Sample
  # @param part [Item, Part, Sample] Item, Part, or Sample to be found
  # @return [Array] Array of item, part, or sample locations in form [[r1,c1],[r2,c1]]
  def get_item_sample_location(collection, part)
    collection.find(part)
  end

  # Finds a sample from an alpha numberical string location(e.g. A1, B1)
  #
  # @param collection [Collection] the collection that contains the part
  # @param  alpha [String] the location of the part within the collection (A1, B3, C7)
  # @return part [Item] the item at the given location
  def part_alpha_num(collection, alpha)
    row, col = convert_alpha_to_rc(alpha)
    dimensions = collection.dimensions
    raise 'Location outside collection dimensions' if row > dimensions[0] || col > dimensions[1]
    part = collection.part(row, col)
  end

  # gets the rcx list of samples in the collection.
  # R is Row
  # C is column
  # x is the alpha numerical location (in this case)
  #
  # Returns in the same order as sample array
  #
  # @param collection [Collection] the collection that items are going to
  # @param samples [The samples that locations are wanted from]
  #
  # @return [Array<Array<r, c, x>]
  def get_rcx_list(collection, samples)
    rcx_list = []
    array_of_samples.each do |sample|
      sample_coordinates = get_item_sample_location(from_collection, sample)
      sample_alpha = get_alpha_num_location(from_collection, sample)

      sample_coordinates.each do |coordinates|
        coordinates.push(sample_alpha) # [0,0,A1]
        locations.push(coordinates)
      end
    end
    rcx_list
  end
end
