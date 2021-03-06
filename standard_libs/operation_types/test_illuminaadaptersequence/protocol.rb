# typed: false
# frozen_string_literal: true

# This is a default Protocol for testing libraries that uses
#   TestFixtures::assertions_framework
# To use it, import the library you want to test.
#
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/Debug'
needs 'Standard Libs/IlluminaAdapterSequence'

class Protocol
  require 'csv'

  include TestFixtures
  include Debug

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    test_barcode

    rval
  end

  def test_barcode
    test_sequences.each do |sequence, barcode, rc_barcode|
      ias = IlluminaAdapterSequence.new(sequence: sequence)
      @assertions[:assert_equal].append([
        barcode,
        ias.barcode(reverse_complement: false)
      ])
      @assertions[:assert_equal].append([
        rc_barcode,
        ias.barcode
      ])
    end
  end

  def test_sequences
    [
      %w[CAAGCAGAAGACGGCATACGAGATGTCGGTAAGTGACTGGAGTTCAGACGTGTGCTCTTCCG GTCGGTAA TTACCGAC],
      %w[CAAGCAGAAGACGGCATACGAGATAGGTCACTGTGACTGGAGTTCAGACGTGTGCTCTTCCG AGGTCACT AGTGACCT],
      %w[CAAGCAGAAGACGGCATACGAGATGAATCCGAGTGACTGGAGTTCAGACGTGTGCTCTTCCG GAATCCGA TCGGATTC]
    ]
  end
end
