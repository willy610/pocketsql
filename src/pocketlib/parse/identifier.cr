class Parse
  def r_Identifier_Lx : AbsSyntTree
    # as_AST = LexValue.new("r_Identifier_Lx")
    as_LEX = AbsSyntTree.new("lexem", "r_Identifier_Lx", "")

    to_ret : String = ""
    to_ret += @ch
    in_any_next()
    while r_Literal_Cs() || r_Digit09_Cs() || @ch == '_' # BB
      if r_Literal_Cs()
        # r_Literal_Cs()
        to_ret += @ch
        in_any_next() # 5.Total
      elsif r_Digit09_Cs()
        # r_Digit09_Cs()
        to_ret += @ch
        in_any_next() # 5.Total
      elsif @ch == '_'
        to_ret += @ch
        r_in_must_and_nowhite_next('_')
      else
        error(%{no choice of r_Literal_Cs()
r_Digit09_Cs()
@ch == '_'}) # 34;
      end
    end # BB

    #
    in_white()
    # as_AST.lex_value = to_ret
    as_LEX.value = to_ret
    # puts to_ret
    # puts @ch
    # as_AST.c_kids.push(to_ret)
    return as_LEX
  end

  def first_in_r_Identifier_Lx : Bool
    if r_Literal_Cs()
      return true # TAG 46
    else
      return false
    end
  end
end
