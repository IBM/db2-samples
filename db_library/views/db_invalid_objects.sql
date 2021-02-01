--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists any invalid or inoperative objects
 * 
 * Note that you can call 
 *    ADMIN_REVALIDATE_DB_OBJECTS()                         -- to revalidate all objects
 *    ADMIN_REVALIDATE_DB_OBJECTS(NULL, 'MY_SCHEMA', NULL)  -- to revalidate all objects in a given schema
 *    ADMIN_REVALIDATE_DB_OBJECTS('VIEW, NULL, NULL)        -- to revalidate all objects of a given type
 *   etc
 *
 * The view generates calls that will revalidate each individual object
 */

CREATE OR REPLACE VIEW DB_INVALID_OBJECTS AS
SELECT
--    I.*
   'call ADMIN_REVALIDATE_DB_OBJECTS(''' 
    || CASE OBJECTTYPE
    WHEN 'F' THEN CASE R.ROUTINETYPE WHEN 'F' THEN 'FUNCTION' WHEN 'P' THEN 'PROCEDURE' WHEN 'M' THEN 'METHOD' END
--    WHEN 'F' THEN 
    WHEN 'v' THEN 'GLOBAL_VARIABLE'
    WHEN '2' THEN 'MASK'
    WHEN 'y' THEN 'PERMISSION'
    WHEN 'B' THEN 'TRIGGER'
    WHEN 'R' THEN 'TYPE'
    WHEN '3' THEN 'USAGELIST'
    WHEN 'V' THEN 'VIEW'
    END
    || ''',''' || OBJECTSCHEMA || ''',''' || COALESCE(I.ROUTINENAME,OBJECTNAME) || ''')' AS REVALIDATE_STMT   
,   I.*
FROM
    SYSCAT.INVALIDOBJECTS I
LEFT OUTER JOIN
    SYSCAT.ROUTINES R 
ON
    R.ROUTINESCHEMA = I.OBJECTSCHEMA
AND R.ROUTINENAME   = I.ROUTINENAME
AND R.ROUTINEMODULENAME IS NOT DISTINCT FROM I.OBJECTMODULENAME
    
