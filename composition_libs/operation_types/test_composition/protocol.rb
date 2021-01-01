# frozen_string_literal: true

needs 'Composition Libs/Composition'
needs 'Standard Libs/TestFixtures'
needs 'Standard Libs/Units'

class Protocol
  include TestFixtures
  include Units

  FOO = 'Foo'
  BAR = 'Bar'
  BAZ = 'Baz'

  def main
    rval = assertions_framework
    @assertions = rval[:assertions]

    composition = CompositionFactory.build(
      component_data: component_data
    )

    test_display_name(composition: composition)

    test_sum_components(composition: composition)

    test_volume(composition: composition)

    test_add_in_table(composition: composition)

    test_added?(composition: composition)

    test_added_components(composition: composition)

    test_sum_added_components(composition: composition)

    test_component_item_equals(composition: composition)

    test_component_sample(composition: composition)

    test_items(composition: composition)

    test_all_input_names(composition: composition)

    rval
  end

  def test_sum_components(composition:)
    @assertions[:assert_equal].append([
      composition.sum_components,
      component_data.map { |_, v| v[:qty] }.reduce(:+).round(1),
      'sum_components'
    ])
  end

  def test_volume(composition:)
    @assertions[:assert_equal].append([
      composition.volume,
      component_data.map { |_, v| v[:qty] }.reduce(:+).round(1),
      'volume'
    ])
  end

  def test_add_in_table(composition:)
    @assertions[:assert_equal].append([
      composition.input(FOO).add_in_table,
      { content: component_data[:foo][:qty].round(1), check: true },
      'add_in_table'
    ])
  end

  def test_added?(composition:)
    @assertions[:assert_equal].append([
      composition.input(FOO).added?,
      true,
      'added?'
    ])
    @assertions[:assert_equal].append([
      composition.input(BAR).added?,
      false,
      'not added?'
    ])
  end

  def test_added_components(composition:)
    @assertions[:assert].append([
      composition.added_components.length == 1,
      'added_components'
    ])
  end

  def test_display_name(composition:)
    @assertions[:assert_equal].append([
      composition.input(BAR).display_name,
      BAR,
      'added_components'
    ])
  end

  def test_sum_added_components(composition:)
    @assertions[:assert_equal].append([
      composition.sum_added_components,
      component_data[:foo][:qty].round(1),
      'sum_added_components'
    ])
  end

  def test_component_item_equals(composition:)
    item = generic_item
    composition.input(BAZ).item = item
    @assertions[:assert_equal].append([
      composition.input(BAZ).item,
      item,
      'component.item='
    ])
  end

  def test_component_sample(composition:)
    @assertions[:assert_equal].append([
      composition.input(BAZ).sample,
      composition.input(BAZ).item.sample,
      'component.sample'
    ])
  end

  def test_items(composition:)
    a = composition.items
    b = [composition.input(BAZ).item, nil, nil]
    @assertions[:assert].append([
      (a-b).blank? && a.length == b.length,
      'composition.items'
    ])
  end

  def test_all_input_names(composition:)
    a = composition.all_input_names
    b = component_data.map { |_, v| v[:input_name] }
    @assertions[:assert].append([
      (a-b).blank? && a.length == b.length,
      'composition.all_input_names'
    ])
  end

  def component_data
    {
      foo: {
        input_name: FOO,
        qty: 0.25, units: MICROLITERS
      },
      bar: {
        input_name: BAR,
        qty: 1,  units: MICROLITERS
      },
      baz: {
        input_name: BAZ,
        qty: 2,  units: MICROLITERS
      }
    }
  end
end
