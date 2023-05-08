require "option_parser"

def get_args
  grammarin = String.new
  parserout = String.new
  creatorout = String.new
  OptionParser.parse do |parser|
    parser.banner = "Usage: grammar2parser -g grammarname  [-p filename] [-c filename]"

    parser.on "-v", "--version", "Show version" do
      puts "version 0.9"
      exit
    end
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.on("-g", "--grammarin GRAMMARNAME", "filename generated parser out") do |name|
      grammarin = name
    end
    parser.on("-p", "--parserout PARSEOUT", "generated parser") do |name|
      parserout = name
    end
    parser.on("-c", "--craetorout CREATOROUT", "filename generated codegen (prel.)") do |name|
      creatorout = name
    end
  end
  final_args = {
    grammarin:  grammarin,
    parserout:  parserout,
    creatorout: creatorout,
  }
  puts final_args
  return final_args
end
