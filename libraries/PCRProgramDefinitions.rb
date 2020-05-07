needs "Standard Libs/Units"

module PCRProgramDefinitions
  
  include Units
  
  PROGRAMS = {
    "qPCR1" => {
      program_template_name: "NGS_qPCR1", volume: 32, layout_template_name: "NGS_qPCR1",
      steps: {
        step1: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: MINUTES}},
        step2: {temperature: {qty: 98, units: DEGREES_C}, duration: {qty: 15, units: SECONDS}},
        step3: {temperature: {qty: 62, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step4: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step5: {goto: 2, times: 34},
        step6: {temperature: {qty: 12, units: DEGREES_C}, duration: {qty: "forever", units: ""}}
      }
    },

    "qPCR2" => {
      program_template_name: "NGS_qPCR2", volume: 50, layout_template_name: "NGS_qPCR1",
      steps: {
        step1: {temperature: {qty: 98, units: DEGREES_C}, duration: {qty:  3, units: MINUTES}},
        step2: {temperature: {qty: 98, units: DEGREES_C}, duration: {qty: 15, units: SECONDS}},
        step3: {temperature: {qty: 64, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step4: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step5: {goto: 2, times: 29},
        step6: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty:  5, units: MINUTES}},
        step7: {temperature: {qty: 12, units: DEGREES_C}, duration: {qty: "forever", units: ""}}
      }
    },

    "lib_qPCR1" => {
      program_template_name: "LIB_qPCR1", volume: 25, layout_template_name: "LIB_qPCR",
      steps: {
        step1: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: MINUTES}},
        step2: {temperature: {qty: 98, units: DEGREES_C}, duration: {qty: 15, units: SECONDS}},
        step3: {temperature: {qty: 65, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step4: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step5: {goto: 2, times: 34},
        step6: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty:  5, units: MINUTES}},
        step7: {temperature: {qty: 12, units: DEGREES_C}, duration: {qty: "forever", units: ""}}
      }
    },

    "lib_qPCR2" => {
      program_template_name: "LIB_qPCR2", volume: 50, layout_template_name: "LIB_qPCR",
      steps: {
        step1: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: MINUTES}},
        step2: {temperature: {qty: 98, units: DEGREES_C}, duration: {qty: 15, units: SECONDS}},
        step3: {temperature: {qty: 65, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step4: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step5: {goto: 2, times: 34},
        step6: {temperature: {qty: 72, units: DEGREES_C}, duration: {qty:  5, units: MINUTES}},
        step7: {temperature: {qty: 12, units: DEGREES_C}, duration: {qty: "forever", units: ""}}
      }
    },

    "illumina_qPCR_quantification" => {
      program_template_name: "illumina_qPCR_quantification_v1", 
      layout_template_name: "illumina_qPCR_plate_layout_v1"
    },

    "CDC_TaqPath_CG" => {
      program_template_name: "CDC_TaqPath_CG", volume: 20, layout_template_name: "CDC_TaqPath_CG",
      steps: {
        step1: {temperature: {qty: 25, units: DEGREES_C}, duration: {qty:  2, units: MINUTES}},
        step2: {temperature: {qty: 50, units: DEGREES_C}, duration: {qty: 15, units: MINUTES}},
        step3: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  2, units: MINUTES}},
        step4: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: SECONDS}},
        step5: {temperature: {qty: 55, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
        step6: {goto: 4, times: 44}
      }
    },

    "CDC_qScript_XLT_ToughMix" => {
      program_template_name: "CDC_qScript_XLT_ToughMix", volume: 20, layout_template_name: "CDC_qScript_XLT_ToughMix",
      step1: {temperature: {qty: 50, units: DEGREES_C}, duration: {qty: 10, units: MINUTES}},
      step2: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: MINUTES}},
      step3: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: SECONDS}},
      step4: {temperature: {qty: 55, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
      step5: {goto: 3, times: 44}
    },

    "CDC_UltraPlex_ToughMix" => {
      program_template_name: "CDC_UltraPlex_ToughMix", volume: 20, layout_template_name: "CDC_UltraPlex_ToughMix",
      step1: {temperature: {qty: 50, units: DEGREES_C}, duration: {qty: 10, units: MINUTES}},
      step2: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: MINUTES}},
      step3: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: SECONDS}},
      step4: {temperature: {qty: 55, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
      step5: {goto: 3, times: 44}
    },

    "CDC_GoTaq_Probe_1-Step" => {
      program_template_name: "CDC_GoTaq_Probe_1-Step", volume: 20, layout_template_name: "CDC_GoTaq_Probe_1-Step",
      step1: {temperature: {qty: 45, units: DEGREES_C}, duration: {qty: 15, units: MINUTES}},
      step2: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  2, units: MINUTES}},
      step3: {temperature: {qty: 95, units: DEGREES_C}, duration: {qty:  3, units: SECONDS}},
      step4: {temperature: {qty: 55, units: DEGREES_C}, duration: {qty: 30, units: SECONDS}},
      step5: {goto: 3, times: 44}
    }
  }

  def get_program_def(name:)
    PCRProgramDefinitions::PROGRAMS[name]
  end

end