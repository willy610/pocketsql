require "./grast"
alias Repeter = {times: Char, repnumber: String}
enum RuleType
  PlainRule
  LxRule
  CsRule
end

class GotSymbol
  property kind : String = ""
  property value : Char | GrAST | String | Nil?

  def initialize(@kind)
  end

  def initialize
  end

  def initialize(@kind, @value)
  end

  def to_s(io : IO)
    io << "GotSymbol='" << @kind << "' value '" << @value << "'"
  end

  def set_value(new_value)
    if @value.nil?
      @value = new_value
    else
      raise "GotSymbol.set_value has old value = '#{@value}'"
    end
  end
end

class Grammar2AST
  property rules : String = ""
  property at : Int32 = 0
  property ch : Char = ' '
  property all_ruleObjs : Array(GrAST) = [] of GrAST

  def initialize
  end

  def eofinput
    if @at >= @rules.size
      return true
    else
      return false
    end
  end

  # ===============================
  def in_any_next
    if @at >= @rules.size
      # debugger;
      @ch = '\u0000'
    else
      @ch = @rules[@at]
      @at += 1
    end
  end

  # ===============================
  def in_white
    while (@ch <= ' ' && @ch != '\t' && @ch != '\u0000')
      in_any_next()
    end
  end

  # ===============================
  def in_must_and_nowhite_next(lookfor_c : Char)
    in_must_next(lookfor_c)
    in_white()
  end

  # ===============================
  def in_must_next(lookfor_c : Char)
    if lookfor_c != @ch
      from = (@at - 10 < 0) ? 0 : @at - 10
      to = (@at + 10 > @rules.size) ? rules.size : @at + 10
      inside = rules[from, to - from]
      STDERR.puts("Found '#{@ch}' but expecting '#{lookfor_c}' close to ' #{inside}' ")
      raise("FAIL")
    end
    in_any_next()
  end

  # ===============================
  def f_Grammar : {Bool, Array(GrAST) | Nil}
    in_white()
    how, gotSymbol = first_in_Rule()
    while how
      @all_ruleObjs.push(f_Rule(gotSymbol))
      in_any_next()
      in_white()
      how, gotSymbol = first_in_Rule()
    end
    return true, @all_ruleObjs
  end

  # ===============================
  def f_Rule(gotSymbol : GotSymbol) : GrAST
    # rule : choise
    rullen = GrAST.new("Rule", gotSymbol.value.to_s)
    rullen.rulename = gotSymbol.value.to_s
    in_must_and_nowhite_next(':')
    rullen.kids.push(f_Choice())
    in_must_and_nowhite_next(';')
    return rullen
  end

  # ===============================
  def first_in_Rule : {Bool, GotSymbol}
    returnSymbol = GotSymbol.new
    if eofinput()
      return false, returnSymbol
    end
    if first_in_Identifier_Lx()
      returnSymbol = GotSymbol.new("Identifier_Lx", f_Identifier_Lx())
      return true, returnSymbol
    else
      return false, returnSymbol
    end
  end

  # ===============================

  def f_Choice
    # seq ( | seq ) *
    prod_rule_choice = GrAST.new("Choice")
    prod_rule_choice.rulename = "Choice"
    prod_rule_choice.kids.push(f_Sequence())
    while (@ch == '|')
      in_must_and_nowhite_next('|')
      prod_rule_choice.kids.push(f_Sequence())
    end
    return prod_rule_choice
  end

  # ===============================

  def f_Sequence
    # primary repeats? (primary repeats?)*
    the_seq_rule = GrAST.new("Sequence")
    gotSymbol = GotSymbol.new
    first_in_Primary(gotSymbol)

    the_seq_rule.rulename = "Sequence"
    the_seq_rule.refrulename = gotSymbol.value.to_s

    primary : GrAST = f_Primary(gotSymbol)
    the_seq_rule.kids.push(primary)
    repeats : GrAST = f_Repeats_Lx()
    the_seq_rule.kids.push(repeats)
    gotSymbol = GotSymbol.new

    while first_in_Primary(gotSymbol)
      primary = f_Primary(gotSymbol)
      the_seq_rule.kids.push(primary)
      repeats_again : GrAST = f_Repeats_Lx()
      the_seq_rule.kids.push(repeats_again)
      gotSymbol = GotSymbol.new
    end
    return the_seq_rule
  end

  # ===============================
  def first_in_Primary(returnSymbol : GotSymbol) : Bool
    if (@ch == '[')
      returnSymbol.kind = "Literal_Cs"
      returnSymbol.value = @ch
      in_must_and_nowhite_next(@ch)
      return true
    elsif (@ch == '(')
      returnSymbol.kind = "Literal_Cs"
      returnSymbol.value = @ch
      in_must_and_nowhite_next(@ch)
      return true
    elsif (first_in_CharLiteral_Lx())
      returnSymbol.kind = "CharLiteral_Lx"
      returnSymbol.value = f_CharLiteral_Lx()
      return true
    elsif (first_in_Identifier_Lx())
      returnSymbol.kind = "Identifier_Lx"
      returnSymbol.value = f_Identifier_Lx()
      return true
    elsif (first_in_DQString_Lx())
      returnSymbol.value, returnSymbol.kind = f_DQString_Lx()
      return true
    end
    return false
  end

  # ===============================

  def f_Primary(gotSymbol : GotSymbol) : GrAST
    one_seq_member = GrAST.new("Primary")
    if gotSymbol.kind === "Identifier_Lx"
      one_seq_member.kind = "ruleref"
      one_seq_member.refrulename = gotSymbol.value.to_s
    elsif gotSymbol.kind === "resword" 
      one_seq_member.kind = "resword"
      one_seq_member.tokenvalue = gotSymbol.value.to_s
    elsif gotSymbol.kind === "resoper"
      one_seq_member.kind = "resoper"
      one_seq_member.tokenvalue = gotSymbol.value.to_s
    elsif gotSymbol.kind === "Literal_Cs" && gotSymbol.value === '('
      one_seq_member.kind = "group"
      a_seq_obj = f_Choice()
      one_seq_member.kids.push(a_seq_obj)
      in_must_and_nowhite_next(')')
    elsif gotSymbol.kind === "Literal_Cs" && gotSymbol.value === '['
      one_seq_member.refrulename = "Literal_Cs"
      one_seq_member = f_CharSetExpr()
      in_must_and_nowhite_next(']')
    elsif gotSymbol.kind === "CharLiteral_Lx"
      the_char = gotSymbol.value
      one_seq_member.kind = "CharLiteral_Lx"
      one_seq_member.tokenvalue = the_char.to_s
      if one_seq_member.tokenvalue === "\\'"
        one_seq_member.refrulename = "in_must_next"
      else
        one_seq_member.refrulename = "in_must_and_nowhite_next"
      end
    end
    return one_seq_member
  end

  # ===============================
  def first_in_Identifier_Lx : Bool
    return f_Literal_Fraction(@ch)
  end

  # ===============================
  def f_Identifier_Lx : String
    a_identifier : String = ""
    done = false
    while !done
      if f_Literal_Fraction(@ch)
        a_identifier += @ch
        in_any_next()
      elsif f_DIGIT_Fraction(@ch)
        a_identifier += @ch
        in_any_next()
      elsif @ch == '_'
        a_identifier += @ch
        in_any_next()
      else
        done = true
      end
      if eofinput
        puts "EOF"
      end
    end
    in_white()
    return a_identifier
  end

  # ===============================
  def first_in_CharLiteral_Lx : Bool
    if @ch == '\''
      return true
    else
      return false
    end
  end

  # ===============================
  def f_CharLiteral_Lx : Char
    to_return : Char = ' '
    in_must_next('\'')
    to_return = f_OneCharLiteral_Lx()
    in_must_and_nowhite_next('\'')
    return to_return
  end

  # ===============================

  def f_OneCharLiteral_Lx : Char
    a_char : Char = ' '
    if @ch >= ' ' && @ch <= '~' && @ch != '\'' && @ch != '\\'
      a_char = @ch
      in_any_next()
    elsif @ch == '\\'
      in_any_next()
      if @ch == 'u' # we have '\u
        a_char = @ch
        # //Number_Lx 4
      else # // we have '\
        # i [1, 2, 3, 1, 2, 3].index(2, offset: 2)
        i = ['b', 'f', 'n', 'r', 't', '\'', '"', '\\'].index(@ch)
        if i.nil?
          raise "f_OneCharLiteral_Lx"
        else
          a_char = ['\b', '\f', '\n', '\r', '\t', '\'', '"', '\\'][i]
          in_any_next()
        end
      end
    end
    return a_char
  end

  # ===============================

  def f_Repeats_Lx : GrAST
    # // number ?
    # // |  ('*' | '+' )  Number_Lx ?
    # // | '?'
    # // | ( ',' (',' | '|') )
    to_ret = GrAST.new("Repeats_Lx")
    rep_number : String = "0"
    in_white()
    if first_in_Number_Lx() || @ch == '*' || @ch == '+' || @ch == '?' || @ch == ','
      if @ch == '?'
        in_must_and_nowhite_next('?')
        to_ret.values = {times: '?', repnumber: "1"}
      elsif @ch == ','
        # // we have  ,   '|'
        in_must_and_nowhite_next(',')
        c_char = f_CharLiteral_Lx()
        if c_char == ',' || c_char == '|'
          to_ret.values = {times: ',', repnumber: c_char.to_s}
        else
          raise("NOT  ch === ','  OR  ch === '|' ")
        end
      elsif @ch == '*'
        in_must_and_nowhite_next('*')
        if first_in_Number_Lx()
          c_char = f_Number_Lx()
          rep_number = c_char
        end
        to_ret.values = {times: '*', repnumber: rep_number}
      elsif @ch == '+'
        in_must_and_nowhite_next('+')
        if first_in_Number_Lx()
          c_char = f_Number_Lx()
          rep_number = c_char
        end
        to_ret.values = {times: '+', repnumber: rep_number}
      elsif first_in_Number_Lx()
        c_char = f_Number_Lx() 
        rep_number = c_char
        to_ret.values = {times: '0', repnumber: rep_number}
      end
    else
      to_ret.values = {times: '1', repnumber: "1"} # // default
      return to_ret
    end
    return to_ret
  end

  # ===============================
  def first_in_Number_Lx : Bool
    return f_Digit19_Cs()
  end

  # ===============================
  def f_Number_Lx : String
    a_number : String = ""
    if @ch >= '1' && @ch <= '9'
      a_number += @ch
      in_any_next()
      while (@ch >= 'a' && @ch <= 'z') || (@ch >= 'A' && @ch <= 'Z') || (@ch >= '0' && @ch <= '9')
        a_number += @ch
        in_any_next()
      end
    end
    return a_number
  end

  # ===============================
  def f_Digit19_Cs : Bool
    if (@ch >= '1' && @ch <= '9') && !(false)
      return true
    else
      return false
    end
  end

  # ===============================
  def f_DIGIT_Fraction(a_dig : Char) : Bool
    if a_dig >= '0' && a_dig <= '9'
      return true
    else
      return false
    end
  end

  # ===============================
  def first_in_DQString_Lx : Bool
    if (@ch == '"')
      return true
    else
      return false
    end
  end

  # ===============================

  def f_DQString_Lx
    is_big_letter : Bool = true
    a_thestring : String = ""
    in_must_next('"')
    while @ch != '"'
      a_char = f_OneCharLiteral_Lx()
      if (a_char >= 'A' && a_char <= 'Z')
      else
        is_big_letter = is_big_letter & false
      end
      a_thestring += a_char
    end
    in_must_and_nowhite_next('"')
    if is_big_letter
      return [a_thestring, "resword"]
    else
      return [a_thestring, "resoper"]
    end

  end

  # ===============================
  def f_Literal_Fraction(a_ch : Char)
    if (a_ch >= 'a' && a_ch <= 'z') ||
       (a_ch >= 'A' && a_ch <= 'Z')
      return true
    else
      return false
    end
  end

  # ===============================

  def f_CharSetExpr
    # /*
    #  CharSetExpr : CharSet (('-' | '+') CharSet )* ;
    #  CharSet
    #  : Identifier_Lx
    #  | (('~' CharLiteral_Lx) | (','  (',' | '|')))
    #  | '[' CharSetExpr ']';
    #  */
    # /*
    #  CharSet();
    #  while (ch === '-' || ch === '+')
    #  CharSet();
    #  */
    # //			debugger
    rot = GrAST.new("CharSetExpr")
    # rot.kids = [];
    rot.prefix = 1
    first = f_CharSet()
    first.prefix = 1
    rot.kids.push(first)
    while (@ch == '-' || @ch == '+')
      the_oper = @ch
      in_must_and_nowhite_next(the_oper)
      latest = f_CharSet()
      latest.prefix = (the_oper == '+') ? +1 : -1
      rot.kids.push(latest) # // array of CharSet's
    end
    return rot
  end

  # ===============================

  def f_CharSet : GrAST
    a_char : Char = ' '
    if first_in_Identifier_Lx()
      to_ret = GrAST.new("ruleref")
      to_ret.prefix = +1
      to_ret.refrulename = "f_Identifier_Lx()"
      return to_ret
    elsif @ch == '['
      to_ret = GrAST.new("CharSetExpr")
      to_ret.prefix = 1
      in_must_and_nowhite_next('[')
      to_ret.kids.push(f_CharSetExpr()) # //  RULENAME
      in_must_and_nowhite_next(']')
      return to_ret
    elsif first_in_CharLiteral_Lx()
      a_char = f_CharLiteral_Lx()
      if @ch == '~' # // we have '~'
        to_ret = GrAST.new("CharSetInterval")
        to_ret.prefix = 1
        to_ret.fromchar = a_char
        in_must_and_nowhite_next('~')
        a_char = f_CharLiteral_Lx()
        to_ret.tochar = a_char
        return to_ret
      else # // we must have ,
        # // list of chars
        # // ['x','y','z' ]
        to_ret = GrAST.new("CharSetList")
        to_ret.prefix = 1
        to_ret.list.push(a_char) # // save first one
        while (@ch == ',')
          in_must_and_nowhite_next(',')
          a_char = f_CharLiteral_Lx()
          to_ret.list.push(a_char)
        end
        return to_ret
      end
    else
      raise "f_CharSet()"
    end
  end

  # ===============================
  def parseGrammer(raw : String) : {Bool, Array(GrAST)}
    @rules = raw
    @at = 0
    self.in_any_next
    how, res = self.f_Grammar
    return how, res
  end
end
