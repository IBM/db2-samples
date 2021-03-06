--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Runs ST_MULTIPOLYGON but will return NULL if the function errors out with GSE3421N  Polygon is not closed."
 */

CREATE OR REPLACE FUNCTION DB_MULTIPOLYGON(I CLOB(2G), SRS_ID INT DEFAULT 4326)
    SPECIFIC DB_MULTIPOLYGON_CLOB
RETURNS ST_MULTIPOLYGON
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '38H15';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN NULL;
  --
  RETURN ST_MULTIPOLYGON(I, SRS_ID);
END
