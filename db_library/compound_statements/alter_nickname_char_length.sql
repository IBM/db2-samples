--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Increase the length of NICKNAME character columns
 * 
 * When you select data from the remote data source, that data is truncated if the character string conversion 
 *    results in a larger number of bytes than the size of the nickname column. 
 * 
 * This code will adjust the nickname column lengths for character columns. 
 * 
 * https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.data.fluidquery.doc/topics/rfpuni15.html
 *
 * The code below will automate this for you. Run it *once* to make you nickname column defiintions 4 times longer  :-)
 * 
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'ALTER NICKNAME "' || TABSCHEMA || '"."' || TABNAME || '"'
        ||     ' ALTER COLUMN "' || COLNAME || '"'
        ||     ' LOCAL TYPE ' || TYPENAME || '(' 
           || CASE TYPENAME 
                WHEN 'CHARACTER'  THEN CHAR(MIN(LENGTH * 4,   255)) || ' OCTETS )'
                WHEN 'VARCHAR'    THEN CHAR(MIN(LENGTH * 4, 32672)) || ' OCTETS )'
                WHEN 'GRAPHIC'    THEN CHAR(MIN(LENGTH * 2,   127)) || ')'
                WHEN 'VARGRAPHIC' THEN CHAR(MIN(LENGTH * 2, 16336)) || ')'
              END
            AS S1
        FROM SYSCAT.TABLES JOIN SYSCAT.COLUMNS USING (TABSCHEMA, TABNAME)
        WHERE TYPE = 'N'
        AND TYPENAME IN ( 'CHARACTER', 'VARCHAR' 
                        , 'GRAPHIC', 'VARGRAPHIC' )
        ORDER BY 
            TABSCHEMA
        ,   TABNAME
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S1;
--          COMMIT;
    END FOR;
END
