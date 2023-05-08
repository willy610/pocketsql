require "option_parser"

def get_args
  schema_name = String.new
  OptionParser.parse do |parser|
    parser.on "-v", "--version", "Show version" do
      puts "version 0.9"
      exit
    end
    # parser.on("-d", "--do_load_data_info", "optional") { do_load_data_info = true}
    parser.on("-s", "--schema_name schema_name", "\nEx: sss") do |name|
      schema_name = name
    end
    # parser.on("-l", "--load_data_info load_data_info", "\nEx: sss") do |name|
    #     load_data_info = name
    # end
  end
  final_args = {
    schema_name: schema_name,
  }
  puts final_args
  return final_args
end
