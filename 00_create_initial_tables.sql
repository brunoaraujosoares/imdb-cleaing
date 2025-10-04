/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [00_create_initial_tables.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03, 2025-10-04]
   VERSION: 1.0
======================================================================
   OBJECTIVE: Creates initial tables with the columns from the 
   Kaggle dataset.

   DEPENDENCIES: None

   INPUT: None

   OUTPUT: 2 tables: [tb_imdb, tb_imdb_stag]

   NOTES:

    1.
    I initially created all columns as character varying because
	there were null fields. Later, I had to convert the "overview"
	column's data type to TEXT (because some values were longer than 
	255 characters, which resulted in error when importing cvs file) 

    2.
    I added an id to the column for further analisys and 
    relastioships


    3.
    ===============================================================
     !!! REMEMBER TO IMPORT DATA BEFORE CREATING tb_imdb_stag !!!
    ===============================================================

    4.
    tb_imdb_stag is a simple copy of the original table for 
    transformation on data berfore applying changes on the original
    tb_imdb


    5. 
    While checking genre column, no inconsistences were found but
    i thought it would be nice to have a separate table to the 
    genres and a relation between the movies and the genres to 
	use in further analisys. 

	6. 
    To check for typos in the movie participants (director, 
    star1, star2, star3 and star4) names, I created a new table from 
    the respecctive columns. This will be also useful in the EDA
    i.e. to figure out the most active participant.

	*/

=================================================================== */


    DROP TABLE IF EXISTS public.tb_imdb;

    CREATE TABLE IF NOT EXISTS public.tb_imdb
    (
        poster_link character varying(255) COLLATE pg_catalog."default",
        series_title character varying(200) COLLATE pg_catalog."default",
        released_year character varying(100) COLLATE pg_catalog."default",
        certificate character varying(100) COLLATE pg_catalog."default",
        runtime character varying(100) COLLATE pg_catalog."default",
        genre character varying(100) COLLATE pg_catalog."default",
        imdb_rating character varying(100) COLLATE pg_catalog."default",
        overview text COLLATE pg_catalog."default",
        meta_score character varying(100) COLLATE pg_catalog."default",
        director character varying(200) COLLATE pg_catalog."default",
        star1 character varying(200) COLLATE pg_catalog."default",
        star2 character varying(200) COLLATE pg_catalog."default",
        star3 character varying(200) COLLATE pg_catalog."default",
        star4 character varying(200) COLLATE pg_catalog."default",
        no_of_votes character varying(200) COLLATE pg_catalog."default",
        gross character varying(200) COLLATE pg_catalog."default"
    );

    ALTER TABLE IF EXISTS public.tb_imdb OWNER to postgres;

    -- adding an id to tb_imdb
	ALTER TABLE tb_imdb
		ADD COLUMN id_series BIGSERIAL PRIMARY KEY;

    -- IMPORT DATA BEFORE CONTINUE

    -- Creating staging table: public.tb_imdb_stag
    DROP TABLE IF EXISTS public.tb_imdb_stag;

    CREATE TABLE IF NOT EXISTS public.tb_imdb_stag AS
        TABLE public.tb_imdb;



    -- Creating separate genre table: public.tb_genres
	DROP TABLE IF EXISTS public.tb_genres;

	CREATE TABLE IF NOT EXISTS public.tb_genres AS
	
		SELECT
		    row_number() OVER () AS genre_id,
		    trim(genre) AS genre
		FROM (
		    SELECT DISTINCT trim(value) AS genre
		    FROM tb_imdb,
		         regexp_split_to_table(genre, ',') AS value
		    WHERE value IS NOT NULL
			ORDER BY trim(value)
		) sub
	ORDER BY genre;

    -- Aux table to map series e genres (N:M)
    DROP TABLE IF EXISTS public.tb_series_genres;


    CREATE TABLE public.tb_series_genres (
        id_series BIGINT NOT NULL,
        genre_id INT NOT NULL,
        PRIMARY KEY (id_series, genre_id),
        FOREIGN KEY (id_series) REFERENCES public.tb_imdb(id_series) ON DELETE CASCADE,
        FOREIGN KEY (genre_id) REFERENCES public.tb_genres(genre_id) ON DELETE CASCADE
    );

    -- Populate tb_series_genres
    INSERT INTO public.tb_series_genres (id_series, genre_id)
        SELECT
            i.id_series,
            g.genre_id
        FROM tb_imdb i
        JOIN LATERAL regexp_split_to_table(i.genre, ',') AS value ON TRUE
        JOIN tb_genres g ON trim(value) = g.genre;

    -- Creates a view that brings tb_imdb main fields and tb_genres via 
    -- tb_series_genres.

    -- good practices recomend remove column genres, but I will leave 
    -- it as it is

    DROP VIEW IF EXISTS public.vw_series_with_genres;

    CREATE VIEW public.vw_series_with_genres AS
    SELECT 
        i.id_series,
        i.series_title,
        i.released_year,
        i.certificate,
        i.runtime,
        i.imdb_rating,
        STRING_AGG(g.genre, ', ' ORDER BY g.genre) AS genres
    FROM tb_imdb i
    JOIN tb_series_genres sg ON i.id_series = sg.id_series
    JOIN tb_genres g ON sg.genre_id = g.genre_id
    GROUP BY 
        i.id_series,
        i.series_title,
        i.released_year,
        i.certificate,
        i.runtime,
        i.imdb_rating
    ORDER BY i.series_title;
    
    
    -- Creating separate movie participants table: public.tb_movie_participants
    -- It holds director, star1, star2, star3 and star4 from tb_imdb
    DROP TABLE IF EXISTS public.tb_movie_participants;

	CREATE TABLE IF NOT EXISTS public.tb_movie_participants (
	    id_participant SERIAL PRIMARY KEY,
	    id_series BIGINT NOT NULL,
	    participant VARCHAR(200) NOT NULL,
	    movie_role VARCHAR(50) NOT NULL
	);
	
	INSERT INTO public.tb_movie_participants (id_series, participant, movie_role)
		SELECT DISTINCT id_series, participants, movie_role
		FROM public.tb_imdb
		CROSS JOIN LATERAL (
		    VALUES
		        (director, 'director'),
		        (star1, 'star1'),
		        (star2, 'star2'),
		        (star3, 'star3'),
		        (star4, 'star4')
		) AS roles(participant, movie_role)
		WHERE participant IS NOT NULL
		  AND participant <> '';

