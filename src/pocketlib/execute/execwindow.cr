class ExecuteQr
  def exec_window(sqr : QR::SubQuery,
                  outer_row : Array(OuterRow),
                  in_result_set : ResultSet)
    window_key_and_rows = Hash(Array(String), Array(Int32)).new
    pick_keys_2_group = [] of {tbl_indx: Int32, col_indx: Int32, tbl: String, col: String}
    # FIND INDEX TO KEYS IN PARTITION
    # pp in_result_set.colnames
    if sqr_window = sqr.window
      if sqr_window_partitionby = sqr_window.partitionby
        pick_keys_2_group = sqr_window_partitionby.map { |a_PartitionBy|
          #   pp a_PartitionBy
          index_table = in_result_set.tablenames.map { |tblname| tblname }.index(a_PartitionBy.table)
          if !index_table.nil?
            index_column = in_result_set.colnames[index_table].index(a_PartitionBy.column)
            if !index_column.nil?
              # {tbl_indx: index_table, col_indx: index_column, tbl: a_PartitionBy.table, col: a_PartitionBy.column}
              {tbl_indx: index_table, col_indx: index_column}
            else
              raise "exec_groupby() Cannot find #{a_PartitionBy.table}.#{a_PartitionBy.column}}"
            end
          else
            raise "exec_groupby() Cannot find #{a_PartitionBy.table}.#{a_PartitionBy.column}}"
          end
        }
      else
        raise "exec_window() '..partitionby' is nil"
      end
    else
      raise "exec_window() '.window' is nil"
    end # end
    first_BBB_SuperRows = (0...in_result_set.tablenames.size - 0).map { |i|
      OuterRow.new(in_result_set.tablenames[i], in_result_set.colnames[i], [] of String)
    }

    ret_result = ResultSet.new
    ret_result.tablenames = ["FROMWINDOW"]

    in_result_set.rows.each_with_index { |a_ResultRow, a_rowNumber|
      the_OOOIII_row = [] of OuterRow
      the_OOOIII_row = outer_row.dup
      a_ResultRow.each_with_index { |_, i|
        first_BBB_SuperRows[i].the_row = a_ResultRow[i]
        the_OOOIII_row.push(first_BBB_SuperRows[i])
      }

      if where_clause = sqr.whereexpr
        res = exec_where(the_OOOIII_row, where_clause)
        if res.is_a?(ConditionResult)
          if res.value == false
            next # ROW
          else
          end
        else
          raise "exec_window() exec_where must result in a 'ConditionResult'"
        end
      end
      # BUILD KEY
      this_window_partition_by_key = pick_keys_2_group.map { |x|
        tbl_indx = x[:tbl_indx]
        col_indx = x[:col_indx]
        # tbl_indx, col_indx = x
        a_ResultRow[tbl_indx][col_indx]
      }
      oldrows_with_this_key = window_key_and_rows[this_window_partition_by_key]?
      if oldrows_with_this_key.nil?
        # First time this key
        window_key_and_rows[this_window_partition_by_key] = [a_rowNumber]
      else
        oldrows_with_this_key << a_rowNumber # add one row
        window_key_and_rows[this_window_partition_by_key] = oldrows_with_this_key
      end
    }
    # pp window_key_and_rows
    # raise "NOT YET"
    # return window_key_and_rows
    return window_key_and_rows
    # raise "NOT YET"
  end

  def exec_update_projection(the_proj)
    the_proj.columns.each { |a_QRProjectItem|
      if a_QRProjectItem.aggrfunction.nil?
        # a_QRProjectItem.value = "#{a_QRProjectItem.look_up_tablename}.#{a_QRProjectItem.look_up_colname}"
        a_QRProjectItem.value = a_QRProjectItem.look_up_colname
      else
        # name given project aggr
      end
    }
  end
end
