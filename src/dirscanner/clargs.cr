require "option_parser"

def get_args
  dir = String.new
  header = false
  sqlinsert = false
  OptionParser.parse do |parser|
    parser.banner = "Usage: dirscanner -d dirpath  [ -h ] [ -i ] >standard_output"
    parser.on "-v", "--version", "Show version" do
      puts "version 0.9"
      exit
    end
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.on("-c", "--colnames", "insert colnames in first output row") { header = true }
    parser.on("-i", "--insert", "use 'INSERT.. for standard SQL") { sqlinsert = true }
    parser.on("-d", "--directory", "directory to scan recursivly") do |name|
      dir = name
    end
  end
  final_args = {
    dir:       dir,
    header:    header,
    sqlinsert: sqlinsert,
  }
  return final_args
end
