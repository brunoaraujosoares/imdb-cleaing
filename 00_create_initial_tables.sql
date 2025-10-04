/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [00_create_initial_tables.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03]
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