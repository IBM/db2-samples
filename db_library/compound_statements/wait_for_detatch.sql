--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Waits until the background DETACH on a range partitioned table has completed
 * 
 * This ia a a simpler version of the code documented here
 * 
 *  https://www.ibm.com/developerworks/data/library/techarticle/dm-1110tablepartinfosphwhs/dm-1110tablepartinfosphwhs-pdf.pdf
 * 
 * With thanks to Mark  Barinstein
 */

BEGIN
  DECLARE V_LTIMEOUT,  V_DUMMY INT;
  DECLARE V_TABSCHEMA, V_TABNAME VARCHAR(128);
  DECLARE SQLSTATE CHAR(5);
  DECLARE CONTINUE HANDLER FOR SQLSTATE '40001' BEGIN END;
  --
  SET V_TABSCHEMA='DB2ADMIN', V_TABNAME='TEST_PART';
  VALUES CURRENT LOCK TIMEOUT INTO V_LTIMEOUT;
  SET CURRENT LOCK TIMEOUT 0;
  --
  L1: LOOP
    SELECT 1 INTO V_DUMMY
    FROM SYSCAT.DATAPARTITIONS
    WHERE TABSCHEMA = V_TABSCHEMA AND TABNAME = V_TABNAME AND STATUS IN ('D', 'L')
    FETCH FIRST 1 ROW ONLY
    WITH CS;
    IF SQLSTATE = '02000' THEN LEAVE L1; END IF;
    CALL DBMS_ALERT.SLEEP(3);
  END LOOP L1;
  --
  SET CURRENT LOCK TIMEOUT V_LTIMEOUT;
END
