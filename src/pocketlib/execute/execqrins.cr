require "./tableinsert"

class ExecuteQr
  def qrins(qr : QR::QInsert, dest_tbl_obj)
    if qr_values = qr.values
      sor_rows = qr_values.rows.map { |aRow| aRow }
    end
    if qr_subq = qr.subq
      ret = self.subqr(qr_subq, outer_row: [] of OuterRow)
      sor_rows = ret.rows.map { |aRow| aRow[0] }
    end
    if !sor_rows.nil?
      if dest_tbl_obj.is_a?(ResultSet)
        sor_rows.each { |a_row|
          dest_tbl_obj.rows << [a_row]
        }
      elsif dest_tbl_obj.is_a?(Table)
        colnames = dest_tbl_obj.the_columns
        dest_tbl_obj.insert_rows(colnames, sor_rows)
      end
    end
    return nil
  end
end
