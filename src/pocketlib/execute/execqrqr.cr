class ExecuteQr
  def qrqr(qr : QR::Query)
    # the_cte = qr.cte
    if qr.cte_plain.size != 0
      the_cte = qr.cte_plain
    else
      the_cte = qr.cte_recur
    end
    # MERGE all CTE's. Plain first
    the_ctes = [qr.cte_plain, qr.cte_recur].flatten
    the_ctes.each { |one_cte_PPPPP|
      one_cte_real = one_cte_PPPPP
      if one_cte_real.is_a?(QR::QrPlainCTE)
        @db.add_cte_def("WITH(r_with)", one_cte_real.filename, one_cte_real.colnames)
        a_result_set = self.subqr(one_cte_real.instructions, outer_row: [] of OuterRow)
        if a_result_set.nil?
          raise "go() failed in 'QrPlainCTE'"
        end
        # we have the_cte.filename. look it up in fill rows
        table = @db.find_table(one_cte_real.filename)
        if !table.nil?
          table.rows = a_result_set.rows.map { |a_ResultRow| [a_ResultRow.flatten] }
        else
          raise "go() Cannot find file '#{one_cte_real.filename}' "
        end
        # DROP TABLE WHEN DONE ??? !!!
      elsif one_cte_real.is_a?(QR::QRWithRecur)
        part_result_rows : Array(ResultRow) = [] of ResultRow
        if cte_first = one_cte_real.first
          dest_table = @db.find_table(one_cte_real.cte_tablename)
          if dest_table.nil?
            raise "go() Unknown dest table in recursive "
          end
          first_result_set = self.subqr(cte_first, outer_row: [] of OuterRow)
          first_result_set.rows.each { |arow|
            if !dest_table.nil?
              part_result_rows << arow
            end
          }
          dest_table.rows = first_result_set.rows
          found_size = first_result_set.rows.size
          limit = 100
          if cte_second = one_cte_real.second
            while limit > 0 && found_size > 0
              second_result_set = self.subqr(cte_second, outer_row: [] of OuterRow)
              found_size = second_result_set.rows.size
              if found_size > 0
                second_result_set.rows.each { |arow|
                  if !dest_table.nil?
                    part_result_rows << arow
                  end
                }
                dest_table.rows = second_result_set.rows
              end
              limit -= 1
            end
          else
            raise " the_cte.second nil"
          end
          dest_table.rows = part_result_rows
        else
          raise " the_cte.first nil"
        end
      end
    }
    if a_QShow = qr.show_table
      # puts "!" + __FILE__ + ":" + __LINE__.to_s
      # pp a_QShow
      return exec_show_table(a_QShow)
    end
    the_subq = qr.subq
    if !the_subq
      puts "MISSING the_subq"
      raise "MISSING the_subq"
    end
    the_proj = the_subq.project
    if !the_proj
      puts "MISSING project"
      raise "MISSING project"
    end
    result_set = self.subqr(the_subq, outer_row: [] of OuterRow)
    if orderby = qr.orderby
      order : Array(Int32) = [] of Int32
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
      result_set.rows.sort! { |a, b|
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
        if order_nr == order.size
          x = 0 # duplicate!
        end
        x
      }
    end
    # limit
    if limit = qr.limit
      from : Int32 = limit.offset.to_i32
      to : Int32 = 0
      if limit.row_count.size == 0
        to = result_set.rows.size - 1
      else
        to = from + limit.row_count.to_i32 - 1
        if to >= result_set.rows.size
          to = result_set.rows.size - 1
        end
      end
      # result_set.rows = (from..to).map { |i| result_set.rows[i] }
      result_set.rows = result_set.rows[from, to]
    end
    return result_set
  end
end
