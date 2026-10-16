-- (c) Copyright IBM Corp. 2026 All Rights Reserved.
--
-- SPDX-License-Identifier: Apache-2.0

-- =============================================================================
-- Trust Procedure Demonstration — DDL Setup
-- FILE: setup.sql
--
-- PURPOSE: Register the trust procedure, grant privileges, and create the
--          trusted context. Run connected as a user with SECADM authority.
--
-- USAGE:   db2 connect to $DB user $AUTHID using $PASSWORD
--          db2 -tvf setup.sql
--
-- NOTE: You will need to change the authid BOSS to your own authid that you
--       want to establish the trusted context for.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Register the trust procedure
--    Points at sqllib/function/trust_proc (deployed in Step 1)
--    NOT FENCED: acceptable for a demo; evaluate for production
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE DEMO.TRUST_PROC ()
    LANGUAGE C
    PARAMETER STYLE SQL
    READS SQL DATA
    EXTERNAL NAME 'trust_proc!trustProc'
    NOT FENCED;

-- -----------------------------------------------------------------------------
-- 2. Grant EXECUTE on the procedure to PUBLIC.
--    Covers the connecting authid and any future demo users.
-- -----------------------------------------------------------------------------
GRANT EXECUTE ON PROCEDURE DEMO.TRUST_PROC TO PUBLIC;

-- -----------------------------------------------------------------------------
-- 3. Create the trusted context for $AUTHID
--    No ADDRESS attribute — accepts connections from any host (demo only).
--    Add ADDRESS and/or ENCRYPTION attributes for production use.
-- -----------------------------------------------------------------------------
CREATE TRUSTED CONTEXT DEMO_TRUSTCTX
    BASED UPON CONNECTION USING SYSTEM AUTHID BOSS
    ENABLE
    ATTRIBUTES (TRUST PROCEDURE DEMO.TRUST_PROC);

-- -----------------------------------------------------------------------------
-- 4. Verification — confirm objects were created correctly
-- -----------------------------------------------------------------------------
SELECT
    c.CONTEXTNAME,
    a.ATTR_NAME,
    a.ATTR_VALUE
FROM SYSIBM.SYSCONTEXTS c
JOIN SYSIBM.SYSCONTEXTATTRIBUTES a
  ON a.CONTEXTID = c.CONTEXTID
WHERE c.CONTEXTNAME = 'DEMO_TRUSTCTX'
ORDER BY a.ATTR_NAME;
