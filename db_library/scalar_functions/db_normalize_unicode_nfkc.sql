--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Apply Unicode normalization NFKC (Normalization Form Compatibility Composition) rules to a string
 */

CREATE OR REPLACE FUNCTION DB_NORMALIZE_UNICODE_NFKC (S VARCHAR(32672 OCTETS)) RETURNS VARCHAR(32672 OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
    XMLCAST(XMLQUERY('fn:normalize-unicode($S, ''NFKC'')' ) AS VARCHAR(32672 OCTETS))
