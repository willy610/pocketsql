require "../pocketlib/parse"
require "../pocketlib/parse/parsesqlextended"
require "../pocketlib/parse/parsequery"
require "../pocketlib/compile/compileast"

class VerifyRecipe < Verify
  def self.verify(db : DBSchema)
    sql = [
      "SHOW TABLES ;",
      "SHOW TABLE Livsmedel;",

      "-- What kategory has no recipe
      SELECT DISTINCT Kategori.Kategori FROM Kategori WHERE
      Kategori.Kategori NOT IN (SELECT DISTINCT Kategori.Kategori FROM KategoriOchRecept) ;
      ",
      " -- What recipe is not in any category
      SELECT DISTINCT Recept.Recept FROM Recept WHERE
      Recept.Recept NOT IN (SELECT DISTINCT Recept.Recept FROM KategoriOchRecept) ;
      ",
      "-- What ingredients is not in use
      SELECT DISTINCT Livsmedel.Livsmedel FROM Livsmedel WHERE
      Livsmedel.Livsmedel NOT IN (SELECT DISTINCT Receptstegsingrediens.Livsmedel FROM Receptstegsingrediens) ;
      ",
      "SELECT Derived.MAXXX FROM
        ( SELECT MAX(Receptsteg.Steg) FROM Receptsteg WHERE Receptsteg.Recept = 'Aioli' )
        AS Derived (MAXXX) ;",

      "SELECT MAX(Receptsteg.Steg)  FROM Receptsteg WHERE Receptsteg.Recept = 'Aioli'; ",

      "SELECT (MAX(Receptsteg.Steg) + 1) FROM Receptsteg WHERE Receptsteg.Recept = 'Aioli'; ",

      "INSERT INTO Kategori(Kategori,Kategoribeskrivning)
          VALUES ('Kat1','Beskr1'),('Kat2','Beskr2') ; ",
      "SELECT * FROM Kategori ; ",

      "DELETE FROM Kategori WHERE Kategori.Kategori LIKE 'Ka%'  ; ",

      "UPDATE Kategori SET Kategoribeskrivning = 'Kalle' WHERE Kategori.Kategori LIKE 'Ka%'  ; ",

      "SELECT * FROM Kategori WHERE Kategori.Kategoribeskrivning != ''; ",

      "SELECT DISTINCT Recept.Recept,Recept.AntalPortioner
          FROM Recept
          JOIN KategoriOchRecept
          ON Recept.Recept = KategoriOchRecept.Recept
          WHERE KategoriOchRecept.Kategori = 'Fisk' ; ",
      "-- Produce a buy list for a certain recipe
      SELECT
        Receptstegsingrediens.Livsmedel,
        Receptstegsingrediens.Enhet,
        SUM(Receptstegsingrediens.Antal) AS SUM_Antal,
        COUNT(Receptstegsingrediens.Antal) AS COUNT_Antal
      FROM
        Receptsteg
        JOIN Receptstegsingrediens ON Receptsteg.Recept = Receptstegsingrediens.Recept
        AND Receptsteg.Steg = Receptstegsingrediens.Steg
      WHERE
        Receptsteg.Recept = 'Currykyckling'
      GROUP BY
        Receptstegsingrediens.Livsmedel,
        Receptstegsingrediens.Enhet
      ORDER BY
        Livsmedel ;
      ",
    ]

    sql.each { |sql|
      x = Parse.new.parseQuery(sql)
      if !x.nil?
        puts sql
        code = CompileAst.new(db).go(x.data[0])
        result = ExecuteQr.new(db).go(code)
        if !result.nil?
          puts result.to_s
        end
      end
    }
    db.save_to_dir("./tempsave")
    return self, "OK"
  end
end
