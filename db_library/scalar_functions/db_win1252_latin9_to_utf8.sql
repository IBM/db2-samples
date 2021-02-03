--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0
 
/*
 * Changes Windows-1252 codepoints that have been incorrectly loaded as Latin-9 (ISO-8859-15) into their correct UTF-8 encoding
 *
 * In other words, if you load data from a Netezza CHAR/VARCHAR column into Db2 using EXTERNAL TABLE and the default assumption that the data will be in Latin-9
 * but you find that the characters from x'80' to x'9F' are now invalid in UTF-8
 * then you can use this function to fix them rather than reloading the data
 *
 * The code works because Db2 simply adds x'C2' in front of the bytes in the  x'80' to x'9F' from the Windows-1252 encoding
 *   
 *   The function maps any instances of those double bytes into the correct UTF-8 character
 *   
 *   Also note that this function will re-map the 8 character that differ between Latin-1 and Latin-9, as per this table
 *   
 *                        A4  A6  A8  B4  B8  BC  BD  BE
 *     Latin-1 / 8859-1    ¤   ¦   ¨   ´   ¸   ¼   ½   ¾
 *     latin-9 / 8859-15   €   Š   š   Ž   ž   Œ   œ   Ÿ
 *   
 *   This works for windows-1252 as it is a superset of Latin-1.
 *   
 *   If you don't want this extra mapping, us the DB_WIN1252_LATIN1_TO_UTF8() function instead
 */

CREATE OR REPLACE FUNCTION DB_WIN1252_LATIN9_TO_UTF8(I VARCHAR(4000))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(4000)
RETURN (
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I
    ,'€','¤')
    ,'Š','¦')
    ,'š','¨')
    ,'Ž','´')
    ,'ž','¸')
    ,'Œ','¼')
    ,'œ','½')   
    ,'Ÿ','¾')
    ----
    ,x'C280','€') --E282AC
    --
    ,x'C282','‚') --E2809A
    ,x'C283','ƒ') --C692
    ,x'C284','„') --E2809E
    ,x'C285','…') --E280A6
    ,x'C286','†') --E280A0
    ,x'C287','‡') --E280A1
    ,x'C288','ˆ') --CB86
    ,x'C289','‰') --E280B0
    ,x'C28A','Š') --C5A0
    ,x'C28B','‹') --E280B9
    ,x'C28C','Œ') --C592
    --
    ,x'C28E','Ž') --C5BD
    --
    ,x'C291','‘') --E28098
    ,x'C292','’') --E28099
    ,x'C293','“') --E2809C
    ,x'C294','”') --E2809D
    ,x'C295','•') --E280A2
    ,x'C296','–') --E28093
    ,x'C297','—') --E28094
    ,x'C298','˜') --CB9C
    ,x'C299','™') --E284A2
    ,x'C29A','š') --C5A1
    ,x'C29B','›') --E280BA
    ,x'C29C','œ') --C593
    ,x'C29E','ž') --C5BE
    ,x'C29F','Ÿ') --C5B8
   )
