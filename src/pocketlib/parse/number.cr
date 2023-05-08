class Parse
  def r_Number_Lx : AbsSyntTree
    # "r_Number_Lx"
    # as_AST = LexValue.new("r_Number_Lx")
    as_LEX = AbsSyntTree.new("lexem", "r_Number_Lx", "")

    to_ret : String = ""
    to_ret += @ch
    in_any_next()
    #
    while r_Digit09_Cs() # BB
      r_Digit09_Cs()
      to_ret += @ch
      in_any_next() # 5.Total
    end             # BB

    if @ch == '.' # CC
      r_in_must_and_nowhite_next('.')
      while r_Digit09_Cs() # BB
        r_Digit09_Cs()
        to_ret += @ch
        in_any_next() # 5.Total
      end             # BB

    end # CC

    #
    in_white
    # as_AST.lex_value = to_ret
    as_LEX.value = to_ret
    # as_AST.c_kids.push(to_ret)
    return as_LEX
  end

  def first_in_r_Number_Lx : Bool
    if r_Digit09_Cs()
      return true # TAG 46
    else
      return false
    end
  end

  # def r_Number_Lx : AbsSyntTree
  #   as_AST = AbsSyntTree.new("r_Number_Lx")
  #   to_ret : String = ""
  #   to_ret += @ch
  #   in_any_next()
  #   #
  #   r_Digit19_Cs()
  #   to_ret += @ch
  #   in_any_next()        # 5.Total
  #   while r_Digit09_Cs() # BB
  #     # r_Digit09_Cs()
  #     to_ret += @ch
  #     in_any_next() # 5.Total
  #   end             # BB

  #   #
  #   in_white
  #   as_AST.c_kids.push(to_ret)
  #   return as_AST
  # end

  # def first_in_r_Number_Lx : Bool
  #   if r_Digit19_Cs()
  #     return true # TAG 46
  #   else
  #     return false
  #   end
  # end
end
