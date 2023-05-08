require "./clargs"

module Dirscanner
  # ./bin/dirscanner -d directory [-h] -[i]
  #
  # Will scan dir and all subdirectories and collect
  # dir,name,extension,type,date,time,size
  command_line_args = get_args()
  dir = command_line_args[:dir]
  if dir.size == 0
    puts "-d directory"
    exit
  end
  lista = Dir.glob("#{dir}/**/*")
  if command_line_args[:header]
    puts "dir,name,extension,type,date,time,size"
  end

  lista.each { |file_name|
    begin
      fileinfo = File.info(file_name)
    rescue
      STDERR.puts "File '#{file_name}' not found"
    else
      extension = File.extname(file_name)
      dirname = File.dirname(file_name) # => "/foo/bar"
      dirname = dirname.gsub("'") { "\"" }
      basename = File.basename(file_name, extension) # "xxx.txt"=> ""txt"
      basename = basename.gsub(",") { "_" }
      basename = basename.gsub("'") { "\"" }
      date_and_time_zone = fileinfo.modification_time.to_s.split(' ')
      if File.file?(file_name)
        if basename.starts_with?("Icon")
          next
        end
        kind = 'F'
      elsif File.directory?(file_name)
        kind = 'D'
      end
      ut_cvs = %[#{dirname},#{basename},#{extension},#{kind},#{date_and_time_zone[0]},#{date_and_time_zone[1]},#{fileinfo.size}]
      if ut_cvs.index("/Library/") == nil
        if command_line_args[:sqlinsert] == true
          ut_sql = %[INSERT INTO `files` VALUES ('#{dirname}','#{basename}','#{extension}','F','#{date_and_time_zone[0]}','#{date_and_time_zone[1]}','#{fileinfo.size}');]
          puts ut_sql
        else
          puts ut_cvs
        end
      end
    end
  }
end
