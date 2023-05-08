class Parse
  def r_compoper_Lx : AbsSyntTree
    as_LEX = AbsSyntTree.new("lexem", "r_compoper_Lx", "")

    to_ret : String = ""
    to_ret += @ch
    if (@ch == '<' && in_res_oper("<=", false))
      in_res_word("<=")
      as_LEX.value = "<="
    elsif (@ch == '>' && in_res_oper(">=", false))
      in_res_word(">=")
      as_LEX.value = ">="
    elsif @ch == '<'
      as_LEX.value = "<"
      r_in_must_and_nowhite_next('<')
    elsif @ch == '>'
      as_LEX.value = ">"
      r_in_must_and_nowhite_next('>')
    elsif @ch == '='
      as_LEX.value = "="
      r_in_must_and_nowhite_next('=')
    elsif (@ch == '!' && in_res_oper("!=", false))
      in_res_word("!=")
      as_LEX.value = "!="
    elsif (@ch == 'I' && in_res_word("IN", false))
      
      in_res_word("IN")
      as_LEX.value = "IN"
    elsif (@ch == 'N' && in_res_word("NOT IN", false))
      in_res_word("NOT IN")
      as_LEX.value = "NOT IN"
    elsif (@ch == 'I' && in_res_word("IS", false))
      in_res_word("IS")
      as_LEX.value = "IS"
    elsif (@ch == 'L' && in_res_word("LIKE", false))
      in_res_word("LIKE")
      as_LEX.value = "LIKE"
    else
      error(%{no choice of (@ch == '<' && in_res_oper("<=",false))
(@ch == '>' && in_res_oper(">=",false))
@ch == '<'
@ch == '>'
@ch == '='
(@ch == '!' && in_res_oper("!=",false))
(@ch == 'I' && in_res_word("IN",false))
(@ch == 'I' && in_res_word("NOT IN",false))
(@ch == 'L' && in_res_word("LIKE",false))
}) # 34;
    end

    in_white()
    return as_LEX
  end

  def first_in_r_compoper_Lx : Bool
    if (@ch == '<' && in_res_word("<=", false, false)) || (@ch == '>' && in_res_word(">=", false, false)) || @ch == '<' || @ch == '>' || @ch == '=' || (@ch == '!' && in_res_word("!=", false, false))
      return true # TAG 46
    else
      return false
    end
  end
end
