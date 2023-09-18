-- ----------------------------------------- Analyzing Road Safety in the UK ------------------------------------------

DROP DATABASE IF EXISTS ukroadsafety;

CREATE DATABASE ukroadsafety;
USE ukroadsafety;

DROP TABLE IF EXISTS accident;

CREATE OR REPLACE TABLE accident 
(
	Accident_Index VARCHAR(20) NOT NULL,
	Location_Easting_OSGR INTEGER,
	Location_Northing_OSGR INTEGER,
	Longitude DECIMAL(8,6),
	Latitude DECIMAL(9,6),
	Police_Force SMALLINT ,
	Accident_Severity SMALLINT,
	Number_of_Vehicles SMALLINT,
	Number_of_Casualties SMALLINT,
	Date DATE,            -- yyyy-mm_dd (IN exCEL IT IS IN dd-mm-yyyy)
    Day_of_Week CHAR(2),
	Time TIME,
    Local_Authority_District SMALLINT,
	Local_Authority_Highway CHAR(12),
	`1st_Road_Class` SMALLINT,
    `1st_Road_Number` SMALLINT,
    Road_Type SMALLINT,
	Speed_limit SMALLINT,
	Junction_Detail SMALLINT,
	Junction_Control CHAR(2),
	`2nd_Road_Class` CHAR(2),
	`2nd_Road_Number` SMALLINT,
	Pedestrian_Crossing_Human_Control CHAR(2), 
	Pedestrian_Crossing_Physical_Facilities CHAR(2),
	Light_Conditions CHAR(2),
    Weather_Conditions CHAR(2),
    Road_Surface_Conditions	CHAR(2),
    Special_Conditions_at_Site	CHAR(2),
    Carriageway_Hazards	CHAR(2),
    Urban_or_Rural_Area	CHAR(2),
    Did_Police_Officer_Attend_Scene_of_Accident	CHAR(2),
    LSOA_of_Accident_Location CHAR(11),
    PRIMARY KEY (Accident_Index)
);

-- First changed rhe data format from dd-mm-yyyy in excel to yyyy-mm-dd 
DESCRIBE TABLE accident;

SELECT count(*) FROM accident; -- 140056 records loaded
--------------

DROP TABLE IF EXISTS vehicle_type;

CREATE OR REPLACE TABLE vehicle_type 
(
	code SMALLINT NOT NULL,
	label VARCHAR(100),
    PRIMARY KEY (code)
);

DESCRIBE vehicle_type;

SELECT count(*) FROM vehicle_type; -- 21 records loaded
-----------

DROP TABLE IF EXISTS vehicle;

CREATE OR REPLACE TABLE vehicle 
(
	Accident_Index VARCHAR(20) NOT NULL,
	Vehicle_Reference CHAR(2),
	Vehicle_Type SMALLINT,
	Towing_and_Articulation CHAR(2),	
    Vehicle_Manoeuvre TINYINT,
    Vehicle_Location_Restricted_Lane CHAR(2),
	Junction_Location CHAR(2),
    Skidding_and_Overturning CHAR(2),
	Hit_Object_in_Carriageway CHAR(2),
	Vehicle_Leaving_Carriageway CHAR(2),
	Hit_Object_off_Carriageway CHAR(2),
	`1st_Point_of_Impact` CHAR(2),
    Was_Vehicle_Left_Hand_Drive CHAR(2),
	Journey_Purpose_of_Driver CHAR(2),
	Sex_of_Driver CHAR(2),
	Age_of_Driver TINYINT,
	Age_Band_of_Driver TINYINT,
	Engine_Capacity_CC SMALLINT,
	Propulsion_Code	CHAR(2),
    Age_of_Vehicle TINYINT,
	Driver_IMD_Decile CHAR(2), 
	Driver_Home_Area_Type CHAR(2),
	Vehicle_IMD_Decile CHAR(2),
    PRIMARY KEY (Vehicle_Reference),
    FOREIGN KEY (Vehicle_Type) REFERENCES vehicle_type(code)
);

DESCRIBE vehicle;

SELECT count(*) FROM vehicle; -- 257845 records loaded
------------------
/*
𝗔𝗽𝗽𝗿𝗼𝗮𝗰𝗵/𝗣𝗿𝗼𝗷𝗲𝗰𝘁 𝗜𝗱𝗲𝗮
Use aggregate functions in SQL and Python to answer the following sample questions:

1. Evaluate the median severity value of accidents caused by various Motorcycles.
2. Evaluate Accident Severity and Total Accidents per Vehicle Type
3. Calculate the Average Severity by vehicle type.
4. Calculate the Average Severity and Total Accidents by Motorcycle.
*/

-- 1. Evaluate the median severity value of accidents caused by various Motorcycles.

-- Median is the middle most value in a sorted list of numbers.

-- If the number of values is odd, the median can be calculated as:
-- Median = (n + 1)/2 th item

-- If the number of values is even, the median can be calculated as:
-- Median = ((n/2)th element + (n/2 + 1)th element)/2

-- In Snowflake, we refer to session variable using '$' sign, while in MySQL using '@' sign in our query.

-- Method 1
SET index = -1;

SELECT v.Vehicle_Type AS Vehicle_type, vt.label as Vehical_name,
       AVG(a.Severity) as Median
FROM
    (SELECT $index = $index + 1 AS i, 
           Accident_Index, Accident_Severity AS Severity
    FROM accident 
    ORDER BY 3) as a
    INNER JOIN vehicle v ON a.Accident_Index = v.Accident_Index
    INNER JOIN vehicle_type vt ON v.Vehicle_Type = vt.code
WHERE a.i in (FLOOR($index / 2), CEIL($index / 2)) AND LOWER(vt.label) LIKE '%motorcycle%'
GROUP BY 1,2
ORDER BY 1,2; -- returns 6 rows

--------
-- Method 2

SET row_index = -1; -- in Snowflake it is assigning Boolean Values, But in MySQL it is assigning integer values
Show Variables;

SELECT AVG(sort.Severity) as Median
FROM
( SELECT $row_index = $row_index + 1 AS i, t.*
  FROM
	 ( SELECT a.Accident_Index, v.Vehicle_Type AS Vehicle_Type, vt.label AS Vehical_Name, Accident_Severity AS Severity
       FROM accident a
       INNER JOIN vehicle v ON a.Accident_Index = v.Accident_Index
	   INNER JOIN vehicle_type vt ON v.Vehicle_Type = vt.code
       WHERE LOWER(vt.label) LIKE '%motorcycle%' 
       ORDER BY 4 ) AS t ) as sort                  -- -- returns 13,022 records (EVEN NUMBERS)
WHERE sort.i in (FLOOR($row_index / 2), CEIL($row_index / 2)); -- Median = 2.75, in MySQL it is giving 3.00

-----
-- Method 3 (Instead of Index, trying with Row_number() window function)

SELECT m.Severity
From
(
  SELECT t.*, row_number() over (ORDER BY Severity) as row_num
  FROM
     ( SELECT a.Accident_Index, v.Vehicle_Type AS Vehicle_Type, vt.label AS Vehical_Name, Accident_Severity AS Severity
       FROM accident a
       INNER JOIN vehicle v ON a.Accident_Index = v.Accident_Index
       INNER JOIN vehicle_type vt ON v.Vehicle_Type = vt.code
       WHERE LOWER(vt.label) LIKE '%motorcycle%'
      ) AS t -- returns 13,022 records
) AS m
WHERE m.row_num = (SELECT CEIL(MAX(m.row_num)/2) FROM m); -- Object 'M' does not exist or not authorized.

-- 2. Evaluate Accident Severity and Total Accidents per Vehicle Type

SELECT v.Vehicle_Type, Accident_Severity, COUNT(*) AS total_accidents
FROM accident a
INNER JOIN vehicle v ON a.Accident_Index = v.Accident_Index
INNER JOIN vehicle_type vt ON v.Vehicle_Type = vt.code
GROUP BY 1,2
ORDER BY 1,2;  -- returns 58 rows

-- 3. Calculate the Average Severity by vehicle type.

SELECT v.Vehicle_Type, ROUND(AVG(Accident_Severity),2) AS average_severity
FROM accident a
INNER JOIN vehicle v ON a.Accident_Index = v.Accident_Index
INNER JOIN vehicle_type vt ON v.Vehicle_Type = vt.code
GROUP BY 1
ORDER BY 1;  -- returns 21 rows

-- 4. Calculate the Average Severity and Total Accidents by Motorcycle.

SELECT vt.code AS vehicle_type, vt.label as vehical_name, 
       ROUND(AVG(Accident_Severity),2) AS average_severity,
       COUNT(*) AS total_accidents
FROM accident a
INNER JOIN vehicle v ON a.Accident_Index = v.Accident_Index
INNER JOIN vehicle_type vt ON v.Vehicle_Type = vt.code
WHERE LOWER(vt.label) LIKE '%motorcycle%'
GROUP BY 1,2
ORDER BY 1,2; -- returns 6 rows

-------------------------------------------------- Analyzing World Population --------------------------------------------

DROP DATABASE IF EXISTS worldpopulation;

CREATE DATABASE worldpopulation;

USE worldpopulation;

DROP TABLE IF EXISTS cia_factbook;

CREATE OR REPLACE TABLE cia_factbook 
(
  country VARCHAR(100),
  area	NUMBER(15,4),
  birth_rate NUMBER(4,2), -- for FLOAT(4,2) it was giving error
  death_rate NUMBER(4,2),
  infant_mortality_rate	NUMBER(5,2),
  internet_users INTEGER,
  life_exp_at_birth	NUMBER(4,2),
  maternal_mortality_rate SMALLINT,
  net_migration_rate NUMBER(5,2),
  population INTEGER,
  population_growth_rate NUMBER(4,2)
);

DESCRIBE TABLE cia_factbook;

-- Replace NA with Blank/NULL in the excel
SELECT count(*) FROM cia_factbook; -- 259 records
-------------
/*
A𝗽𝗽𝗿𝗼𝗮𝗰𝗵/𝗣𝗿𝗼𝗷𝗲𝗰𝘁 𝗜𝗱𝗲𝗮
You will learn how to use SQL to answer the following analytical questions:
1. Which country has the highest population?
2. Which country has the least number of people?
3. Which country is witnessing the highest population growth?
4. Which country has an extraordinary number for the population?
5. Which is the most densely populated country in the world?
*/

-- 1. Which country has the highest population?

SELECT country, MAX(population) as max_population
FROM cia_factbook
GROUP BY 1
HAVING max_population IS NOT NULL  -- as data is not complete, so NULL is coming in DESC order result
ORDER BY 2 DESC
LIMIT 5; -- China - 1355692576

-- 2. Which country has the least number of people?

SELECT country, Min(population) as min_population
FROM cia_factbook
GROUP BY 1
HAVING min_population IS NOT NULL 
ORDER BY 2
LIMIT 5; -- Pitcairn Islands - 48

-- 3. Which country is witnessing the highest population growth?

SELECT country, MAX(population_growth_rate) as population_g_rate
FROM cia_factbook
GROUP BY 1
HAVING population_G_rate IS NOT NULL
ORDER BY 2 desc
LIMIT 5; -- Lebanon - 9.37

-- 4. Which country has an extraordinary number for the population?

-- Ask in the doubt class, was told to leave it.

-- 5. Which is the most densely populated country in the world?

SELECT country, ROUND(MAX(area/population),2) AS density
FROM cia_factbook
GROUP BY 1
HAVING density IS NOT NULL
ORDER BY 2 desc
LIMIT 3; -- Greenland - 37.52