-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2007 All rights reserved.
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
-- SOURCE FILE NAME: checkv9limits.db2
--
-- SAMPLE: Check if any of the v9 identifier length limits have been 
--         exceeded in this database.  
--
-- SQL STATEMENTS USED:
--    SELECT
--    TERMINATE
--
-- Note: Use following command to execute the sample:
--         db2 -td@ -vf checkv9limits.db2
--
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Connect to 'sample' database
CONNECT TO SAMPLE @

-- This is a collection of queries that returns result sets similar to the
-- following format:
--    OBJECT_SCHEMA VARCHAR(128)
--    OBJECT_NAME   VARCHAR(128)
--    LENGTH        INTEGER
--    OLD_LIMIT     INTEGER
--
-- The result sets contain lists of the identifiers in the database
-- which have exceeded the old V9 identifier length limits.  The purpose
-- of this is for administrators to determine if any users or developers
-- have created large identifier names.  This allows administrators to 
-- ensure that the database and applications can handle longer identifier
-- names.  
-- For more information on identifier length limits, please refer to the
-- InfoCenter topic "SQL and XQuery Limits"

ECHO Checking for ATTRIBUTE NAME identifiers larger than 18 @
SELECT TYPESCHEMA, ATTR_NAME, LENGTH(ATTR_NAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.ATTRIBUTES
    WHERE LENGTH(ATTR_NAME) > 18 @

ECHO Checking for AUTHID identifiers larger than 30 @
SELECT AUTHID, LENGTH(AUTHID) AS LENGTH, INTEGER(30) AS OLDLIMIT
    FROM SYSIBMADM.AUTHORIZATIONIDS  
    WHERE AUTHIDTYPE = 'U' AND LENGTH(AUTHID) > 30 @

ECHO Checking for COLUMN NAME identifiers larger than 30 @
SELECT TABSCHEMA, COLNAME, LENGTH(COLNAME) AS LENGTH, INTEGER(30) AS OLDLIMIT
    FROM SYSCAT.COLUMNS 
    WHERE LENGTH(COLNAME) > 30 @

ECHO Checking for CONSTRAINT NAME identifiers larger than 18 @
SELECT TABSCHEMA, CONSTNAME, LENGTH(CONSTNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.CONSTDEP
    WHERE LENGTH(CONSTNAME) > 18 
  UNION 
  SELECT TABSCHEMA, CONSTNAME, LENGTH(CONSTNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.KEYCOLUSE
    WHERE LENGTH(CONSTNAME) > 18 
  UNION
  SELECT TABSCHEMA, CONSTNAME, LENGTH(CONSTNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.CHECKS
    WHERE LENGTH(CONSTNAME) > 18 @

ECHO Checking for EVENT MONITOR NAME identifiers larger than 18 @
SELECT EVMONNAME, LENGTH(EVMONNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.EVENTMONITORS
    WHERE LENGTH(EVMONNAME) > 18 @

ECHO Checking for GROUP identifiers larger than 30 @
SELECT AUTHID, LENGTH(AUTHID) AS LENGTH, INTEGER(30) AS OLDLIMIT
    FROM SYSIBMADM.AUTHORIZATIONIDS 
    WHERE AUTHIDTYPE = 'G' AND LENGTH(AUTHID) > 30 @

ECHO Checking for DBPARTITIONGROUP NAME identifiers larger than 18 @
SELECT DBPGNAME, LENGTH(DBPGNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.DBPARTITIONGROUPS
    WHERE LENGTH(DBPGNAME) > 18 @

ECHO Checking for PACKAGE NAME identifiers larger than 12 @
SELECT PKGSCHEMA, PKGNAME, LENGTH(PKGNAME) AS LENGTH, INTEGER(8) AS OLDLIMIT
    FROM SYSCAT.PACKAGES
    WHERE LENGTH(PKGNAME) > 12 @

ECHO Checking for SCHEMA NAME identifiers larger than 30 @
SELECT SCHEMANAME, LENGTH(SCHEMANAME) AS LENGTH, INTEGER(30) AS OLDLIMIT
    FROM SYSCAT.SCHEMATA
    WHERE LENGTH(SCHEMANAME) > 30 @

ECHO Checking for SPECIFIC NAME identifiers larger than 18 @
SELECT ROUTINESCHEMA, SPECIFICNAME, LENGTH(SPECIFICNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.ROUTINES
    WHERE LENGTH(SPECIFICNAME) > 18 @

ECHO Checking for FUNCPATH identifiers larger than 254 @
SELECT VARCHAR(FUNC_PATH) AS FUNCPATH, LENGTH(FUNC_PATH) AS LENGTH, INTEGER(254) AS OLDLIMIT
    FROM SYSCAT.VIEWS
    WHERE LENGTH(FUNC_PATH) > 254 
  UNION
  SELECT VARCHAR(FUNC_PATH) AS FUNCPATH, LENGTH(FUNC_PATH) AS LENGTH, INTEGER(254) AS OLDLIMIT
    FROM SYSCAT.CHECKS
    WHERE LENGTH(FUNC_PATH) > 254 
  UNION
  SELECT VARCHAR(FUNC_PATH) AS FUNCPATH, LENGTH(FUNC_PATH) AS LENGTH, INTEGER(254) AS OLDLIMIT
    FROM SYSCAT.TRIGGERS
    WHERE LENGTH(FUNC_PATH) > 254 
  UNION
  SELECT VARCHAR(FUNC_PATH) AS FUNCPATH, LENGTH(FUNC_PATH) AS LENGTH, INTEGER(254) AS OLDLIMIT
    FROM SYSCAT.PACKAGES
    WHERE LENGTH(FUNC_PATH) > 254 
  UNION
  SELECT VARCHAR(FUNC_PATH) AS FUNCPATH, LENGTH(FUNC_PATH) AS LENGTH, INTEGER(254) AS OLDLIMIT
    FROM SYSCAT.ROUTINES
    WHERE LENGTH(FUNC_PATH) > 254 @

ECHO Checking for TRIGGER NAME identifiers larger than 18 @
SELECT TRIGSCHEMA, TRIGNAME, LENGTH(TRIGNAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.TRIGGERS
    WHERE LENGTH(TRIGNAME) > 18 @

ECHO Checking for UDT NAME identifiers larger than 18 @
SELECT TYPESCHEMA, TYPENAME, LENGTH(TYPENAME) AS LENGTH, INTEGER(18) AS OLDLIMIT
    FROM SYSCAT.DATATYPES
    WHERE LENGTH(TYPENAME) > 18  @


-- Disconnect from the sample database
CONNECT RESET @

TERMINATE @
