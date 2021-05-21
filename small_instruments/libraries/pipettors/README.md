## [Pipettor](https://github.com/aquariumbio/protocol-base/blob/main/small_instruments/libraries/pipettors/source.rb)
To use the pipettor class simply call `pipet` for single channel pipetting or `multichannel_pipet` for multi channel pipetting.  This will return a string with most required instructions.

Since multi channel pipetting is only used with multi well plates or tube racks it is recommended to use [Collection Transfer](https://github.com/aquariumbio/protocol-base/tree/main/collection_management/libraries/collectiontransfer) library to provide instructions for transfers.  This library utilizes the small instrument libraries but adds more context for the technician.

``` Ruby
pipet(volume: {qty: , units: },
               source: ,
               destination: ,
               type: nil)
```

`volume` can be any volume in microliter given in [Standard Libs/Units](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/units)

`source` Is any string that represents the sources that pipetting is from.  Often this is an Item however it maybe be other things such as reservoir troughs, reagent bottles, etc.

`destination` Is any string that represents where pipetting is going.  Often this is an Item however it maybe be other things such as reservoir troughs, reagent bottles, etc.

`type` Is optional.  Can be any specific SubClass of Pipettors.  THis enables the code to specify a desired subclass.  Otherwise the 'best fit' will be used.  It is usually best to call specific types using their class variable (e.g. a P200 pipette would be `P200::NAME`)

```Ruby
show block
  title 'Example Pipette'
  note pipet(volume: {qty: 3, units: MICROLITERS},
               source: 'Item 1',
               destination: 'Item 2',
               type: nil)
end
```

Output:
```
Example Pipette
"Use a P20 to pipet 3ul from Item 1 into Item 2"
```

The existing pipettor subclasses are as follows:

Multichannel
- `PA12X300` 12 channel 300ul max
- `PA6X1200` 6 channel 1200ul max
- `P8X20` 8 channel 20ul max
- `P8X200` 8 channel 200ul max

Single Channel
- `P2` 2ul max
- `P20` 20ul max
- `P200` 200ul max
- `P1000` 1000ul max
- `Pipet controller` Uses serological pipettes.


New classes can be added easily by creating a new class and adding the class to the `get_single_channel_pipettor` or `get_multi_channel_pipettor`.

```Ruby
  class new_pipettor < Pipettor
    NAME = 'new_pipettor'.freeze
    MIN_VOLUME = 0.0
    MAX_VOLUME = 1.0
    ROUND_TO = 0
    CHANNELS = 1
  end
```
- `NAME` should match the class name and **MUST** be unique
- `MIN_VOLUME` the minimum accurate volume a pipettor can transfer
- `MAX_VOLUME` the maximum volume a pipettor can transfer
- `ROUND_TO` if measurements should be rounded lists the decimal that it 
should be rounded to.  0 = no rounding.
- `CHANNELS` the number of channels a pipettor can use

The order of pipettors in this method is important.  Make sure to add new pipettors based on maximum volume.
```Ruby
 def get_single_channel_pipettor(volume:, type: nil)
    qty = type.present? ? Float::INFINITY : volume[:qty]
  
    if type == P2::NAME || qty <= 2
      P2.instance
    elsif type == P20::NAME || qty <= 20
      P20.instance
    elsif type == P200::NAME || qty <= 200
      P200.instance
    elsif type == P1000::NAME || qty <= 1000
      P1000.instance
    elsif qty <= 2000
      P1000.instance
    elsif type == PipetController::NAME || qty > 2000
      PipetController.instance
    end
  end
```

Multi channel pipettors are added here. 
```Ruby
  def get_multi_channel_pipettor(volume:, type: nil)
    qty = type.present? ? Float::INFINITY : volume[:qty]
    if type == P8X20::NAME || qty <= 20
       P8X20.instance
    elsif type == P8X200::NAME || qty <= 200
       P8X200.instance
    elsif type == PA12X300::NAME || qty <= 300
      PA12X300.instance
    elsif type == PA6X1200::NAME || qty <= 1000
      PA6X1200.instance
    end
  end
```