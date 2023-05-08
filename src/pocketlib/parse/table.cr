class Parse
    def r_tablename : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_tablename", "")
    if first_in_r_SQString_Lx()
      # 4->
      as_AST.content.push(r_SQString_Lx())
      # <-4
    elsif first_in_r_Identifier_Lx()
      # 4->
      as_AST.content.push(r_Identifier_Lx())
      # <-4
    else
      error(%{no choice of first_in_r_SQString_Lx()
first_in_r_Identifier_Lx()})
    end
    return as_AST
  end

  def first_in_r_tablename : Bool
    if (@ch == 'R' && in_res_word("RECURSIVE", false))
      return false
    elsif first_in_r_SQString_Lx() || first_in_r_Identifier_Lx()
      return true
    else
      return false
    end
  end
end