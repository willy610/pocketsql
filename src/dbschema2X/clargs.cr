require "option_parser"

def get_args
  sqldefsource = String.new
  createsqltable = String.new
  dbschema = String.new
  tablesuffix = String.new
  #
  OptionParser.parse do |parser|
    parser.banner = "Usage: dbschema2X -s filename  ( -c createtable [-t tablesuffix] ) | -d filename"
    parser.on "-v", "--version", "Show version" do
      puts "version 0.9"
      exit
    end
    parser.on "-h", "--help", "Show help" do
      puts parser
      exit
    end
    parser.on("-s", "--sql source", "filename sql source in") do |name|
      sqldefsource = name
    end
    parser.on("-c", "--createsqltable codeout", "filename holding create sql tables") do |name|
      createsqltable = name
    end
    parser.on("-d", "--dbschema codeout", "filename generated dbschema") do |name|
      dbschema = name
    end
    parser.on("-t", "--tablesuffix xxx", "tablesuffix for create table") do |name|
      # Append this to each CREATE TABLE XX()<suffix>
      # (like ENGINE [=] engine_name, COLLATE [=] collation_name)
      tablesuffix = name
    end
  end
  final_args = {
    sqldefsource:   sqldefsource,
    createsqltable: createsqltable,
    dbschema:       dbschema,
    tablesuffix:    tablesuffix,
  }
  # puts final_args
  return final_args
end
