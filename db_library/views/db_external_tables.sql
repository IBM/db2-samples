--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all named (i.e. non transient) external tables
 */

CREATE OR REPLACE VIEW DB_EXTERNAL_TABLES AS
SELECT
    *
FROM
     SYSCAT.EXTERNALTABLEOPTIONS
