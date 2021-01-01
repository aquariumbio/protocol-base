# frozen_string_literal: true

needs 'Composition Libs/Composition'
needs 'PCR Libs/PCRCompositionDefinitions'

# Factory class for instantiating `PCRComposition`
# @author Devin Strickland <strcklnd@uw.edu>
class PCRCompositionFactory
  # Instantiates `PCRComposition`
  # Either `component_data` or `program_name` must be passed
  #
  # @param component_data [Hash] a hash enumerating the components
  # @param program_name [String] the name of one of the default
  #   component hashes
  # @return [PCRComposition]
  def self.build(component_data: nil, program_name: nil)
    PCRComposition.new(
      component_data: component_data,
      program_name: program_name
    )
  end
end

# Models the composition of a polymerase chain reaction
# @author Devin Strickland <strcklnd@uw.edu>
# @note As much as possible, Protocols using this class should draw
#   input names from `CommonInputOutputNames`
class PCRComposition < Composition
  include PCRCompositionDefinitions

  attr_accessor :components

  # Instantiates the class
  # Either `component_data` or `program_name` must be passed
  #
  # @param component_data [Hash] a hash enumerating the components
  # @param program_name [String] the name of one of the default
  #   component hashes
  # @return [PCRComposition]
  def initialize(component_data: nil, program_name: nil)
    if component_data.blank? && program_name.blank?
      msg = 'Unable to initialize PCRComposition.' \
        ' Either `component_data` or `program_name` is required.'
      raise ProtocolError, msg
    elsif program_name.present?
      component_data = get_composition_def(name: program_name)
    end

    super(component_data: component_data)
  end

  # Specifications for the dye component
  # @return (see #input)
  def dye
    input(DYE)
  end

  # Specifications for the buffer component
  # @return (see #input)
  def buffer
    input(BUFFER)
  end

  # Specifications for the polymerase component
  # @return (see #input)
  def polymerase
    input(POLYMERASE)
  end

  # Specifications for the master mix component
  # @return (see #input)
  def master_mix
    input(MASTER_MIX)
  end

  # Specifications for the forward primer component
  # @return (see #input)
  def forward_primer
    input(FORWARD_PRIMER)
  end

  # Specifications for the reverse primer component
  # @return (see #input)
  def reverse_primer
    input(REVERSE_PRIMER)
  end

  # Specifications for the primer/probe component
  # @return (see #input)
  def primer_probe_mix
    input(PRIMER_PROBE_MIX)
  end

  # Specifications for the template component
  # @return [Component]
  def template
    input(TEMPLATE)
  end

  # Specifications for the water component
  # @return (see #input)
  def water
    input(WATER)
  end
end