/*

World Layoffs Data Cleaning And Processing Using MySQL Database

*/

-- Layoffs Data Source: https://www.kaggle.com/datasets/swaptr/layoffs-2022

-- The data availability is from when COVID-19 was declared as a pandemic i.e. 11 March 2020 to 8 May 2025.

/*

Environment Preparation

*/

-- Create Database for Data Processing
CREATE DATABASE IF NOT EXISTS `world_layoffs`;
USE `world_layoffs`;

CREATE TABLE `raw_layoffs_data` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `source` text,
  `stage` text,
  `funds_raised` text,
  `country` text,
  `date_added` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/layoffs.csv'
INTO TABLE raw_layoffs_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Change some columns info (optional)
ALTER TABLE world_layoffs.raw_layoffs_data
CHANGE `funds_raised` `millions_funds_raised` text,
CHANGE `date` `date` text AFTER `country`;

-- Look at layoffs data
SELECT *
FROM world_layoffs.raw_layoffs_data;

--------------------------------------------------------------------------------------------------------------------------

/*

Layoffs Data Cleaning And Processing

*/

-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens
CREATE TABLE world_layoffs.layoffs_staging 
LIKE raw_layoffs_data;

INSERT layoffs_staging 
SELECT * FROM raw_layoffs_data;

--------------------------------------------------------------------------------------------------------------------------

-- 1. Remove Duplicates

# First let's check for duplicates
SELECT *
FROM world_layoffs.layoffs_staging
;

SELECT *
FROM (
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY company, location, total_laid_off, percentage_laid_off,
						 industry, stage, millions_funds_raised, country, `date`
            ORDER BY `date`) AS duplicate_num
	FROM 
		layoffs_staging
) duplicates
WHERE 
	duplicate_num > 1;
    
-- let's just look at 'Cazoo' company to confirm
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Cazoo'
;
    
-- create a new column and add those row numbers in. Then delete where row numbers are over 1, then delete that column
DROP TABLE IF EXISTS layoffs_staging;

CREATE TABLE IF NOT EXISTS `world_layoffs`.`layoffs_staging` (
`company` text,
`location` text,
`total_laid_off` text,
`percentage_laid_off` text,
`industry` text,
`source` text,
`stage` text,
`millions_funds_raised` text,
`country` text,
`date` text,
`date_added` text,
`duplicate_num` INT
);

INSERT INTO `world_layoffs`.`layoffs_staging`
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, total_laid_off, percentage_laid_off,
					 industry, stage, millions_funds_raised, country, `date`
		ORDER BY `date`) AS duplicate_num
FROM raw_layoffs_data;

DELETE
FROM layoffs_staging
WHERE duplicate_num > 1;

ALTER TABLE layoffs_staging
DROP COLUMN duplicate_num;

--------------------------------------------------------------------------------------------------------------------------

-- 2. Standardize Data

-- 1- Remove Excess spaces in 'company' column
SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging;

UPDATE layoffs_staging
SET company = TRIM(company);

--------------------------------------------------------------------------------------------------------------------------

-- 2- Combine (Ada, Ada Support, Ada Health) in one row in 'company' column
SELECT DISTINCT company
FROM layoffs_staging
WHERE company = 'Ada' OR company LIKE 'Ada %';

UPDATE layoffs_staging
SET company = 'Ada'
where company IN ('Ada', 'Ada Health', 'Ada Support');

--------------------------------------------------------------------------------------------------------------------------

-- 3- Combine 'UAE' and 'United Arab Emirates' in one row in 'country' column
SELECT DISTINCT country
FROM layoffs_staging
WHERE country LIKE 'U%'
ORDER BY country;

UPDATE layoffs_staging
SET country = REPLACE(country, 'UAE', 'United Arab Emirates')
WHERE country = 'UAE';

--------------------------------------------------------------------------------------------------------------------------

-- 4- Convert 'date' column to date type and change date format
SELECT DISTINCT `date`, str_to_date(`date`, '%m/%d/%Y') AS `date_format`
FROM layoffs_staging;

UPDATE layoffs_staging
SET `date` = str_to_date(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging
MODIFY COLUMN `date` DATE;

--------------------------------------------------------------------------------------------------------------------------

-- 3. Look at Null Values

-- Convert blank values to null values because original_data shows null values as blank(empty) values but it's nulls
-- The null values are found in (total_laid_off, percentage_laid_off, industry, millions_funds_raised) columns
UPDATE layoffs_staging
SET total_laid_off = NULL,
	percentage_laid_off = NULL,
    millions_funds_raised = NULL,
    industry = NULL
WHERE total_laid_off = '' OR percentage_laid_off = '' OR millions_funds_raised = '' OR industry = '';

-- now if we check those are all null
SELECT *
FROM layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL
AND industry IS NULL;

-- if we look at industry it looks like we have some null let's take a look at these
SELECT *
FROM world_layoffs.layoffs_staging
WHERE industry IS NULL
ORDER BY industry;

-- let's take a look at this company
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company LIKE 'airbnb%';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them

-- now we need to know if we can populate those nulls
SELECT *
FROM layoffs_staging t1
JOIN layoffs_staging t2
	USING(company)
WHERE (t1.industry IS NULL OR t1.industry = '')
and t2.industry IS NOT NULL;

-- now we need to populate those nulls
UPDATE layoffs_staging t1
JOIN layoffs_staging t2
	USING(company)
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- the null values in total_laid_off, percentage_laid_off and millions_funds_raised all look normal,
-- so there isn't anything I want to change with the null values.

--------------------------------------------------------------------------------------------------------------------------

-- 4. remove any columns and rows we don't need to

-- 1- Delete Useless columns we can't really use
ALTER TABLE layoffs_staging
DROP `source`,
DROP date_added;

--------------------------------------------------------------------------------------------------------------------------

-- 2- Delete Useless data we can't really use
-- Delete rows has null values in 'total_laid_off', 'percentage_laid_off' columns together becuase all our data about layoffs
-- so if we don't have information about layoffs like these columns it will be hard when we head to EDA process
SELECT *
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE 
FROM world_layoffs.layoffs_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM world_layoffs.layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------

-- 5. Breaking out 'location' column into Individual Columns (location, entity_type)

-- maybe this is useful for some applications it's want entity type of companies
-- or some applications it's want know if company in USA or not
SELECT location
FROM layoffs_staging
WHERE location = 'Non-U.S.' OR location LIKE '%,Non-U.S.';

-- Add 'entity_type' column
ALTER TABLE layoffs_staging
ADD entity_type text AFTER location;

-- Add entity values(U.S., Non-U.S.) in 'entity_type' column
UPDATE layoffs_staging
SET entity_type = SUBSTRING(location, LOCATE(',', location) + 1, LENGTH(location))
WHERE location LIKE '%,Non-U.S.' OR location = 'Non-U.S.';

UPDATE layoffs_staging
SET entity_type = 'U.S.'
WHERE entity_type IS NULL;

SELECT entity_type
FROM layoffs_staging;

-- remove entity_type values from 'location' column
SELECT location,
TRIM(TRAILING ',Non-U.S.' FROM location) AS location_only
FROM layoffs_staging;

UPDATE layoffs_staging
SET location = TRIM(TRAILING ',Non-U.S.' FROM location);

SELECT location
FROM layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------

-- 6. Create 'companies_size' (number of employees in each company in every layoffs date) column from ('total_laid_off', 'percentage_laid_off')
-- Percentage_laid_off = (total_laid_off/companies size)*100
-- so companies size = total_laid_off/(percentage_laid_off/100)
-- This columns is very useful when we head to EDA process.
ALTER TABLE layoffs_staging
ADD companies_size INT AFTER company;

SELECT company,
	   ROUND(total_laid_off/(percentage_laid_off/100), 0) AS companies_size
FROM layoffs_staging;

UPDATE layoffs_staging
SET companies_size = ROUND(total_laid_off/(percentage_laid_off/100), 0)
WHERE (REPLACE(percentage_laid_off, '%', '') + 0) != 0
AND percentage_laid_off IS NOT NULL;

SELECT company, companies_size
FROM layoffs_staging;

--------------------------------------------------------------------------------------------------------------------------

-- 7. Create Triggers to set rules to ensure if update or insert happens will be can't make 'total_laid_off' negative.
-- this triggers are useful when we head to EDA process to give an accurate analysis

-- change 'total_laid_off' column type to integer
ALTER TABLE layoffs_staging
MODIFY total_laid_off INT;

-- 1- create first trigger for insert
DELIMITER $$
CREATE TRIGGER trg_validate_layoffs
BEFORE INSERT ON layoffs_staging
FOR EACH ROW
BEGIN
	IF NEW.total_laid_off < 0 THEN SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'total_laid_off must be non_negative';
	END IF;
END $$
DELIMITER ;

--------------------------------------------------------------------------------------------------------------------------

-- 2- create second trigger for update
DELIMITER $$
CREATE TRIGGER trg2_validate_layoffs
BEFORE UPDATE ON layoffs_staging
FOR EACH ROW
BEGIN
	IF NEW.total_laid_off < 0 THEN SIGNAL SQLSTATE '45000'
			SET MESSAGE_TEXT = 'total_laid_off must be non_negative';
	END IF;
END $$
DELIMITER ;

--------------------------------------------------------------------------------------------------------------------------

-- 8. Create stored Procedure and put all processess in.
-- Notic: I wiil not put all the processess, so that we don't repeate everything we wrote before.
-- I will put the most important processess (Remove Duplicates, Popluate Nulls, Remove Nulls) we wrote before.
DELIMITER $$
CREATE PROCEDURE layoffs_processing()
BEGIN
-- 1. Remove Duplicates
	DROP TABLE IF EXISTS layoffs_staging;

	CREATE TABLE IF NOT EXISTS `world_layoffs`.`layoffs_staging` (
	`company` text,
	`location` text,
	`total_laid_off` text,
	`percentage_laid_off` text,
	`industry` text,
	`source` text,
	`stage` text,
	`millions_funds_raised` text,
	`country` text,
	`date` text,
	`date_added` text,
	`duplicate_num` INT
	);

	INSERT INTO `world_layoffs`.`layoffs_staging`
	SELECT *,
		ROW_NUMBER() OVER(
			PARTITION BY company, location, total_laid_off, percentage_laid_off,
						 industry, stage, millions_funds_raised, country, `date`
			ORDER BY `date`) AS duplicate_num
	FROM raw_layoffs_data;

	DELETE
	FROM layoffs_staging
	WHERE duplicate_num > 1;

	ALTER TABLE layoffs_staging
	DROP COLUMN duplicate_num;

-- 2. Look at Null Values
	UPDATE layoffs_staging
	SET total_laid_off = NULL,
		percentage_laid_off = NULL,
		millions_funds_raised = NULL,
		industry = NULL
	WHERE total_laid_off = '' OR percentage_laid_off = '' OR millions_funds_raised = '' OR industry = '';

-- now we need to populate those nulls
	UPDATE layoffs_staging t1
	JOIN layoffs_staging t2
		USING(company)
	SET t1.industry = t2.industry
	WHERE (t1.industry IS NULL OR t1.industry = '')
	AND t2.industry IS NOT NULL;

-- 3. remove any columns and rows we don't need to

-- Delete Useless columns we can't really use
	ALTER TABLE layoffs_staging
	DROP `source`,
	DROP date_added;

-- Remove nulls.
	DELETE 
	FROM world_layoffs.layoffs_staging
	WHERE total_laid_off IS NULL
	AND percentage_laid_off IS NULL;
END $$
DELIMITER ;

-- Execute layoffs_processing Procedure
CALL layoffs_processing();

-- Last looking at the data after these processess
SELECT *
FROM layoffs_staging;

-- That's it all for layoffs data cleaning & processing processess

-- some info about me:
/*
Name: Emran Albeik
GitHub: https://github.com/RedDragon30
LinkedIn: www.linkedin.com/in/emranalbeik
Kaggle: https://www.kaggle.com/emranalbiek
*/