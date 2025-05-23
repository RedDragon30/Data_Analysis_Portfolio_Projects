/*

World Layoffs Data Analysis (EDA) Using PostgreSQL Database

*/

-- Preprocessed Layoffs Data Source: https://github.com/RedDragon30/Data_Analysis_Portfolio_Projects/blob/main/SQL%20Portfolio%20Projects/data/preprocessed%20data/layoffs_staging.csv

-- This Preprocessed Layoffs data that we cleaned in MySQL Project.

/*

Environment Preparation

*/

-- Create Database for Data Analysis (EDA)
DROP DATABASE IF EXISTS world_layoffs;
CREATE DATABASE world_layoffs;

-- Import Preprocessed data
CREATE TABLE IF NOT EXISTS layoffs_eda (
  company text,
  companies_size int DEFAULT NULL,
  location text,
  entity_type text,
  total_laid_off int DEFAULT NULL,
  percentage_laid_off text,
  industry text,
  stage text,
  millions_funds_raised text,
  country text,
  "date" date
);

COPY layoffs_eda(company, companies_size, location, entity_type, total_laid_off, percentage_laid_off,
                 industry, stage, millions_funds_raised, country, "date")
FROM 'C:\Program Files\PostgreSQL\17\data\layoffs_staging.csv'
WITH(
	FORMAT csv,
	DELIMITER ',',
	HEADER true,
	ENCODING 'UTF8',
	NULL 'NULL'
);

-- Change Some columns to integer
UPDATE layoffs_eda
SET percentage_laid_off = regexp_replace(percentage_laid_off, '[^0-9]', '', 'g'),
	millions_funds_raised = regexp_replace(millions_funds_raised, '[^0-9]', '', 'g');

ALTER TABLE layoffs_eda
ALTER COLUMN percentage_laid_off TYPE INTEGER
	USING percentage_laid_off::INTEGER,
ALTER COLUMN millions_funds_raised TYPE INTEGER
	USING millions_funds_raised::INTEGER;

-- Look at Preprocessed layoffs data
SELECT *
FROM layoffs_eda;

--------------------------------------------------------------------------------------------------------------------------

/*

Layoffs Data Analysis (EDA)

*/

-- Here we are jsut going to explore the data and find trends or patterns or anything interesting

-- 1. Descriptive Analysis

-- 1- Number of Companies and Rows in data
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT company) AS total_companies
FROM layoffs_eda;

--------------------------------------------------------------------------------------------------------------------------

-- 2- Univariate Distributions

-- Looking at 'total_laid_off' to see laid off range
SELECT MIN(total_laid_off), MAX(total_laid_off)
FROM layoffs_eda;

-- Looking at Percentage to see how big these layoffs were
SELECT MIN(percentage_laid_off), MAX(percentage_laid_off)
FROM layoffs_eda
WHERE percentage_laid_off IS NOT NULL;

--------------------------------------------------------------------------------------------------------------------------

-- Which companies had 100 percent of they company laid off
SELECT *
FROM layoffs_eda
WHERE percentage_laid_off = 100;
-- these are mostly startups it looks like who all went out of business during this time

-- if we order by millions_funds_raised we can see how big some of these companies were
SELECT *
FROM layoffs_eda
WHERE  percentage_laid_off = 100
ORDER BY millions_funds_raised DESC;
-- BritishVolt looks like an EV company, It raised like 2 billion dollars and went under

--------------------------------------------------------------------------------------------------------------------------

-- Industry Distribution in our data
SELECT industry, COUNT(*) AS total_data
FROM layoffs_eda
GROUP BY industry
ORDER BY total_data DESC
LIMIT 10;

-- Country Distribution in our data
SELECT country, COUNT(*) AS total_data
FROM layoffs_eda
GROUP BY country
ORDER BY total_data DESC
LIMIT 10;

--------------------------------------------------------------------------------------------------------------------------

-- 2. Bivariate & Relational Analysis

-- Companies with the biggest single Layoff
SELECT company, total_laid_off
FROM layoffs_eda
ORDER BY 2 DESC
LIMIT 10;
-- now that's just on a single day

-- Top 10 Companies with the biggest total Layoff of all days
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY company
ORDER BY 2 DESC
LIMIT 10;

--------------------------------------------------------------------------------------------------------------------------

-- by location 
SELECT location, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY location
ORDER BY 2 DESC
LIMIT 10;

-- by entity type
SELECT entity_type, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY entity_type
ORDER BY 2 DESC
LIMIT 10;

-- by country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY country
ORDER BY 2 DESC
LIMIT 10;

-- this it total in the past 6 years or in the dataset
SELECT EXTRACT(YEAR FROM "date") AS laid_off_year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

-- by industry
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY industry
ORDER BY 2 DESC
LIMIT 10;

-- by stage
SELECT stage, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY stage
ORDER BY 2 DESC
LIMIT 10;

-- by Company Size
SELECT company, SUM(companies_size) AS company_size, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;

--------------------------------------------------------------------------------------------------------------------------

-- If you want see specific company (like FAANG companies) and it size and total laid off
-- we using pg_trgm extension for search for specific company 
-- and citext extension for simplify operations like group by and order by (optional)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

/* (optional)

CREATE EXTENSION IF NOT EXISTS citext;

ALTER TABLE layoffs_eda
ALTER COLUMN company TYPE citext;

*/

-- Optional
-- CREATE INDEX idx_layoffs_trgm_gist
-- 		ON layoffs_eda
--		USING GIST(company gist_trgm_ops);

-- we want see 'Amazon' company
SELECT company, SUM(companies_size) AS company_size, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
WHERE company % 'amaz'
GROUP BY 1
ORDER BY 3 DESC
LIMIT 10;

--------------------------------------------------------------------------------------------------------------------------

-- 3. Advanced Analysis

-- 1- Earlier we looked at Companies and it size with the most Layoffs. Now let's look at that per year.
WITH Company_Year AS 
(
  SELECT company, EXTRACT(YEAR FROM "date") AS laid_off_year,
  		 SUM(companies_size) AS company_size, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_eda
  GROUP BY 1, 2
)
, Company_Year_Rank AS (
  SELECT company, laid_off_year, company_size, total_laid_off, DENSE_RANK() OVER (PARTITION BY laid_off_year ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, company_size, total_laid_off, laid_off_year, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND laid_off_year IS NOT NULL
ORDER BY laid_off_year ASC, total_laid_off DESC;

--------------------------------------------------------------------------------------------------------------------------

-- 2- Rolling Total of Layoffs Per Month using cte and window function
WITH DATE_CTE AS 
(
SELECT SUBSTRING("date", 1, 7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;

--------------------------------------------------------------------------------------------------------------------------

-- 4. Create Some Views for export to visualization tools (like Tableau, Power BI)

-- First View Relationship between company, company size, total laid off and laid off year
CREATE VIEW layoffs_by_company AS
WITH Company_Year AS 
(
  SELECT company, EXTRACT(YEAR FROM "date") AS laid_off_year,
  		 SUM(companies_size) AS company_size, SUM(total_laid_off) AS total_laid_off
  FROM layoffs_eda
  GROUP BY 1, 2
)
, Company_Year_Rank AS (
  SELECT company, laid_off_year, company_size, total_laid_off, DENSE_RANK() OVER (PARTITION BY laid_off_year ORDER BY total_laid_off DESC) AS ranking
  FROM Company_Year
)
SELECT company, company_size,total_laid_off, laid_off_year, ranking
FROM Company_Year_Rank
WHERE ranking <= 3
AND laid_off_year IS NOT NULL
ORDER BY laid_off_year ASC, total_laid_off DESC;

SELECT *
FROM layoffs_by_company;

--------------------------------------------------------------------------------------------------------------------------

-- Second View Relationship between date('YYYY-MM') and total laid off
CREATE VIEW layoffs_by_date AS
WITH DATE_CTE AS 
(
SELECT SUBSTRING("date",1,7) as dates, SUM(total_laid_off) AS total_laid_off
FROM layoffs_eda
GROUP BY dates
ORDER BY dates ASC
)
SELECT dates, SUM(total_laid_off) OVER (ORDER BY dates ASC) as rolling_total_layoffs
FROM DATE_CTE
ORDER BY dates ASC;

SELECT *
FROM layoffs_by_date;

--------------------------------------------------------------------------------------------------------------------------

-- That's it all for layoffs data Analysis (EDA) processess

-- some info about me:
/*
Name: Emran Albeik
GitHub: https://github.com/RedDragon30
LinkedIn: www.linkedin.com/in/emranalbeik
Kaggle: https://www.kaggle.com/emranalbiek
*/