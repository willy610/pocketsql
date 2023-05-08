require "./clargs"
require "./parsecreate"
require "./parsecreateextended"
require "./compilecreate"
require "./gencreateanddbdef"
require "../pocketlib/parse"
require "../pocketlib/compile/stepper"
require "../pocketlib/dbschema"

#
#  ./bin/dbschema2X -s ./src/dbschema2X/examples/create/recipe.schema  -c ./src/dbschema2X/examples/createsql/dbrecipe.sql 
#  ./bin/dbschema2X -s ./src/dbschema2X/examples/create/recipe.schema  -d ./src/dbschema2X/examples/geneddbdef/dbrecipe.json

# ./bin/dbschema2X -s ./src/docextractor/data/dbdef.schema  -d ./src/docextractor/data/dbdef.json
#
module DBSchema2X
  command_line_args = get_args()
  if command_line_args[:sqldefsource].size > 0
    source = File.read(command_line_args[:sqldefsource])
    parse_create = Parse.new
    #
    # Read the create table definition
    #
    as_ASBranch : (TopAbsSyntTreeObj | Nil) = parse_create.parseCreate(source)
    #
    code = CompileCreate.new
    a_Rot : Rot = code.r_Createtable(as_ASBranch.data[0])
    a_Rot.prepare

    if command_line_args[:createsqltable].size > 0
      #
      # Generate trad sql create -c
      #
      exp_create : String = a_Rot.export_create_sql(command_line_args[:tablesuffix]).flatten.join('\n')
      File.write(command_line_args[:createsqltable], exp_create)
    end
    if command_line_args[:dbschema].size > 0
      #
      # Generate dbschem -d
      #
      a_schema : DBSchema = a_Rot.create_dbschema
      File.write(command_line_args[:dbschema], a_schema.to_json)
    end
  end
end
