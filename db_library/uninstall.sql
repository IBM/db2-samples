/*
Execute this from the CURRENT SCHEMA where you installed the db objects

it will DROP ALL OBJECTS THAT BEGIN `DB_` in the current schema ... SO USE WITH DUE CAUTION
Use @ as the statement terminator

*/
SET SCHEMA DB @

BEGIN FOR D AS 
    SELECT 'DROP VIEW ' || VIEWNAME AS DDL FROM SYSCAT.VIEWS 
    WHERE VIEWSCHEMA = CURRENT SCHEMA AND SUBSTR(VIEWNAME,1,3) = 'DB_'
      DO       EXECUTE IMMEDIATE D.DDL;
      END FOR;
END
@
BEGIN FOR D AS 
    SELECT 'DROP SPECIFIC FUNCTION ' || SPECIFICNAME || ' --'  || FUNCNAME AS DDL FROM SYSCAT.FUNCTIONS 
    WHERE FUNCSCHEMA = CURRENT SCHEMA AND SUBSTR(FUNCNAME,1,3) = 'DB_' ORDER BY FUNCNAME DESC
      DO       EXECUTE IMMEDIATE D.DDL;
      END FOR;
END
@
BEGIN FOR D AS 
    SELECT 'DROP VARIABLE ' || VARNAME AS DDL FROM SYSCAT.VARIABLES 
    WHERE VARSCHEMA = CURRENT SCHEMA AND SUBSTR(VARNAME,1,3) = 'DB_'
      DO       EXECUTE IMMEDIATE D.DDL;
      END FOR;
END
@
BEGIN FOR D AS 
    SELECT 'DROP TABLE ' || TABNAME AS DDL FROM SYSCAT.TABLES 
    WHERE TABSCHEMA = CURRENT SCHEMA AND SUBSTR(TABNAME,1,3) = 'DB_'
      DO       EXECUTE IMMEDIATE D.DDL;
      END FOR;
END
@

