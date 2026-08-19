-- Create a staging table for the cleaned dataset
CREATE TABLE staging_movies (
    budget NUMERIC,
    id INTEGER,
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
COPY staging_movies
FROM '/tmp/interim.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ',',
    ENCODING 'UTF8'
);


/*
dim_date
*/

-- Populate the date dimension from release dates
CREATE TABLE dim_date (
    date_id INTEGER PRIMARY KEY,
    full_date DATE,
    year INTEGER,
    decade INTEGER
);

INSERT INTO dim_date (
    date_id,
    full_date,
    year,
    decade
)

SELECT DISTINCT
    TO_CHAR(release_date, 'YYYYMMDD')::INTEGER AS date_id,
    release_date AS full_date,
    release_year AS year,
    release_decade AS decade
FROM staging_movies
WHERE release_date IS NOT NULL;

-- Preview the date dimension
SELECT *
FROM dim_date
ORDER BY full_date
LIMIT 10;

/*
dim_language
*/

-- Create the language dimension
CREATE TABLE dim_language (
    language_id SERIAL PRIMARY KEY,
    language_code TEXT UNIQUE
);

-- Populate the language dimension
INSERT INTO dim_language (language_code)
SELECT DISTINCT original_language
FROM staging_movies
WHERE original_language IS NOT NULL;

-- Preview the language dimension
SELECT *
FROM dim_language
ORDER BY language_id;

-- Count unique languages : 89
SELECT COUNT(*) AS language_count
FROM dim_language;

/*
dim_runtime_category
*/

CREATE TABLE dim_runtime_category (
    runtime_category_id SERIAL PRIMARY KEY,
    category_name TEXT UNIQUE
);

-- Populate the runtime category dimension
INSERT INTO dim_runtime_category (category_name)
VALUES
    ('Short Film'),
    ('Medium-Length'),
    ('Standard Feature'),
    ('Long Feature');

-- Preview the runtime categories
SELECT *
FROM dim_runtime_category
ORDER BY runtime_category_id;

/*
fact_movies
*/

-- Create the main movie fact table
CREATE TABLE fact_movies (
    movie_id INTEGER PRIMARY KEY,
    title TEXT,
    date_id INTEGER,
    language_id INTEGER,
    runtime_category_id INTEGER,
    runtime NUMERIC,
    budget NUMERIC,
    revenue NUMERIC,
    profit NUMERIC,
    revenue_budget_ratio NUMERIC,
    popularity NUMERIC,
    vote_average NUMERIC,
    vote_count NUMERIC,

    FOREIGN KEY (date_id)
        REFERENCES dim_date(date_id),

    FOREIGN KEY (language_id)
        REFERENCES dim_language(language_id),

    FOREIGN KEY (runtime_category_id)
        REFERENCES dim_runtime_category(runtime_category_id)
);

-- Populate the movie fact table
INSERT INTO fact_movies (
    movie_id,
    title,
    date_id,
    language_id,
    runtime_category_id,
    runtime,
    budget,
    revenue,
    profit,
    revenue_budget_ratio,
    popularity,
    vote_average,
    vote_count
)
SELECT
    s.id AS movie_id,
    s.title,
    d.date_id,
    l.language_id,
    rc.runtime_category_id,
    s.runtime,
    s.budget,
    s.revenue,
    s.revenue - s.budget AS profit,
    CASE
        WHEN s.budget > 0
             AND s.revenue IS NOT NULL
        THEN s.revenue / s.budget
        ELSE NULL
    END AS revenue_budget_ratio,
    s.popularity,
    s.vote_average,
    s.vote_count
FROM staging_movies AS s

LEFT JOIN dim_date AS d
    ON s.release_date = d.full_date

LEFT JOIN dim_language AS l
    ON s.original_language = l.language_code

LEFT JOIN dim_runtime_category AS rc
    ON CASE
        WHEN s.runtime < 40 THEN 'Short Film'
        WHEN s.runtime < 60 THEN 'Medium-Length'
        WHEN s.runtime < 150 THEN 'Standard Feature'
        WHEN s.runtime >= 150 THEN 'Long Feature'
       END = rc.category_name;

-- Preview the movie fact table
SELECT *
FROM fact_movies
LIMIT 10;

-- Compare staging and fact row counts
SELECT COUNT(*) AS fact_movie_count
FROM fact_movies;

/*
genre_dim
*/

-- Create the genre dimension
CREATE TABLE dim_genre (
    genre_id SERIAL PRIMARY KEY,
    genre_name TEXT UNIQUE
);

-- Extract individual genres from the genre strings
INSERT INTO dim_genre (genre_name)
SELECT DISTINCT
    match[1] AS genre_name
FROM staging_movies AS s
CROSS JOIN LATERAL regexp_matches(
    s.genre_names,
    '''([^'']+)''',
    'g'
) AS match
WHERE s.genre_names IS NOT NULL
  AND match[1] IS NOT NULL
  AND TRIM(match[1]) <> '';

SELECT * 
FROM dim_genre
LIMIT 10;

-- Create the movie-genre bridge table
CREATE TABLE bridge_genre (
    movie_id INTEGER,
    genre_id INTEGER,

    PRIMARY KEY (movie_id, genre_id),

    FOREIGN KEY (movie_id)
        REFERENCES fact_movies(movie_id),

    FOREIGN KEY (genre_id)
        REFERENCES dim_genre(genre_id)
);

-- Populate the movie-genre bridge table
INSERT INTO bridge_genre (
    movie_id,
    genre_id
)
SELECT DISTINCT
    s.id AS movie_id,
    g.genre_id
FROM staging_movies AS s

CROSS JOIN LATERAL regexp_matches(
    s.genre_names,
    '''([^'']+)''',
    'g'
) AS match

JOIN dim_genre AS g
    ON TRIM(match[1]) = g.genre_name

WHERE s.genre_names IS NOT NULL
  AND match[1] IS NOT NULL
  AND TRIM(match[1]) <> '';

-- Count movie-genre relationships
SELECT COUNT(*) AS relationship_count
FROM bridge_genre;

-- Preview movies with their genres
SELECT
    f.movie_id,
    f.title,
    g.genre_name
FROM fact_movies AS f
JOIN bridge_genre AS bg
    ON f.movie_id = bg.movie_id
JOIN dim_genre AS g
    ON bg.genre_id = g.genre_id
ORDER BY f.movie_id
LIMIT 20;

/* 
dim_company
*/

-- Create the company dimension
CREATE TABLE dim_company (
    company_id SERIAL PRIMARY KEY,
    company_name TEXT UNIQUE
);

-- Populate the company dimension
INSERT INTO dim_company (company_name)
SELECT DISTINCT
    TRIM(match[1]) AS company_name
FROM staging_movies AS s
CROSS JOIN LATERAL regexp_matches(
    s.company_names,
    '''([^'']+)''',
    'g'
) AS match
WHERE s.company_names IS NOT NULL
  AND match[1] IS NOT NULL
  AND TRIM(match[1]) <> '';

-- Preview the company dimension
SELECT *
FROM dim_company
ORDER BY company_id
LIMIT 20;

-- Count unique companies
SELECT COUNT(*) AS company_count
FROM dim_company;

-- Create the movie-company bridge table
CREATE TABLE bridge_company (
    movie_id INTEGER,
    company_id INTEGER,
    PRIMARY KEY (movie_id, company_id),
    FOREIGN KEY (movie_id) REFERENCES fact_movies(movie_id),
    FOREIGN KEY (company_id) REFERENCES dim_company(company_id)
);

-- Populate the movie-company bridge table
INSERT INTO bridge_company (movie_id, company_id)
SELECT DISTINCT
    s.id AS movie_id,
    c.company_id
FROM staging_movies AS s
CROSS JOIN LATERAL regexp_matches(
    s.company_names,
    '''([^'']+)''',
    'g'
) AS match
JOIN dim_company AS c
    ON TRIM(match[1]) = c.company_name
WHERE s.company_names IS NOT NULL
  AND match[1] IS NOT NULL
  AND TRIM(match[1]) <> '';

/*
dim_country
*/

-- Create the country dimension
CREATE TABLE dim_country (
    country_id SERIAL PRIMARY KEY,
    country_name TEXT UNIQUE
);

-- Populate the country dimension
INSERT INTO dim_country (country_name)
SELECT DISTINCT
    TRIM(match[1]) AS country_name
FROM staging_movies AS s
CROSS JOIN LATERAL regexp_matches(
    s.country_names,
    '''([^'']+)''',
    'g'
) AS match
WHERE s.country_names IS NOT NULL
  AND match[1] IS NOT NULL
  AND TRIM(match[1]) <> '';

-- Preview the country dimension
SELECT *
FROM dim_country
ORDER BY country_id
LIMIT 20;

-- Count unique countries
SELECT COUNT(*) AS country_count
FROM dim_country;

-- Create the movie-country bridge table
CREATE TABLE bridge_country (
    movie_id INTEGER,
    country_id INTEGER,

    PRIMARY KEY (movie_id, country_id),

    FOREIGN KEY (movie_id)
        REFERENCES fact_movies(movie_id),

    FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id)
);

-- Populate the movie-country bridge table
INSERT INTO bridge_country (
    movie_id,
    country_id
)
SELECT DISTINCT
    s.id AS movie_id,
    c.country_id
FROM staging_movies AS s

CROSS JOIN LATERAL regexp_matches(
    s.country_names,
    '''([^'']+)''',
    'g'
) AS match

JOIN dim_country AS c
    ON TRIM(match[1]) = c.country_name

WHERE s.country_names IS NOT NULL
  AND match[1] IS NOT NULL
  AND TRIM(match[1]) <> '';

-- Preview movies with their countries
SELECT
    f.movie_id,
    f.title,
    c.country_name
FROM fact_movies AS f
JOIN bridge_country AS bc
    ON f.movie_id = bc.movie_id
JOIN dim_country AS c
    ON bc.country_id = c.country_id
ORDER BY f.movie_id
LIMIT 20;
