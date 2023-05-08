# require "./QR"
require "../qr"
require "./aggrfunc"

class ExecuteQr
  def exec_groupby(sqr : QR::SubQuery,
                   in_result_set : ResultSet)
    if sqr.groupby.nil?
      having_groupby = false
    else
      having_groupby = true
    end
    if sqr.aggr_funcs_in_project.nil?
      have_aggr_funcs_in_project = false
    else
      have_aggr_funcs_in_project = true
    end

    pick_keys_2_group = [] of {tbl_indx: Int32, col_indx: Int32, tbl: String, col: String}
    the_groups_with_aggr = Hash(Array(String), Array(Tuple(Int32, Int32, AggrFunc))).new
    the_groups_without_aggr = Set(Array(String)).new
    aggr_without_groupby : Array(Tuple(Int32, Int32, AggrFunc)) = [] of Tuple(Int32, Int32, AggrFunc)

    # ==================================================================
    # Generate a source on aggregates to be used for each new key for a groupby
    # ==================================================================
    aggr_content_4_each_group_scheleton = ->{
      if aggr_funcs_in_project = sqr.aggr_funcs_in_project
        aggr_funcs_in_project.map { |x|
          index_table = [] of Array({Int32, Int32, AggrFunc})
          index_table = in_result_set.tablenames.map { |tblname| tblname }.index(x[:look_up_table])
          if !index_table.nil?
            index_column = in_result_set.colnames[index_table].index(x[:look_up_colname])
            if index_column.nil?
              raise "exec_groupby() Cannot find 'tbl.col' for #{x[:look_up_table]}.#{x[:look_up_colname]}"
            end
          else
            raise "exec_groupby() Cannot find 'tbl' for #{x[:look_up_table]}"
          end
          {index_table, index_column, AggrFunc.new(x[:func])}
        }
      else
        raise "aggr_content_4_each_group_scheleton() No aggr_funcs_in_project"
      end
    }
    # ==================================================================
    # Build index for picking values from resultset into the group key
    # ==================================================================

    if the_group_by = sqr.groupby
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp the_group_by

      pick_keys_2_group = the_group_by.map { |a_GroupBy|
        # pp a_GroupBy
        index_table = in_result_set.tablenames.map { |tblname| tblname }.index(a_GroupBy.table)
        if !index_table.nil?
          index_column = in_result_set.colnames[index_table].index(a_GroupBy.column)
          if !index_column.nil?
            {tbl_indx: index_table, col_indx: index_column, tbl: a_GroupBy.table, col: a_GroupBy.column}
          else
            raise "exec_groupby() Cannot find #{a_GroupBy.table}.#{a_GroupBy.column}}"
          end
        else
          raise "exec_groupby() Cannot find #{a_GroupBy.table}.#{a_GroupBy.column}}"
        end
      }
    end
    # ==================================================================
    # Prepare resultset to return
    # ==================================================================
    ret_result = ResultSet.new
    ret_result.isAggregation = true
    ret_result.tablenames = ["FROMAGGRORGROUPBY"]
    if sqrgroupby = sqr.groupby
      fromgrp = sqrgroupby.map { |a_GroupBy|
        "#{a_GroupBy.table}.#{a_GroupBy.column}"
      }
    else
      fromgrp = [] of String
    end
    if sqr_aggr_funcs_in_project = sqr.aggr_funcs_in_project
      fromaggr = sqr_aggr_funcs_in_project.map { |a_tuple|
        a_tuple[:generated_aggr_name]
      }
    else
      fromaggr = [] of String
    end
    # puts "!" + __FILE__ + ":" + __LINE__.to_s
    # pp fromaggr

    ret_result.colnames = [[fromgrp, fromaggr].flatten]
    # puts "!" + __FILE__ + ":" + __LINE__.to_s
    # pp ret_result.colnames

    the_group_key = [] of String
    # ==================================================================
    # Here we start iter over in resultset
    # ==================================================================
    in_result_set.rows.each { |a_ResultRow|
      # Filter on where
      if where_clause = sqr.whereexpr
        # Build an Array of OuterRows (for where)
        the_III_row = [] of OuterRow
        the_III_row = a_ResultRow.map_with_index { |_, i|
          outer = OuterRow.new(in_result_set.tablenames[i],
            in_result_set.colnames[i],
            a_ResultRow[i])
        }
        res = exec_where(the_III_row, where_clause)
        if res.is_a?(ConditionResult)
          if res.value == false
            next # skip this row
          end
        else
          raise "subqr() exec_where must reust in a 'ConditionResult'"
        end
      end
      # Filter done
      #
      # Start group by

      if having_groupby
        the_group_key = pick_keys_2_group.map { |a_Tuple|
          # {tbl_indx: Int32, col_indx: Int32, tbl: String, col: String}
          if !a_Tuple.nil?
            a_ResultRow[a_Tuple[:tbl_indx]][a_Tuple[:col_indx]]
          else
            raise "exec_groupby () value not found"
          end
        }
      end
      if have_aggr_funcs_in_project && having_groupby
        # SELECT a,b,MAX(c) .. GROUP BY (a,b)
        aggrdata = the_groups_with_aggr[the_group_key]?
        if aggrdata.nil?
          # First time this key
          first_skeleton = aggr_content_4_each_group_scheleton.call
          first_skeleton.each { |a_Tuple|
            # Tuple(Int32, Int32, AggrFunc)
            val = a_ResultRow[a_Tuple[0]][a_Tuple[1]]
            a_Tuple[2].new_value(val)
          }
          the_groups_with_aggr[the_group_key] = first_skeleton
        else
          # We have seen this key earlier
          aggrdata.each { |a_Tuple|
            val = a_ResultRow[a_Tuple[0]][a_Tuple[1]]
            a_Tuple[2].new_value(val)
          }
          the_groups_with_aggr[the_group_key] = aggrdata
        end
      end
      if have_aggr_funcs_in_project == false && having_groupby
        # SELECT a,b .. GROUP BY (a,b)
        # SELCT DISTINCT a,b ..
        the_groups_without_aggr.add(the_group_key)
      end
      if have_aggr_funcs_in_project && having_groupby == false
        # SELECT MAX(col1),MIN(col2).. "NOGROUPBY"
        # first call ?
        if aggr_without_groupby.size == 0
          aggr_without_groupby = aggr_content_4_each_group_scheleton.call
        end
        aggr_without_groupby.each { |a_Tuple|
          val = a_ResultRow[a_Tuple[0]][a_Tuple[1]]
          a_Tuple[2].new_value(val)
        }
      end
    }

    if having_groupby == true && have_aggr_funcs_in_project == true
      the_groups_with_aggr.each { |groupkey, aggrvalues|
        ret_result.rows << [[groupkey.map { |kpart| kpart },
                             aggrvalues.map { |acol| acol[2].get_value.to_s }].flatten]
      }
    end
    if having_groupby == true && have_aggr_funcs_in_project == false
      the_groups_without_aggr.each { |set_member|
        ret_result.rows.push([set_member])
      }
    end
    if having_groupby == false && have_aggr_funcs_in_project == true
      ret_result.rows << [aggr_without_groupby.map { |acol| acol[2].get_value.to_s }]
    end
    ret_result
  end
end
