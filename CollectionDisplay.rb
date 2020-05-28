# Justin Vrana
#
# modified by:
# Cannon Mallory
# malloc3@uw.edu
#
# Modifications include:
# Optional Checkable boxes.  Additional Documentation

# Methods for displaying information about collections
module CollectionDisplay
  # Highlights all non-empty slots in collection
  #
  # @param collection [Collection] the collection
  # @param check [Boolean] Optional weather cells should be Checkable
  # @param &rc_block [Block] Optional block to determine rc_list
  # @return [Table]
  def highlight_non_empty(collection, check: true, &rc_block)
    highlight_collection_rc(collection, collection.get_non_empty,
                            check: check, &rc_block)
  end

  # Highlights all empty slots in collection
  #
  # @param collection [Collection] the collection
  # @param check [Boolean] Optional weather cells should be Checkable
  # @param &rc_block [Block] Optional block to determine rc_list
  # @return [Table]
  def highlight_empty(collection, check: true, &rc_block)
    highlight_collection_rc(collection, collection.get_empty,
                            check: check, &rc_block)
  end

  # Highlights all non-empty slots in collection
  #
  # @param collection [Collection] the collection
  # @param check [Boolean] Optional weather cells should be Checkable
  # @param &rc_block [Block] Optional block to determine rc_list
  # @return [Table]
  def highlight_alpha_non_empty(collection, check: true, &rc_block)
    highlight_alpha_rc(collection, collection.get_non_empty,
                       check: check, &rc_block)
  end

  # Highlights all empty slots in collection
  #
  # @param collection [Collection] the collection
  # @param check [Boolean] Optional weather cells should be Checkable
  # @param &rc_block [Block] Optional block to determine rc_list
  # @return [Table]
  def highlight_alpha_empty(collection, check: true, &rc_block)
    highlight_alpha_rc(collection, collection.get_empty,
                       check: check, &rc_block)
  end

  # Gets a list of the coordinates and alphanumeric locations
  #
  # @param collection [Collection] the collection that items are going to
  # @param samples [The samples that locations are wanted from]
  #
  # @return [Array<Array<row, column, location>] Coordinates and
  #      locations in same order as sample array
  def get_rcx_list(collection, samples)
    coordinates_and_data = []
    samples.each do |sample|
      sample_coordinates = get_obj_location(collection, sample)
      sample_locations = get_alpha_num_location(collection, sample)

      sample_coordinates.each do |coordinates|
        coordinates.push(sample_locations) # [0,0,A1]
        coordinates_and_data.push(coordinates)
      end
    end
  end

  # Highlights all cells listed in rc_list (CHANGED NAME)
  #
  # @param collection [Collection] the collection which should be highlighted
  # @param rc_list [Array] array of rc [[row,col],...]
  #                       row = int
  #                       col = int
  # @param check [Boolean] Optional whether cells should be Checkable
  # @param &rc_block [Block] to determine rc list
  # @return [Table]
  def highlight_collection_rc(collection, rc_list, check: true, &_rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, '']
    }
    highlight_collection_rcx(collection, rcx_list, check: check)
  end

  # Highlights all cells in ROW/COLUMN/X
  #
  #
  # @param collection [Collection] the collection
  # @param rcx_list [Array] array of [[row, colum, x],...]
  #     row = int
  #     col = int
  #     x = string
  # @return [Table]
  def highlight_collection_rcx(collection, rcx_list, check: true)
    rows, columns = collection.dimensions
    table = create_collection_table(rows: rows, columns: columns)
    highlight_rcx(table, rcx_list, check: check)
  end

  # Makes an alpha numerical display of collection wells listed in rc_list
  #
  # @param collection [Collection] the collection
  # @param rc_list [Array] Array of rows and columns [[row,col],...]
  # @param check [Boolean] Default True weather cells are checkable
  # @param &rc_block [Block] Optional tbd
  def highlight_alpha_rc(collection, rc_list, check: true, &_rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, '']
    }
    highlight_alpha_rcx(collection, rcx_list, check: check)
  end

  # Makes an alpha numerical display of collection wells listed in rcx_list
  #
  # @param collection [Collection] the collection
  # @param rc_list [Array] Array of rows and columns [[row,col,x],...]
  #         row,column are int, x is string
  # @param check [Boolean] Default True weather cells are checkable
  # @param &rc_block [Block] Optional tbd
  def highlight_alpha_rcx(collection, rcx_list, check: true)
    rows, columns = collection.dimensions
    tbl = create_collection_table(rows: rows, columns: columns)
    rcx_list.each do |r, c, x|
      highlight_cell(tbl, r, c, x, check: check)
    end
    tbl
  end
  
  # Creates a table with the same dimensions as the input collection
  #
  # @param collection [Collection] the collection to be represented by the table
  # @param add_headers [Boolean] optional True
  # @return tab [Table] a table to be displayed
  def create_collection_table(rows:, columns:)
    size = rows * columns
    slots = (1..size + rows + columns + 1).to_a
    tab = slots.each_slice(columns + 1).map do |row|
      row.map do
        { class: 'td-empty-slot' }
      end
    end

    labels = Array(1...size + 1)
    tab.each_with_index do |row, row_idx|
      row.each_with_index do |col, col_idx|
        if row_idx.zero?
          col[:content] = "<b><u>#{col_idx}</u></b>"
        elsif col_idx.zero?
          col[:content] = "<b><u>#{get_alpha(row_idx)}</u></b>"
        else
          col[:content] = labels.first
          labels = labels.drop(1)
        end
      end
    end
    tab.first.first[:content] = '<b>:)</b>'
    tab
  end

  # converts numbers to alphabetical values (eg 1->A 27-AA etc)
  #
  # @param num [Integer] the integer to be converted
  def get_alpha(num)
    return '' if num < 1

    string = ''
    loop do
      num, r = (num-1).divmod(26)
      string.prepend(alpha26[r])
      break if num.zero?
    end
    string
  end

  # Highlights a specific location in a table (TODO TABLE CLASS)
  #
  # @param tbl [Table] the table which parts are being highlighted
  # @param row [Integer] the row
  # @param col [Integer] the column
  # @param id [String] what will be printed in the table
  #                    (TODO EMPTY STRING/DON'T REPLACE CONTENT)
  # @param check [Boolean] optional determines if cell is checkable or not
  def highlight_cell(tbl, row, col, id, check: true)
    tbl[row + 1][col + 1] = { content: id, class: 'td-filled-slot', check: check}
  end

  # Highlights all cells in ROW/COLUMN/X  (TODO TABLE CLASS)
  # X can be any string that is to be displayed in cell
  #
  # @param table [table] the table with cells to be highlighted
  # @param rcx_list [array] array of [[row, column, x],...]
  #     row = int
  #     col = int
  #     x = string
  # @return [table]
  def highlight_rcx(table, rcx_list, check: true)
    rcx_list.each do |rcx|
      rcx.push(check)
    end
    highlight_rcx_check(table, rcx_list)
    table
  end

  # Highlights all cells in ROW/COLUMN/X  (TODO TABLE CLASS)
  # X can be any string that is to be displayed in cell
  #
  # @param table [Table] the table with cells to be highlighted
  # @param rcx_check_list [Array] array of [[row, column, data, check],...]
  # @return [Table]
  def highlight_rcx_check(table, rcx_check_list)
    rcx_check_list.each do |row, column, data, check|
      highlight_cell(table, row, column, data, check: check)
    end
    table
  end

  # TODO: TABLE LIB
  # Highlights all cells listed in rc_list
  #
  # @param collection [Collection] the collection which should be highlighted
  # @param rc_list [Array] array of rc [[row,col],...]
  #                       row = int
  #                       col = int
  # @param check [Boolean] true if cells should be Checkable
  # @param &rc_block [Block] to determine rc list
  # @return [Table]
  def highlight_rc(table, rc_list, check: true, &_rc_block)
    rcx_list = rc_list.map { |r, c|
      block_given? ? [r, c, yield(r, c)] : [r, c, '']
    }
    highlight_rcx(table, rcx_list, check: check)
  end

  # Highlights all slots in all collections in operation list
  #
  # @param ops [OperationList] Operation list
  # @param id_block [Block] Optional Unknown
  # @param check [Boolean] true if cells should be Checkable
  # @param &fv_block [Block] Optional Unknown
  # @return [Table]
  def highlight_collection(ops, id_block: nil, check: true, &fv_block)
    g = ops.group_by { |op| fv_block.call(op).collection }
    tables = g.map do |collection, grouped_ops|
      rcx_list = grouped_ops.map do |op|
        fv = fv_block.call(op)
        id = id_block.call(op) if id_block
        id ||= fv.sample.id
        [fv.row, fv.column, id]
      end
      tbl = highlight_collection_rcx(collection, rcx_list, check: check)
      [collection, tbl]
    end
    tables
  end

  
  # TODO: write highlight heat map method for table
  # Creates table illustrating data associated with keys
  #  for each part noted in rc_list
  #
  # @param collection [Collection] the collection
  # @param keys [Array<String>] an array of all keys that point to desired data
  # @param rc_list [Array<Array<row, col>...>] optional array of locations
  #        if not given will display all non_empty
  # @return table of parts with data information
  def display_data(collection, keys, rc_list: nil)
    rc_list = collection.get_non_empty if rc_list.nil?
    rcx_array = []
    rc_list.each do |loc|
      data_string = ''
      keys.each_with_index do |key, idx|
        part = collection.part(loc[0], loc[1])
        data = get_associated_data(part, key).to_s
        unless data.nil?
          data_string += ', ' unless idx.zero?
          data_string += data
        end
        loc.push(data_string)
        rcx_array.push(loc)
      end
      loc.push(data_string)
      rcx_array.push(loc)
    end
    highlight_collection_rcx(collection, rcx_array, check: false)
  end
end