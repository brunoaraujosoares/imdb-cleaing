/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [functions.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03]
   VERSION: 1.0
======================================================================   
  OBJECTIVE:
    This file contains reusable PostgreSQL functions developed for the
    dataset cleaning and preprocessing project. Each function is designed
    to support data quality assessment, transformation, and analysis tasks,
    such as counting NULL values, standardizing formats, and other common
    dataset cleaning operations.

   DEPENDENCIES: None

   INPUT: Described in each function

   OUTPUT: Described in each function

   NOTES:
    - Functions are implemented in PL/pgSQL.
    - Ensure proper schema permissions before executing the functions.
    - Designed for PostgreSQL databases.
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
        - Designed for PostgreSQL using PL/pgSQL.
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

    Notes:
        - Implemented in PL/pgSQL.
        - Make sure you have UPDATE permissions on the target table.
        - Intended for PostgreSQL databases.
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

