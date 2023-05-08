class Parse
  def r_scalaroper_Lx : AbsSyntTree
    as_LEX = AbsSyntTree.new("lexem", "r_scalaroper_Lx", "")
    to_ret : String = ""
    to_ret += @ch
    if @ch == '+'
      r_in_must_and_nowhite_next('+')
      as_LEX.value = "+"
    elsif @ch == '-'
      r_in_must_and_nowhite_next('-')
      as_LEX.value = "-"
    elsif @ch == '/'
      r_in_must_and_nowhite_next('/')
      as_LEX.value = "/"
    elsif @ch == '*'
      r_in_must_and_nowhite_next('*')
      as_LEX.value = "*"
    elsif (@ch == '|' && in_res_oper("||", false))
      in_res_word("||")
      as_LEX.value = "||"
    else
      error(%{no choice of @ch == '+'
@ch == '-' @ch == '/' @ch == '*' @resword == '||'}) # 34;
    end
    in_white()
    return as_LEX
  end

  def first_in_r_scalaroper_Lx : Bool
    if @ch == '+' || @ch == '-' || @ch == '/' || @ch == '*' || (@ch == '|' && in_res_oper("||", false))
      return true # TAG 46
    else
      return false
    end
  end
end
