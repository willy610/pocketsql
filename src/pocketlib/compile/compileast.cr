require "../execute/execqr"
require "../dbschema"
require "../compile/stepper"

alias AggrFuncInUse = {look_up_table: String, look_up_colname: String, func: AggregateFunctionEnum | Nil, generated_aggr_name: String, as_colname: String}

class CompileAst
  property db : DBSchema

  def initialize(@db)
  end

  # =============================
  def ensure_resword(the_resword : String, a_res_word_rule : AbsSyntTree)
    if a_res_word_rule.is_a?(AbsSyntTree)
      if a_res_word_rule.rule_name == "resword"
        if a_res_word_rule.content[0] != the_resword
          err = "ensure_resword() Require '#{the_resword}' but got '#{a_res_word_rule.content[0]}'"
          raise err
        else
          return
        end
      else
        err = "ensure_resword() Require rule 'resword' but got '#{a_res_word_rule.rule_name}'"
        raise err
      end
    else
      err = "ensure_resword() Require an params to be '' but got #{a_res_word_rule}"
      raise err
    end
  end

  # =============================
  def must_kind_value(stpr, kind, value, msg)
    if !(stpr.content_now.kind == kind && stpr.content_now.value == value)
      pp stpr.content_now
      raise msg
    end
  end

  # =============================

  def go(rules : AbsSyntTree) : QR::TopInQr
    # Program: (with? "INSERT" insertbody | "SELECT" projectbody orderby? | "UPDATE" updatebody ) ";" ; `;

    if !(rules.kind == "rule" && rules.rule_name == "r_Program")
      raise "go() Missing intial 'r_Program' rule"
    end
    stpr = Stepper.new(rules)

    if is_type_comment(stpr.content_now)
      stpr.next
    end

    if is_type_with(stpr.content_now)
      from_with = r_with(stpr.content_now)
      stpr.next
    else
      from_with = {cte_plain: [] of QR::QrPlainCTE, cte_recur: [] of QR::QRWithRecur}
    end

    resword = stpr.content_now
    if resword.kind == "resword"
      case resword.value
      when "SHOW"
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        # pp rules
        stpr.next
        a_QShow = QR::QShow.new
        if (stpr.content_now.kind == "resword" && stpr.content_now.value =="TABLES")
          a_QShow.all_tables = true
        elsif stpr.content_now.kind == "resword" && stpr.content_now.value == "TABLE"
          stpr.next
          if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_AS_TID"
            a_QShow.one_table = stpr.content_now.content[0].value
          else
            raise "go() Expecting table name after 'SHOW TABLE'"
          end
        else
          raise "SHOW () Expecting 'TABLE' or 'TABLES' "
        end
        a_Query = QR::Query.new
        a_Query.show_table = a_QShow
        top = QR::TopInQr.new(a_Query)
        return top
      when "INSERT"
        stpr.next
        if is_type_insertbody(stpr.content_now)
          qd = r_insertbody(stpr.content_now)
          top = QR::TopInQr.new(qd)
          return top
        else
          raise "go() Expecting insertbody after 'INSERT'"
        end
      when "UPDATE"
        stpr.next
        if is_type_updatebody(stpr.content_now)
          qd = r_updatebody(stpr.content_now)
          top = QR::TopInQr.new(qd)
          return top
        else
          raise "go() Expecting insertbody after 'INSERT'"
        end
        raise "NOT YET UPDATE"
      when "DELETE"
        stpr.next
        if is_type_deletebody(stpr.content_now)
          qd = r_deletebody(stpr.content_now)
          top = QR::TopInQr.new(qd)
          return top
        else
          raise "go() Expecting deletebody after 'DELETE'"
        end
      when "SELECT"
        stpr.next
        if is_type_projectbody(stpr.content_now)
          res_from_rule_projectbody = r_projectbody(stpr.content_now)
          stpr.next
          qr = QR::Query.new
          # orderby
          if stpr.having_more
            if is_type_orderby(stpr.content_now)
              ret = r_orderby(stpr.content_now)
              qr.orderby = ret
              stpr.next
            end
          end
          # limit
          if stpr.having_more
            if is_type_limit(stpr.content_now)
              qr.limit = r_limit(stpr.content_now)
              stpr.next
            end
          end
          qr.subq = res_from_rule_projectbody
          qr.cte_plain = from_with[:cte_plain]
          qr.cte_recur = from_with[:cte_recur]
          top = QR::TopInQr.new(qr)
          return top
        else
          raise "go() Missing  'r_projectbody' rule"
        end
      else
      end
    end
    raise "NOT YET. found '#{resword}' "
  end

  # =============================
  def is_type_show(rules : AbsSyntTree)
    return rules.kind == "resword" && rules.value == "SHOW"
  end

  def r_show(rules : AbsSyntTree)
    if !is_type_show(rules)
      pp rules
      raise "Wrong rule to 'r_show' "
    end
    stpr = Stepper.new(rules)
    stpr.next
    pp rules
    a_QShow = QR::QShow.new
    if stpr.content_now.kind == "resword" && stpr.content_now.value == "TABLES"
      a_QShow.all_tables = true
    elsif stpr.content_now.kind == "resword" && stpr.content_now.value == "TABLE"
      stpr.next
      pp rules
      a_QShow.one_table = "ONETABLE"
    else
      raise "r_show () Expecting 'TABLE' or 'TABLES' "
    end
    a_Query = QR::Query.new
    a_Query.show_table = a_QShow
    ret_Query = QR::Query.new
    return ret_Query
  end

  # =============================
  def is_type_insertbody(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_insertbody"
  end

  def r_insertbody(rules : AbsSyntTree)
    if !is_type_insertbody(rules)
      pp rules
      raise "Wrong rule to 'r_insertbody' "
    end
    stpr = Stepper.new(rules)
    an_QInsert = QR::QInsert.new
    a_QRCUD = QR::QRCUD.new
    a_QRCUD.kind_QInsert = an_QInsert
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "INTO")
      pp stpr.content_now
      raise "Expecting 'INTO' "
    end
    stpr.next
    # INSERT INTO (TABLE | ('file.csv' AS TABLE(COL1,COL2,..) ) (COL1,COL2)... values or select
    tabe_or_file : QR::QrLoadFileFile | String = build_CUD_destination(stpr)
    if tabe_or_file.is_a?(String)
      a_QRCUD.destination_string = tabe_or_file
    elsif tabe_or_file.is_a?(QR::QrLoadFileFile)
      a_QRCUD.destination_QrLoadFileFile = tabe_or_file
    end
    # stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    col_names = r_column_comma_list(stpr.content_now)

    an_QInsert.into_columns = col_names
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next
    values : QR::SubQuery | QR::QRLoadFileValues = r_value_or_select(stpr.content_now)
    if values.is_a?(QR::SubQuery?)
      an_QInsert.subq = values
    else
      an_QInsert.values = values
    end
    a_QRCUD
  end

  # =============================
  def is_type_value_or_select(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_value_or_select"
  end

  def r_value_or_select(rules : AbsSyntTree) : QR::SubQuery | QR::QRLoadFileValues
    if !is_type_value_or_select(rules)
      pp rules
      raise "Wrong rule to 'r_value_or_select' "
    end
    stpr = Stepper.new(rules)
    if stpr.content_now.kind == "resword" && stpr.content_now.value == "VALUES"
      stpr.next
      a_QRLoadFileValues = r_value_list(stpr.content_now)
    elsif stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT"
      stpr.next
      ret = r_projectbody(stpr.content_now)
    else
      raise "r_value_or_select() expecting 'VALUES' or 'SELECT' "
    end
  end

  # =============================
  private def build_CUD_destination(stpr : Stepper) : QR::QrLoadFileFile | String
    if stpr.content_now.kind == "lexem" && stpr.content_now.rule_name == "r_SQString_Lx"
      csv_file_name = stpr.content_now.value
      stpr.next
      if stpr.having_more
        if is_type_tbl_col_alias(stpr.content_now)
          ret_from_tbl_col_alias = r_tbl_col_alias(stpr.content_now)
          destination = QR::QrLoadFileFile.new(csv_file_name,
            ret_from_tbl_col_alias[:table_name],
            ret_from_tbl_col_alias[:col_names])
          stpr.next
          destination
        else
          raise "r_insertbody() table 'r_SQString_Lx' must have alias"
        end
      else
        raise "r_insertbody() table 'r_SQString_Lx' must have alias"
      end
    elsif stpr.content_now.kind == "lexem" && stpr.content_now.rule_name == "r_Identifier_Lx"
      destination = stpr.content_now.value
      stpr.next
    else
      pp stpr.content_now
      raise "build_CUD_destination() failed"
    end

    destination
  end

  # =============================
  def is_type_updatebody(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_updatebody"
  end

  def r_updatebody(rules : AbsSyntTree)
    if !is_type_updatebody(rules)
      pp rules
      raise "Wrong rule to 'r_updatebody' "
    end
    # ------------------------------
    gen_one_assign = ->(stpr : Stepper) {
      if !is_type_AS_CID(stpr.content_now)
        pp rules
        raise "is_type_AS_CID() wrong rule"
      end

      left_side = r_AS_CID(stpr.content_now)
      stpr.next
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "=")
        pp stpr.content_now
        raise "Expecting '=' "
      end
      stpr.next
      right_side = r_scalarexp(stpr.content_now)
      one_update = QR::QUpdateValue.new(left_side, right_side)
    }
    # ------------------------------
    stpr = Stepper.new(rules)
    an_QUpdate = QR::QUpdate.new
    a_QRCUD = QR::QRCUD.new
    a_QRCUD.kind_QUpdate = an_QUpdate

    # UPDATE TABLE | 'file.csv' AS TABLE(COL1,COL2) ... SET (left=scalar,..) where

    tabe_or_file : QR::QrLoadFileFile | String = build_CUD_destination(stpr)
    if tabe_or_file.is_a?(String)
      a_QRCUD.destination_string = tabe_or_file
    elsif tabe_or_file.is_a?(QR::QrLoadFileFile)
      a_QRCUD.destination_QrLoadFileFile = tabe_or_file
    end
    #
    # stpr.next
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SET")
      pp stpr.content_now
      raise "Expecting 'SET' "
    end
    stpr.next
    # ONE OR MORE assigns
    # all_assigns : Array(QR::QUpdateValue) = [] of QR::QUpdateValue
    if stpr.having_more
      while is_type_AS_CID(stpr.content_now)
        an_QUpdate.settings << gen_one_assign.call(stpr)
        stpr.next
        if !stpr.having_more
          break
        end
      end
    end
    # ensure we got on or more
    if an_QUpdate.settings.size == 0
      raise "r_updatebody()  UPDATE must hold at least one entry"
    end

    if stpr.having_more
      if is_type_whererule(stpr.content_now)
        ret_from_rule_where = r_whererule(stpr.content_now)
        an_QUpdate.whereexpr = ret_from_rule_where
        return a_QRCUD
      end
    end
    raise " missing where in delete"
  end

  # =============================
  def is_type_deletebody(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_deletebody"
  end

  def r_deletebody(rules : AbsSyntTree)
    if !is_type_deletebody(rules)
      pp rules
      raise "Wrong rule to 'r_deletebody' "
    end

    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "FROM")
      pp stpr.content_now
      raise "Expecting 'FROM' "
    end
    stpr.next
    an_QDelete = QR::QDelete.new
    a_QRCUD = QR::QRCUD.new
    a_QRCUD.kind_QDelete = an_QDelete

    # DELETE FROM TABLE | 'file.csv' AS TABLE(COL1,COL2) ... where

    tabe_or_file : QR::QrLoadFileFile | String = build_CUD_destination(stpr)
    if tabe_or_file.is_a?(String)
      a_QRCUD.destination_string = tabe_or_file
    elsif tabe_or_file.is_a?(QR::QrLoadFileFile)
      a_QRCUD.destination_QrLoadFileFile = tabe_or_file
    end
    # stpr.next
    if stpr.having_more
      if is_type_whererule(stpr.content_now)
        ret_from_rule_where = r_whererule(stpr.content_now)
        an_QDelete.whereexpr = ret_from_rule_where
        return a_QRCUD
      end
    end
    raise " missing where in delete"
  end

  # =============================
  def is_type_having(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_having"
  end

  def r_having(rules : AbsSyntTree)
    if !is_type_having(rules)
      pp rules
      raise "Wrong rule to 'r_having' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "HAVING")
      pp stpr.content_now
      raise "Expecting 'HAVING' "
    end
    stpr.next

    ret = r_fullcondexpr(stpr.content_now)
    return ret
  end

  # =============================
  def is_type_orderby(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_orderby"
  end

  def r_orderby(rules : AbsSyntTree)
    # "ORDER BY" ( (Identifier_Lx | Number_Lx ) ("ASC" | "DESC")? ),','
    if !is_type_orderby(rules)
      raise "is_type_orderby() wrong rule"
    end
    to_ret : Array(QR::QROrderBy) = [] of QR::QROrderBy
    stpr = Stepper.new(rules)
    must_kind_value(stpr, "resword", "ORDER", "Expecting 'ORDER'")
    stpr.next
    must_kind_value(stpr, "resword", "BY", "Expecting 'BY'")
    stpr.next

    while stpr.having_more
      an_OrderBy = QR::QROrderBy.new
      if stpr.content_now.kind == "lexem" && stpr.content_now.rule_name == "r_Number_Lx"
        an_OrderBy.column_number = stpr.content_now.value.to_i16
        stpr.next
      elsif stpr.content_now.kind == "lexem" && stpr.content_now.rule_name == "r_Identifier_Lx"
        an_OrderBy.column_name = stpr.content_now.value
        stpr.next
      else
        break # there was no more of type (Identifier_Lx | Number_Lx ). So order by is done
      end
      if stpr.having_more
        if stpr.content_now.kind == "resword" && stpr.content_now.value == "ASC"
          an_OrderBy.ordering = "ASC"
          stpr.next
        elsif stpr.content_now.kind == "resword" && stpr.content_now.value == "DESC"
          an_OrderBy.ordering = "DESC"
          stpr.next
        end
      end # end
      to_ret << an_OrderBy
    end
    return to_ret
  end

  # =============================
  def is_type_limit(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_limit"
  end

  # "LIMIT" ( Number_Lx ("OFFSET" Number_Lx) | ("," Number_Lx )? );
  # LIMIT {[offset,] row_count | row_count OFFSET offset}
  def r_limit(rules : AbsSyntTree)
    if !is_type_limit(rules)
      pp rules
      raise "Wrong rule to 'r_limit' "
    end
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "LIMIT")
      pp stpr.content_now
      raise "Expecting 'LIMIT' "
    end
    stpr.next
    if !is_type_Number_Lx(stpr.content_now)
      pp stpr.content_now
      raise "r_Number_Lx"
    end
    a_Limit = QR::QRLimit.new
    offset_or_row_count = stpr.content_now.value
    a_Limit.offset = offset_or_row_count # Assume
    stpr.next
    if stpr.having_more
      if stpr.content_now.kind == "resword" && stpr.content_now.value == "OFFSET"
        stpr.next
        if !is_type_Number_Lx(stpr.content_now)
          pp stpr.content_now
          raise "r_Number_Lx"
        end
        a_Limit.offset = stpr.content_now.value
        a_Limit.row_count = offset_or_row_count
      elsif stpr.content_now.kind == "resoper" && stpr.content_now.value == ","
        stpr.next
        if !is_type_Number_Lx(stpr.content_now)
          pp stpr.content_now
          raise "r_Number_Lx"
        end
        a_Limit.row_count = stpr.content_now.value
      else
        raise "limit missing "
      end
    end
    return a_Limit
  end

  # =============================
  def is_type_comment(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_comments"
  end

  # =============================
  def is_type_with(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_with"
  end

  def r_with(rules : AbsSyntTree)
    # "WITH" (withplain,',') *  withrecur?
    # withplain: "NONERECURSIVE"  tablename "(" column_comma_list ")" "AS" "("  "SELECT" projectbody ")"  ;
    # withrecur: "RECURSIVE" tablename "(" column_comma_list ")" "AS" "(SELECT"  projectbody "UNION" "ALL"? "SELECT" projectbody ")" ;

    if !is_type_with(rules)
      raise "r_with() wrong rule"
    end

    to_ret_cte_plain : Array(QR::QrPlainCTE) = [] of QR::QrPlainCTE
    to_ret_cte_recur : Array(QR::QRWithRecur) = [] of QR::QRWithRecur

    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "WITH")
      raise "r_with() missing 'WITH' "
    end
    stpr.next
    # zero or more NONERECURSIVE
    while stpr.having_more && is_type_withplain(stpr.content_now)
      if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_withplain"
        to_ret_cte_plain += r_withplain(stpr.content_now)
      end
      stpr.next
    end
    # one optional final RECURSIVE
    if stpr.having_more
      if is_type_withrecur(stpr.content_now)
        to_ret_cte_recur << r_withrecur(stpr.content_now)
      else
        raise "r_with() Problem #{stpr.content_now}"
      end
    end
    return {cte_plain: to_ret_cte_plain, cte_recur: to_ret_cte_recur}
  end

  # =============================
  def is_type_withrecur(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_withrecur"
  end

  def r_withrecur(rules : AbsSyntTree)
    # "RECURSIVE" tablename  "AS" "(SELECT"  projectbody "UNION" "ALL"? "SELECT" projectbody ")"
    # if !(rules.kind == "rule" && rules.rule_name == "r_withrecur")
    if !is_type_withrecur(rules)
      pp rules
      raise "r_withrecur() wrong rule"
    end
    if !(rules.content[0].kind == "resword" && rules.content[0].value == "RECURSIVE")
      pp rules.content[0]
      raise "r_withrecur() missing 'RECURSIVE'"
    end
    if !(rules.content[1].kind == "rule" && rules.content[1].rule_name == "r_tablename")
      pp rules.content[1]
      raise "r_withrecur() missing 'r_tablename'"
    end
    with_table_name = rules.content[1].content[0].value

    if !(rules.content[2].kind == "resoper" && rules.content[2].value == "(")
      raise "r_withrecur() expection '('"
    end
    comma_list = r_column_comma_list(rules.content[3])

    if !(rules.content[4].kind == "resoper" && rules.content[4].value == ")")
      pp rules.content[4]
      raise "r_withrecur() expection ')'"
    end

    if !(rules.content[5].kind == "resword" && rules.content[5].value == "AS")
      pp rules.content[5]
      raise "r_withrecur() missing 'AS'"
    end
    # !!!!!!!
    @db.add_cte_def("WITH(r_withrecur)", with_table_name, comma_list)
    # ExecuteQr.add_cte_def("WITH(r_withrecur)", with_table_name, comma_list)

    if !(rules.content[6].kind == "resoper" && rules.content[6].value == "(")
      pp rules.content[6]
      raise "r_withrecur() missing '('"
    end

    if !(rules.content[7].kind == "resword" && rules.content[7].value == "SELECT")
      pp rules.content[7]
      raise "r_withrecur() missing 'SELECT'"
    end

    first_project_body = r_projectbody(rules.content[8])
    if !(rules.content[9].kind == "resword" && rules.content[9].value == "UNION")
      pp rules.content[9]
      raise "r_withrecur() missing 'UNION'"
    end
    next_indx = 10
    if rules.content[next_indx].kind == "resword" && rules.content[next_indx].value == "ALL"
      next_indx += 1
    end
    if !(rules.content[next_indx].kind == "resword" && rules.content[next_indx].value == "SELECT")
      pp rules.content[next_indx]
      raise "r_withrecur() missing 'SELECT'"
    end
    next_indx += 1
    recursive_project_body = r_projectbody(rules.content[next_indx])
    return QR::QRWithRecur.new(with_table_name, first_project_body, recursive_project_body)
    raise "Startx"
  end

  # =============================
  def is_type_withplain(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_withplain"
  end

  def r_withplain(rules : AbsSyntTree)
    #  tablename "(" column_comma_list ")" "AS" "("  "SELECT" projectbody ")"
    if !is_type_withplain(rules)
      # if !(rules.kind == "rule" && rules.rule_name == "r_withplain")
      raise "r_withplain() wrong rule"
    end
    to_ret : Array(QR::QrPlainCTE) = [] of QR::QrPlainCTE
    stpr = Stepper.new(rules)

    # if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "NONERECURSIVE")
    #   raise "r_withplain() expection 'NONERECURSIVE'"
    # end
    # stpr.next
    if !(stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_tablename")
      raise "r_withplain() expection 'tablename'"
    end
    # group_size = 9
    # group_now = 0
    # stpr.next
    # with a rule with leaexm down under
    while stpr.having_more
      # tablename = stpr.content_now.content[group_now + 0].content[0].value
      tablename = stpr.content_now.content[0].value
      # puts tablename
      stpr.next
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
        raise "r_withplain() expection '('"
      end
      stpr.next
      # comma_list_rule = rules.content[group_now + 2]
      if !(stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_column_comma_list")
        raise "r_withplain() expection 'column_comma_list'"
      end
      comma_list = r_column_comma_list(stpr.content_now)
      # pp comma_list
      stpr.next
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
        raise "r_withplain() expection ')'"
      end
      stpr.next
      if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
        raise "r_withplain() expection 'AS'"
      end
      stpr.next
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
        raise "r_withplain() expection '('"
      end
      stpr.next
      if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
        raise "r_withplain() expection 'SELECT'"
      end
      stpr.next
      if !(stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_projectbody")
        raise "r_withplain() expection 'r_projectbody'"
      end
      projectbody = r_projectbody(stpr.content_now)
      stpr.next
      # end
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
        raise "r_withplain() expection ')'"
      end
      stpr.next

      ret = QR::QrPlainCTE.new(tablename, comma_list, projectbody)
      # puts "tablename=#{tablename}"
      # puts "comma_list=#{comma_list}"
      # @db.add_cte_def("WITH(r_with)", tablename, comma_list)
      # puts x.show
      # ExecuteQr.add_cte_def("WITH(r_with)", tablename, comma_list)
      to_ret << ret
      # group_now = group_now + group_size
    end
    return to_ret
    # return [tablename,comma_list,projectbody]
  end

  # =============================
  def is_type_projectbody(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_projectbody"
  end

  def r_projectbody(rules : AbsSyntTree) : QR::SubQuery
    # projectbody : "DISTINCT"? project "FROM" from whererule? window? groupby? having?
    if !is_type_projectbody(rules)
      raise "r_projectbody() wrong rule. Got #{rules.rule_name}"
    end
    stpr = Stepper.new(rules)
    if stpr.content_now.kind == "resword" && stpr.content_now.value == "DISTINCT"
      prod_distinct = true
      stpr.next
    else
      prod_distinct = false
    end
    #
    # r_project
    #
    ret_from_rule_project = r_project(stpr.content_now)
    stpr.next
    must_kind_value(stpr, "resword", "FROM", "r_projectbody() missed 'FROM' keyword")
    # if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "FROM")
    #   pp rules
    #   raise "r_projectbody() missed 'FROM' keyword"
    # end
    stpr.next
    #
    # r_from
    #
    ret_from_r_from = r_from(stpr.content_now)

    # the_from_obj = QR::QFrom.new

    # if ret_from_r_from.is_a?(QR::QRFirstJoin)
    #   the_from_obj.from_QRFirstJoin = ret_from_r_from
    # elsif ret_from_r_from.is_a?(QR::QRLoadFileValues)
    #   the_from_obj.from_QRLoadFileValues = ret_from_r_from
    # elsif ret_from_r_from.is_a?(QR::QRLoadFromStore)
    #   the_from_obj.from_QRLoadFromStore = ret_from_r_from
    # elsif ret_from_r_from.is_a?(QR::QrLoadFileFile)
    #   the_from_obj.from_QrLoadFileFile = ret_from_r_from
    # elsif ret_from_r_from.is_a?(QR::SubQuery)
    #   the_from_obj.from_SubQuery = ret_from_r_from
    # end
    stpr.next
    #
    # r_whererule?
    #
    if stpr.having_more
      if is_type_whererule(stpr.content_now)
        ret_from_rule_where = r_whererule(stpr.content_now)
        stpr.next
      end
    end
    #
    # r_window?
    #
    if stpr.having_more
      if is_type_window(stpr.content_now) # *******
        ret_from_rule_window = r_window(stpr.content_now)
        # pp ret_from_rule_window
        stpr.next
      end
    end
    #
    # r_groupby?
    #
    if stpr.having_more
      if is_type_groupby(stpr.content_now) # *******
        ret_from_rule_groupby = r_groupby(stpr.content_now)
        stpr.next
      end
    end

    a_SubQuery = QR::SubQuery.new(
      # from: ret_from_r_from,
      the_from: ret_from_r_from,
      project: ret_from_rule_project
    )
    #
    # r_having?
    #
    aggr_funcs_in_project : Array(AggrFuncInUse) = [] of AggrFuncInUse

    if stpr.having_more # rep '?'
      if is_type_having(stpr.content_now)
        a_SubQuery.having = r_having(stpr.content_now)
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        # pp a_SubQuery.having
        if a_SubQuery_having = a_SubQuery.having
          a_SubQuery_having.collect_aggr_funcs(aggr_funcs_in_project)
        end
        stpr.next
      end
    end
    #
    # We must produce code here
    #
    # aggr_funcs_in_project = ret_from_rule_project.columns.select { |col|
    #   puts "!" + __FILE__ + ":" + __LINE__.to_s
    #   pp col
    #   col.aggrfunction.is_a?(AggregateFunctionEnum)
    # }.map { |col|
    #   {look_up_table:       col.look_up_tablename,
    #    look_up_colname:     col.look_up_colname,
    #    func:                col.aggrfunction,
    #    generated_aggr_name: col.generated_aggr_name,
    #    as_colname:          col.as_colname}
    # }
    ret_from_rule_project.columns.each { |a_QRProjectItem|
      a_QRProjectItem.collect_aggr_funcs(aggr_funcs_in_project)
    }
    # puts "!" + __FILE__ + ":" + __LINE__.to_s
    # pp aggr_funcs_in_project
    a_SubQuery.distinct = prod_distinct

    if aggr_funcs_in_project.size == 0
      a_SubQuery.aggr_funcs_in_project = nil
    else
      a_SubQuery.aggr_funcs_in_project = aggr_funcs_in_project
    end

    if !ret_from_rule_window.nil?
      a_SubQuery.window = ret_from_rule_window
    end
    if !ret_from_rule_groupby.nil?
      a_SubQuery.groupby = ret_from_rule_groupby
    end
    if !ret_from_rule_where.nil?
      a_SubQuery.whereexpr = ret_from_rule_where
    end
    return a_SubQuery
  end

  # =============================
  def is_type_whererule(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_whererule"
  end

  def r_whererule(rules : AbsSyntTree)
    if !is_type_whererule(rules)
      pp rules
      raise "Wrong rule to 'r_whererule' "
    end
    stpr = Stepper.new(rules)
    must_kind_value(stpr, "resword", "WHERE", "r_whererule() Expecting 'WHERE' ")
    # if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "WHERE")
    #   pp stpr.content_now
    #   raise "Expecting 'WHERE' "
    # end
    stpr.next
    # to_ret : QR::QRWhere = QR::QRWhere.new
    ret = r_fullcondexpr(stpr.content_now)
    return ret
  end

  # =============================
  def is_type_project(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_project"
  end

  # project: ( "*" | (nyQRProjectItem ("AS" AS_CID)?),',' ) ) ("AS" AS_TID)? ;

  def r_project(rules : AbsSyntTree)
    if !is_type_project(rules)
      pp rules
      raise "Wrong rule to 'r_project' "
    end
    # ------------------------------------------
    gen_one_proj_column = ->(stpr : Stepper) {
      if !is_type_nyprojectitem(stpr.content_now)
        pp rules
        raise "is_type_nyprojectitem() wrong rule"
      end
      this_item = r_nyprojectitem(stpr.content_now)
      stpr.next
      if stpr.having_more &&
         stpr.content_now.kind == "resword" &&
         stpr.content_now.value == "AS"
        stpr.next
        this_item.as_colname = r_AS_CID(stpr.content_now)
        stpr.next
      end
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp this_item
      this_item
    }
    # ------------------------------------------
    to_ret = QR::QRProject.new

    stpr = Stepper.new(rules)
    if (stpr.content_now.kind == "resoper" && stpr.content_now.value == "*")
      pi = QR::QRProjectItem.new("", "", QRProjectItemKind::PWild)
      pi.look_up_tablename = "*"
      pi.look_up_colname = "*"
      to_ret.columns << pi
      stpr.next # done
    elsif (stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_nyprojectitem")
      #
      # ONE OR MORE 'r_nyprojectitem'
      if stpr.having_more
        while is_type_nyprojectitem(stpr.content_now)
          to_ret.columns << gen_one_proj_column.call(stpr)
          # stpr.next
          if !stpr.having_more
            break
          end
        end
      end
      stpr.next
      if stpr.having_more
        if (stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
          stpr.next
          ret = r_AS_CID(stpr.content_now)
          stpr.next
        end
      end
      # **************
      # **************
    else
      pp stpr.content_now
      raise "Expecting '*' or  r_nyprojectitem"
    end
    stpr.next
    if stpr.having_more
      if (stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
        stpr.next
        ret = r_AS_TID(stpr.content_now)
        to_ret.astablename = ret
      end
    end
    return to_ret
  end

  # =============================

  def is_type_nyprojectitem(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_nyprojectitem"
  end

  # nyQRProjectItem : ( "(" projselectbodyorscalarexp ")" ) | simpleQRProjectItem
  def r_nyprojectitem(rules : AbsSyntTree) : QR::QRProjectItem
    if !is_type_nyprojectitem(rules)
      pp rules
      raise "Wrong rule to 'r_nyprojectitem' "
    end
    stpr = Stepper.new(rules)

    if (stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      stpr.next
      ret = r_projselectbodyorscalarexp(stpr.content_now)
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp ret

      stpr.next
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
        pp stpr.content_now
        raise "Expecting ')' "
      end
    else
      ret = r_simpleprojectitem(stpr.content_now)
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp ret

    end
    return ret
  end

  # =============================
  def is_type_projselectbodyorscalarexp(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_projselectbodyorscalarexp"
  end

  # projselectbodyorscalarexp: ( "SELECT" projectbody ) |  scalarexp
  def r_projselectbodyorscalarexp(rules : AbsSyntTree)
    if !is_type_projselectbodyorscalarexp(rules)
      pp rules
      raise "Wrong rule to 'r_projselectbodyorscalarexp' "
    end
    stpr = Stepper.new(rules)

    if (stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT")
      ret = QR::QRProjectItem.new("", "", QRProjectItemKind::PNOTYET)
      ret.kind = QRProjectItemKind::PSelect
      # ret.value = "SELECT"
      stpr.next
      ret.subq = r_projectbody(stpr.content_now)
    else
      ret = QR::QRProjectItem.new("", "", QRProjectItemKind::PScalarExpression)
      ret.kind = QRProjectItemKind::PScalarExpression
      # ret.value = ""
      ret.scalarexp = r_scalarexp(stpr.content_now)
    end
    return ret
  end

  # =============================

  def r_simpleprojectitem(rules : AbsSyntTree) : QR::QRProjectItem
    # StandardFunctionEnum | (AS_TID (( "." AS_CID |  ".*"  ))?
    #  StandardFunctionEnum | ( AS_TID ( (".*"  | "." AS_CID  ) )? | SQString_Lx | Number_Lx )
    if !(rules.kind == "rule" && rules.rule_name == "r_simpleprojectitem")
      pp rules
      raise "r_simpleprojectitem() wrong rule. Got #{rules.rule_name}"
    end
    the_item = rules.content[0]
    # pp the_item
    if the_item.kind == "rule" && the_item.rule_name == "r_standardfunction"
      x = r_standardfunction(the_item)
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp x
      return x
    elsif the_item.kind == "rule" && the_item.rule_name == "r_AS_TID"
      table = the_item.content[0].value
      if rules.content.size == 1
        # WE have SELECT x AS
        ret = QR::QRProjectItem.new("", "", QRProjectItemKind::PTblCol)
        ret.look_up_tablename = ""
        ret.look_up_colname = table
        # ret.value = "#{table}"
        return ret
      else
        the_second_item = rules.content[1]
        if the_second_item.kind == "resoper" && the_second_item.value == ".*"
          # WE have SELECT *.
          ret = QR::QRProjectItem.new("", "", QRProjectItemKind::PTblWild)
          ret.look_up_tablename = table
          # ret.value = "#{table}.*"
          ret.look_up_tablename = table
          ret.look_up_colname = "*"
          return ret
        elsif the_second_item.kind == "resoper" && the_second_item.value == "."
          the_third_item = rules.content[2]
          colname = the_third_item.content[0].value
          ret = QR::QRProjectItem.new(table, colname, QRProjectItemKind::PTblCol)
          ret.look_up_tablename = table
          ret.look_up_colname = colname
          # ret.value = "#{table}.#{colname}"
          return ret
        else
          raise "r_simpleprojectitem () Missing '.*' or '.XXX'"
        end
      end
    elsif the_item.kind == "lexem" && the_item.rule_name == "r_SQString_Lx"
      ret = QR::QRProjectItem.new("", "", QRProjectItemKind::PString)
      ret.look_up_tablename = ""
      ret.look_up_colname = ""
      ret.literalvalue = the_item.value
      return ret
    elsif the_item.kind == "lexem" && the_item.rule_name == "r_Number_Lx"
      ret = QR::QRProjectItem.new("", "", QRProjectItemKind::PString)
      ret.look_up_tablename = ""
      ret.look_up_colname = ""
      ret.literalvalue = the_item.value
      return ret
    else
      pp rules
      raise "r_simpleprojectitem () Missing 'r_standardfunction' or 'r_AS_TID' "
    end
  end

  # =============================
  # =============================
  def is_type_StandardFunctionEnum(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_standardfunction"
  end

  def r_standardfunction(rules : AbsSyntTree) : QR::QRProjectItem
    # ( "MIN" | "MAX" | "AVG" | "SUM" | "COUNT" | "STDDEV" | "TOUPPER"| "TOLOWER" ) "(" TID ")"
    if !is_type_StandardFunctionEnum(rules)
      pp rules
      raise "r_standardfunction() wrong rule. Got #{rules.rule_name}"
    end
    stpr = Stepper.new(rules)
    func = stpr.content_now.value
    stpr.next # FUNCTION CONSUMED

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "is_type_StandardFunctionEnum '(' "
    end
    stpr.next # '(' CONSUMED
    ret_project_item = QR::QRProjectItem.new("", "", QRProjectItemKind::PStandardFunctionEnum)

    if stpr.having_more
      if is_type_TID(stpr.content_now)
        # r_TID(stpr.content_now)
        # if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_TID"
        # the_table = stpr.content_now.content[0]
        # the_column = stpr.content_now.content[1]
        ret_project_item.look_up_tablename = stpr.content_now.content[0].value
        ret_project_item.look_up_colname = stpr.content_now.content[1].value
        ret_project_item.as_colname = ret_project_item.look_up_colname
        stpr.next # param name consumed
      else
        ret_project_item.look_up_tablename = ""
        ret_project_item.look_up_colname = ""
        ret_project_item.as_colname = ""
      end
      # stpr.next # PARAM CONSUMED
    end
    # AGGRFUNC or STANDARD
    # NAME is comming from a column from group by or window
    # ret_project_item.value = "#{func}(#{ret_project_item.look_up_tablename}.#{ret_project_item.look_up_colname})"
    # ret_project_item.generated_aggr_name = "#{func}_#{ret_project_item.look_up_tablename}.#{ret_project_item.look_up_colname}"
    ret_project_item.generated_aggr_name = "#{func}(#{ret_project_item.look_up_tablename}.#{ret_project_item.look_up_colname})"
    aggr_func = {
      "AVG"    => AggregateFunctionEnum::AVG,
      "MIN"    => AggregateFunctionEnum::MIN,
      "MIN"    => AggregateFunctionEnum::MIN,
      "MAX"    => AggregateFunctionEnum::MAX,
      "SUM"    => AggregateFunctionEnum::SUM,
      "COUNT"  => AggregateFunctionEnum::COUNT,
      "STDDEV" => AggregateFunctionEnum::STDDEV,
    }
    std_func = {
      "TOUPPER" => StandardFunctionEnum::TOUPPER,
      "TOLOWER" => StandardFunctionEnum::TOLOWER,
    }
    the_aggr_value = aggr_func[func]?
    if !the_aggr_value.nil?
      ret_project_item.aggrfunction = the_aggr_value
    else
      the_std_value = std_func[func]?
      if !the_std_value.nil?
        ret_project_item.columnfunction = the_std_value
      else
        raise "r_standardfunction () function '#{func}' not known"
      end
    end
    # stpr.next # param to func done done

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "is_type_StandardFunctionEnum ')' "
    end
    stpr.next # ")" CONSUMED

    if stpr.having_more # might be an over '?'
      if is_type_over(stpr.content_now)
        ret = r_over(stpr.content_now)
        ret_project_item.over_window = ret
        # pp ret_project_item
        stpr.next
      end
    end
    return ret_project_item
  end

  # =============================
  def is_type_over(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_over"
  end

  def r_over(rules : AbsSyntTree)
    if !is_type_over(rules)
      pp rules
      raise "Wrong rule to 'r_over' "
    end
    to_ret = QR::QRProjectOver.new
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "OVER")
      pp stpr.content_now
      raise "Expecting 'OVER' "
    end
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_AS_TID"
      to_ret.window_name = stpr.content_now.content[0].value
      stpr.next
    end

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    stpr.next

    if stpr.having_more # rep '?'
      if is_type_orderby(stpr.content_now)
        ret_from_order_by = r_orderby(stpr.content_now)
        # puts ret_from_order_by
        to_ret.order_by = ret_from_order_by
        stpr.next
      end
    end
    return to_ret
  end

  # =============================

  def r_column_comma_list(rules : AbsSyntTree) # : Array(QR::SubQuery | String)
    # column_comma_list :  AS_CID ,',' ;
    # to_ret : Array(String | QR::SubQuery) = [] of String | QR::SubQuery
    if !(rules.kind == "rule" && rules.rule_name == "r_column_comma_list")
      raise "r_column_comma_list() wrong rule"
    end

    to_ret : Array(String) = [] of String
    kids = rules.content
    kids.each { |elem|
      # if elem.is_a?(AbsSyntTree)
      if elem.kind == "rule" && elem.rule_name == "r_AS_CID"
        kid = elem.content[0]
        to_ret << elem.content[0].value
      else
        raise "r_column_comma_list() Missing rule"
      end
    }
    return to_ret.flatten
  end

  # =============================
  def is_type_from(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_from"
  end

  def r_from(rules : AbsSyntTree) : QR::QFrom
    kids = rules.content
    table_ref = kids[0]
    if table_ref.is_a?(AbsSyntTree)
      ret_table_ref = r_table_ref(table_ref)
      the_from_obj = QR::QFrom.new

      if ret_table_ref.is_a?(QR::QRFirstJoin)
        the_from_obj.from_QRFirstJoin = ret_table_ref
      elsif ret_table_ref.is_a?(QR::QRLoadFileValues)
        the_from_obj.from_QRLoadFileValues = ret_table_ref
      elsif ret_table_ref.is_a?(QR::QRLoadFromStore)
        the_from_obj.from_QRLoadFromStore = ret_table_ref
      elsif ret_table_ref.is_a?(QR::QrLoadFileFile)
        the_from_obj.from_QrLoadFileFile = ret_table_ref
      elsif ret_table_ref.is_a?(QR::SubQuery)
        the_from_obj.from_SubQuery = ret_table_ref
      end

      return the_from_obj
    end
    raise "r_from() NOT YET"
  end

  # =============================

  # def r_where(rules : AbsSyntTree) : Nil | QR::QrLoadFileFile | QR::QRLoadFileValues | QR::NotYet
  def is_type_where(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_where"
  end

  def r_where(rules : AbsSyntTree)
    # "WHERE" pcondexpr ( ("AND" | "OR" ) pcondexpr ) *
    #
    # rules[0] = WHERE
    # rules[1] = pcondexpr
    # n <- 2
    # rules[n] = ("AND" | "OR" )
    # rules[n+1] = pcondexpr

    # to_ret = QR::Where.new
    # dummy_to_ret : Array(QR::QRJoiner | QR::QRJoinerTops) = [] of (QR::QRJoiner | QR::QRJoinerTops)
    to_ret : QR::QRWhere = QR::QRWhere.new

    # try_pcondexpr = ->(a_rule : AbsSyntTree) {
    #   if a_rule.is_a?(AbsSyntTree)
    #     if a_rule.rule_name == "r_pcondexpr"
    #       ret_from = r_pcondexpr(a_rule)
    #     else
    #       raise "try_pcondexpr() not a 'r_pcondexpr' rule. Is a #{a_rule.rule_name}"
    #     end
    #   else
    #     raise "try_pcondexpr() not a rule. Is #{typeof(a_rule)}"
    #   end
    #   return ret_from
    # }
    #
    if !is_type_where(rules)
      raise "r_where() wrong rule"
    end
    stpr = Stepper.new(rules)
    puts "rules.content.size=#{rules.content.size}"
    # if size == we have no 'and/or'
    stpr.next
    left = r_pcondexpr(stpr.content_now)
    # to_ret.first_cond_expr = left
    stpr.next
    while stpr.having_more
      if (stpr.content_now.kind == "resword" && stpr.content_now.value == "AND") || (stpr.content_now.kind == "resword" && stpr.content_now.value == "OR")
        stpr.next
        r_pcondexpr(stpr.content_now)
        stpr.next
      else
        raise "r_where() Expecting 'AND' or 'OR' "
      end
    end
    return to_ret
    # return left
  end

  # =============================
  def is_type_window(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_window"
  end

  def r_window(rules : AbsSyntTree)
    if !is_type_window(rules)
      pp rules
      raise "Wrong rule to 'r_window' "
    end
    to_ret = QR::QRWindow.new
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "WINDOW")
      pp stpr.content_now
      raise "Expecting 'WINDOW' "
    end
    stpr.next

    if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_AS_TID"
      to_ret.name = stpr.content_now.content[0].value
      stpr.next
    end

    # ret = r_AS_TID(stpr.content_now)
    # to_ret.name= "LLL"
    # stpr.next

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

    if stpr.having_more # rep '?'
      if is_type_partby(stpr.content_now)
        ret = r_partby(stpr.content_now)
        to_ret.partitionby = ret
        stpr.next
      end
    end

    if stpr.having_more # rep '?'
      if is_type_orderby(stpr.content_now)
        ret = r_orderby(stpr.content_now)
        to_ret.orderby = ret
        stpr.next
      end
    end

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    return to_ret
  end

  # =============================
  def is_type_partby(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_partby"
  end

  # "PARTITION" "BY" ( TID  ),','
  def r_partby(rules : AbsSyntTree)
    if !is_type_partby(rules)
      pp rules
      raise "Wrong rule to 'r_partby' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "PARTITION")
      pp stpr.content_now
      raise "Expecting 'PARTITION' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "BY")
      pp stpr.content_now
      raise "Expecting 'BY' "
    end
    stpr.next
    key_to_window_partition : Array(QR::QRPartitionBy) = [] of QR::QRPartitionBy
    # ONE OR MORE r_TID
    if stpr.having_more
      while is_type_TID(stpr.content_now)
        the_table = stpr.content_now.content[0].value
        the_column = stpr.content_now.content[1].value
        a_PartitionBy = QR::QRPartitionBy.new(the_table, the_column)
        key_to_window_partition << a_PartitionBy
        stpr.next
        if !stpr.having_more
          break
        end
      end
    end
    # ensure we got on or more
    if key_to_window_partition.size == 0
      raise "r_partby()  PARTITION BY must hold at least one entry"
    end
    return key_to_window_partition
  end

  # =============================
  def is_type_groupby(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_groupby"
  end

  def r_groupby(rules : AbsSyntTree)
    # "GROUP BY"  ( TID ),','
    if !is_type_groupby(rules)
      pp rules
      raise "r_grouby wrong rule"
    end
    to_ret : Array(QR::QRGroupBy) = [] of QR::QRGroupBy
    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "GROUP")
      pp stpr.content_now
      raise "Expecting 'GROUP' "
    end
    stpr.next

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "BY")
      pp stpr.content_now
      raise "Expecting 'BY' "
    end
    stpr.next

    # stpr.next
    while stpr.having_more
      a_GroupBy = QR::QRGroupBy.new
      if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_TID"
        the_table = stpr.content_now.content[0]
        the_column = stpr.content_now.content[1]
        if the_table.kind == "lexem" && the_table.rule_name == "r_Identifier_Lx"
          a_GroupBy.table = the_table.value
          if the_column.kind == "lexem" && the_column.rule_name == "r_Identifier_Lx"
            a_GroupBy.column = the_column.value
            to_ret << a_GroupBy
          else
            pp stpr.content_now
            raise "r_groupby() Missing table.column"
          end
        else
          pp stpr.content_now
          raise "r_groupby() Missing table.column"
        end
      end
      stpr.next
    end
    if to_ret.size == 0
      raise "r_groupby() No table.col at all"
    end
    return to_ret
  end

  # =============================
  def is_rulename(rules : AbsSyntTree, rule_name : String)
    if rules.rule_name == rule_name
      return true
    else
      return false
    end
    raise "is_rulename() is not a rule"
    # end
  end

  # =============================
  def get_resword_value(rules : AbsSyntTree, rule_name : String) : String
    if rules.is_a?(AbsSyntTree) && rules.rule_name == rule_name
      rule = rules.content[0]
      if rule.is_a?(AbsSyntTree) && rules.rule_name = "resword"
        kid = rule.content[0]
        if kid.is_a?(String)
          return kid
        else
          raise "get_resword_value() Values not a String"
        end
      else
        raise "get_resword_value() Not a 'resword' rule"
      end
    else
      raise "get_resword_value() not a '#{rule_name}' or wrong name rule"
    end
  end

  # =============================
  def is_type_Number_Lx(rules : AbsSyntTree)
    if !(rules.kind == "lexem" && rules.rule_name == "r_Number_Lx")
      pp rules
      raise "is_type_Number_Lx fail"
    end
    return true
  end

  # =============================
  def get_r_Number_Lx_value(rules : AbsSyntTree)
    if !(rules.kind == "lexem" && rules.rule_name == "r_Number_Lx")
      raise "get_r_Number_Lx_value() wrong rule"
    end
    return QR::QRLoadNumberValueOntoStack.new(rules.value)
  end

  # =============================

  def get_r_DQString_Lx_value(rules : AbsSyntTree)
    if !(rules.kind == "lexem" && rules.rule_name == "r_DQString_Lx")
      raise "get_r_DQString_Lx_value() wrong rule"
    end
    return QR::QRLoadStringValueOntoStack.new(rules.value)
  end

  # =============================

  def get_r_SQString_Lx_value(rules : AbsSyntTree)
    if !(rules.kind == "lexem" && rules.rule_name == "r_SQString_Lx")
      raise "get_r_SQString_Lx_value() wrong rule"
    end
    return QR::QRLoadStringValueOntoStack.new(rules.value)
  end

  # =============================

  def get_r_Param_Lx_value(rules : AbsSyntTree)
    if !(rules.kind == "lexem" && rules.rule_name == "r_Param_Lx")
      raise "get_r_Param_Lx_value() wrong rule"
    end
    return QR::QRLoadParamNameOnStack.new(rules.value)
  end

  # =============================

  def r_compoper_Lx(rules : AbsSyntTree)
    if !(rules.kind == "lexem" && rules.rule_name == "r_compoper_Lx")
      raise "r_compoper_Lx() wrong rule"
    end
    return QR::QRDualCompareOperation.new(rules.value)
  end

  # =============================

  def get_r_scalaroper_Lx_value(rules : AbsSyntTree)
    value = get_resword_value(rules, "r_scalaroper_Lx")
    return QR::QRDualScalarOperation.new(value)
  end

  # =============================

  def get_r_TID_value(rules : AbsSyntTree) : QR::QRLoadColnameValueOntoStack
    #  Identifier_Lx ( '.' Identifier_Lx )?
    # TABLE.COLUMN or COLUMN
    if !is_type_TID(rules)
      pp rules
      raise "get_r_TID_value() wrong rule"
    end
    if rules.content.size == 1
      return QR::QRLoadColnameValueOntoStack.new("", rules.content[0].value)
    elsif rules.content.size == 2
      return QR::QRLoadColnameValueOntoStack.new(rules.content[0].value, rules.content[1].value)
    else
      pp rules
      raise "get_r_TID_value() Wrong number of kids"
    end
  end

  # =============================

  def r_scalarterm(rules : AbsSyntTree) : QR::QRLoadColnameValueOntoStack | QR::QRLoadNumberValueOntoStack | QR::QRLoadStringValueOntoStack | QR::QRProjectItem | QR::QRLoadParamNameOnStack
    #  TID | DQString_Lx | SQString_Lx | Number_Lx
    # to_ret : Array(String) = [] of String
    if rules.is_a?(AbsSyntTree)
      if rules.rule_name == "r_scalarterm"
        the_one = rules.content[0]
        if is_rulename(the_one, "r_standardfunction")
          return r_standardfunction(the_one)
        elsif is_rulename(the_one, "r_TID")
          return get_r_TID_value(the_one)
        elsif is_rulename(the_one, "r_DQString_Lx")
          return get_r_DQString_Lx_value(the_one)
        elsif is_rulename(the_one, "r_SQString_Lx")
          return get_r_SQString_Lx_value(the_one)
        elsif is_rulename(the_one, "r_Number_Lx")
          return get_r_Number_Lx_value(the_one)
        elsif is_rulename(the_one, "r_Param_Lx")
          return get_r_Param_Lx_value(the_one)
        else
          pp rules
          raise "r_scalarterm() 'r_TID' or 'r_DQString_Lx' or 'SQString_Lx' or 'r_Number_Lx'"
        end
      else
        pp rules
        raise "r_scalarterm() wrong rule name"
      end
    else
      pp rules
      raise "r_scalarterm() no rule"
    end
  end

  # =============================

  def r_pscalarexp(rules : AbsSyntTree)
    # nypscalarexp ( scalaroper_Lx nypscalarexp ) *  ;
    if !(rules.kind == "rule" && rules.rule_name == "r_pscalarexp")
      pp rules
      raise "r_pscalarexp() wrong rule"
    end
    stpr = Stepper.new(rules)

    the_zero = rules.content[0]
    if the_zero.rule_name == "r_scalarterm"
      return r_scalarterm(the_zero)
    elsif the_zero.rule_name == "r_scalarexp"
      return r_scalarexp(the_zero)
    elsif the_zero.rule_name == "resoper" && the_zero.value == "(SELECT"
      return r_projectbody(rules.content[1])
    else
      pp the_zero
      raise "r_pscalarexp() (2) the_zero = #{the_zero}"
    end
  end

  def convert_r_nypscalarexp_2_QRScalarItem(div_scalar)
    the_QRScalarItem = QR::QRScalarItem.new
    if div_scalar.is_a?(QR::QRLoadColnameValueOntoStack)
      the_QRScalarItem.item_QRLoadColnameValueOntoStack = div_scalar
    elsif div_scalar.is_a?(QR::QRLoadNumberValueOntoStack)
      the_QRScalarItem.item_QRLoadNumberValueOntoStack = div_scalar
    elsif div_scalar.is_a?(QR::QRLoadStringValueOntoStack)
      the_QRScalarItem.item_QRLoadStringValueOntoStack = div_scalar
    elsif div_scalar.is_a?(QR::QRProjectItem)
      the_QRScalarItem.item_QRProjectItem = div_scalar
    elsif div_scalar.is_a?(QR::QRScalarExpr)
      the_QRScalarItem.item_QRScalarExpr = div_scalar
    elsif div_scalar.is_a?(QR::SubQuery)
      the_QRScalarItem.item_SubQuery = div_scalar
    elsif div_scalar.is_a?(QR::QRLoadParamNameOnStack)
      the_QRScalarItem.item_QRLoadParamNameOnStack = div_scalar
    elsif div_scalar.is_a?(QR::QRLoadFileValues)
      the_QRScalarItem.item_QRLoadFileValues = div_scalar
    else
      raise "convert_r_nypscalarexp_2_QRScalarItem() Odd type '#{div_scalar}'"
    end
    return the_QRScalarItem
  end

  # =============================
  def is_type_scalarexp(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_scalarexp"
  end

  # scalarexp : nypscalarexp ( scalaroper_Lx nypscalarexp ) *

  def r_scalarexp(rules : AbsSyntTree) : QR::QRScalarExpr
    if !is_type_scalarexp(rules)
      pp rules
      raise "Wrong rule to 'r_scalarexp' "
    end

    stpr = Stepper.new(rules)
    left = r_nypscalarexp(stpr.content_now)

    ret_QRScalarExpr = QR::QRScalarExpr.new(convert_r_nypscalarexp_2_QRScalarItem(left))
    stpr.next
    while stpr.having_more
      if stpr.content_now.kind == "lexem" && stpr.content_now.rule_name == "r_scalaroper_Lx"
        oper = QR::QRDualScalarOperation.new(stpr.content_now.value)
      else
        pp rules
        raise "r_scalarexp () Expecting 'r_scalaroper_Lx'"
      end
      stpr.next
      right = r_nypscalarexp(stpr.content_now)
      the_QRScalarExpr_right = convert_r_nypscalarexp_2_QRScalarItem(right)

      ny_one_QRMoreScalarExpr = QR::QRMoreScalarExpr.new(the_QRScalarExpr_right, oper)
      stpr.next
      ret_QRScalarExpr.more_scalars << ny_one_QRMoreScalarExpr
    end
    return ret_QRScalarExpr
  end

  # =============================
  def is_type_nypscalarexp(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_nypscalarexp"
  end

  # nypscalarexp :  ( "(" scalarexpselectbodyorscalarexp ")" ) | scalarterm ;

  def r_nypscalarexp(rules : AbsSyntTree)
    if !is_type_nypscalarexp(rules)
      pp rules
      raise "Wrong rule to 'r_nypscalarexp' "
    end
    stpr = Stepper.new(rules)
    if (stpr.content_now.kind == "resword" && stpr.content_now.value == "VALUES")
      stpr.next
      ret = r_value_list(stpr.content_now)
    elsif (stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      stpr.next
      ret = r_scalarexpselectbodyorscalarexp(stpr.content_now)
      stpr.next
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
        pp stpr.content_now
        raise "Expecting ')' "
      end
    elsif stpr.content_now.rule_name == "r_scalarterm"
      ret = r_scalarterm(stpr.content_now)
    else
      pp stpr.content_now
      raise "r_nypscalarexp wrong rule"
    end
    return ret
  end

  # =============================
  def is_type_scalarexpselectbodyorscalarexp(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_scalarexpselectbodyorscalarexp"
  end

  def r_scalarexpselectbodyorscalarexp(rules : AbsSyntTree)
    if !is_type_scalarexpselectbodyorscalarexp(rules)
      pp rules
      raise "Wrong rule to 'r_scalarexpselectbodyorscalarexp' "
    end
    stpr = Stepper.new(rules)

    if stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT"
      stpr.next
      ret = r_projectbody(stpr.content_now)
    else
      ret = r_scalarexp(stpr.content_now)
    end
  end

  # =============================

  def r_psimplecond(rules : AbsSyntTree)
    # ('(' scalarexp ')') | scalarexp
    if rules.is_a?(AbsSyntTree)
      if rules.rule_name == "r_psimplecond"
        kids = rules.content
        if kids.size == 1
          return r_scalarexp(kids[0])
        elsif kids.size == 3
          pp rules
          raise "r_psimplecond (whats)"
        else
          pp rules
          raise "r_psimplecond (1 or 3 kids)"
        end
      else
        pp rules
        raise "r_psimplecond"
      end
    else
      pp rules
      raise "r_psimplecond"
    end
  end

  # =============================

  def r_simplecond(rules : AbsSyntTree)
    kids = rules.content
    left : QR::QRScalarExpr = r_psimplecond(kids[0])
    oper : QR::QRDualCompareOperation = r_compoper_Lx(kids[1])
    right : QR::QRScalarExpr = r_psimplecond(kids[2])
    if oper.value == "LIKE"
      right_first_scalar_item = right.first_scalar
      if the_item = right_first_scalar_item.item_QRLoadStringValueOntoStack
        regexppattern = the_item.value.gsub(".") { "\\." }
        regexppattern = regexppattern.gsub("*") { "\\*" }

        regexppattern = regexppattern.gsub("%") { ".*?" }
        regexppattern = regexppattern.gsub("_") { "." }
        new_rigth_scaler_item = QR::QRScalarItem.new
        new_rigth_scaler_item.item_QRLoadStringValueOntoStack = QR::QRLoadStringValueOntoStack.new(regexppattern)
        new_rigth = QR::QRScalarExpr.new(new_rigth_scaler_item)

        return QR::QROneCondExpr.new(oper, left, new_rigth)
      else
        raise "r_simplecond() 'LIKE' must be a string pattern"
      end
    end
    return QR::QROneCondExpr.new(oper, left, right)
  end

  # =============================

  def r_condexpr(rules : AbsSyntTree)
    #  simplecond | '(' condexpr ')'
    if !(rules.kind == "rule" && rules.rule_name == "r_condexpr")
      raise "r_tabler_condexpr_ref() wrong rule"
    end
    if rules.content[0].kind == "rule" && rules.content[0].rule_name == "r_simplecond"
      return r_simplecond(rules.content[0])
    else
      pp rules
      raise "r_condexpr() '(' not YET"
    end
  end

  # =============================

  def r_pcondexpr(rules : AbsSyntTree)
    # ('(' condexpr ')') | condexpr
    if !(rules.kind == "rule" && rules.rule_name == "r_pcondexpr")
      pp rules
      raise "r_pcondexpr() wrong rule"
    end

    if rules.content[0].kind == "rule" && rules.content[0].rule_name == "r_condexpr"
      return r_condexpr(rules.content[0])
    else
      pp rules
      raise "r_pcondexpr() '(' not YET"
    end
  end

  # =============================

  def r_table_ref(rules : AbsSyntTree) : QR::QRFirstJoin | QR::QRLoadFileValues | QR::QRLoadFromStore | QR::QrLoadFileFile | QR::SubQuery
    # relation_body  joiner_or_setoper?
    if !(rules.kind == "rule" && rules.rule_name == "r_table_ref")
      pp rules
      raise "r_table_ref() wrong rule"
    end
    # We are about to return
    # 1. A single ret_relation_body
    # 2. A JOIN TOP first body and second body (QR::QRJoiner)
    # 3. In case of several (join > 2 ) return JOIN TOP (TOP of stack with this body)
    stpr = Stepper.new(rules)
    first_table : QR::QRLoadFileValues | QR::QRLoadFromStore | QR::SubQuery | QR::QrLoadFileFile = r_relation_body(stpr.content_now)
    a_QFrom = convert_r_relation_body_2_QFrom(first_table)
    if rules.content.size == 1
      return first_table
    end
    # to_ret : QR::QRFirstJoin = QR::QRFirstJoin.new(first_table)
    to_ret : QR::QRFirstJoin = QR::QRFirstJoin.new(a_QFrom)
    # to_ret.first_from = first_table
    stpr.next
    while stpr.having_more
      # puts  stpr.content_now.rule_name
      ret_from_joiner_or_setoper = r_joiner_or_setoper(stpr.content_now)
      qrm = QR::QRMoreJoin.new(ret_from_joiner_or_setoper[:the_from])
      # qrm.from = ret_from_joiner_or_setoper[:the_from]
      qrm.join_on = ret_from_joiner_or_setoper[:the_r_onrule]
      qrm.join_cover = ret_from_joiner_or_setoper[:join_cover]
      # puts "qrm"
      # pp qrm
      to_ret.more_from << qrm
      stpr.next
    end
    return to_ret
  end

  # =============================
  private def convert_r_relation_body_2_QFrom(from_r_relation_body)
    the_from_obj = QR::QFrom.new

    if from_r_relation_body.is_a?(QR::QRFirstJoin)
      the_from_obj.from_QRFirstJoin = from_r_relation_body
    elsif from_r_relation_body.is_a?(QR::QRLoadFileValues)
      the_from_obj.from_QRLoadFileValues = from_r_relation_body
    elsif from_r_relation_body.is_a?(QR::QRLoadFromStore)
      the_from_obj.from_QRLoadFromStore = from_r_relation_body
    elsif from_r_relation_body.is_a?(QR::QrLoadFileFile)
      the_from_obj.from_QrLoadFileFile = from_r_relation_body
    elsif from_r_relation_body.is_a?(QR::SubQuery)
      the_from_obj.from_SubQuery = from_r_relation_body
    else
      pp from_r_relation_body
      raise "convert_r_relation_body_2_QFrom() missing variant #{from_r_relation_body}"
    end

    return the_from_obj
  end

  def r_relation_body(rules : AbsSyntTree) : QR::QRLoadFileValues | QR::QRLoadFromStore | QR::SubQuery | QR::QrLoadFileFile
    #   relation_body :
    #   "(" relation_body ")"
    # | "VALUES" value_list tbl_col_alias?
    # | "SELECT" projectbody
    # | tablename tbl_alias? ;`;
    try_tbl_alias = ->(stpr : Stepper) {
      if stpr.having_more
        if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_tbl_col_alias"
          aliaset = r_tbl_col_alias(rules: stpr.content_now)
          {as_table: aliaset[:table_name], as_cols: aliaset[:col_names]}
        else
          {as_table: "", as_cols: [] of String}
        end
      else
        {as_table: "", as_cols: [] of String}
      end
    }
    stpr = Stepper.new(rules)
    if stpr.content_now.kind == "resoper" && stpr.content_now.value == "("
      stpr.next
      to_ret : QR::QRLoadFileValues | QR::QRLoadFromStore | QR::SubQuery | QR::QrLoadFileFile = r_relation_body(stpr.content_now)
      stpr.next

      if stpr.content_now.kind == "resoper" && stpr.content_now.value == ")"
        stpr.next
        if is_type_tbl_col_alias(stpr.content_now)
          tbl_cols = try_tbl_alias.call(stpr)
          opt_drived_as = QR::QRASTableCols.new(tbl_cols[:as_table], tbl_cols[:as_cols])
          if to_ret.is_a?(QR::SubQuery)
            to_ret.derived_as = opt_drived_as
          end
          return to_ret
        else
          raise " Missing mandatory 'AS' "
        end
      else
        raise "r_relation_body() Expecting ')'"
      end
    elsif stpr.content_now.kind == "resword" && stpr.content_now.value == "VALUES"
      stpr.next
      a_QRLoadFileValues = r_value_list(stpr.content_now)
      if stpr.having_more
        stpr.next
        aliaset = r_tbl_col_alias(rules: stpr.content_now)
        a_QRLoadFileValues.filename = aliaset[:table_name]
        a_QRLoadFileValues.colnames = aliaset[:col_names]
        @db.add_value_table("VALUES",
          a_QRLoadFileValues.filename,
          a_QRLoadFileValues.colnames,
          a_QRLoadFileValues.rows
        )
        return a_QRLoadFileValues
      else
        raise "r_relation_body() 'VALUES' missing 'tbl_col_alias'"
      end
    elsif stpr.content_now.kind == "resword" && stpr.content_now.value == "SELECT"
      stpr.next
      to_ret = r_projectbody(stpr.content_now)
      return to_ret
    elsif stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_tablename"
      if stpr.content_now.content[0].rule_name == "r_Identifier_Lx"
        use_table = stpr.content_now.content[0].value
        stpr.next
        x = try_tbl_alias.call(stpr)
        to_ret = QR::QRLoadFromStore.new(use_table, x[:as_table], x[:as_cols])
        return to_ret
      elsif stpr.content_now.content[0].rule_name == "r_SQString_Lx"
        loadfilename = stpr.content_now.content[0].value
        stpr.next
        x = try_tbl_alias.call(stpr)
        to_ret = QR::QrLoadFileFile.new(loadfilename, x[:as_table], x[:as_cols])
        return to_ret
      else
        raise "r_relation_body() from must be 'string or ident"
      end
    else
      pp rules
      raise "r_relation_body() Odd rule"
    end
  end

  # =============================
  def is_type_joiner_or_setoper(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_joiner_or_setoper"
  end

  def r_joiner_or_setoper(rules : AbsSyntTree)
    # ( ( "JOIN" | ( join_type "JOIN" ) ) relation_body "ON" pcondexpr )
    # | (("UNION" | "EXCEPT" | "INTERSECT") "ALL"?  relation_body)
    # | ("CROSS" "JOIN" relation_body)
    if !is_type_joiner_or_setoper(rules)
      raise "r_joiner_or_setoper() wrong rule"
    end
    stpr = Stepper.new(rules)
    if stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_join_type"
      join_type = stpr.content_now.content[0].value
      if (join_type == "INNER") ||
         (join_type == "LEFT") ||
         (join_type == "RIGHT") ||
         (join_type == "FULL")
        stpr.next
        optional_join_cover = join_type
      else
        raise "r_join_type ? "
      end
    else
      optional_join_cover = "INNER"
    end
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "JOIN")
      pp stpr.content_now
      raise "r_joiner_or_setoper() Missing 'JOIN'"
    end
    stpr.next
    the_from : QR::QRLoadFileValues | QR::QRLoadFromStore | QR::SubQuery | QR::QrLoadFileFile = r_relation_body(stpr.content_now)
    a_QFrom = convert_r_relation_body_2_QFrom(the_from)
    stpr.next
    ret = r_onrule(stpr.content_now)
    return {the_from: a_QFrom, the_r_onrule: ret, join_cover: optional_join_cover}
  end

  # =============================
  def is_type_onrule(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_onrule"
  end

  def r_onrule(rules : AbsSyntTree)
    if !is_type_onrule(rules)
      pp rules
      raise "Wrong rule to 'r_onrule' "
    end
    stpr = Stepper.new(rules)

    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "ON")
      pp stpr.content_now
      raise "Expecting 'ON' "
    end
    stpr.next

    ret = r_fullcondexpr(stpr.content_now)
    return ret
  end

  # =============================
  def is_type_fullcondexpr(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_fullcondexpr"
  end

  def r_fullcondexpr(rules : AbsSyntTree)
    if !is_type_fullcondexpr(rules)
      pp rules
      raise "Wrong rule to 'r_fullcondexpr' "
    end
    to_ret : QR::QRWhere = QR::QRWhere.new

    stpr = Stepper.new(rules)
    if stpr.size > 1
      to_ret.more_cond_expr = [] of QR::QRMoreCondExpr
    end
    ret = r_pcondexpr(stpr.content_now)
    to_ret.first_cond_expr = ret
    stpr.next

    while stpr.having_more
      if (stpr.content_now.kind == "rule" && stpr.content_now.rule_name == "r_andor")
        the_and_or = stpr.content_now.content[0]
        oper = the_and_or.value
        the_rules = stpr.content_now.content[1]
        ret = r_pcondexpr(the_rules)
        a_QRMoreCondExpr = QR::QRMoreCondExpr.new
        a_QRMoreCondExpr.more = ret
        a_QRMoreCondExpr.and_or_or = oper
        to_ret.more_cond_expr << a_QRMoreCondExpr
        stpr.next
      else
        pp stpr.content_now
        raise "r_where() Expecting 'AND' or 'OR' "
      end
    end
    return to_ret
  end

  # =============================

  def r_value_list(rules : AbsSyntTree) : QR::QRLoadFileValues
    # value_list : "(", a, b, c, ")" , "("...")"
    if !(rules.kind == "rule" && rules.rule_name == "r_value_list")
      raise "r_value_list() wrong rule"
    end
    all_rows : Array(Array(String)) = [] of Array(String)
    this_row : Array(String) = [] of String

    rules.content.each { |item|
      if item.kind == "resoper" && item.value == "("
        this_row.clear # start of row
      elsif item.kind == "resoper" && item.value == ")"
        all_rows.push(this_row.clone) # inside row
      elsif item.kind == "lexem"
        this_row.push(item.value) # end of row
      else
        pp item
        raise "r_value_list() Odd content. Maybe subquery"
      end
    }
    return QR::QRLoadFileValues.new("", [] of String, all_rows)
  end

  # =============================
  def is_type_tablename(rules : AbsSyntTree)
    if (rules.kind == "rule" && rules.rule_name == "r_tablename")
      return true
    else
      return false
    end
  end

  def r_tablename(rules : AbsSyntTree) : {table_name: String, rule_name: String}
    # r_SQString_Lx}

    table_name = rules.content[0].value
    if rule_name = rules.content[0].rule_name
      {table_name: table_name, rule_name: rule_name}
    else
      raise "r_tablename() No rule? #{rules}"
    end
  end

  # =============================
  def is_type_tbl_alias(rules : AbsSyntTree)
    if (rules.kind == "rule" && rules.rule_name == "r_tbl_alias")
      return true
    else
      return false
    end
  end

  # =============================
  def is_type_tbl_col_alias(rules : AbsSyntTree)
    if (rules.kind == "rule" && rules.rule_name == "r_tbl_col_alias")
      return true
    else
      return false
    end
  end

  def r_tbl_col_alias(rules : AbsSyntTree) : {table_name: String, col_names: Array(String)}
    # "AS" AS_TID ;
    if !is_type_tbl_col_alias(rules)
      pp rules
      raise "r_tbl_col_alias() wrong rule"
    end

    as_colnames : Array(String) = [] of String
    as_table_name : String = ""

    stpr = Stepper.new(rules)
    if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "AS")
      pp stpr.content_now
      raise "Expecting 'AS' "
    end
    stpr.next
    as_table_name = r_AS_TID(stpr.content_now)
    stpr.next
    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "(")
      pp stpr.content_now
      raise "Expecting '(' "
    end
    stpr.next
    ret_column_comma_list = r_column_comma_list(stpr.content_now)
    stpr.next

    if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == ")")
      pp stpr.content_now
      raise "Expecting ')' "
    end
    return {table_name: as_table_name, col_names: ret_column_comma_list}

    ##################################
    kids = rules.content

    as_resword_rule = kids[0]
    if !(as_resword_rule.kind == "resword" && as_resword_rule.value == "AS")
      pp rules
      raise "r_tbl_col_alias() 'AS' missing"
    end
    as_AS_TID_rule = kids[1]
    if !(as_AS_TID_rule.kind == "rule" && as_AS_TID_rule.rule_name == "r_AS_TID")
      pp rules
      raise "r_tbl_col_alias() 'AS' missing must be a table name"
    end
    as_table_name_lexem = as_AS_TID_rule.content[0]
    if !(as_table_name_lexem.kind == "lexem" && as_table_name_lexem.rule_name == "r_Identifier_Lx")
      pp rules
      raise "r_tbl_col_alias() 'AS' columns must be a 'r_Identifier_Lx' "
    end
    as_table_name = as_table_name_lexem.value

    left_comma = kids[2] # resword
    if !(left_comma.kind == "resoper" && left_comma.value == "(")
      pp rules
      raise "r_tbl_col_alias() 'AS' colmn list must start witj an '(' "
    end
    column_comma_list = kids[3]
    if !(column_comma_list.kind == "rule" && column_comma_list.rule_name == "r_column_comma_list")
      pp rules
      raise "r_tbl_col_alias() 'AS' colmn list must start with 'r_column_comma_list' "
    end

    column_comma_list.content.each { |a_column|
      if !(a_column.kind == "rule" && a_column.rule_name == "r_AS_CID")
        pp rules
        raise "r_tbl_col_alias() 'AS' colmn list must start with 'r_AS_CID' "
      end
      the_colname_lexem = a_column.content[0]
      if !(the_colname_lexem.kind == "lexem" && the_colname_lexem.rule_name == "r_Identifier_Lx")
        pp rules
        raise "r_tbl_col_alias() 'AS' colmn list must be a 'r_Identifier_Lx' "
      end
      the_colname = the_colname_lexem.value
      as_colnames << the_colname
    }
    return {table_name: as_table_name, col_names: as_colnames}
  end

  # =============================
  def is_type_Identifier_Lx(rules : AbsSyntTree)
    return rules.kind == "lexem" && rules.rule_name == "r_Identifier_Lx"
  end

  def r_Identifier_Lx(rules : AbsSyntTree) : String
    if !is_type_Identifier_Lx(rules)
      pp rules
      raise "Wrong rule to 'r_ASis_type_Identifier_Lx_TID' "
    end
    if rules.value.is_a?(String)
      return rules.value
    else
      raise "r_Identifier_Lx not a String #{rules.value}"
    end
  end

  # =============================
  def is_type_AS_TID(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_AS_TID"
  end

  def r_AS_TID(rules : AbsSyntTree)
    if !is_type_AS_TID(rules)
      pp rules
      raise "Wrong rule to 'r_AS_TID' "
    end
    stpr = Stepper.new(rules)

    ret = r_Identifier_Lx(stpr.content_now)
    return ret
  end

  # =============================
  def is_type_AS_CID(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_AS_CID"
  end

  def r_AS_CID(rules : AbsSyntTree) : String
    if !is_type_AS_CID(rules)
      pp rules
      raise "Wrong rule to 'r_AS_CID' "
    end
    stpr = Stepper.new(rules)

    ret = r_Identifier_Lx(stpr.content_now)
    return ret
  end

  # =============================
  def is_type_TID(rules : AbsSyntTree)
    return rules.kind == "rule" && rules.rule_name == "r_TID"
  end
end
