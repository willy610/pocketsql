class AggrFunc
  property kind : AggregateFunctionEnum
  private property value : String | Float32
  property count : Int32

  def initialize(kind : AggregateFunctionEnum | Nil)
    if kind.nil?
      raise "AggrFunc() new with 'nil'"
    end
    @kind = kind
    @value = 0.0
    @count = 0
    @sum = 0.0
    @sum2 = 0.0
    case @kind
    when AggregateFunctionEnum::AVG
    when AggregateFunctionEnum::MIN
      @value = Float32::MAX
    when AggregateFunctionEnum::MAX
      @value = Float32::MIN
    when AggregateFunctionEnum::SUM
    when AggregateFunctionEnum::COUNT
    when AggregateFunctionEnum::STDDEV
    end
  end

  def new_value(column_value)
    case @kind
    when AggregateFunctionEnum::AVG
      @value = ((@value * @count).to_f32 + column_value.to_f32) / (@count + 1).to_f32
      @count += 1
    when AggregateFunctionEnum::MIN
      if column_value.to_f32 < @value.to_f32
        @value = column_value.to_f32
      end
      self
    when AggregateFunctionEnum::MAX
      if column_value.to_f32 > @value.to_f32
        @value = column_value.to_f32
      end
      self
    when AggregateFunctionEnum::SUM
      @value = @value.to_f32 + column_value.to_f32
    when AggregateFunctionEnum::COUNT
      @value = @value.to_f32 + 1.0
    when AggregateFunctionEnum::STDDEV
      @count += 1
      @sum += column_value.to_f32
      @sum2 += (column_value.to_f32)**2
    else
      raise "AggrFunc::new_value() Unknown function '#{@kind}'"
    end
  end

  def get_value
    case @kind
    when AggregateFunctionEnum::STDDEV
      Math.sqrt((@sum2 * @count - @sum**2) / @count**2)
    else
      @value
    end
  end
end
# class StdDevAccumulator
#   def initialize
#     @count, @sum, @sum2 = 0, 0.0, 0.0
#     # @count, @sum, @sum2 = 0, 0.0, 0.0
#   end

#   def <<(num)
#     # @count += 1
#     # @sum += num
#     # @sum2 += num**2
#     # v1=Math.sqrt (@sum2 * @count - @sum**2) / @count**2
#     # v1
#     @count += 1
#     @sum += num
#     @sum2 += num**2
#     v2=Math.sqrt ((@sum2 * @count - @sum**2) / @count**2)
#     v2
#   end
# end

# sd = StdDevAccumulator.new
# i = 0
# [2,4,4,4,5,5,7,9].each { |n| puts "adding #{n}: stddev of #{i+=1} samples is #{sd << n}" }

