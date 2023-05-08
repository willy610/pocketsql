class Parse
  def r_Createtable : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_Createtable", "")
    as_AST.content.push(r_create())
    in_res_oper(";")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ";")
    as_AST.content.push(resoper_AST)

    return as_AST
  end

  def first_in_r_Createtable : Bool
    if first_in_r_create()
      return true
    else
      return false
    end
  end

  def r_create : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_create", "")
    in_res_word("CREATE")
    resword_AST = AbsSyntTree.new("resword", "resword", "CREATE")
    as_AST.content.push(resword_AST)

    in_res_word("ENTITYTABLE")
    resword_AST = AbsSyntTree.new("resword", "resword", "ENTITYTABLE")
    as_AST.content.push(resword_AST)

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)

    as_AST.content.push(r_enttable())
    while first_in_r_enttable() # '+'
      as_AST.content.push(r_enttable())
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    if (@ch == 'R' && in_res_word("RELATIONSHIPTABLE", false)) # '?'
      in_res_word("RELATIONSHIPTABLE")
      resword_AST = AbsSyntTree.new("resword", "resword", "RELATIONSHIPTABLE")
      as_AST.content.push(resword_AST)

      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)

      as_AST.content.push(r_reltable())
      while first_in_r_reltable() # '+'
        as_AST.content.push(r_reltable())
      end

      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
    end

    return as_AST
  end

  def first_in_r_create : Bool
    if (@ch == 'C' && in_res_word("CREATE", false))
      return true
    else
      return false
    end
  end

  def r_enttable : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_enttable", "")
    as_AST.content.push(r_tablename())
    as_AST.content.push(r_entkey())
    if first_in_r_relcols() # '?'
      as_AST.content.push(r_relcols())
    end

    if first_in_r_plaincols() # '?'
      as_AST.content.push(r_plaincols())
    end

    return as_AST
  end

  def first_in_r_enttable : Bool
    if first_in_r_tablename()
      return true
    else
      return false
    end
  end

  def r_reltable : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_reltable", "")
    as_AST.content.push(r_tablename())
    as_AST.content.push(r_relkey())
    if first_in_r_relcols() # '?'
      as_AST.content.push(r_relcols())
    end

    if first_in_r_plaincols() # '?'
      as_AST.content.push(r_plaincols())
    end

    return as_AST
  end

  def first_in_r_reltable : Bool
    if first_in_r_tablename()
      return true
    else
      return false
    end
  end

  def r_entkey : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_entkey", "")
    in_res_word("PRIMARYKEY")
    resword_AST = AbsSyntTree.new("resword", "resword", "PRIMARYKEY")
    as_AST.content.push(resword_AST)

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)

    as_AST.content.push(r_acolumn())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_acolumn())
    end

    while first_in_r_acolumn() # '+'
      as_AST.content.push(r_acolumn())

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        as_AST.content.push(r_acolumn())
      end
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    return as_AST
  end

  def first_in_r_entkey : Bool
    if (@ch == 'P' && in_res_word("PRIMARYKEY", false))
      return true
    else
      return false
    end
  end

  def r_relkey : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_relkey", "")
    in_res_word("PRIMARYKEY")
    resword_AST = AbsSyntTree.new("resword", "resword", "PRIMARYKEY")
    as_AST.content.push(resword_AST)

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)

    in_res_word("PARENTS")
    resword_AST = AbsSyntTree.new("resword", "resword", "PARENTS")
    as_AST.content.push(resword_AST)

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)

    as_AST.content.push(r_tablenameandmore())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_tablenameandmore())
    end

    while first_in_r_tablenameandmore() # '+'
      as_AST.content.push(r_tablenameandmore())

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        as_AST.content.push(r_tablenameandmore())
      end
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    if (@ch == 'O' && in_res_word("OWNPRIMARY", false)) # '?'
      in_res_word("OWNPRIMARY")
      resword_AST = AbsSyntTree.new("resword", "resword", "OWNPRIMARY")
      as_AST.content.push(resword_AST)

      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)

      as_AST.content.push(r_acolumn())

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        as_AST.content.push(r_acolumn())
      end

      while first_in_r_acolumn() # '+'
        as_AST.content.push(r_acolumn())

        while @ch == ',' # ', '
          in_must_and_nowhite_next(',')
          as_AST.content.push(r_acolumn())
        end
      end

      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    return as_AST
  end

  def first_in_r_relkey : Bool
    if (@ch == 'P' && in_res_word("PRIMARYKEY", false))
      return true
    else
      return false
    end
  end

  def r_tablenameandmore : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_tablenameandmore", "")
    as_AST.content.push(r_tablename())
    if first_in_r_prefixed() # '?'
      as_AST.content.push(r_prefixed())
    end

    if first_in_r_sqlattribute() # '?'
      as_AST.content.push(r_sqlattribute())
    end

    return as_AST
  end

  def first_in_r_tablenameandmore : Bool
    if first_in_r_tablename()
      return true
    else
      return false
    end
  end

  def r_prefixed : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_prefixed", "")
    in_res_word("PREFIXED")
    resword_AST = AbsSyntTree.new("resword", "resword", "PREFIXED")
    as_AST.content.push(resword_AST)

    # 4->
    as_AST.content.push(r_SQString_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_prefixed : Bool
    if (@ch == 'P' && in_res_word("PREFIXED", false))
      return true
    else
      return false
    end
  end

  def r_acolumn : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_acolumn", "")
    as_AST.content.push(r_colname())
    if first_in_r_sqlattribute() # '?'
      as_AST.content.push(r_sqlattribute())
    end

    return as_AST
  end

  def first_in_r_acolumn : Bool
    if first_in_r_colname()
      return true
    else
      return false
    end
  end

  def r_relcols : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_relcols", "")
    in_res_word("RELATIVECOLUMN")
    resword_AST = AbsSyntTree.new("resword", "resword", "RELATIVECOLUMN")
    as_AST.content.push(resword_AST)

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)

    as_AST.content.push(r_tablename())
    if first_in_r_prefixed() # '?'
      as_AST.content.push(r_prefixed())
    end

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_tablename())
      if first_in_r_prefixed() # '?'
        as_AST.content.push(r_prefixed())
      end
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    return as_AST
  end

  def first_in_r_relcols : Bool
    if (@ch == 'R' && in_res_word("RELATIVECOLUMN", false))
      return true
    else
      return false
    end
  end

  def r_plaincols : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_plaincols", "")
    in_res_word("PLAINCOLUMN")
    resword_AST = AbsSyntTree.new("resword", "resword", "PLAINCOLUMN")
    as_AST.content.push(resword_AST)

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)

    as_AST.content.push(r_acolumn())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_acolumn())
    end

    while first_in_r_acolumn() # '+'
      as_AST.content.push(r_acolumn())

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        as_AST.content.push(r_acolumn())
      end
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    return as_AST
  end

  def first_in_r_plaincols : Bool
    if (@ch == 'P' && in_res_word("PLAINCOLUMN", false))
      return true
    else
      return false
    end
  end

  def r_tablename : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_tablename", "")

    # 4->
    as_AST.content.push(r_Identifier_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_tablename : Bool
    if first_in_r_Identifier_Lx()
      return true
    else
      return false
    end
  end

  def r_colname : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_colname", "")

    # 4->
    as_AST.content.push(r_Identifier_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_colname : Bool
    if first_in_r_Identifier_Lx()
      return true
    else
      return false
    end
  end

  def r_Literal_Cs : Bool
    # XX(CS)->
    if (@ch >= 'a' && @ch <= 'z') && !(false)
      return true
    end
    if (@ch >= 'A' && @ch <= 'Z') && !(false)
      return true
    end
    return false

    return false
    # XX(CS)-<
  end

  def first_in_r_Literal_Cs : Bool
    if @ch >= 'a' || @ch >= 'A'
      return true
    else
      return false
    end
  end

  def r_Digit09_Cs : Bool
    # XX(CS)->
    if (@ch >= '0' && @ch <= '9') && !(false)
      return true
    end

    return false
    # XX(CS)-<
  end

  def first_in_r_Digit09_Cs : Bool
    if @ch >= '0'
      return true
    else
      return false
    end
  end

  def r_Digit19_Cs : Bool
    # XX(CS)->
    if (@ch >= '1' && @ch <= '9') && !(false)
      return true
    end

    return false
    # XX(CS)-<
  end

  def first_in_r_Digit19_Cs : Bool
    if @ch >= '1'
      return true
    else
      return false
    end
  end

  def r_sqlattribute : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_sqlattribute", "")

    # 4->
    as_AST.content.push(r_SQString_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_sqlattribute : Bool
    if first_in_r_SQString_Lx()
      return true
    else
      return false
    end
  end

  def r_Identifier_Lx : AbsSyntTree
    as_LEX = AbsSyntTree.new("lexem", "r_Identifier_Lx", "")
    to_ret : String = ""
    to_ret += @ch
    in_any_next()
    r_Literal_Cs()
    to_ret += @ch
    in_any_next()                                        # 5.Total
    while r_Literal_Cs() || r_Digit09_Cs() || @ch == '_' # '*'
      if r_Literal_Cs()
        r_Literal_Cs()
        to_ret += @ch
        in_any_next() # 5.Total
      elsif r_Digit09_Cs()
        r_Digit09_Cs()
        to_ret += @ch
        in_any_next() # 5.Total
      elsif @ch == '_'
        r_in_must_and_nowhite_next('_')
      else
        error(%{no choice of r_Literal_Cs()
r_Digit09_Cs()
@ch == '_'})
      end
    end

    in_white()
    as_LEX.value = to_ret
    return as_LEX
  end

  def first_in_r_Identifier_Lx : Bool
    if r_Literal_Cs()
      return true
    else
      return false
    end
  end
end
