Suffix_Cs = "_Cs"
Suffix_Lx = "_Lx"
alias RetTogenParts = {body: String} | String

class ToParser
  property genedcode : Array(String) = [] of String
  property rule_is_Lx = false
  property rule_is_Cs = false
  property rule_is_General = false

  def initialize
  end

  # ------------------------------------------------------------------------

  def genparser(x : Array(GrAST))
    x.each { |g| genRule(g) }
    genclass = "
class Parse
  #{genedcode.flatten.join("\n")}
  end
"
    return genclass
  end

  # ------------------------------------------------------------------------
  def genRule(aRule : GrAST)
    if aRule.rulename == ""
      raise "NO rulename!!"
    end
    if (aRule.rulename.includes?(Suffix_Lx))
      @rule_is_Lx = true
    else
      @rule_is_Lx = false
    end
    if (aRule.rulename.includes?(Suffix_Cs))
      @rule_is_Cs = true
    else
      @rule_is_Cs = false
    end
    if (!@rule_is_Lx && !@rule_is_Cs)
      local_rule_is_General = true
    else
      local_rule_is_General = false
    end

    body = aRule.kids.map { |aKid|
      p = genParts(aKid)
      if p.is_a?(Array(String))
        p.flatten.join("\n")
      elsif p.is_a?(String)
        p
      else
        raise "genrule() genParts ${p} returns no array"
      end
    }
    body = body.flatten.join("\n")
    the_program : String = ""
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    if @rule_is_Lx
      the_program = %[
def r_#{aRule.rulename} : AbsSyntTree
  as_LEX = AbsSyntTree.new("lexem","r_#{aRule.rulename}","")
  to_ret : String = ""
  to_ret += @ch
  in_any_next()
  #{body}
  in_white()
  as_LEX.value = to_ret
  return as_LEX
end]
    end
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    if local_rule_is_General
      the_program = %[
def r_#{aRule.rulename} : AbsSyntTree
  as_AST = AbsSyntTree.new("rule","r_#{aRule.rulename}","")
  #{body}
  return as_AST
end
      ]
    end
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    if @rule_is_Cs
      the_program = "
def r_#{aRule.rulename} : Bool
#XX(CS)->
  #{body}
  return false
#XX(CS)-<
end
"
    end
    the_first_in = ""
    first_in_Lx = first_in_kids(aRule)
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
    if aRule.rule_type == RuleType::LxRule
      the_first_in =
        "
def first_in_r_#{aRule.rulename} : Bool
  return #{first_in_Lx}
end
"
    else
      # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
      # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
      # <<<<<<<<<<<<<<<>>>>>>>>>>>>>>>
      first_in_other = first_in_kids(aRule)
      the_first_in =
        "
def first_in_r_#{aRule.rulename} : Bool
  if #{first_in_other}
    return true
  else
    return false
  end
end
"
    end
    @genedcode << the_program << the_first_in
  end

  # ------------------------------------------------------------------------

  def genParts(aKid) : RetTogenParts
    if aKid.rulename.includes?("_Lx")
      aKid.rule_type = RuleType::LxRule
    elsif aKid.rulename.includes?("_Cs")
      aKid.rule_type = RuleType::CsRule
    else
      # default
    end

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
      return aKid.kids.map { |subkid|
        genParts(subkid)
      }.flatten.join("\n")
    when "CharSetExpr"
      return genCharSetExpr(aKid)
    when "CharSetInterval"
      return genCharSetInterval(aKid)
    when "CharSetList"
      return genCharSetList(aKid)
    else
      STDERR.puts "genParts() missing ? #{aKid.kind}"
      STDERR.puts "genParts() NOT YET"
    end
    return "EMPTY genParts"
  end

  # ------------------------------------------------------------------------

  def genChoice(aKid) : RetTogenParts
    body : String = ""

    if aKid.kids.size == 1 && aKid.rule_type != RuleType::CsRule
      return genParts(aKid.kids[0])
    end

    first_error_list = [] of String
    aKid.kids.each_with_index { |a_kid, index|
      if !@rule_is_Cs
        if index == 0
          test = "if "
        else
          test = "elsif "
        end
        cond = first_in_kids(a_kid.kids[0])
        first_error_list.push(cond)
        aChoiceBody = genParts(a_kid)
        if aChoiceBody.is_a?(String)
          body += "#{test} #{cond}\n#{aChoiceBody}\n"
        else
          raise "genChoice() (1)genParts(a_kid) returns other than String"
        end
      else
        aChoiceBody = genParts(a_kid)
        if aChoiceBody.is_a?(String)
          body += aChoiceBody
        else
          raise "genChoice() (2)genParts(a_kid) returns other than String"
        end
      end
    }
    if @rule_is_Cs
      body += "return false\n"
    else
      body += "else\n"
      x = "no choice of #{first_error_list.join('\n')}"
      body += "error(%{#{x}})"
      body += "\nend\n"
    end
    return body
  end

  # ------------------------------------------------------------------------
  def genSequence(aKid) : RetTogenParts
    body : Array(String) = [] of String
    i = 0
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
  def genRepeats(the_primary : GrAST, the_repeater : GrAST) : RetTogenParts
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
    first_check_string = first_in_kids(the_primary)
    code : String = ""
    case theRepeater
    when '+'
      # seq();
      # while (first_in())
      #   seq();
      code = "#{body}\nwhile #{first_check_string} # '+'\n #{body}\nend\n"
    when '*'
      # while ()
      #   seq();
      code = "while #{first_check_string} # '*'\n #{body}\nend\n"
    when '?'
      # if ()
      #   seq();
      code = "if #{first_check_string} # '?' \n #{body}\nend\n"
    when '0'
      the_repeater.values[:repnumber].to_i.times {
        code += body
      }
    when ','
      tmp1 = "@ch == '#{the_repeater.values[:repnumber]}'"
      tmp2 = "in_must_and_nowhite_next('#{the_repeater.values[:repnumber]}')\n"
      code = "#{body}\n
  while #{tmp1} # ', '\n #{tmp2}#{body}\nend\n"
    else
      raise "genRepeats() theRepeater#{theRepeater}"
    end

    return code
  end

  # ------------------------------------------------------------------------
  def genCharLiteral_Lx(aKid) : RetTogenParts
    escit = escape_it(aKid.tokenvalue)
    token = aKid.tokenvalue
    return {
      body: "r_#{aKid.refrulename}('#{escit}#{token}')",
    }
  end

  # ------------------------------------------------------------------------
  def genresword(aKid) : RetTogenParts
    return {
      body: %[in_res_word("#{aKid.tokenvalue}")
      resword_AST = AbsSyntTree.new("resword","resword","#{aKid.tokenvalue}")
      as_AST.content.push(resword_AST)]
    }
  end

  # ------------------------------------------------------------------------
  def genresoper(aKid) : RetTogenParts
    return {
      body: %[in_res_oper("#{aKid.tokenvalue}")
      resoper_AST = AbsSyntTree.new("resoper","resoper","#{aKid.tokenvalue}")
      as_AST.content.push(resoper_AST)]
    }
  end

  # ------------------------------------------------------------------------
  alias APair = {prefix: Int32, code: String}

  def genCharSetExpr(aKid) : RetTogenParts
    char_set_expr_terms : Array(APair) = [] of APair
    aKid.kids.each { |a_kid|
      gen_CharSet(char_set_expr_terms, a_kid, a_kid.prefix)
    }
    char_set_expr_terms.sort { |a, b| a[:prefix] <=> b[:prefix] }
    include_parts : Array(String) = [] of String
    exclude_parts : Array(String) = [] of String
    char_set_expr_terms.each { |a_pair|
      if a_pair[:prefix] == 1
        include_parts.push(a_pair[:code])
      else
        exclude_parts.push(a_pair[:code])
      end
    }
    if (exclude_parts.size == 0)
      exclude_parts = ["false"]
    end
    to_ret : String = ""
    # JUST TAKE 2. above
    #  return  (() && !())
    # make up the expression to test
    incs = include_parts.join(" || ")
    exc = exclude_parts.join(" || ")
    logical_expression = "(#{incs}) && !(#{exc})"
    if @rule_is_Cs
      to_ret =
        "if #{logical_expression}
  return true
  end
"
      return to_ret
    else
      to_ret = "
if #{logical_expression}
  to_ret += ch
  in_any_next()
else
  error(\"ch  not in #{logical_expression}\")
end
"
      return to_ret
    end
  end

  # ------------------------------------------------------------------------
  def gen_CharSet(sofar, xxx, outerprefix)
    case xxx.kind
    when "ruleref"
      sofar.push({prefix: outerprefix, code: xxx.refrulename + "()"})
    when "CharSetExpr"
      xxx.kids.each { |kidden|
        gen_CharSet(sofar, kidden, kidden.prefix * outerprefix)
      }
    when "CharSetInterval"
      sofar.push({
        prefix: outerprefix,
        code:   "@ch >= '" + xxx.fromchar + "' && @ch <= '" + xxx.tochar + "'",
      })
    when "CharSetList"
      listan = "[" + xxx.list.map { |c|
        escape = escape_it(c)
        "'#{escape}#{c}'"
      }.join(",") + "]"
      sofar.push({
        prefix: outerprefix,
        code:   listan,
      })
    else
    end
  end

  # ------------------------------------------------------------------------
  def genCharSetInterval(aKid) : RetTogenParts
    # STDERR.puts "genCharSetInterval start"
    # STDERR.puts "genCharSetInterval end"
    return "EMPTY genCharSetInterval"
  end

  # ------------------------------------------------------------------------
  def genCharSetList(aKid) : RetTogenParts
    # STDERR.puts "genCharSetList start"
    # STDERR.puts "genCharSetList end"
    return "EMPTY genCharSetList"
  end

  # end

  # ------------------------------------------------------------------------

  def first_in_kids(a_primary)
    funccall : String = ""
    funccall = first_in(a_primary)
    return funccall
  end

  def first_in(an_obj)
    case an_obj.kind
    when "ruleref"
      if (an_obj.refrulename.includes?(Suffix_Cs))
        return "r_#{an_obj.refrulename}()"
      else
        return "first_in_r_#{an_obj.refrulename}()"
      end
    when "Rule"
      return first_in(an_obj.kids[0])
    when "Sequence"
      return first_in(an_obj.kids[0])
    when "group"
      return first_in(an_obj.kids[0])
    when "List"
      return first_in(an_obj.kids[0])
    when "Iter"
      return first_in(an_obj.kids[0])
    when "Choice"
      choices = an_obj.kids.map { |a_kid|
        first_in(a_kid)
      }
      return choices.join(" || ")
    when "CharLiteral_Lx"
      escape = escape_it(an_obj.tokenvalue)
      return "@ch == '" + escape + an_obj.tokenvalue + "'"
    when "Literal_Cs"
      return "FAIL Literal_Cs"
    when "CharSetExpr"
      return first_in(an_obj.kids[0])
    when "CharSetInterval"
      return "@ch >= '#{an_obj.fromchar}'"
    when "CharSetList"
      listan = an_obj.list.map { |l_ch|
        escape = escape_it(l_ch)
        "'#{escape}#{l_ch}'"
      }
      return "[" + listan.join(',') + "].includes(ch)"
    when "resword"
      return "(@ch == '#{an_obj.tokenvalue[0]}' && in_res_word(\"#{an_obj.tokenvalue}\",false))"
    when "resoper"
      return "(@ch == '#{an_obj.tokenvalue[0]}' && in_res_oper(\"#{an_obj.tokenvalue}\",false))"
    when "Repeats_Lx"
      return " true "
      break
    else
      pp an_obj
      debugger
      return '"' + an_obj.tokenvalue + '"'
    end
  end

  def escape_it(c : Char)
    puts "escape_it_char (#{c})"
    if (c == '\'' || c == '\\')
      return "\\"
    else
      return ""
    end
  end

  def escape_it(c : String)
    if (c == "'" || c == "\\")
      return "\\"
    else
      return ""
    end
  end

  def genRuleref(aKid) : RetTogenParts
    #
    # How to call a rule
    # From General to General
    #   my_collector.kids.push( f_XXX(gotSymbol) ))

    # From General to Lx
    #   my_collector.kids.push( f_XXX(gotSymbol) ))

    # From Lx to Lx
    #   ??? = f_XXX_Lx()

    # From Lx to C
    #   return f_XXX_Cs

    to_ret = {body: "ERROR #{aKid.refrulename}"}
    if (aKid.refrulename == "StringLiteral")
      STDERR.puts "genRuleref FAIL"
    end
    if (aKid.refrulename.includes?(Suffix_Cs))
      local_rule_REF_is_Cs = true
    else
      local_rule_REF_is_Cs = false
    end
    if aKid.refrulename.includes?(Suffix_Lx)
      local_calling_Lx = true
    else
      local_calling_Lx = false
    end
    local_rule_is_General = true
    @rule_is_Lx = true
    if @rule_is_Lx && local_calling_Lx
      to_ret = {
        body: "to_ret +=r_#{aKid.refrulename}()#1.\n",
      }
    end
    if @rule_is_Lx && !local_calling_Lx && local_rule_REF_is_Cs
      to_ret = {
        body: "
        {
        r_#{aKid.refrulename}()
        to_ret += @ch
        in_any_next()
        ",
      }
    end
    if @rule_is_Lx && !local_calling_Lx && !local_rule_REF_is_Cs
      to_ret = {
        body: "r_#{aKid.refrulename}()#3.Total\n",
      }
    end
    if local_rule_is_General && local_calling_Lx
      to_ret = {
        body: "
#4->
as_AST.content.push(r_#{aKid.refrulename}())
#<-4
",
      }
    end
    if local_rule_is_General && !local_calling_Lx && local_rule_REF_is_Cs
      to_ret = {
        body: "r_#{aKid.refrulename}()
        to_ret += @ch
        in_any_next()#5.Total",
      }
    end
    if local_rule_is_General && !local_calling_Lx && !local_rule_REF_is_Cs
      to_ret = {
        body: "as_AST.content.push(r_#{aKid.refrulename}())",
      }
    end
    return to_ret
  end
end
