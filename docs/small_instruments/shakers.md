## Shakers
This class includes use of full size adjustable shakers, vortexers, and inversion to mix (by hand).

The easiest way to use this class is to simply call the `shake` method.
```Ruby
show do
  title 'Example Shake'
  note shake(items: [item1, item2, item3],
             speed: {qty: 30, units: RPM,
             time: {qty: 3, units: MINUTES,
             type: nil)
end
```
output:
```
Example Shake
Set Generic Shaker speed to 30 RPM
Set time to 3 min
Load the following items into Generic Shaker
 - Item 1
 - Item 2
 - Item 3
```
- `items` any list of Strings or objects that have to_string method.  Typically an item
- `speed` optional, given in RPM in the [Standard Libs/Units](/docs/standard_libraries/units.md) format `{qty: 2200, units: RPM}`
- `time` optional, given in the [Standard Libs/Units](/docs/standard_libraries/units.md) format
- `type` optional, specify what shaker, vortexer, or inversion by hand is desired.  Use the class variable name to specify type (e.g. `BasicShaker::NAME`)

This method will find the best shaker available based on given speed.  If no speed is given then it will vortex.  If type is specified then will use given type as long as speed (if given) is less than max speed of shaker.

If no speed is specified then a default shaker will be used and there will be no instructions to set speed.

If no time is specified then there will be no instructions to set the time.

---

If vortexer is specifically desired either use `shake` and specify the `Vortex::NAME`.  Or use the `vortex` method
```Ruby
show do
  title 'Example Vortex'
  note vortex(items)
end
```
Output:
```
Example Vortex
Please vortex the following items
 - Item 1
 - Item 2
 - Item 3
```
---

If mixing by inversion is desired either use `shake` and specify `Inversion:NAME` or use the `inversion` method.

```Ruby
show do
  title 'Example Inversion'
  note inversion(items)
end
```
Output:
```
Example Shake
Please mix by inversion
 - Item 1
 - Item 2
 - Item 3
```
