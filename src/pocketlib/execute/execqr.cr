alias OnStack = ResultSet | LiteralValue | NumericValue | ConditionResult | ParamName
alias TableRow = Array(String)
alias ResultRow = Array(TableRow)

alias ScalarItem = QR::QRScalarExpr | QR::QRLoadColnameValueOntoStack | QR::QRLoadStringValueOntoStack | QR::QRLoadNumberValueOntoStack | QR::SubQuery | QR::QRProjectItem

alias AggrFuncInCol = {look_up_table: String, look_up_colname: String, func: AggregateFunctionEnum | Nil, generated_aggr_name: String, as_colname: String}



enum QRProjectItemKind
  PString
  PSelect
  PSubq
  PWild
  PTblWild
  PNOTYET
  PTblCol
  PStandardFunctionEnum
  PAggregateFunctionEnum
  PScalarExpression
end
enum AggregateFunctionEnum
  AVG
  MIN
  MAX
  SUM
  COUNT
  STDDEV
end
enum StandardFunctionEnum
  TOUPPER
  TOLOWER
end

require "../qr"
require "./execqrqr"
require "./execqrdel"
require "./execqrins"
require "./execqrupd"
require "./onstack"
require "./outerrow"
require "./execwhere"
require "./execjoin"
require "./execgroupby"
require "./execwindow"
require "./execprojectfromwindow"
require "./execproject"
require "./execshowtable"
require "./cteandderived"
require "./resultset"
require "json"

class ParamIn
  include JSON::Serializable
  property paramname : String
  property value : String

  def initialize(@paramname, @value)
  end
end

class AllParams
  include JSON::Serializable
  property the_params : Array(ParamIn) = [] of ParamIn

  def initialize
  end
end

class ExecuteQr
  @@stack : Stack = Stack.new
  @@params : AllParams = AllParams.new
  @db : DBSchema = DBSchema.new

  def self.path_csv
    @@path_csv
  end

  def initialize(@db)
  end

  def self.stack
    @@stack
  end

  def self.params
    @@params
  end

  def self.params=(val)
    @@params = val
  end

  # =================================================

  def go(qr : QR::TopInQr)
    if that_Query = qr.the_Query
      # Select
      qrqr(that_Query)

      # # http://binaryworld.net/blogs/sql-parent-child-query-example-recursive-cte-hierarchy//
      # # https://learnsql.com/blog/sql-recursive-cte/
      # # https://builtin.com/data-science/recursive-sql

    elsif that_QRCUD = qr.the_CRUD
      # Create(Insert), Update, Delete
      # Destination (INTO...)
      if try_destination_QrLoadFileFile = that_QRCUD.destination_QrLoadFileFile
        the_table = @db.add_csv_table(try_destination_QrLoadFileFile.loadfilename,
          try_destination_QrLoadFileFile.colnames,
          try_destination_QrLoadFileFile.filename)
        try_into_table_obj = @db.find_table_obj(try_destination_QrLoadFileFile.filename)
      elsif try_destination_string = that_QRCUD.destination_string
        try_into_table_obj = @db.find_table_obj(try_destination_string)
      else
        pp that_QRCUD.destination_QrLoadFileFile
        pp that_QRCUD.destination_string
        raise "qrins() Unknown into '#{that_QRCUD.destination_QrLoadFileFile}' or #{that_QRCUD.destination_string}"
      end
      if into_table_obj = try_into_table_obj
        if try_qr_kind = that_QRCUD.kind_QInsert
          qrins(try_qr_kind, into_table_obj)
          return nil
        elsif try_qr_kind = that_QRCUD.kind_QDelete
          qrdel(try_qr_kind, into_table_obj)
          return nil
        elsif try_qr_kind = that_QRCUD.kind_QUpdate
          qrupd(try_qr_kind, into_table_obj)
          return nil
        end
      end
    else
      raise "go() WHAT '#{typeof(qr)}' "
    end
  end

  # =============================================================================================================
  def subqr(sqr : QR::SubQuery, outer_row : Array(OuterRow))
    the_proj = sqr.project
    if !the_proj
      puts "MISSING project"
      raise "MISSING project"
    end
    # if the_from = sqr.from
    the_QFrom = sqr.the_from
    #
    # FROM
    #
    # -------------------------------------------------------------------
    if try_the_QFrom = the_QFrom.from_QRFirstJoin
      #
      # Build with join
      #
      the_iter = join_it(outer_row, try_the_QFrom, sqr.whereexpr)
    else
      #
      # Build without join
      #
      the_iter = get_an_iter(the_QFrom)[:the_result_set]
    end
    #
    # -------------------------------------------------------------------
    # FROM DONE
    having_where : Bool = false
    having_groupby : Bool = false
    having_window : Bool = false
    # join
    #
    having_join = !the_QFrom.from_QRFirstJoin.nil?
    # where
    #
    if sqr.whereexpr.nil?
      having_where = false
    else
      having_where = true
    end
    # window
    #
    if sqr.window.nil?
      having_window = false
    else
      having_window = true
    end
    # group by
    #
    if sqr.groupby.nil?
      having_groupby = false
    else
      having_groupby = true
    end
    # having
    #
    if sqr.having.nil?
      having_having = false
    else
      having_having = true
    end

    if sqr.aggr_funcs_in_project.nil?
      have_aggr_funcs_in_project = false
    else
      have_aggr_funcs_in_project = true
    end

    if having_window
      # FIRST WINDOW (WITH preceedings WHERE)
      # Adjust all loookup colnames in the projection
      window_key_and_rows = exec_window(sqr, outer_row, the_iter)
      res_from_window = exec_project_from_window(sqr, the_iter, window_key_and_rows)
      final_res = exec_project(the_proj, outer_row, res_from_window, nil, nil, sqr.distinct)
    else
      if having_groupby || have_aggr_funcs_in_project
        # FIRST GROUP BY (WITH preceedings WHERE)
        resfrom_groupby = exec_groupby(sqr, the_iter)
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        # pp resfrom_groupby
        if having_having
          final_res = exec_project(the_proj, outer_row, resfrom_groupby, nil, sqr.having, sqr.distinct)
        else
          final_res = exec_project(the_proj, outer_row, resfrom_groupby, nil, nil, sqr.distinct)
        end
      else
        if having_where && !having_join
          final_res = exec_project(the_proj, outer_row, the_iter, sqr.whereexpr, nil, sqr.distinct)
        else
          final_res = exec_project(the_proj, outer_row, the_iter, nil, nil, sqr.distinct)
        end
      end
      #
    end
    return final_res
    # else
    #   raise "subqr() missing 'sqr.from' "
    # end
  end
end
