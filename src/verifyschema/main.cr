require "./clargs"
require "./verify"
require "./verifyrecipe"
require "../docextractor/verifybrowser"
require "../pocketlib/execute/loadanything.cr"

# ./bin/verifyschema -s recipe | browse

module Verifyschema
  alias SchemaInfo = {schema_name: String, load_data_info: String, do_load_data_info: Bool, verify: Verify.class}
  allt : Hash(String, SchemaInfo) = Hash(String, SchemaInfo).new
  allt["recipe"] = {schema_name:       "./src/verifyschema/examples/recipe/dbrecept.json",
                    load_data_info:    "./src/verifyschema/examples/recipe/loadfiles.json",
                    do_load_data_info: true,
                    verify:            VerifyRecipe,
  }
  allt["browse"]=  {schema_name:       "./src/docextractor/data/dbdef.json",
                    load_data_info:    "./src/docextractor/data/loadfiles.json",
                    do_load_data_info: true,
                    verify:            VerifyBrowser,

  }
  command_line_args = get_args()
  what_schema_name = command_line_args[:schema_name]
  the_schema = allt.fetch(what_schema_name, nil)
  if the_schema.nil?
    STDERR.puts "-s '#{what_schema_name}' is not a known schema"
  else
    the_db = LoadAnyThing.go(schema_name: the_schema[:schema_name],
      load_data_info: the_schema[:load_data_info],
      do_load_data_info: the_schema[:do_load_data_info])
    the_schema[:verify].verify(the_db)
  end
end
