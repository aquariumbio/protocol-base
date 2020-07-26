var config = {

  tagline: "The Laboratory</br>Operating System",
  documentation_url: "http://localhost:4000/aquarium",
  title: "Aquarium Microtiter Plates",
  navigation: [

    {
      category: "Overview",
      contents: [
        { name: "Introduction", type: "local-md", path: "README.md" },
        { name: "About this Workflow", type: "local-md", path: "ABOUT.md" },
        { name: "License", type: "local-md", path: "LICENSE.md" },
        { name: "Issues", type: "external-link", path: 'https://github.com/aquariumbio/microtiter-plates/issues' }
      ]
    },

    

      {

        category: "Operation Types",

        contents: [

          
            {
              name: 'Microtiter Plate Test',
              path: 'operation_types/Microtiter_Plate_Test' + '.md',
              type: "local-md"
            },
          

        ]

      },

    

    

      {

        category: "Libraries",

        contents: [

          
            {
              name: 'MicrotiterPlates',
              path: 'libraries/MicrotiterPlates' + '.html',
              type: "local-webpage"
            },
          
            {
              name: 'PlateLayoutGenerator',
              path: 'libraries/PlateLayoutGenerator' + '.html',
              type: "local-webpage"
            },
          

        ]

    },

    

    
      { category: "Sample Types",
        contents: [
          
            {
              name: 'Master Mix',
              path: 'sample_types/Master_Mix'  + '.md',
              type: "local-md"
            },
          
            {
              name: 'qPCR Reaction',
              path: 'sample_types/qPCR_Reaction'  + '.md',
              type: "local-md"
            },
          
        ]
      },
      { category: "Containers",
        contents: [
          
            {
              name: '96-well qPCR Plate',
              path: 'object_types/96-well_qPCR_Plate'  + '.md',
              type: "local-md"
            },
          
        ]
      }
    

  ]

};
