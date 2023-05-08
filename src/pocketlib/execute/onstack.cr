class Stack
  property the_stack : Array(OnStack) = [] of OnStack

  def initialize
  end

  def get_top
    return @the_stack[@the_stack.size - 1]
  end

  def get_below_top
    return @the_stack[@the_stack.size - 2]
  end

  def push(something)
    if something.is_a?(ConditionResult)
      something.isNumeric = false
    elsif something.is_a?(NumericValue)
      something.isNumeric = true
    elsif something.is_a?(LiteralValue)
      if x = something.value.to_f?
        something.isNumeric = true
      else
        something.isNumeric = false
      end
    elsif something.is_a?(ResultSet)
      if something.rows.size == 1      # have one row only
        if something.rows[0].size == 1 # have result from one table only
          if something.rows[0][0].size == 1
            the_one_and_only_column = something.rows[0][0][0]
            if x = the_one_and_only_column.to_f?
              value = NumericValue.new(the_one_and_only_column)
              something.isNumeric = true
            else
              something.isNumeric = false
            end
            something.value = the_one_and_only_column
          end
        end
      end
    elsif something.nil?
      raise "OnStack() push is nil"
    end
    @the_stack.push(something)
  end

  def pop
    @the_stack.pop
  end
end

class FileFile
  property filename : String
  property indexname : String

  def initialize(@filename, @indexname)
  end

  def to_num
    raise "No 'FileFile' to_num"
  end
end

class FileValues
  property asname : String
  property colnames : Array(String)

  def initialize(@asname, @colnames)
  end

  def to_num
    raise "No 'FileValues' to_num"
  end
end

class LiteralValue
  property value : String
  property isNumeric : Bool?

  def initialize(@value)
  end

  def to_num
    return @value.to_f32
  end

  def to_str
    @value
  end

  def dump
    to_s
  end

  def to_s(io : IO)
    io << "LiteralValue:" << @value
  end
end

class NumericValue
  property value : String
  property isNumeric : Bool?

  def initialize(@value)
  end

  def to_num
    return @value.to_f32
  end

  def to_str
    @value
  end

  def dump
    to_s
  end

  def to_s(io : IO)
    io << "NumericValue:" << @value
  end
end

class ParamName
  property value : String
  property isNumeric : Bool?

  def initialize(@value)
  end

  def to_num
    return @value.to_f32
  end

  def to_str
    @value
  end

  def dump
    to_s
  end

  def to_s(io : IO)
    io << "ParamName:" << @value
  end
end

class ConditionResult
  property value : Bool
  property isNumeric : Bool = false

  def initialize(@value)
  end

  def dump
    to_s
  end

  def to_str
    @value.to_s
  end

  def to_num
    raise "ConditionResult t-Num fails"
  end
end
