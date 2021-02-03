--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows predicates used in an access plan, and check if the filter factors have default values
 */

CREATE OR REPLACE VIEW DB_EXPLAIN_PREDICATES AS
SELECT
     DENSE_RANK() OVER(ORDER BY EXPLAIN_TIME DESC) AS SEQ
,    EXPLAIN_TIME
,    HOW_APPLIED || CASE WHEN WHEN_EVALUATED <> '' THEN ' ( ' || WHEN_EVALUATED || ')' ELSE '' END AS WHAT
,    CASE RELOP_TYPE
         WHEN 'EQ' THEN '=' WHEN 'NE' THEN '<>' WHEN 'NN' THEN 'NOT NULL' WHEN 'NL' THEN 'IS NULL'
         WHEN 'LT' THEN '<' WHEN 'LE' THEN '<=' WHEN 'GT' THEN '>' WHEN 'GE' THEN '>=' 
         WHEN 'LK' THEN 'LIKE' WHEN 'RE' THEN 'REGEXP'
         WHEN 'IN' THEN 'IN'  WHEN 'IC' THEN 'IN sort' WHEN 'IR' THEN 'IN sort rt'
                --IC  In list, sorted during query optimization
                --IR  In list, sorted at runtime
         ELSE RELOP_TYPE
         END 
                AS OP
,    SUBQUERY   AS SUB
,   CASE FILTER_FACTOR
        WHEN 0.03999999910593033 THEN 0.04      -- Equal / Is NULL
        WHEN 0.9599999785423279  THEN 0.96      -- Not equal / Is NOT NULL
        WHEN 0.3333333134651184  THEN 0.33      -- Range
        WHEN 0.1111110970377922  THEN 0.11111
        WHEN 0.555555522441864   THEN 0.55555
        WHEN 0.10000000149011612 THEN 0.1       -- IN / Like / Between
        WHEN 0.8999999761581421  THEN 0.89999   -- User defined function
        ELSE DECIMAL(FILTER_FACTOR,7,6) END            AS FF
,   CASE WHEN FILTER_FACTOR IN 
            ( 0.03999999910593033
            , 0.9599999785423279 
            , 0.3333333134651184 
            , 0.1111110970377922 
            , 0.555555522441864  
            , 0.10000000149011612
            , 0.8999999761581421 )
        THEN 'Y' ELSE 'N' END       AS GUESS
,    DECIMAL(1/ FILTER_FACTOR,31,1)        AS ONE_IN
,    PREDICATE_TEXT
,    RANGE_NUM
,    INDEX_COLSEQ
,    STMTNO
,    SECTNO
,    OPERATOR_ID
,    PREDICATE_ID
,    FILTER_FACTOR
,    RELOP_TYPE
,    CASE HOW_APPLIED
        WHEN 'BIT_FLTR'   THEN 'Predicate is applied as a bit filter'
        WHEN 'BSARG'      THEN 'Evaluated as a sargable predicate once for every block'
        WHEN 'DPSTART'    THEN 'Start key predicate used in data partition elimination'
        WHEN 'DPSTOP'     THEN 'Stop key predicate used in data partition elimination'
        WHEN 'ESARG'      THEN 'Evaluated as a sargable predicate by external reader'
        WHEN 'JOIN'       THEN 'Used to join tables'
        WHEN 'RANGE_FLTR' THEN 'Predicate is applied as a range filter'
        WHEN 'RESID'      THEN 'Evaluated as a residual predicate'
        WHEN 'SARG'       THEN 'Evaluated as a sargable predicate for index or data page'
        WHEN 'GAP_START'  THEN 'Used as a start condition on an index gap'
        WHEN 'GAP_STOP'   THEN 'Used as a stop condition on an index gap'
        WHEN 'START'      THEN 'Used as a start condition'
        WHEN 'STOP'       THEN 'Used as a stop condition'
        WHEN 'FEEDBACK'   THEN 'Zigzag join feedback predicate'
     END AS HOW_APPLIED_DESC
FROM
        SYSTOOLS.EXPLAIN_PREDICATE
