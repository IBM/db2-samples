--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Split a deliminated string into multiple rows
 * 
 *  Note that there are othwe ways of doing this kind of split
 *  On SMP servers use can use a table function that outputs rows via PIPE()
 *  If you know the max number of items in your list, a simple cross product and e.g. REGEXP_EXTRACT will perform the best
 *  
 * Adapated from this article
 * 
 * https://community.ibm.com/community/user/hybriddatamanagement/viewdocument/how-to-split-a-string-into-a-set-of?CommunityKey=ea909850-39ea-4ac4-9512-8e2eb37ea09a&tab=librarydocuments&LibraryFolderKey=44bf3d32-40ec-406b-ba6e-797935f128a1&DefaultView=folder
 * 
 * which used to be hosted here
 *    https://www.ibm.com/developerworks/community/blogs/SQLTips4DB2LUW/entry/how_to_split_a_string_into_a_set_of_rows_anti_listagg12?lang=en
*/
CREATE OR REPLACE FUNCTION DB_SPLIT_STRING(text CLOB, delimiter VARCHAR(10))
SPECIFIC DB_SPLIT_STRING_CLOB
RETURNS TABLE(rn INTEGER, val VARCHAR(4000))
RETURN WITH rec(rn, val, pos) AS
(   VALUES (
        1
    ,   SUBSTR(text, 1, CASE INSTR(text, delimiter, 1) WHEN 0 THEN LENGTH(text) ELSE INSTR(text, delimiter, 1)  - 1 END )
    ,   INSTR(text, delimiter, 1) + LENGTH(delimiter)
    )
UNION ALL
    SELECT
        rn + 1
    ,   SUBSTR(text, pos, CASE INSTR(text, delimiter, pos) WHEN 0 THEN LENGTH(text) - pos + 1 ELSE INSTR(text, delimiter, pos) - pos END)
   ,    INSTR(text, delimiter, pos) + LENGTH(delimiter)
    FROM
        rec 
    WHERE 
        rn <= 2000000000    --- some number to stop the SQL0357W warning " ‪The‬‎ ‪recursive‬‎ ‪common‬‎ ‪table‬‎ ‪expression‬‎ ‪‬‎‪may‬‎ ‪contain‬‎ ‪an‬‎ ‪infinite‬‎ ‪loop‬‎"
    AND pos > LENGTH(delimiter)
)
SELECT rn, val
FROM rec
WHERE delimiter IS NOT NULL AND LENGTH(delimiter) > 0
