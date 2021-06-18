# Small Instruments
These classes create easy, standard ways for technicians to interact with "small instruments".  Small instruments are any common instruments that requires some settings to use but generally do not have complex computer control.  Each Instrument Type class has multiple Instrument subclasses to accommodate multiple versions of an instrument (e.g. P10, P100, P1000 pipettors).  Current Instrument Type Classes include:

- Pipettors
- Centrifuges
- Shakers

More Instrument subclasses and Instrument Type Classes can be added, however any additional classes must follow the standard set in these existing libraries.  Many of these classes are used throughout other libraries and major changes to structure may affect multiple other sources.

These classes all return a simple String that has the required instructions for using the instrument.  Typically it is not needed to create or use the classes directly.  Instead each class has a generic action method.  This method will use the required classes and return the proper string.



