# [Composition Libs](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs)

The [Composition Libs](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs) are a series of libraries developed to help manage item requirements for specific reactions.  These libraries do not include any information on how to perform a reaction, it is simply a recipe for what is needed.

Reference the [Covid Genome Protocols](https://github.com/aquariumbio/aq-genome-center) for examples on how these libraries should be used.

A [Composition](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/composition) is a list of components.  The **Composition** class enables easy actions on this list such as: 
- Search
- Volume adjustment (based on number of required reactions)

A [Component](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/component) is a single Item with relevant volume information required for a specific [Composition](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/composition).  A [Component](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/component) contains information such as: 

- input_name (name of Component in Composition)
- qty (volume required for this specific Composition in the [StandardLibs/Units](https://github.com/aquariumbio/protocol-base/tree/main/standard_libs/libraries/units) format)
- Item (Aquarium Item)
- Notes (Any specific applicable notes for this Composition)

Two different reactions may use the same Item however they will have a different [Composition](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/composition) and a different [Component](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/component) associated with that Item. (e.g. Water may be used in many different reactions but each reaction uses water at different volumes/different ways).


Reference the [CompositionDefinitions](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/composition) library for examples of the Composition/Component data structure.

The [CompositionHelper](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/compositionhelper) contains many helpful methods for use with Compositions.

The [MasterMix](https://github.com/aquariumbio/protocol-base/tree/main/composition_libs/libraries/mastermixhelper) library helps manage compositions with master mixes.   You can select a subsection of the components to include in the master mix.s