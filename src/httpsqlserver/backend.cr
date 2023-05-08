# request {"request":"modules"}
# response {"response": "modules","names":["A","B","Kalle"]}
#
# request {"request":"module"}
# response {"response": "module","the_module_name":"XXX","names":["A","B","Kalle"]}
#
# request {"request":"classes"}
# response {"response": "classes","names":["A","B","Kalle"]}
#
# request {"request":"class"}
# response {"response": "class","the_class_name":"XXX","methods":["A","B","Kalle"]}

require "../pocketlib/execute/loadanything.cr"
require "../pocketlib/parse"
require "../pocketlib/parse/parsesqlextended"
require "../pocketlib/parse/parsequery"
require "../pocketlib/compile/compileast"
require "../pocketlib/qr"

class BackEnd
  property db : DBSchema

  def initialize
    @db = LoadAnyThing.go(schema_name: "./src/docextractor/data/dbdef.json",
      load_data_info: "./src/docextractor/data/loadfiles.json",
      do_load_data_info: true)
  end

  # ------------------------------------
  def go_exec_sql(sql_string, return_as_resultset = false)
    begin
      x = Parse.new.parseQuery(sql_string)
      if !x.nil?
        code = CompileAst.new(db).go(x.data[0])
        ExecuteQr.params = AllParams.new # empty
        result = ExecuteQr.new(db).go(code)
        if !result.nil?
          if return_as_resultset
            return ["OK", result]
          else
            return ["OK", result.projection_as_json]
          end
        end
      end
      return nil
    rescue exception
      puts exception
      return ["FAIL", exception]
    end
  end

  # ------------------------------------
  def go_exec_stored_procedure(code : QR::TopInQr, params : AllParams)
    begin
      ExecuteQr.params = params
      result = ExecuteQr.new(@db).go(code)
      if !result.nil?
        return ["OK", result.projection_as_json]
      else
        raise "go_exec_stored_procedure() failed"
      end
    rescue exception
      puts exception
      return ["FAIL", exception]
    end
  end

  # ------------------------------------
  def process_rqst(request)
    pp request
    case request["request"]
    when "modules"
      sql = "SELECT * FROM module ORDER BY 1;"
      res = go_exec_sql(sql)
      if !res.nil?
        if res[0] == "OK"
          return %[{"response": "modules",#{res[1]}}]
        else
          return %[{"response": "FAIL"}]
        end
      else
        return %[{"response": "FAIL"}]
      end
    when "module"
      the_module_name = request["module"]
      return %[{"response": "module","the_module_name":"#{the_module_name}",
      "names":["Alias","Enums","Classes","Structs","..."]}]
    when "classes"
      sql = "SELECT * FROM class ORDER BY 1;"
      res = go_exec_sql(sql)
      if !res.nil?
        if res[0] == "OK"
          return %[{"response": "classes",#{res[1]}}]
        else
          return %[{"response": "FAIL"}]
        end
      else
        return %[{"response": "FAIL"}]
      end
    when "class"
      the_class_name = request["class"]
      sql = "SELECT classmethod.method  FROM classmethod WHERE classmethod.class = '#{the_class_name}';"
      res = go_exec_sql(sql)
      #
      # sql = "SELECT modulesource.module FROM modulesource WHERE modulesource.filename = '#{the_source_name}';"
      # if true
      #   # Try a precompiled version of above 'sql'
      #   a_TopInQr = QR::TopInQr.from_json(File.read("./src/docextractor/data/modsinsor_code.json"))
      #   the_params = %({"the_params": [{"paramname":"filenam","value":"'src//g.cr'"}] })
      #   params = AllParams.from_json(the_params)
      #   res = go_exec_stored_procedure(a_TopInQr, params)
      # else
      #   the_source_name = request["source"]
      #   # Or Compile and execute the 'sql'
      #   sql = "SELECT modulesource.module FROM modulesource WHERE modulesource.filename = '#{the_source_name}';"
      #   res = go_exec_sql(sql)
      # end
      #
      if !res.nil?
        if res[0] == "OK"
          return %[{"response": "class","the_class_name":"#{the_class_name}",#{res[1]}}]
        else
          return %[{"response": "FAIL"}]
        end
      else
        return %[{"response": "FAIL"}]
      end
    when "query"
      sql = request["stm"].to_s
      res = go_exec_sql(sql, true)
      if !res.nil?
        if res[0] == "OK"
          resett = res[1]
          if resett.is_a?(ResultSet)
            return %[{"response":"query","as_code":"#{res[1].to_s}"}]
          else
            return %[{"response": "FAIL"}]
          end
        else
          puts res[1]
          return %[{"response": "FAIL","as_code":"#{res[1]}"}]
        end
      else
        return %[{"response": "FAIL"}]
      end
    else
      puts "do_another_thing"
      return %[{"response": "failed"}]
    end
  end
end
