require "./ast"
require "./dqstringliteral"
require "./sqstringliteral"
require "./param"
require "./scalaroper"
require "./compoper"
require "./identifier"
require "./number"
require "./comment"
require "./table"

class Parse
  property pgmsor : String = ""

  property at : Int32 = 0
  property ch : Char = ' '
  property all_ruleObjs : Array(AbsSyntTree) = [] of AbsSyntTree

  def initialize
  end

  # ----------------------------------------------------------------------------------

  def in_res_oper(must_oper)
    return in_res_oper(must_oper, true)
  end

  # ----------------------------------------------------------------------------------
  def in_res_oper(must_oper, itMust)
    in_white()
    in_word : String = ""
    in_pos : Int32 = 0
    save_at = @at
    save_ch = @ch
    # while @ch != ' '
    while in_pos < must_oper.size && @ch == must_oper[in_pos]
      in_word += @ch
      in_pos += 1
      in_any_next()
    end

    if in_word == must_oper
      if itMust
        in_white()
        return true
      else
        @ch = save_ch
        @at = save_at
        return true
      end
    else
      if itMust
        error("Expecting '" + must_oper + "' but found '" + @ch + "' ")
      else
        @ch = save_ch
        @at = save_at
        return false
      end
    end
  end

  # ----------------------------------------------------------------------------------

  def in_res_word(must_word)
    return in_res_word(must_word, true)
  end

  # ----------------------------------------------------------------------------------

  # def in_res_word(must_word, itMust, word_or_symb)
  def in_res_word(must_word, itMust)
    in_white()
    in_word : String = ""
    in_pos : Int32 = 0
    save_at = @at
    save_ch = @ch
    is_letters : Bool = true
    while in_pos < must_word.size && @ch == must_word[in_pos]
      in_word += @ch
      if @ch >= 'A' && @ch <= 'Z'
        is_letters = is_letters & true
      else
        is_letters = is_letters & false
      end
      in_pos += 1
      in_any_next()
    end
    if in_word == must_word && (@ch < 'A' || @ch > 'Z')
      # FOUND like 'OR' but not 'ORDER'
      if itMust
        in_white() # consume it
        return true
      else
        # TEST and FOUND. Restore
        @ch = save_ch
        @at = save_at
        return true
      end
    else
      # No match at all
      if itMust
        error("Expecting '" + must_word + "' but found '" + @ch + "' ")
      else
        @ch = save_ch
        @at = save_at
        return false
      end
    end
  end

  # ----------------------------------------------------------------------------------

  def r_in_must_and_nowhite_next(tkn : Char)
    in_must_next(tkn)
    in_white()
  end

  # ----------------------------------------------------------------------------------

  def in_any_next
    if @at >= @pgmsor.size
      # debugger;
      @ch = '\u0000'
      # raise "END Of INPUT"
    else
      @ch = @pgmsor[@at]
      @at += 1
    end
  end

  def in_white
    while (@ch <= ' ' && @ch != ';' && @ch != '\u0000')
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
      to = (@at + 10 > @pgmsor.size) ? pgmsor.size : @at + 10
      inside = pgmsor[from, to - from]
      err = "Found '#{@ch}' but expecting '#{lookfor_c}' close to '#{inside}' "
      STDERR.puts err
      raise(err)
    end
    in_any_next()
  end

  # ===============================

  def error(msg : String)
    raise msg
  end
end
