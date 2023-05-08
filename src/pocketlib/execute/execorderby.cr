class ExecuteQr
  def execorderby(orderby,
                  result_set : ResultSet,
                  rows : Array(ResultRow))
    order : Array(Int32) = [] of Int32
    # pp orderby
    order = orderby.map { |an_OrderBy|
      if column_number = an_OrderBy.column_number
        if an_OrderBy.ordering == "DESC"
          -column_number
        else
          column_number
        end
      elsif column_name = an_OrderBy.column_name
        column_number = result_set.colnames[0].index(column_name)
        if column_number.nil?
          raise "Order by() column '#{column_name}'not found "
        end
        if an_OrderBy.ordering == "DESC"
          -(column_number + 1)
        else
          (column_number + 1)
        end
      else
        raise "Order by() missing column"
      end
    }
    # puts order
    # order = [0, 1]
    # a final_result.rows is [[col1,col2,col3,...]]
    # puts final_result.rows[0]
    rows.sort! { |a, b|
      # puts a
      # puts b
      order_nr = 0
      x = while order_nr <= order.size - 1
        col_index = order[order_nr]
        if col_index > 0
          col_index = col_index - 1 # ASC
          begin
            break -1 if a[0][col_index].to_f < b[0][col_index].to_f
            break +1 if a[0][col_index].to_f > b[0][col_index].to_f
          rescue
            break -1 if a[0][col_index] < b[0][col_index]
            break +1 if a[0][col_index] > b[0][col_index]
          else
          end
        else
          col_index = -col_index - 1 # DESC
          begin
            break -1 if b[0][col_index].to_f < a[0][col_index].to_f
            break +1 if b[0][col_index].to_f > a[0][col_index].to_f
          rescue
            break -1 if b[0][col_index] < a[0][col_index]
            break +1 if b[0][col_index] > a[0][col_index]
          end
        end
        # continue with next column
        order_nr = order_nr + 1
      end
      # puts order_nr == order.size
      if order_nr == order.size
        # puts a
        # puts b
        x = 0 # duplicate!
        # else
        #   puts "no dup"
      end
      # puts x
      x
    }
    return rows
  end
end
