# frozen_string_literal: true

# Cannon Mallory
# malloc3@uw.edu
#
# Methods to facilitate sample management within collections
module CollectionLocation
  ALPHA26 = ('A'...'AAA').to_a.freeze

  # Convert a letter to the corresponding array index
  #
  # @param letter [String] the letter (usually of a row)
  # @return Fixnum
  def letter_to_index(letter)
    ALPHA26.index(letter.upcase)
  end

  # Convert an array index to the corresponding letter of the alphabet
  #
  # @param index [Fixnum] the index (usually of a row)
  # @return String
  def index_to_letter(index)
    ALPHA26[index]
  end

  # Checks if a string is a number
  # @param string [String]
  def is_number?(string)
    true if Float(string) rescue false
  end

  # Gets the location string of a sample in a collection
  #
  # @param collection [Collection] the collection containing the sample
  # @param sample [Sample] the Sample that you want to locate
  # @return [Hash{sample: location}] the Alpha Numeric location(s) e.g. A1, A2
  def get_alpha_num_location(collection, items)
    items = [items] unless items.is_a?(Array)

    hash_of_samples = {}
    items.each do |sample|
      coordinates = collection.find(sample)
      alpha_num_locations = []
      coordinates.each do |coordinate_set|
        alpha_num_locations << convert_coordinates_to_location(coordinate_set)
      end
      alpha_num_locations.join(',')
      hash_of_samples[sample] = alpha_num_locations
    end
    hash_of_samples
  end

  # Converts alpha numerical location to an Array of coordinates
  #
  # @param alpha [String] alpha numerical location
  # @return [Array<r,c>] array of row and column
  def convert_location_to_coordinates(alpha)
    coord = []
    alpha.split(/(\d+)/).each do |ch|
      if is_number?(ch)
        coord.push(ch.to_i)
      else
        coord.push(letter_to_index(ch))
      end
    end
    coord
  end

  # Finds the location coordinates of an multiple items/samples
  #
  # @param collection [Collection] the Collection containing the Item or Sample
  # @param items [Array<objects>] Item, Part, or Sample to be found
  # @return [Hash{sample: [row, column]}] 
  def get_items_coordinates(collection, items)
    hash_of_locations = {}
    items.each do |item|
      hash_of_locations[item] = collection.find(item)
    end
    hash_of_locations
  end

  # Finds a part from an alpha numerical string location(e.g. A1, B1)
  #  TODO Move to krill
  #
  # @param collection [Collection] the collection that contains the part
  # @param location [String] the location of the part within the collection
  # @return part [Item] the item at the given location
  def get_part(collection, location)
    row, column = convert_location_to_coordinates(location)
    collection.part(row, column)
  end
  
  # DEPRECIATED
  # Returns the exact location of an Part in a collection.
  #  Will return the location of only that part
  #
  # @param collection [Collection]
  # @param item [Item] item that exists in the collection
  # @return [row, column] the location in the collection
  def find_item_in_collection(collection:, item:)
    collection.find(item)
  end

  # DEPRECIATED
  # Converts an array of coordinates to alpha numerical locations
  #
  # @param coordinates [Array<row,column>] set of coordinates
  # @return [String] alpha numerical location
  def convert_coordinates_to_location(coordinates)
    index_to_letter(coordinates[0]) + coordinates[1].to_s
  end
end
