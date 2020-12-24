var config = {

  tagline: "The Laboratory</br>Operating System",
  documentation_url: "http://localhost:4000/aquarium",
  title: "Aquarium PCR Models",
  navigation: [

    {
      category: "Overview",
      contents: [
        { name: "Introduction", type: "local-md", path: "README.md" },
        { name: "About this Workflow", type: "local-md", path: "ABOUT.md" },
        { name: "License", type: "local-md", path: "LICENSE.md" },
        { name: "Issues", type: "external-link", path: 'https://github.com/aquariumbio/pcr-models/issues' }
      ]
    },

    

      {

        category: "Operation Types",

        contents: [

          
            {
              name: 'PCR Test',
              path: 'operation_types/PCR_Test' + '.md',
              type: "local-md"
            },
          

        ]

      },

    

    

      {

        category: "Libraries",

        contents: [

          
            {
              name: 'MasterMixHelper',
              path: 'libraries/MasterMixHelper' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'PCRComposition',
              path: 'libraries/PCRComposition' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'PCRCompositionDefinitions',
              path: 'libraries/PCRCompositionDefinitions' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'PCRProgram',
              path: 'libraries/PCRProgram' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'PCRProgramDefinitions',
              path: 'libraries/PCRProgramDefinitions' + '.html',
              type: "local-webpage"
            },
          

        ]

    },

    

    
      { category: "Sample Types",
        contents: [
          
        ]
      },
      { category: "Containers",
        contents: [
          
        ]
      }
    

  ]

};
