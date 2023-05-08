# TODO !!! Don't use ( avoid -c in /bin/a)
class ToExec
  def initialize
  end

  # ------------------------------------------------------------------------

  def genexec(x : Array(GrAST))
    tot = x.map { |g| genRule(g) }
    to_ret = %[
class DBDefGen
  def initialize
  end
  #{tot.join("\n")}
end]
    return to_ret
  end

  # ------------------------------------------------------------------------
  def genRule(aRule : GrAST)
    body = aRule.kids.map { |aKid|
      part = genParts(aKid)
      if part.is_a?(Array(String))
        part.flatten.join("\n")
      elsif part.is_a?(String)
        part
      else
        raise "genrule() genParts #{part} returns no array"
      end
    }
    body = body.flatten.join("\n")
    the_rule = %[# =============================
    def is_type_#{aRule.rulename}(rules : InAst::AbsSyntTree)
      return rules.kind == "rule" && rules.rule_name == "r_#{aRule.rulename}"
    end
    def r_#{aRule.rulename}(rules : InAst::AbsSyntTree)
      if !is_type_#{aRule.rulename}(rules)
        pp rules
        raise "Wrong rule to 'r_#{aRule.rulename}' "
      end
      stpr = Stepper.new(rules)
      #{body}
    end
  ]
    return the_rule
  end

  # ------------------------------------------------------------------------

  def genParts(aKid) # : RetTogenParts
    case aKid.kind
    when "Choice"
      return genChoice(aKid)
    when "Sequence"
      return genSequence(aKid)
    when "ruleref"
      return genRuleref(aKid)
    when "CharLiteral_Lx"
      return genCharLiteral_Lx(aKid)
    when "resword"
      return genresword(aKid)
    when "resoper"
      return genresoper(aKid)
    when "group"
      # puts "group"
      # pp aKid.kids
      return aKid.kids.map { |subkid|
        # puts subkid.dump
        genParts(subkid)
      }.flatten.join("\n")
    when "CharSetExpr"
      return genCharSetExpr(aKid)
      # when "CharSetInterval"
      #   return genCharSetInterval(aKid)
      # when "CharSetList"
      #   return genCharSetList(aKid)
    else
      STDERR.puts "genParts() missing ? #{aKid.kind}"
      STDERR.puts "genParts() NOT YET"
    end
    return "EMPTY genParts"
  end

  # ------------------------------------------------------------------------

  def genChoice(aKid) # : RetTogenParts
    body : String = ""
    aKid.kids.each_with_index { |a_kid, index|
      aChoiceBody = genParts(a_kid)
      if aChoiceBody.is_a?(String)
        # ((((((((((((((((((
        # if rules[stpr.content_now].kind == "" && rules[stpr.content_now].name/value = ""
        # l = r_#{}(rules[stpr.content_now])
        # ))))))))))))))))))

        body += aChoiceBody # one choice
      else
        raise "???"
      end
    }
    return body
  end

  # ------------------------------------------------------------------------
  def genSequence(aKid) # : RetTogenParts
    body : Array(String) = [] of String
    # STDERR.puts "genSequence start"
    i = 0
    # p "aKid.kids.size=#{aKid.kids.size}"
    while i + 1 <= aKid.kids.size
      x = genRepeats(aKid.kids[i], aKid.kids[i + 1])
      if x.is_a?(String)
        body << x
      else
        STDERR.puts "genSequence got no String, got '#{x}'"
      end
      i = i + 2
    end
    return body.flatten.join("\n")
  end

  # ------------------------------------------------------------------------
  def genRepeats(the_primary : GrAST, the_repeater : GrAST) # : RetTogenParts
    body : String = ""
    got = genParts(the_primary)
    if got.is_a?(String)
      body = got
    else
      body = got[:body]
    end
    if the_repeater.values[:times] == '1'
      return body
    end
    theRepeater = the_repeater.values[:times]
    # first_check_string = is_kind(the_primary)
    is_kind_string = xxx_is_kind(the_primary)

    code : String = ""

    case theRepeater
    when '+'
      # code = "#{body}\nwhile #{first_check_string} # AA\n #{body}\nend#AA\n"
      code = %[
        #{body}
        while stpr.having_more && #{is_kind_string} # rep '+'
          #{body}
        end]
    when '*'
      # code = "while #{first_check_string} # BB\n #{body}\nend#BB\n"
      code = %[
        while stpr.having_more && #{is_kind_string} # rep '*'
          #{body}
        end]
    when '?'
      code = %[
      if stpr.having_more # rep '?'
        if #{is_kind_string}
          #{body}
        end
      end]
      # code = "if #{first_check_string} #CC \n #{body}\nend#CC\n"
    when '0'
      the_repeater.values[:repnumber].to_i.times {
        # STDERR.puts "ONE TIME"
        code += body
      }
    when ','
      #     tmp1 = "@ch == '#{the_repeater.values[:repnumber]}'"
      #     tmp2 = "in_must_and_nowhite_next('#{the_repeater.values[:repnumber]}')\n"
      #     code = "#{body}\n
      # while #{tmp1} #DD \n #{tmp2}#{body}\nend #DD\n"
      # code = %[
      # #{body}
      # while stpr.having_more && #{is_kind_string} #  rep ','
      #   #{body}
      # end]

      code = %[#{body} # ','
    while stpr.having_more && #{is_kind_string}
      #{body}
    end]
    else
      raise "genRepeats() theRepeater#{theRepeater}"
    end

    return code
  end

  # ------------------------------------------------------------------------
  def genRuleref(aKid) # : RetTogenParts
    return %[
      ret = r_#{aKid.refrulename}(stpr.content_now)
      stpr.next]
    # return "rulref=#{aKid.refrulename}"
  end

  # ------------------------------------------------------------------------
  def genCharLiteral_Lx(aKid) # : RetTogenParts
    return ""
    # return "#{aKid.refrulename}"
  end

  # ------------------------------------------------------------------------
  def genresword(aKid) # : RetTogenParts
    return %[
      if !(stpr.content_now.kind == "resword" && stpr.content_now.value == "#{aKid.tokenvalue}")
        pp stpr.content_now
        raise "Expecting '#{aKid.tokenvalue}' "
      end
      stpr.next]
    # return "genresword=#{aKid.tokenvalue}"
  end

  # ------------------------------------------------------------------------
  def genresoper(aKid) # : RetTogenParts
    return %[
      if !(stpr.content_now.kind == "resoper" && stpr.content_now.value == "#{aKid.tokenvalue}")
        pp stpr.content_now
        raise "Expecting '#{aKid.tokenvalue}' "
      end
      stpr.next]
    # return "genresoper=#{aKid.tokenvalue}"
  end

  # ------------------------------------------------------------------------
  def genCharSetExpr(aKid) # : RetTogenParts
    return "genCharSetExpr#{aKid.refrulename}"
  end

  # ------------------------------------------------------------------------

  def xxx_is_kind(a_primary)
    funccall : String = ""
    funccall = is_kind(a_primary)
    return funccall
  end

  # ------------------------------------------------------------------------
  def is_kind(an_obj)
    # is_type_#{}
    case an_obj.kind
    when "ruleref"
      if (an_obj.refrulename.includes?(Suffix_Cs))
        return "r_#{an_obj.refrulename}()"
      else
        return "is_type_#{an_obj.refrulename}(stpr.content_now)"
      end
    when "Choice"
      choices = an_obj.kids.map { |a_kid|
        is_kind(a_kid)
      }
      return choices.join(" || ")
    when "resword"
      %[stpr.content_now.kind == "resword" && stpr.content_now.value == #{an_obj.tokenvalue}]
    when "resoper"
      %[stpr.content_now.kind == "resword" && stpr.content_now.value == #{an_obj.tokenvalue}]
    when "group"
      %[stpr.content_now.kind == "group"]
    when "Rule", "Sequence"
      return is_kind(an_obj.kids[0])
    else
      "UNKNOWN #{an_obj.kind}"
    end
  end
end
