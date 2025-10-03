/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [functions.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03]
   VERSION: 1.0
======================================================================   
  OBJECTIVE:
    This file contains reusable PostgreSQL functions developed for the
    dataset cleaning and preprocessing project. Functions included here
    support tasks such as data quality assessment, standardization of
    text columns, and analysis of categorical distributions.

USAGE:
    - Run this script before the other scripts to store the functions
      in the database
    - Each function is self-contained and can be called independently.


   DEPENDENCIES: None

   INPUT: Described in each function

   OUTPUT: Described in each function

   NOTES:
    - Functions are implemented in PL/pgSQL.
    - Ensure proper schema permissions before executing the functions.
    - Designed for PostgreSQL databases.

  TODO
    - Include or source this file in SQL scripts where dataset cleaning
      functions are needed.

=================================================================== */


/*
    Function: public.count_null

    Purpose:
        Counts the number of NULL or empty ('') values for each column in a specified table
        within a given schema. Returns the count, total number of rows, and the percentage
        of NULL/empty values per column.

    Parameters:
        p_schema TEXT - The schema name where the target table resides.
        p_table  TEXT - The table name to analyze.

    Returns:
        TABLE with columns:
            column_name TEXT     - Name of the column.
            null_count  SMALLINT - Number of NULL or empty values in the column.
            total_count SMALLINT - Total number of rows in the table.
            pct_null    NUMERIC(5,2) - Percentage of NULL/empty values (0-100).

    Behavior:
        - Iterates through all columns of the specified table.
        - Counts both NULL and empty string values per column.
        - Calculates the percentage of NULL/empty values relative to the total row count.
        - Returns one row per column with the computed statistics.
        - If the table is empty, pct_null is returned as 0 to avoid division by zero.

    Usage:
        SELECT * FROM public.count_null('public', 'my_table');

    Notes:
        - Only works for columns of types compatible with '' (empty string) comparison.
*/



CREATE OR REPLACE FUNCTION public.count_null(
    p_schema TEXT,
    p_table  TEXT
)
RETURNS TABLE(
    column_name text,
    null_count smallint,
    total_count smallint,
    pct_null numeric(5,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    c RECORD;
    total_rows smallint;
    n smallint;
BEGIN
    -- count num rows
    EXECUTE format('SELECT COUNT(*) FROM %I.%I', p_schema, p_table) INTO total_rows;

    FOR c IN
        SELECT c2.column_name
        FROM information_schema.columns c2
        WHERE c2.table_schema = p_schema
            AND c2.table_name   = p_table
        ORDER BY c2.ordinal_position
    LOOP
        -- count NULL and empty 
        EXECUTE format(
            'SELECT COUNT(*) FROM %I.%I WHERE %I IS NULL OR %I = '''' ',
            p_schema, p_table, c.column_name, c.column_name
        ) INTO n;
        -- find percentage (already check zero division)
        IF total_rows = 0 THEN
            pct_null := 0;
        ELSE
            pct_null := round((n::numeric / total_rows::numeric) * 100.0, 2);
        END IF;

        -- assign return values
        column_name := c.column_name;
        null_count  := n;
        total_count := total_rows;
        RETURN NEXT;
    END LOOP;
END;
$$;

/*
end    Function: public.count_null
*/

/*
    Function: public.trim_column

    Purpose:
        Removes leading and trailing whitespace from all values in a specified
        column of a table. Useful for dataset cleaning to standardize string data
        and prevent issues with comparisons or joins caused by extra spaces.

    Parameters:
        t_name TEXT - Name of the target table.
        c_name TEXT - Name of the column to trim.

    Returns:
        VOID - The function performs an in-place update on the specified column.

    Behavior:
        - Iterates over all rows of the table and applies the TRIM function
          to remove spaces at the beginning and end of the string values.
        - Can be applied to any text-based column (CHAR, VARCHAR, TEXT).

    Usage:
        SELECT trim_column('table_name', 'column_name');


*/


CREATE OR REPLACE FUNCTION trim_column(
    t_name text,
    c_name text
)
RETURNS void AS
$$
BEGIN
    EXECUTE format(
        'UPDATE %I SET %I = TRIM(%I)',
        t_name,
        c_name,
        c_name
    );
END;
$$
LANGUAGE plpgsql;
/*
end Function: public.trim_column
*/

/*
    Function: public.count_occurrences

    Purpose:
        Counts the number of occurrences of each distinct value in a specified
        column of a table. Returns a summary of values and their frequencies,
        ordered by descending count. Useful for analyzing categorical data
        distributions and detecting common or rare values.

    Parameters:
        t_name TEXT - Name of the target table.
        c_name TEXT - Name of the column to analyze.

    Returns:
        TABLE with columns:
            column_value TEXT      - The distinct value from the column (cast to text).
            num_occurrences BIGINT - Number of times the value appears in the column.

    Usage:
        SELECT * FROM count_occurrences('table_name', 'column_name');

    Notes:
        - Works with any column type that can be cast to text.
        - Intended for PostgreSQL databases.
*/
CREATE OR REPLACE FUNCTION count_occurrences(
    t_name text,
    c_name text
)
RETURNS TABLE(column_value text, num_occurrences bigint) AS
$$
BEGIN
    RETURN QUERY EXECUTE format(
        'SELECT %I::text, COUNT(%I) AS num_occurrences
            FROM %I
            GROUP BY %I
            ORDER BY COUNT(%I) DESC',
        c_name,  -- SELECT
        c_name,  -- COUNT
        t_name,  -- FROM
        c_name,  -- GROUP BY
        c_name   -- ORDER BY
    );
END;
$$
LANGUAGE plpgsql;
/*
  end Function: public.count_occurrences
*/

