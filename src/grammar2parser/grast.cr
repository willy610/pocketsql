class GrAST
  property kind : String = ""
  property kids : Array(GrAST) = [] of GrAST
  property rulename : String = ""
  property refrulename : String = ""
  property tokenvalue : String = ""
  property prefix : Int32 = 0
  property fromchar : Char = ' '
  property tochar : Char = ' '
  property list : Array(Char) = [] of Char
  property values : Repeter = {times: '1', repnumber: "1"}
  property rule_type : RuleType = RuleType::PlainRule

  def initialize(@kind)
  end

  def initialize(@kind, @rulename)
  end
  def dump : String
    that = "GrAST:: kind=#{@kind}, rulename=#{@rulename} refrulename=#{@refrulename} tokenvalue=#{tokenvalue}"
    all = @kids.map { |s| s.dump }.join("\n")
    return "#{that} #{all}"
  end
end
