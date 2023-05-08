alias TblName = String
alias ColName = String
alias ColValue = String
# alias ColValue = String | Nil
alias RowId = Int32
alias PkValue = Array(ColValue)
enum AttribPlainOrParentEntity
  Plain
  ParentEntity
end
enum TableType
  Entity
  Relation
end
alias ToRealtiveChild = {to_child_table: TblName, to_child_columns: Array(ColName)}
alias ToRealtiveChildObject = {to_child_table_obj: Table, to_child_columns: Array(ColName)}
# alias FkFromTabelToTable = {from_table: String, to_table: String}
