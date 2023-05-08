class Table
  # ========================================
  def insert_rows(in_colnames_array : Array(String), rows : Array(Array(String))) : {Nil | Table, String}
    rows.each { |a_row|
      # puts a_row
      new_row : Array(String) = [] of String
      @the_columns.each { |self_col_name|
        pos_in_data = in_colnames_array.index(self_col_name)
        if pos_in_data
          new_row << a_row[pos_in_data]
        else
          # STDERR.puts "@the_columns=#{@the_columns}"
          # STDERR.puts "in_colnames_array=#{in_colnames_array}"
          return nil, "Mandatory Colname '#{self_col_name}' missing in table '#{@name}'"
        end
      }
      # Ensure no duplicate on primary key
      #
      # STDERR.puts @the_col_index_pk
      new_pk : PkValue = @the_col_index_pk.map { |i| new_row[i] }
      if @the_pks.has_key?(new_pk)
        pp @the_pks.keys
        return nil, "Duplicate entry for key '#{new_pk}' in '#{@name}'"
      end
      #
      # Do we have any related attribute
      #
      @the_related_columns.each { |a_ToRelated|
        # Pick colvalues for this relat
        # Lock up in related table. Key must exist
        the_col_value_as_parent_key : PkValue = a_ToRelated.from_columns_in_own_row.map { |c| new_row[c] }
        #
        # Optional ?
        # TDO !!!

        pk_exists = a_ToRelated.to_parent_obj.the_pks.fetch(the_col_value_as_parent_key, nil)
        if pk_exists.nil?
          pp a_ToRelated.to_parent_obj.the_pks.keys
          pp a_ToRelated.to_parent_obj
          msg = "Related key '#{the_col_value_as_parent_key}' for '#{a_ToRelated.col_names}' does not exists"
          STDERR.puts msg
          return nil, msg
        end

        old_rows = a_ToRelated.key_and_rows.fetch(the_col_value_as_parent_key, nil)
        if old_rows.nil?
          a_ToRelated.key_and_rows[the_col_value_as_parent_key] = [@the_lastused_rowid + 1]
        else
          a_ToRelated.key_and_rows[the_col_value_as_parent_key] << @the_lastused_rowid + 1
        end
        a_ToRelated.row_and_key[@the_lastused_rowid + 1] = the_col_value_as_parent_key
        #
        # Also tell a_ToRelated table that it's refeenced.
        # In case of try delete a_ToRelated[key] the reference count must be zero!
        #
        old_refs = a_ToRelated.to_parent_obj.count_relatives_refs_into.fetch(the_col_value_as_parent_key, nil)
        if old_refs.nil?
          a_ToRelated.to_parent_obj.count_relatives_refs_into[the_col_value_as_parent_key] = 1
        else
          a_ToRelated.to_parent_obj.count_relatives_refs_into[the_col_value_as_parent_key] += 1
        end
      }
      #
      # CHECK FOREIGN KEYS ON PRIMARY KEY
      if @kind == TableType::Relation
        # ensure each parent key exists
        # pp the_parents
        @the_parents.each { |a_ToParentIndex|
          # pp a_ToParentIndex
          parent_pk : PkValue = a_ToParentIndex.from_columns_in_pk.map { |i| new_row[i] }
          the_parent_obj = a_ToParentIndex.to_parent_obj

          if the_parent_obj.the_pks.has_key?(parent_pk)
            # OK Parent exists
            # Update own
            a_ToParentIndex.row_and_key[@the_lastused_rowid + 1] = parent_pk
            res_old_ColValueNumber = a_ToParentIndex.key_and_rows.fetch(parent_pk, nil)
            if old_ColValueNumber = res_old_ColValueNumber
              # This part of pk is not new
              a_ToParentIndex.key_and_rows[parent_pk] << @the_lastused_rowid + 1
            else
              a_ToParentIndex.key_and_rows[parent_pk] = [@the_lastused_rowid + 1]
            end
          else
            pp the_parent_obj.the_pks.keys
            return nil, "Parent key '#{parent_pk}' not found from '#{@name}' to '#{the_parent_obj.name}' "
          end
        }
      end
      @the_lastused_rowid += 1
      @the_pks[new_pk] = @the_lastused_rowid
      @the_rows[@the_lastused_rowid] = new_row
    }
    return self, "#{rows.size} rows inserted into table '#{@name}'"
  end
end
