class ExecuteQr
    def exec_show_table(a_QShow : QR::QShow) 
        if a_QShow.all_tables == true
            x = @db.all_tables_as_result
            return x
        elsif a_QShow.one_table.size !=0
            x = @db.one_table_as_result(a_QShow.one_table)
        else
           raise "exec_show_table () either one or all tables requested " 
        end
    end
end