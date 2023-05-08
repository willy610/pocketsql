require "./clargs"
require "../pocketlib/parse/parsequery"
require "../pocketlib/parse/parsesqlextended"
require "../pocketlib/parse"
require "../pocketlib/compile/compileast"

module Tryout
  command_line_args = get_args()

  # https://stackoverflow.com/questions/73234038/how-do-i-list-files-and-directories-those-are-not-hidden-in-current-directory-us
  # https://randomgeekery.org/post/2019/11/directory-listings-with-crystal/
  # -------------------------------

  # Use cases :
  #  -S dir -A ? -C ? (-p file)? options ?
  #  -s file.sql (-a file.ast)? (-c file.code)? (-p file)? options ?
  #  -A dir -C ?
  #  -a file.ast ( -c file.code) ? (-p file)? options ?
  #  -C ? options (-p file)?
  #  -c file.code options (-p file)?

  # ---------------------------------------------------------------
  s_to_x = ->(sqlfile_name : String, ast_file_out : String, code_file_out : String, xecute : Bool, print : Bool, output : Bool) {
    source = File.read(sqlfile_name)
    if print
      puts source
    end
    the_AST = Parse.new.parseQuery(source)

    if !the_AST.nil?
      if ast_file_out.size != 0
        File.write(ast_file_out, the_AST.to_json)
      end

      db = DBSchema.new
      the_Code : QR::TopInQr = CompileAst.new(db).go(the_AST.data[0])
      if code_file_out.size != 0
        File.write(code_file_out, the_Code.to_json)
      end
      if xecute == true
        a_ResultSet = ExecuteQr.new(db).go(the_Code)
        if output == true
          if !a_ResultSet.nil?
            # If one wnats to access a certain column in each row
            #BEGIN
            # try_indx_date = a_ResultSet.colnames[0].index("date")
            # try_indx_date.try { |indx_date|
            #   a_ResultSet.rows.each { |a_row|
            #     date_value = a_row[0][indx_date]
            #     puts "date=#{date_value}"
            #   }
            # }
            #END
            puts a_ResultSet.to_s
          end
        end
      end
    end
  }
  # ---------------------------------------------------------------
  a_to_x = ->(jsonfile_name : String, code_file_out : String, xecute : Bool, output : Bool) {
    the_AST = TopAbsSyntTreeObj.from_json(File.read(jsonfile_name))
    db = DBSchema.new
    the_Code = CompileAst.new(db).go(the_AST.data[0])
    if xecute == true
      a_ResultSet = ExecuteQr.new(db).go(the_Code)
      if output == true
        if !a_ResultSet.nil?
          puts a_ResultSet.to_s
        end
      end
    end
  }
  # -------------------------------
  if command_line_args[:parameter].size > 0
    params = AllParams.from_json(File.read(command_line_args[:parameter]))
    ExecuteQr.params = params
  end

  if command_line_args[:opt_S].size > 0
    #
    # -S -A ? -C ?  options ?
    #
    if command_line_args[:opt_A].size != 0
      dir_name_A = command_line_args[:opt_A]
    end
    if command_line_args[:opt_C].size != 0
      dir_name_C = command_line_args[:opt_C]
    end
    dir_name_S = command_line_args[:opt_S]

    Dir.open(dir_name_S).each_child { |child|
      extension = File.extname(child)
      the_base_file_name = File.basename(child, extension) # => "file"
      if !child.starts_with?(".")
        if child.ends_with?(".sql")
          puts "#{dir_name_S}/#{child}"
          the_a = if dir_name_A.nil?
                    ""
                  else
                    "#{dir_name_A}/#{the_base_file_name}.json"
                  end
          the_c = if dir_name_C.nil?
                    ""
                  else
                    "#{dir_name_C}/#{the_base_file_name}.json"
                  end
          s_to_x.call("#{dir_name_S}/#{child}",
            the_a,
            the_c,
            command_line_args[:xecute],
            command_line_args[:display],
            command_line_args[:output])
        end
      end
    }
  elsif command_line_args[:opt_s].size > 0
    #
    # -s file (-a file)? (-c file)? options ?
    #
    if command_line_args[:opt_a].size != 0
      file_name_a = command_line_args[:opt_a]
    else
      file_name_a = ""
    end
    if command_line_args[:opt_c].size != 0
      file_name_c = command_line_args[:opt_c]
    else
      file_name_c = ""
    end
    s_to_x.call(command_line_args[:opt_s],
      file_name_a, file_name_c,
      command_line_args[:xecute],
      command_line_args[:display],
      command_line_args[:output])
  elsif command_line_args[:opt_A].size > 0
    #
    # -A -C? options ?
    #
    if command_line_args[:opt_C].size != 0
      dir_name_C = command_line_args[:opt_C]
    end

    dir_name = command_line_args[:opt_A]
    Dir.open(dir_name).each_child { |child|
      if !child.starts_with?(".")
        if child.ends_with?(".json")
          puts "#{dir_name}/#{child}"
          extension = File.extname(child)
          the_base_file_name = File.basename(child, extension) # => "file"

          the_c = if dir_name_C.nil?
                    ""
                  else
                    "#{dir_name_C}/#{the_base_file_name}.json"
                  end

          a_to_x.call("#{dir_name}/#{child}",
            the_c,
            command_line_args[:xecute],
            command_line_args[:output]
          )
        end
      end
    }
  elsif command_line_args[:opt_a].size > 0
    #
    # -a file (-c file)? options?
    #
    if command_line_args[:opt_c].size != 0
      file_name_c = command_line_args[:opt_c]
    else
      file_name_c = ""
    end

    a_to_x.call(command_line_args[:opt_a],
      file_name_c,
      command_line_args[:xecute],
      command_line_args[:output])
    #
  elsif command_line_args[:opt_c].size > 0
    #
    # -c file options?
    #
    the_Code = QR::TopInQr.from_json(File.read(command_line_args[:opt_c]))
    if command_line_args[:xecute] == true
      a_ResultSet = ExecuteQr.new(DBSchema.new).go(the_Code)
      if command_line_args[:output] == true
        if !a_ResultSet.nil?
          puts a_ResultSet.to_s
        end
      end
    end
  end
end
