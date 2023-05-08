class ExecuteQr
  # def exec_scalarexpr(outer_row : Array(OuterRow), scalarexpr : Array(ScalarItem)?)
  def exec_scalarexpr(outer_row : Array(OuterRow), scalarexpr : QR::QRScalarExpr | Nil)
    try_cache = ->(opr : QR::QRLoadColnameValueOntoStack) : Tuple(Bool, Int32, Int32) {
      if opr_cached_table_indx = opr.cached_table_indx
        if opr_cached_column_indx = opr.cached_column_indx
          return {true, opr_cached_table_indx, opr_cached_column_indx}
        else
        end
      else
      end
      return {false, 0, 0}
    }
    must_look_up = ->(opr : QR::QRLoadColnameValueOntoStack) : Tuple(Bool, Int32, Int32) {
      opr_cached_table_indx = 0
      while opr_cached_table_indx < outer_row.size
        if outer_row[opr_cached_table_indx].filename == opr.tablename
          if opr_cached_column_indx = outer_row[opr_cached_table_indx].colnames.index(opr.colname)
            return {true, opr_cached_table_indx, opr_cached_column_indx}
          end
        end
        opr_cached_table_indx = opr_cached_table_indx + 1
      end
      return {false, 0, 0}
    }
    # push_scalar_item = ->(item : ScalarItem | Nil) {
    push_scalar_item = ->(par_item : QR::QRScalarItem) {
      if the_item = par_item.item_QRScalarExpr
        result_set = exec_scalarexpr(outer_row, the_item)
        ExecuteQr.stack.push(result_set)
      elsif the_item = par_item.item_QRLoadColnameValueOntoStack
        the_colvalue : String = ""
        # We have been here before?
        how, opr_cached_table_indx, opr_cached_column_indx = try_cache.call(the_item)
        if how == true
        else
          how, opr_cached_table_indx, opr_cached_column_indx = must_look_up.call(the_item)
          if how == false
            raise "push_scalar_item() FAILED #{the_item}"
          end
        end
        the_colvalue = outer_row[opr_cached_table_indx].the_row[opr_cached_column_indx]
        the_item.cached_table_indx = opr_cached_table_indx
        the_item.cached_column_indx = opr_cached_column_indx
        if x = the_colvalue.to_f?
          ExecuteQr.stack.push(NumericValue.new(the_colvalue))
        else
          ExecuteQr.stack.push(LiteralValue.new(the_colvalue))
        end
      elsif the_item = par_item.item_QRLoadStringValueOntoStack
        ExecuteQr.stack.push(LiteralValue.new(the_item.value))
        #
        #
        #
      elsif the_item = par_item.item_QRLoadParamNameOnStack
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        # puts ExecuteQr.params.the_params
        indx = ExecuteQr.params.the_params.index { |a_ParamIn| a_ParamIn.paramname == the_item.paramname }
        if !indx.nil?
          the_value = ExecuteQr.params.the_params[indx].value
          if the_value.starts_with?("'")
            ExecuteQr.stack.push(LiteralValue.new(the_value.strip("'")))
          else
            ExecuteQr.stack.push(NumericValue.new(the_value))
          end
          # puts indx
          # ExecuteQr.params.the_params.each { |a_ParamIn|
          #   puts a_ParamIn.paramname
          #   if a_ParamIn.paramname == the_item.paramname
          #     puts "FOUND"
          #     puts a_ParamIn.value

          #     ExecuteQr.stack.push(NumericValue.new(a_ParamIn.value))
          #   end
          # }
        else
          raise "exec_scalarexpr() Param '#{the_item.paramname}' not found"
        end
        # ExecuteQr.stack.push(ParamName.new(the_item.paramname))
        #
        #
        #
      elsif the_item = par_item.item_QRLoadNumberValueOntoStack
        ExecuteQr.stack.push(NumericValue.new(the_item.value))
      elsif the_item = par_item.item_SubQuery
        result_set = ExecuteQr.new(@db).subqr(the_item, outer_row: outer_row.dup)
        ExecuteQr.stack.push(result_set)
      elsif the_item = par_item.item_QRProjectItem
        if the_item.kind == QRProjectItemKind::PStandardFunctionEnum
          colname = the_item.generated_aggr_name
          index_column = outer_row[0].colnames.index(colname)
          if !index_column.nil?
            the_colvalue = outer_row[0].the_row[index_column]
            if x = the_colvalue.to_f?
              ExecuteQr.stack.push(NumericValue.new(the_colvalue))
            else
              ExecuteQr.stack.push(LiteralValue.new(the_colvalue))
            end
          else
            pp outer_row
            pp the_item
            raise " colname '#{colname}' not found"
          end
        else
          raise "exec_scalarexpr () the_item=#{the_item}"
        end
      elsif the_item = par_item.item_QRLoadFileValues
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        # puts the_item
        result_set = ResultSet.new(["SET"],[["COL_1"]],[the_item.rows])
        ExecuteQr.stack.push(result_set)
        # result_set
      else
        raise "push_scalar_item() Odd item '#{par_item}'"
      end
      # raise "NOT YET"

      # if the_item = item
      #   if the_item.is_a?(QR::QRLoadColnameValueOntoStack)
      # the_colvalue : String = ""
      # # We have been here before?
      # how, opr_cached_table_indx, opr_cached_column_indx = try_cache.call(the_item)
      # if how == true
      # else
      #   how, opr_cached_table_indx, opr_cached_column_indx = must_look_up.call(the_item)
      #   if how == false
      #     raise "push_scalar_item() FAILED #{the_item}"
      #   end
      # end
      # the_colvalue = outer_row[opr_cached_table_indx].the_row[opr_cached_column_indx]
      # the_item.cached_table_indx = opr_cached_table_indx
      # the_item.cached_column_indx = opr_cached_column_indx
      # if x = the_colvalue.to_f?
      #   ExecuteQr.stack.push(NumericValue.new(the_colvalue))
      # else
      #   ExecuteQr.stack.push(LiteralValue.new(the_colvalue))
      # end
      # elsif the_item.is_a?(QR::QRLoadNumberValueOntoStack)
      #   ExecuteQr.stack.push(NumericValue.new(the_item.value))
      # elsif the_item.is_a?(QR::QRLoadStringValueOntoStack)
      #   ExecuteQr.stack.push(LiteralValue.new(the_item.value))
      # elsif the_item.is_a?(QR::SubQuery)
      #   result_set = ExecuteQr.new(@db).subqr(the_item, outer_row: outer_row.dup)
      #   ExecuteQr.stack.push(result_set)
      # elsif the_item.is_a?(QR::QRScalarExpr)
      #   # exec_scalarexpr(outer_row : Array(OuterRow), scalarexpr : QR::QRScalarExpr | Nil)
      #   result_set = exec_scalarexpr(outer_row, the_item)
      #   ExecuteQr.stack.push(result_set)
      # elsif the_item.is_a?(QR::QRProjectItem)
      #   if the_item.kind == QRProjectItemKind::PStandardFunctionEnum
      #     colname = the_item.generated_aggr_name
      #     index_column = outer_row[0].colnames.index(colname)
      #     if !index_column.nil?
      #       the_colvalue = outer_row[0].the_row[index_column]
      #       if x = the_colvalue.to_f?
      #         ExecuteQr.stack.push(NumericValue.new(the_colvalue))
      #       else
      #         ExecuteQr.stack.push(LiteralValue.new(the_colvalue))
      #       end
      #     else
      #       pp outer_row
      #       pp the_item
      #       raise " colname '#{colname}' not found"
      #     end
      #   else
      #     raise "exec_scalarexpr () the_item=#{the_item}"
      #   end
      #   else #end
      #     raise "push_scalar_item () the_item=#{the_item}"
      #   end
      # else
      #   raise "push_scalar_item() 'item' is Nil "
      # end
    }
    eval_stack = ->(the_oper : QR::QRDualScalarOperation) {
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp the_oper

      if the_oper.value == "||"
        toppen = ExecuteQr.stack.get_top
        if toppen.is_a?(LiteralValue) || toppen.is_a?(NumericValue)
          left_value = toppen.to_str
        else
          raise ""
        end
        toppen_below = ExecuteQr.stack.get_below_top
        if toppen_below.is_a?(LiteralValue) || toppen_below.is_a?(NumericValue)
          right_value = toppen_below.to_str
        else
          raise ""
        end
        ExecuteQr.stack.pop
        ExecuteQr.stack.pop
        ExecuteQr.stack.push(LiteralValue.new("#{right_value}#{left_value}"))
      elsif ExecuteQr.stack.get_top.isNumeric && ExecuteQr.stack.get_below_top.isNumeric
        left_value = ExecuteQr.stack.get_top.to_num
        right_value = ExecuteQr.stack.get_below_top.to_num
        case the_oper.value
        when "+"
          num_res = left_value + right_value
        when "-"
          num_res = right_value - left_value
        when "/"
          num_res = right_value / left_value
        when "*"
          num_res = left_value * right_value
        end
        ExecuteQr.stack.pop
        ExecuteQr.stack.pop
        ExecuteQr.stack.push(NumericValue.new(num_res.to_s))
      else
        puts "!" + __FILE__ + ":" + __LINE__.to_s
        pp ExecuteQr.stack
        pp the_oper
        raise "exec_where() Top on ExecuteQr.stack.push 0..-1 must be numeric"
      end
    }
    if the_scalarexpr = scalarexpr
      push_scalar_item.call(the_scalarexpr.first_scalar)
      the_scalarexpr.more_scalars.each { |a_QRMoreScalarExpr|
        push_scalar_item.call(a_QRMoreScalarExpr.the_scalar)
        eval_stack.call(a_QRMoreScalarExpr.the_oper)
      }
      tops = ExecuteQr.stack.get_top
      if tops.is_a?(NumericValue)
        return tops
      elsif tops.is_a?(LiteralValue)
        return tops
      else
        return tops
      end
    else
      raise "exec_scalarexpr () 'scalarexpr' is Nil"
    end

  end
end
