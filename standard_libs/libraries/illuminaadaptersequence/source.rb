# frozen_string_literal: true

# Class that retrieves standard features from DNA sequences corresponding to
#   adapters for Illumina sequencing.
#
# Oligonucleotide sequences Copyright 2021 Illumina, Inc. All rights reserved
# @todo This library is specific to a single type of primer used for work with
#   the IPD. It should be extended to automatically identify other types of
#   adapter sequences.
# @author Devin Strickland <strcklnd@uw.edu>
class IlluminaAdapterSequence
  attr_reader :sequence

  # Create a new IlluminaAdapterSequence object from a DNA sequence.
  def initialize(sequence:)
    @sequence = sequence
  end

  # Identify the barcode from the DNA sequence.
  def barcode(reverse_complement: true)
    sequence =~ /#{index1_5prime}(.+)#{ipd_primer_3prime}/i
    bc = Regexp.last_match(1)
    bc = IlluminaAdapterSequence.complement(bc).reverse if bc.present? && reverse_complement
    bc
  end

  def self.complement(str)
    str.gsub(/./, complements)
  end

  private

  def index1_5prime
    'CAAGCAGAAGACGGCATACGAGAT'
  end

  def index2_5prime
    'AATGATACGGCGACCACCGAGATCTACAC'
  end

  def ipd_primer_3prime
    'GTGACTGGAGTTCAGACGTGTGCTCTTCCG'
  end

  private_class_method def self.complements
    {
      'a' => 't',
      'A' => 'T',
      't' => 'a',
      'T' => 'A',
      'c' => 'g',
      'C' => 'G',
      'g' => 'c',
      'G' => 'C'
    }
  end
end
