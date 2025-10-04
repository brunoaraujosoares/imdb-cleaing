/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [03_standardization.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03, 2025-10-04]
   VERSION: 1.0
======================================================================
   OBJECTIVES: 
      -- Count unique values in each column
      -- Check domain of each field

   DEPENDENCIES: 
        00_create_initial_tables.sql
        functions.sql

   INPUT: None

   OUTPUT: See comments below each statement

   NOTES:
		See Certificate column notes
=================================================================== */


-- column released_year
	SELECT * FROM count_occurrences('public.tb_imdb', 'released_year');
	-- The attribute's domain is integer, but there is a line with string value ("PG")

	-- Finding out what is wrong
		
	SELECT series_title, released_year FROM public.tb_imdb WHERE released_year = 'PG';
	/*|--------|-----------------------|
		|  series_title  | released_year |
		|----------------|---------------|
		|  Apollo 13     |           PG  |
		|----------------|---------------|*/	


	-- Compute mode in a manner that supports multimodal attributes
		WITH counts AS (
			SELECT released_year, COUNT(*) AS num_occurrences
			FROM public.tb_imdb
			GROUP BY released_year
		)
		
		SELECT released_year as mode, num_occurrences FROM counts WHERE num_occurrences = (
		SELECT MAX(num_occurrences) FROM counts
		);

	  /*|--------|----------------|
		|  mode  | num_occurences |
		|--------|----------------|
		|  2014  |            32  |
		|--------|----------------|*/	

		-- I could input mode, but 
		-- I googled it instead and figured out the year: 1995. 

		-- input mean is not a good idea because someone could type '2025' as '25' 
		-- median otherwise was close enough

		SELECT percentile_cont(0.5) WITHIN GROUP (
		ORDER BY released_year::smallint) as median
		FROM public.tb_imdb;

	  /*|--------|
		| median |
		|--------|
		|  1999  |
		|--------|*/	
	

	-- Manually replacing 'PG' value
	UPDATE public.tb_imdb SET released_year = '1995' WHERE released_year = 'PG';

	-- Alter the column data type to SMALLINT.
	ALTER TABLE public.tb_imdb ALTER COLUMN released_year TYPE SMALLINT
		USING released_year::SMALLINT;

/* end released_year */


-- certificate column
	/* Important notes:

	Certificates and guidelines are the four yellow boxes with black letters: U, UA, A and S
	
	The original ones were:
		- U (unrestricted public exhibition with family-friendly movies) 
		- A (restricted to adult audiences but any kind of nudity not allowed). 
		
		Two were added in 1983:
		- U/A (unrestricted public exhibition, with parental guidance for children under 12)
		- S (restricted to specialised audiences, such as doctors or scientists)
		
		Additionally, V/U, V/UA, V/A are used for video films with U, U/A and A carrying the same meaning as above
		
		Variations of the U/A certificate were introduced in November 2024: U/A 7+, U/A 13+ and U/A 16+.

		There is another classification from Motion Picture Association film rating system

		G – General Audiences 
		All ages admitted. Nothing that would offend parents for viewing by children.
		
		PG – Parental Guidance Suggested
		Some material may not be suitable for children. Parents urged to give "parental guidance". 
		
		PG-13 – Parents Strongly Cautioned
		Some material may be inappropriate for children under 13. Parents are urged to be cautious.
		Some material may be inappropriate for pre-teenagers.

		R – Restricted
		Under 17 requires accompanying parent or adult guardian. Contains some adult material.

		NC-17 – Adults Only
		No one 17 and under admitted. Clearly adult. Children are not admitted.


*/
	
	SELECT * FROM count_occurrences('public.tb_imdb', 'certificate');


	  /*|---------------|----------------|
		|  certificate  | num_occurences |
		|---------------|----------------|
		|  A            |           197  |
		|---------------|----------------|
		|  UA           |           175  |
		|---------------|----------------|
		|  R	        |           146  |
		|---------------|----------------|
		|  [null]       |           101  |
		|---------------|----------------|
		|  PG-13        |            43  |
		|---------------|----------------|
		|  PG           |            37  |
		|---------------|----------------|
		|  Passed       |            34  |
		|---------------|----------------|
		|  G            |            12  |
		|---------------|----------------|
		|  Approved     |            11  |
		|---------------|----------------|
		|  TV-PG        |             3  |
		|---------------|----------------|
		|  GP           |             2  |
		|---------------|----------------|
		|  16           |             1 |
		|---------------|----------------|
		|  TV-MA        |             1  |
		|---------------|----------------|
		|  U/A          |             1  |
		|---------------|----------------|
		|  TV-14        |             1  |
		|---------------|----------------|
		|  Unrated      |             1  |
		|---------------|----------------|*/			


	-- Adopted actions:
	-- replace G rating to its equivalent: A
	UPDATE public.tb_imdb set certificate = 'A' 
		WHERE certificate = 'G';

	-- replace PG AND GP AND TV-PG rating to their equivalent: UA
	UPDATE public.tb_imdb set certificate = 'UA' 
		WHERE certificate = 'PG' 
		OR certificate = 'GP'
		OR certificate = 'TV-PG';

	-- replace R rating to its equivalent: A
	UPDATE public.tb_imdb set certificate = 'A' 
		WHERE certificate = 'R';

	-- fix U/A
	UPDATE public.tb_imdb set certificate = 'UA' 
		WHERE certificate = 'U/A';

	-- replace TV-MA rating to its equivalent: A
	UPDATE public.tb_imdb set certificate = 'A' 
		WHERE certificate = 'TV-MA';

	-- I decided to change  PG-13, TV-14 to UA13 to maintain the pattern 
	UPDATE public.tb_imdb set certificate = 'UA13' 
		WHERE certificate = 'PG-13'
			OR certificate = 'TV-14'; 

	-- check 16
	SELECT  series_title, released_year FROM public.tb_imdb WHERE certificate = '16';
	-- "Koe no katachi"	2016: 

	-- Check Passed and Approved: movies released from 20's till 60's. Add to "Unrated"
	SELECT series_title, released_year FROM public.tb_imdb 
		WHERE certificate = 'Passed'
			OR certificate = 'Aproved';

	-- fill null with 'Unrated'?
	-- replace 16, Passed and Approved to Unrated
	-- in a real scenario I would do a scrape to find out the real ratings.
	UPDATE public.tb_imdb set certificate = 'Unrated' 
		WHERE certificate IS NULL
			OR certificate = 'Passed'
			OR certificate = 'Approved'
			OR certificate = '16';

/* end certificate */

--  runtime
	/*  Most datasets  recurrent errors appear in 
	the first 10 rows or so. In very large datasets, sampling is an alternative.
	In this case, I selected all rows because it is a small table. */


	SELECT * FROM count_occurrences('public.tb_imdb', 'runtime');

	-- no abnomalies where found, but the runtime adds 'min'. 
	-- I should remove it and alter the data type into integer.

	UPDATE public.tb_imdb SET 
		runtime = REGEXP_REPLACE(runtime, '[A-Za-z ]','','g' )

	ALTER TABLE public.tb_imdb ALTER COLUMN runtime TYPE SMALLINT
		USING runtime::SMALLINT

	-- check domain (0-400)
	  SELECT MIN(runtime), MAX(runtime) FROM public.tb_imdb
	  --  45 | 321

		SELECT series_title, released_year, runtime
		FROM public.tb_imdb
		WHERE runtime = (
		    SELECT MAX(runtime)
		    FROM public.tb_imdb
		);

		-- "Gangs of Wasseypur"	| 2012 | 321. 
		-- A very long movie indeed!

/* end runtime */

  ---  genre column

	SELECT * FROM count_occurrences('public.tb_imdb', 'genre');
	
	/* head(6)

	"Drama"	85
	"Drama, Romance"	37
	"Comedy, Drama"	35
	"Comedy, Drama, Romance"	31
	"Action, Crime, Drama"	30
	-----

	no inconsistences were found but it would be nice to create a 
	separate table to the genres and a relation between the movies 
	and the genres to 	use in  further analisys. 

	The SQL code to create this table is in 
	00_create_initial_tables.sql file
	
	*/
	

/* end genre */

-- imdb_rating

	SELECT * FROM count_occurrences('public.tb_imdb', 'imdb_rating');

	-- Alter column data type to FLOAT with one .
	ALTER TABLE public.tb_imdb ALTER COLUMN imdb_rating TYPE NUMERIC(3,1)
		USING imdb_rating::NUMERIC(3,1);

	-- check domain
	SELECT MIN(imdb_rating), MAX(imdb_rating) FROM public.tb_imdb;
	-- 7.6 | 9.3

/* end imdb_rating */

  -- overview 

	SELECT * FROM count_occurrences('public.tb_imdb', 'overview');

	-- no inconsistences were found
	-- nothing to do here

/* end   -- overview  */

  -- meta_score 
	
	SELECT * FROM count_occurrences('public.tb_imdb', 'meta_score');

	-- a lot of missing here (157 - 15,7%). 

	/* Note: 
		The METASCORE is a weighted average of reviews from top critics and 
		publications for a given movie, TV show, video game, or album as
		declared by Metacritic website.

		there may be a correlation with imdb_rating, or maybe not. 
		Movie critics know nothing! :)
		

		Options for handling missing data
			a) 	Exclude the column from the analysis.
				Advantage: simplicity, avoids imputation bias.
				Disadvantage: you lose a metric that can aggregate 
				information (expert(?) reviews <> audience rating).

			b)	Exclude only records with a null meta_score by creating
				an aux column "has_meta_score".
				Advantage: keeps the column intact.
				Disadvantage: reduces the sample size 
				(can bias the analysis if films without a 
				meta_score are not random).

			c) 	Simple (deterministic) imputation
				Replace nulls with the mean, median, or mode.
				Advantage: easy to implement directly in SQL.
				Disadvantage: flattens variability and can distort correlations.

			d) 	Advanced Imputation (Probabilistic/Predictive)
				Use regression or another model to predict meta_score based
				on imdb_rating, genre, year, etc.
				Advantage: Preserves data structure and reduces information loss.
				Disadvantage: Pure PostgreSQL does not have sophisticated
				built-in imputation algorithms.

		*/
		
		-- check nulls
		SELECT * FROM public.tb_imdb WHERE meta_score IS NULL;

		-- check domain
		SELECT MAX(imdb_rating), MIN(imdb_rating), AVG(imdb_rating) FROM public.tb_imdb
		WHERE meta_score IS NULL;
		-- MAX | MIN |  AVG  |
		-- 8.6 | 7.6 | 8.043 |

		/*
			I suppose most of the null values are movies not on mainstream, so they
			weren't rated by critics.
			
			After trying two different forms of imputation I decided leave at it is.
			The changes I made distorted data distribution too much. 15% is too much
			missing data.
			
			Before EDA I should use imputation algorithms such as KNNImputer,
			IterativeImputer, or regression models and then Reimport to Postgres.
		*/

		-- Alter data type to numeric
		
		ALTER TABLE public.tb_imdb ALTER COLUMN meta_score TYPE SMALLINT
			USING meta_score::SMALLINT

/* end   -- meta_score  */

  --  Director and Stars
	/*
		I already checked nulls before
		
		I created a single table tb_movie_crew to check mispelling
		from the columns director, star1, star2, star3, star4

		The SQL code to create this table is in 
		00_create_initial_tables.sql file
	*/

	-- check distance visual analisys needed
		
		CREATE EXTENSION fuzzystrmatch;
		SELECT a.participant as p1,
				b.participant as p2,
				levenshtein(a.participant,b.participant) as distance
			FROM public.tb_movie_participant a
			JOIN public.tb_movie_participant b
				ON a.participant < b.participant
			WHERE levenshtein(a.participant,b.participant) <= 3
			ORDER BY distance;

		-- No inconsistences found
	
/* end   -- Director and Stars  */


-- no_of_votes
	SELECT * FROM count_occurrences('public.tb_imdb', 'no_of_votes');

	-- no inconsistences were found
	ALTER TABLE public.tb_imdb ALTER COLUMN no_of_votes TYPE BIGINT
		USING no_of_votes::BIGINT

	-- check domain
	SELECT MIN(no_of_votes), MAX(no_of_votes) FROM public.tb_imdb;
	-- 25088, 	2343110


-- gross
	
	SELECT * FROM count_occurrences('public.tb_imdb', 'gross');

		-- too many null values 16,9%
		-- I might perform a regression with Python before starting the exploratory analysis.

	--check domain
	SELECT MIN(gross::numeric), MAX(no_of_votes::numeric) FROM public.tb_imdb;
	-- 1,000,045,	2,343,110

	-- values not currency
	SELECT gross FROM public.tb_imdb WHERE gross !~ '^[0-9,]+$';
	-- no result

	-- sample 
	SELECT gross FROM public.tb_imdb WHERE gross IS NOT NULL ORDER BY RANDOM () LIMIT 50;

	-- creating aux column to transform data
	-- shame on me. I did not use the staging table :(
	ALTER TABLE public.tb_imdb ADD COLUMN gross_num NUMERIC;

	-- update aux table with transformed data
	UPDATE public.tb_imdb SET gross_num = NULLIF(
			regexp_replace(gross, '[^0-9]', '', 'g'), ''
		)::NUMERIC;

	SELECT gross_num, COUNT(*) as num_occurences FROM public.tb_imdb
		GROUP BY gross_num ORDER BY COUNT(*) DESC;

	-- 1. Remove old column
	ALTER TABLE public.tb_imdb DROP COLUMN gross;

	-- 2. rename new column to gross
	ALTER TABLE public.tb_imdb
		RENAME COLUMN gross_num TO gross;

	--check domain again
	SELECT MIN(gross), MAX(no_of_votes) FROM public.tb_imdb;
	;-- 1305 | 2343110

