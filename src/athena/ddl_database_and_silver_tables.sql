CREATE DATABASE silver;

CREATE EXTERNAL TABLE IF NOT EXISTS silver.links (
    movieid bigint,
    imdbid  bigint,
    tmdbid  bigint
)
STORED AS PARQUET
LOCATION 's3://novaims-group30-bdf/ml32m/silver/links';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.movies (
    movieid bigint,
    title string,
    genres string
)
STORED AS PARQUET
LOCATION 's3://novaims-group30-bdf/ml32m/silver/movies';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.ratings (
    userid  bigint,
    movieid  bigint,
    rating   double,
    timestamp bigint 
)
STORED AS PARQUET
LOCATION 's3://novaims-group30-bdf/ml32m/silver/ratings';

CREATE EXTERNAL TABLE IF NOT EXISTS silver.tags (
    userid  bigint,
    movieid bigint,
    tag     string,
    timestamp bigint 
)
STORED AS PARQUET
LOCATION 's3://novaims-group30-bdf/ml32m/silver/tags';