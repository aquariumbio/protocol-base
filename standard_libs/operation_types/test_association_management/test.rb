# typed: false
# frozen_string_literal: true

class ProtocolTest < ProtocolTestBase
  def setup
    add_random_operations(1)
  end

  def analyze
    rval = @backtrace.last[:rval]
    rval.each { |k, v| log("#{k}: #{v}") }

    # Check that the job completed and returned the right hash
    assert_equal(@backtrace.last[:operation], 'complete')
    assert_equal(rval[:foo], 'bar')

    # Test AssociationMap.associate_data and subordinates
    assert_equal(rval[:assoc_to_noncol_fv], 'good')
    assert_equal(rval[:assoc_to_col_fv], 'good')
    assert_equal(rval[:assoc_by_coord], 'good')
    assert_equal(rval[:assoc_to_part], 'good')
    assert_equal(rval[:assoc_to_item], 'good')
    assert_equal(rval[:assoc_to_plan], 'good')

    # Test AssociationMap.get_associated_data and subordinates
    assert_equal(rval[:get_from_plan], 'good')
    assert_equal(rval[:get_from_item], 'good')
    assert_equal(rval[:get_from_noncol_fv], 'good')
    assert_equal(rval[:get_from_col_fv], 'good')
    assert_equal(rval[:get_from_coord], 'good')
    assert_equal(rval[:get_from_part], 'good')

    # Test from_obj_to_obj_provenance
    assert(rval[:cont_prov_src_id].length == 1)
    assert_equal(rval[:test_cont_in_item_id], rval[:cont_prov_src_id].first[:id])
  end
end
