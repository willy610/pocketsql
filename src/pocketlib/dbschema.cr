require "json"
require "../pocketlib/execute/execqr"
require "../pocketlib/execute/tableupdate"
require "../pocketlib/execute/tabletypes"
require "../pocketlib/execute/resultset"

# This components holds
# 1. Table and content from a 'WITH' clause (derived)
# 2. Table and content from independent subqueries as derived table
# 3. Table and content from initial load anything
# 4. and of cource from running sql statemnets
#
class DBSchema
  include JSON::Serializable
  property tables : Array(Table) = [] of Table
  @[JSON::Field(key: "cte_and_derived_tables", ignore: true)]
  property cte_and_derived_tables : Array(ResultSet) = [] of ResultSet

  def initialize
  end

  def save_to_dir(dirpath : String)
    @tables.each { |a_Table|
      a_Table.save_to_dir(dirpath)
    }
    @cte_and_derived_tables.each { |a_Table|
      a_Table.save_to_dir(dirpath)
    }
  end

  # -------------------------
  private def eunsure_uniq(tablename)
    indx = @cte_and_derived_tables.map { |t| t.tablenames[0] }.index(tablename)
    if !indx.nil?
      raise "() Table '#{tablename}' already defined in 'cte_and_derived_tables"
    else
      indx = @tables.map { |t| t.name }.index(tablename)
      if !indx.nil?
        raise "() Table '#{tablename}' already defined in 'tables'"
      end
      return true
    end
  end

  # ---------------------------------------------
  def all_tables_as_result
    ret = ResultSet.new
    ret.tablenames += ["TABLES"]
    ret.colnames << ["Tablename"]
    ret.rows = @tables.map { |table_name| [[table_name.name]] }
    ret
  end

  # ---------------------------------------------
  def one_table_as_result(table_name : String)
    ret = ResultSet.new
    ret.tablenames += [table_name]
    ret.colnames << ["Columns"]
    a_table = find_table_obj(table_name)
    if a_table.is_a?(Table)
      # ret.rows += [[a_table.the_columns]]
      ret.rows = a_table.the_columns.map { |col_name| [[col_name]] }
    elsif a_table.is_a?(ResultSet)
      ret.rows += [a_table.colnames]
    else
      raise "one_table_as_result () Table '#{table_name}' not found"
    end
    ret
  end

  # ---------------------------------------------

  def add_cte_def(kind, tablename, comma_list)
    old_tbl = find_table(tablename)
    if old_tbl.nil?
      @cte_and_derived_tables << ResultSet.new([tablename], [comma_list])
      @cte_and_derived_tables.last
    else
      old_tbl
    end
    # end
  end

  # ---------------------------------------------
  def add_value_table(kind, tablename, comma_list, rows)
    old_tbl = find_table(tablename)
    if old_tbl.nil?
      @cte_and_derived_tables << ResultSet.new([tablename], [comma_list], rows.map { |r| [r] })
      @cte_and_derived_tables.last
    else
      old_tbl
    end
  end

  # ---------------------------------------------
  def add_result_set(rs)
    @cte_and_derived_tables << rs
    @cte_and_derived_tables.last
  end

  # ---------------------------------------------

  def find_table_obj(tbl_name : String)
    Table | ResultSet | Nil
    indx = @cte_and_derived_tables.map { |t| t.tablenames[0] }.index(tbl_name)
    if !indx.nil?
      return @cte_and_derived_tables[indx]
    else
      indx = @tables.map { |t| t.name }.index(tbl_name)
      if !indx.nil?
        return @tables[indx]
      else
        return nil
      end
    end
  end

  # ---------------------------------------------

  def find_table(tbl_name : String) : ResultSet | Nil
    indx = @cte_and_derived_tables.map { |t| t.tablenames[0] }.index(tbl_name)
    if !indx.nil?
      return @cte_and_derived_tables[indx]
    else
      indx = @tables.map { |t| t.name }.index(tbl_name)
      if !indx.nil?
        the_table = @tables[indx]
        return ResultSet.new([the_table.name], [the_table.the_columns],
          the_table.the_rows.map { |rowid, colvalues| [colvalues] })
      else
        return nil
      end
    end
  end

  # ---------------------------------------------
  def add_csv_table(loadfilename, colnames, filename) : ResultSet
    old_tbl = find_table(filename)
    if old_tbl.nil?
      the_file_path = loadfilename
      lines = File.read_lines(the_file_path)
      @cte_and_derived_tables << ResultSet.new([filename], [colnames], lines.map { |l| [l.split(',')] })
      @cte_and_derived_tables.last
    else
      old_tbl
    end
  end

  # All 'Table' attributes are known to its name only
  # Resolve 'Table' names to real Table instance at start time
  # ---------------------------------------------------------------------------
  def set_up_related_objs
    @tables.each { |a_Table|
      a_Table.the_parents.each { |a_Parent|
        parent_table_obj, txx = find_table_by_name(a_Parent.to_parent_name)
        if !parent_table_obj
          raise "set_up_related_objs() 0 Parent table '#{a_Parent.to_parent_name}' not found"
        end
        a_Parent.to_parent_obj = parent_table_obj
      }
      a_Table.the_related_columns.each { |a_ToRelated|
        parent_table_obj, txx = find_table_by_name(a_ToRelated.to_parent_name)
        if !parent_table_obj
          raise "set_up_related_objs() 1 Parent table '#{a_ToRelated.to_parent_name}' not found"
        end
        a_ToRelated.to_parent_obj = parent_table_obj
      }
      # One must be aware of child with related attributes referening one
      a_Table.pk_child_tables_names.each { |a_TableName|
        from_table_obj, txx = find_table_by_name(a_TableName)
        if !from_table_obj
          raise "set_up_related_objs() 3 Parent table '#{a_TableName}' not found"
        end
        a_Table.pk_child_tables << from_table_obj
      }
    }
  end

  # ---------------------------------------------------------------------------

  def find_table_by_name(name : TblName)
    res = @tables.select { |tbl| tbl.name == name }
    if res.size == 1
      return res.first, "OK"
    else
      msg = "No such table '#{name}'"
      STDERR.puts msg
      return nil, msg
    end
  end
end

# ---------------------------------------------------------------------------

class Table
  include JSON::Serializable
  property name : String = "NONAME"
  property kind : TableType?
  property the_lastused_rowid : RowId = 0
  property the_columns : Array(ColName) = [] of ColName
  property the_pk_col_names : Array(ColName) = [] of ColName
  property index_own_pk : Array(Int32) = [] of Int32
  #
  property the_lastused_rowid : RowId = 0
  property the_col_index_pk : Array(Int32) = [] of Int32
  #
  # Rows are stored in 'the_rows'
  #
  @[JSON::Field(key: "the_rows", ignore: true)]
  property the_rows : Hash(RowId, Array(ColValue)) = Hash(RowId, Array(ColValue)).new
  #
  # Pk are in 'the_pks'
  #
  @[JSON::Field(key: "the_pks", ignore: true)]
  property the_pks : Hash(PkValue, RowId) = Hash(PkValue, RowId).new
  #
  # Here is one entry for each fk in the pk
  #
  property the_parents : Array(ToParent) = [] of ToParent
  #
  # Ordinary columns
  #
  property the_column_attributes : Array(ColumnAttribute) = [] of ColumnAttribute
  #
  # Columns which are related to other table
  #
  property the_related_columns : Array(ToRelated) = [] of ToRelated
  #
  #
  # We must keep track who is referencing us. At update, delete we must propagate the action
  # 'as pk through 'pk_child_tables'
  # 'as relat through 'relatives_childs'
  @[JSON::Field(key: "pk_child_tables", ignore: true)]
  property pk_child_tables : Array(Table) = [] of Table
  property pk_child_tables_names : Array(String) = [] of String

  property relatives_childs_tables_names : Array(ToRealtiveChild) = [] of ToRealtiveChild
  @[JSON::Field(key: "relatives_childs_tables", ignore: true)]
  property relatives_childs_tables : Array(ToRealtiveChildObject) = [] of ToRealtiveChildObject

  @[JSON::Field(key: "count_relatives_refs_into", ignore: true)]
  property count_relatives_refs_into : Hash(PkValue, Int32) = Hash(PkValue, Int32).new

  #
  # ----------------------------------------------
  def initialize
  end

  # ----------------------------------------------
  def save_to_dir(dirpath : String)
    the_file = File.new("#{dirpath}/#{@name}.csv","w")
    @the_rows.each { |_rowid, array_of_colvalue|
      the_file.puts(array_of_colvalue.join(","))
      # the_file.write_string(["ett","tva"].join(",").to_slice)
    }
    the_file.close
  end

  # ----------------------------------------------
  def to_s(io : IO)
    puts @name
    puts @the_columns.map { |c| c }.join(" | ")
    @the_rows.each { |rowid, cols|
      puts cols.map { |c| c }.join(" | ")
    }
  end

  # ----------------------------------------------
  def get_a_pk_iter
    the_rows.map { |a_rowId, a_ColValue| [a_ColValue] }
  end

  # ----------------------------------------------
  def get_an_OuterRow_template
    [OuterRow.new(name, the_columns, [] of String)]
  end

  # ----------------------------------------------
  def find_id_for_a_row(arow : OuterRow)
    indeces_in_row = xxx(arow)
    pk = indeces_in_row.map { |colindex_pk| arow.the_row[colindex_pk] }
    @the_pks[pk]
  end

  # ----------------------------------------------

  private def xxx(rows : OuterRow)
    indeces_in_row = the_pk_col_names.map { |a_PK_col_name|
      index_this_col = rows.colnames.index { |a_colname|
        a_colname == a_PK_col_name
      }
      if index_this_col.nil?
        raise "delete_rows() pk-colname 'a_PK_col_name' not found in row '#{rows.colnames}'"
      end
      index_this_col
    }
    indeces_in_row
  end

  # ----------------------------------------------
  def qr_update_row(id_row_to_delete, row : OuterRow, colname : String, new_value)
    colvals = @the_rows[id_row_to_delete]
    if @the_pk_col_names.index { |a_pk| colname == a_pk }
      update_pk_row(id_row_to_delete, [colname], [new_value])
      # puts "update pk-value"
    else
      # puts "update attribute"
      update_attributes(id_row_to_delete, [colname], [new_value])
    end
  end

  # ----------------------------------------------
  def qr_delete_rows(rows : Array(OuterRow))
    # Ensure all pk's are present in 'rows' to be deleted
    # Find index for columns rows to build a pk

    indeces_in_row = the_pk_col_names.map { |a_PK_col_name|
      index_this_col = rows[0].colnames.index { |a_colname|
        a_colname == a_PK_col_name
      }
      if index_this_col.nil?
        raise "delete_rows() pk-colname 'a_PK_col_name' not found in row '#{rows[0].colnames}'"
      end
      index_this_col
    }

    # puts indeces_in_row
    rows.each { |as_OuterRow|
      # pick pk values for this row
      pk = indeces_in_row.map { |colindex_pk| as_OuterRow.the_row[colindex_pk] }
      # new find id for row to delete
      row_id = @the_pks[pk]
      if !row_id.nil?
        # This the only entry for delete a row
        delete_rows(row_ids: [row_id])
      else
        raise "qr_delete_rows() row with pk '#{pk}' not found"
      end
    }
  end
end

# ---------------------------------------------------------------------------

class ToParent
  include JSON::Serializable
  property fk_name : String?
  property local_name : String?
  @[JSON::Field(key: "to_parent_obj", ignore: true)]
  property to_parent_obj : Table = Table.new
  property to_parent_name : String = ""
  property from_columns_in_pk : Array(Int32) = [] of Int32
  @[JSON::Field(key: "key_and_rows", ignore: true)]
  property key_and_rows : Hash(PkValue, Array(RowId)) = Hash(PkValue, Array(RowId)).new
  @[JSON::Field(key: "row_and_key", ignore: true)]
  property row_and_key : Hash(RowId, PkValue) = Hash(RowId, PkValue).new

  def initialize(@fk_name, @local_name, @to_parent_obj)
  end
end

# ---------------------------------------------------------------------------

class ColumnAttribute
  include JSON::Serializable
  property name : ColName
  property is_optional : Bool?
  property is_unique : Bool?
  property relative_entity : ToRelated?

  def initialize(@name, @is_optional, @is_unique, @relative_entity)
  end
end

# ---------------------------------------------------------------------------

class ToRelated
  include JSON::Serializable
  property col_names : Array(ColName) = [] of ColName
  property to_parent_name : String = ""
  @[JSON::Field(key: "to_parent_obj", ignore: true)]
  property to_parent_obj : Table = Table.new
  property is_optional : Bool?
  property from_columns_in_own_row : Array(Int32) = [] of Int32
  @[JSON::Field(key: "key_and_rows", ignore: true)]
  property key_and_rows : Hash(PkValue, Array(RowId)) = Hash(PkValue, Array(RowId)).new
  @[JSON::Field(key: "row_and_key", ignore: true)]
  property row_and_key : Hash(RowId, PkValue) = Hash(RowId, PkValue).new

  def initialize(@to_parent_name)
  end
end
