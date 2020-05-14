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
  def get_alpha_num_location(collection, obj_to_find)
    unless obj-to_find.is_a? Array
      array_of_objs = [obj_to_find] 
    else
      array_of_objs = obj_to_find
    end

    hash_of_samples = Hash.new
    array_of_objs.each do |sample|
      coordinates = get_obj_location(collection, sample) # [[r0, c0],[r1, c0], [r2,c0]]
      alpha_num_locations = []
      coordinates.each do |coordinate_set| # takes coords [2, 0] index=0
        alpha_num_locations << convert_coordinates_to_location(coordinate_set) # 2,0 -> C1, 4,0 -> E1
      end
      locations.join(',') # removes the ["A1"] the brackets and parantheses
      return locations unless obj_to_find.is_a? Array
      hash_of_samples[sample] = locations
    end
    hash_of_samples
  end

  # converts an array containing row and column coordinates to alphanumeric locations
  #
  # @param coordinates [Array<row,column>] set of coordinates
  # @return [String] alpha numerical location
  def convert_coordinates_to_location(coordinates)
    ALPHA26[coordinates[0]] + (coordinates[1] + 1).to_s
  end

  # Converts alpha numerical location to an Array of coordinatese
  #
  # @param alpha [String] alpha numerical location
  # @return [Array<r,c>] array of row and column
  def convert_location_to_coordinates(alpha)
    alpha_characters = ''
    alpha.length.times |idx|
      char = alpha(idx, idx+1) 
      alpha_characters += alpha(idx, idx+1) unless char.is_an_integer?
    end
    inspect alpha_characters #TODO remove this once confirmed to work
    row = ALPHA26.find_index(alpha_characters)
    column = alpha[1..-1].to_i - 1
    [row, column]
  end


  # @depreciated wrapper for old uses
  def get_item_sample_location(collection, obj_to_find)
    get_obj_location(collection, obj_to_find)
  end

  # Finds the location coordinates of an Item or Sample
  #
  # @param collection [Collection] the Collection containing the Item or Sample
  # @param obj_to_find [Item, Part, Sample] Item, Part, or Sample to be found or array of such
  # @return [Array] Array of item, part, or sample locations in form [[r1,c1],[r2,c1]]
  def get_obj_location(collection, obj_to_find)
    if obj_to_find.is_a? Array
      hash_of_locations = Hash.new
      obj_to_find.each do |part|
        hash_of_locations[part] = collection.find(obj_to_find)
      end
      return hash_of_locations
    else
      return collection.find(obj_to_find)
    end
  end

  # Finds a part from an alpha numerical string location(e.g. A1, B1)
  #
  # @param collection [Collection] the collection that contains the part
  # @param location [String] the location of the part within the collection (A1, B3, C7)
  # @return part [Item] the item at the given location
  def locate_part(collection, location)
    row, column = convert_location_to_coordinates(location)
    dimensions = collection.dimensions
    raise 'Location outside collection dimensions' if row > dimensions[0] || column > dimensions[1]

    collection.part(row, column)
  end

  # @deprecated Wrapper to New Method
  def part_alpha_num(collection, alpha)
    locate_part(collection, alpha)
  end
end
