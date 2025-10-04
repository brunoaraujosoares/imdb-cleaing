/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [04_data_dictionary.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-04]
   VERSION: 1.0
======================================================================
   OBJECTIVES: 
      -- Documents all actions in the project.
      -- Describes domain of each field and transformations made 
         during the project. 
      -- The ideal would be to create a record for each transformation
         and relate it to a column or table. Maybe I will do it in the
         next poject.

   DEPENDENCIES: None

   INPUT: None

   OUTPUT: Creates tb_metadata 

   NOTES:
      -- This is not really neccessary to run. It contains the 
         transformation made in each column.
         
=================================================================== */


-- Creates a table to the data dictionary
DROP TABLE IF EXISTS public.tb_metadata;

CREATE TABLE public.tb_metadata (
    column_name text PRIMARY KEY,
    data_type text NOT NULL,
    description text,
    transformations_applied text
);

-- Insert metadata per column (name, type, description, applied transformations)
INSERT INTO public.tb_metadata (column_name, data_type, description, transformations_applied) VALUES
('id_series', 'BIGSERIAL / BIGINT', 
 'Auto-incremental primary key added to uniquely identify each movie/record.', 
 'ALTER TABLE tb_imdb ADD COLUMN id_series BIGSERIAL PRIMARY KEY;'),

('poster_link', 'VARCHAR(255)', 
 'Movie poster URL; can be NULL when unavailable.', 
 'TRIM'),

('series_title', 'VARCHAR(200)', 
 'Movie/series title (text). Used for identification and joins with other sources.', 
 'TRIM'),

('released_year', 'SMALLINT', 
 'Movie release year (integer value).', 
 'Fixed invalid entries (e.g., replaced ''PG'' with ''1995''); ALTER COLUMN released_year TYPE SMALLINT USING released_year::SMALLINT.'),

('certificate', 'VARCHAR(100)', 
 'Parental guidance / rating (e.g., A, UA, UA13, Unrated).', 
 'Standardization applied: G -> A; PG / GP / TV-PG -> UA; R -> A; U/A -> UA; TV-MA -> A; PG-13 / TV-14 -> UA13; Passed / Approved / 16 / NULL -> ''Unrated''.'),

('runtime', 'SMALLINT', 
 'Movie runtime in minutes (integer).', 
 'Removed text (e.g., ''min'') via REGEXP_REPLACE, then ALTER COLUMN runtime TYPE SMALLINT USING runtime::SMALLINT.'),

('genre', 'VARCHAR(100)', 
 'Movie genres (string with possibly multiple comma-separated values).', 
 'Created auxiliary table tb_genres with regexp_split_to_table to normalize genres; original kept. Many-to-many relationship (tb_movie_genre).'),

('imdb_rating', 'NUMERIC(3,1)', 
 'Public IMDB rating (scale 0.0–10.0).', 
 'ALTER TABLE ... ALTER COLUMN imdb_rating TYPE NUMERIC(3,1) USING imdb_rating::NUMERIC(3,1).'),

('overview', 'TEXT', 
 'Movie synopsis/overview (free text; may be long).', 
 'Converted to TEXT (some entries exceeded 255 characters during import). Kept as TEXT.'),

('meta_score', 'SMALLINT', 
 'Aggregated critics score (Metascore, typically 0–100). May be missing in many records.', 
 'Initially in VARCHAR. ALTER TABLE ... ALTER COLUMN meta_score TYPE SMALLINT USING meta_score::SMALLINT. Note: ~15% missing; imputation considered but NOT applied (decision to preserve NULLs).'),

('director', 'VARCHAR(200)', 
 'Movie director name.', 
 'Kept as VARCHAR(200). Extracted tb_movie_participants table via CROSS JOIN LATERAL VALUES. Applied fuzzy test (fuzzystrmatch + levenshtein) to detect possible typos; no relevant issues found.'),

('star1', 'VARCHAR(200)', 
 'Main actor/actress (star1).', 
 'Kept as VARCHAR(200). Unpivoted into tb_movie_participant; used for duplicate/typo checks. Recommended TRIM/INITCAP if necessary.'),

('star2', 'VARCHAR(200)', 
 'Second listed actor/actress.', 
 'Kept as VARCHAR(200). Unpivoted into tb_movie_participant.'),

('star3', 'VARCHAR(200)', 
 'Third listed actor/actress.', 
 'Kept as VARCHAR(200). Unpivoted into tb_movie_participant.'),

('star4', 'VARCHAR(200)', 
 'Fourth listed actor/actress.', 
 'Kept as VARCHAR(200). Unpivoted into tb_movie_participant.'),

('no_of_votes', 'BIGINT', 
 'Number of votes registered on IMDB (large integer).', 
 'ALTER TABLE ... ALTER COLUMN no_of_votes TYPE BIGINT USING no_of_votes::BIGINT. Values checked (min 25088, max 2343110 in dataset).'),

('gross', 'NUMERIC', 
 'Gross revenue (currency value).', 
 'Created auxiliary column gross_num NUMERIC; UPDATE using regexp_replace(gross, ''[^0-9]'','''',''g'')::NUMERIC; DROP COLUMN gross; RENAME gross_num TO gross. Standardized numeric format; display formatting via to_char when required.');



