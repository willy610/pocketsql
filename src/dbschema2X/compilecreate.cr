class CompileCreate
  def initialize
  end

  # =============================
  def type_Createtable(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Createtable"
  end

  def r_Createtable(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_Createtable")
      pp rules
      raise "Wrong rule to 'r_Createtable' "
    end
    stpr = Stepper.new(rules)
    ret = r_create(stpr.content_now)
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ";")
      pp stpr.content_now
      raise "Expecting ';' "
    end
    ret
  end

  # =============================
  def type_create(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_create"
  end

  def r_create(rules : AbsSyntTree)
    # "CREATE" "ENTITYTABLE"
    #   "(" enttable +  ")"
    #    (
    #       "RELATIONSHIPTABLE" "(" reltable + ")"
    #    )? ;
    if !(rules.kind == "rule" && rules.rule_name == "r_create")
      pp rules
      raise "Wrong rule to 'r_create' "
    end
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "CREATE")
      pp stpr.content_now
      raise "Expecting 'CREATE' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "ENTITYTABLE")
      pp stpr.content_now
      raise "Expecting 'ENTITYTABLE' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    a_Rot = Rot.new
    a_BasTableCreate = r_enttable(stpr.content_now)
    a_Rot.tables << a_BasTableCreate
    stpr.next
    while stpr.having_more && type_enttable(stpr.content_now)
      a_BasTableCreate = r_enttable(stpr.content_now)
      a_Rot.tables << a_BasTableCreate
      stpr.next
    end
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
    if stpr.having_more
      if (stpr.content_now.kind == "resword" && stpr.content_now.value == "RELATIONSHIPTABLE")
        stpr.next
        if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
          pp stpr.content_now
          raise "Expecting '(' "
        end
        stpr.next
        a_BasTableCreate = r_reltable(stpr.content_now)
        a_Rot.tables << a_BasTableCreate

        stpr.next
        while stpr.having_more && type_reltable(stpr.content_now)
          a_BasTableCreate = r_reltable(stpr.content_now)
          a_Rot.tables << a_BasTableCreate

          stpr.next
        end
        if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
          pp stpr.content_now
          raise "Expecting ')' "
        end
        stpr.next
      end
    end

    a_Rot
  end

  # =============================
  def type_enttable(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_enttable"
  end

  def r_enttable(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_enttable")
      pp rules
      raise "Wrong rule to 'r_enttable' "
    end
    a_BasTableCreate = BasTableCreate.new
    a_BasTableCreate.kind = "entity"

    stpr = Stepper.new(rules)
    table_name = r_tablename(stpr.content_now)
    a_BasTableCreate.tablename = table_name

    stpr.next
    a_EntityTableCreate = EntityTableCreate.new

    pks = r_entkey(stpr.content_now)
    a_EntityTableCreate.pk = pks.first
    my_RaletedColumnCreate : Array(FKCreate) = [] of FKCreate
    stpr.next
    # relcols ?
    if stpr.having_more # rep '?'
      if is_type_relcols(stpr.content_now)
        my_RaletedColumnCreate = r_relcols(stpr.content_now)
        stpr.next
      end
    end
    # plaincols?
    my_PlainColumnCreate : Array(PlainColumnCreate) = [] of PlainColumnCreate
    if stpr.having_more # rep '?'
      if is_type_plaincols(stpr.content_now)
        my_PlainColumnCreate = r_plaincols(stpr.content_now)
        stpr.next
      end
    end
    a_BasTableCreate.plain_attributes = my_PlainColumnCreate
    a_BasTableCreate.related_attributes = my_RaletedColumnCreate

    # # OLD
    #     if stpr.having_more && type_relcols(stpr.content_now)
    #       my_RaletedColumnCreate = r_relcols(stpr.content_now)
    #       stpr.next
    #     end

    #     if stpr.having_more && is_type_plaincols(stpr.content_now)
    #       my_PlainColumnCreate = r_plaincols(stpr.content_now)
    #       stpr.next
    #     end
    #     a_BasTableCreate = BasTableCreate.new
    #     a_BasTableCreate.kind = "entity"
    #     a_BasTableCreate.tablename = table_name
    #     #
    #     a_EntityTableCreate = EntityTableCreate.new
    #     a_EntityTableCreate.pk = pks.first
    #     if !my_PlainColumnCreate.nil?
    #       a_BasTableCreate.plain_attributes = my_PlainColumnCreate
    #     end
    #     if !my_RaletedColumnCreate.nil?
    #       a_BasTableCreate.related_attributes = my_RaletedColumnCreate
    #     end
    a_BasTableCreate.entity = a_EntityTableCreate
    return a_BasTableCreate
  end

  # =============================
  def type_reltable(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_reltable"
  end

  def r_reltable(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_reltable")
      pp rules
      raise "Wrong rule to 'r_reltable' "
    end
    stpr = Stepper.new(rules)
    table_name = r_tablename(stpr.content_now)

    stpr.next
    from_r_relkey = r_relkey(stpr.content_now)
    #
    a_BasTableCreate = BasTableCreate.new
    a_BasTableCreate.kind = "relationship"
    a_BasTableCreate.tablename = table_name
    #
    a_RelatTableCreate = RelatTableCreate.new
    a_RelatTableCreate.parent_tables = from_r_relkey[:all_ParentCreate]
    a_RelatTableCreate.own_primary = from_r_relkey[:own_Primary]

    stpr.next
    my_RaletedColumnCreate : Array(FKCreate) = [] of FKCreate
    my_PlainColumnCreate : Array(PlainColumnCreate) = [] of PlainColumnCreate

    if stpr.having_more # rep '?'
      if is_type_relcols(stpr.content_now)
        my_RaletedColumnCreate = r_relcols(stpr.content_now)
        stpr.next
      end
    end
    if stpr.having_more # rep '?'
      if is_type_plaincols(stpr.content_now)
        my_PlainColumnCreate = r_plaincols(stpr.content_now)
        stpr.next
      end
    end
    # #OLD
    #     if stpr.having_more && type_relcols(stpr.content_now)
    #       my_RaletedColumnCreate = r_relcols(stpr.content_now)
    #       stpr.next
    #     end
    #     if stpr.having_more && is_type_plaincols(stpr.content_now)
    #       my_PlainColumnCreate = r_plaincols(stpr.content_now)
    #       stpr.next
    #     end
    #     if !my_PlainColumnCreate.nil?
    #       a_BasTableCreate.plain_attributes = my_PlainColumnCreate
    #     end
    #     if !my_RaletedColumnCreate.nil?
    #       a_BasTableCreate.related_attributes = my_RaletedColumnCreate
    #     end

    #     a_BasTableCreate.relat = a_RelatTableCreate
    a_BasTableCreate.plain_attributes = my_PlainColumnCreate
    a_BasTableCreate.related_attributes = my_RaletedColumnCreate
    a_BasTableCreate.relat = a_RelatTableCreate
    return a_BasTableCreate
  end

  # =============================
  def type_entkey(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_entkey"
  end

  def r_entkey(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_entkey")
      pp rules
      raise "Wrong rule to 'r_entkey' "
    end

    # primary_key : Array({col_name: String, sql_attr: String}) = [] of {col_name: String, sql_attr: String}
    primary_key : Array(ParentPKAttribs) = [] of ParentPKAttribs
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "PRIMARYKEY")
      pp stpr.content_now
      raise "Expecting 'PRIMARYKEY' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    # {col_name: col_name, sql_attr: sql_attr}
    ret = r_acolumn(stpr.content_now)
    # primary_key << {ret[:col_name],ret[:sql_attr]}
    primary_key << ret
    stpr.next
    while stpr.having_more && type_acolumn(stpr.content_now)
      # {col_name: col_name, sql_attr: sql_attr}
      ret = r_acolumn(stpr.content_now)
      # primary_key << {ret[:col_name],ret[:sql_attr]}
      primary_key << ret
      stpr.next
    end
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
    primary_key
  end

  # =============================
  def type_relkey(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_relkey"
  end

  def r_relkey(rules : AbsSyntTree)
    # "PRIMARYKEY" "("
    #     "PARENTS" "("
    #       (
    #         (tablenameandmore ),','
    #       )+
    #     ")"
    #   ("OWNPRIMARY" "(" acolumn (',' acolumn) *  ")" )?
    #    ")";
    if !(rules.kind == "rule" && rules.rule_name == "r_relkey")
      pp rules
      raise "Wrong rule to 'r_relkey' "
    end
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "PRIMARYKEY")
      pp stpr.content_now
      raise "Expecting 'PRIMARYKEY' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "PARENTS")
      pp stpr.content_now
      raise "Expecting 'PARENTS' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end

    stpr.next

    all_ParentCreate : Array(FKCreate) = [] of FKCreate
    ret = r_tablenameandmore(stpr.content_now)
    an_FKCreate = FKCreate.new
    an_FKCreate.parent_table_name = ret[:table_name]
    an_FKCreate.prefix = ret[:parents]
    all_ParentCreate << an_FKCreate
    stpr.next
    while stpr.having_more && type_tablenameandmore(stpr.content_now)
      ret = r_tablenameandmore(stpr.content_now)
      an_FKCreate = FKCreate.new
      an_FKCreate.parent_table_name = ret[:table_name]
      an_FKCreate.prefix = ret[:parents]
      all_ParentCreate << an_FKCreate
      stpr.next
    end
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next

    # own_Primary : Array({col_name: String, sql_attr: String | Nil}) = [] of {col_name: String, sql_attr: String | Nil}
    own_Primary : Array(ParentPKAttribs) = [] of ParentPKAttribs
    if stpr.having_more
      if (stpr.content_now.kind == "resword" && stpr.content_now.value == "OWNPRIMARY")
        stpr.next
        if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
          pp stpr.content_now
          raise "Expecting '(' "
        end
        stpr.next
        ret = r_acolumn(stpr.content_now)
        own_Primary << ret
        stpr.next
        while stpr.having_more && type_acolumn(stpr.content_now)
          ret = r_acolumn(stpr.content_now)
          own_Primary << ret
          stpr.next
        end
        if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
          pp stpr.content_now
          raise "Expecting ')' "
        end
        stpr.next
      end
    end

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    return {all_ParentCreate: all_ParentCreate, own_Primary: own_Primary}
  end

  # =============================
  def type_tablenameandmore(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_tablenameandmore"
  end

  #
  # rule: "tablenameandmore", body: %[ tablename parentas? sqlattribute? ;
  #
  def r_tablenameandmore(rules : AbsSyntTree)
    if !type_tablenameandmore(rules)
      pp rules
      raise "Wrong rule to 'r_tablenameandmore' "
    end
    stpr = Stepper.new(rules)

    table_name = r_tablename(stpr.content_now)
    stpr.next
    parents = ""
    sqlattr = "NO SQLATTR"
    if stpr.having_more # rep '?'
      if type_prefixed(stpr.content_now)
        parents = r_prefixed(stpr.content_now)
        stpr.next
      end
    end

    if stpr.having_more # rep '?'
      if type_sqlattribute(stpr.content_now)
        sqlattr = r_sqlattribute(stpr.content_now)
        stpr.next
      end
    end
    return {table_name: table_name, parents: parents, sqlattr: sqlattr}
  end

  # =============================
  def type_prefixed(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_prefixed"
  end

  def r_prefixed(rules : AbsSyntTree)
    if !type_prefixed(rules)
      pp rules
      raise "Wrong rule to 'r_prefixed' "
    end
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "PREFIXED")
      pp stpr.content_now
      raise "Expecting 'PREFIXED' "
    end
    stpr.next
    # table_name = r_tablename(stpr.content_now)
    table_name = r_SQString_Lx(stpr.content_now)
    # stpr.next
    return table_name
  end

  # =============================
  def type_acolumn(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_acolumn"
  end

  def r_acolumn(rules : AbsSyntTree)
    if !type_acolumn(rules)
      pp rules
      raise "Wrong rule to 'r_acolumn' "
    end
    stpr = Stepper.new(rules)
    col_name = r_colname(stpr.content_now)
    stpr.next
    if stpr.having_more && type_sqlattribute(stpr.content_now)
      sql_attr = r_sqlattribute(stpr.content_now)
      stpr.next
    else
      sql_attr = "MISSING ATTRIBUTES"
    end
    return {col_name: col_name, sql_attr: sql_attr}
  end

  # =============================
  def is_type_relcols(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_relcols"
  end

  # "RELATIVECOLUMN" "(" (tablename prefixed?) ,',' ")"

  def r_relcols(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_relcols")
      pp rules
      raise "Wrong rule to 'r_relcols' "
    end
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "RELATIVECOLUMN")
      pp stpr.content_now
      raise "Expecting 'RELATIVECOLUMN' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    my_related_atributes : Array(FKCreate) = [] of FKCreate

    one_related_atributes = FKCreate.new
    one_related_atributes.parent_table_name = r_tablename(stpr.content_now)

    # OLD
    # my_FKCreate = FKCreate.new
    # my_FKCreate.parent_table_name = ret

    stpr.next

    # if stpr.having_more
    #   if stpr.content_now.kind == "resword" && stpr.content_now.value == "PREFIXED"
    #     stpr.next
    #     one_related_atributes.prefix = r_SQString_Lx(stpr.content_now)
    #   end
    # end

    if stpr.having_more # rep '?'
      if type_prefixed(stpr.content_now)
        one_related_atributes.prefix = r_prefixed(stpr.content_now)
        stpr.next
      end
    end # ','
    my_related_atributes << one_related_atributes
    while stpr.having_more && type_tablename(stpr.content_now)
      one_related_atributes = FKCreate.new
      one_related_atributes.parent_table_name = r_tablename(stpr.content_now)
      stpr.next

      if stpr.having_more # rep '?'
        if type_prefixed(stpr.content_now)
          one_related_atributes.prefix = r_prefixed(stpr.content_now)
          stpr.next
        end
      end
      my_related_atributes << one_related_atributes
    end

    my_related_atributes
    # stpr.next
    # if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
    #   pp stpr.content_now
    #   raise "Expecting '(' "
    # end
    # stpr.next
    # #
    # my_PlainColumnCreate : Array(FKCreate) = [] of FKCreate
    # #
    # a_column = r_acolumn(stpr.content_now)
    # an_FKCreate = FKCreate.new
    # an_FKCreate.parent_table_name = a_column[:col_name]
    # my_PlainColumnCreate << an_FKCreate

    # stpr.next
    # # acolumn more
    # while type_acolumn(stpr.content_now)
    #   # {col_name: col_name, sql_attr: sql_attr}
    #   a_column = r_acolumn(stpr.content_now)
    #   an_FKCreate = FKCreate.new
    #   an_FKCreate.parent_table_name = a_column[:col_name]
    #   my_PlainColumnCreate << an_FKCreate
    #   stpr.next
    # end
    # if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
    #   pp stpr.content_now
    #   raise "Expecting ')' "
    # end
    # stpr.next
    # return my_PlainColumnCreate
  end

  # =============================
  def is_type_plaincols(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_plaincols"
  end

  def r_plaincols(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_plaincols")
      pp rules
      raise "Wrong rule to 'r_plaincols' "
    end
    my_PlainColumnCreate : Array(PlainColumnCreate) = [] of PlainColumnCreate
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "PLAINCOLUMN")
      pp stpr.content_now
      raise "Expecting 'PLAINCOLUMN' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    # At least one entry

    a_column = r_acolumn(stpr.content_now)
    a_PlainColumnCreate = PlainColumnCreate.new
    a_PlainColumnCreate.col_name = a_column[:col_name]
    a_PlainColumnCreate.sql_attributes = a_column[:sql_attr]
    my_PlainColumnCreate << a_PlainColumnCreate

    stpr.next
    while stpr.having_more && type_acolumn(stpr.content_now)
      a_column = r_acolumn(stpr.content_now)
      a_PlainColumnCreate = PlainColumnCreate.new
      a_PlainColumnCreate.col_name = a_column[:col_name]
      a_PlainColumnCreate.sql_attributes = a_column[:sql_attr]
      my_PlainColumnCreate << a_PlainColumnCreate
      stpr.next
    end
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    # stpr.next
    return my_PlainColumnCreate
  end

  # =============================
  def type_tablename(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_tablename"
  end

  def r_tablename(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_tablename")
      pp rules
      raise "Wrong rule to 'r_tablename' "
    end
    stpr = Stepper.new(rules)
    ret = r_Identifier_Lx(stpr.content_now)
    return ret
  end

  # =============================
  def type_colname(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_colname"
  end

  def r_colname(rules : AbsSyntTree)
    if !type_colname(rules)
      pp rules
      raise "Wrong rule to 'r_colname' "
    end
    stpr = Stepper.new(rules)
    value = r_Identifier_Lx(stpr.content_now)

    return value
  end

  # =============================
  def type_Digit19_Cs(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Digit19_Cs"
  end

  def r_Digit19_Cs(rules : AbsSyntTree)
    if !(rules.kind == "rule" && rules.rule_name == "r_Digit19_Cs")
      pp rules
      raise "Wrong rule to 'r_Digit19_Cs' "
    end
    stpr = Stepper.new(rules)
    genCharSetExpr
  end

  # =============================
  def type_sqlattribute(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_sqlattribute"
  end

  def r_sqlattribute(rules : AbsSyntTree) : String
    if !type_sqlattribute(rules)
      pp rules
      raise "Wrong rule to 'r_sqlattribute' "
    end
    stpr = Stepper.new(rules)
    value = r_SQString_Lx(stpr.content_now)
    return value
  end

  # =============================
  def is_type_Identifier_Lx(rules : AbsSyntTree)
    return rules.kind == "lexem" && rules.rule_name == "r_Identifier_Lx"
  end

  def r_Identifier_Lx(rules : AbsSyntTree)
    if !is_type_Identifier_Lx(rules)
      pp rules
      raise "Wrong rule to 'r_Identifier_Lx' "
    end
    return rules.value
  end

  # =============================
  def is_type_Literal_Cs(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_Literal_Cs"
  end

  def r_Literal_Cs(rules : AbsSyntTree)
    if !is_type_Literal_Cs(rules)
      pp rules
      raise "Wrong rule to 'r_Literal_Cs' "
    end
    return rules.value
  end

  # =============================
  def is_type_Digit09_Cs(rules : AbsSyntTree)
    return rules.kind == "lexem" && rules.rule_name == "r_Digit09_Cs"
  end

  def r_Digit09_Cs(rules : AbsSyntTree)
    if !is_type_Digit09_Cs(rules)
      pp rules
      raise "Wrong rule to 'r_Digit09_Cs' "
    end
    return rules.value
  end

  # =============================
  def is_type_SQString_Lx(rules : AbsSyntTree)
    return rules.kind == "lexem" && rules.rule_name == "r_SQString_Lx"
  end

  def r_SQString_Lx(rules : AbsSyntTree)
    if !is_type_SQString_Lx(rules)
      pp rules
      raise "Wrong rule to 'r_SQString_Lx' "
    end
    return rules.value
  end
end
