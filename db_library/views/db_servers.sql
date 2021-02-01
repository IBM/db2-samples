--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all Federated Servers created on the database
 */

CREATE OR REPLACE VIEW DB_SERVERS AS
SELECT
    SERVERNAME     AS SERVER_NAME
,   WRAPNAME       AS WRAPPER
,   SERVERTYPE     AS SERVER_TYPE
,   SERVERVERSION  AS SERVER_VERSION
,   REMARKS
,   'CREATE SERVER "' || SERVERNAME || '" TYPE ' || SERVERTYPE || ' VERSION ''' || SERVERVERSION || ''' WRAPPER "' || WRAPNAME || '"'
    || COALESCE(' OPTIONS ' || CHR(10) || '(   ' || OPTIONS || CHR(10) || ')','')
        AS DDL
FROM
    SYSCAT.SERVERS
LEFT JOIN
(   SELECT SERVERNAME
    ,   LISTAGG(OPTION || ' ''' || SETTING || '''', CHR(10) || ',   ') WITHIN GROUP (ORDER BY CREATE_TIME)  AS OPTIONS
    FROM
        SYSCAT.SERVEROPTIONS
    GROUP BY
        SERVERNAME
) O
    USING ( SERVERNAME )