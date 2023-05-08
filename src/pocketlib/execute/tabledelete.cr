class Table
  #
  # 1. Public entry is 'delete_rows'
  # 2. Update (delete) all indexes to parent keys
  # 3. Then inovoke 'private_delete_one_new' which will do deep cascade delete of all cilds
  #
  def delete_rows(row_ids : Array(RowId)) : {Nil | Table, String}
    # res, msg = {self, "Ok"}
    row_ids.each { |a_RowId|
      the_row_values = @the_rows[a_RowId]
      the_pk : PkValue = @the_col_index_pk.map { |i| the_row_values[i] }
      res, msg = ensure_no_refs_from_relatives(pk_value: the_pk)
      if res.nil?
        return res, msg
      end
      #
      # DO WE HAVE PARENT INDEX ?
      #
      @the_parents.each { |a_ToParentIndex|
        this_parent_key : PkValue = a_ToParentIndex.from_columns_in_pk.map { |i| the_row_values[i] }
        res_rows = a_ToParentIndex.key_and_rows.fetch(this_parent_key, nil)
        if rows = res_rows
          #
          a_ToParentIndex.key_and_rows.update(this_parent_key) { |value| value - [a_RowId] }
          remaing_row_values = a_ToParentIndex.key_and_rows[this_parent_key]
          if remaing_row_values.size == 0
            a_ToParentIndex.key_and_rows.delete(this_parent_key)
          end
        else
          STDERR.puts "don't have rows"
        end
      }
      res, msg = private_delete_one_new(row_id: a_RowId)
      if res == nil
        return res, msg
      end
    }
    return self, "Ok"
  end

  # -----------------------------------

  private def private_delete_one_new(row_id : RowId) : {Nil | Table, String}
    #
    # 1. Update all index in the refs to parent
    #
    @the_parents.each { |a_ToParentIndex|
      res_the_pk_value = a_ToParentIndex.row_and_key.delete(row_id)
      if the_pk_value = res_the_pk_value
        #
        a_ToParentIndex.key_and_rows.update(the_pk_value) { |value| value - [row_id] }
        remaing_row_values = a_ToParentIndex.key_and_rows[the_pk_value]
        if remaing_row_values.size == 0
          a_ToParentIndex.key_and_rows.delete(the_pk_value)
        end
      end
    }
    #
    # 2. Cascade delete all childs having this pk
    #
    the_row_values = @the_rows[row_id]
    this_row_pk_value : PkValue = @the_col_index_pk.map { |i| the_row_values[i] }

    # @meta_info.child_table_names.each { |a_child_table_name, the_childer_obj|
    # puts "private_delete_one_new() "+@name
    # puts " @pk_child_tables " + @pk_child_tables.to_s
    @pk_child_tables.each { |the_childer_obj|
      # debug!(the_childer_obj.name)
      # debug!(@name)
      # debug!(this_row_pk_value)
      res, msg = the_childer_obj.do_cascade_delete_childs(from_table_name: @name, pk_value: this_row_pk_value)
      if !res
        return res, msg
      end
    }
    #
    # 3. Reduce relative attributes
    #
    @the_related_columns.each { |a_ToRelated|
      the_col_value = a_ToRelated.from_columns_in_own_row.map { |c| the_row_values[c] }
      old_rows = a_ToRelated.key_and_rows.fetch(the_col_value, nil)
      old_rows.try { |all_rows|
        a_ToRelated.key_and_rows[the_col_value] = all_rows - [row_id]
        if a_ToRelated.key_and_rows[the_col_value].size == 0
          a_ToRelated.key_and_rows.delete(the_col_value)
        end
      }
    }
    #
    # 4. Delete the row
    #
    res = @the_rows.delete(row_id)
    if !res
      return res, "Rowid '#{row_id}' not in table '#{@name}'"
    end
    res = @the_pks.delete(this_row_pk_value)
    if !res
      return res, "Pkvalues '#{this_row_pk_value}' not in table '#{@name}'"
    end
    return self, "Ok"
  end

  # -----------------------------------
  def do_cascade_delete_childs(from_table_name : String, pk_value : PkValue) : {Nil | Table, String}
    # Called from parent table when a pk_value is deleted.
    # Delete rows with that parent key
    @the_parents.each { |a_parent|
      if a_parent.to_parent_obj.name == from_table_name
        # Is there a ref to parent ?
        res_rows = a_parent.key_and_rows.fetch(pk_value, nil)
        if res_rows
          res_rows.each { |one_row_id|
            #
            # Before deleting a pk
            # ensure it is not used
            # as a relative attribute in an other table
            #
            res, msg = ensure_no_refs_from_relatives(pk_value: pk_value)
            if res.nil?
              return res, msg
            end
            res, msg = private_delete_one_new(row_id: one_row_id)
            if !res
              return res, msg
            end
          }
        else
          # STDERR.puts "OK, No keys '#{pk_value}'in '#{@name} "
        end
      end
    }
    return self, "Ok"
  end

  private def ensure_no_refs_from_relatives(pk_value : PkValue)
    #
    # Before deleting a pk ensure it is not used as a relative attribute in an other table
    #
    nr_refs = @count_relatives_refs_into.fetch(pk_value, nil)
    nr_refs.try { |cnt|
      msg = "Pkvalue '#{pk_value}' in Table '#{@name}' has '#{cnt}' reference(s) as relative attribute. Row can't be deleted"
      STDERR.puts msg
      @relatives_childs_tables.each { |childtable_and_colname|
        child_table_obj = childtable_and_colname[:to_child_table_obj]
        col_names = childtable_and_colname[:to_child_columns]

        # child_table_obj.the_related_columns.each { |a_ToRelated|
        #   if col_name == a_ToRelated.col_names
        #     STDERR.puts "Referenced in table '#{child_table_obj.name}' and column #{a_ToRelated.col_names}'"
        #   end
        # }
      }
      return nil, msg
    }
    return self, "OK"
  end
end
