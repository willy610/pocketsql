require "../verifyschema/verify"
require "../pocketlib/parse"
require "../pocketlib/parse/parsesqlextended"
require "../pocketlib/parse/parsequery"
require "../pocketlib/compile/compileast"

class VerifyBrowser < Verify
  def self.verify(db : DBSchema)
    puts "verify"
    sql = [
      "SELECT *
        FROM module ;",

      "SELECT *
        FROM class ;",

      "SELECT *
        FROM method ;",

      "SELECT *
        FROM modulemethod ;",

      "SELECT classmethod.method, classmethod.class,   classmethod.TBD
        FROM classmethod ORDER BY 1,2 ;",

    ]

    sql.each { |sql|
      x = Parse.new.parseQuery(sql)
      if !x.nil?
        puts sql
        code = CompileAst.new(db).go(x.data[0])
        # puts code.to_json
        # result = ExecuteQr.new(db).go(code.data)
        result = ExecuteQr.new(db).go(code)
        if !result.nil?
          puts result.to_s
        end
      end
    }
    return self, "OK"
  end

  # ////////////////////////////////////////////
end
