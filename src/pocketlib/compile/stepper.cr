require "../parse/ast"

class Stepper
  property the_rule : AbsSyntTree
  property size : Int32

  def initialize(@the_rule)
    @size = @the_rule.content.size
    @pos_now = 0
  end

  def having_more
    @pos_now <= @size - 1
  end

  def next
    @pos_now += 1
    self
  end

  def content_now
    @the_rule.content[@pos_now]
  end

  def dump_content
    @the_rule.content.each_with_index{|c,i|
      puts i
      puts "kind=#{c.kind}"
      puts "rule_name=#{c.rule_name}"
      puts "value=#{c.value}"
      }
  end
end
