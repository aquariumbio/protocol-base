# frozen_string_literal: true

needs 'Microtiter Plates/PlateLayoutGenerator'

class Protocol
  def main
    rval = {}
    layout_table = Array.new(8) { |_| Array.new(12) }

    plg = PlateLayoutGeneratorFactory.build(group_size: 2)

    8.times do |_|
      plg.next_group(column: 0).each { |r, c| layout_table[r][c] = 'P1' }
      plg.next_group(column: 6).each { |r, c| layout_table[r][c] = 'P2' }
    end

    64.times do |i|
      r, c = plg.next
      layout_table[r][c] = i
    end

    show do
      table layout_table
    end

    rval[:layout_table] = layout_table
    rval
  end
end
