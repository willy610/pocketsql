class ExecuteQr
  def exec_where(outer_row : Array(OuterRow), where_clause : QR::QRWhere) : ConditionResult
    if !(first_cond_expr = where_clause.first_cond_expr)
      raise "exec_where() Missing condition"
    end

    left = exec_scalarexpr(outer_row, first_cond_expr.left_scalaritem)
    right = exec_scalarexpr(outer_row, first_cond_expr.right_scalaritem)
    sofar = eval_cond_expr(left, right, first_cond_expr.oper)
    where_clause.more_cond_expr.each { |a_QRMoreCondExpr|
      and_or_or = a_QRMoreCondExpr.and_or_or
      if (!sofar.value) && (and_or_or == "AND")
        return ConditionResult.new(false)
      end
      if more = a_QRMoreCondExpr.more
        left = exec_scalarexpr(outer_row, more.left_scalaritem)
        right = exec_scalarexpr(outer_row, more.right_scalaritem)
        nxt_cond = eval_cond_expr(left, right, more.oper)
        if and_or_or = a_QRMoreCondExpr.and_or_or
          if and_or_or == "AND"
            sofar = ConditionResult.new(sofar.value && nxt_cond.value)
          else
            sofar = ConditionResult.new(sofar.value || nxt_cond.value)
          end
          if sofar.value == false
            return sofar
          end
        else
          raise "exec_where() Missing 'a_QRMoreCondExpr.more'"
        end
      end
    }
    return sofar
  end

  private def eval_cond_expr(left, right, opr)
    bool_res : Bool = true
    ExecuteQr.stack.push(left)
    ExecuteQr.stack.push(right)
    if opr.is_a?(QR::QRDualCompareOperation)
      left_tos = ExecuteQr.stack.get_below_top
      right_tos = ExecuteQr.stack.get_top
      if opr.value == "IN" && (left_tos.is_a?(LiteralValue) || left_tos.is_a?(NumericValue)) && right_tos.is_a?(ResultSet)
        if right_tos.rows.flatten.includes?(left_tos.value)
          bool_res = true
        else
          bool_res = false
        end
      elsif opr.value == "NOT IN" && (left_tos.is_a?(LiteralValue) || left_tos.is_a?(NumericValue)) && right_tos.is_a?(ResultSet)
        if right_tos.rows.flatten.includes?(left_tos.value)
          bool_res = false
        else
          bool_res = true
        end
      elsif opr.value == "LIKE"
        regex = Regex.new(right_tos.value.to_s)
        bool_res = left_tos.value.to_s.matches?(regex)
      elsif left_tos.isNumeric == true && right_tos.isNumeric == true
        left_value = left_tos.to_num
        right_value = right_tos.to_num
        case opr.value
        when "="
          bool_res = left_value == right_value
        when "!="
          bool_res = left_value != right_value
        when ">"
          bool_res = left_value > right_value
        when ">="
          bool_res = left_value >= right_value
        when "<"
          bool_res = left_value < right_value
        when "<="
          bool_res = left_value <= right_value
        when "IN"
          debugger
        end
      elsif left_tos.is_a?(LiteralValue) && right_tos.is_a?(LiteralValue)
        left_value = left_tos.value
        right_value = right_tos.value
        case opr.value
        when "="
          bool_res = left_value == right_value
        when "!="
          bool_res = left_value != right_value
        when ">"
          bool_res = left_value > right_value
        when ">="
          bool_res = left_value >= right_value
        when "<"
          bool_res = left_value < right_value
        when "<="
          bool_res = left_value <= right_value
        when "IN"
          debugger
        end
      else
        pp left_tos
        pp right_tos
        pp left
        pp right
        raise "exec_where() Tos [0..-1] different types"
      end
      ExecuteQr.stack.pop
      ExecuteQr.stack.pop
      ExecuteQr.stack.push(ConditionResult.new(bool_res))
    else
      pp opr
      raise "exec_where() unknown opr '#{opr}'"
    end

    tops = ExecuteQr.stack.get_top
    if tops.is_a?(ConditionResult)
      return tops
    else
      raise "exec_where() bad result of ExecuteQr.stack #{ExecuteQr.stack}"
    end
  end
end
