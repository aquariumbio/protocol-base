# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/ProvenanceFinder'

class Protocol
  include TestFixtures
  include ProvenanceFinder

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    found_ops = walk_back(nil, 463_144)
    test_found_ops(found_ops.flatten.map(&:name))

    show do
      found_ops.flatten.each do |op|
        note "#{op.id} (#{op.name}): #{op.predecessor_ids}"
      end
    end

    rval
  end

  def test_found_ops(actual)
    expected = [
      'Dilute to 4nM', 'Qubit concentration',
      'Purify Gel Slice (NGS)', 'Extract Gel Slice (NGS)',
      'Run Pre-poured Gel', 'Make qPCR Fragment WITH PLATES',
      'Purify Gel Slice (NGS)', 'Extract Gel Slice (NGS)',
      'Run Pre-poured Gel', 'Make qPCR Fragment',
      'Digest Genomic DNA', 'Yeast Plasmid Extraction', 'Treat With Zymolyase',
      'Store Yeast Library Sample', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Sort Yeast Display Library', 'Challenge and Label',
      'Dilute Yeast Library', 'Innoculate Yeast Library',
      'Make Library Glycerol Stocks', 'High-Efficiency Transformation NEW',
      'Combine and Dry DNA', 'Ethanol Precipitation Cleanup',
      'DNA ethanol precipitation', 'Combine Purified Samples',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR',
      'qPCR Library Purification', 'Transfer From Stripwell to Tubes', 'Library qPCR'
    ]
    @assertions[:assert_equal].append([expected, actual])
  end
end
