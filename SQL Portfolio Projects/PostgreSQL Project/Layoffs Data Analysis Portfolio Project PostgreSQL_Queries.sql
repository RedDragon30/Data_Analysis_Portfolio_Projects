/*

World Layoffs Data Analysis (EDA) Using PostgreSQL Database

*/

-- Preprocessed Layoffs Data Source: https://github.com/RedDragon30/Data_Analysis_Portfolio_Projects/blob/main/SQL%20Portfolio%20Projects/data/preprocessed%20data/layoffs_staging.csv

-- This Preprocessed Layoffs data that we cleaned in MySQL Project.

-- Create Database for Data Analysis (EDA)
DROP DATABASE IF EXISTS world_layoffs;
CREATE DATABASE world_layoffs;

-- Impord Preprocessed data
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
  date text
);

COPY layoffs_eda(company, companies_size, location, entity_type, total_laid_off, percentage_laid_off,
                 industry, stage, millions_funds_raised, country, date)
FROM 'C:\Program Files\PostgreSQL\17\data\layoffs_staging.csv'
WITH(
	FORMAT csv,
	DELIMITER ',',
	HEADER true,
	ENCODING 'UTF8',
	NULL 'NULL'
);

-- Look at Preprocessed layoffs data
SELECT *
FROM layoffs_eda;

--------------------------------------------------------------------------------------------------------------------------

/*

Layoffs Data Analysis

*/
















