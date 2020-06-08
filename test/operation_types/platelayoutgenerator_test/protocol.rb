# frozen_string_literal: true

needs 'Standard Libs/Debug'
needs 'Microtiter Plates/PlateLayoutGenerator'

# Protocol for setting up a plate with extracted RNA samples
#
# @author Devin Strickland <strcklnd@uw.edu>
class Protocol
  include Debug

  def main
    raise 'Too many' if operations.length > 22

    layout_table = Array.new(8) { |_| Array.new(12) }

    clg = PlateLayoutGeneratorFactory.build(group_size: 3)

    clg.next_group.each { |r, c| layout_table[r][c] = 'NTC' }

    clg.next_group(column: 11).each { |r, c| layout_table[r][c] = 'nCoVPC' }

    operations.each do |op|
      clg.next_group.each { |r, c| layout_table[r][c] = op.id }
    end

    show do
      table layout_table
    end

    {}
  end
end
