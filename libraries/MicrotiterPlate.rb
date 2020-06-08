module MicrotiterPlate
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