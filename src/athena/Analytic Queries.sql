-- 2) Top 10 filmes mais avaliados

    SELECT m.title, COUNT(r.rating) AS n_ratings
    FROM ratings r
    JOIN movies m USING (movieId)
    GROUP BY m.title
    ORDER BY n_ratings DESC
    LIMIT 10

-- 2a) Top 10 filmes mais avaliados com seus gêneros
    WITH top_10 AS (
        SELECT m.movieId, m.title, COUNT(r.rating) AS n_ratings
        FROM ratings r
        JOIN movies m on m.movieId = r.movieId
        GROUP BY m.movieId, m.title
        ORDER BY n_ratings DESC
        LIMIT 10
    )
    SELECT t.title, t.n_ratings, m.genres
    FROM top_10 t
    JOIN movies m ON m.movieId = t.movieId
    ORDER BY t.n_ratings DESC

-- 3) Top 10 filmes com melhor média (≥100 avaliações)
    SELECT m.title, COUNT(r.rating) AS n_ratings, AVG(r.rating) AS avg_rating
    FROM ratings r
    JOIN movies m on m.movieId = r.movieId
    GROUP BY m.title
    HAVING COUNT(r.rating) >= 1000
    ORDER BY avg_rating DESC
    LIMIT 10

-- 3a) Top 10 filmes com melhor média com seus gêneros
    WITH top_10 AS (
        SELECT m.movieId, m.title, COUNT(r.rating) AS n_ratings, AVG(r.rating) AS avg_rating
        FROM ratings r
        JOIN movies m ON m.movieId = r.movieId
        GROUP BY m.movieId, m.title
        HAVING COUNT(r.rating) >= 100
        ORDER BY avg_rating DESC
        LIMIT 10
    )
    SELECT t.title, t.n_ratings, t.avg_rating, m.genres
    FROM top_10 t
    JOIN movies m ON m.movieId = t.movieId
    ORDER BY t.avg_rating DESC

-- 4) Popularidade por gênero
   WITH exploded AS (
        SELECT 
            movieId,
            genre
        FROM movies
        CROSS JOIN UNNEST(split(genres, '|')) AS t(genre)
        WHERE genres IS NOT NULL 
          AND genres <> '(no genres listed)'
    )
    SELECT 
        genre, 
        COUNT(*) AS n_movies
    FROM exploded
    GROUP BY genre
    ORDER BY n_movies DESC;

-- 5) Atividade de avaliações ao longo do tempo 
    SELECT date_format(date(from_unixtime(timestamp)), '%Y-%m') AS month,
           COUNT(*) AS n_ratings
    FROM ratings
    GROUP BY date_format(date(from_unixtime(timestamp)), '%Y-%m')
    ORDER BY month

-- 6) Ciclo de vida por ano de lançamento
    SELECT CAST(SUBSTRING(m.title, LENGTH(m.title)-4, 4) AS INT) AS year_guess,
           COUNT(r.rating) AS n_ratings
    FROM movies m
    LEFT JOIN ratings r USING (movieId)
    WHERE m.title LIKE '%(%)'
      AND TRY_CAST(SUBSTRING(m.title, LENGTH(m.title)-4, 4) AS INT) IS NOT NULL
    GROUP BY year_guess
    ORDER BY year_guess

-- 7) Co-ocorrência de gêneros --== Não percebi
    WITH exploded AS (
        SELECT movieId, genre
        FROM movies
        CROSS JOIN UNNEST(split(genres, '|')) AS t(genre)
        WHERE genres IS NOT NULL AND genres <> '(no genres listed)'
    ),
    pairs AS (
        SELECT a.movieId, LEAST(a.genre,b.genre) AS g1, GREATEST(a.genre,b.genre) AS g2
        FROM exploded a
        JOIN exploded b ON a.movieId = b.movieId AND a.genre < b.genre
    )
    SELECT g1, g2, COUNT(*) AS n
    FROM pairs
    GROUP BY g1, g2
    ORDER BY n DESC
    LIMIT 20


-- 8) Média global
    SELECT AVG(rating) AS gmean FROM ratings

-- 9) Distribuição de nº de avaliações por usuário
    SELECT COUNT(*) AS n_ratings
    FROM ratings
    GROUP BY userId

-- 9.a) Análise do utilizador mais ativo
    WITH user_stats AS (
        SELECT userId, COUNT(*) AS n_ratings
        FROM ratings
        GROUP BY userId
    )
    SELECT *
    FROM user_stats
    ORDER BY n_ratings DESC
    LIMIT 1

-- 9.b) Contagem de reviews por ano para o utilizador mais ativo
    SELECT
        YEAR(date(from_unixtime(timestamp))) AS review_year,
        COUNT(*) AS n_reviews
    FROM
        ratings
    WHERE
        userId = 175325 
    GROUP BY
        YEAR(date(from_unixtime(timestamp)))
    ORDER BY
        review_year ASC

-- 9.c) Primeiros 10 filmes avaliados por este utilizador em 2001
    SELECT
        m.title,
        r.rating,
        date_format(date(from_unixtime(timestamp)), '%Y-%m-%d %H:%M:%S') AS review_date
    FROM
        ratings r
    JOIN
        movies m ON r.movieId = m.movieId
    WHERE
        r.userId = 175325
        AND YEAR(date(from_unixtime(timestamp))) = 2001
    ORDER BY
        r.timestamp ASC
    LIMIT 10

-- 9.d) Número de filmes únicos avaliados por este utilizador
    SELECT
        COUNT(DISTINCT movieId) AS n_unique_movies,
        COUNT(*) AS total_reviews
    FROM
        ratings
    WHERE
        userId = 175325

-- 9.e) Filmes com as avaliações mais altas dadas por este utilizador
    SELECT
        m.title,
        r.rating,
        date(from_unixtime(timestamp)) AS review_date
    FROM
        ratings r
    JOIN
        movies m ON r.movieId = m.movieId
    WHERE
        r.userId = 175325
    ORDER BY
        r.rating DESC,
        r.timestamp DESC
    LIMIT 20

-- 10  Top 20 Customers with the most ratings posted
    SELECT userId, COUNT(userId) AS n_ratings, AVG(rating) AS average_rating
    FROM ratings
    GROUP BY userId
    ORDER BY n_ratings DESC
    LIMIT 10;

-- # 11) Rating by Genre

WITH exploded AS (
    SELECT r.rating, genre
    FROM ratings r
    JOIN movies m USING (movieId)
    CROSS JOIN UNNEST(split(m.genres, '|')) AS t(genre)
    WHERE m.genres IS NOT NULL
      AND m.genres <> '(no genres listed)'
)
SELECT 
    genre,
    AVG(rating) AS avg_rating
FROM exploded
GROUP BY genre
ORDER BY avg_rating DESC;

-- # 12) Number of Avaluations vs Average Rating
SELECT 
    m.title,
    COUNT(r.rating) AS n_ratings,
    AVG(r.rating) AS avg_rating
FROM ratings r
JOIN movies m ON r.movieId = m.movieId
GROUP BY m.title
ORDER BY n_ratings DESC
LIMIT 20;

-- #13 Movies with Highest Rating Standard Deviation (at least 500 ratings)
SELECT 
    m.title,
    COUNT(r.rating) AS n,
    stddev(r.rating) AS std
FROM ratings r
JOIN movies m ON r.movieId = m.movieId
GROUP BY m.title
HAVING COUNT(r.rating) >= 500
ORDER BY std DESC
LIMIT 15;


-- # 14) Top 20 Tags with Highest Average Movie Rating (at least 50 ratings)
SELECT 
    LOWER(trim(t.tag)) AS tag,
    AVG(r.rating) AS avg_rating,
    COUNT(*) AS n
FROM ratings r
JOIN tags t 
    ON r.userId = t.userId 
   AND r.movieId = t.movieId
GROUP BY 1
HAVING COUNT(*) >= 50
ORDER BY avg_rating DESC
LIMIT 20;

-- # 15) Top 20 Tags with Lowest Average Movie Rating (at least 50 ratings)
SELECT 
    LOWER(trim(t.tag)) AS tag,
    AVG(r.rating) AS avg_rating,
    COUNT(*) AS n
FROM ratings r
JOIN tags t
    ON r.userId = t.userId
   AND r.movieId = t.movieId
GROUP BY 1
HAVING COUNT(*) >= 50
ORDER BY avg_rating ASC
LIMIT 20;


-------------------------------------
--16 - Nota média por década 
SELECT 
    r.movieid,
    title, 
    ((YEAR(date(from_unixtime(timestamp))) / 10) * 10) AS decade, 
    avg(rating) as med_rating, 
    count(*) qtd_ratings 
FROM "bronze"."ratings" as r
left join "bronze"."movies" as m on m.movieid = r.movieid
group by r.movieid,title, ((YEAR(date(from_unixtime(timestamp))) / 10) * 10)
order by title, ((YEAR(date(from_unixtime(timestamp))) / 10) * 10), count(*) desc, avg(rating) desc
;

-- 16a -  Filme mais avaliado por década (Top 1 por década) - Fica, mas não usamos gráfico, só tabela, juntamos a evolução por ano (ponto 5)
WITH MAIN_QUERY AS 
(
    SELECT 
        title, 
        ((YEAR(date(from_unixtime(timestamp))) / 10) * 10) AS decade, 
        avg(rating) as med_rating, 
        count(*) qtd_ratings,
        row_number() OVER(PARTITION BY ((YEAR(date(from_unixtime(timestamp))) / 10) * 10) ORDER BY count(*) DESC, avg(rating) DESC) AS RN
    FROM "bronze"."ratings" as r
    left join "bronze"."movies" as m on m.movieid = r.movieid
    group by title, ((YEAR(date(from_unixtime(timestamp))) / 10) * 10)
)
SELECT 
    decade,
    title,
    med_rating,
    qtd_ratings
FROM MAIN_QUERY
WHERE RN = 1
ORDER BY decade

--17- Filmes com maior proporção de notas 5 
WITH filmes_5 AS (
    SELECT 
        title, 
        genres,
        AVG(rating) as med_rating,
        SUM(CASE WHEN rating >=5 THEN 1 ELSE 0 END) qtd_ratings_5,
        count(*) qtd_ratings
    FROM "bronze"."ratings" as r
    left join "bronze"."movies" as m on m.movieid = r.movieid
    group by title, genres
)
SELECT *, ((qtd_ratings_5*1.0/qtd_ratings)*100.0)  as prct FROM filmes_5
ORDER BY qtd_ratings_5 DESC

--17a- Filmes com maior proporção de notas 1 
WITH filmes_1 AS (
    SELECT 
        title, 
        genres,
        AVG(rating) as med_rating,
        SUM(CASE WHEN rating <=1 THEN 1 ELSE 0 END) qtd_ratings_1,
        count(*) qtd_ratings
    FROM "bronze"."ratings" as r
    left join "bronze"."movies" as m on m.movieid = r.movieid
    group by title, genres
)
SELECT *, ((qtd_ratings_1*1.0/qtd_ratings)*100.0)  as prct FROM filmes_1
ORDER BY qtd_ratings_1 DESC


--18 Variação de filmes ao longos dos anos
WITH filmes AS (
    SELECT 
        title, 
        genres,
        YEAR(date(from_unixtime(timestamp))) AS ano, 
        AVG(rating) as med_rating,
        count(*) qtd_ratings
    FROM "bronze"."ratings" as r
    left join "bronze"."movies" as m on m.movieid = r.movieid
    group by title, genres, YEAR(date(from_unixtime(timestamp)))
)
SELECT *, med_rating-LAG(med_rating) OVER (ORDER BY title, ano) var_med_rating, 
qtd_ratings-LAG(qtd_ratings) OVER (ORDER BY title, ano) var_qtd_rating FROM filmes
--ORDER BY title, ano DESC
 