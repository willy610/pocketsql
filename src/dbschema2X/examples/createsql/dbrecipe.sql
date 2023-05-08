DROP TABLE IF EXISTS `ReplaceIngred`;
DROP TABLE IF EXISTS `Receptstegsingrediens`;
DROP TABLE IF EXISTS `Receptsteg`;
DROP TABLE IF EXISTS `KategoriOchRecept`;
DROP TABLE IF EXISTS `Recept`;
DROP TABLE IF EXISTS `Kategori`;
DROP TABLE IF EXISTS `Livsmedel`;
CREATE TABLE `Livsmedel` (
  `Livsmedel` varchar(100),
  PRIMARY KEY ( `Livsmedel` ),
  `kcal` int(11),
  `notering` varchar(253),
  `pris` float
);

CREATE TABLE `Kategori` (
  `Kategori` varchar(30),
  PRIMARY KEY ( `Kategori` ),
  `Kategoribeskrivning` varchar(255)
);

CREATE TABLE `Recept` (
  `Recept` varchar(50),
  PRIMARY KEY ( `Recept` ),
  `AntalPortioner` int(11) null,
  `TillagningsTid` int(11) null,
  `Ursprung` varchar(100),
  `Beskrivning` varchar(10)
);

CREATE TABLE `KategoriOchRecept` (
  `Kategori` varchar(30),
  CONSTRAINT `fk_KategoriOchRecept__Kategori`
     FOREIGN KEY (Kategori)
     REFERENCES `Kategori` (Kategori),
  INDEX parent_index_Kategori (Kategori),
  `Recept` varchar(50),
  CONSTRAINT `fk_KategoriOchRecept__Recept`
     FOREIGN KEY (Recept)
     REFERENCES `Recept` (Recept),
  INDEX parent_index_Recept (Recept),
PRIMARY KEY (Kategori,Recept)
);

CREATE TABLE `Receptsteg` (
  `Recept` varchar(50),
  CONSTRAINT `fk_Receptsteg__Recept`
     FOREIGN KEY (Recept)
     REFERENCES `Recept` (Recept),
  INDEX parent_index_Recept (Recept),
  `Steg` varchar(3),
  `Kortbeskrivning` varchar(20),
  `Minuter` int(11),
  `Beskrivning` varchar(253),
PRIMARY KEY (Recept,Steg)
);

CREATE TABLE `Receptstegsingrediens` (
  `Recept` varchar(50),
  `Steg` varchar(3),
  CONSTRAINT `fk_Receptstegsingrediens__Receptsteg`
     FOREIGN KEY (Recept,Steg)
     REFERENCES `Receptsteg` (Recept,Steg),
  INDEX parent_index_Recept_Steg (Recept,Steg),
  `Livsmedel` varchar(100),
  CONSTRAINT `fk_Receptstegsingrediens__Livsmedel`
     FOREIGN KEY (Livsmedel)
     REFERENCES `Livsmedel` (Livsmedel),
  INDEX parent_index_Livsmedel (Livsmedel),
  `Antal` float,
  `Enhet` varchar(32),
PRIMARY KEY (Recept,Steg,Livsmedel)
);

CREATE TABLE `ReplaceIngred` (
  `Livsmedel` varchar(100),
  CONSTRAINT `fk_ReplaceIngred__Livsmedel`
     FOREIGN KEY (Livsmedel)
     REFERENCES `Livsmedel` (Livsmedel),
  INDEX parent_index_Livsmedel (Livsmedel),
  `NYTT_Livsmedel` varchar(100),
  CONSTRAINT `fk_ReplaceIngred_NYTT__Livsmedel`
     FOREIGN KEY (NYTT_Livsmedel)
     REFERENCES `Livsmedel` (Livsmedel),
  INDEX parent_index_NYTT_Livsmedel (NYTT_Livsmedel),
  `pref_Kategori` varchar(30),
  `pref_Recept` varchar(50),
  CONSTRAINT `fk_ReplaceIngred_pref__KategoriOchRecept`
     FOREIGN KEY (pref_Kategori,pref_Recept)
     REFERENCES `KategoriOchRecept` (Kategori,Recept),
  INDEX parent_index_pref_Kategori_pref_Recept (pref_Kategori,pref_Recept),
  `FOM` float,
PRIMARY KEY (Livsmedel,NYTT_Livsmedel)
);
