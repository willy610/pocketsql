class CTEandDerivedX
  property tables : Array(ResultSet) = [] of ResultSet

  def initialize
  end

  def dump
    tables.each { |t| p t }
  end

  # ---------------------------------------------

  def add_cte_def(kind, tablename, comma_list)
    @tables << ResultSet.new([tablename], [comma_list])
  end

  # ---------------------------------------------
  def add_values_def(kind, tablename, comma_list, rows)
    @tables << ResultSet.new([tablename], [comma_list], rows.map { |r| [r] })
  end

  # ---------------------------------------------

  def find_table(tbl_name)
    indx = @tables.map { |t| t.tablenames[0] }.index(tbl_name)
    if !indx.nil?
      return @tables[indx]
    else
      return nil
    end
  end

  # ---------------------------------------------
  def find_table(loadfilename, colnames, filename)
    tbl = find_table(loadfilename)
    if !tbl.nil?
      return tbl
    else
      the_file_path = loadfilename
      lines = File.read_lines(the_file_path)
      x = ResultSet.new([filename], [colnames], lines.map { |l| [l.split(',')] })
      return x
    end
  end
end
