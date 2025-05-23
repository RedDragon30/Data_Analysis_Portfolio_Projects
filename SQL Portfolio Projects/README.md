# SQL Portfolio Project

## Layoffs Data Project: Cleaning & Processing in MySQL & Analysis (EDA) in PostgreSQL
![Layoffs](https://americanbazaaronline.com/wp-content/uploads/2022/12/Layoff.jpg)

## Description

#### Layoffs Data Source: [Layoffs Data](https://www.kaggle.com/datasets/swaptr/layoffs-2022)
#### The layoffs data availability is from when COVID-19 was declared as a pandemic i.e. 11 March 2020 to 8 May 2025.


### List of most important Columns

```
1) company : Companies Name
2) total_laid_off :  Number of laid-off employees in each company
3) percentage_laid_off : Percentage of laid-off employees in each company
4) industry :  Companies Industry
5) funds_raised : Funds raised by the company (in Millions $)
6) date :  Date of laid-off employees in each company
```

### - - - PROCESSESS  - - -

### (1) MySQL Processess 
![MySQL](https://img.icons8.com/?size=100&id=UFXRpPFebwa2&format=png&color=000000)
* Remove Duplicates
* Standardize Data
* Handle Null/Empty Values
* Remove Useless Rows/Columns
* Create Columns
* Breaking out column into multiple columns 
* Create Triggers/Stored Procedures

### (2) PostgreSQL Processess
![PostgreSQL](https://img.icons8.com/?size=100&id=JRnxU7ZWP4mi&format=png&color=000000)
* Descriptive Analysis
* Univariate Distributions
* Bivariate & Relational Analysis (like total laid off by columns)
* USE some extentions for EDA like (pg_trgm, citext) and GIST Index for pg_trgm
* Advanced Analysis
 * Create some CTEs and Window functions for EDA
* Create Some Views for export to visualization tools (like Tableau, Power BI)

### Requirements
* MySQL 8+
* PostgreSQL 13+
* INFILE/OUTFILE Permissions on MySQL
