/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [02_initial_analysis.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03]
   VERSION: 1.0
======================================================================
   OBJECTIVE: Creates initial tables with the columns from the 
   Kaggle dataset.

   DEPENDENCIES: 
        00_create_initial_tables.sql
        functions.sql

   INPUT: None

   OUTPUT: See comments below each statement

   NOTES:

=================================================================== */

    -- count rows
    SELECT count(*) as number_of_rows FROM public.tb_imdb;
	--  number_of_rows: 1000 

    -- show column names
    SELECT column_name FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name   = 'tb_imdb'
    ORDER BY ordinal_position;

    /* poster_link, series_title, released_year, certificate, 
    runtime, genre, imdb_rating, overview, meta_score, director,
    star1, star2, star3, star4, no_of_votes, gross */

    -- Find null values in each column		
    SELECT * FROM public.count_null('public','tb_imdb')
    WHERE null_count > 0 ORDER BY null_count DESC;
        
    /*|------------------------------------------------------------|
        |  column_name  |  null_count  |  total_count  |   pct_null  |
        |  gross        |      169     |     1000      |	  16.90    |
        |  meta_score   |      157     | 	   1000      |    15.70    |
        |  certificate  |      101     |     1000      |    10.10    |
        |------------------------------------------------------------|*/

	
    -- Sample of null values
			
        -- ! BAD FOR BIG DATA !
        SELECT * FROM public.tb_imdb WHERE gross IS NULL
            ORDER BY RANDOM() LIMIT (
                SELECT CEIL(COUNT(*) * 0.1) FROM public.tb_imdb
                    WHERE gross IS NULL
                );
                
        -- 9 from 17 meta_score were also null. 
        -- Remember to check correlation when EDA

        -- ! BAD FOR BIG DATA !
        SELECT * FROM public.tb_imdb WHERE meta_score IS NULL
            ORDER BY RANDOM() LIMIT (
                SELECT CEIL(COUNT(*) * 0.1) FROM public.tb_imdb
                    WHERE meta_score IS NULL
                );

        -- 9 from 16 gross were also null. 

        -- ! BAD FOR BIG DATA 
        SELECT * FROM public.tb_imdb WHERE certificate IS NULL
            ORDER BY RANDOM() LIMIT (
                SELECT CEIL(COUNT(*) * 0.1) FROM public.tb_imdb
                    WHERE certificate IS NULL
                );

        -- 5 from 11 meta_score were also null. 
        -- 7 from 11 gross were also null. 

	-- 1.4 Find duplicated rows

        SELECT COUNT(*) FROM public.tb_imdb
        GROUP BY 
            poster_link, series_title, released_year, certificate, runtime,
            genre, imdb_rating ,overview , meta_score, director, star1,
            star2, star3, star4, no_of_votes, gross 
        HAVING COUNT(*) > 1;
    
        -- The query returned no results (0 row affected). No duplicated 
        -- records where found.

	
	-- Find duplicated movies (comparing series_title + released_year)
	
        SELECT series_title, released_year, count(*) as num_occurrences 
        FROM public.tb_imdb 
        GROUP BY series_title, released_year
        HAVING  count(*) > 1
        ORDER BY count(*);
			
        -- The query returned no results (0 row affected). No duplicated 
        -- movies where found.