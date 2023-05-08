class Parse
  def r_Param_Lx : AbsSyntTree
    xxx = ->{
      if (@ch >= '0' && @ch <= '9')
        return true
      elsif (@ch >= 'a' && @ch <= 'z')
        return true
      elsif (@ch >= 'A' && @ch <= 'Z')
        return true
      else
        return false
      end
    }
    as_AST = AbsSyntTree.new("lexem", "r_Param_Lx", "")
    to_ret : String = ""
    in_any_next()
    while xxx.call
      to_ret += ch
      in_any_next()
    end
    as_AST.value = to_ret
    # r_in_must_and_nowhite_next('"')
    in_white
    return as_AST

  end

  def first_in_r_Param_Lx  : Bool
    if @ch == '?'
      return true
    else
      return false
    end
  end
end
