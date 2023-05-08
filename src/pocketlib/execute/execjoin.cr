alias IterCSV = Array(Array(Array(String)))
alias ResultSetAndCSVIter = {the_result_set: ResultSet, iter: IterCSV}

class ExecuteQr
  def join_it(outer_row : Array(OuterRow), the_from : QR::QRFirstJoin,
              extra_where : QR::QRWhere?)
    # START HERE
    # =====================================================
    # puts "!" + __FILE__ + ":" + __LINE__.to_s
    # pp the_from

    latest_iter_allt = get_an_iter(the_from.first_from)
    #
    the_from.more_from.each_with_index { |an_QRMoreJoin, i|
      if now_QRMoreJoin = an_QRMoreJoin
        if an_QRMoreJoin_from = an_QRMoreJoin.from
          next_iter_allt = get_an_iter(an_QRMoreJoin_from)
          next_iter = next_iter_allt[:the_result_set]
          if an_QRMoreJoin_join_on = an_QRMoreJoin.join_on
            latest_iter_allt = join_more(the_join_cover: an_QRMoreJoin.join_cover,
              in_AAA_outer_row: outer_row,
              iter_first_all: latest_iter_allt,
              iter_second_all: next_iter_allt,
              where: an_QRMoreJoin_join_on,
              last_join: i == the_from.more_from.size - 1,
              extra_where: extra_where)
          else
            raise "join_it() no 'an_QRMoreJoin.from' "
          end
        else
          raise "join_it() no 'join_on"
        end
      end
    }
    return latest_iter_allt[:the_result_set]
  end

  # =====================================================

  def get_an_iter(a_QRJoiner_from : QR::QFrom) : ResultSetAndCSVIter
    # puts "!" + __FILE__ + ":" + __LINE__.to_s
    # pp a_QRJoiner_from

    if the_from = a_QRJoiner_from.from_QrLoadFileFile
      the_table = @db.add_csv_table(
        the_from.loadfilename,
        the_from.colnames,
        the_from.filename)
      return {the_result_set: the_table, iter: the_table.rows.map { |aRow| aRow }}
      #
    elsif the_from = a_QRJoiner_from.from_QRLoadFileValues
      the_table = @db.add_value_table("KIND",
        the_from.filename,
        the_from.colnames,
        the_from.rows)
      return {the_result_set: the_table, iter: the_table.rows.map { |aRow| aRow }}
      #
    elsif the_from = a_QRJoiner_from.from_QRLoadFromStore
      the_table = @db.find_table(the_from.tablename)
      if !the_table.nil?
        return {the_result_set: the_table, iter: the_table.rows.map { |aRow| aRow }}
      else
        raise "get_an_iter() Table '#{the_from.tablename}' not found"
      end
    elsif the_from = a_QRJoiner_from.from_SubQuery
      result_set = ExecuteQr.new(@db).subqr(the_from, outer_row: [] of OuterRow)
      if a_QRJoiner_from_derived_as = the_from.derived_as
        result_set.tablenames[0] = a_QRJoiner_from_derived_as.as_tablename
        result_set.colnames[0] = a_QRJoiner_from_derived_as.as_colnames
      else
        raise "get_an_iter() (Subquery) Derived table must have a name and columns"
      end
      @db.add_result_set(result_set)
      the_table = @db.find_table(result_set.tablenames[0])
      if !the_table.nil?
        {the_result_set: the_table, iter: the_table.rows.map { |aRow| aRow }}
      else
        raise "WAIT"
      end
    else
      raise "join_it() get_an_iter() Wrong 'a_QRJoiner_from' #{a_QRJoiner_from}"
    end
  end

  # =====================================================

  private def join_more(the_join_cover : String,
                        in_AAA_outer_row : Array(OuterRow),
                        iter_first_all : ResultSetAndCSVIter,
                        iter_second_all : ResultSetAndCSVIter,
                        where : QR::QRWhere?,
                        last_join : Bool,
                        extra_where : QR::QRWhere?)
    # Whats to pass to 'exec_where' 'join_on'
    # From outer: AAAA's one or more
    # From left : BBBB's one if left is TableReader several if left is ResultSet
    # From right : CCCC (Right is assumed to be a TableReader?)
    # we pass AAAs + BBBs + CCC to 'where'
    # on positive where
    # we have a result of AAAs + BBBs + CCC
    # or we have AAAs + BBBs + null's in case of LEFT JOIN

    result = ResultSet.new

    first_resset = iter_first_all[:the_result_set]
    nr_result_tables = first_resset.tablenames.size
    first_BBB_SuperRows = (0...nr_result_tables - 0).map { |i|
      result.tablenames << first_resset.tablenames[i]
      result.colnames << first_resset.colnames[i]
      OuterRow.new(first_resset.tablenames[i], first_resset.colnames[i], [] of String)
    }
    second_null_row = [] of TableRow
    second_resset = iter_second_all[:the_result_set]
    second_CCC_SuperRow = (0...second_resset.tablenames.size - 0).map { |i|
      result.tablenames << second_resset.tablenames[i]
      result.colnames << second_resset.colnames[i]
      second_null_row << Array.new(second_resset.colnames[i].size) { "null" }
      OuterRow.new(second_resset.tablenames[i], second_resset.colnames[i], [] of String)
    }
    second_null_row = Array.new(3) { "null" }

    iter_first_all[:iter].each { |an_BBB_row|
      #
      # Pick from row content outer
      #
      the_ABC_row = in_AAA_outer_row.dup
      #
      # Pick row content from left (first) row
      #
      first_BBB_SuperRows.each_with_index { |a_row, i|
        first_BBB_SuperRows[i].the_row = an_BBB_row[i]
        the_ABC_row.push(first_BBB_SuperRows[i])
      }

      found_inner : Bool = false
      #
      # Pick from second (right) row
      #
      iter_second_all[:iter].each { |an_CCC_row|
        second_CCC_SuperRow.each_with_index { |a_row, i|
          second_CCC_SuperRow[i].the_row = an_CCC_row[i]
          the_ABC_row.push(second_CCC_SuperRow[i])
        }
        #
        # Now filter this join
        #
        res = exec_where(the_ABC_row, where)
        if res.is_a?(ConditionResult)
          if res.value == true
            #
            # Now also check with a where-clause
            #
            accept_outmost_where = true
            if last_join
              if outer_where = extra_where
                res_where = exec_where(the_ABC_row, outer_where)
                # pp the_ABC_row
                # pp outer_where
                if res_where.is_a?(ConditionResult)
                  if res_where.value == true
                    # puts "KEEP"
                  else
                    # puts "DISMISS"
                    accept_outmost_where = false
                  end
                else
                  raise "join_more() Outer where results wrong type"
                end
              end
            end
            #
            if accept_outmost_where
              x = an_BBB_row # [[1,2,..],[3,4,5,6,..]]
              x += an_CCC_row.map { |a| a }
              # x is now [[1,2,..],[3,4,5,6,..],[a,v,f,..]]
              result.rows << x   # INNER JOIN
              found_inner = true # at least one row
            end
          else
            # puts "NO MATCH"
          end
          #
          # Drop last (C) from the_ABC_row
          # Keep OuterRow + B
          #
          the_ABC_row.pop(second_CCC_SuperRow.size)
        else
          raise "() exec_where must produce true/false"
        end
      }
      if !found_inner && the_join_cover == "LEFT"
        x = an_BBB_row # [[1,2,..],[3,4,5,6,..]]
        x << second_null_row
        # x is now [[1,2,..],[3,4,5,6,..],["null","null","null",..]]
        result.rows << x # LEFT JOIN
      end
    }
    return {the_result_set: result, iter: result.rows.map { |r| r }}
  end
end
