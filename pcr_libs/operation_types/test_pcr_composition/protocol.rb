# frozen_string_literal: true

needs 'PCR Libs/PCRComposition'
needs 'Standard Libs/TestFixtures'

class Protocol
  include PCRCompositionDefinitions
  include TestFixtures

  def main
    rval = assertions_framework
    assert_equal = rval[:assertions][:assert_equal]

    composition = PCRCompositionFactory.build(
      component_data: component_data
    )

    # Test component accessors
    assert_equal.append([composition.dye, nil, 'composition.dye not nil'])
    assert_equal.append([
      composition.polymerase.volume_hash[:qty],
      component_data[:polymerase][:qty],
      'polymerase.volume_hash[:qty]'
    ])
    assert_equal.append([
      composition.polymerase.volume_hash[:units],
      component_data[:polymerase][:units],
      'polymerase.volume_hash[:units]'
    ])
    assert_equal.append([
      composition.input(BUFFER).volume_hash[:qty],
      component_data[:buffer][:qty],
      'input(BUFFER).volume_hash[:qty]'
    ])

    # Test sum_components
    assert_equal.append([
      composition.sum_components,
      component_data.map { |_, v| v[:qty] }.reduce(:+).round(1),
      'sum_components'
    ])

    # Test volume
    assert_equal.append([
      composition.volume,
      component_data.map { |_, v| v[:qty] }.reduce(:+).round(1),
      'volume'
    ])

    # Test add_in_table and adjusted_qty
    assert_equal.append([
      composition.polymerase.add_in_table,
      { content: component_data[:polymerase][:qty].round(1), check: true },
      'add_in_table'
    ])

    # Test added?
    assert_equal.append([composition.polymerase.added?, true, 'polymerase.added?'])

    # Test added_components and display_name
    assert_equal.append([
      composition.added_components.map(&:display_name),
      [POLYMERASE],
      'added_components'
    ])

    # Test sum_added_components
    assert_equal.append([
      composition.sum_added_components,
      component_data[:polymerase][:qty].round(1),
      'sum_added_components'
    ])

    # Test component.item=
    item = generic_item
    composition.template.item = item
    assert_equal.append([
      composition.template.item,
      item,
      'component.item='
    ])

    # Test component.sample
    assert_equal.append([
      composition.template.sample,
      item.sample,
      'component.sample'
    ])

    # Test items
    a = composition.items
    b = [item, nil, nil, nil, nil]
    rval[:assertions][:assert].append([
      (a-b).blank? && a.length == b.length,
      'composition.items'
    ])

    # Test all_input_names
    a = composition.all_input_names
    b = component_data.map { |_, v| v[:input_name] }
    rval[:assertions][:assert].append([
      (a-b).blank? && a.length == b.length,
      'composition.all_input_names'
    ])

    rval
  end

  def component_data
    {
      polymerase: {
        input_name: POLYMERASE,
        qty: 0.25, units: MICROLITERS
      },
      forward_primer: {
        input_name: FORWARD_PRIMER,
        qty: 1,  units: MICROLITERS
      },
      reverse_primer: {
        input_name: REVERSE_PRIMER,
        qty: 1,  units: MICROLITERS
      },
      template: {
        input_name: TEMPLATE,
        qty: 1, units: MICROLITERS
      },
      buffer: {
        input_name: BUFFER,
        qty: 5,  units: MICROLITERS
      }
    }
  end
end
