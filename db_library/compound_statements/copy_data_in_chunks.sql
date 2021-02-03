--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Example of copying 1 month of data at a time from one table into another
 * 
 * Best to use once a dictonary has been "primed" on the target via e.g. DB_BUILD_DICTONARY
 * 
 * TO-DO allow code to work if max date is 9999...
 */

CREATE TABLE COPY_LOG (
    FROM_DATE   DATE NOT NULL    
,   TS          TIMESTAMP(2) NOT NULL
--,   ROW_COUNT   BIGINT
)
@
BEGIN
    DECLARE MIN_DATE  DATE;  
    DECLARE MAX_DATE  DATE;
    DECLARE FROM_DATE DATE;
    DECLARE TO_DATE   DATE;
    --
    SELECT MIN("Business_Date"), MAX("Business_Date") INTO MIN_DATE, MAX_DATE
    FROM "DATAMART"."TRANSACTIONS" ;
    SET FROM_DATE = MIN_DATE;
    --
    WHILE FROM_DATE <= MAX_DATE
    DO
        SET TO_DATE = FROM_DATE + 1 MONTH;
        --  
        INSERT INTO   "DATAMART"."TRANSACTIONS_NEW"
        SELECT * FROM "DATAMART"."TRANSACTIONS"
        WHERE 
            "Business_Date" >= FROM_DATE
        AND "Business_Date" <  TO_DATE
        ORDER BY
            "Product_Group_Id", "Region_Id","Product_Id","Customer_Id","Transaction_DateTime";
        --
        INSERT INTO COPY_LOG
        VALUES ( FROM_DATE, CURRENT_TIMESTAMP );
        --
        COMMIT;
        SET FROM_DATE = TO_DATE;
    END WHILE;
END
