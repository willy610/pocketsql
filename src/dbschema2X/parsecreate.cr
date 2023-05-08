class Parse
  def parseCreate(raw : String) : (TopAbsSyntTreeObj | Nil)
    @pgmsor = raw
    @at = 0
    self.in_white
    res = self.r_Createtable
    top = TopAbsSyntTreeObj.new
    top.data = [res]
    return top
  end
end
