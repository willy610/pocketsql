class Parse
  def r_Program : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_Program", "")
    while first_in_r_comments() # '*'
      as_AST.content.push(r_comments())
    end

    if first_in_r_with() # '?'
      as_AST.content.push(r_with())
    end

    if (@ch == 'S' && in_res_word("SHOW", false))
      in_res_word("SHOW")
      resword_AST = AbsSyntTree.new("resword", "resword", "SHOW")
      as_AST.content.push(resword_AST)
      if (@ch == 'T' && in_res_word("TABLES", false))
        in_res_word("TABLES")
        resword_AST = AbsSyntTree.new("resword", "resword", "TABLES")
        as_AST.content.push(resword_AST)
      elsif (@ch == 'T' && in_res_word("TABLE", false))
        in_res_word("TABLE")
        resword_AST = AbsSyntTree.new("resword", "resword", "TABLE")
        as_AST.content.push(resword_AST)
        as_AST.content.push(r_AS_TID())
      else
        error(%{no choice of (@ch == 'T' && in_res_word("TABLES",false))
(@ch == 'T' && in_res_word("TABLE",false))})
      end
    elsif (@ch == 'I' && in_res_word("INSERT", false))
      in_res_word("INSERT")
      resword_AST = AbsSyntTree.new("resword", "resword", "INSERT")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_insertbody())
    elsif (@ch == 'S' && in_res_word("SELECT", false))
      in_res_word("SELECT")
      resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_projectbody())
      if first_in_r_orderby() # '?'
        as_AST.content.push(r_orderby())
      end

      if first_in_r_limit() # '?'
        as_AST.content.push(r_limit())
      end
    elsif (@ch == 'U' && in_res_word("UPDATE", false))
      in_res_word("UPDATE")
      resword_AST = AbsSyntTree.new("resword", "resword", "UPDATE")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_updatebody())
    elsif (@ch == 'D' && in_res_word("DELETE", false))
      in_res_word("DELETE")
      resword_AST = AbsSyntTree.new("resword", "resword", "DELETE")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_deletebody())
    else
      error(%{no choice of (@ch == 'S' && in_res_word("SHOW",false))
(@ch == 'I' && in_res_word("INSERT",false))
(@ch == 'S' && in_res_word("SELECT",false))
(@ch == 'U' && in_res_word("UPDATE",false))
(@ch == 'D' && in_res_word("DELETE",false))})
    end

    in_res_oper(";")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ";")
    as_AST.content.push(resoper_AST)
    return as_AST
  end

  def first_in_r_Program : Bool
    if first_in_r_comments()
      return true
    else
      return false
    end
  end

  def r_comments : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_comments", "")
    in_res_oper("-- ")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "-- ")
    as_AST.content.push(resoper_AST)

    # 4->
    as_AST.content.push(r_fullrow_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_comments : Bool
    if (@ch == '-' && in_res_oper("-- ", false))
      return true
    else
      return false
    end
  end

  def r_with : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_with", "")
    in_res_word("WITH")
    resword_AST = AbsSyntTree.new("resword", "resword", "WITH")
    as_AST.content.push(resword_AST)
    if first_in_r_withplain() # '?'
      as_AST.content.push(r_withplain())

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        as_AST.content.push(r_withplain())
      end
    end

    if first_in_r_withrecur() # '?'
      as_AST.content.push(r_withrecur())
    end

    return as_AST
  end

  def first_in_r_with : Bool
    if (@ch == 'W' && in_res_word("WITH", false))
      return true
    else
      return false
    end
  end

  def r_withplain : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_withplain", "")
    as_AST.content.push(r_tablename())
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    as_AST.content.push(r_column_comma_list())
    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    in_res_word("AS")
    resword_AST = AbsSyntTree.new("resword", "resword", "AS")
    as_AST.content.push(resword_AST)
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    in_res_word("SELECT")
    resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_projectbody())
    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    return as_AST
  end

  def first_in_r_withplain : Bool
    if first_in_r_tablename()
      return true
    else
      return false
    end
  end

  def r_withrecur : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_withrecur", "")
    in_res_word("RECURSIVE")
    resword_AST = AbsSyntTree.new("resword", "resword", "RECURSIVE")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_tablename())
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    as_AST.content.push(r_column_comma_list())
    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    in_res_word("AS")
    resword_AST = AbsSyntTree.new("resword", "resword", "AS")
    as_AST.content.push(resword_AST)
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    in_res_word("SELECT")
    resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_projectbody())
    in_res_word("UNION")
    resword_AST = AbsSyntTree.new("resword", "resword", "UNION")
    as_AST.content.push(resword_AST)
    if (@ch == 'A' && in_res_word("ALL", false)) # '?'
      in_res_word("ALL")
      resword_AST = AbsSyntTree.new("resword", "resword", "ALL")
      as_AST.content.push(resword_AST)
    end

    in_res_word("SELECT")
    resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_projectbody())
    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    return as_AST
  end

  def first_in_r_withrecur : Bool
    if (@ch == 'R' && in_res_word("RECURSIVE", false))
      return true
    else
      return false
    end
  end

  def r_insertbody : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_insertbody", "")
    in_res_word("INTO")
    resword_AST = AbsSyntTree.new("resword", "resword", "INTO")
    as_AST.content.push(resword_AST)
    if first_in_r_Identifier_Lx()
      # 4->
      as_AST.content.push(r_Identifier_Lx())
      # <-4
    elsif first_in_r_SQString_Lx()
      # 4->
      as_AST.content.push(r_SQString_Lx())
      # <-4

      as_AST.content.push(r_tbl_col_alias())
    else
      error(%{no choice of first_in_r_Identifier_Lx()
first_in_r_SQString_Lx()})
    end

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    as_AST.content.push(r_column_comma_list())
    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    as_AST.content.push(r_value_or_select())
    return as_AST
  end

  def first_in_r_insertbody : Bool
    if (@ch == 'I' && in_res_word("INTO", false))
      return true
    else
      return false
    end
  end

  def r_value_or_select : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_value_or_select", "")
    if (@ch == 'V' && in_res_word("VALUES", false))
      in_res_word("VALUES")
      resword_AST = AbsSyntTree.new("resword", "resword", "VALUES")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_value_list())
    elsif (@ch == 'S' && in_res_word("SELECT", false))
      in_res_word("SELECT")
      resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_projectbody())
    else
      error(%{no choice of (@ch == 'V' && in_res_word("VALUES",false))
(@ch == 'S' && in_res_word("SELECT",false))})
    end

    return as_AST
  end

  def first_in_r_value_or_select : Bool
    if (@ch == 'V' && in_res_word("VALUES", false)) || (@ch == 'S' && in_res_word("SELECT", false))
      return true
    else
      return false
    end
  end

  def r_updatebody : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_updatebody", "")
    if first_in_r_Identifier_Lx()
      # 4->
      as_AST.content.push(r_Identifier_Lx())
      # <-4
    elsif first_in_r_SQString_Lx()
      # 4->
      as_AST.content.push(r_SQString_Lx())
      # <-4

      as_AST.content.push(r_tbl_col_alias())
    else
      error(%{no choice of first_in_r_Identifier_Lx()
first_in_r_SQString_Lx()})
    end

    in_res_word("SET")
    resword_AST = AbsSyntTree.new("resword", "resword", "SET")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_AS_CID())
    in_res_oper("=")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "=")
    as_AST.content.push(resoper_AST)
    as_AST.content.push(r_scalarexp())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_AS_CID())
      in_res_oper("=")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "=")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_scalarexp())
    end

    as_AST.content.push(r_whererule())
    return as_AST
  end

  def first_in_r_updatebody : Bool
    if first_in_r_Identifier_Lx() || first_in_r_SQString_Lx()
      return true
    else
      return false
    end
  end

  def r_deletebody : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_deletebody", "")
    in_res_word("FROM")
    resword_AST = AbsSyntTree.new("resword", "resword", "FROM")
    as_AST.content.push(resword_AST)
    if first_in_r_Identifier_Lx()
      # 4->
      as_AST.content.push(r_Identifier_Lx())
      # <-4
    elsif first_in_r_SQString_Lx()
      # 4->
      as_AST.content.push(r_SQString_Lx())
      # <-4

      as_AST.content.push(r_tbl_col_alias())
    else
      error(%{no choice of first_in_r_Identifier_Lx()
first_in_r_SQString_Lx()})
    end

    as_AST.content.push(r_whererule())
    return as_AST
  end

  def first_in_r_deletebody : Bool
    if (@ch == 'F' && in_res_word("FROM", false))
      return true
    else
      return false
    end
  end

  def r_projectbody : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_projectbody", "")
    if (@ch == 'D' && in_res_word("DISTINCT", false)) # '?'
      in_res_word("DISTINCT")
      resword_AST = AbsSyntTree.new("resword", "resword", "DISTINCT")
      as_AST.content.push(resword_AST)
    end

    as_AST.content.push(r_project())
    in_res_word("FROM")
    resword_AST = AbsSyntTree.new("resword", "resword", "FROM")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_from())
    if first_in_r_whererule() # '?'
      as_AST.content.push(r_whererule())
    end

    if first_in_r_window() # '?'
      as_AST.content.push(r_window())
    end

    if first_in_r_groupby() # '?'
      as_AST.content.push(r_groupby())
    end

    if first_in_r_having() # '?'
      as_AST.content.push(r_having())
    end

    return as_AST
  end

  def first_in_r_projectbody : Bool
    if (@ch == 'D' && in_res_word("DISTINCT", false))
      return true
    else
      return false
    end
  end

  def r_from : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_from", "")
    as_AST.content.push(r_table_ref())
    return as_AST
  end

  def first_in_r_from : Bool
    if first_in_r_table_ref()
      return true
    else
      return false
    end
  end

  def r_table_ref : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_table_ref", "")
    as_AST.content.push(r_relation_body())
    while first_in_r_joiner_or_setoper() # '*'
      as_AST.content.push(r_joiner_or_setoper())
    end

    return as_AST
  end

  def first_in_r_table_ref : Bool
    if first_in_r_relation_body()
      return true
    else
      return false
    end
  end

  def r_relation_body : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_relation_body", "")
    if (@ch == '(' && in_res_oper("(", false))
      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_relation_body())
      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_tbl_col_alias())
    elsif (@ch == 'V' && in_res_word("VALUES", false))
      in_res_word("VALUES")
      resword_AST = AbsSyntTree.new("resword", "resword", "VALUES")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_value_list())
      if first_in_r_tbl_col_alias() # '?'
        as_AST.content.push(r_tbl_col_alias())
      end
    elsif (@ch == 'S' && in_res_word("SELECT", false))
      in_res_word("SELECT")
      resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_projectbody())
    elsif first_in_r_tablename()
      as_AST.content.push(r_tablename())
      if first_in_r_tbl_col_alias() # '?'
        as_AST.content.push(r_tbl_col_alias())
      end
    else
      error(%{no choice of (@ch == '(' && in_res_oper("(",false))
(@ch == 'V' && in_res_word("VALUES",false))
(@ch == 'S' && in_res_word("SELECT",false))
first_in_r_tablename()})
    end

    return as_AST
  end

  def first_in_r_relation_body : Bool
    if (@ch == '(' && in_res_oper("(", false)) || (@ch == 'V' && in_res_word("VALUES", false)) || (@ch == 'S' && in_res_word("SELECT", false)) || first_in_r_tablename()
      return true
    else
      return false
    end
  end

  def r_value_list : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_value_list", "")
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    if first_in_r_DQString_Lx()
      # 4->
      as_AST.content.push(r_DQString_Lx())
      # <-4
    elsif first_in_r_SQString_Lx()
      # 4->
      as_AST.content.push(r_SQString_Lx())
      # <-4
    elsif first_in_r_Number_Lx()
      # 4->
      as_AST.content.push(r_Number_Lx())
      # <-4
    else
      error(%{no choice of first_in_r_DQString_Lx()
first_in_r_SQString_Lx()
first_in_r_Number_Lx()})
    end

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      if first_in_r_DQString_Lx()
        # 4->
        as_AST.content.push(r_DQString_Lx())
        # <-4
      elsif first_in_r_SQString_Lx()
        # 4->
        as_AST.content.push(r_SQString_Lx())
        # <-4
      elsif first_in_r_Number_Lx()
        # 4->
        as_AST.content.push(r_Number_Lx())
        # <-4
      else
        error(%{no choice of first_in_r_DQString_Lx()
first_in_r_SQString_Lx()
first_in_r_Number_Lx()})
      end
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)
      if first_in_r_DQString_Lx()
        # 4->
        as_AST.content.push(r_DQString_Lx())
        # <-4
      elsif first_in_r_SQString_Lx()
        # 4->
        as_AST.content.push(r_SQString_Lx())
        # <-4
      elsif first_in_r_Number_Lx()
        # 4->
        as_AST.content.push(r_Number_Lx())
        # <-4
      else
        error(%{no choice of first_in_r_DQString_Lx()
first_in_r_SQString_Lx()
first_in_r_Number_Lx()})
      end

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        if first_in_r_DQString_Lx()
          # 4->
          as_AST.content.push(r_DQString_Lx())
          # <-4
        elsif first_in_r_SQString_Lx()
          # 4->
          as_AST.content.push(r_SQString_Lx())
          # <-4
        elsif first_in_r_Number_Lx()
          # 4->
          as_AST.content.push(r_Number_Lx())
          # <-4
        else
          error(%{no choice of first_in_r_DQString_Lx()
first_in_r_SQString_Lx()
first_in_r_Number_Lx()})
        end
      end

      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
    end

    return as_AST
  end

  def first_in_r_value_list : Bool
    if (@ch == '(' && in_res_oper("(", false))
      return true
    else
      return false
    end
  end

  def r_tbl_col_alias : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_tbl_col_alias", "")
    in_res_word("AS")
    resword_AST = AbsSyntTree.new("resword", "resword", "AS")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_AS_TID())
    if (@ch == '(' && in_res_oper("(", false)) # '?'
      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_column_comma_list())
      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
    end

    return as_AST
  end

  def first_in_r_tbl_col_alias : Bool
    if (@ch == 'A' && in_res_word("AS", false))
      return true
    else
      return false
    end
  end

  def r_joiner_or_setoper : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_joiner_or_setoper", "")
    if (@ch == ',' && in_res_oper(",", false))
      in_res_oper(",")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ",")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_relation_body())
    elsif (@ch == 'J' && in_res_word("JOIN", false)) || first_in_r_join_type()
      if (@ch == 'J' && in_res_word("JOIN", false))
        in_res_word("JOIN")
        resword_AST = AbsSyntTree.new("resword", "resword", "JOIN")
        as_AST.content.push(resword_AST)
      elsif first_in_r_join_type()
        as_AST.content.push(r_join_type())
        in_res_word("JOIN")
        resword_AST = AbsSyntTree.new("resword", "resword", "JOIN")
        as_AST.content.push(resword_AST)
      else
        error(%{no choice of (@ch == 'J' && in_res_word("JOIN",false))
first_in_r_join_type()})
      end

      as_AST.content.push(r_relation_body())
      as_AST.content.push(r_onrule())
    elsif (@ch == 'U' && in_res_word("UNION", false)) || (@ch == 'E' && in_res_word("EXCEPT", false)) || (@ch == 'I' && in_res_word("INTERSECT", false))
      if (@ch == 'U' && in_res_word("UNION", false))
        in_res_word("UNION")
        resword_AST = AbsSyntTree.new("resword", "resword", "UNION")
        as_AST.content.push(resword_AST)
      elsif (@ch == 'E' && in_res_word("EXCEPT", false))
        in_res_word("EXCEPT")
        resword_AST = AbsSyntTree.new("resword", "resword", "EXCEPT")
        as_AST.content.push(resword_AST)
      elsif (@ch == 'I' && in_res_word("INTERSECT", false))
        in_res_word("INTERSECT")
        resword_AST = AbsSyntTree.new("resword", "resword", "INTERSECT")
        as_AST.content.push(resword_AST)
      else
        error(%{no choice of (@ch == 'U' && in_res_word("UNION",false))
(@ch == 'E' && in_res_word("EXCEPT",false))
(@ch == 'I' && in_res_word("INTERSECT",false))})
      end

      if (@ch == 'A' && in_res_word("ALL", false)) # '?'
        in_res_word("ALL")
        resword_AST = AbsSyntTree.new("resword", "resword", "ALL")
        as_AST.content.push(resword_AST)
      end

      as_AST.content.push(r_relation_body())
    elsif (@ch == 'C' && in_res_word("CROSS", false))
      in_res_word("CROSS")
      resword_AST = AbsSyntTree.new("resword", "resword", "CROSS")
      as_AST.content.push(resword_AST)
      in_res_word("JOIN")
      resword_AST = AbsSyntTree.new("resword", "resword", "JOIN")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_relation_body())
    else
      error(%{no choice of (@ch == ',' && in_res_oper(",",false))
(@ch == 'J' && in_res_word("JOIN",false)) || first_in_r_join_type()
(@ch == 'U' && in_res_word("UNION",false)) || (@ch == 'E' && in_res_word("EXCEPT",false)) || (@ch == 'I' && in_res_word("INTERSECT",false))
(@ch == 'C' && in_res_word("CROSS",false))})
    end

    return as_AST
  end

  def first_in_r_joiner_or_setoper : Bool
    if (@ch == ',' && in_res_oper(",", false)) || (@ch == 'J' && in_res_word("JOIN", false)) || first_in_r_join_type() || (@ch == 'U' && in_res_word("UNION", false)) || (@ch == 'E' && in_res_word("EXCEPT", false)) || (@ch == 'I' && in_res_word("INTERSECT", false)) || (@ch == 'C' && in_res_word("CROSS", false))
      return true
    else
      return false
    end
  end

  def r_join_type : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_join_type", "")
    if (@ch == 'I' && in_res_word("INNER", false))
      in_res_word("INNER")
      resword_AST = AbsSyntTree.new("resword", "resword", "INNER")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'L' && in_res_word("LEFT", false)) || (@ch == 'R' && in_res_word("RIGHT", false)) || (@ch == 'F' && in_res_word("FULL", false))
      if (@ch == 'L' && in_res_word("LEFT", false))
        in_res_word("LEFT")
        resword_AST = AbsSyntTree.new("resword", "resword", "LEFT")
        as_AST.content.push(resword_AST)
      elsif (@ch == 'R' && in_res_word("RIGHT", false))
        in_res_word("RIGHT")
        resword_AST = AbsSyntTree.new("resword", "resword", "RIGHT")
        as_AST.content.push(resword_AST)
      elsif (@ch == 'F' && in_res_word("FULL", false))
        in_res_word("FULL")
        resword_AST = AbsSyntTree.new("resword", "resword", "FULL")
        as_AST.content.push(resword_AST)
      else
        error(%{no choice of (@ch == 'L' && in_res_word("LEFT",false))
(@ch == 'R' && in_res_word("RIGHT",false))
(@ch == 'F' && in_res_word("FULL",false))})
      end

      if (@ch == 'O' && in_res_word("OUTER", false)) # '?'
        in_res_word("OUTER")
        resword_AST = AbsSyntTree.new("resword", "resword", "OUTER")
        as_AST.content.push(resword_AST)
      end
    elsif (@ch == 'U' && in_res_word("UNION", false))
      in_res_word("UNION")
      resword_AST = AbsSyntTree.new("resword", "resword", "UNION")
      as_AST.content.push(resword_AST)
    else
      error(%{no choice of (@ch == 'I' && in_res_word("INNER",false))
(@ch == 'L' && in_res_word("LEFT",false)) || (@ch == 'R' && in_res_word("RIGHT",false)) || (@ch == 'F' && in_res_word("FULL",false))
(@ch == 'U' && in_res_word("UNION",false))})
    end

    return as_AST
  end

  def first_in_r_join_type : Bool
    if (@ch == 'I' && in_res_word("INNER", false)) || (@ch == 'L' && in_res_word("LEFT", false)) || (@ch == 'R' && in_res_word("RIGHT", false)) || (@ch == 'F' && in_res_word("FULL", false)) || (@ch == 'U' && in_res_word("UNION", false))
      return true
    else
      return false
    end
  end

  def r_whererule : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_whererule", "")
    in_res_word("WHERE")
    resword_AST = AbsSyntTree.new("resword", "resword", "WHERE")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_fullcondexpr())
    return as_AST
  end

  def first_in_r_whererule : Bool
    if (@ch == 'W' && in_res_word("WHERE", false))
      return true
    else
      return false
    end
  end

  def r_onrule : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_onrule", "")
    in_res_word("ON")
    resword_AST = AbsSyntTree.new("resword", "resword", "ON")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_fullcondexpr())
    return as_AST
  end

  def first_in_r_onrule : Bool
    if (@ch == 'O' && in_res_word("ON", false))
      return true
    else
      return false
    end
  end

  def r_fullcondexpr : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_fullcondexpr", "")
    as_AST.content.push(r_pcondexpr())
    while first_in_r_andor() # '*'
      as_AST.content.push(r_andor())
    end

    return as_AST
  end

  def first_in_r_fullcondexpr : Bool
    if first_in_r_pcondexpr()
      return true
    else
      return false
    end
  end

  def r_andor : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_andor", "")
    if (@ch == 'A' && in_res_word("AND", false))
      in_res_word("AND")
      resword_AST = AbsSyntTree.new("resword", "resword", "AND")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'O' && in_res_word("OR", false))
      in_res_word("OR")
      resword_AST = AbsSyntTree.new("resword", "resword", "OR")
      as_AST.content.push(resword_AST)
    else
      error(%{no choice of (@ch == 'A' && in_res_word("AND",false))
(@ch == 'O' && in_res_word("OR",false))})
    end

    as_AST.content.push(r_pcondexpr())
    return as_AST
  end

  def first_in_r_andor : Bool
    if (@ch == 'A' && in_res_word("AND", false)) || (@ch == 'O' && in_res_word("OR", false))
      return true
    else
      return false
    end
  end

  def r_pcondexpr : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_pcondexpr", "")
    if @ch == '('
      r_in_must_and_nowhite_next('(')
      as_AST.content.push(r_condexpr())
      r_in_must_and_nowhite_next(')')
    elsif first_in_r_condexpr()
      as_AST.content.push(r_condexpr())
    else
      error(%{no choice of @ch == '('
first_in_r_condexpr()})
    end

    return as_AST
  end

  def first_in_r_pcondexpr : Bool
    if @ch == '(' || first_in_r_condexpr()
      return true
    else
      return false
    end
  end

  def r_condexpr : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_condexpr", "")
    if first_in_r_simplecond()
      as_AST.content.push(r_simplecond())
    elsif @ch == '('
      r_in_must_and_nowhite_next('(')
      as_AST.content.push(r_condexpr())
      r_in_must_and_nowhite_next(')')
    else
      error(%{no choice of first_in_r_simplecond()
@ch == '('})
    end

    return as_AST
  end

  def first_in_r_condexpr : Bool
    if first_in_r_simplecond() || @ch == '('
      return true
    else
      return false
    end
  end

  def r_simplecond : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_simplecond", "")
    as_AST.content.push(r_psimplecond())

    # 4->
    as_AST.content.push(r_compoper_Lx())
    # <-4

    as_AST.content.push(r_psimplecond())
    return as_AST
  end

  def first_in_r_simplecond : Bool
    if first_in_r_psimplecond()
      return true
    else
      return false
    end
  end

  def r_psimplecond : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_psimplecond", "")
    if first_in_r_scalarexp()
      as_AST.content.push(r_scalarexp())
    elsif @ch == '('
      r_in_must_and_nowhite_next('(')
      as_AST.content.push(r_scalarexp())
      r_in_must_and_nowhite_next(')')
    else
      error(%{no choice of first_in_r_scalarexp()
@ch == '('})
    end

    return as_AST
  end

  def first_in_r_psimplecond : Bool
    if first_in_r_scalarexp() || @ch == '('
      return true
    else
      return false
    end
  end

  def r_scalarexp : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_scalarexp", "")
    as_AST.content.push(r_nypscalarexp())
    while first_in_r_scalaroper_Lx() # '*'

      # 4->
      as_AST.content.push(r_scalaroper_Lx())
      # <-4

      as_AST.content.push(r_nypscalarexp())
    end

    return as_AST
  end

  def first_in_r_scalarexp : Bool
    if first_in_r_nypscalarexp()
      return true
    else
      return false
    end
  end

  def r_nypscalarexp : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_nypscalarexp", "")
    if (@ch == 'V' && in_res_word("VALUES", false))
      in_res_word("VALUES")
      resword_AST = AbsSyntTree.new("resword", "resword", "VALUES")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_value_list())
    elsif (@ch == '(' && in_res_oper("(", false))
      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_scalarexpselectbodyorscalarexp())
      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
    elsif first_in_r_scalarterm()
      as_AST.content.push(r_scalarterm())
    else
      error(%{no choice of (@ch == 'V' && in_res_word("VALUES",false))
(@ch == '(' && in_res_oper("(",false))
first_in_r_scalarterm()})
    end

    return as_AST
  end

  def first_in_r_nypscalarexp : Bool
    if (@ch == 'V' && in_res_word("VALUES", false)) || (@ch == '(' && in_res_oper("(", false)) || first_in_r_scalarterm()
      return true
    else
      return false
    end
  end

  def r_scalarexpselectbodyorscalarexp : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_scalarexpselectbodyorscalarexp", "")
    if (@ch == 'S' && in_res_word("SELECT", false))
      in_res_word("SELECT")
      resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_projectbody())
    elsif first_in_r_scalarexp()
      as_AST.content.push(r_scalarexp())
    else
      error(%{no choice of (@ch == 'S' && in_res_word("SELECT",false))
first_in_r_scalarexp()})
    end

    return as_AST
  end

  def first_in_r_scalarexpselectbodyorscalarexp : Bool
    if (@ch == 'S' && in_res_word("SELECT", false)) || first_in_r_scalarexp()
      return true
    else
      return false
    end
  end

  def r_scalarterm : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_scalarterm", "")
    if first_in_r_standardfunction()
      as_AST.content.push(r_standardfunction())
    elsif first_in_r_DQString_Lx()
      # 4->
      as_AST.content.push(r_DQString_Lx())
      # <-4
    elsif first_in_r_SQString_Lx()
      # 4->
      as_AST.content.push(r_SQString_Lx())
      # <-4
    elsif first_in_r_Number_Lx()
      # 4->
      as_AST.content.push(r_Number_Lx())
      # <-4
    elsif first_in_r_TID()
      as_AST.content.push(r_TID())
    elsif first_in_r_Param_Lx()
      # 4->
      as_AST.content.push(r_Param_Lx())
      # <-4
    else
      error(%{no choice of first_in_r_standardfunction()
first_in_r_DQString_Lx()
first_in_r_SQString_Lx()
first_in_r_Number_Lx()
first_in_r_TID()
first_in_r_Param_Lx()})
    end

    return as_AST
  end

  def first_in_r_scalarterm : Bool
    if first_in_r_standardfunction() || first_in_r_DQString_Lx() || first_in_r_SQString_Lx() || first_in_r_Number_Lx() || first_in_r_TID() || first_in_r_Param_Lx()
      return true
    else
      return false
    end
  end

  def r_orderby : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_orderby", "")
    in_res_word("ORDER")
    resword_AST = AbsSyntTree.new("resword", "resword", "ORDER")
    as_AST.content.push(resword_AST)
    in_res_word("BY")
    resword_AST = AbsSyntTree.new("resword", "resword", "BY")
    as_AST.content.push(resword_AST)
    if first_in_r_Identifier_Lx()
      # 4->
      as_AST.content.push(r_Identifier_Lx())
      # <-4
    elsif first_in_r_Number_Lx()
      # 4->
      as_AST.content.push(r_Number_Lx())
      # <-4
    else
      error(%{no choice of first_in_r_Identifier_Lx()
first_in_r_Number_Lx()})
    end

    if (@ch == 'A' && in_res_word("ASC", false)) || (@ch == 'D' && in_res_word("DESC", false)) # '?'
      if (@ch == 'A' && in_res_word("ASC", false))
        in_res_word("ASC")
        resword_AST = AbsSyntTree.new("resword", "resword", "ASC")
        as_AST.content.push(resword_AST)
      elsif (@ch == 'D' && in_res_word("DESC", false))
        in_res_word("DESC")
        resword_AST = AbsSyntTree.new("resword", "resword", "DESC")
        as_AST.content.push(resword_AST)
      else
        error(%{no choice of (@ch == 'A' && in_res_word("ASC",false))
(@ch == 'D' && in_res_word("DESC",false))})
      end
    end

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      if first_in_r_Identifier_Lx()
        # 4->
        as_AST.content.push(r_Identifier_Lx())
        # <-4
      elsif first_in_r_Number_Lx()
        # 4->
        as_AST.content.push(r_Number_Lx())
        # <-4
      else
        error(%{no choice of first_in_r_Identifier_Lx()
first_in_r_Number_Lx()})
      end

      if (@ch == 'A' && in_res_word("ASC", false)) || (@ch == 'D' && in_res_word("DESC", false)) # '?'
        if (@ch == 'A' && in_res_word("ASC", false))
          in_res_word("ASC")
          resword_AST = AbsSyntTree.new("resword", "resword", "ASC")
          as_AST.content.push(resword_AST)
        elsif (@ch == 'D' && in_res_word("DESC", false))
          in_res_word("DESC")
          resword_AST = AbsSyntTree.new("resword", "resword", "DESC")
          as_AST.content.push(resword_AST)
        else
          error(%{no choice of (@ch == 'A' && in_res_word("ASC",false))
(@ch == 'D' && in_res_word("DESC",false))})
        end
      end
    end

    return as_AST
  end

  def first_in_r_orderby : Bool
    if (@ch == 'O' && in_res_word("ORDER", false))
      return true
    else
      return false
    end
  end

  def r_partby : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_partby", "")
    in_res_word("PARTITION")
    resword_AST = AbsSyntTree.new("resword", "resword", "PARTITION")
    as_AST.content.push(resword_AST)
    in_res_word("BY")
    resword_AST = AbsSyntTree.new("resword", "resword", "BY")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_TID())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_TID())
    end

    return as_AST
  end

  def first_in_r_partby : Bool
    if (@ch == 'P' && in_res_word("PARTITION", false))
      return true
    else
      return false
    end
  end

  def r_limit : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_limit", "")
    in_res_word("LIMIT")
    resword_AST = AbsSyntTree.new("resword", "resword", "LIMIT")
    as_AST.content.push(resword_AST)
    if first_in_r_Number_Lx()
      # 4->
      as_AST.content.push(r_Number_Lx())
      # <-4

      if (@ch == 'O' && in_res_word("OFFSET", false)) # '?'
        in_res_word("OFFSET")
        resword_AST = AbsSyntTree.new("resword", "resword", "OFFSET")
        as_AST.content.push(resword_AST)

        # 4->
        as_AST.content.push(r_Number_Lx())
        # <-4
      end
    elsif (@ch == ',' && in_res_oper(",", false))
      if (@ch == ',' && in_res_oper(",", false)) # '?'
        in_res_oper(",")
        resoper_AST = AbsSyntTree.new("resoper", "resoper", ",")
        as_AST.content.push(resoper_AST)

        # 4->
        as_AST.content.push(r_Number_Lx())
        # <-4
      end
    else
      error(%{no choice of first_in_r_Number_Lx()
(@ch == ',' && in_res_oper(",",false))})
    end

    return as_AST
  end

  def first_in_r_limit : Bool
    if (@ch == 'L' && in_res_word("LIMIT", false))
      return true
    else
      return false
    end
  end

  def r_window : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_window", "")
    in_res_word("WINDOW")
    resword_AST = AbsSyntTree.new("resword", "resword", "WINDOW")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_AS_TID())
    in_res_word("AS")
    resword_AST = AbsSyntTree.new("resword", "resword", "AS")
    as_AST.content.push(resword_AST)
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    if first_in_r_partby() # '?'
      as_AST.content.push(r_partby())
    end

    if first_in_r_orderby() # '?'
      as_AST.content.push(r_orderby())
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    return as_AST
  end

  def first_in_r_window : Bool
    if (@ch == 'W' && in_res_word("WINDOW", false))
      return true
    else
      return false
    end
  end

  def r_groupby : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_groupby", "")
    in_res_word("GROUP")
    resword_AST = AbsSyntTree.new("resword", "resword", "GROUP")
    as_AST.content.push(resword_AST)
    in_res_word("BY")
    resword_AST = AbsSyntTree.new("resword", "resword", "BY")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_TID())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_TID())
    end

    return as_AST
  end

  def first_in_r_groupby : Bool
    if (@ch == 'G' && in_res_word("GROUP", false))
      return true
    else
      return false
    end
  end

  def r_having : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_having", "")
    in_res_word("HAVING")
    resword_AST = AbsSyntTree.new("resword", "resword", "HAVING")
    as_AST.content.push(resword_AST)
    as_AST.content.push(r_fullcondexpr())
    return as_AST
  end

  def first_in_r_having : Bool
    if (@ch == 'H' && in_res_word("HAVING", false))
      return true
    else
      return false
    end
  end

  def r_project : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_project", "")
    if (@ch == '*' && in_res_oper("*", false))
      in_res_oper("*")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "*")
      as_AST.content.push(resoper_AST)
    elsif first_in_r_nyprojectitem()
      as_AST.content.push(r_nyprojectitem())
      if (@ch == 'A' && in_res_word("AS", false)) # '?'
        in_res_word("AS")
        resword_AST = AbsSyntTree.new("resword", "resword", "AS")
        as_AST.content.push(resword_AST)
        as_AST.content.push(r_AS_CID())
      end

      while @ch == ',' # ', '
        in_must_and_nowhite_next(',')
        as_AST.content.push(r_nyprojectitem())
        if (@ch == 'A' && in_res_word("AS", false)) # '?'
          in_res_word("AS")
          resword_AST = AbsSyntTree.new("resword", "resword", "AS")
          as_AST.content.push(resword_AST)
          as_AST.content.push(r_AS_CID())
        end
      end
    else
      error(%{no choice of (@ch == '*' && in_res_oper("*",false))
first_in_r_nyprojectitem()})
    end

    if (@ch == 'A' && in_res_word("AS", false)) # '?'
      in_res_word("AS")
      resword_AST = AbsSyntTree.new("resword", "resword", "AS")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_AS_TID())
    end

    return as_AST
  end

  def first_in_r_project : Bool
    if (@ch == '*' && in_res_oper("*", false)) || first_in_r_nyprojectitem()
      return true
    else
      return false
    end
  end

  def r_nyprojectitem : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_nyprojectitem", "")
    if (@ch == '(' && in_res_oper("(", false))
      in_res_oper("(")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
      as_AST.content.push(resoper_AST)
      as_AST.content.push(r_projselectbodyorscalarexp())
      in_res_oper(")")
      resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
      as_AST.content.push(resoper_AST)
    elsif first_in_r_simpleprojectitem()
      as_AST.content.push(r_simpleprojectitem())
    else
      error(%{no choice of (@ch == '(' && in_res_oper("(",false))
first_in_r_simpleprojectitem()})
    end

    return as_AST
  end

  def first_in_r_nyprojectitem : Bool
    if (@ch == '(' && in_res_oper("(", false)) || first_in_r_simpleprojectitem()
      return true
    else
      return false
    end
  end

  def r_projselectbodyorscalarexp : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_projselectbodyorscalarexp", "")
    if (@ch == 'S' && in_res_word("SELECT", false))
      in_res_word("SELECT")
      resword_AST = AbsSyntTree.new("resword", "resword", "SELECT")
      as_AST.content.push(resword_AST)
      as_AST.content.push(r_projectbody())
    elsif first_in_r_scalarexp()
      as_AST.content.push(r_scalarexp())
    else
      error(%{no choice of (@ch == 'S' && in_res_word("SELECT",false))
first_in_r_scalarexp()})
    end

    return as_AST
  end

  def first_in_r_projselectbodyorscalarexp : Bool
    if (@ch == 'S' && in_res_word("SELECT", false)) || first_in_r_scalarexp()
      return true
    else
      return false
    end
  end

  def r_simpleprojectitem : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_simpleprojectitem", "")
    if first_in_r_standardfunction()
      as_AST.content.push(r_standardfunction())
    elsif first_in_r_AS_TID() || first_in_r_SQString_Lx() || first_in_r_Number_Lx()
      if first_in_r_AS_TID()
        as_AST.content.push(r_AS_TID())
        if (@ch == '.' && in_res_oper(".*", false)) || (@ch == '.' && in_res_oper(".", false)) # '?'
          if (@ch == '.' && in_res_oper(".*", false))
            in_res_oper(".*")
            resoper_AST = AbsSyntTree.new("resoper", "resoper", ".*")
            as_AST.content.push(resoper_AST)
          elsif (@ch == '.' && in_res_oper(".", false))
            in_res_oper(".")
            resoper_AST = AbsSyntTree.new("resoper", "resoper", ".")
            as_AST.content.push(resoper_AST)
            as_AST.content.push(r_AS_CID())
          else
            error(%{no choice of (@ch == '.' && in_res_oper(".*",false))
(@ch == '.' && in_res_oper(".",false))})
          end
        end
      elsif first_in_r_SQString_Lx()
        # 4->
        as_AST.content.push(r_SQString_Lx())
        # <-4
      elsif first_in_r_Number_Lx()
        # 4->
        as_AST.content.push(r_Number_Lx())
        # <-4
      else
        error(%{no choice of first_in_r_AS_TID()
first_in_r_SQString_Lx()
first_in_r_Number_Lx()})
      end
    else
      error(%{no choice of first_in_r_standardfunction()
first_in_r_AS_TID() || first_in_r_SQString_Lx() || first_in_r_Number_Lx()})
    end

    return as_AST
  end

  def first_in_r_simpleprojectitem : Bool
    if first_in_r_standardfunction() || first_in_r_AS_TID() || first_in_r_SQString_Lx() || first_in_r_Number_Lx()
      return true
    else
      return false
    end
  end

  def r_standardfunction : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_standardfunction", "")
    if (@ch == 'M' && in_res_word("MIN", false))
      in_res_word("MIN")
      resword_AST = AbsSyntTree.new("resword", "resword", "MIN")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'M' && in_res_word("MAX", false))
      in_res_word("MAX")
      resword_AST = AbsSyntTree.new("resword", "resword", "MAX")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'A' && in_res_word("AVG", false))
      in_res_word("AVG")
      resword_AST = AbsSyntTree.new("resword", "resword", "AVG")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'S' && in_res_word("SUM", false))
      in_res_word("SUM")
      resword_AST = AbsSyntTree.new("resword", "resword", "SUM")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'C' && in_res_word("COUNT", false))
      in_res_word("COUNT")
      resword_AST = AbsSyntTree.new("resword", "resword", "COUNT")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'S' && in_res_word("STDDEV", false))
      in_res_word("STDDEV")
      resword_AST = AbsSyntTree.new("resword", "resword", "STDDEV")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'T' && in_res_word("TOUPPER", false))
      in_res_word("TOUPPER")
      resword_AST = AbsSyntTree.new("resword", "resword", "TOUPPER")
      as_AST.content.push(resword_AST)
    elsif (@ch == 'T' && in_res_word("TOLOWER", false))
      in_res_word("TOLOWER")
      resword_AST = AbsSyntTree.new("resword", "resword", "TOLOWER")
      as_AST.content.push(resword_AST)
    else
      error(%{no choice of (@ch == 'M' && in_res_word("MIN",false))
(@ch == 'M' && in_res_word("MAX",false))
(@ch == 'A' && in_res_word("AVG",false))
(@ch == 'S' && in_res_word("SUM",false))
(@ch == 'C' && in_res_word("COUNT",false))
(@ch == 'S' && in_res_word("STDDEV",false))
(@ch == 'T' && in_res_word("TOUPPER",false))
(@ch == 'T' && in_res_word("TOLOWER",false))})
    end

    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    if first_in_r_TID() # '?'
      as_AST.content.push(r_TID())
    end

    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    if first_in_r_over() # '?'
      as_AST.content.push(r_over())
    end

    return as_AST
  end

  def first_in_r_standardfunction : Bool
    if (@ch == 'M' && in_res_word("MIN", false)) || (@ch == 'M' && in_res_word("MAX", false)) || (@ch == 'A' && in_res_word("AVG", false)) || (@ch == 'S' && in_res_word("SUM", false)) || (@ch == 'C' && in_res_word("COUNT", false)) || (@ch == 'S' && in_res_word("STDDEV", false)) || (@ch == 'T' && in_res_word("TOUPPER", false)) || (@ch == 'T' && in_res_word("TOLOWER", false))
      return true
    else
      return false
    end
  end

  def r_over : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_over", "")
    in_res_word("OVER")
    resword_AST = AbsSyntTree.new("resword", "resword", "OVER")
    as_AST.content.push(resword_AST)
    in_res_oper("(")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", "(")
    as_AST.content.push(resoper_AST)
    as_AST.content.push(r_AS_TID())
    in_res_oper(")")
    resoper_AST = AbsSyntTree.new("resoper", "resoper", ")")
    as_AST.content.push(resoper_AST)
    if first_in_r_orderby() # '?'
      as_AST.content.push(r_orderby())
    end

    return as_AST
  end

  def first_in_r_over : Bool
    if (@ch == 'O' && in_res_word("OVER", false))
      return true
    else
      return false
    end
  end

  def r_column_comma_list : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_column_comma_list", "")
    as_AST.content.push(r_AS_CID())

    while @ch == ',' # ', '
      in_must_and_nowhite_next(',')
      as_AST.content.push(r_AS_CID())
    end

    return as_AST
  end

  def first_in_r_column_comma_list : Bool
    if first_in_r_AS_CID()
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

  def r_AS_TID : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_AS_TID", "")

    # 4->
    as_AST.content.push(r_Identifier_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_AS_TID : Bool
    if first_in_r_Identifier_Lx()
      return true
    else
      return false
    end
  end

  def r_AS_CID : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_AS_CID", "")

    # 4->
    as_AST.content.push(r_Identifier_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_AS_CID : Bool
    if first_in_r_Identifier_Lx()
      return true
    else
      return false
    end
  end

  def r_TID : AbsSyntTree
    as_AST = AbsSyntTree.new("rule", "r_TID", "")

    # 4->
    as_AST.content.push(r_Identifier_Lx())
    # <-4

    r_in_must_and_nowhite_next('.')

    # 4->
    as_AST.content.push(r_Identifier_Lx())
    # <-4

    return as_AST
  end

  def first_in_r_TID : Bool
    if first_in_r_Identifier_Lx()
      return true
    else
      return false
    end
  end
end
