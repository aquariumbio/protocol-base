## Centrifuges
This class enables easy use of any centrifuge

The easiest way to use this class is to simply call the `spin_down` method.
```Ruby
show do
  title 'Example Shake'
  note spind_down(items: [item1, item2, item3],
                  speed: {qty: 3000, units: RPM,
                  time: {qty: 3, units: MINUTES,
                  type: nil)
end
```
output:
```
Example Shake
Set Medium Centrifuge to 3000 RPM
Set time to 3 min
Load the following items into Medium Centrifuge
 - Item 1
 - Item 2
 - Item 3
```
- `items` any list of Strings or objects that have to_string method.  Typically an item
- `speed` optional, given in RPM in the [Standard Libs/Units](/docs/standard_libraries/units.md) format `{qty: 2200, units: RPM}`
- `time` optional, given in the [Standard Libs/Units](/docs/standard_libraries/units.md) format
- `type` optional, specify what centrifuge is desired.  Use the class variable name to specify type (e.g. `Medium::NAME`)

This method will find the best centrifuge available based on given speed.  If no speed is given then it will choose a default small centrifuge.  If type is specified then will use given type as long as speed (if given) is less than max speed of shaker.

If no speed is specified then a default small centrifuge will be used.

If no time is specified then there will be no instructions to set the time.

