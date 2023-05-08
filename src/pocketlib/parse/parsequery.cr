class Parse
  # ===============================
  def parseQuery(raw : String) : (TopAbsSyntTreeObj | Nil)
    @pgmsor = raw
    @at = 0
    self.in_white
    res = self.r_Program
    top = TopAbsSyntTreeObj.new
    top.data = [res]
    return top
  end
end
