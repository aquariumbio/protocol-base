# typed: false
# frozen_string_literal: true

needs 'Microtiter Plates/PlateLayoutGenerator'

module MicrotiterPlates
  # Convert a letter to the corresponding array index
  #
  # @param letter [String] the letter (usually of a row)
  # @return Fixnum
  def letter_to_index(letter)
    alphabet_array.index(letter.upcase)
  end

  # Convert an array index to the corresponding letter of the alphabet
  #
  # @param index [Fixnum] the index (usually of a row)
  # @return String
  def index_to_letter(index)
    alphabet_array[index]
  end

  # Array of all letters of the alphablet in uppercase
  #
  # @return Array<String>
  def alphabet_array
    ('A'..'Z').to_a
  end

  # Get the alpha component of an alphanumumeric coordinate
  #
  # @param alphanum [String]
  # @return [String, nil] the first contiguous run of letters or nil if no
  #   letters are found
  def alpha_component(alphanum)
    mtch = alphanum.match(/[[:alpha:]]+/)
    return mtch[0] if mtch
  end

  # Get the numeric component of an alphanumumeric coordinate
  #
  # @param alphanum [String]
  # @return [Fixnum, nil] the first contiguous run of digits or nil if no
  #   digits are found
  def numeric_component(alphanum)
    mtch = alphanum.match(/\d+/)
    return mtch[0].to_i if mtch
  end
end

# Factory class for building `MicrotiterPlate`s
# @author Devin Strickland <strcklnd@uw.edu>
#
class MicrotiterPlateFactory
  # Builds a new `MicrotiterPlate`
  #
  # @param collection [Collection] the `Collection` that is to be managed
  # @param group_size [Fixnum] the size of groups of wells, e.g., corresponding
  #   to replicates (see `PlateLayoutGenerator`)
  # @param method [String] the method for creating a new `PlateLayoutGenerator`
  # @return [MicrotiterPlate]
  def self.build(collection:, group_size:, method:)
    MicrotiterPlate.new(
      collection: collection,
      group_size: group_size,
      method: method
    )
  end
end

# Class for modeling the addition of samples to a microtiter (e.g, 96-well)
#   plate
# @author Devin Strickland <strcklnd@uw.edu>
#
class MicrotiterPlate
  # Instantiates `MicrotiterPlate`
  #
  # @param collection [Collection] the `Collection` that is to be managed
  # @param group_size [Fixnum] the size of groups of wells, e.g., correspionding
  #   to replicates (see `PlateLayoutGenerator`)
  # @param method [String] the method for creating a new `PlateLayoutGenerator`
  # @return [MicrotiterPlate]
  def initialize(collection:, group_size:, method:)
    @collection = collection
    @plate_layout_generator = PlateLayoutGeneratorFactory.build(
      group_size: group_size,
      method: method
    )
  end

  # Returns the next `PlateLayoutGenerator` index that does not point to a
  #   `Part` that already has a `DataAssociation` for `key`
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param column [Fixnum] an alternative column index to start with
  def next_empty(key:, column: nil)
    nxt = nil
    loop do
      nxt = @plate_layout_generator.next(column: column)
      prt = @collection.part(nxt[0], nxt[1])
      break unless prt.associations[key].present?
    end
    nxt
  end

  # Returns the next `PlateLayoutGenerator` group that does not point to any
  #   `Part` that already has a `DataAssociation` for `key`
  #
  # @param key [String] the key pointing to the relevant `DataAssociation`
  # @param column [Fixnum] an alternative column index to start with
  def next_empty_group(key:, column: nil)
    nxt_grp = nil
    loop do
      present = false
      nxt_grp = @plate_layout_generator.next_group(column: column)
      nxt_grp.each do |nxt|
        prt = @collection.part(nxt[0], nxt[1])
        present = true if prt.associations[key].present?
      end
      break unless present
    end
    nxt_grp
  end
end
