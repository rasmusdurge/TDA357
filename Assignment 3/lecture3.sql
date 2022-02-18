/*
--  psql -v ON_ERROR_STOP=1 -U postgres portal
*/

-- OBS: Deletes everything!
\c portal
\set QUIT true
SET client_min_messages TO WARNING;
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
\set QUIET false


---------------------- Recall running table ---------------------
-- We should have the data inserted in the table in lecture 2 for the queries

-- Recall table
CREATE TABLE Countries(
  name TEXT PRIMARY KEY,
  abbr CHAR(2) NOT NULL UNIQUE,
  capital TEXT NOT NULL,
  area FLOAT NOT NULL,
  population INT NOT NULL CHECK (population >= 0),
  continent CHAR(2) NOT NULL,
  currency CHAR(3));

INSERT INTO Countries
VALUES ('Denmark', 'DK', 'Copenhagen', 43094, 5484000, 'EU', 'DKK');
INSERT INTO Countries
VALUES ('Sweden', 'SE', 'Stockholm' , 449964, 9555893, 'EU', 'SEK');
INSERT INTO Countries
VALUES ('Estonia', 'EE', 'Tallinn', 45226, 1291170, 'EU', 'EUR');
INSERT INTO Countries
VALUES ('Finland', 'FI', 'Helsinki', 337030, 5244000, 'EU', 'EUR');
INSERT INTO Countries
VALUES ('Norway', 'NO', 'Oslo', 324220.5, 5009150, 'EU', 'NOK');
INSERT INTO Countries
VALUES ('Uruguay', 'UY', 'Montevideo' , 176215, 3518552, 'AM', 'UYU');
INSERT INTO Countries
VALUES ('Ecuador', 'EC', 'Quito' , 283561, 17084358, 'AM', 'USD');
INSERT INTO Countries
VALUES ('Argentina', 'AR', 'Buenos Aires' , 2780400, 44938712, 'AM', 'ARS');

SELECT * FROM Countries;


---------------------- Local definitions ------------------------

SELECT *
FROM (SELECT name, CEIL(population/area) AS density
      FROM Countries) AS Densities
ORDER BY density DESC
LIMIT 5;

/* Doesn't work without the aliasing
SELECT *
FROM (SELECT name, CEIL(population/area) AS density
      FROM Countries) 
ORDER BY density DESC
LIMIT 5;
*/

WITH Densities AS
      (SELECT name, FLOOR(population/area) AS density
       FROM Countries)
SELECT *
FROM Densities
ORDER BY density DESC
LIMIT 5;


---------------------- Views Views ------------------------

CREATE VIEW Densities AS
  (SELECT name, population/area AS density FROM Countries);

SELECT * FROM Densities;

/*
-- Will not work
CREATE OR REPLACE VIEW Densities AS
  (SELECT name, abbr, population/area AS density FROM Countries);

CREATE OR REPLACE VIEW Densities AS
  (SELECT name, abbr AS density, population/area AS density FROM Countries);
*/

-- I need to instead put abbr after
CREATE OR REPLACE VIEW Densities AS
  (SELECT name, population/area AS density, abbr FROM Countries);
  
SELECT name FROM Densities
ORDER BY density DESC
LIMIT 3;

SELECT name, abbr FROM Densities
ORDER BY density ASC
LIMIT 3;

DROP VIEW Densities;


---------------------- Materialized Views ------------------------

CREATE MATERIALIZED VIEW MDensities AS
  (SELECT name, population/area AS density FROM Countries);

SELECT * FROM MDensities;

INSERT INTO Countries
VALUES ('Salvador', 'SA', 'Salvador', 134567, 7000000, 'AM', 'SAP');

SELECT * FROM MDensities;

REFRESH MATERIALIZED VIEW MDensities;

SELECT * FROM MDensities;

DROP MATERIALIZED VIEW MDensities;


---------------------- Set operation: Union ------------------------

-- Set union!!
SELECT currency FROM Countries WHERE continent = 'AM'
UNION 
SELECT currency FROM Countries WHERE continent = 'EU';

-- Compare with
SELECT DISTINCT currency FROM Countries WHERE continent IN ('AM', 'EU');

-- If we want even the duplicates elements in the
SELECT currency FROM Countries WHERE continent = 'AM'
UNION ALL 
SELECT currency FROM Countries WHERE continent = 'EU';

-- Compare with
SELECT currency FROM Countries WHERE continent IN ('AM', 'EU');


-- Union: more examples 

-- These queries make no sense but it is just to see the result of UNION
SELECT name, currency FROM Countries WHERE continent = 'AM'
UNION 
SELECT name, currency FROM Countries WHERE continent = 'AM';

SELECT name, currency FROM Countries WHERE continent = 'AM'
UNION ALL
SELECT name, currency FROM Countries WHERE continent = 'AM';

/*
-- Will not work since selected attributes needs to have compatible types
SELECT area FROM Countries 
UNION
SELECT name FROM Countries WHERE currency = 'USD';
*/

-- will put "max" as name of the column if we don't give it a name
SELECT MAX(population) AS max_min_pop FROM Countries
UNION
SELECT MIN(population) AS max_min_pop FROM Countries;

-- Will classifiy each country as small or big
SELECT name, 'small' AS size FROM Countries WHERE area < 300000
UNION
SELECT name, 'big' AS size FROM Countries WHERE area >= 300000;


---------------------- Set operation: Intersection ------------------------

-- We need to insert other values for these queries
-- to give an interesting result

INSERT INTO Countries
VALUES ('NewSalvador', 'NS', 'Salvador', 134567, 10000000, 'AM', 'SAP');
INSERT INTO Countries
VALUES ('NewSweden', 'SN', 'Sweden', 453627, 17352648, 'EU', 'NSK');

SELECT * FROM Countries;

SELECT name AS place FROM Countries
INTERSECT
SELECT capital AS place FROM Countries;

-- Is this the same as the query above?
SELECT name FROM Countries WHERE name = capital;

-- Recall that results needs to be included in each subqueries
-- That is why Salvador only occurs once in the result but twice in a subquery
SELECT name AS place FROM Countries
INTERSECT ALL
SELECT capital AS place FROM Countries;

-- Doesn't make too much sense but keeps the duplicates :-)
SELECT capital AS place FROM Countries
INTERSECT ALL
SELECT capital AS place FROM Countries;

-- We remove the "extra" data
DELETE FROM Countries WHERE name IN ('NewSalvador', 'NewSweden', 'Salvador');


---------------------- Set operation: Difference ------------------------

SELECT currency FROM Countries
EXCEPT 
SELECT currency FROM Countries WHERE currency != 'EUR';

SELECT DISTINCT currency FROM Countries WHERE currency = 'EUR';

SELECT currency FROM Countries
EXCEPT ALL
SELECT currency FROM Countries WHERE currency != 'EUR';

SELECT currency FROM Countries WHERE currency = 'EUR';


---------------------- Complex query making no sense :-) ---------------------

WITH
  ManyPeople AS
    (SELECT name, area, 'many' AS size FROM Countries
     WHERE population >= 10000000),
  FewPeople AS
    (SELECT name, area, 'few' AS size FROM Countries
     WHERE population < 6000000)
(-- Removes American countries from FewPeople
 SELECT name, size FROM FewPeople
 EXCEPT
 SELECT name, 'few' FROM Countries WHERE continent = 'AM')
UNION  -- puts the results together 
(-- Keeps countries with big area from ManyPeople
 SELECT name, size FROM ManyPeople
 INTERSECT
 SELECT name, 'many' FROM Countries WHERE area > 2500000);


---------------------- Adding a new table and values ---------------------

-- New table 
-- Schema: Currencies (_code_, name, value) 
CREATE TABLE Currencies(
  code CHAR(3) PRIMARY KEY,
  name TEXT,
  value FLOAT);

INSERT INTO Currencies VALUES ('SEK','Swedish Krona', 1.00);
INSERT INTO Currencies VALUES ('DKK','Danish Krone', 1.36);
INSERT INTO Currencies VALUES ('EUR','Euro', 10.17);
INSERT INTO Currencies VALUES ('ARS','Peso Argentino', 0.1);
INSERT INTO Currencies VALUES ('UYU','Peso Uruguayo', 0.2);
INSERT INTO Currencies VALUES ('USD','Dollar', 8.28);
INSERT INTO Currencies VALUES ('BTC','Bitcoin', 85634.34);

-- Which currency from a country is not in this table?
SELECT DISTINCT currency AS code
FROM Countries
WHERE currency NOT IN (SELECT code FROM Currencies);


---------------------- Querrying several tables ---------------------

SELECT Countries.name, code, Currencies.name, value
FROM Countries, Currencies
WHERE currency = code;

/*
-- Will not work: which column named "name" needs to be output?
SELECT name, code, value
FROM Countries, Currencies
WHERE currency = code;
*/


---------------------- Join = INNER Join -------------------------
-- These querries are equivalent to the previous
-- Only matching rows in the output

SELECT Countries.name, code, Currencies.name, value
FROM Countries JOIN Currencies ON currency=code;

SELECT Countries.name, code, Currencies.name, value
FROM Countries INNER JOIN Currencies ON currency=code;


---------------------- Outer Join -------------------------

-- All currencies even if no country uses it
SELECT Countries.name, code, Currencies.name, value
FROM Countries RIGHT OUTER JOIN Currencies ON currency=code;

-- All countries, even if the currency is missing
SELECT Countries.name, code, Currencies.name, value
FROM Countries LEFT OUTER JOIN Currencies ON currency=code;

-- Compare with
SELECT Countries.name, currency, Currencies.name, value
FROM Countries LEFT OUTER JOIN Currencies ON currency=code;

-- Info from all rows in both tables
SELECT Countries.name, code, Currencies.name, value
FROM Countries FULL OUTER JOIN Currencies ON currency=code;

-- Compare with
SELECT Countries.name, currency, Currencies.name, value
FROM Countries FULL OUTER JOIN Currencies ON currency=code;


---------------------- Natural Join -------------------------
-- Joins are done on the columns with the same name
-- OBS: Types have to be comparable

CREATE TABLE Capitals (
  country TEXT PRIMARY KEY,
  capital TEXT);

CREATE TABLE CurrencyCodes (
  country TEXT PRIMARY KEY,
  currency CHAR(3));


INSERT INTO Capitals VALUES ('Sweden', 'Stockholm');
INSERT INTO Capitals VALUES ('Norway', 'Oslo');
INSERT INTO Capitals VALUES ('France', 'Paris');

INSERT INTO CurrencyCodes VALUES ('Sweden', 'SEK');
INSERT INTO CurrencyCodes VALUES ('Norway', 'NOK');
INSERT INTO CurrencyCodes VALUES ('Germany', 'EUR');

SELECT * FROM Capitals;

SELECT * FROM CurrencyCodes;


-- Inner join is the default, the INNER keyword can be omitted
SELECT * FROM Capitals, CurrencyCodes
WHERE Capitals.country = CurrencyCodes.country;

SELECT * FROM Capitals JOIN CurrencyCodes USING (country);

SELECT * FROM Capitals NATURAL INNER JOIN CurrencyCodes;

SELECT * FROM Capitals NATURAL JOIN CurrencyCodes;

-- Outer joins (the OUTER keyword can be omitted) 
SELECT * FROM Capitals NATURAL LEFT OUTER JOIN CurrencyCodes;
SELECT * FROM Capitals NATURAL LEFT JOIN CurrencyCodes;

SELECT * FROM Capitals NATURAL RIGHT OUTER JOIN CurrencyCodes;
SELECT * FROM Capitals NATURAL RIGHT JOIN CurrencyCodes;

SELECT * FROM Capitals NATURAL FULL OUTER JOIN CurrencyCodes;
SELECT * FROM Capitals NATURAL FULL JOIN CurrencyCodes;


---------------------- Playing with Outer Join -------------------------

-- Left outer
SELECT *
FROM Capitals LEFT OUTER JOIN CurrencyCodes
ON (Capitals.country = CurrencyCodes.country);

-- Compare with
SELECT *
FROM Capitals LEFT OUTER JOIN CurrencyCodes USING (country);

-- Right outer
SELECT *
FROM Capitals RIGHT OUTER JOIN CurrencyCodes
ON (Capitals.country = CurrencyCodes.country);

-- Compare with
SELECT *
FROM Capitals RIGHT OUTER JOIN CurrencyCodes USING (country);

-- Full outer
SELECT *
FROM Capitals FULL OUTER JOIN CurrencyCodes
ON (Capitals.country = CurrencyCodes.country);

-- Compare with
SELECT *
FROM Capitals FULL OUTER JOIN CurrencyCodes USING (country);

-- And with this
SELECT Capitals.country, capital, currency
FROM Capitals FULL OUTER JOIN CurrencyCodes USING (country);

-- And this
SELECT CurrencyCodes.country, capital, currency
FROM Capitals FULL OUTER JOIN CurrencyCodes USING (country);


---------------------- Empty values: Three value logic -----------------------

SELECT TRUE OR 'o' = NULL;
SELECT 'o' = NULL OR TRUE;
SELECT TRUE AND 'o' = NULL;
SELECT FALSE OR 'o' = NULL;
SELECT FALSE AND 'o' = NULL;
SELECT 'o' = NULL AND FALSE;
SELECT NULL = NULL;


---------------------- Exists / Not Exists -------------------------

-- Selects all currencies used in some country
SELECT code, Currencies.name FROM Currencies
WHERE EXISTS (SELECT * FROM Countries WHERE currency = code);

SELECT code, Currencies.name FROM Currencies
WHERE code IN (SELECT currency FROM Countries);

-- Selects all currencies not used in a country
SELECT code, Currencies.name FROM Currencies
WHERE NOT EXISTS (SELECT * FROM Countries WHERE currency = code);

SELECT code, Currencies.name FROM Currencies
WHERE code NOT IN (SELECT currency FROM Countries);


---------------------- Getting rid of empty values -------------------------

SELECT country, COALESCE(capital, 'no capital'),
       COALESCE(currency, 'no currency')
FROM Capitals NATURAL FULL JOIN CurrencyCodes;

SELECT country, COALESCE(capital, 'no capital') AS capital,
       COALESCE(currency, 'no currency') AS currency
FROM Capitals NATURAL FULL JOIN CurrencyCodes;
