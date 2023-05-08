class DBDefGen
  def initialize
  end

  # =============================
  def is_type_Program(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Program"
  end

  def r_Program(rules : InAst::AbsSyntTree)
    if !is_type_Program(rules)
      pp rules
      raise "Wrong rule to 'r_Program' "
    end
    stpr = Stepper.new(rules)

    if stpr.having_more # rep '?'
      if is_type_with(stpr.content_now)
        ret = r_with(stpr.content_now)
        stpr.next
      end
    end

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "INSERT")
      pp stpr.content_now
      raise "Expecting 'INSERT' "
    end
    stpr.next
#==============================

#===============================
    ret = r_insertbody(stpr.content_now)
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      pp stpr.content_now
      raise "Expecting 'SELECT' "
    end
    stpr.next

    ret = r_projectbody(stpr.content_now)
    stpr.next

    if stpr.having_more # rep '?'
      if is_type_orderby(stpr.content_now)
        ret = r_orderby(stpr.content_now)
        stpr.next
      end
    end
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "UPDATE")
      pp stpr.content_now
      raise "Expecting 'UPDATE' "
    end
    stpr.next

    ret = r_updatebody(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ";")
      pp stpr.content_now
      raise "Expecting ';' "
    end
    stpr.next
  end

  # =============================
  def is_type_with(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_with"
  end

  def r_with(rules : InAst::AbsSyntTree)
    if !is_type_with(rules)
      pp rules
      raise "Wrong rule to 'r_with' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "WITH")
      pp stpr.content_now
      raise "Expecting 'WITH' "
    end
    stpr.next

    while stpr.having_more && stpr.content_now.kind == "group" # rep '*'

      ret = r_withplain(stpr.content_now)
      stpr.next # ','
      while stpr.having_more && is_type_withplain(stpr.content_now)
        ret = r_withplain(stpr.content_now)
        stpr.next
      end
    end

    if stpr.having_more # rep '?'
      if is_type_withrecur(stpr.content_now)
        ret = r_withrecur(stpr.content_now)
        stpr.next
      end
    end
  end

  # =============================
  def is_type_withplain(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_withplain"
  end

  def r_withplain(rules : InAst::AbsSyntTree)
    if !is_type_withplain(rules)
      pp rules
      raise "Wrong rule to 'r_withplain' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "NONERECURSIVE")
      pp stpr.content_now
      raise "Expecting 'NONERECURSIVE' "
    end
    stpr.next

    ret = r_tablename(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_column_comma_list(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
      pp stpr.content_now
      raise "Expecting 'AS' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      pp stpr.content_now
      raise "Expecting 'SELECT' "
    end
    stpr.next

    ret = r_projectbody(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
  end

  # =============================
  def is_type_withrecur(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_withrecur"
  end

  def r_withrecur(rules : InAst::AbsSyntTree)
    if !is_type_withrecur(rules)
      pp rules
      raise "Wrong rule to 'r_withrecur' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "RECURSIVE")
      pp stpr.content_now
      raise "Expecting 'RECURSIVE' "
    end
    stpr.next

    ret = r_tablename(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_column_comma_list(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
      pp stpr.content_now
      raise "Expecting 'AS' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      pp stpr.content_now
      raise "Expecting 'SELECT' "
    end
    stpr.next

    ret = r_projectbody(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "UNION")
      pp stpr.content_now
      raise "Expecting 'UNION' "
    end
    stpr.next

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "resword" && stpr.content_now.value == ALL
        if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "ALL")
          pp stpr.content_now
          raise "Expecting 'ALL' "
        end
        stpr.next
      end
    end

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      pp stpr.content_now
      raise "Expecting 'SELECT' "
    end
    stpr.next

    ret = r_projectbody(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
  end

  # =============================
  def is_type_insertbody(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_insertbody"
  end

  def r_insertbody(rules : InAst::AbsSyntTree)
    if !is_type_insertbody(rules)
      pp rules
      raise "Wrong rule to 'r_insertbody' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "body")
      pp stpr.content_now
      raise "Expecting 'body' "
    end
    stpr.next
  end

  # =============================
  def is_type_updatebody(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_updatebody"
  end

  def r_updatebody(rules : InAst::AbsSyntTree)
    if !is_type_updatebody(rules)
      pp rules
      raise "Wrong rule to 'r_updatebody' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "body")
      pp stpr.content_now
      raise "Expecting 'body' "
    end
    stpr.next
  end

  # =============================
  def is_type_projectbody(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_projectbody"
  end

  def r_projectbody(rules : InAst::AbsSyntTree)
    if !is_type_projectbody(rules)
      pp rules
      raise "Wrong rule to 'r_projectbody' "
    end
    stpr = Stepper.new(rules)

    ret = r_project(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "FROM")
      pp stpr.content_now
      raise "Expecting 'FROM' "
    end
    stpr.next

    ret = r_from(stpr.content_now)
    stpr.next

    if stpr.having_more # rep '?'
      if is_type_where(stpr.content_now)
        ret = r_where(stpr.content_now)
        stpr.next
      end
    end

    if stpr.having_more # rep '?'
      if is_type_groupby(stpr.content_now)
        ret = r_groupby(stpr.content_now)
        stpr.next
      end
    end

    if stpr.having_more # rep '?'
      if is_type_having(stpr.content_now)
        ret = r_having(stpr.content_now)
        stpr.next
      end
    end
  end

  # =============================
  def is_type_from(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_from"
  end

  def r_from(rules : InAst::AbsSyntTree)
    if !is_type_from(rules)
      pp rules
      raise "Wrong rule to 'r_from' "
    end
    stpr = Stepper.new(rules)

    ret = r_table_ref(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_table_ref(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_table_ref"
  end

  def r_table_ref(rules : InAst::AbsSyntTree)
    if !is_type_table_ref(rules)
      pp rules
      raise "Wrong rule to 'r_table_ref' "
    end
    stpr = Stepper.new(rules)

    ret = r_relation_body(stpr.content_now)
    stpr.next

    while stpr.having_more && is_type_joiner_or_setoper(stpr.content_now) # rep '*'

      ret = r_joiner_or_setoper(stpr.content_now)
      stpr.next
    end
  end

  # =============================
  def is_type_relation_body(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_relation_body"
  end

  def r_relation_body(rules : InAst::AbsSyntTree)
    if !is_type_relation_body(rules)
      pp rules
      raise "Wrong rule to 'r_relation_body' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_relation_body(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "VALUES")
      pp stpr.content_now
      raise "Expecting 'VALUES' "
    end
    stpr.next

    ret = r_value_list(stpr.content_now)
    stpr.next

    if stpr.having_more # rep '?'
      if is_type_tbl_col_alias(stpr.content_now)
        ret = r_tbl_col_alias(stpr.content_now)
        stpr.next
      end
    end
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      pp stpr.content_now
      raise "Expecting 'SELECT' "
    end
    stpr.next

    ret = r_project_expression(stpr.content_now)
    stpr.next
    ret = r_tablename(stpr.content_now)
    stpr.next

    if stpr.having_more # rep '?'
      if is_type_tbl_col_alias(stpr.content_now)
        ret = r_tbl_col_alias(stpr.content_now)
        stpr.next
      end
    end
  end

  # =============================
  def is_type_tablename(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_tablename"
  end

  def r_tablename(rules : InAst::AbsSyntTree)
    if !is_type_tablename(rules)
      pp rules
      raise "Wrong rule to 'r_tablename' "
    end
    stpr = Stepper.new(rules)

    ret = r_Identifier_Lx(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_project_expression(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_project_expression"
  end

  def r_project_expression(rules : InAst::AbsSyntTree)
    if !is_type_project_expression(rules)
      pp rules
      raise "Wrong rule to 'r_project_expression' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      pp stpr.content_now
      raise "Expecting 'SELECT' "
    end
    stpr.next
  end

  # =============================
  def is_type_value_list(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_value_list"
  end

  def r_value_list(rules : InAst::AbsSyntTree)
    if !is_type_value_list(rules)
      pp rules
      raise "Wrong rule to 'r_value_list' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_DQString_Lx(stpr.content_now)
    stpr.next
    ret = r_SQString_Lx(stpr.content_now)
    stpr.next
    ret = r_Number_Lx(stpr.content_now)
    stpr.next # ','
    while stpr.having_more && stpr.content_now.kind == "group"
      ret = r_DQString_Lx(stpr.content_now)
      stpr.next
      ret = r_SQString_Lx(stpr.content_now)
      stpr.next
      ret = r_Number_Lx(stpr.content_now)
      stpr.next
    end

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next # ','
    while stpr.having_more && stpr.content_now.kind == "group"
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
        pp stpr.content_now
        raise "Expecting '(' "
      end
      stpr.next

      ret = r_DQString_Lx(stpr.content_now)
      stpr.next
      ret = r_SQString_Lx(stpr.content_now)
      stpr.next
      ret = r_Number_Lx(stpr.content_now)
      stpr.next # ','
      while stpr.having_more && stpr.content_now.kind == "group"
        ret = r_DQString_Lx(stpr.content_now)
        stpr.next
        ret = r_SQString_Lx(stpr.content_now)
        stpr.next
        ret = r_Number_Lx(stpr.content_now)
        stpr.next
      end

      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
        pp stpr.content_now
        raise "Expecting ')' "
      end
      stpr.next
    end
  end

  # =============================
  def is_type_tbl_col_alias(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_tbl_col_alias"
  end

  def r_tbl_col_alias(rules : InAst::AbsSyntTree)
    if !is_type_tbl_col_alias(rules)
      pp rules
      raise "Wrong rule to 'r_tbl_col_alias' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
      pp stpr.content_now
      raise "Expecting 'AS' "
    end
    stpr.next

    ret = r_AS_TID(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_column_comma_list(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
  end

  # =============================
  def is_type_tbl_alias(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_tbl_alias"
  end

  def r_tbl_alias(rules : InAst::AbsSyntTree)
    if !is_type_tbl_alias(rules)
      pp rules
      raise "Wrong rule to 'r_tbl_alias' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
      pp stpr.content_now
      raise "Expecting 'AS' "
    end
    stpr.next

    ret = r_AS_TID(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_joiner_or_setoper(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_joiner_or_setoper"
  end

  def r_joiner_or_setoper(rules : InAst::AbsSyntTree)
    if !is_type_joiner_or_setoper(rules)
      pp rules
      raise "Wrong rule to 'r_joiner_or_setoper' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "JOIN")
      pp stpr.content_now
      raise "Expecting 'JOIN' "
    end
    stpr.next
    ret = r_join_type(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "JOIN")
      pp stpr.content_now
      raise "Expecting 'JOIN' "
    end
    stpr.next

    ret = r_relation_body(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "ON")
      pp stpr.content_now
      raise "Expecting 'ON' "
    end
    stpr.next

    ret = r_pcondexpr(stpr.content_now)
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "UNION")
      pp stpr.content_now
      raise "Expecting 'UNION' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "EXCEPT")
      pp stpr.content_now
      raise "Expecting 'EXCEPT' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "INTERSECT")
      pp stpr.content_now
      raise "Expecting 'INTERSECT' "
    end
    stpr.next

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "resword" && stpr.content_now.value == ALL
        if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "ALL")
          pp stpr.content_now
          raise "Expecting 'ALL' "
        end
        stpr.next
      end
    end

    ret = r_relation_body(stpr.content_now)
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "CROSS")
      pp stpr.content_now
      raise "Expecting 'CROSS' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "JOIN")
      pp stpr.content_now
      raise "Expecting 'JOIN' "
    end
    stpr.next

    ret = r_relation_body(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_join_type(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_join_type"
  end

  def r_join_type(rules : InAst::AbsSyntTree)
    if !is_type_join_type(rules)
      pp rules
      raise "Wrong rule to 'r_join_type' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "INNER")
      pp stpr.content_now
      raise "Expecting 'INNER' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "LEFT")
      pp stpr.content_now
      raise "Expecting 'LEFT' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "RIGHT")
      pp stpr.content_now
      raise "Expecting 'RIGHT' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "FULL")
      pp stpr.content_now
      raise "Expecting 'FULL' "
    end
    stpr.next

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "resword" && stpr.content_now.value == OUTER
        if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "OUTER")
          pp stpr.content_now
          raise "Expecting 'OUTER' "
        end
        stpr.next
      end
    end
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "UNION")
      pp stpr.content_now
      raise "Expecting 'UNION' "
    end
    stpr.next
  end

  # =============================
  def is_type_where(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_where"
  end

  def r_where(rules : InAst::AbsSyntTree)
    if !is_type_where(rules)
      pp rules
      raise "Wrong rule to 'r_where' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "WHERE")
      pp stpr.content_now
      raise "Expecting 'WHERE' "
    end
    stpr.next

    ret = r_pcondexpr(stpr.content_now)
    stpr.next

    while stpr.having_more && stpr.content_now.kind == "group" # rep '*'

      if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AND")
        pp stpr.content_now
        raise "Expecting 'AND' "
      end
      stpr.next
      if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "OR")
        pp stpr.content_now
        raise "Expecting 'OR' "
      end
      stpr.next

      ret = r_pcondexpr(stpr.content_now)
      stpr.next
    end
  end

  # =============================
  def is_type_pcondexpr(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_pcondexpr"
  end

  def r_pcondexpr(rules : InAst::AbsSyntTree)
    if !is_type_pcondexpr(rules)
      pp rules
      raise "Wrong rule to 'r_pcondexpr' "
    end
    stpr = Stepper.new(rules)

    ret = r_condexpr(stpr.content_now)
    stpr.next

    ret = r_condexpr(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_condexpr(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_condexpr"
  end

  def r_condexpr(rules : InAst::AbsSyntTree)
    if !is_type_condexpr(rules)
      pp rules
      raise "Wrong rule to 'r_condexpr' "
    end
    stpr = Stepper.new(rules)

    ret = r_simplecond(stpr.content_now)
    stpr.next

    ret = r_condexpr(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_simplecond(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_simplecond"
  end

  def r_simplecond(rules : InAst::AbsSyntTree)
    if !is_type_simplecond(rules)
      pp rules
      raise "Wrong rule to 'r_simplecond' "
    end
    stpr = Stepper.new(rules)

    ret = r_psimplecond(stpr.content_now)
    stpr.next

    ret = r_compoper_Lx(stpr.content_now)
    stpr.next

    ret = r_psimplecond(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_psimplecond(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_psimplecond"
  end

  def r_psimplecond(rules : InAst::AbsSyntTree)
    if !is_type_psimplecond(rules)
      pp rules
      raise "Wrong rule to 'r_psimplecond' "
    end
    stpr = Stepper.new(rules)

    ret = r_scalarexp(stpr.content_now)
    stpr.next

    ret = r_scalarexp(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_scalarexp(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_scalarexp"
  end

  def r_scalarexp(rules : InAst::AbsSyntTree)
    if !is_type_scalarexp(rules)
      pp rules
      raise "Wrong rule to 'r_scalarexp' "
    end
    stpr = Stepper.new(rules)

    ret = r_pscalarexp(stpr.content_now)
    stpr.next

    while stpr.having_more && stpr.content_now.kind == "group" # rep '*'

      ret = r_scalaroper_Lx(stpr.content_now)
      stpr.next

      ret = r_pscalarexp(stpr.content_now)
      stpr.next
    end
  end

  # =============================
  def is_type_pscalarexp(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_pscalarexp"
  end

  def r_pscalarexp(rules : InAst::AbsSyntTree)
    if !is_type_pscalarexp(rules)
      pp rules
      raise "Wrong rule to 'r_pscalarexp' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(SELECT")
      pp stpr.content_now
      raise "Expecting '(SELECT' "
    end
    stpr.next

    ret = r_projectbody(stpr.content_now)
    stpr.next

    ret = r_scalarexp(stpr.content_now)
    stpr.next

    ret = r_scalarterm(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_scalarterm(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_scalarterm"
  end

  def r_scalarterm(rules : InAst::AbsSyntTree)
    if !is_type_scalarterm(rules)
      pp rules
      raise "Wrong rule to 'r_scalarterm' "
    end
    stpr = Stepper.new(rules)

    ret = r_TID(stpr.content_now)
    stpr.next
    ret = r_DQString_Lx(stpr.content_now)
    stpr.next
    ret = r_SQString_Lx(stpr.content_now)
    stpr.next
    ret = r_Number_Lx(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_orderby(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_orderby"
  end

  def r_orderby(rules : InAst::AbsSyntTree)
    if !is_type_orderby(rules)
      pp rules
      raise "Wrong rule to 'r_orderby' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "ORDER BY")
      pp stpr.content_now
      raise "Expecting 'ORDER BY' "
    end
    stpr.next

    ret = r_TID(stpr.content_now)
    stpr.next # ','
    while stpr.having_more && stpr.content_now.kind == "group"
      ret = r_TID(stpr.content_now)
      stpr.next
    end
  end

  # =============================
  def is_type_groupby(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_groupby"
  end

  def r_groupby(rules : InAst::AbsSyntTree)
    if !is_type_groupby(rules)
      pp rules
      raise "Wrong rule to 'r_groupby' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "GROUP BY")
      pp stpr.content_now
      raise "Expecting 'GROUP BY' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_TID(stpr.content_now)
    stpr.next # ','
    while stpr.having_more && stpr.content_now.kind == "group"
      ret = r_TID(stpr.content_now)
      stpr.next
    end

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
  end

  # =============================
  def is_type_having(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_having"
  end

  def r_having(rules : InAst::AbsSyntTree)
    if !is_type_having(rules)
      pp rules
      raise "Wrong rule to 'r_having' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "having")
      pp stpr.content_now
      raise "Expecting 'having' "
    end
    stpr.next
  end

  # =============================
  def is_type_project(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_project"
  end

  def r_project(rules : InAst::AbsSyntTree)
    if !is_type_project(rules)
      pp rules
      raise "Wrong rule to 'r_project' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "*")
      pp stpr.content_now
      raise "Expecting '*' "
    end
    stpr.next
    ret = r_projectitem(stpr.content_now)
    stpr.next

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "group"
        if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
          pp stpr.content_now
          raise "Expecting 'AS' "
        end
        stpr.next

        ret = r_AS_CID(stpr.content_now)
        stpr.next
      end
    end # ','
    while stpr.having_more && stpr.content_now.kind == "group"
      ret = r_projectitem(stpr.content_now)
      stpr.next

      if stpr.having_more # rep '?'
        if stpr.content_now.kind == "group"
          if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
            pp stpr.content_now
            raise "Expecting 'AS' "
          end
          stpr.next

          ret = r_AS_CID(stpr.content_now)
          stpr.next
        end
      end
    end

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "group"
        if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
          pp stpr.content_now
          raise "Expecting 'AS' "
        end
        stpr.next

        ret = r_AS_TID(stpr.content_now)
        stpr.next
      end
    end
  end

  # =============================
  def is_type_projectitem(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_projectitem"
  end

  def r_projectitem(rules : InAst::AbsSyntTree)
    if !is_type_projectitem(rules)
      pp rules
      raise "Wrong rule to 'r_projectitem' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(SELECT")
      pp stpr.content_now
      raise "Expecting '(SELECT' "
    end
    stpr.next

    ret = r_projectbody(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next

    ret = r_scalarexp(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
    ret = r_simpleprojectitem(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_simpleprojectitem(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_simpleprojectitem"
  end

  def r_simpleprojectitem(rules : InAst::AbsSyntTree)
    if !is_type_simpleprojectitem(rules)
      pp rules
      raise "Wrong rule to 'r_simpleprojectitem' "
    end
    stpr = Stepper.new(rules)

    ret = r_standardfunction(stpr.content_now)
    stpr.next
    ret = r_AS_TID(stpr.content_now)
    stpr.next

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "group"
        if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ".*")
          pp stpr.content_now
          raise "Expecting '.*' "
        end
        stpr.next
        if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ".")
          pp stpr.content_now
          raise "Expecting '.' "
        end
        stpr.next

        ret = r_AS_CID(stpr.content_now)
        stpr.next
      end
    end
    ret = r_SQString_Lx(stpr.content_now)
    stpr.next
    ret = r_Number_Lx(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_standardfunction(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_standardfunction"
  end

  def r_standardfunction(rules : InAst::AbsSyntTree)
    if !is_type_standardfunction(rules)
      pp rules
      raise "Wrong rule to 'r_standardfunction' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "MIN(")
      pp stpr.content_now
      raise "Expecting 'MIN(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "MAX(")
      pp stpr.content_now
      raise "Expecting 'MAX(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "AVG(")
      pp stpr.content_now
      raise "Expecting 'AVG(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "SUM(")
      pp stpr.content_now
      raise "Expecting 'SUM(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "COUNT(")
      pp stpr.content_now
      raise "Expecting 'COUNT(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "STDDEV(")
      pp stpr.content_now
      raise "Expecting 'STDDEV(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "TOUPPER(")
      pp stpr.content_now
      raise "Expecting 'TOUPPER(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "TOLOWER(")
      pp stpr.content_now
      raise "Expecting 'TOLOWER(' "
    end
    stpr.next

    ret = r_TID(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
  end

  # =============================
  def is_type_column_comma_list(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_column_comma_list"
  end

  def r_column_comma_list(rules : InAst::AbsSyntTree)
    if !is_type_column_comma_list(rules)
      pp rules
      raise "Wrong rule to 'r_column_comma_list' "
    end
    stpr = Stepper.new(rules)

    ret = r_AS_CID(stpr.content_now)
    stpr.next # ','
    while stpr.having_more && is_type_AS_CID(stpr.content_now)
      ret = r_AS_CID(stpr.content_now)
      stpr.next
    end
  end

  # =============================
  def is_type_Literal_Cs(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Literal_Cs"
  end

  def r_Literal_Cs(rules : InAst::AbsSyntTree)
    if !is_type_Literal_Cs(rules)
      pp rules
      raise "Wrong rule to 'r_Literal_Cs' "
    end
    stpr = Stepper.new(rules)
    genCharSetExprgenCharSetExpr
  end

  # =============================
  def is_type_Digit09_Cs(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Digit09_Cs"
  end

  def r_Digit09_Cs(rules : InAst::AbsSyntTree)
    if !is_type_Digit09_Cs(rules)
      pp rules
      raise "Wrong rule to 'r_Digit09_Cs' "
    end
    stpr = Stepper.new(rules)
    genCharSetExpr
  end

  # =============================
  def is_type_Digit19_Cs(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Digit19_Cs"
  end

  def r_Digit19_Cs(rules : InAst::AbsSyntTree)
    if !is_type_Digit19_Cs(rules)
      pp rules
      raise "Wrong rule to 'r_Digit19_Cs' "
    end
    stpr = Stepper.new(rules)
    genCharSetExpr
  end

  # =============================
  def is_type_AS_TID(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_AS_TID"
  end

  def r_AS_TID(rules : InAst::AbsSyntTree)
    if !is_type_AS_TID(rules)
      pp rules
      raise "Wrong rule to 'r_AS_TID' "
    end
    stpr = Stepper.new(rules)

    ret = r_Identifier_Lx(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_AS_CID(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_AS_CID"
  end

  def r_AS_CID(rules : InAst::AbsSyntTree)
    if !is_type_AS_CID(rules)
      pp rules
      raise "Wrong rule to 'r_AS_CID' "
    end
    stpr = Stepper.new(rules)

    ret = r_Identifier_Lx(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_TID(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_TID"
  end

  def r_TID(rules : InAst::AbsSyntTree)
    if !is_type_TID(rules)
      pp rules
      raise "Wrong rule to 'r_TID' "
    end
    stpr = Stepper.new(rules)

    ret = r_Identifier_Lx(stpr.content_now)
    stpr.next

    ret = r_Identifier_Lx(stpr.content_now)
    stpr.next
  end

  # =============================
  def is_type_Number_Lx(rules : InAst::AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Number_Lx"
  end

  def r_Number_Lx(rules : InAst::AbsSyntTree)
    if !is_type_Number_Lx(rules)
      pp rules
      raise "Wrong rule to 'r_Number_Lx' "
    end
    stpr = Stepper.new(rules)

    while stpr.having_more && r_Digit09_Cs() # rep '*'

      ret = r_Digit09_Cs(stpr.content_now)
      stpr.next
    end

    if stpr.having_more # rep '?'
      if stpr.content_now.kind == "group"
        while stpr.having_more && r_Digit09_Cs() # rep '*'

          ret = r_Digit09_Cs(stpr.content_now)
          stpr.next
        end
      end
    end
  end
end
