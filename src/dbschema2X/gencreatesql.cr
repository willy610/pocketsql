class Rot
  # ************************************************************************

  def export_create_sql(tablesuffix : String)
    # --------
    # Entity table
    # TABLENAME
    # PRIMARYKEY (colname1 "ATTR1")
    # OWNPRIMARY (colname1 "ATTR2") ???
    # ->colname1 "ATTR1" NOT NULL,
    # ->colname2 "ATTR2" NOT NULL,
    # ->PRIMARY KEY (colname1,colname2)
    # -----------

    # --------
    # Relationship table
    # TABLENAME
    # PRIMARYKEY (
    #  PARENTS (table1, table2 PREFIX old)
    #  OWNPRIMARY (something "ATTR")
    #  )
    # ------ PATTERN for FKCreate as in primary OR a RELATEDCOLUMN
    # foreach PARENTS.table_pk_col
    #     ->[prefixe_]foreign_key_col "ATTR1" NOT NULL
    # ->FOREIGN KEY parent_foreign_key_cols (foreign_key_col,)
    # - REFERENCES `#{tableN}` (foreign_key_col,)"
    # ->something "ATTR" NOT NULL
    # ================================
    # Relationship table
    # ->PRIMARY KEY (all_fk_colsN,something)
    # ================================
    # -----------

    # --------
    # PLAINCOLUMN (colname1 "ATTR1",colname2 "ATTR2")
    # ->colname1 "ATTR1",
    # ->colname2 "ATTR2",
    # --------
    xy = @topoplogical_sort.map { |a_tbl_name|
      a_BasTableCreate = @name_to_table[a_tbl_name]
      a_BasTableCreate.related_attributes.each { |an_FKCreate|
        an_FKCreate.parent_table_obj = @name_to_table[an_FKCreate.parent_table_name]
      }
      if a_BasTableCreate.kind == "entity"
        x = gen_ent_pk(a_BasTableCreate, tablesuffix)
      else
        # puts "resolve_pk for table=#{a_BasTableCreate.tablename}"
        a_BasTableCreate.relat.collect_pk
        # a_BasTableCreate.relat.resolve_pk
        # puts " resolved = #{a_BasTableCreate.relat.resolved_pk}"
        y = gen_relat_pk(a_BasTableCreate, tablesuffix)
      end
    }
    [@topoplogical_sort.reverse.map { |a_tbl_name|
      "DROP TABLE IF EXISTS `#{a_tbl_name}`;"
    }.join('\n'),
     xy].flatten
  end

  # ******************************************
  def gen_ent_pk(a_BasTableCreate : BasTableCreate, tablesuffix : String)
    # PK
    # PRIMARY KEY (...)
    pkddef = "  PRIMARY KEY ( `#{a_BasTableCreate.entity.pk[:col_name]}` )"
    pkdcl = "  `#{a_BasTableCreate.entity.pk[:col_name]}` #{a_BasTableCreate.entity.pk[:sql_attr]}"
    # RELATED COLUMNS
    a_BasTableCreate.related_attributes.each { |a_FKCreate| a_FKCreate.collect_fk }
    relcols = a_BasTableCreate.related_attributes.map { |a_FKCreate|
      one_relat = build_one_fk_ref(a_BasTableCreate, a_FKCreate)
      [one_relat[:pk_dcl], one_relat[:fk_def], one_relat[:fk_index]]
    }
    # PLAINCOLUMNS
    plaincols = a_BasTableCreate.plain_attributes.map { |a_PlainColumnCreate|
      build_one_plain_column(a_PlainColumnCreate)
    }
    allt = [pkdcl, pkddef, plaincols, relcols].flatten.join(",\n")
    ret =
      "CREATE TABLE `#{a_BasTableCreate.tablename}` (
#{allt}
)#{tablesuffix};
"
  end

  # ******************************************
  def gen_relat_pk(a_BasTableCreate : BasTableCreate, tablesuffix : String) : String
    # PK COLUMNS
    #
    mypknames : Array(String) = [] of String
    #
    # PARENTS (table1, table2 PREFIX old)
    #
    # pkcols = [""]
    pkcols = a_BasTableCreate.relat.parent_tables.map { |a_FKCreate|
      one_fk = build_one_fk_ref(a_BasTableCreate, a_FKCreate)
      mypknames += one_fk[:all_pks]
      [one_fk[:pk_dcl], one_fk[:fk_def], one_fk[:fk_index]]
    }
    mypknames += a_BasTableCreate.relat.own_primary.map { |x| x[:col_name] }
    mypknames = mypknames.flatten

    # PLAINCOLUMNS

    plaincols = a_BasTableCreate.plain_attributes.map { |a_PlainColumnCreate|
      build_one_plain_column(a_PlainColumnCreate)
    }
    a_BasTableCreate.related_attributes.each { |a_FKCreate|
      a_FKCreate.collect_fk
    }
    relcols = a_BasTableCreate.related_attributes.map { |a_FKCreate|
      one_relat = build_one_fk_ref(a_BasTableCreate, a_FKCreate)
      [one_relat[:pk_dcl], one_relat[:fk_def], one_relat[:fk_index]]
    }

    # OWNPRIMARY
    own_primary = a_BasTableCreate.relat.own_primary.map { |o| "  `#{o[:col_name]}` #{o[:sql_attr]}" }
    all_pk_s = "PRIMARY KEY (#{mypknames.join(',')})"
    allt = [pkcols, own_primary, relcols, plaincols, all_pk_s].flatten.join(",\n")
    ret =
      "CREATE TABLE `#{a_BasTableCreate.tablename}` (
#{allt}
)#{tablesuffix};
"
  end

  # ************************************************************************

  def build_one_fk_ref(a_BasTableCreate : BasTableCreate, the_FKCreate : FKCreate)
    pk_dcl : Array(String) = [] of String
    all_pks : Array(String) = [] of String
    one_time : Array(ParentPKAttribs) = the_FKCreate.parent_table_obj.get_pk
    the_FKCreate.collected_fk.each { |one_pk|
      pk_dcl << "  `#{one_pk[:col_name]}` #{one_pk[:sql_attr]}"
      all_pks << one_pk[:col_name]
    }
    all_parent_pk = all_pks.map { |c| c[the_FKCreate.prefix.size..] }

    fk_def = "  CONSTRAINT `fk_#{a_BasTableCreate.tablename}_#{the_FKCreate.prefix}_#{the_FKCreate.parent_table_name}`
     FOREIGN KEY (#{all_pks.join(',')})
     REFERENCES `#{the_FKCreate.parent_table_name}` (#{all_parent_pk.join(',')})"

    fk_index = "  INDEX parent_index_#{all_pks.join('_')} (#{all_pks.join(',')})"
    {pk_dcl: pk_dcl, fk_def: fk_def, fk_index: fk_index, all_pks: all_pks}
  end

  # ******************************************
  def build_one_plain_column(a_PlainColumnCreate : PlainColumnCreate)
    "  `#{a_PlainColumnCreate.col_name}` " + a_PlainColumnCreate.sql_attributes
  end
end
