# Thermocyclers
Classes that provide a standard way to model different types of thermocyclers and allow them to be interchanged in protocols.

These classes all follow the same basic set up as shown in [Abstract Thermocyclers](/thermocyclers/libraries/abstractthermocycler/source.rb). Use [BioRAD CFX96](/thermocyclers/libraries/bioradcfx96/source.rb) for a good example on how to create a concrete class.

Conceptually each class should have the same external interactions.  A protocol can ask the class to `turn_on` or `open_software` and the class will return a series of string 'instructions' that should be displayed to the technician.  This enables each class to model its own specific instructions while making the interface uniform.

## Required libraries
* Standard Libraries
* [PCR Libraries](/docs/pcr_models/pcr_models.md) (for testing)

## Usage
This library provides an interface for working with multiple makes and models of thermocyclers. The goal is to provide a consistent interface for instructions on how to use the thermocycler. For example, in a protocol `show` block,

```ruby
note "Click the <b>Close Lid</b> button"
image "Actions/TestThermocycler/close_lid.png"
```
becomes
```ruby
thermocycler = ThermocyclerFactory.build(
  model: TestThermocycler::MODEL
)
.
.
.
note thermocycler.close_lid
image thermocycler.close_lid_image
```

To use a different thermocycler change `TestThermocycler::MODEL` to `BioRadCFX96::MODEL` and all of the language and image paths will be updated automatically.

There are a few parameters that must be overridden in concrete classes:

```Ruby
MODEL = '' #user defined
PROGRAM_EXT = '' #user defined
```
`MODEL` is the name/model of the thermocycler that is commonly used within the lab e.g. `BioRad CFX96`

`PROGRAM_EXT` is the file extension used for program files e.g. `.pcrd`

---

The [BioRAD CFX96](/thermocyclers/libraries/bioradcfx96/source.rb) has additional parameters that may or may not be applicable:
```Ruby
  LAYOUT_EXT =  '.pltd'
  SOFTWARE_NAME = 'CFX Manager Software'
```
`LAYOUT_EXT` is for preprogramed plate layout files that work with the BIORad software.

`SOFTWARE_NAME` is the name of the default software for the BIORad.

---

Typically the `initialize` function doesn't need to be changed so simply put:
```Ruby
  def initialize(name: 'Unnamed Thermocycler')
    super(name: name)
  end
```
`name` references the colloquial name of the thermocycler.  Some labs have multiple thermocyclers of the same type.  In this case the protocol may want to specify which specific thermocycler to use e.g. `Thermo A` or `Thermo B`.   You can set the default to anything.

---

`user_defined_params` can get quite complicated and specific to the thermocycler and largely depend on how detailed you want the 'instruction' methods to be.   If the 'instruction' methods to be simple then there may not be many `user_defined_params`.

The default parameters are shown below, however more parameters can be added as desired.
```Ruby
experiment_filepath: '',
export_filepath: '',
image_path: '',
setup_program_image: 'setup_program.png',
open_lid_image: 'open_lid.png',
close_lid_image: 'close_lid.png',
start_run_image: 'start_run.png'
```
If the thermocycler can works with multiple wells it is recommended to always include the `dimensions` parameter.  This parameter can be helpful with instructions as well as ensuring a thermocycler has enough room for all desired sample.

The [BioRAD CFX96](/thermocyclers/libraries/bioradcfx96/source.rb) goes into notable detail when creating instructions.  It even go so far as to include helpful images to the technician.  Some of the `user_defined_params` are shown here:

```Ruby
experiment_filepath: 'Desktop/_qPCR_UWBIOFAB',
export_filepath: 'Desktop/BIOFAB qPCR Exports',
image_path: 'Actions/BioRad_qPCR_Thermocycler',
open_software_image: 'open_biorad_thermo_workspace.JPG',
setup_workspace_image: 'setup_workspace.JPG',
setup_program_image: 'setting_up_qPCR_thermo_conditions.png',
setup_plate_layout_image: 'setting_up_plate_layout_v1.png',
open_lid_image: 'open_lid.png',
close_lid_image: 'close_lid.png',
start_run_image: 'start_run.png',
export_measurements_image: 'exporting_qPCR_quantification.png',
dimensions: [8, 12]
```
