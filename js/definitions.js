var config = {

  tagline: "The Laboratory</br>Operating System",
  documentation_url: "http://localhost:4000/aquarium",
  title: "Aquarium Thermocycler Models",
  navigation: [

    {
      category: "Overview",
      contents: [
        { name: "Introduction", type: "local-md", path: "README.md" },
        { name: "About this Workflow", type: "local-md", path: "ABOUT.md" },
        { name: "License", type: "local-md", path: "LICENSE.md" },
        { name: "Issues", type: "external-link", path: 'https://github.com/klavinslab/aq-thermocyclers/issues' }
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
              name: 'AbstractThermocycler',
              path: 'libraries/AbstractThermocycler' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'BioRadCFX96',
              path: 'libraries/BioRadCFX96' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'TestThermocycler',
              path: 'libraries/TestThermocycler' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'Thermocyclers',
              path: 'libraries/Thermocyclers' + '.html',
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
