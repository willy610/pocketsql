class Parse
  def r_SQString_Lx : AbsSyntTree
    xxx = ->{
      if @ch == '\''
        return false
      end
      if (@ch >= ' ' && @ch <= '~')
        return true
      else
        return false
      end
    }

    as_LEX = AbsSyntTree.new("lexem", "r_SQString_Lx", "")

    to_ret : String = ""
    in_any_next()

    while xxx.call
      to_ret += ch
      in_any_next()
    end

    r_in_must_and_nowhite_next('\'')
    as_LEX.value = to_ret
    return as_LEX
  end

  def first_in_r_SQString_Lx : Bool
    if @ch == '\''
      return true
    else
      return false
    end
  end
end
