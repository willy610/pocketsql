# require "./examples/loaddbdef"
# require "./examples/loaddbdeffromjson"

require "json"
require "csv"
require "../dbschema"
require "./tableinsert"

module LoadAnyThing
  class TheRoot
    include JSON::Serializable
    property rot : String?
    property tables : Array(TablesToLoad) = [] of TablesToLoad

    def initialize
    end
  end

  class TablesToLoad
    include JSON::Serializable
    property tablenam : String = ""
    property columns : Array(String) = [] of String
    property data_file_name : String = ""
    property dont_load_this : String?

    def initialize
    end
  end

  def self.go(schema_name : String, load_data_info : String, do_load_data_info : Bool) : DBSchema

    a_DBSchema = DBSchema.from_json(File.read(schema_name))
    a_DBSchema.set_up_related_objs
    the_rot = TheRoot.from_json(File.read(load_data_info))
    the_rot.tables.each { |json_tbl|
      if json_tbl.dont_load_this.nil?
        res, msg = a_DBSchema.find_table_by_name(json_tbl.tablenam)
        if res.nil?
          raise msg
        end
        file = File.new(json_tbl.data_file_name)
        csv = CSV.parse(file)
        # puts "!" + __FILE__ + ":" + __LINE__.to_s
        res, txt = res.insert_rows(in_colnames_array: json_tbl.columns, rows: csv)
        if res.nil?
          puts txt
        end
        # puts res
      else
        STDERR.puts "DONT LOAD table '#{json_tbl.tablenam}'"
      end
    }
    return a_DBSchema
  end
end
