-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2011 All rights reserved.
-- 
-- The following sample of source code ("Sample") is owned by International 
-- Business Machines Corporation or one of its subsidiaries ("IBM") and is 
-- copyrighted and licensed, not sold. You may use, copy, modify, and 
-- distribute the Sample in any form without payment to IBM, for the purpose of 
-- assisting you in the development of your applications.
-- 
-- The Sample code is provided to you on an "AS IS" basis, without warranty of 
-- any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
-- IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
-- not allow for the exclusion or limitation of implied warranties, so the above 
-- limitations or exclusions may not apply to you. IBM shall not be liable for 
-- any damages you suffer as a result of using, copying, modifying or 
-- distributing the Sample, even if IBM has been advised of the possibility of 
-- such damages.
-----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: temporal_revert.db2
--    
-- SAMPLE: Creates the SQL procedure REVERT_TABLE_SYSTEM_TIME
--
-- To create the SQL procedure REVERT_TABLE_SYSTEM_TIME():
-- 1. Connect to your database
-- 2. At the OS prompt, enter the following command: 
--
--    db2 -td@ -vf temporal_revert.db2
--
--
-- To call the SQL procedure from the command line:
-- 1. Connect to your database
-- 2. Enter command such as the following:
--    db2 "call REVERT_TABLE_SYSTEM_TIME('DB2INST1', 'EMPLOYEES002', 
--       TIMESTAMP('2003-06-21-11.17.04.663397000000'), 'YES', 'empID > 50')";
--    You can also use tthe default value:
--    db2 "call REVERT_TABLE_SYSTEM_TIME('DB2INST1', 'EMPLOYEES002',
--       TIMESTAMP('2003-06-21-11.17.04.663397000000'))";
--
-- ----------------------------------------------------------------------------
-- 
-- REVERT_TABLE_SYSTEM_TIME
-- 
-- Purpose: The REVERT_TABLE_SYSTEM_TIME procedure reverts a system-period temporal 
-- table or a subset of its rows to a prior point in time. 
--
-- 
-- Syntax:
-- 
--    >>-REVERT_TABLE_SYSTEM_TIME-- (--tableschema--,--tablename--,+--timestamp--+-->
--                                                                                  
--    >--before--,--row_identifying_predicate--) ------------------------><
--        
-- Procedure parameters
-- 
--    tableschema
--       Schema of the table to revert.
--    tablename
--       Unqualified name of the table to revert. This table must be a 
--       system-period temporal table with versioning enabled.
--    timestamp
--       A past point in time that is used to revert the table. This point in time
--       can indicate one of two things:
--        (a) The exact point in time to which the table will be reverted, e.g. the 
--            time of the last known good state of the table. In this case, set the
--            parameter before to 'NO'.
--        (b) The timestamp of a bad transaction that needs to be undone, if the
--            table should be reverted to the state before this transaction. In this 
--            case, set the parameter before to 'YES'.
--
--       Example: TIMESTAMP ('2009-11-10-00.12.32.123456123456')
--                TIMESTAMP ('2009-11-10')
-- 
--    before
--       This parameter is optional and specifies how to revert the table.
--       There are two values for this parameter, 'YES' and 'NO'
--       YES: The table is reverted to last valid state before the specified timestamp.
--       NO:  The table is reverted to the state as it was at the specified timestamp. 
--       If this parameter is omitted, the default value is 'NO'. Must not be NULL.
-- 
--    row_identifying_predicate 
--       This parameter is optional and can specifiy a predicate that selects a subset 
--       of rows that need to be reverted. 
--
-- 
-- Authorization:
--   The user that invokes the stored procedure must have authorizations
--   to SELECT, INSERT and DELETE rows in the specified table.
-- 
-- Note:
--   The procedure performs the following checks to ensure a proper revert operation:
--     - Input parameters for tableschema, tablename, timestamp, before must not be null.
--     - The specified table must be system-period temporaql table.
--     - All input values have a valid format for the required data type.
-- 
-- 
-- Usage notes:
-- 1. DELETE and INSERT row-level triggers fire for each row that is 
--    deleted and each history rows that is reinserted into the base table.
-- 2. The REVERT_TABLE_SYSTEM_TIME procedure does not DELETE or change rows 
--    in the history table. On the contrary, any changes performed by the procedure 
--    are captured in the history table so that the revert operation itself can be
--    reverted if necessary.
-- 3. The procedures can be called mutliple times on the same tables, if needed.
-- 4. When REVERT_TABLE_SYSTEM_TIME is executed, the selected rows have
--    their data reverted, but their system time values are not reverted.
--    Instead, the new system start times for these rows will be the time of
--    executing the revert procedure.
-- 5. The procedures returns one of the following codes:
--    -9999 : means the target table is not a system-period temporal table
--    100   : means no change to target table was performed
--    -206  : means the specified row_identifying_predicate is incorrect
--    other : Other sqlcodes may be returned for other failures.
-- 6. If an error occurrs, any work performed in the unit of work 
--    that called the REVERT_TABLE_SYSTEM_TIME procedure is also rolled back. 
--    This behavior ensures that no table is changed if an error occurs.
-- 
-----------------------------------------------------------------------------
--
-- For more information on the sample scripts, see the README file.
--
-- For information on creating SQL procedures, see the Application
-- Development Guide.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2 
-- applications, visit the DB2 application development website: 
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------


--#SET TERMINATOR @

-- Drop all necessary type and SPs
DROP PROCEDURE GET_TABLE_COLUMN_NAME @
DROP PROCEDURE GET_HISTORY_TABLE_NAME @
DROP PROCEDURE REVERT_TABLE_SYSTEM_TIME @

-- This SP returns information about all columns in a table
CREATE PROCEDURE GET_TABLE_COLUMN_NAME ( IN schemaname     VARCHAR(128),
                                         IN tablename      VARCHAR(128),
                                         INOUT sys_start   VARCHAR(128),
                                         INOUT sys_end     VARCHAR(128),
                                         INOUT trans_start VARCHAR(128),
                                         INOUT result      VARCHAR(20000) )                                   

LANGUAGE SQL
-- Transaction has to be atomic if we
-- want to be able to roll back changes
BEGIN ATOMIC

  -- Get "SYSTEM_START", "SYSTEM_END", "TRANS_START" column names using SYSIBM.SYSCOLUMNS
  -- We also get other column names list in this SP.

    FOR conc AS
       SELECT name, identity FROM sysibm.syscolumns
       WHERE TBNAME = tablename and TBCREATOR = schemaname
    DO
       IF -- 'B' means ||sys_start|| column
          conc.IDENTITY = 'B' THEN SET sys_start = name ;
       ELSEIF -- 'E' means ||sys_end|| column
          conc.IDENTITY = 'E' then set sys_end = name ;
       ELSEIF -- 'S' means TRANS_START column
          conc.IDENTITY = 'S' THEN SET trans_start = name;
       ELSE
          SET result =  CASE WHEN COALESCE(result, '') = '' THEN '"' CONCAT name CONCAT '"'
                        ELSE result CONCAT ',' CONCAT '"' CONCAT name CONCAT '"'
                        END;
        END IF;
    END FOR;
END @

-- This SP returns all column names of an input table (excluding sys_start and sys_end)
-- in a comma-separated string
CREATE PROCEDURE GET_HISTORY_TABLE_NAME ( IN schemaname     VARCHAR(128),
                                          IN tablename      VARCHAR(128),
                                          INOUT hisfullname VARCHAR(257) )                                   

LANGUAGE SQL
-- Transaction has to be atomic if we
-- want to be able to roll back changes
BEGIN ATOMIC

  -- Get history table names using SYSCAT.PERIODS
  FOR conc AS 
      SELECT historytabname,historytabschema FROM syscat.periods 
      WHERE tabschema = schemaname AND tabname = tablename 
  DO
        SET hisfullname = case WHEN COALESCE(conc.historytabname, '') = '' THEN ''
        ELSE conc.historytabschema CONCAT '.' CONCAT conc.historytabname
        END;
  END FOR;
END @

-----------------------------------------------------------------------------------
-- The main revert stored procedure
CREATE PROCEDURE REVERT_TABLE_SYSTEM_TIME ( IN tschema                   VARCHAR(128),
                                            IN tname                     VARCHAR(128),
                                            IN pointInTime               TIMESTAMP, 
                                            IN before                    VARCHAR(3) default 'NO',                                      
                                            IN row_identifying_predicate VARCHAR(20000) default '1=1')

LANGUAGE SQL
-- Transaction has to be atomic if we
-- want to be able to roll back changes
BEGIN ATOMIC

-- Local variable declaration
   DECLARE del_stmt    VARCHAR(20000);
   DECLARE ins_stmt    VARCHAR(20000);

   -- pit = point in time
   DECLARE pit_strg    VARCHAR(50);

   DECLARE ret         INTEGER default 0;
   DECLARE result      VARCHAR(20000);
   DECLARE sys_start   VARCHAR(128);
   DECLARE sys_end     VARCHAR(128);
   DECLARE trans_start VARCHAR(128);
   DECLARE hisfullname VARCHAR(257);

   DECLARE sql_code    INTEGER default 0;
   DECLARE sqlcode     INTEGER default 0;
   
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET sql_code = sqlcode;
   DECLARE CONTINUE HANDLER FOR SQLWARNING SET sql_code = sqlcode;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET sql_code = sqlcode;

   SET pit_strg = CAST(pointInTime AS VARCHAR(50));

   -- Each time a table is reverted, result and hisfullname are first set to '' in order to
   -- retrieve correct table's column names
   SET result = '';
   SET hisfullname ='';

   CALL GET_TABLE_COLUMN_NAME (tschema, tname, sys_start, sys_end, trans_start, result);
   CALL GET_HISTORY_TABLE_NAME (tschema, tname, hisfullname);
   
   -- If we don't get a history table name, it means the given table is not a temporal table or
   -- that verisoning is not enabled. If we encouter either case, we return a error.
   IF hisfullname = '' THEN  
      SET ret = 1;
      GOTO nohistory;
   END IF;
   
   IF (UCASE(before)) = 'YES' THEN
      SET before = 'YES';
   ELSE
      SET before = 'NO';
   END IF;

   -- First, delete all rows where start time > pit.
   -- Then select all rows from history where start time < pit and end time > pit, 
   -- and insert them into the base table. 

   CASE 
      WHEN before='YES' THEN

         SET del_stmt = 'DELETE FROM "' || tschema || '"."' || tname || '"
                        WHERE '||sys_start||' >= timestamp(' || '''' || pit_strg || '''' || ')' ||
                        ' and '||sys_end||' = timestamp(''9999-12-30-00.00.00.000000000000'')' ||
                        ' and ('||row_identifying_predicate||')' ;
         SET ins_stmt = ' INSERT INTO "' || tschema || '"."' || tname || '" (' || result || ') 
                        SELECT ' || result ||
                        ' FROM '||hisfullname|| '
                        WHERE '||sys_start||' <  timestamp(' || '''' || pit_strg || '''' || ')' ||
                        ' and '||sys_end||' >  timestamp(' || '''' || pit_strg || '''' || ')' ||
                        ' and ('||row_identifying_predicate||') ' ;

         EXECUTE IMMEDIATE del_stmt;

         IF sql_code = 100 THEN
            SET ret = ret + 100;
         ELSEIF sql_code < 0 THEN
            RETURN sql_code;
         END IF;

         EXECUTE IMMEDIATE ins_stmt;
         
         IF sql_code = 100 THEN
            SET ret = ret + 100;
         ELSEIF sql_code < 0 THEN
            RETURN sql_code;
         END IF;

      WHEN before='NO' THEN

        SET del_stmt = 'DELETE FROM "' || tschema || '"."' || tname || '"
                       WHERE '||sys_start||' >= timestamp(' || '''' || pit_strg || '''' || ')' ||
                       ' and '||sys_end||' = timestamp(''9999-12-30-00.00.00.000000000000'')' ||
                       ' and ('||row_identifying_predicate||')' ;
        SET ins_stmt = ' INSERT INTO "' || tschema || '"."' || tname || '" (' || result || ') 
                       SELECT ' || result ||
                       ' FROM '||hisfullname|| '
                       WHERE '||sys_start||' <=  timestamp(' || '''' || pit_strg || '''' || ')' ||
                       ' and '||sys_end||' >=  timestamp(' || '''' || pit_strg || '''' || ')' ||
                       ' and ('||row_identifying_predicate||')';

         EXECUTE IMMEDIATE del_stmt;

         IF sql_code = 100 THEN
            SET ret = ret + 100;
         ELSEIF sql_code < 0 THEN
            RETURN sql_code;
         END IF;

         EXECUTE IMMEDIATE ins_stmt;
         
         IF sql_code = 100 THEN
            SET ret = ret + 100;
         ELSEIF sql_code < 0 THEN
            RETURN sql_code;
         END IF;

   END CASE;

nohistory :

   IF ret = 1 THEN  
      RETURN -9999;
   END IF;

   IF RET = 200 THEN 
      RETURN 100;
   END IF;

end @
