/*
01-feature-engineering.sql

1. Data quality checks
*/


-- Create the main movie table
CREATE TABLE movies (
    budget NUMERIC,
    id NUMERIC,
    original_language TEXT,
    original_title TEXT,
    overview TEXT,
    popularity NUMERIC,
    poster_path TEXT,
    release_date DATE,
    revenue NUMERIC,
    runtime NUMERIC,
    title TEXT,
    vote_average NUMERIC,
    vote_count NUMERIC,
    collection TEXT,
    genre_names TEXT,
    company_names TEXT,
    country_names TEXT,
    language_names TEXT,
    release_year INTEGER,
    release_decade INTEGER
);

-- Load cleaned data from csv
COPY movies
FROM '/tmp/interim.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    ENCODING 'UTF8'
);

-- Preview imported data
SELECT * FROM movies
LIMIT 10;

-- Check number of records
SELECT COUNT(*)
FROM movies;

-- Inspect table structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'movies';

-- Create runtime category based on movie length
SELECT
    id,
    title,
    runtime,
    CASE
        WHEN runtime < 5 THEN 'Micro Short'
        WHEN runtime < 40 THEN 'Short Film'
        WHEN runtime < 60 THEN 'Medium-Length'
        WHEN runtime < 150 THEN 'Standard Feature'
        WHEN runtime >= 150 THEN 'Long Feature'
        ELSE NULL
    END AS runtime_category
FROM movies
WHERE runtime IS NOT NULL AND runtime > 0
LIMIT 20;

-- Calculate estimated gross profit
SELECT
    id,
    title,
    budget,
    revenue,
    revenue - budget AS profit
FROM movies
WHERE 
    revenue IS NOT NULL 
    AND budget IS NOT NULL 
    AND budget > 0
    AND runtime > 0
LIMIT 20;

-- Calculate revenue-to-budget ratio
SELECT
    id,
    title,
    budget,
    revenue,
    CASE
        WHEN budget IS NOT NULL
         AND revenue IS NOT NULL
         AND budget > 0
        THEN revenue / budget
        ELSE NULL
    END AS revenue_budget_ratio
FROM movies
LIMIT 20;
