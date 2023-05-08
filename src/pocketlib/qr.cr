# https://forum.crystal-lang.org/t/creeating-struct-from-json/3492/
# https://forum.crystal-lang.org/t/creeating-struct-from-json/3492
# https://stackoverflow.com/questions/62852621/is-there-a-way-to-see-what-a-crystal-macro-expands-to
require "json"

# Don't use any unions '|' for properties as they can't be restored from_json
module QR
  class TopInQr
    include JSON::Serializable
    property the_CRUD : QRCUD?
    property the_Query : Query?

    def initialize(the_CRUD : QRCUD)
      @the_CRUD = the_CRUD
    end

    def initialize(the_Query : Query)
      @the_Query = the_Query
    end
  end

  class Query
    include JSON::Serializable
    property tag : String = "Query"
    property cte_plain : Array(QrPlainCTE) = [] of QrPlainCTE
    property cte_recur : Array(QRWithRecur) = [] of QRWithRecur
    property subq : SubQuery?
    property orderby : Array(QROrderBy)?
    property limit : QRLimit?
    property show_table : QShow?
    # property show_tables : QShow?

    def initialize
    end
  end

  class QShow
    include JSON::Serializable
    property  one_table : String =""
    property  all_tables : Bool = false
    def initialize
    end
  end
  class QRCUD
    include JSON::Serializable
    property tag : String = "QRCUD"
    property destination_QrLoadFileFile : QR::QrLoadFileFile?
    property destination_string : String?
    # property destination : QR::QrLoadFileFile | String?
    # property kind : QInsert | QUpdate | QDelete?
    property kind_QInsert : QInsert?
    property kind_QUpdate : QUpdate?
    property kind_QDelete : QDelete?

    def initialize
    end
  end

  class QInsert
    include JSON::Serializable
    property tag : String = "QInsert"
    property into_columns : Array(String) = [] of String
    property subq : SubQuery?
    property values : QR::QRLoadFileValues?

    def initialize
    end
  end

  class QDelete
    include JSON::Serializable
    property tag : String = "QDelete"
    property whereexpr : QRWhere?

    def initialize
    end
  end

  class QUpdate
    include JSON::Serializable
    property tag : String = "QUpdate"
    property whereexpr : QRWhere?
    property settings : Array(QUpdateValue) = [] of QUpdateValue

    def initialize
    end
  end

  class QFrom
    include JSON::Serializable
    property from_QRLoadFileValues : QR::QRLoadFileValues?
    property from_QRLoadFromStore : QR::QRLoadFromStore?
    property from_QrLoadFileFile : QR::QrLoadFileFile?
    property from_QRFirstJoin : QR::QRFirstJoin?
    # property from_QRLoadFileValues : QR::QRLoadFileValues?
    property from_SubQuery : QR::SubQuery?

    def initialize
    end
  end

  class QUpdateValue
    include JSON::Serializable
    property colname : String
    property assign_value : QRScalarExpr

    def initialize(@colname, @assign_value)
    end
  end

  # alias ScalarItem = QR::QRScalarExpr | QR::QRLoadColnameValueOntoStack | QR::QRLoadStringValueOntoStack | QR::QRLoadNumberValueOntoStack | QR::SubQuery | QR::QRProjectItem

  class QRScalarItem
    include JSON::Serializable
    property item_QRScalarExpr : QR::QRScalarExpr?
    property item_QRLoadColnameValueOntoStack : QR::QRLoadColnameValueOntoStack?
    property item_QRLoadStringValueOntoStack : QR::QRLoadStringValueOntoStack?
    property item_QRLoadNumberValueOntoStack : QR::QRLoadNumberValueOntoStack?
    property item_SubQuery : QR::SubQuery?
    property item_QRProjectItem : QR::QRProjectItem?
    property item_QRLoadParamNameOnStack : QR::QRLoadParamNameOnStack?
    property item_QRLoadFileValues : QR::QRLoadFileValues?

    def initialize
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
      if the_item = @item_QRScalarExpr
        the_item.collect_aggr_funcs(collection)
      elsif the_item = @item_SubQuery
        the_item.collect_aggr_funcs(collection)
      elsif the_item = @item_QRProjectItem
        the_item.collect_aggr_funcs(collection)
      else
        # pp self
        # raise "collect_aggr_funcs() odd item '#{self}'"
      end
    end
  end

  class QRScalarExpr
    include JSON::Serializable
    property tag_QRScalarExpr : String = "QRScalarExpr"
    # property first_scalar : ScalarItem
    property first_scalar : QRScalarItem
    property more_scalars : Array(QRMoreScalarExpr) = [] of QRMoreScalarExpr

    def initialize(@first_scalar)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
      @first_scalar.collect_aggr_funcs(collection)
      @more_scalars.each { |a_QRMoreScalarExpr|
        a_QRMoreScalarExpr.collect_aggr_funcs(collection)
      }
    end
  end

  class QRMoreScalarExpr
    include JSON::Serializable
    property tag : String = "QRMoreScalarExpr"
    # property the_scalar : ScalarItem
    property the_scalar : QRScalarItem
    property the_oper : QRDualScalarOperation

    def initialize(@the_scalar, @the_oper)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
      the_scalar.collect_aggr_funcs(collection)
    end
  end

  class QRWhere
    include JSON::Serializable
    property tag : String = "QRWhere"
    property first_cond_expr : QROneCondExpr?
    property more_cond_expr : Array(QRMoreCondExpr) = [] of QRMoreCondExpr

    def initialize
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
      if try_first_cond_expr = @first_cond_expr
        try_first_cond_expr.collect_aggr_funcs(collection)
      end
    end
  end

  class QRProjectOver
    include JSON::Serializable
    property tag : String = "QRProjectOver"
    property window_name : String = ""
    property order_by : Array(QROrderBy)?

    def initialize
    end
  end

  class QRWindow
    include JSON::Serializable
    property tag : String = "QRWindow"
    property name : String = ""
    property partitionby : Array(QRPartitionBy)?
    property orderby : Array(QROrderBy)?

    def initialize
    end
  end

  class QROneCondExpr
    include JSON::Serializable
    property tag : String = "QROneCondExpr"
    property oper : QR::QRDualCompareOperation?
    # property left_scalaritem : Array(ScalarItem) = [] of ScalarItem
    # property right_scalaritem : Array(ScalarItem) = [] of ScalarItem
    property left_scalaritem : QRScalarExpr
    property right_scalaritem : QRScalarExpr
    property

    def initialize(@oper, @left_scalaritem, @right_scalaritem)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
      # @left_scalaritem.each { |c| c.collect_aggr_funcs(collection) }
      # @right_scalaritem.each { |c| c.collect_aggr_funcs(collection) }
      @left_scalaritem.collect_aggr_funcs(collection)
      @right_scalaritem.collect_aggr_funcs(collection)
    end
  end

  class QRMoreCondExpr
    include JSON::Serializable
    property more : QR::QROneCondExpr?
    property and_or_or : String?

    def initialize
    end
  end

  class SubQuery
    include JSON::Serializable
    property tag_SubQuery : String = "SubQuery"
    property distinct : Bool = false
    # alias LoadData = QR::QRLoadFileValues | QR::QRLoadFromStore | QR::QrLoadFileFile | QR::QRFirstJoin

    # property from : QR::SubQuery | LoadData?
    property the_from : QFrom
    property whereexpr : QRWhere?
    property window : QRWindow?
    property groupby : Array(QRGroupBy)?
    property aggr_funcs_in_project : Array(AggrFuncInCol)?
    property having : QRWhere?
    property project : QRProject?
    property derived_as : QRASTableCols?

    def initialize(@the_from, @project)
      @whereexpr = nil
    end

    # def initialize(@the_from)
    #   @whereexpr = nil
    # end

    # def initialize
    # end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
    end

    def dump
      return "from=#{@from}
where=#{@where}
project=#{@project}"
    end
  end

  class QRASTableCols
    include JSON::Serializable
    property tag : String = "QRASTableCols"
    property as_tablename : String
    property as_colnames : Array(String)

    def initialize(@as_tablename, @as_colnames)
    end
  end

  class QRFirstJoin
    include JSON::Serializable
    property tag : String = "QRFirstJoin"
    property join_cover : String = ""
    # property first_from : QR::SubQuery | LoadData
    # property first_from : QR::SubQuery | LoadData
    property first_from : QFrom
    property more_from : Array(QRMoreJoin) = [] of QRMoreJoin

    def initialize(@first_from)
    end
  end

  class QRMoreJoin
    include JSON::Serializable
    property tag : String = "QRMoreJoin"
    property join_cover : String = ""
    property join_on : QRWhere?
    # property from : QR::SubQuery | LoadData?
    property from : QFrom
    property

    # def initialize
    # end
    def initialize(@from)
    end
  end

  class QrPlainCTE
    include JSON::Serializable
    property tag : String = "QrPlainCTE"
    property filename : String
    property colnames : Array(String)
    property instructions : QR::SubQuery

    def initialize(@filename, @colnames, @instructions)
    end
  end

  class QRWithRecur
    include JSON::Serializable
    property tag : String = "QRWithRecur"
    property first : QR::SubQuery?
    property second : QR::SubQuery?
    property cte_tablename : String

    def initialize(@cte_tablename, @first, @second)
    end
  end

  class QrLoadFileFile
    include JSON::Serializable
    property tag : String = "QrLoadFileFile"
    property loadfilename : String
    property filename : String
    property colnames : Array(String)

    # property indexname : String

    # def initialize(@loadfilename, @filename, @colnames, @indexname)
    def initialize(@loadfilename, @filename, @colnames)
    end
  end

  class QRLoadFileValues
    include JSON::Serializable
    property tag_QRLoadFileValues : String = "QRLoadFileValues"
    property filename : String
    property colnames : Array(String)
    property rows : Array(Array(String))

    def initialize(@filename, @colnames, @rows)
    end
  end

  class QRLoadFromStore
    include JSON::Serializable
    property tag_QRLoadFromStore : String = "QRLoadFromStore"
    property tablename : String
    property as_tablename : String
    property as_colnames : Array(String)

    def initialize(@tablename, @as_tablename, @as_colnames)
    end
  end

  class QRLoadColnameValueOntoStack
    include JSON::Serializable
    property tag_QRLoadColnameValueOntoStack : String = "QRLoadColnameValueOntoStack"
    property tablename : String
    property colname : String
    property cached_table_indx : Int32?
    property cached_column_indx : Int32?

    def initialize(@tablename, @colname)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
    end
  end

  class QRLoadParamNameOnStack
    include JSON::Serializable
    property tag_QRLoadParamNameOnStack : String = "QRLoadParamNameOnStack"
    property paramname : String

    def initialize(@paramname)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
    end
  end

  class QRLoadNumberValueOntoStack
    include JSON::Serializable
    property tag_QRLoadNumberValueOntoStack : String = "QRLoadNumberValueOntoStack"
    property value : String

    def initialize(@value)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
    end

    def initialize(*, pull : JSON::PullParser)
      puts "YYYY"
      @value = ""
      @tag_QRLoadNumberValueOntoStack = "QRLoadNumberValueOntoStack"
      pull.read_object do |key|
        case key
        when "value"
          @value = pull.read_object
        when "tag_QRLoadStringValueOntoStack"
          @tag_QRLoadNumberValueOntoStack = pull.read_object
        end
      end
    end
  end

  class QRLoadStringValueOntoStack
    include JSON::Serializable
    property tag_QRLoadStringValueOntoStack : String = "QRLoadStringValueOntoStack"
    property value : String

    def initialize(@value)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
    end
  end

  class QRDualScalarOperation
    include JSON::Serializable
    property tag : String = "QRDualScalarOperation"
    property value : String

    def initialize(@value)
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
    end
  end

  class QRDualCompareOperation
    include JSON::Serializable
    property tag : String = "QRDualCompareOperation"
    property value : String

    def initialize(@value)
    end
  end

  class QRProjectItem
    include JSON::Serializable
    property tag_QRProjectItem : String = "QRProjectItem"
    property kind : QRProjectItemKind
    property look_up_tablename : String        # find from 'from' SELECT TABLE.'
    property look_up_colname : String          # find from 'from' SELECT TABLE.COL'
    property as_colname : String               # SELCT ? AS name
    property literalvalue : String = ""        # SELECT 'some string'
    property generated_aggr_name : String = "" # table.col_func
    property subq : QR::SubQuery?
    # property scalarexp : Array(ScalarItem)?
    property scalarexp : QRScalarExpr?
    property aggrfunction : AggregateFunctionEnum?
    property columnfunction : StandardFunctionEnum?
    property over_window : QRProjectOver?

    def initialize(@look_up_tablename, @look_up_colname, @kind)
      @as_colname = @look_up_colname
    end

    def collect_aggr_funcs(collection : Array(AggrFuncInUse))
      if @aggrfunction.is_a?(AggregateFunctionEnum)
        collection << {look_up_table:       @look_up_tablename,
                       look_up_colname:     @look_up_colname,
                       func:                @aggrfunction,
                       generated_aggr_name: @generated_aggr_name,
                       as_colname:          @as_colname}
      elsif @scalarexp.is_a?(QR::QRScalarExpr)
        if try_scalarexp = @scalarexp
          try_scalarexp.collect_aggr_funcs(collection)
        else
        end
      end
    end
  end

  class QRProject
    include JSON::Serializable
    property tag : String = "QRProject"
    property astablename : String = "NOASTABLENAME"
    property columns : Array(QRProjectItem) = [] of QRProjectItem

    def initialize
    end
  end

  class QRGroupBy
    include JSON::Serializable
    property table : String?
    property column : String?

    def initialize(@table, @column)
    end

    def initialize
    end
  end

  class QRPartitionBy
    include JSON::Serializable
    property table : String?
    property column : String?

    def initialize(@table, @column)
    end

    def initialize
    end
  end

  class QROrderBy
    include JSON::Serializable
    property column_number : Int32?
    property column_name : String?
    property ordering : String?

    def initialize
    end
  end

  class QRLimit
    include JSON::Serializable
    property offset : String = "0"
    property row_count : String = ""

    def initialize
    end
  end
end
