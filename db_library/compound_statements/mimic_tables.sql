--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Mimic Statistics for tables, columns, indexes etc
 * 
 * From (and optionally offline copy of) the following catalog views
 *  
 *    SYSCAT.TABLES
 *    SYSCAT.COLUMN
 *    SYSCAT.COLDIST
 *    etc
 * 
 * Update the statistics of a copy your given tables
 * 
 * I.e. do what db2look does in -m  mimic mode, but via SQL..
 * 
 * Currently only coded for TABLE stats. INDEX, COLUMN, COLDIST, GOLCOUP, VIEW stats are a TO-DO
 * 
 *  guidelines that you should follow when updating statistics in the SYSSTAT.TABLES catalog view.
 *  https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.admin.perf.doc/doc/c0005124.html
 * 
 */

-- Table stats
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT  TABNAME vTABNAME, TABSCHEMA vTABSCHEMA
        , CARD vCARD, NPAGES vNPAGES--, MPAGES vMPAGES     -- Not sure if MPAGES (col meta pages) needs to be updated. It gives SQL1227N sometimes
        , FPAGES vFPAGES, OVERFLOW vOVERFLOW, ACTIVE_BLOCKS vACTIVE_BLOCKS
        FROM
            TABLES
        WHERE
            TYPE = 'T'
        AND TABSCHEMA = 'your schema'
        AND TABNAME IN  ('your tables')
        MINUS
        SELECT  TABNAME vTABNAME, TABSCHEMA vTABSCHEMA
        , CARD vCARD, NPAGES vNPAGES--, MPAGES vMPAGES
        , FPAGES vFPAGES, OVERFLOW vOVERFLOW, ACTIVE_BLOCKS vACTIVE_BLOCKS
        FROM
            SYSCAT.TABLES
        ORDER BY
            vTABSCHEMA, vTABNAME
    DO
          UPDATE SYSSTAT.TABLES 
          SET ( CARD, NPAGES, /*MPAGES,*/ FPAGES, OVERFLOW, ACTIVE_BLOCKS ) 
           =  (vCARD,vNPAGES,/*vMPAGES,*/vFPAGES,vOVERFLOW,vACTIVE_BLOCKS )
          WHERE ( TABNAME, TABSCHEMA  )
          =     (vTABNAME, vTABSCHEMA)
          ;
          COMMIT;
    END FOR;
END

/*

The aim is to generate and run the following kind of statements

RUNSTATS ON TABLE "DB2V11  "."T" WITH DISTRIBUTION ON COLUMNS (
                "K" NUM_FREQVALUES 3 NUM_QUANTILES 3,
                "I" NUM_FREQVALUES 3 NUM_QUANTILES 3,
                "J" NUM_FREQVALUES 3 NUM_QUANTILES 3);

UPDATE SYSSTAT.INDEXES
SET ( NLEAF,NLEVELS,FIRSTKEYCARD,FIRST2KEYCARD,FIRST3KEYCARD,FIRST4KEYCARD,FULLKEYCARD,CLUSTERFACTOR,CLUSTERRATIO,SEQUENTIAL_PAGES,PAGE_FETCH_PAIRS
,DENSITY,AVERAGE_SEQUENCE_GAP,AVERAGE_SEQUENCE_FETCH_GAP,AVERAGE_SEQUENCE_PAGES,AVERAGE_SEQUENCE_FETCH_PAGES
,AVERAGE_RANDOM_PAGES,AVERAGE_RANDOM_FETCH_PAGES,NUMRIDS,NUMRIDS_DELETED,NUM_EMPTY_LEAFS,INDCARD )
= (-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,'',-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1)
WHERE TABNAME = 'T' AND TABSCHEMA = 'DB2V11  '
   
--UPDATE SYSSTAT.COLUMNS
--SET (COLCARD, NUMNULLS) = (-1,-1)
--WHERE TABNAME = 'T' AND TABSCHEMA = 'DB2V11  ';

UPDATE SYSSTAT.TABLES
SET CARD, NPAGES, MPAGES, FPAGES, OVERFLOW, ACTIVE_BLOCKS) = (3,1,0,1,0,0)
WHERE TABNAME = 'T' AND TABSCHEMA = 'DB2V11  ';

UPDATE SYSSTAT.COLUMNS
SET ( COLCARD,NUMNULLS,SUB_COUNT,SUB_DELIM_LENGTH,PCTENCODED,AVGCOLLENCHAR,PAGEVARIANCERATIO,AVGENCODEDCOLLEN,AVGCOLLEN )
= ( 1,0,-1,-1,-1,-1,-1.000000,-1.000000,5 )
WHERE COLNAME = 'I' AND TABNAME = 'T' AND TABSCHEMA = 'DB2V11  '

UPDATE SYSSTAT.COLDIST
SET ( COLVALUE,  VALCOUNT) = ('AA','-3')
WHERE COLNAME = 'I' AND TABNAME = 'T' AND TABSCHEMA = 'DB2V11  '  AND TYPE  = 'F'  AND SEQNO = 1

*/