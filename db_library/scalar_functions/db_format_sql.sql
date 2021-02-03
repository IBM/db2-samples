--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * A very simple SQL formatter - adds line-feeds before various SQL keywords and characters to the passed SQL code
 */

CREATE OR REPLACE FUNCTION DB_FORMAT_SQL(STMT_TEXT VARCHAR(32672 OCTETS)) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32672 OCTETS)
RETURN
    REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(VARCHAR(STMT_TEXT,30000)
        ,',((\s+\w+)|((sum)|(max)|(avg)|(min)|(row_number)|(rank)))' , CHR(10) ||',  \1',1,0,'i')
        ,'\s+((select)|(from)|(where)|(group by)|(having)|(((inner|left|full|right) )?(outer )?join))\s+'    ,CHR(10) || '\1' || CHR(10) ||'    ',1,0,'i')
        ,'(;)',CHR(10) || '\1' || CHR(10))
 