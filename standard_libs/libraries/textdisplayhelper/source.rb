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
end