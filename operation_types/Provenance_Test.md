# Provenance Test

Documentation here. Start with a paragraph, not a heading or title, as in most views, the title will be supplied by the view.
### Inputs


- **Input** [X]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer/Probe Mix")'>Primer/Probe Mix</a> / <a href='#' onclick='easy_select("Containers", "Lyophilized Primer Mix")'>Lyophilized Primer Mix</a>



### Outputs


- **Output 1** [Y1]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer/Probe Mix")'>Primer/Probe Mix</a> / <a href='#' onclick='easy_select("Containers", "Primer Mix Aliquot")'>Primer Mix Aliquot</a>

- **Output 2** [Y2]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer/Probe Mix")'>Primer/Probe Mix</a> / <a href='#' onclick='easy_select("Containers", "Primer Mix Aliquot")'>Primer Mix Aliquot</a>

- **Output 3** [Y3]  
  - <a href='#' onclick='easy_select("Sample Types", "Primer/Probe Mix")'>Primer/Probe Mix</a> / <a href='#' onclick='easy_select("Containers", "Primer Mix Aliquot")'>Primer Mix Aliquot</a>

### Precondition <a href='#' id='precondition'>[hide]</a>
```ruby
def precondition(_op)
  true
end
```

### Protocol Code <a href='#' id='protocol'>[hide]</a>
```ruby
# typed: false
# frozen_string_literal: true

needs 'Standard Libs/AssociationManagement'
needs 'Standard Libs/Debug'

class Protocol

  include AssociationManagement
  include PartProvenance
  include Debug

  def main

    operations.make

    input_item = operations.first.input('Input').item
    input_item.associate(:foo, 'bar')

    output_items = [
      operations.first.output('Output 1').item,
      operations.first.output('Output 2').item,
      operations.first.output('Output 3').item
    ]

    output_items.zip(['bax', 'bay', 'baz']).each do |a, b|
      a.associate(:foo, b)
    end

    output_items.each do |output_item|
      add_one_to_one_provenance(from_item: input_item, to_item: output_item)
      inspect input_item.associations, 'input'
      inspect output_item.associations, 'output'
    end

    {}

  end

  # Add provenance data to a source-destination pair of items
  #
  # @param from_item [Item]
  # @param to_item [Item]
  # @param additional_relation_data [serializable object] additional data that
  #   will be added to the provenace association
  # @return [void]
  def add_one_to_one_provenance(from_item:, to_item:,
                                additional_relation_data: nil)
    from_map = AssociationMap.new(from_item)
    to_map = AssociationMap.new(to_item)

    add_provenance(
      from: from_item, from_map: from_map,
      to: to_item, to_map: to_map,
      additional_relation_data: additional_relation_data
    )
    from_map.save
    to_map.save
  end

end

```
