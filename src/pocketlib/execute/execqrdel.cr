require "./tabledelete"
class ExecuteQr
  def qrdel(qr : QR::QDelete, dest_tbl_obj)
    rows_for_delete : Array(OuterRow) = [] of OuterRow

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
            next # ROW
          else
            # collect for delete row
            rows_for_delete << as_OuterRow[0].dup
          end
        end
      }
      if rows_for_delete.size > 0
        dest_tbl_obj.qr_delete_rows(rows_for_delete)
      end
    end
  end
end
