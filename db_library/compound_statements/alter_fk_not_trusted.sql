--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * For every TRUSTED FORIEGN KEY, ALTER it to be NOT TRUSTED
 * 
 * A more intelligent version of this script would only set FKs to NOT TRUSTED if they are indeed not true...
 * 
 */

BEGIN
FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
           'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" ALTER FOREIGN KEY "' || CONSTNAME || '"'  
        || ' NOT ENFORCED NOT TRUSTED'      AS ALTER_FK
    FROM
        SYSCAT.TABCONST C
    WHERE  
        C.TYPE = 'F'
    AND C.ENFORCED = 'N'
    AND C.TRUSTED  = 'Y'
    AND SUBSTR(C.TABSCHEMA,1,3) NOT IN ('SYS','IBM','DB2')
    AND TABSCHEMA = 'YOUR_SCHEMA'
    WITH UR
DO
      EXECUTE IMMEDIATE C.ALTER_FK;
      COMMIT;
END FOR;
END
