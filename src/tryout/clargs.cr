require "option_parser"

def get_args
  opt_s = String.new
  opt_a = String.new
  opt_c = String.new
  opt_S = String.new
  opt_A = String.new
  opt_C = String.new
  parameter = String.new
  xecute = false
  display = false
  output = false

  OptionParser.parse(gnu_optional_args: true) do |parser|
    parser.banner = "Use cases :
  From source:
   -S dir -A ? -C ? (-p file)? options ?
   -s file.sql (-a file)? (-c file)? (-p file)? options ?
  From AST:
   -A dir -C ?
   -a file.ast ( -c file.code) ? (-p file)? options ?
  From Code:
   -C options ? (-p file)?
   -c file.code options ? (-p file)?
  "

    parser.on("-x", "--execute", "execute") { xecute = true }
    parser.on("-d", "--display", "show as sheet") { display = true }
    parser.on("-o", "--output", "print input") { output = true }
    parser.on "-v", "--version", "Show version" do
      puts "version 0.9"
      exit
    end
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.on("-s", "--sql x.sql", "from sql file") do |name|
      opt_s = name
    end
    parser.on("-S", "--SQL dir", "all *.sql on dir") do |name|
      opt_S = name
    end
    parser.on("-a", "--ason x_asjson.json", "AST file") do |name|
      opt_a = name
    end
    parser.on("-A", "--ASON dir", "all *.json on dir") do |name|
      opt_A = name
    end
    parser.on("-c", "--code x_ascode.json", "Code file") do |name|
      opt_c = name
    end
    parser.on("-C", "--Code x_ascode.json", "all *.json on dir") do |name|
      opt_C = name
    end
    parser.on("-p", "--parameter x_ascode.json", "send parameter file when executing") do |name|
      parameter = name
    end
  end
  final_args = {
    opt_s:     opt_s,
    opt_a:     opt_a,
    opt_c:     opt_c,
    opt_S:     opt_S,
    opt_A:     opt_A,
    opt_C:     opt_C,
    xecute:    xecute,
    display:   display,
    output:    output,
    parameter: parameter,
  }
  # puts final_args
  return final_args
end
