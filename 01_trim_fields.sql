/* ====================================================================
   PROJECT: IMDB Data Cleaning (Kaggle dataset)
   FILE:    [0_trim_fields.sql]   
   AUTHOR:  Bruno Lucido - brunoaraujosoares@gmail.com
   DATE:    [2025-10-03]
   VERSION: 1.0
======================================================================
   OBJECTIVE: 

   DEPENDENCIES: None

   INPUT: None

   OUTPUT: Replace values on each column for trimmed ones

   NOTES:
=================================================================== */

	
DO $$
DECLARE
    p_column record;
BEGIN
    -- Loop sobre todas as colunas da tabela desejada
    FOR p_column IN
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
            AND table_name = 'tb_imdb'
        ORDER BY ordinal_position
    LOOP
        -- Monta e executa o UPDATE dinamicamente
        EXECUTE format(
            'UPDATE public.tb_imdb SET %I = TRIM(%I) WHERE %I IS NOT NULL',
            p_column.column_name,
            p_column.column_name,
            p_column.column_name
        );
    END LOOP;
END;
$$;
