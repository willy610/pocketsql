module Grammars
   # GRAMMARGRAMMAR = [
  #   {rule: "Grammar", body: "Rule  +  ';' ; "},
  #   {rule: "Rule", body: "Identifier_Lx ':' Choice ';' ; "},
  #   {rule: "Choice", body: "Sequence ( '|' Sequence ) * ';' ;"},
  #   {rule: "Sequence", body: "( Primary Repeats_Lx ) + ; "},

  #   {rule: "Identifier_Lx", body: "Literal_Cs (Literal_Cs | Digit09_Cs | '_')* ;"},
  #   {rule: "Primary", body: "Identifier_Lx | DQString_Lx | ('[' CharSetExpr ']') | ('(' Choice ')') | CharLiteral_Lx ; "},
  #   {rule: "Repeats_Lx", body: %[ (
  #       Number_Lx
  #   | ( '*' | '+' )  Number_Lx ?
  #   |  '?'
  #   ) ]},
  #   {rule: "CharSetExpr", body: %[CharLiteral_Lx (('~' CharLiteral_Lx) | (','  CharLiteral_Lx) *) ;]},
  #   {rule: "Literal_Cs", body: "['a' ~ 'z'] | ['A' ~ 'Z'] ;"},
  #   {rule: "CharLiteral_Lx", body: %([' ' ~ '!' ] | [ '#' ~ '~' ] ;)},
  #   {rule: "CharSetExpr", body: %[CharLiteral_Lx (('~' CharLiteral_Lx) | (','  CharLiteral_Lx) *) ;]},
  #   {rule: "Digit09_Cs", body: "['0' ~ '9'] ;"},
  #   {rule: "Digit19_Cs", body: "['1' ~ '9'] ;"},
  #   {rule: "Number_Lx", body: %(Digit09_Cs *  ( Digit09_Cs * )? ;)},
  # ]

  GRAMMARSQL = [
    {rule: "Program", body: %( comments* with?
    (("SHOW" ("TABLES" | ( "TABLE" AS_TID))) 
    | "INSERT" insertbody 
    | "SELECT" projectbody orderby?  limit? 
    | "UPDATE" updatebody 
    | "DELETE" deletebody) ";" ;)},
    {rule: "comments", body: %["-- " fullrow_Lx ;]},
    {rule: "with", body: %[ "WITH" ((withplain,',')) ?  withrecur? ; ]},
    {rule: "withplain", body: %[  tablename "(" column_comma_list ")" "AS" "("  "SELECT" projectbody ")"  ; ]},
    {rule: "withrecur", body: %[ "RECURSIVE" tablename "(" column_comma_list ")" "AS" "(" "SELECT"  projectbody "UNION" "ALL"? "SELECT" projectbody ")" ; ]},
    {rule: "insertbody", body: %( "INTO" (Identifier_Lx | SQString_Lx tbl_col_alias) "(" column_comma_list ")" value_or_select ;)},
    {rule: "value_or_select", body: %( ("VALUES" value_list) | ("SELECT" projectbody) ;)},
    {rule: "updatebody", body: %( (Identifier_Lx | SQString_Lx tbl_col_alias) "SET" ( AS_CID "=" scalarexp ),',' whererule  ;)},
    {rule: "deletebody", body: %( "FROM" (Identifier_Lx | SQString_Lx tbl_col_alias) whererule ;)},
    {rule: "projectbody", body: %( "DISTINCT"? project "FROM" from whererule? window? groupby? having?  ;)},
    {rule: "from", body: %( table_ref  ;)},
    {rule: "table_ref", body: %( relation_body  joiner_or_setoper*  ;)},
    {rule: "relation_body", body: %( ( "(" relation_body ")" tbl_col_alias )
      | "VALUES" value_list tbl_col_alias?
      | "SELECT" projectbody
      | tablename tbl_col_alias?   ;)},

    {rule: "value_list", body: %( ( "(" ( DQString_Lx | SQString_Lx | Number_Lx ) ,',' ")" ),','   ;)},

    {rule: "tbl_col_alias", body: %("AS" AS_TID ( "(" column_comma_list ")" )?;)},

    {rule: "joiner_or_setoper", body: %(
      ( "," relation_body ) |
      ( ( "JOIN" | ( join_type "JOIN" ) ) relation_body onrule)
      | (("UNION" | "EXCEPT" | "INTERSECT") "ALL"?  relation_body)
      | ("CROSS" "JOIN" relation_body)
  ;)},

    {rule: "join_type", body: %("INNER"
      | ("LEFT" | "RIGHT" | "FULL") "OUTER" ?
      | "UNION"  ;)},

    {rule: "whererule", body: %{ "WHERE" fullcondexpr ; }},
    {rule: "onrule", body: %{ "ON" fullcondexpr ; }},
    {rule: "fullcondexpr", body: %{  pcondexpr andor * ; }},
    {rule: "andor", body: %{  ("AND" | "OR" ) pcondexpr  ; }},
    {rule: "pcondexpr", body: %{ (('(' condexpr ')') | condexpr )  ; }},
    {rule: "condexpr", body: %{ simplecond | '(' condexpr ')'  ; }},
    {rule: "simplecond", body: %( psimplecond compoper_Lx psimplecond  ; )},
    {rule: "psimplecond", body: %( scalarexp  |  ('(' scalarexp ')')  ; )},

    {rule: "scalarexp", body: %( nypscalarexp ( scalaroper_Lx nypscalarexp ) *  ; )},
    {rule: "nypscalarexp", body: %{ ("VALUES" value_list) | ( "(" scalarexpselectbodyorscalarexp ")" ) | scalarterm ; }},
    {rule: "scalarexpselectbodyorscalarexp", body: %{ ( "SELECT" projectbody ) |  scalarexp ; }},

    {rule: "scalarterm", body: %{
      standardfunction
      | DQString_Lx
      | SQString_Lx
      | Number_Lx
      | TID
      | Param_Lx
      ; }},
    {rule: "orderby", body: %( "ORDER" "BY" ( (Identifier_Lx | Number_Lx ) ("ASC" | "DESC")? ),','   ;)},
    {rule: "partby", body: %( "PARTITION" "BY" ( TID  ),','   ;)},
    {rule: "limit", body: %(  "LIMIT"     ( Number_Lx ("OFFSET" Number_Lx)? | ("," Number_Lx )? ); )},
    {rule: "window", body: %( "WINDOW"  AS_TID "AS" "("  partby? orderby? ")"   ;)},
    {rule: "groupby", body: %( "GROUP" "BY"   ( TID ),','   ;)},
    {rule: "having", body: %( "HAVING" fullcondexpr ;)},

    {rule: "project", body: %((("*" | (nyprojectitem ("AS" AS_CID)?),',' )) ("AS" AS_TID)? ;)},

    {rule: "nyprojectitem", body: %{ ( "(" projselectbodyorscalarexp ")" ) | simpleprojectitem ; }},
    {rule: "projselectbodyorscalarexp", body: %{ ( "SELECT" projectbody ) |  scalarexp ; }},

    {rule: "simpleprojectitem", body: %[ standardfunction | ( AS_TID ( (".*"  | "." AS_CID  ) )? | SQString_Lx | Number_Lx ) ; ]},
    {rule: "standardfunction", body: %[( "MIN" | "MAX" | "AVG" | "SUM" | "COUNT" | "STDDEV" | "TOUPPER"| "TOLOWER" ) "(" TID? ")"  over? ;]},
    {rule: "over", body: %{ "OVER" "(" AS_TID ")" orderby? ; }},
    {rule: "column_comma_list", body: %(AS_CID,',';)},
    {rule: "Literal_Cs", body: "['a' ~ 'z'] | ['A' ~ 'Z'] ;"},
    {rule: "Digit09_Cs", body: "['0' ~ '9'] ;"},
    {rule: "Digit19_Cs", body: "['1' ~ '9'] ;"},
    {rule: "AS_TID", body: " Identifier_Lx  ; "},
    {rule: "AS_CID", body: %(Identifier_Lx ;)},
    {rule: "TID", body: " Identifier_Lx '.' Identifier_Lx ; "},
  ]

  GRAMMARSQLSCHEMA = [
    {rule: "Createtable", body: %[  create ";" ;]},
    {rule: "create", body: %[
    "CREATE" "ENTITYTABLE"
    "(" enttable  +  ")"
     (
      "RELATIONSHIPTABLE" "(" reltable + ")"
      )? ;
      ]},
    {rule: "enttable", body: %[tablename entkey relcols? plaincols? ;]},
    {rule: "reltable", body: %[tablename relkey relcols? plaincols? ;]},
    {rule: "entkey", body: %["PRIMARYKEY" "("  (acolumn,',') + ")" ; ]},
    {rule: "relkey", body: %["PRIMARYKEY" "("
        "PARENTS" "("
          (  tablenameandmore,',' )+
        ")"
      ("OWNPRIMARY" "(" (acolumn,',') + ")" )?
       ")";]},
    {rule: "tablenameandmore", body: %[ tablename prefixed? sqlattribute? ;]},
    {rule: "prefixed", body: %[ "PREFIXED" SQString_Lx  ;]},
    {rule: "acolumn", body: %[ colname sqlattribute? ;]},
    {rule: "relcols", body: %[ "RELATIVECOLUMN" "(" (tablename prefixed?) ,',' ")" ;]},
    {rule: "plaincols", body: %[ "PLAINCOLUMN" "(" (acolumn,',')+ ")" ;]},
    {rule: "tablename", body: %[Identifier_Lx ;]},
    {rule: "colname", body: %[Identifier_Lx ;]},
    {rule: "Literal_Cs", body: "['a' ~ 'z'] | ['A' ~ 'Z'] ;"},
    {rule: "Digit09_Cs", body: "['0' ~ '9'] ;"},
    {rule: "Digit19_Cs", body: "['1' ~ '9'] ;"},
    {rule: "sqlattribute", body: " SQString_Lx ;"},
    {rule: "Identifier_Lx", body: "Literal_Cs (Literal_Cs | Digit09_Cs | '_')* ;"},

  ]
  GrammarDict = {sql: GRAMMARSQL, sqlschema: GRAMMARSQLSCHEMA}
end
