# Aquarium PCR Models

This set of libraries can be used to model reaction compositions and thermocycler programs for PCR. 

Reaction compositions are modeled by `class PCRComposition`, which includes descriptions of the composition like this one:

```ruby
COMPONENTS = {
        "qPCR1" => {
            polymerase:     {input_name: POLYMERASE,        qty: 16,    units: MICROLITERS},
            forward_primer: {input_name: FORWARD_PRIMER,    qty: 0.16,  units: MICROLITERS},
            reverse_primer: {input_name: REVERSE_PRIMER,    qty: 0.16,  units: MICROLITERS},
            dye:            {input_name: DYE,               qty: 1.6,   units: MICROLITERS},
            water:          {input_name: WATER,             qty: 6.58,  units: MICROLITERS},
            template:       {input_name: TEMPLATE,          qty: 7.5,   units: MICROLITERS}
        }
}
```

This model is instantiated with this composition by:

```ruby
composition = PCRComposition.new(program_name: "qPCR1")
```

Individual components are modeled by `class ReactionComponent`, which are created during initialiization of `PCRComposition`.

Reaction programs are modeled by `class PCRProgram`, which includes descriptions of the program like this one:

```ruby
PROGRAMS = {
        "qPCR1" => {
            name: "NGS_qPCR1.prcl", volume: 32, plate: "NGS_qPCR1.pltd",
            steps: {
                step1: {temp: {qty: 95, units: DEGREES_C}, time: {qty:  3, units: MINUTES}},
                step2: {temp: {qty: 98, units: DEGREES_C}, time: {qty: 15, units: SECONDS}},
                step3: {temp: {qty: 62, units: DEGREES_C}, time: {qty: 30, units: SECONDS}},
                step4: {temp: {qty: 72, units: DEGREES_C}, time: {qty: 30, units: SECONDS}},
                step5: {goto: 2, times: 34},
                step6: {temp: {qty: 12, units: DEGREES_C}, time: {qty: "forever", units: ""}}
            }
        }
}
```

Like `PCRComposition`, this model is instantiated with this program by:

```ruby
program = PCRProgram.new(program_name: "qPCR1", volume: composition.volume)
```

`PCRProgram` can automatically generate tables for `show` blocks:

```ruby
show do
    title "Program Setup"
    
    note "Enter these settings into the thermocycler:"
    table program.table
end
```

Master mixes are handled by `module MasterMixHelper`. This module contains, among other things, a method for grouping `Operations` by shared inputs, and a `show` method for making a master mix based on a `PCRComposition` object.

All three make use of the `Units` library, which, for example, renders

```ruby
volume = {qty: 6.58,  units: MICROLITERS}
Units.qty_display(volume)
```

as 6.58 µl. This is especially useful for units with greek letters, which are often lost when they are hard-coded in protocols.
