require "json"

class TopAbsSyntTreeObj
  include JSON::Serializable
  property tag : String = "AbsSyntTree"
  property data : Array(AbsSyntTree) = [] of AbsSyntTree

  def initialize
    # @data  = [] of (AbsSyntTree | ReswordValue | LexValue)
  end
end

class AbsSyntTree
  include JSON::Serializable
  property kind : String? # "lexem", "resword", "rule"
  property rule_name : String?
  property value : String = ""

  property content : Array(AbsSyntTree) = [] of AbsSyntTree

  def initialize(kind, rulename, other)
    @kind = kind
    @rule_name = rulename
    if kind == "lexem"
      @value = other
    elsif kind == "resword"
      @value = other
    elsif kind == "resoper"
      @value = other
    end
  end

  def to_s(io : IO)
    # x = @c_kids.map{|k|"#{k.to_s}\n"}

    io << "AbsSyntTree:: kind='#{@kind}'" << " rule_name='" << @rule_name << "' value= '" << @value << "'\n"
  end
  # def dump : String
  #   that = "AbsSyntTree:: a_rulename=#{@a_rulename}, c_kids=\n "
  #   slutet = @c_kids.map { |s| s.dump }.join("\n")
  #   return "#{that} #{slutet}"
  # end

end
