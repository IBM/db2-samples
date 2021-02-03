--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Database version and release information
 */

CREATE OR REPLACE VIEW DB_LEVEL AS
SELECT
    I.SERVICE_LEVEL
,   I.FIXPACK_NUM
,   I.BLD_LEVEL
,   I.PTF
,   S.OS_NAME
,   S.OS_VERSION
,   S.OS_RELEASE
,   S.HOST_NAME          
FROM
    SYSIBMADM.ENV_INST_INFO I
INNER JOIN
    SYSIBMADM.ENV_SYS_INFO  S
ON 1=1
