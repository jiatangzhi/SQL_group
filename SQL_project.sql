-- ==================================== --
-- MSc in DSAIS 
-- 2023-2024
-- SQL group exercise 
-- ==================================== --
-- You will work here on the movies database. 
-- You will focus on the table metadata but what we will see is applicable to 
-- the other tables as well.

-- Write down your names here: 
-- Team mate 1: Jean Luis Soto
-- Team mate 2: Jia Xin Tang Zhi
-- Team mate 3: Michelle Bianchi 
-- Team mate 4: 
-- (if needed Team mate 5:) 
-- 

select * from movies.metadata;
-- ==================================== --
-- PART ONE: Evaluate data imperfection
-- ==================================== --

-- Exercice 1: Dealing with NULL and N/A
-- We want to be able to study the evolution of the duration of the films through the years. 
-- But first we need to make sure there are no missing values.
-- Focus on columns : movie_title, duration, title_year
-- 1) Write a query to know if there are missing values in those columns (be careful about how they are represented!)
-- Qualify them
Select movie_title, duration, title_year
From movies.metadata
WHERE movie_title IS NULL or duration like "" or title_year like "";

-- IS NULL: This condition filters the data to include rows where the movie_title column has a NULL value
-- duration/title_year like "" : to check if the duration column is an empty string ("")

-- 2) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.
Select count(*) as Total_records, 
count(CASE WHEN movie_title IS NULL OR duration LIKE "" OR title_year LIKE "" THEN movie_title end) as Total_missing_records, 
count(CASE WHEN movie_title IS NULL OR duration LIKE "" OR title_year LIKE "" THEN movie_title end)/count(*) * 100 as Ratio
From movies.metadata;

-- We can see that 128 records have missings values, having around 2.5% of the total records 

-- 3) Select all the data, excluding the rows with missing values.
SELECT movie_title, duration, title_year
FROM movies.metadata
WHERE movie_title IS NOT NULL AND duration <> '' AND title_year <> '';

-- Here we retrieved the columns from the metadata table and only include rows where movie_title has some value  
-- as well as ensures only rows where title_year and duration is not an empty string

-- Exercice 2: Dealing with Duplicate Records - Removing them
-- (On the table metadata from the movies database).
-- We still want to be able to study the evolution of the duration of the films through the years. But first we need to make sure there are no duplicates.
-- Focus on the same columns: movie_title, duration, title_year,
-- Plus we add director_name to know wether they are real duplicates or movies with the same name
 
-- 1) Write a query to know whether there is duplicates in those columns.
SELECT movie_title, duration, title_year, director_name, COUNT(*) as Unique_values
FROM movies.metadata
WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
GROUP BY movie_title, duration, title_year, director_name
HAVING Unique_values <> 1
ORDER BY Unique_values DESC;

-- Selecting the columns and counting the number of rows (records) for each group of unique values in the specified columns
-- Using the where clause to filter out empty rows and we grouped the data to count the number of rows that have the same values in these four columns.
-- Thanks to the HAVING clause we filter out the ones that are not equal to one (meaning duplicates)

-- 2) Select the duplicates and try to understand why we have duplicates.
WITH DUPLICATES AS (
SELECT movie_title, duration, title_year, director_name, COUNT(*) as Unique_values
FROM movies.metadata
WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
GROUP BY movie_title, duration, title_year, director_name
HAVING Unique_values <> 1
ORDER BY Unique_values DESC)

SELECT * FROM  movies.metadata AS A
JOIN DUPLICATES AS B
ON A.movie_title = B.movie_title AND A.duration = B.duration AND A.director_name = B.director_name and A.title_year = B.title_year
ORDER BY A.title_year;

-- The main part of the query selects all columns from movies.metadata and joins it with the DUPLICATES created before, the results are ordered by title_year
-- After checking this last query result, we could see there are differences for the actor 1 and 2 facebook likes columns, we can assume they piled up the previous versions of those movies when updating the dataset

-- 3) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.

WITH DUPLICATES AS (
SELECT movie_title, duration, title_year, director_name, COUNT(*) as Unique_values
FROM movies.metadata
WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
GROUP BY movie_title, duration, title_year, director_name
HAVING Unique_values <> 1
ORDER BY Unique_values DESC)

SELECT 
    (SELECT SUM(Unique_values) FROM DUPLICATES) / 
    (SELECT COUNT(*) FROM movies.metadata WHERE movie_title <> '' AND duration <> '' AND title_year <> '') * 100
    AS Proportion_of_total_records;

-- We have around 4.7% of records that are duplicates 
 
-- 4) Select all the data, excluding the rows with missing values and the duplicates.
WITH RankedMovies AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
    FROM movies.metadata
    WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
)
SELECT movie_title, duration, title_year, director_name
FROM RankedMovies
WHERE Enumeration = 1;

-- We have a common query to identify and return rows from the metadata table while eliminating duplicates based on a set of criteria
-- We selected some columns from RankedMovies. However, Enumeration keeps only unique rows, to avoid duplicates.


-- -----------
-- Exercise 3 
-- 1) Explore carefully the table, do you notice anything?
-- Try to identify a maximum of issues on metadata design :
-- You can write down here your comments as well as your queries that 
-- helped you to identify those issues

DESCRIBE movies.metadata;
-- We can observe some problems with VARCHAR type for numerical columns like duration, facebook likes, gross, num_voted_users, budget, title_year, imbd_score

SELECT distinct duration, gross, num_voted_users,  budget, title_year,actor_3_facebook_likes,facenumber_in_poster,imdb_score
FROM movies.metadata;

-- We can see that in num_voted_users we have some text
-- For imdb_score we have some scores higher than 10 points which is not correct 
-- facenumber_in_poster we have mixed text and numbers 
-- For the title_year we have years up to 180000000
-- In budget we have numbers mixed with the age rating for the movies 

SELECT MIN(duration), MAX(duration), AVG(duration) FROM movies.metadata;
SELECT MIN(director_facebook_likes), MAX(director_facebook_likes), AVG(director_facebook_likes) FROM movies.metadata;
SELECT MIN(cast_total_facebook_likes), MAX(cast_total_facebook_likes), AVG(cast_total_facebook_likes) FROM movies.metadata;
-- These ones above seem pretty normal 

SELECT MIN(title_year), MAX(title_year), AVG(title_year) FROM movies.metadata;
-- We can see there is a clear problem, stating MAX is USA instead of a year 

SELECT MIN(num_voted_users), MAX(num_voted_users), AVG(num_voted_users) FROM movies.metadata;
-- We can also appreciate a problem the maximum voted users is "who lives at home" and the minimum being 0000 B.C.

-- movie_imdb_link has string 
SELECT movie_imdb_link
FROM movies.metadata
WHERE movie_imdb_link REGEXP '[0-9]' ;

-- num_user_for_reviews has links, strings  
SELECT num_user_for_reviews
FROM movies.metadata; 

-- language columns has numerical values, links

-- country also has numerical values and links 

-- content_rating has strings that make no sens for this category : 
SELECT content_rating
FROM movies.metadata
WHERE 
content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7');

-- 2) Try to select the problematic rows and to understand the problem.
 
SELECT title_year, duration, gross, num_voted_users, budget,actor_3_facebook_likes,facenumber_in_poster,imdb_score, country
,content_rating, language, num_user_for_reviews, movie_imdb_link
FROM movies.metadata 
WHERE (title_year REGEXP '^[^0-9]+$' OR duration REGEXP '^[^0-9]+$' OR num_voted_users REGEXP '^[^0-9]+$'
OR budget REGEXP '^[^0-9]+$' OR title_year REGEXP '^[^0-9]+$' OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
OR facenumber_in_poster REGEXP '^[^0-9]+$' OR imdb_score REGEXP '^[^0-9]+$' OR num_user_for_reviews REGEXP '^[^0-9]+$'  
OR movie_imdb_link REGEXP '[^0-9]+$'
OR title_year NOT BETWEEN 1900 AND 2023
OR imdb_score NOT BETWEEN 1 AND 10
OR country REGEXP '[0-9]' OR language REGEXP '[0-9]' 
OR country LIKE "https%" OR language LIKE "https%" OR num_user_for_reviews LIKE "https%"
OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7'))
AND movie_title <> '' AND duration <> '' AND title_year <> '';

-- Here we selected the problematic columns from metadata we previously identified
-- by applying several conditions to filter out specific rows like : non-numeric characters, invalid movies years, invalid imbd score( >10),
-- numerical characters in columns that make no sense like country, values outside of a specified set of valid content ratings,
-- filtering out rows with missing values 

-- 3) How many records are concerned? Make sure to have your result as a proportion of the total nb of records.

SELECT 
    (
        SELECT COUNT(*)
        FROM movies.metadata
        WHERE (title_year REGEXP '^[^0-9]+$' 
               OR duration REGEXP '^[^0-9]+$' 
               OR num_voted_users REGEXP '^[^0-9]+$'
               OR budget REGEXP '^[^0-9]+$' 
               OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
               OR facenumber_in_poster REGEXP '^[^0-9]+$' 
               OR imdb_score REGEXP '^[^0-9]+$' 
               OR num_user_for_reviews REGEXP '^[^0-9]+$'  
               OR movie_imdb_link REGEXP '[^0-9]+$'
               OR title_year NOT BETWEEN 1900 AND 2023
               OR imdb_score NOT BETWEEN 1 AND 10
               OR country REGEXP '[0-9]' 
               OR language REGEXP '[0-9]' 
               OR country LIKE "https%" 
               OR language LIKE "https%" 
               OR num_user_for_reviews LIKE "https%"
               OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
              )
              AND movie_title <> '' 
              AND duration <> '' 
              AND title_year <> ''
    ) 
    / 
    (SELECT COUNT(*) FROM movies.metadata WHERE movie_title <> '' AND duration <> '' AND title_year <> '') 
    * 100 AS Proportion_of_total_records_percentage;

-- The records concerned are around 8% of the total records

-- 4) Select all the data, excluding the rows with missing values, duplicates AND corrupted data.

WITH RankedMovies AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
    FROM movies.metadata
    WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
)
,
FINAL AS (SELECT * FROM RankedMovies WHERE Enumeration = 1)

SELECT *
FROM FINAL
WHERE NOT (
    title_year REGEXP '^[^0-9]+$' 
    OR num_voted_users REGEXP '^[^0-9]+$' 
    OR budget REGEXP '^[^0-9]+$' 
    OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
    OR facenumber_in_poster REGEXP '^[^0-9]+$' 
    OR imdb_score REGEXP '^[^0-9]+$' 
    OR num_user_for_reviews REGEXP '^[^0-9]+$' 
    OR NOT (title_year BETWEEN 1900 AND 2023)
    OR NOT (imdb_score BETWEEN 1 AND 10)
    OR country REGEXP '[0-9]' 
    OR language REGEXP '[0-9]'
    OR country LIKE 'https%' 
    OR language LIKE 'https%' 
    OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
);

-- ==================================== --
-- PART TWO: Make ambitious table junction
-- ==================================== --
-- The database “movies” contains two kind of ratings. 
-- One “rating” is in the table “ratings” and is link to a “movieId”. 
-- The other, “imdb_score”, is in the “metadata” table. 
-- What we want here is to make an ambitious junction between the two table and get, per movie, the two kind of ratings available in this database.
-- Why ambitious? 
-- Because as you can see there is no common key or even common attribute between the two tables. 
-- In fact, there is no perfectly identic attributes but there is one eventually common value : the movie title.
-- Here, the issue here is how formate/clean your table’s data so you could make a proper join.
-- ====== --
-- Step 1:
-- What is the difference between the two attributes metadata.movie_title and movies.title ?
-- Only comment here

select *
from movies.movies
Where title like "Toy%";

-- Here we have the movie ID and Genre, probably corrected for these movies
-- The main difference is that the movies titles also include the years while in metadata we have years in a different column 

select *
from movies.metadata
Where movie_title like "Toy%";

-- ====== --
-- Step 2:
-- How to cut out some unwanted pieces of a string ? 
-- Use the function SUBSTR() but you will also need another function : CHAR_LENGTH().
-- From the movies table, 
-- Try to get a query returning the movie.title, considering only the correct title of each movie.

SELECT lower(trim( substr(title, 1, CHAR_LENGTH(title) -6))) AS ExtractedTitle
FROM movies.movies;

-- And then also include the aggregation of the average rating for each movie

-- “rating” is in the table “ratings” and is link to a “movieId” :

SELECT movieID, ROUND(AVG(rating),2) AS Average_ratings
FROM movies.ratings
GROUP BY movieID;

-- Below we calculated the average rating for the “imdb_score” in the “metadata” table : 

WITH RankedMovies AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
    FROM movies.metadata
    WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
)
,
FINAL AS (SELECT * FROM RankedMovies WHERE Enumeration = 1)

SELECT ROUND(AVG(imdb_score),2) AS Average_rating_per_movie
FROM FINAL
WHERE NOT (
    title_year REGEXP '^[^0-9]+$' 
    OR num_voted_users REGEXP '^[^0-9]+$' 
    OR budget REGEXP '^[^0-9]+$' 
    OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
    OR facenumber_in_poster REGEXP '^[^0-9]+$' 
    OR imdb_score REGEXP '^[^0-9]+$' 
    OR num_user_for_reviews REGEXP '^[^0-9]+$' 
    OR NOT (title_year BETWEEN 1900 AND 2023)
    OR NOT (imdb_score BETWEEN 1 AND 10)
    OR country REGEXP '[0-9]' 
    OR language REGEXP '[0-9]'
    OR country LIKE 'https%' 
    OR language LIKE 'https%' 
    OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
);

-- joining the ratings table : between the two table and get, per movie, the two kind of ratings available in this database.

WITH RankedMovies AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
    FROM movies.metadata
    WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
)
,
FINAL AS (SELECT * FROM RankedMovies WHERE Enumeration = 1)

SELECT ROUND(AVG(imdb_score),2) AS Average_rating_per_movie
FROM FINAL
WHERE NOT (
    title_year REGEXP '^[^0-9]+$' 
    OR num_voted_users REGEXP '^[^0-9]+$' 
    OR budget REGEXP '^[^0-9]+$' 
    OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
    OR facenumber_in_poster REGEXP '^[^0-9]+$' 
    OR imdb_score REGEXP '^[^0-9]+$' 
    OR num_user_for_reviews REGEXP '^[^0-9]+$' 
    OR NOT (title_year BETWEEN 1900 AND 2023)
    OR NOT (imdb_score BETWEEN 1 AND 10)
    OR country REGEXP '[0-9]' 
    OR language REGEXP '[0-9]'
    OR country LIKE 'https%' 
    OR language LIKE 'https%' 
    OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
);

-- joining the ratings table : between the two table and get, per movie, the two kind of ratings available in this database.

WITH Rating1 AS (SELECT movieID, ROUND(AVG(rating),2) AS Average_ratings
FROM movies.ratings
GROUP BY movieID), 
Metadata AS ( 
        WITH RankedMovies AS (
            SELECT *, 
                ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
            FROM movies.metadata
            WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
        )
        ,
        FINAL AS (SELECT * FROM RankedMovies WHERE Enumeration = 1)

        SELECT  lower(trim(substr(movie_title, 1, CHAR_LENGTH(movie_title) -1))) AS ExtractedTitle1, ROUND(AVG(imdb_score),2) AS Average_rating_per_movie
        FROM FINAL
        WHERE NOT (
            title_year REGEXP '^[^0-9]+$' 
            OR num_voted_users REGEXP '^[^0-9]+$' 
            OR budget REGEXP '^[^0-9]+$' 
            OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
            OR facenumber_in_poster REGEXP '^[^0-9]+$' 
            OR imdb_score REGEXP '^[^0-9]+$' 
            OR num_user_for_reviews REGEXP '^[^0-9]+$' 
            OR NOT (title_year BETWEEN 1900 AND 2023)
            OR NOT (imdb_score BETWEEN 1 AND 10)
            OR country REGEXP '[0-9]' 
            OR language REGEXP '[0-9]'
            OR country LIKE 'https%' 
            OR language LIKE 'https%' 
            OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
        )
        GROUP BY 1
    )

SELECT lower(trim( substr(A.title, 1, CHAR_LENGTH(A.title) -6))) AS ExtractedTitle2, B.Average_ratings, C.Average_rating_per_movie
FROM movies.movies AS A
LEFT JOIN Rating1 AS B
ON A.movieId = B.movieId
LEFT JOIN Metadata AS C
ON lower(trim( substr(A.title, 1, CHAR_LENGTH(A.title) -6))) = C.ExtractedTitle1;

 -- ====== --
-- Step 3:
-- Now that we have a good request for cleaned and aggregated version of movies/ratings, 
-- you need to also have a clean request from metadata.
-- Make a query returning aggregated metadata.imdb_score for each metadata.movie_title.
-- excluding the corrupted rows 


WITH Rating1 AS (SELECT movieID, ROUND(AVG(rating),2) AS Average_ratings
FROM movies.ratings
GROUP BY movieID), 
Metadata AS ( 
        WITH RankedMovies AS (
            SELECT *, 
                ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
            FROM movies.metadata
            WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
        )
        ,
        FINAL AS (SELECT * FROM RankedMovies WHERE Enumeration = 1)

        SELECT  lower(trim(substr(movie_title, 1, CHAR_LENGTH(movie_title) -1))) AS ExtractedTitle1, ROUND(AVG(imdb_score),2) AS Average_rating_per_movie
        FROM FINAL
        WHERE NOT (
            title_year REGEXP '^[^0-9]+$' 
            OR num_voted_users REGEXP '^[^0-9]+$' 
            OR budget REGEXP '^[^0-9]+$' 
            OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
            OR facenumber_in_poster REGEXP '^[^0-9]+$' 
            OR imdb_score REGEXP '^[^0-9]+$' 
            OR num_user_for_reviews REGEXP '^[^0-9]+$' 
            OR NOT (title_year BETWEEN 1900 AND 2023)
            OR NOT (imdb_score BETWEEN 1 AND 10)
            OR country REGEXP '[0-9]' 
            OR language REGEXP '[0-9]'
            OR country LIKE 'https%' 
            OR language LIKE 'https%' 
            OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
        )
        GROUP BY 1
    )

SELECT C.ExtractedTitle1,lower(trim( substr(A.title, 1, CHAR_LENGTH(A.title) -6))) AS ExtractedTitle2, B.Average_ratings, C.Average_rating_per_movie

FROM Metadata AS C
LEFT JOIN movies.movies AS A
ON lower(trim( substr(A.title, 1, CHAR_LENGTH(A.title) -6))) = C.ExtractedTitle1
LEFT JOIN Rating1 AS B
ON A.movieId = B.movieId;

-- ====== --
-- Step 4:
-- It is time to make a JOIN! Try to make a request merging the result of Step 2 and Step 3. 
-- You need to use your previous as two subqueries and join on the movie title.
-- What is happening ? What is the result ? This request can take time to return.

WITH Rating1 AS (SELECT movieID, ROUND(AVG(rating),2) AS Average_ratings
FROM movies.ratings
GROUP BY movieID), 
Metadata AS ( 
        WITH RankedMovies AS (
            SELECT *, 
                ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
            FROM movies.metadata
            WHERE movie_title <> '' AND duration <> '' AND title_year <> ''
        )
        ,
        FINAL AS (SELECT * FROM RankedMovies WHERE Enumeration = 1)

        SELECT  lower(trim(substr(movie_title, 1, CHAR_LENGTH(movie_title) -1))) AS ExtractedTitle1, ROUND(AVG(imdb_score),2) AS Average_rating_per_movie
        FROM FINAL
        WHERE NOT (
            title_year REGEXP '^[^0-9]+$' 
            OR num_voted_users REGEXP '^[^0-9]+$' 
            OR budget REGEXP '^[^0-9]+$' 
            OR actor_3_facebook_likes REGEXP '^[^0-9]+$' 
            OR facenumber_in_poster REGEXP '^[^0-9]+$' 
            OR imdb_score REGEXP '^[^0-9]+$' 
            OR num_user_for_reviews REGEXP '^[^0-9]+$' 
            OR NOT (title_year BETWEEN 1900 AND 2023)
            OR NOT (imdb_score BETWEEN 1 AND 10)
            OR country REGEXP '[0-9]' 
            OR language REGEXP '[0-9]'
            OR country LIKE 'https%' 
            OR language LIKE 'https%' 
            OR content_rating NOT IN ('PG-13', 'PG', 'G', 'R', 'TV-14', 'TV-PG', 'TV-MA', 'TV-G', 'Not Rated', 'Unrated', 'TV-Y', 'TV-Y7')
        )
        GROUP BY 1
    )

SELECT C.ExtractedTitle1, B.Average_ratings, C.Average_rating_per_movie

FROM Metadata AS C
LEFT JOIN movies.movies AS A
ON lower(trim( substr(A.title, 1, CHAR_LENGTH(A.title) -6))) = C.ExtractedTitle1
LEFT JOIN Rating1 AS B
ON A.movieId = B.movieId
WHERE A.title is not null;

-- ====== --
-- Step 5:
-- There is a possibility that your previous query doesn't work for apparently no reasons, 
-- despite of the join condition being respected on some rows 
-- (check by yourself on a specific film of your choice by adding a simple WHERE condition).
-- Try to find out what could go wrong 
-- And try to query a workable join
-- Tip: Think about spaces or blanks 

-- We had a problem with null values in the average_rating_per_movie column when joining 
-- We add this code to take out the blank space at the end of the title and solve our problem when joining the tables :
-- SELECT lower(trim(substr(movie_title, 1, CHAR_LENGTH(movie_title) -1)))

-- For final version of the output, 
-- Also include the count of ratings used to compute the average.

  SELECT *, 
                ROW_NUMBER() OVER (PARTITION BY movie_title, duration, title_year, director_name ORDER BY movie_title) as Enumeration 
            FROM movies.metadata
            WHERE movie_title <> '' AND duration <> '' AND title_year <> '';


-- ------------------
-- Well done ! 
-- Congratulations !
-- ------------------



