class ExecuteQr
  def qrupd(qr : QR::QUpdate, dest_tbl_obj)
    if the_where_clause = qr.whereexpr
      the_iter = dest_tbl_obj.get_a_pk_iter
      as_OuterRow : Array(OuterRow) = dest_tbl_obj.get_an_OuterRow_template
      the_iter.each { |a_row|
        a_row.each_with_index { |_, i|
          as_OuterRow[i].the_row = a_row[i]
        }

        res = exec_where(as_OuterRow, the_where_clause)
        if res.is_a?(ConditionResult)
          if res.value == false
            next # skip
          else
            # This row might have several updates
            # Identify the row first
            try_id_row_to_delete = dest_tbl_obj.find_id_for_a_row(as_OuterRow.first)
            if id_row_to_delete = try_id_row_to_delete
              qr.settings.each { |one_QUpdateValue|
                col_name = one_QUpdateValue.colname
                result_right_value = exec_scalarexpr(as_OuterRow, one_QUpdateValue.assign_value)
                if result_right_value.is_a?(LiteralValue)
                  right_value = result_right_value.value
                  dest_tbl_obj.qr_update_row(id_row_to_delete, as_OuterRow.first, col_name, right_value)
                else
                    raise "qrupd() Right side must be of kind 'LiteralValue'"
                end
              }
            else
              raise "qrupd() Row '#{as_OuterRow.first}' not found "
            end
          end
        end
      }
    end
  end
end
