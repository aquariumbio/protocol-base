# typed: false
# frozen_string_literal: true

needs 'Standard Libs/AssociationManagement'

class Protocol
  include AssociationManagement

  def main
    rval = { foo: 'bar' }
    operations.make

    op = operations.first

    ##### TEST ASSOCIATE DATA #####
    # test associate_data to plan
    pln = op.plan
    associate_data(pln, 'assoc_to_plan', 'good')
    rval[:assoc_to_plan] = pln.get(:assoc_to_plan)

    fv = op.input('Test Container Input')
    # test associate_data to item
    associate_data(fv.item, 'assoc_to_item', 'good')
    rval[:assoc_to_item] = fv.item.get(:assoc_to_item)
    # test associate_data to non-collection field value
    associate_data(fv, 'assoc_to_noncol_fv', 'good')
    rval[:assoc_to_noncol_fv] = fv.item.get(:assoc_to_noncol_fv)

    fv = op.input('Test Part Input')
    # test associate_data to collection field value
    associate_data(fv, 'assoc_to_col_fv', 'good')
    rval[:assoc_to_col_fv] = fv.part.get(:assoc_to_col_fv)
    # test associate_data to by coord
    opts = { coord: [fv.row, fv.column] }
    associate_data(fv.collection, 'assoc_by_coord', 'good', opts)
    rval[:assoc_by_coord] = fv.part.get(:assoc_by_coord)
    # test associate_data to part
    associate_data(fv.part, 'assoc_to_part', 'good')
    rval[:assoc_to_part] = fv.part.get(:assoc_to_part)

    ##### TEST GET DATA #####
    # test get_associated_data from plan
    pln = op.plan
    d = get_associated_data(pln, 'assoc_to_plan')
    rval[:get_from_plan] = d

    fv = op.input('Test Container Input')
    # test get_associated_data from item
    d = get_associated_data(fv.item, 'assoc_to_item')
    rval[:get_from_item] = d
    # test get_associated_data from non-collection field value
    d = get_associated_data(fv, 'assoc_to_noncol_fv')
    rval[:get_from_noncol_fv] = d

    fv = op.input('Test Part Input')
    # test get_associated_data from collection field value
    d = get_associated_data(fv, 'assoc_to_col_fv')
    rval[:get_from_col_fv] = d
    # test get_associated_data by coord
    opts = { coord: [fv.row, fv.column] }
    d = get_associated_data(fv.collection, 'assoc_by_coord', opts)
    rval[:get_from_coord] = d
    # test get_associated_data from part
    d = get_associated_data(fv.part, 'assoc_to_part')
    rval[:get_from_part] = d


    ##### TEST PROVENANCE #####
    # test from_obj_to_obj_provenance
    src = op.input('Test Container Input').item
    dst = op.output('Test Container Output').item
    from_obj_to_obj_provenance(from_item: src, to_item: dst)
    rval[:test_cont_in_item_id] = src.id
    rval[:cont_prov_src_id] = dst.get(:source)

    rval
  end
end
