require "./execscalarexpr"

class ExecuteQr
  def exec_project(the_proj : QR::QRProject,
                   outer_row : Array(OuterRow),
                   in_result_set : ResultSet,
                   where : QR::QRWhere?,
                   having : QR::QRWhere?,
                   distinct : Bool)
    first_BBB_SuperRows = (0...in_result_set.tablenames.size - 0).map { |i|
      OuterRow.new(in_result_set.tablenames[i], in_result_set.colnames[i], [] of String)
    }
    final_result = ResultSet.new
    final_result.tablenames << the_proj.astablename
    final_result.colnames = [] of Array(String)
    # Try detrmine colnames in result.
    # There might be zero rows, so this a separat pass
    #
    # start ------
    xxx_the_result_set_cols : Array(String) = [] of String
    the_proj.columns.each { |a_QRProjectItem|
      if a_QRProjectItem.kind.is_a?(QRProjectItemKind::PWild)
        in_result_set.colnames.each { |from_one_table|
          from_one_table.each { |col| xxx_the_result_set_cols << col }
        }
      elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PTblCol) ||
            a_QRProjectItem.kind.is_a?(QRProjectItemKind::PStandardFunctionEnum) ||
            a_QRProjectItem.kind.is_a?(QRProjectItemKind::PAggregateFunctionEnum)
        #
        # Table.Colname
        xxx_the_result_set_cols << a_QRProjectItem.as_colname
        #
      elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PTblWild)
        #
        # Table.*
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        # pp first_BBB_SuperRows
        index_table = first_BBB_SuperRows.map { |sr| sr.filename }.index(a_QRProjectItem.look_up_tablename)
        if !index_table.nil?
          xxx_the_result_set_cols += first_BBB_SuperRows[index_table].colnames
        end

        #
        # xxx_the_result_set_cols << "#{a_QRProjectItem.look_up_tablename}.*"
      elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PString)
        xxx_the_result_set_cols << a_QRProjectItem.as_colname
      elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PScalarExpression)
        xxx_the_result_set_cols << a_QRProjectItem.as_colname
      elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PSelect)
        xxx_the_result_set_cols << a_QRProjectItem.as_colname
      else
        pp a_QRProjectItem
        raise "exec_project() Colname not deductable"
      end
    }
    # end headers---------
    # Each row

    in_result_set.rows.each { |a_result_row|
      the_result_set_row : TableRow = [] of String

      the_OOOIII_row = [] of OuterRow
      the_OOOIII_row = outer_row.dup
      a_result_row.each_with_index { |_, i|
        first_BBB_SuperRows[i].the_row = a_result_row[i]
        the_OOOIII_row.push(first_BBB_SuperRows[i])
      }
      if where_clause = where
        res = exec_where(the_OOOIII_row, where_clause)
        if res.is_a?(ConditionResult)
          if res.value == false
            next # ROW
          else
          end
        else
          raise "subqr() exec_where must reust in a 'ConditionResult'"
        end
      end
      #
      # We have a row from table,join or aggr
      # Pick up what we want from 'SELECT'
      #
      # if having_clause = having
      #   res = exec_where(the_OOOIII_row, having_clause)
      #   if res.is_a?(ConditionResult)
      #     if res.value == false
      #       next # ROW
      #     else
      #     end
      #   else
      #     raise "subqr() exec_where must reust in a 'ConditionResult'"
      #   end
      # end
      the_proj.columns.each { |a_QRProjectItem|
        if a_QRProjectItem.kind.is_a?(QRProjectItemKind::PWild)
          the_result_set_row = the_OOOIII_row.map { |an_OuterRow| an_OuterRow.the_row.map { |c| c } }.flatten
          #
          # *
          #
        elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PTblCol) ||
              a_QRProjectItem.kind.is_a?(QRProjectItemKind::PStandardFunctionEnum) ||
              a_QRProjectItem.kind.is_a?(QRProjectItemKind::PAggregateFunctionEnum)
          #
          # Table.Colname
          #
          # Find proper part of 'the_OOOIII_row'
          the_colvalue : String?
          if in_result_set.isAggregation
            # if the_OOOIII_row.size == 1 && (
            #      the_OOOIII_row[0].filename == "FROMAGGRORGROUPBY" ||
            #      the_OOOIII_row[0].filename == "FROMAGGRWINDOW"
            #    )
            if a_QRProjectItem.kind.is_a?(QRProjectItemKind::PStandardFunctionEnum) ||
               a_QRProjectItem.kind.is_a?(QRProjectItemKind::PAggregateFunctionEnum)
              lookupname = a_QRProjectItem.generated_aggr_name
            else
              lookupname = "#{a_QRProjectItem.look_up_tablename}.#{a_QRProjectItem.look_up_colname}"
            end
            # puts "!" + __FILE__ + ":" + __LINE__.to_s
            # puts lookupname
            index_column = the_OOOIII_row[0].colnames.index(lookupname)
            if !index_column.nil?
              the_colvalue = the_OOOIII_row[0].the_row[index_column]
            end
            if the_colvalue
              the_result_set_row << the_colvalue
            else
              puts ">>"
              pp a_QRProjectItem.kind
              pp the_OOOIII_row
              puts "<<"
              raise "subqr() Colname '#{lookupname}' not found in 'FROMAGGR*' "
            end
          else
            proj_table = a_QRProjectItem.look_up_tablename
            proj_col = a_QRProjectItem.look_up_colname
            index_table = the_OOOIII_row.map { |sr| sr.filename }.index(proj_table)
            if !index_table.nil?
              index_column = the_OOOIII_row[index_table].colnames.index(proj_col)
              if !index_column.nil?
                the_colvalue = the_OOOIII_row[index_table].the_row[index_column]
              end
            end
            if the_colvalue
              the_result_set_row << the_colvalue
            else
              puts "FAIL -------------------------"
              pp the_OOOIII_row
              pp a_QRProjectItem
              raise "subqr() Table '#{proj_table}' and Colname '#{proj_col}' not found"
            end
          end
        elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PWild)
          #
          # *
          #
          the_result_set_row = first_BBB_SuperRows.map { |a_SuperRow| a_SuperRow.the_row.map { |c| c } }.flatten
        elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PTblWild)
          #
          # Table.*
          #
          index_table = the_OOOIII_row.map { |sr| sr.filename }.index(a_QRProjectItem.look_up_tablename)
          if !index_table.nil?
            the_result_set_row += the_OOOIII_row[index_table].the_row
          end
        elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PString)
          the_result_set_row << a_QRProjectItem.literalvalue
        elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PScalarExpression)
          # puts "!"+__FILE__+":"+__LINE__.to_s
          # pp the_OOOIII_row
          r = exec_scalarexpr(the_OOOIII_row, a_QRProjectItem.scalarexp)
          if r.is_a?(NumericValue) || r.is_a?(LiteralValue)
            the_result_set_row << r.value
          else
            pp r
            raise "exec_project() got 'Set' from 'exec_scalarexpr'"
          end
        elsif a_QRProjectItem.kind.is_a?(QRProjectItemKind::PSelect)
          if the_subq = a_QRProjectItem.subq
            ret = self.subqr(the_subq, outer_row: the_OOOIII_row)
            # Ensure we got one value or null???
            single_value = ret.rows[0][0][0]
            the_result_set_row << single_value
          else
            pp a_QRProjectItem
            raise "subqr() Project failed, missing subq. a_QRProjectItem=#{a_QRProjectItem}"
          end
        else
          pp a_QRProjectItem
          raise "subqr() Project failed, a_QRProjectItem=#{a_QRProjectItem}"
        end
      }
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp the_result_set_row

      if the_result_set_row.size != 0
        if having_clause = having
          # tmp_OuterRow : OuterRow = OuterRow.new(
          #   final_result.tablenames[0],
          #   xxx_the_result_set_cols.flatten, the_result_set_row.flatten)
          # pp xxx_the_result_set_cols
          # res = exec_where([tmp_OuterRow], having_clause)
          # puts "!" + __FILE__ + ":" + __LINE__.to_s
          # pp the_OOOIII_row
          res = exec_where(the_OOOIII_row, having_clause)
          if res.is_a?(ConditionResult)
            if res.value == false
              next # ROW
            else
              final_result.rows << [the_result_set_row.flatten]
            end
          else
            raise "subqr() exec_where must reust in a 'ConditionResult'"
          end
        else
          final_result.rows << [the_result_set_row.flatten]
        end
      end
    }
    final_result.colnames = [xxx_the_result_set_cols.flatten]
    if distinct
      final_result.rows.uniq!
    end
    # puts "!" + __FILE__ + ":" + __LINE__.to_s
    # pp final_result
    return final_result
  end
end
