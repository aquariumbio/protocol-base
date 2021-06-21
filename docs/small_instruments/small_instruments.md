# Small Instruments
Thes Small Instruments classes create interfaces for interacting with common lab instruments that have some settings, but generally lack complex programs and are not controlled by a freestanding computer. Each Instrument Type class has multiple Instrument subclasses to accommodate multiple versions of an instrument (e.g. P10, P100, P1000 pipettors). Current Instrument Type Classes include:

- [Pipettors](./pipettors.md)
- [Centrifuges](./centrifuges.md)
- [Shakers](./shakers.md)

More Instrument subclasses and Instrument Type Classes can be added, however any additional classes must follow the standard set in these existing libraries.  Many of these classes are used throughout other libraries and major changes to structure may affect multiple other sources.

These classes all return a simple String that has the required instructions for using the instrument.  Typically it is not needed to create or use the classes directly.  Instead each class has a generic action method.  This method will use the required classes and return the proper string.



