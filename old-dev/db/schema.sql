DROP table IF exists stocks;
CREATE TABLE stocks ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "ticker" varchar NOT NULL, "shares" integer NOT NULL, "avgcost" float NOT NULL, "last" float NOT NULL, "mktvalue" float NOT NULL, "mktvaluecible" float NOT NULL, "order" varchar NOT NULL);
