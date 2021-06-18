# frozen_string_literal: true

module TextDisplayHelper
  # Add HTML tags for bold text
  def bold(text)
    '<b>' + text + '</b>'
  end

  # Return Item IDs as a string with one or more ID ranges represented as
  #   the beginning and end separated by a hyphen. Currently raises an
  #   exception if the numbers are non-consecutive.
  #
  # @param items [Array<Item>]
  # @return [String]
  def id_ranges_display(items:)
    ids = items.map(&:id).sort
    ranges = []
    range = [ids.shift]

    ids.each do |id|
      if id == range.last + 1
        range.append(id)
      else
        ranges.append(range)
        range = [id]
      end
    end
    ranges.append(range)

    ranges.map! { |r| r.length == 1 ? r.first.to_s : "#{r.first} - #{r.last}" }
    ranges.to_sentence
  end

  # Creates show block following instructions for show block
  # TODO this could be simplified using a back-end method created by Ben
  #    (to be identified and implemented)
  #
  # @param title 'String' the string of things to show
  # @param show_block: 'Array<Hash>' hash to represent each line
  #        [{display: Array<String>/String/Table, type: 'note','bullet','table'}]
  def display(title:, show_block:)
    show do
      title title
      show_block.each do |block|
        raise 'block is nil' if block.empty?

        if block.is_a? Array
          block.each do |line|
            if line.is_a? Hash
              send(line[:type], line[:display])
            elsif line.is_a? Array
              line.each do |sub_line|
                note sub_line.to_s
              end
            else
              note line.to_s
            end
          end
        elsif block.is_a? Hash
          if block[:type] == 'table'
            send(block[:type], block[:display])
          elsif block[:display].is_a? Array
            block[:display].each do |line|
              send(block[:type], line)
            end
          else
            send(block[:type], block[:display])
          end
        else
          note block.to_s
        end
        separator
      end
    end
  end
end