--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * CASTs the input to an BIGINT but returns an error containing the value if it can't be cast to an BIGINT
 * 
 * We can't allow this UDF to be parallel, so it will cause performance issue if used in production code.
 * But it is fine for it's intended use of debuging things
 */

CREATE OR REPLACE FUNCTION DB_TO_BIGINT_DEBUG(i VARCHAR(64), msg VARCHAR(128) DEFAULT null) RETURNS BIGINT
    --CONTAINS SQL ALLOW PARALLEL   -- fails on MPP with SQL0487N if use these options
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN COALESCE(RAISE_ERROR('70001','Value "' || i || '"' || COALESCE(' for ' || msg || ' ','') ||' cannot be converted to BIGINT'),0);
  --
  RETURN CAST(i AS BIGINT);
END