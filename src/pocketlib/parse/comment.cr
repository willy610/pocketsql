class Parse
  def first_in_r_comments : Bool
    if (@ch == '-' && in_res_oper("-- ", false))
      return true
    else
      return false
    end
  end

  def r_fullrow_Lx : AbsSyntTree
    as_LEX = AbsSyntTree.new("lexem", "r_fullrow_Lx", "")
    to_ret : String = ""
    to_ret += @ch
    in_any_next()
    while !(@ch == '\n' || @ch == '\u0000' || @ch == '\r')
      to_ret += @ch
      # puts to_ret
      in_any_next() # 5.Total
    end
    in_white
    # puts @ch
    # puts "to_ret=#{to_ret}"
    as_LEX.value = to_ret
    return as_LEX
  end
end
