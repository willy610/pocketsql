require "./clargs"
require "./grammar2ast"
require "./grammars"
require "./toparser"
require "./toexec"

module Grammar2Parser
  #
  # TEST ONLY ./bin/grammar2parser -g grammar -p ./src/grammar2parser/parseSELF_OUTLINE.cr [ -c ./src/grammar2parser/compileSELF_OUTLINE.cr ]

  # ./bin/grammar2parser -g sqlschema -p ./src/dbschema2X/parsecreateextended.cr [ -c ./src/dbschema2X/compilecreateastTEMPLATE.cr ]
  # ./bin/grammar2parser -g sql -p ./src/pocketlib/parse/parsesqlextended.cr

  command_line_args = get_args()
  grammarsource = Grammars::GrammarDict[command_line_args[:grammarin]]
  parserout = command_line_args[:parserout]
  creatorout = command_line_args[:creatorout]

  bnf = Grammar2AST.new
  flat_text = grammarsource.map { |r|
    "#{r[:rule]} : #{r[:body]} ;"
  }.join("\n")
  puts flat_text
  how, res = bnf.parseGrammer(flat_text)

  if parserout.size > 0
    gener = ToParser.new
    gened_parser = gener.genparser(res)
    File.write(parserout, gened_parser)
  end

  if creatorout.size > 0
    exer = ToExec.new
    gened_exectemplate = exer.genexec(res)
    File.write(creatorout, gened_exectemplate)
  end
end
