class OuterRow
  property filename : String
  property colnames : Array(String)
  property the_row : Array(String)

  def initialize(@filename, @colnames, @the_row)
  end

  def initialize
    @filename = ""
    @colnames = [] of String
    @the_row = [] of String
  end
    # ----------------------------------------------
  def as_one_row
    [@colnames.map{|c|c},@the_row.map{|c|c}]
  end

end
