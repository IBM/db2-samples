--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Changes Windows-1252 codepoints that have been incorrectly loaded as Latin-1 (ISO-8859-1) into their correct UTF-8 encoding
 *
 *  In other words, if you load data from a data source that proports to be Latin-1 but is actually Window-1252
 *  then you can use this function to fix the code point that have been invalidly mapped
 *  rather than re-loading with the correct source code-page specified
 * 
 *  The code works because Db2 simply adds x'C2' in front of the bytes in the  x'80' to x'9F' from the Windows-1252 encoding
 *  SO we can look for all pairs od byte sequences that start x'C2' and map them to the correct character
 *
*/

CREATE OR REPLACE FUNCTION DB_WIN1252_LATIN1_TO_UTF8(I VARCHAR(4000))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(4000)
RETURN (
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I
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
