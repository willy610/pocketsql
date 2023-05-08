class ResultSet
  property tablenames : Array(String) = [] of String   # one entry for each table
  property colnames : Array(TableRow) = [] of TableRow # one row for each table
  property rows : Array(ResultRow) = [] of ResultRow
  property value : String = ""
  property isNumeric : Bool?
  property isAggregation : Bool = false

  def initialize
  end

  def initialize(@tablenames, @colnames, @rows)
  end

  def initialize(@tablenames, @colnames)
  end

  # ----------------------------------------------
  def save_to_dir(dirpath : String)
    the_file = File.new("#{dirpath}/#{@tablenames[0]}.csv", "w")
    @rows.each { |a_ResultRow|
      the_file.puts(a_ResultRow[0].join(","))
    # the_file.write_string(["ett","tva"].join(",").to_slice)
    }
  end

  # ----------------------------------------------
  def get_a_pk_iter
    @rows.map { |a_ResultRow| a_ResultRow }
  end

  # ----------------------------------------------

  def get_an_OuterRow_template
    (0...@tablenames.size - 0).map { |i|
      OuterRow.new(@tablenames[i], @colnames[i], [] of String)
    }
  end

  # ----------------------------------------------
  def qr_delete_rows(rows_for_delete : Array(OuterRow))
    if @tablenames.size != 1
      raise "delete_rows() Stored table must be of dimension==1"
    end
    rows_for_delete.each { |as_OuterRow|
      the_row_to_delete = as_OuterRow.the_row
      indx = @rows.index { |a_stored_row|
        the_row_to_delete == a_stored_row[0]
      }
      if !indx.nil?
        @rows.delete_at(indx)
      end
    }
  end

  # ----------------------------------------------
  def find_id_for_a_row(arow : OuterRow)
    indx = @rows.index { |a_stored_row|
      arow.the_row == a_stored_row[0]
    }
    indx
  end

  # ----------------------------------------------
  def qr_update_row(id_row_to_update, row : OuterRow, colname : String, new_value)
    if @tablenames.size != 1
      raise "qr_update_row() Stored table must be of dimension==1"
    end
    colindex = @colnames[0].index { |c| colname == c }
    if !colindex.nil?
      @rows[id_row_to_update][0][colindex] = new_value
    else
      raise "qr_update_row () row '#{row}' not found"
    end
  end

  # ----------------------------------------------

  def to_num
    if @isNumeric
      if @value.is_a?(String)
        return @value.to_f32
      end
    end
    raise "No 'ResultSet' to_num"
  end

  # ----------------------------------------------

  # def to_s(io : IO)
  #   io << tablenames.join(" >< ") + "\n"
  #   io << colnames.map { |one_tbl| one_tbl.join(" | ") }.join(" >< ")+"\n"
  #   rows.each { |arow|
  #     io << arow.map { |one_tbl| one_tbl.join(" | ") }.join(" >< ")+"\n"
  #   }
  # end

  # ----------------------------------------------
  def projection_as_json
    if @tablenames.size != 1
      raise "projection_as_json() ResultSet must be of dimension 1"
    end
    col_names = @colnames[0].map { |c| %("#{c}") }.flatten.join(",")
    rows = @rows.map { |a_ResultRow| a_ResultRow[0] }.to_json

    return %("col_names":[ #{col_names}], "rows": #{rows} )
  end

  # ----------------------------------------------

  def dump
    return "ResultSet:#{@value}"
  end

  # ------------------------------------
  # def show
  #   to_show
  # end
  # ------------------------------------
  def to_s(io : IO)
    max_col_width = 300
    limit = 10000
    colnames = @tablenames.map_with_index { |t, it|
      @colnames[it].map { |c| "#{t}.#{c}" }
    }.flatten
    colnames = @colnames.flatten
    max_widths = colnames.map { |hdr| hdr.size }
    # Calc max widths
    @rows.each_with_index { |a_ResultRow, row_nr|
      if row_nr + 0 > limit
        break
      end
      a_ResultRow.flatten.each_with_index { |c, ic|
        if ic > max_widths.size - 1
          puts "!" + __FILE__ + ":" + __LINE__.to_s
          pp self
          raise "line '#{a_ResultRow}' too many columns"
        end
        if c.size > max_widths[ic]
          max_widths[ic] = [c.size, max_col_width].min
        end
      }
    }
    firstline = (["+"] <<
                 max_widths.map { |acol|
                   (0..acol + 1).map { |_| "-" }.join
                 }.join("+") << "+").join

    ([colnames.flatten] + rows).each_with_index { |a_row, row_nr|
      cols = a_row.flatten.map_with_index { |val, i|
        sprintf "%-#{max_widths[i]}s", val[0, [val.size, max_col_width].min]
      }.join(" | ")
      if row_nr + 0 > limit
        break
      end
      if row_nr == 0
        io << firstline + "\n"
        io << "| #{cols} |" + "\n"
        io << firstline + "\n"
      else
        io << "| #{cols} |" + "\n"
      end
    }
    io << firstline + "\n"
  end
end
