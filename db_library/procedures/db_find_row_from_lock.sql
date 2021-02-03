/*
 * Procedure to 
 * 
 * Takes from these (defunct) articles
 * 
 *  https://www.ibm.com/developerworks/community/blogs/wcs/entry/Finding_the_Row_Associated_to_a_Lock_in_DB2?lang=en
 *  https://www.ibm.com/developerworks/community/blogs/SQLTips4DB2LUW/entry/lock2row?lang=en
 * 
 * The latter of which is archived here
 *  https://community.ibm.com/community/user/hybriddatamanagement/viewdocument/have-lock-seek-row-a-handy-functi?CommunityKey=ea909850-39ea-4ac4-9512-8e2eb37ea09a&tab=librarydocuments&LibraryFolderKey=44bf3d32-40ec-406b-ba6e-797935f128a1&DefaultView=folder
 */


--#SET TERMINATOR @
CREATE OR REPLACE PROCEDURE LOCKTOROW(IN  lock      VARCHAR(32), 
                                      OUT tabschema VARCHAR(128),
                                      OUT tabname   VARCHAR(128),
                                      IN  mode      VARCHAR(10) DEFAULT ('SHORT'),
                                      IN  member    SMALLINT    DEFAULT (0))
 SPECIFIC LOCKTOROW READS SQL DATA NOT DETERMINISTIC NO EXTERNAL ACTION
 DYNAMIC RESULT SETS 1
BEGIN
  DECLARE stmttxt           VARCHAR(32000);
  DECLARE colname           VARCHAR(128);
  DECLARE lock_object_type  VARCHAR(255);
  DECLARE data_partition_id BIGINT;
  DECLARE rid               BIGINT DEFAULT NULL;
  DECLARE pageid            BIGINT;
  DECLARE stmt              STATEMENT;
  DECLARE res               CURSOR WITH RETURN TO CALLER FOR stmt;

  SET mode = UPPER(mode);
  IF mode NOT IN ('LONG', 'SHORT') THEN
    SIGNAL SQLSTATE '78000' SET MESSAGE_TEXT = 'Unknown mode [LONG|SHORT]';
  END IF;
  
  SELECT MAX(CASE WHEN NAME = 'LOCK_OBJECT_TYPE'  THEN VALUE END),
         MAX(CASE WHEN NAME = 'ROWID'             THEN VALUE END),
         MAX(CASE WHEN NAME = 'TABSCHEMA'         THEN VALUE END),
         MAX(CASE WHEN NAME = 'TABNAME'           THEN VALUE END),
         MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN VALUE END),
         MAX(CASE WHEN NAME = 'PAGEID'            THEN VALUE END)
    INTO lock_object_type, rid, tabschema, tabname, data_partition_id, pageid
    FROM TABLE(MON_FORMAT_LOCK_NAME(lock));

  IF rid IS NULL THEN 
    SIGNAL SQLSTATE '78000' SET MESSAGE_TEXT = 'Lock not found'; 
  END IF;

  IF lock_object_type <> 'ROW' THEN 
    SIGNAL SQLSTATE '78000' SET MESSAGE_TEXT = 'Not a ROW lock'; 
  END IF;

  SET colname = (SELECT colname 
                   FROM SYSCAT.COLUMNS 
                   WHERE TABNAME   = locktorow.tabname 
                        AND TABSCHEMA = locktorow.tabschema
                      AND colno = 0);

  IF mode = 'LONG' THEN                     
    SET stmttxt = 'SELECT * FROM "' || tabschema || '"."' || tabname || '" AS T'
               || ' WHERE RID(T) = ?'
                 || '   AND DBPARTITIONNUM(T."' || colname || '") = ? WITH UR';
  ELSE
    SET stmttxt = 'SELECT ';
    FOR col AS SELECT COLNAME,
                      TYPESCHEMA,
                      TYPENAME,
                      LENGTH                      
                 FROM SYSCAT.COLUMNS 
                 WHERE TABNAME   = locktorow.tabname 
                      AND TABSCHEMA = locktorow.tabschema
                 ORDER BY colno
    DO
      IF TYPESCHEMA = 'SYSIBM  ' 
         AND TYPENAME IN ('VARCHAR', 'VARGRAPHIC', 'CLOB', 'BLOB', 'DBCLOB')
         AND LENGTH > 30
      THEN
        SET stmttxt = stmttxt || 'SUBSTR("' || colname || '", 1, 30) AS "' || colname || '", ';
      ELSE    
        SET stmttxt = stmttxt || '"' || colname || '", ';
      END IF;
    END FOR;

    SET stmttxt = SUBSTR(stmttxt, 1, LENGTH(stmttxt) - 2)
               || ' FROM "' || tabschema || '"."' || tabname || '" AS T'
               || '  WHERE RID(T) = ?'
                 || '    AND DBPARTITIONNUM(T."' || colname || '") = ? WITH UR';
  END IF;
  PREPARE stmt FROM stmttxt;
  OPEN res USING data_partition_id * power(bigint(2),48) 
                   + pageid * power(bigint(2),16) + rid, 
                 member;
END
@