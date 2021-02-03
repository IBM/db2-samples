--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 Create this table
 
 CREATE TABLE DB_HASH_COMPARE_GROUPED
    (   
        TABSCHEMA    VARCHAR(128)
    ,   TABNAME      VARCHAR(128)
    ,   GROUP_COL1       VARCHAR(128)
    ,   GROUP_COL2       VARCHAR(128)
    ,   GROUP_COL3       VARCHAR(128)
    ,   GROUP_COL4       VARCHAR(128)
    ,   COLNO        SMALLINT
    ,   COLNAME      VARCHAR(128)
    ,   SUM_HASH     DECIMAL(31,0)
    )

  Run like e.g this

DELETE FROM DB_HASH_COMPARE_GROUPED WHERE 1=1

CALL DB_GEN_HASH_COMPARE_GROUPED('PAUL','TABLE','"YEAR","MONTH"','SALES,null,null,null','XD > 2','SALES,null,null,null')

SELECT * FROM DB_HASH_COMPARE_GROUPED

or

CALL DB_GEN_HASH_COMPARE_GROUPED('PAUL','TABLE','"YEAR","MONTH"','SUBSTR(STATUS,1,1) STATUS,null,null,null','XD > 2','STATUS,null,null,null')

  *  */


@
    
CREATE OR REPLACE PROCEDURE DB_GEN_HASH_COMPARE_GROUPED ( 
    DB_HASH_COMPARE_SCHEMA  VARCHAR(128)
,   DB_HASH_COMPARE_TABLE   VARCHAR(128)
,   DB_HASH_COMPARE_COLUMNS VARCHAR(512)
,   DB_HASH_COMPARE_GROUP   VARCHAR(512) 
,   DB_HASH_COMPARE_FILTER  VARCHAR(512) DEFAULT NULL
,   DB_HASH_COMPARE_GROUP_NAMES  VARCHAR(512) DEFAULT NULL
)
BEGIN
/*
    Generates SQL that will return a set containing 
    -  a count of rows
    -  a total HASH of all rows
    -  a HASH value for one column GROUPED BY some set of columns
    
    Usefull for drilling down into what sub-set of rows contain the mis-match

*/
    DECLARE SQL_STMT VARCHAR(32672 OCTETS)
    ;
    SET SQL_STMT = (
      SELECT  'INSERT INTO DB_HASH_COMPARE_GROUPED SELECT'
        ||  CHR(10) || '     ''' || RTRIM(TABSCHEMA) || ''' AS TABSCHEMA'   
        ||  CHR(10) || ',    ''' || RTRIM(TABNAME)   || ''' AS TABNAME'
        || CASE WHEN DB_HASH_COMPARE_GROUP IS NOT NULL THEN CHR(10) || ',    ' || COALESCE(DB_HASH_COMPARE_GROUP_NAMES,DB_HASH_COMPARE_GROUP) ELSE '' END
        ||  CHR(10) || ',    PIVOT.*'
        ||  CHR(10) || 'FROM (' 
        ||  CHR(10) || '    SELECT'
        ||  CHR(10) || '        COUNT(*) AS COUNT_OF_ROWS'
        || CASE WHEN DB_HASH_COMPARE_GROUP IS NOT NULL THEN CHR(10) || ',        ' || DB_HASH_COMPARE_GROUP ELSE '' END
        ||  CHR(10) || '    ,    SUM((' ||  LISTAGG(VARCHAR('C' || COLNO,32000) , '::DECIMAL(31,0)+ ') WITHIN GROUP (ORDER BY COLNO)
        ||  CHR(10) || '        )::DECIMAL(31,0)) AS HASH_OF_ROWS'
        ||  CHR(10) || '    ,    ' ||  LISTAGG(VARCHAR('SUM(C' || COLNO || '::DECIMAL(31,0)) AS S' || COLNO || '',32000), ', ') WITHIN GROUP (ORDER BY COLNO)
        ||  CHR(10) || '    FROM ('     
        ||  CHR(10) || '        SELECT   ' 
        || CASE WHEN DB_HASH_COMPARE_GROUP IS NOT NULL THEN CHR(10) || DB_HASH_COMPARE_GROUP || ',' ELSE '' END
        || LISTAGG(VARCHAR(CASE WHEN C.NULLS = 'Y' THEN 'COALESCE(' ELSE '' END 
        || 'HASH4('
    	    || CASE WHEN COALESCE(D.SOURCENAME,C.TYPENAME) = 'XML' THEN 'XMLSERIALIZE(' 
                       WHEN COALESCE(D.SOURCENAME,C.TYPENAME) IN ('DOUBLE','REAL')  THEN 'CAST(ROUND('
    	               WHEN D.SOURCENAME IS NOT NULL OR COALESCE(D.SOURCENAME,C.TYPENAME) IN ('XML','DATE')  THEN 'CAST('     
    	               ELSE '' END
           || CASE WHEN COALESCE(D.SOURCENAME,C.TYPENAME) LIKE '%CHAR%' OR COALESCE(D.SOURCENAME,C.TYPENAME) LIKE '%GRAPHIC%' THEN 'RTRIM(' ELSE '(' END
    	                      || '"' || COLNAME || '")' || CASE WHEN COALESCE(D.SOURCENAME,C.TYPENAME) = 'XML'  THEN ' AS CLOB(1G))'
    	                                                       WHEN COALESCE(D.SOURCENAME,C.TYPENAME) = 'DATE' THEN ' AS INTEGER)'
                                                               WHEN COALESCE(D.SOURCENAME,C.TYPENAME) IN ('DOUBLE','REAL') THEN ',8) AS DECIMAL(31,8))'
    	                                                       WHEN D.SOURCENAME IS NOT NULL THEN ' AS ' || SOURCENAME || ')  '  ELSE '' END
         || ')' || CASE WHEN C.NULLS = 'Y' THEN ',' || HASH4(COLNAME) || ')' ELSE '' END 
                    || ' AS C' || COLNO,32000), CHR(10)||',       ') WITHIN GROUP (ORDER BY COLNO)
        ||  CHR(10) || ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
        ||  CASE WHEN DB_HASH_COMPARE_FILTER IS NOT NULL AND DB_HASH_COMPARE_FILTER <> '' THEN CHR(10) || ' WHERE ' || DB_HASH_COMPARE_FILTER || CHR(10) ELSE '' END
        || ') AS T'
        || CASE WHEN DB_HASH_COMPARE_GROUP IS NOT NULL THEN CHR(10) || 'GROUP BY ' || COALESCE(DB_HASH_COMPARE_GROUP_NAMES,DB_HASH_COMPARE_GROUP) ELSE '' END
        || ') AS S'
        ||  CHR(10) || ', LATERAL(VALUES  (NULL,''_COUNT_OF_ROWS_'', COUNT_OF_ROWS),(NULL,''_HASH_OF_ROWS_'', HASH_OF_ROWS)'
        ||  CHR(10) || ',            ' || LISTAGG(VARCHAR('('||COLNO||', ''' || COLNAME || ''', S' || COLNO || ')',32000) , CHR(10)||',           ') WITHIN GROUP (ORDER BY COLNO)
        ||  CHR(10) || ') AS PIVOT(COLNO, COLNAME, HASH_VALUE)  '
    FROM
        SYSCAT.COLUMNS C
    INNER JOIN
        SYSCAT.DATATYPES D USING ( TYPESCHEMA, TYPENAME )
    WHERE
            TABSCHEMA  = DB_HASH_COMPARE_SCHEMA
    AND     TABNAME    = DB_HASH_COMPARE_TABLE
--    AND   COLNAME'   = DB_HASH_COMPARE_COLUMN
    AND     DB_HASH_COMPARE_COLUMNS LIKE '%"' || COLNAME || '"%'
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    WITH UR
    )
    ;
    EXECUTE IMMEDIATE SQL_STMT
    ;
    RETURN 0
    ;
END
    