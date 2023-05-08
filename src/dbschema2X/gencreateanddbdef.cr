require "./gencreatesql"
require "./gendbschema"

alias ParentPKAttribs = {col_name: String, sql_attr: String | Nil}
alias FKDef = {from_table: String, from_prefix: String, to_table: String}
alias FKGened = {pk_dcl: Array(String), fk_def: String, fk_index: String, all_pks: Array(String)}

class Rot
  property rot : String?
  property tables : Array(BasTableCreate) = [] of BasTableCreate
  property topoplogical_sort : Array(String) = [] of String
  property table_with_parents : Hash(String, Array(String)) = Hash(String, Array(String)).new
  property name_to_table : Hash(String, BasTableCreate) = Hash(String, BasTableCreate).new

  def initialize
  end

  # ************************************************************************

  def prepare
    # 1. Sort toplogical
    # 2. Calculate all pk details on each table
    # 3. Calculate all reltive columns and all ordinary columns
    #
    @tables.each { |json_tbl|
      case json_tbl.kind
      when "entity"
        a_table = json_tbl.tablename
        @name_to_table[a_table] = json_tbl
        @table_with_parents[a_table] = [] of String
      when "relationship"
        a_table = json_tbl.tablename
        @name_to_table[a_table] = json_tbl
        @table_with_parents[a_table] = [] of String
        json_tbl.relat.parent_tables.each { |a_ParentCreate|
          @table_with_parents[a_table] << a_ParentCreate.parent_table_name
          a_ParentCreate.parent_table_obj = @name_to_table[a_ParentCreate.parent_table_name]
        }
      end
      json_tbl.related_attributes.each { |a_RaletedColumnCreate|
        @table_with_parents[a_table] << a_RaletedColumnCreate.parent_table_name
      }
    }
    # Now walk all table_with_parents pick if it has no parent
    # Remove from all the found parent. Thsi will give one order where all tables are known
    # Detect cyclces

    maxloop = @table_with_parents.size
    loop do
      tables_have_no_parent = @table_with_parents.select { |from_table, its_parents|
        its_parents.size == 0
      }.map { |from_table, its_parents| from_table }
      if tables_have_no_parent.size == 0
        raise "Cycle on primary keys. Or what. Remaining tables=#{@table_with_parents} "
      end

      table_has_no_parent = tables_have_no_parent.first
      # Remove in the dependences
      @table_with_parents.each { |from_table, its_parents|
        @table_with_parents[from_table] = its_parents - [table_has_no_parent]
      }
      @topoplogical_sort << table_has_no_parent
      @table_with_parents.delete(table_has_no_parent)
      maxloop -= 1
      if maxloop <= 0
        break
      end
    end
    # STDERR.puts "topoplogical_sort#{@topoplogical_sort}"
  end
end

# ************************************************************************

class BasTableCreate
  property kind : String # entity or relationship
  property tablename : String = ""
  property entity : EntityTableCreate = EntityTableCreate.new
  property relat : RelatTableCreate = RelatTableCreate.new
  property related_attributes : Array(FKCreate) = [] of FKCreate
  property plain_attributes : Array(PlainColumnCreate) = [] of PlainColumnCreate

  def initialize
    @kind = "UNKNOWN (entity | relationship)"
  end

  def get_pk
    if @kind == "entity"
      # NOP
      [@entity.pk]
    else
      @relat.get_pk
    end
  end

  def collect_pk
    if @kind == "entity"
      # NOP
      puts "has value #{[@entity.pk]}"
    else
      @relat.collect_pk
    end
  end
end

class EntityTableCreate
  property pk : ParentPKAttribs = {col_name: "", sql_attr: ""}

  def initialize
  end
end

class RelatTableCreate
  property parent_tables : Array(FKCreate) = [] of FKCreate
  property own_primary : Array(ParentPKAttribs) = [] of ParentPKAttribs
  property pk : Array(ParentPKAttribs) = [] of ParentPKAttribs

  def initialize
  end

  def get_pk : Array(ParentPKAttribs)
    @pk
  end

  def collect_pk
    @pk =
      [
        @parent_tables.map { |a_FKCreate|
          a_FKCreate.collect_fk
        },
        own_primary.map { |p| p },
      ].flatten
  end
end

class FKCreate
  property parent_table_name : String = ""
  property parent_table_obj : BasTableCreate = BasTableCreate.new
  property prefix : String = ""
  property collected_fk : Array(ParentPKAttribs) = [] of ParentPKAttribs

  def initialize
  end

  def collect_fk
    @collected_fk = @parent_table_obj.get_pk.map { |a_ParentPKAttribs|
      {
        col_name: @prefix + a_ParentPKAttribs[:col_name],
        sql_attr: a_ParentPKAttribs[:sql_attr],
      }
    }
    @collected_fk
  end
end

class PlainColumnCreate
  property col_name : String = "NONAME"
  property is_optional : String?
  property default_value : String?
  property is_ordererd : String?
  property is_indexed : String?
  property is_unique : String?
  property sql_attributes : String = ""

  def initialize
  end
end
