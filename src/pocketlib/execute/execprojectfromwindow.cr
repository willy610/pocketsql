require "./execorderby"

class ExecuteQr
  alias AggrFuncInfo = NamedTuple(index_table: Int32, index_column: Int32, as_colname: Int32, func_name: AggregateFunctionEnum)

  def exec_project_from_window(sqr : QR::SubQuery,
                               in_result_set : ResultSet,
                               window_key_and_rows : Hash(Array(String), Array(Int32)))
    # ==================================================================
    # Generate a source on aggregates to be used for each PARTITION for a aggregate
    # ==================================================================
    aggr_content_4_each_group_scheleton = ->{
      if aggr_funcs_in_project = sqr.aggr_funcs_in_project
        aggr_funcs_in_project.map { |a_AggrFuncInCol|
          index_table = [] of Array({Int32, Int32, AggrFunc})
          index_table = in_result_set.tablenames.map { |tblname| tblname }.index(a_AggrFuncInCol[:look_up_table])
          if !index_table.nil?
            index_column = in_result_set.colnames[index_table].index(a_AggrFuncInCol[:look_up_colname])
            if index_column.nil?
              pp in_result_set.tablenames
              pp in_result_set.colnames
              pp aggr_funcs_in_project
              raise "exec_project_from_window() Cannot find #{a_AggrFuncInCol[:look_up_table]}.#{a_AggrFuncInCol[:look_up_colname]}}"
            end
          else
            pp in_result_set.tablenames
            pp aggr_funcs_in_project
            raise "exec_project_from_window() Cannot find #{a_AggrFuncInCol[:look_up_table]}.#{a_AggrFuncInCol[:look_up_colname]}}"
          end
          {table:               index_table,
           colname:             index_column,
           func:                AggrFunc.new(a_AggrFuncInCol[:func]),
           as_colname:          a_AggrFuncInCol[:look_up_colname],
           generated_aggr_name: a_AggrFuncInCol[:generated_aggr_name],
          }
        }
      else
        raise "aggr_content_4_each_group_scheleton() No aggr_funcs_in_project"
      end
    }
    # We will produce one extra column for each aggr
    # This can be seen as a join of old row columns and a new column like the result from joins
    #
    # Walk through all columns and find thoose with aggrfunction. Pick function and colname
    # pp sqr.project
    # EXTRA 'file' inresultset
    window_table_name = "NO_WINDOW_NAME"
    if sqr_window = sqr.window
      window_table_name = sqr_window.name
      window_order_by = sqr_window.orderby
    end
    ret_result = ResultSet.new
    ret_result.tablenames = ["FROMAGGRWINDOW"]
    ret_result.isAggregation = true
    aggrdata = aggr_content_4_each_group_scheleton.call

    new_cols = aggrdata.map { |some| some[:generated_aggr_name] }

    import_from_inresult = in_result_set.tablenames.map_with_index { |tbl, i|
      in_result_set.colnames[i].map { |colname| "#{tbl}.#{colname}" }
    }.flatten
    ret_result.colnames = [[import_from_inresult, new_cols].flatten]
    # ------------------------
    sorted_values = window_key_and_rows.keys.sort
    sorted_values.each { |key|
      row_nrs_in_partition = window_key_and_rows.fetch(key, nil)
      if row_nrs_in_partition.nil?
        raise "exec_project_from_window() Key not found"
      end
      # reset aggr for each partition
      aggrdata = aggr_content_4_each_group_scheleton.call
      # NOW MAKE SOME AGGR ON ONE ORE COLUMNS FOR THIS ROWS
      row_nrs_in_partition.each { |a_ResultSetRowNumber|
        # pick columns for aggr
        aggrdata.each { |a_Tuple|
          val = in_result_set.rows[a_ResultSetRowNumber][a_Tuple[:table]][a_Tuple[:colname]]
          a_Tuple[:func].new_value(val)
        }
      }
      # ADD new cols to old row
      for_sort = Array(ResultRow).new
      row_nrs_in_partition.map { |a_ResultSetRowNumber|
        aggr_cols = aggrdata.map { |acol| acol[:func].get_value.to_s }
        tmp = in_result_set.rows[a_ResultSetRowNumber]
        tmp = [tmp, aggr_cols].flatten
        if window_order_by
          for_sort << [tmp]
        else
          ret_result.rows << [tmp]
        end
      }
      # order within partition
      if window_order_by
        sorted = execorderby(window_order_by, ret_result, for_sort)
        sorted.each { |a_row|
          ret_result.rows << a_row
        }
      else
      end
    }
    return ret_result
  end
end
