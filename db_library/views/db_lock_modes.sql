--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Describes the possible values of the LOCK_MODE_CODE column
 */

CREATE OR REPLACE VIEW DB.DB_LOCK_MODES AS
SELECT * FROM TABLE(VALUES
    ( ''  , 'No Lock'                            ,'SQLM_LNON',  0 )
,   ( 'IS', 'Intention Share Lock'               ,'SQLM_LOIS',  1 )
,   ( 'IX', 'Intention Exclusive Lock'           ,'SQLM_LOIX',  2 )
,   ( 'S',  'Share Lock'                         ,'SQLM_LOOS',  3 )
,   ( 'SIX','Share with Intention Exclusive Lock','SQLM_LSIX',  4 )
,   ( 'X'  ,'Exclusive Lock'                     ,'SQLM_LOOX',  5 )
,   ( 'IN' ,'Intent None'                        ,'SQLM_LOIN',  6 )
,   ( 'Z'  ,'Super Exclusive Lock'               ,'SQLM_LOOZ',  7 )
,   ( 'U'  ,'Update Lock'                        ,'SQLM_LOOU',  8 )
,   ( 'NS' ,'Scan Share Lock'                    ,'SQLM_LONS',  9 )
,   ( 'NX' ,'Next-Key Exclusive Lock'            ,'SQLM_LONX', 10 )
,   ( 'W'  ,'Weak Exclusive Lock'                ,'SQLM_LOOW', 11 )
,   ( 'NW' ,'Next Key Weak Exclusive Lock'       ,'SQLM_LONW', 12 )
) T ( LOCK_MODE_CODE, LOCK_MODE, API_CONSTANT, LOCK_MODE_NUMBER)