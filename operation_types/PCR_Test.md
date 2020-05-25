# PCR Test

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.






### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'
needs 'PCR Libs/PCRProgram'
needs 'Thermocyclers/Thermocyclers'

class Protocol
  include ThermocyclerHelper

  def main
    composition = PCRCompositionFactory.build(
      program_name: 'qPCR1'
    )
    program = PCRProgramFactory.build(
      program_name: 'qPCR1',
      volume: composition.volume
    )

    show do
      title 'Composition and Program Test'

      note 'From the PCRProgram'
      table program.table
      note 'From the PCRComposition'
      note "Total volume: #{composition.volume}"
    end

    thermocycler = ThermocyclerFactory.build(
      model: TestThermocycler::MODEL
    )

    if thermocycler.respond_to?(:set_dye)
      show do
        title 'Thermocycler Test'

        note 'Template files:'
        note thermocycler.program_template_file(program: program)
        note thermocycler.layout_template_file(program: program)

        note 'Test image path:'
        note thermocycler.open_software_image
      end

      set_up_program(
        thermocycler: thermocycler,
        program: program,
        composition: composition,
        qpcr: true
      )

      export_measurements(thermocycler: thermocycler)
    end

    load_plate_and_start_run(
      thermocycler: thermocycler,
      experiment_filename: 'test_filename'
    )

    {}
  end
end

```
