class Table
  # -----------------------------------

  def update_pk_row(row_number : RowId,
                    col_names : Array(ColName),
                    new_values : Array(ColValue)) : {Nil | Table, String}
    #
    # We have ( for an entity table only)
    # A A B C C C <- parent key name
    # 1 2 3 4 5 6 <- old pk value
    #   X     Y   <- new columns in pk
    # 1 X 3 4 Y 6 <- new pk
    # A A   C C C <- parent index to be updated
    # 1 2   4 5 6 <- old values for parent key index
    # 1 X   4 Y 6 <- new values for parent key index

    old_row_values = @the_rows[row_number]
    old_pk : PkValue = @the_col_index_pk.map { |i| old_row_values[i] }
    new_pk : PkValue = old_pk.clone
    colindex_to_update = @the_pk_col_names.map_with_index { |self_col_name, i|
      res_is_new = col_names.index(self_col_name, 0)
      if is_new = res_is_new
        new_pk[i] = new_values[is_new]
        i
      else
        -1
      end
    }.select { |p| p != -1 }

    if @the_pks.has_key?(new_pk)
      msg = "New primary '#{new_pk}' already exists"
      STDERR.puts msg
      return nil, msg
    end
    #
    # This is only used on relationship tables. Not on entity. They don't have any parents
    #
    @the_parents.each { |a_ToParentIndex|
      any_col_changed = colindex_to_update.map { |an_index_in_pk|
        a_ToParentIndex.from_columns_in_pk.includes?(an_index_in_pk)
      }
      if any_col_changed.any?(true)
        this_parent_new_key = a_ToParentIndex.from_columns_in_pk.map { |i| new_pk[i] }
        # Ensure parent new key exist
        value = a_ToParentIndex.to_parent_obj.the_pks.fetch(this_parent_new_key, nil)
        if !value
          msg = "New pk value '#{this_parent_new_key}' does not exists as parent key in '#{a_ToParentIndex.to_parent_obj.name}'"
          STDERR.puts msg
          return nil, msg
        end
        this_parent_old_key : PkValue = a_ToParentIndex.from_columns_in_pk.map { |i| old_pk[i] }
        # Now update out parent key index
        a_ToParentIndex.key_and_rows.update(this_parent_old_key) { |value| value - [row_number] }
        remaing_row_values = a_ToParentIndex.key_and_rows[this_parent_old_key]
        if remaing_row_values.size == 0
          a_ToParentIndex.key_and_rows.delete(this_parent_old_key)
        end
        if a_ToParentIndex.key_and_rows.has_key?(this_parent_new_key)
          a_ToParentIndex.key_and_rows.update(this_parent_new_key) { |value| value << row_number }
        else
          a_ToParentIndex.key_and_rows[this_parent_new_key] = [row_number]
        end
      end
    }
    res, txt = update_row_pk_ny_aaa(row_number: row_number, old_pk: old_pk, new_pk: new_pk)
    return res, txt
  end

  # -----------------------------------
  # ------------------------------------------------------------

  private def update_row_pk_ny_aaa(row_number : RowId,
                                   old_pk : PkValue, new_pk : PkValue) : {Nil | Table, String}
    old_row = @the_rows[row_number]
    # Build new pk from old stored values merged with in params
    # Update index on parent parts

    # Just invoke clients with our new and old pk value and anem
    # @meta_info.child_table_names.each { |a_child_table_name, the_childer_obj|
    # @child_tables.each { |the_childer_obj|
    @pk_child_tables.each { |the_childer_obj|
      res, msg = the_childer_obj.update_client_pk(from_table_name: @name,
        old_parent_pk: old_pk,
        new_parent_pk: new_pk)
      if res == nil
        STDERR.puts msg
        return res, msg
      end
    }
    # Update self row

    the_colvalues = @the_rows[row_number]
    @the_col_index_pk.each { |i| the_colvalues[i] = new_pk[i] }

    @the_rows[row_number] = the_colvalues
    @the_pks.delete(old_pk)
    @the_pks[new_pk] = row_number
    return self, "Ok"
  end

  # -----------------------------------
  def update_client_pk(from_table_name : String,
                       old_parent_pk : PkValue,
                       new_parent_pk : PkValue) : {Nil | Table, String}
    #
    @the_parents.each { |a_parent|
      if a_parent.to_parent_obj.name == from_table_name
        # Get all rowids for this (partial) pk
        res_rowids = a_parent.key_and_rows.fetch(old_parent_pk, nil)
        res_rowids.try { |rowids|
          rowids.each { |a_rowid|
            old_row_value = @the_rows[a_rowid]
            old_self_pk : PkValue = @the_col_index_pk.map { |i| old_row_value[i] }
            new_self_pk : PkValue = old_self_pk.clone
            a_parent.from_columns_in_pk.each_with_index { |iself, ip| new_self_pk[iself] = new_parent_pk[ip] }

            # Extract own old pk from row
            # Update certain pk columns which should have new values

            res, msg = update_row_pk_ny_aaa(row_number: a_rowid, old_pk: old_self_pk, new_pk: new_self_pk)
            if res == nil
              STDERR.puts msg
              return res, msg
            end
          }
          # Now update the pk in this parent index
          a_parent.key_and_rows[new_parent_pk] = rowids
        }
      end
    }
    return self, "OK"
  end

  # -----------------------------------
  # -----------------------------------
  # -----------------------------------
  def update_attributes(row_number : RowId, col_names : Array(String), new_values : Array(String)) : {Nil | Table, String}
    old_row = @the_rows[row_number]
    new_row = old_row.clone

    col_names.each_with_index { |a_col_name, index_new_value|
      res_i = @the_columns.index(a_col_name, 0)
      if i = res_i
        if i <= the_pk_col_names.size - 1
          msg = "Colname '#{a_col_name}' is part of primary key. Should be an attribute"
          STDERR.puts msg
          return nil, msg
        end
        new_row[i] = new_values[index_new_value]
        # Is this a relative column ? Related to an other tables
        @the_related_columns.each { |a_ToRelated|
          if a_ToRelated.col_names.includes?(a_col_name)
            the_parent_old_pk : PkValue = a_ToRelated.from_columns_in_own_row.map { |c| old_row[c] }
            the_parent_new_pk : PkValue = a_ToRelated.from_columns_in_own_row.map { |c| new_row[c] }
            # Ensure new col_value exists at the parent
            pk_exists = a_ToRelated.to_parent_obj.the_pks.fetch(the_parent_new_pk, nil)
            if pk_exists.nil?
              msg = "Related key '#{the_parent_new_pk}' for '#{a_ToRelated.col_names}' in Table '#{name}' does not exists"
              STDERR.puts msg
              return nil, msg
            end
            # Take care of info for this table
            old_rows = a_ToRelated.key_and_rows.fetch(the_parent_old_pk, nil)
            if old_rows.nil?
              msg = "(Internal error) Old value '#{the_parent_old_pk}' was not found when updating attribute '#{a_col_name}' in in Table '#{name}'"
              STDERR.puts msg
              return nil, msg
            end
            a_ToRelated.key_and_rows[the_parent_old_pk] = old_rows - [row_number]
            if a_ToRelated.key_and_rows[the_parent_old_pk].size == 0
              a_ToRelated.key_and_rows.delete(the_parent_old_pk)
            end
            a_ToRelated.key_and_rows[the_parent_new_pk] << row_number
            #
            # Look into parent table
            #
            # Reduce the usage of old attribute value
            a_ToRelated.to_parent_obj.count_relatives_refs_into[the_parent_old_pk] -= 1
            # Increase the usage of olnewd attribute value
            a_ToRelated.to_parent_obj.count_relatives_refs_into[the_parent_new_pk] += 1
          end
        }
      else
        return nil, "Unknown colname '#{a_col_name}' in row"
      end
    }
    @the_rows[row_number] = new_row
    return self, "OK"
  end
end
