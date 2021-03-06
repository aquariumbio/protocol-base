# frozen_string_literal: true

needs 'Standard Libs/Units'
needs 'Standard Libs/CommonInputOutputNames'

# Provice composition definitions for PCR reactions
# @author Devin Strickland <strcklnd@uw.edu>
module PCRCompositionDefinitions
  include Units
  include CommonInputOutputNames

  POLYMERASE = 'Polymerase'
  DYE = 'Dye'
  WATER = 'Molecular Grade Water'
  MASTER_MIX = 'Master Mix'
  PRIMER_PROBE_MIX = 'Primer/Probe Mix'
  BUFFER = 'Buffer'

  COMPONENTS = {
    # qPCR2: 2nd qPCR in NGS prep.
    'qPCR1' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 16, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 0.16,  units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 0.16,  units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 1.6, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 6.58, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 7.5, units: MICROLITERS
      }
    },

    # qPCR2: 2nd qPCR in NGS prep.
    #   Reverse primer is indexed primer.
    'qPCR2' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 25, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 2.5, units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 2.5, units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 2.5, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 15.5, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 2, units: MICROLITERS
      }
    },

    # LIBqPCR1: 1st qPCR in Libray prep.
    #   If sublibrary primers exist they are used here.
    'lib_qPCR1' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 12.5, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 0.75, units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 0.75, units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 1.25, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 8.75, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 1, units: MICROLITERS
      }
    },

    # LIBqPCR2: 2nd qPCR in Libray prep.
    #   Overhangs compatible with cloning vector are added here.
    'lib_qPCR2' => {
      polymerase: {
        input_name: POLYMERASE,
        qty: 25, units: MICROLITERS,
        sample_name: 'Kapa HF Master Mix'
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 1.5, units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 1.5, units: MICROLITERS
      },
      dye: {
        input_name: DYE,
        qty: 2.5, units: MICROLITERS,
        sample_name: 'Eva Green'
      },
      water: {
        input_name: WATER,
        qty: 17.5, units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 2, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_TaqPath_CG' => {
      water: {
        input_name: WATER,
        qty: 8.5, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 5.0, units: MICROLITERS,
        sample_name: 'TaqPath 1-Step RT-qPCR Master Mix (4x)'
      },
      template: {
        input_name: TEMPLATE,
        qty: 5.0, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_qScript_XLT_ToughMix' => {
      water: {
        input_name: WATER,
        qty: 3.5, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 10, units: MICROLITERS,
        sample_name: 'qScript XLT One-Step RT-qPCR ToughMix (2X)'
      },
      template: {
        input_name: TEMPLATE,
        qty: 5.0, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_UltraPlex_ToughMix' => {
      water: {
        input_name: WATER,
        qty: 8.5, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 5.0, units: MICROLITERS,
        sample_name: 'UltraPlex 1-Step ToughMix (4X)'
      },
      template: {
        input_name: TEMPLATE,
        qty: 5.0, units: MICROLITERS
      }
    },

    # CDC COVID-19 detection protocol
    'CDC_GoTaq_Probe_1-Step' => {
      water: {
        input_name: WATER,
        qty: 3.1, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 1.5, units: MICROLITERS
      },
      master_mix: {
        input_name: MASTER_MIX,
        qty: 10, units: MICROLITERS,
        sample_name: 'GoTaq Probe qPCR Master Mix with dUTP'
      },
      rt_mix: {
        input_name: 'RT Mix',
        qty: 0.4, units: MICROLITERS,
        sample_name: 'Go Script RT Mix for 1-Step RT-qPCR'
      },
      template: {
        input_name: TEMPLATE,
        qty: 5.0, units: MICROLITERS
      }
    },
    # Modified CDC COVID-19 detection protocol
    'Modified_CDC' => {
      template: {
        input_name: TEMPLATE,
        qty: 20.0, units: MICROLITERS
      },
      primer_probe_mix: {
        input_name: PRIMER_PROBE_MIX,
        qty: 0.0, units: MICROLITERS
      },
      master_mix: {
          input_name: MASTER_MIX,
          qty: 18, units: MICROLITERS,
          sample_name: 'Rehydration Buffer'
      }
    },
    'Modified_CDC_Exp_1' => {
      program_template_name: 'Modified_CDC',
      layout_template_name: 'Modified_CDC',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 10, units: MINUTES }
        },
        step2: {
          temperature: { qty: 94, units: DEGREES_C },
          duration: { qty: 1, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 5, units: SECONDS }
        },
        step4: {
          temperature: { qty: 57, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { 
          goto: 3, times: 50 
        }
      }
    },
    'Modified_CDC_Exp_3' => {
      program_template_name: 'Modified_CDC',
      layout_template_name: 'Modified_CDC',
      volume: 20,
      steps: {
        step1: {
          temperature: { qty: 55, units: DEGREES_C },
          duration: { qty: 10, units: MINUTES }
        },
        step2: {
          temperature: { qty: 94, units: DEGREES_C },
          duration: { qty: 1, units: MINUTES }
        },
        step3: {
          temperature: { qty: 95, units: DEGREES_C },
          duration: { qty: 5, units: SECONDS }
        },
        step4: {
          temperature: { qty: 57, units: DEGREES_C },
          duration: { qty: 30, units: SECONDS }
        },
        step5: { 
          goto: 3, times: 50 
        }
      }
    },
    'duke_anneal_rna' => {
      program_template_name: 'Anneal',
      layout_template_name: 'Anneal',
      volume: 20,
      steps: {}
    },
    'duke_synthesize_fs' => {
      program_template_name: 'FSS',
      layout_template_name: 'FSS',
      volume: 20,
      steps: {}
    },
    'duke_amplify_cdna' => {
      program_template_name: 'PCR',
      layout_template_name: 'PCR',
      volume: 20,
      steps: {}
    },
    'duke_tagment_pcr_amplicons' => {
      program_template_name: 'TAG',
      layout_template_name: 'TAG',
      volume: 20,
      steps: {}
    },
    'duke_amplify_tagmenteed_amplicons' => {
      program_template_name: 'TAG PCR',
      layout_template_name: 'TAG PCR',
      volume: 20,
      steps: {}
    }
  }.freeze

  private_constant :COMPONENTS

  # Gets the Hash that defines the compostion for the given name
  #
  # @param name [String]
  # @return [Hash]
  def get_composition_def(name:)
    COMPONENTS[name]
  end
end
