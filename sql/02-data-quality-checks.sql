-- Compare the number of movies in staging and fact
SELECT
    (SELECT COUNT(*) FROM staging_movies) AS staging_count,
    (SELECT COUNT(*) FROM fact_movies) AS fact_count;

-- Check for duplicated movie IDs
SELECT
    movie_id,
    COUNT(*) AS movie_count
FROM fact_movies
GROUP BY movie_id
HAVING COUNT(*) > 1;

-- Check for invalid date references
SELECT COUNT(*) AS invalid_date_references
FROM fact_movies AS f
LEFT JOIN dim_date AS d
    ON f.date_id = d.date_id
WHERE f.date_id IS NOT NULL
  AND d.date_id IS NULL;

-- Check for invalid language references
SELECT COUNT(*) AS invalid_language_references
FROM fact_movies AS f
LEFT JOIN dim_language AS l
    ON f.language_id = l.language_id
WHERE f.language_id IS NOT NULL
  AND l.language_id IS NULL;

-- Check for invalid runtime category references
SELECT COUNT(*) AS invalid_runtime_category_references
FROM fact_movies AS f
LEFT JOIN dim_runtime_category AS rc
    ON f.runtime_category_id = rc.runtime_category_id
WHERE f.runtime_category_id IS NOT NULL
  AND rc.runtime_category_id IS NULL;

-- Check for invalid movie references in bridge_genre
SELECT COUNT(*) AS invalid_movie_references
FROM bridge_genre AS bg
LEFT JOIN fact_movies AS f
    ON bg.movie_id = f.movie_id
WHERE f.movie_id IS NULL;

-- Check for invalid genre references
SELECT COUNT(*) AS invalid_genre_references
FROM bridge_genre AS bg
LEFT JOIN dim_genre AS g
    ON bg.genre_id = g.genre_id
WHERE g.genre_id IS NULL;

-- Check for invalid movie references in bridge_company
SELECT COUNT(*) AS invalid_movie_references
FROM bridge_company AS bc
LEFT JOIN fact_movies AS f
    ON bc.movie_id = f.movie_id
WHERE f.movie_id IS NULL;

-- Check for invalid company references
SELECT COUNT(*) AS invalid_company_references
FROM bridge_company AS bc
LEFT JOIN dim_company AS c
    ON bc.company_id = c.company_id
WHERE c.company_id IS NULL;

-- Check for invalid movie references in bridge_country
SELECT COUNT(*) AS invalid_movie_references
FROM bridge_country AS bc
LEFT JOIN fact_movies AS f
    ON bc.movie_id = f.movie_id
WHERE f.movie_id IS NULL;

-- Check for invalid country references
SELECT COUNT(*) AS invalid_country_references
FROM bridge_country AS bc
LEFT JOIN dim_country AS c
    ON bc.country_id = c.country_id
WHERE c.country_id IS NULL;

-- Check genre distribution across movies
SELECT
    COUNT(*) AS relationship_count,
    COUNT(DISTINCT movie_id) AS movie_count,
    COUNT(DISTINCT genre_id) AS genre_count
FROM bridge_genre;
