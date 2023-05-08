class Rot
  # ************************************************************************
  def create_dbschema
    # /////////
    running_build_column_index = 0 # Just declare it
    #
    # ////////////////////////////////////
    # .....................................................................
    gen_public_colname_name = ->(col_name : String, any_prefix : String) {
      if any_prefix.size != 0
        # public_name = "#{col_name}_#{any_suffixet}"
        public_name = "#{any_prefix}#{col_name}"
      else
        public_name = col_name
      end
      public_name
    }
    # .....................................................................
    gen_one_plain = ->(the_table : Table, col_name : String, par_optional : Bool, par_unique : Bool, the_relative : ToRelated?) {
      the_table.the_column_attributes << ColumnAttribute.new(name: col_name,
        is_optional: par_optional,
        is_unique: par_unique,
        relative_entity: the_relative)
      the_table.the_columns << col_name

      running_build_column_index += 1

      return self, "OK"
    }
    # .....................................................................
    relater = ->(the_table : Table, a_FKCreate : Array(FKCreate), out_DBSchema : DBSchema) {
      a_FKCreate.each { |one_FKCreate|
        parent_attribute_obj, txt = out_DBSchema.find_table_by_name(one_FKCreate.parent_table_name)
        if !parent_attribute_obj
          return parent_attribute_obj, txt
        end
        a_ToRelated = ToRelated.new(one_FKCreate.parent_table_name)
        # a_ToRelated.is_optional = a_json_related_attribute.is_optional != nil
        # a_ToRelated.to_parent_name = to_parent_name
        a_ToRelated.is_optional = false
        parent_attribute_obj.the_pk_col_names.each_with_index { |colname, indx_pk|
          colname = gen_public_colname_name.call(colname,
            one_FKCreate.prefix)

          a_ToRelated.col_names << colname
          a_ToRelated.from_columns_in_own_row << running_build_column_index
          gen_one_plain.call(the_table, colname,
            # a_json_related_attribute.is_optional != nil,
            false,
            false,
            a_ToRelated
          )
          the_table.the_related_columns << a_ToRelated
          # pp the_table.the_related_columns
        }
      }
    }
    out_DBSchema = DBSchema.new
    this_running_parent_nr = 1

    # local_name_to_table : Hash(String, Table) = Hash(String, Table).new
    own_primary_in_table : Hash(Table, String) = Hash(Table, String).new
    start_running_build_column_index : Hash(String, Int32) = Hash(String, Int32).new
    #
    # Firts pk for entity and rlationship
    @topoplogical_sort.map { |a_tbl_name|
      running_build_column_index = 0
      tbl = Table.new
      tbl.name = a_tbl_name
      #   local_name_to_table[tbl.name] = tbl
      a_BasTableCreate = @name_to_table[a_tbl_name]
      case a_BasTableCreate.kind
      when "entity"
        tbl.kind = TableType::Entity
        tbl.the_pk_col_names = [a_BasTableCreate.entity.pk[:col_name]]
        tbl.the_columns = tbl.the_pk_col_names.clone
        tbl.the_col_index_pk = (0..tbl.the_pk_col_names.size - 1).map { |i| i }
        running_build_column_index = tbl.the_pk_col_names.size
        start_running_build_column_index[tbl.name] = running_build_column_index
        #
      when "relationship"
        # Resolve source name for all related
        # a_BasTableCreate.relat.collect_pk
        this_running_pk_index = 0
        tbl.kind = TableType::Relation
        #
        # PRIMARY KEY (FROM OTHER TABLES)
        #
        a_BasTableCreate.relat.parent_tables.each_with_index { |a_FKCreate, parent_number|
          parent_table_obj, txt = out_DBSchema.find_table_by_name(a_FKCreate.parent_table_name)
          if !parent_table_obj
            raise "loaddef() 0 Parent table '#{a_FKCreate.parent_table_name}' not found"
          end
          xparent = parent_table_obj
          xchild = tbl

          xparent.pk_child_tables_names << xchild.name
          # puts "Table '#{xparent.name}' now has '#{xparent.pk_child_tables_names.map{|x|x}}' as pk_child_tables_names"
          local_parent_name = a_FKCreate.parent_table_name
          if a_FKCreate.prefix.size != 0
            # puts "a_FKCreate.prefix=#{a_FKCreate.prefix}"
            local_parent_name = a_FKCreate.prefix + local_parent_name
          end
          a_ToParent_obj = ToParent.new("fk_#{this_running_parent_nr.to_s}",
            local_parent_name, parent_table_obj)
          # a_ToParent_obj.to_parent_name = local_parent_name
          a_ToParent_obj.to_parent_name = a_FKCreate.parent_table_name
          parent_table_obj.the_pk_col_names.each_with_index { |colname, indx_pk|
            public_name = gen_public_colname_name.call(colname,
              a_FKCreate.prefix)
            tbl.the_columns << public_name
            tbl.the_pk_col_names << public_name
            tbl.the_col_index_pk << this_running_pk_index
            a_ToParent_obj.from_columns_in_pk << this_running_pk_index
            this_running_pk_index += 1
            running_build_column_index += 1
          }
          this_running_parent_nr += 1
          tbl.the_parents << a_ToParent_obj
        }
        #
        # PRIMARY KEY (FROM OWN DEFINITIONS)
        #

        a_BasTableCreate.relat.own_primary.each_with_index { |a_own_name, own_index|
          tbl.the_pk_col_names << a_own_name[:col_name]
          tbl.the_columns << a_own_name[:col_name]
          tbl.the_col_index_pk << this_running_pk_index
          tbl.index_own_pk << this_running_pk_index
          this_running_pk_index += 1
          running_build_column_index += 1
        }
        start_running_build_column_index[a_BasTableCreate.tablename] = running_build_column_index
      end
      out_DBSchema.tables << tbl
    }
    # Now resolve all relatives and ordinary columns
    topoplogical_sort.each { |tlb_name|
      json_tbl = @name_to_table[tlb_name]
      a_table, msg = out_DBSchema.find_table_by_name(tlb_name)
      if a_table.nil?
        raise "Table '#{tlb_name}' not found in step 2"
      end
      case json_tbl.kind
      when "entity"
        # ATRRIBUTES FROM OTHER TABLE
        #
        running_build_column_index = start_running_build_column_index[tlb_name]
        relater.call(a_table, json_tbl.related_attributes, out_DBSchema)
        #
        # PLAIN ATTRIBUTES
        #
        json_tbl.plain_attributes.each { |a_column|
          gen_one_plain.call(a_table, a_column.col_name,
            a_column.is_optional != nil,
            a_column.is_unique != nil,
            nil
          )
        }
      when "relationship"
        # ATTRIBUTES FROM OTHER TABLE
        #
        running_build_column_index = start_running_build_column_index[json_tbl.tablename]
        relater.call(a_table, json_tbl.related_attributes, out_DBSchema)
        #
        # PLAIN ATTRIBUTES
        #
        json_tbl.plain_attributes.each { |a_column|
          gen_one_plain.call(a_table, a_column.col_name,
            a_column.is_optional != nil,
            a_column.is_unique != nil,
            nil
          )
        }
      end
    }
    out_DBSchema.tables.each { |a_FromTable|
      # Related columns. Tell parent of child
      a_FromTable.the_related_columns.each { |a_ToRelated|
        # puts "Table '#{a_FromTable.name}' has a relativ ref to table '#{a_ToRelated.to_parent_name}' "
        to_parent_Table, txt = out_DBSchema.find_table_by_name(a_ToRelated.to_parent_name)
        if !to_parent_Table
          raise "Table '#{a_ToRelated.to_parent_name}' not found in step 2"
        end
        col_name = a_ToRelated.col_names
        to_parent_Table.relatives_childs_tables_names << {to_child_table: a_FromTable.name, to_child_columns: col_name}
        # puts "Table '#{to_parent_Table.name}' is now aware it has a child in Table '#{a_FromTable.name}' and its columns '#{col_name}'"
      }
    }
    out_DBSchema
  end
end
