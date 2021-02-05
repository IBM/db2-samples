--# (C) Copyright IBM Corp. 2020 All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

--# db-library version  1.0

/*
If you do not have e.g. the EXPLAIN tables or ADMIN_MOVE_TABLE in SYSTOOLS one or two views will fail
  as some views depend on objects in SYSTOOLS schema.

      You can either ignore such errors, or create the missing objects as follows
       
                    CALL SYSINSTALLOBJECTS('explain', 'c', '', '')
                    @
                    SET SCHEMA SYSTOOLS
                    @
                    CREATE TABLE ADMIN_MOVE_TABLE
                    (
                        TABSCHEMA    VARCHAR(128 OCTETS) NOT NULL
                    ,   TABNAME      VARCHAR(128 OCTETS) NOT NULL
                    ,   KEY          VARCHAR(32 OCTETS) NOT NULL
                    ,   VALUE        CLOB(10485760 OCTETS) INLINE LENGTH 256  DEFAULT NULL
                    ,   CONSTRAINT ADMIN_MOVE_TABLEP PRIMARY KEY ( TABSCHEMA, TABNAME, KEY ) ENFORCED
                    )
                    ORGANIZE BY ROW 
                    DISTRIBUTE BY (TABSCHEMA, TABNAME)
                    IN SYSTOOLSPACE
                    @
*/
SET SCHEMA           DB @  -- You can install in any schema you like. DB is not a bad one to choose, but up to you 
SET PATH=SYSTEM PATH,DB @  -- change it in the path too, if you do change it

CREATE OR REPLACE VARIABLE DB_VERSION DECIMAL(6,3) DEFAULT 1.001 @


CREATE OR REPLACE VARIABLE DB_DIAG_FROM_TIMESTAMP TIMESTAMP DEFAULT (TIMESTAMP(CURRENT_DATE))@
CREATE OR REPLACE VARIABLE DB_DIAG_TO_TIMESTAMP TIMESTAMP DEFAULT (CAST(NULL AS TIMESTAMP))@
CREATE OR REPLACE VARIABLE DB_DIAG_MEMBER INTEGER DEFAULT -2@

CREATE OR REPLACE VARIABLE DB_OUT_INTEGER  INTEGER@

/*
 * Converts a Base64 string into a binary value
 */

-- https://stackoverflow.com/questions/56521008/how-to-use-base64decode-function-in-db2

CREATE OR REPLACE FUNCTION DB_BASE64_DECODE(C CLOB(1G OCTETS))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS BLOB(2G)
RETURN
    XMLCAST(XMLQUERY('$d/a' PASSING XMLDOCUMENT(XMLELEMENT(NAME "a", C)) AS "d") AS BLOB(2G))
@

/*
 * Converts a binary value into a Base64 text string
 */

--  https://stackoverflow.com/questions/56521008/how-to-use-base64decode-function-in-db2
CREATE OR REPLACE FUNCTION DB_BASE64_ENCODE(B BLOB(2G))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS CLOB(1G OCTETS)
RETURN
    XMLCAST(XMLQUERY('$d/a' PASSING XMLDOCUMENT(XMLELEMENT(NAME "a", b)) as "d") AS CLOB(1G OCTETS))
@

/*
 * Converts a BINARY value to a character string. I.e. removes the FOR BIT DATA tag from a binary string
 */

/*
 "Remove" the FOR BIT DATA tag on a binary string.
 
 Credit https://stackoverflow.com/questions/7913300/convert-hex-value-to-char-on-db2/42371427#42371427
 
 Not sure why it works!  It needs to be within an ATOMIC compound statement, and does not work with a simple return

 Useful because both
 
     values 'K'::VARBINARY::VARCHAR
 and 
     values BX'4B'::VARCHAR
 
 return the following error
 
    ‪A‬‎ ‪value‬‎ ‪with‬‎ ‪data‬‎ ‪type‬‎ ‪‬‎"‪SYSIBM.VARBINARY"‬‎ ‪cannot‬‎ ‪be‬‎ ‪CAST‬‎ ‪to‬‎ ‪type‬‎ ‪‬‎"‪SYSIBM.VARCHAR"‬‎.‪‬‎.‪‬‎ ‪SQLCODE‬‎=‪‬‎-‪461‬‎,‪‬‎ ‪SQLSTATE‬‎=‪42846‬‎,‪‬‎ ‪DRIVER‬‎=‪4‬‎.‪26‬‎.‪14

  BTW on Db2 11.5 you can use the inbuilt UTIL_RAW module instead
 
    E.g.  VALUES SYSIBMADM.UTL_RAW.CAST_TO_VARCHAR2( your_varchar_for_bit_data_column::VARBINARY)
 
*/

CREATE OR REPLACE FUNCTION DB_BINARY_TO_CHARACTER(A VARCHAR(32672 OCTETS) FOR BIT DATA) RETURNS VARCHAR(32672 OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN ATOMIC
    RETURN A;
END
@

/*
 * Converts ASCII Latin-9 decimal code values to a UTF-8 value. A Netezza compatible version of CHR.
 */

CREATE OR REPLACE FUNCTION DB_CHR(I INTEGER)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(4) 
RETURN    
    CASE
        WHEN I BETWEEN 1 AND 159 THEN CHR(I)
        WHEN I = 0 THEN U&'\0000'
        ELSE CASE I 
		WHEN 160 THEN U&'\00A0'  --  NBSP
		WHEN 161 THEN U&'\00A1'  --  ¡
		WHEN 162 THEN U&'\00A2'  --  ¢
		WHEN 163 THEN U&'\00A3'  --  £
		WHEN 164 THEN U&'\20AC'  --  €
		WHEN 165 THEN U&'\00A5'  --  ¥
		WHEN 166 THEN U&'\0160'  --  Š
		WHEN 167 THEN U&'\00A7'  --  §
		WHEN 168 THEN U&'\0161'  --  š
		WHEN 169 THEN U&'\00A9'  --  ©
		WHEN 170 THEN U&'\00AA'  --  ª
		WHEN 171 THEN U&'\00AB'  --  «
		WHEN 172 THEN U&'\00AC'  --  ¬
		WHEN 173 THEN U&'\00AD'  --  SHY
		WHEN 174 THEN U&'\00AE'  --  ®
		WHEN 175 THEN U&'\00AF'  --  ¯
		--
		WHEN 176 THEN U&'\00B0'  --  °
		WHEN 177 THEN U&'\00B1'  --  ±
		WHEN 178 THEN U&'\00B2'  --  ²
		WHEN 179 THEN U&'\00B3'  --  ³
		WHEN 180 THEN U&'\017D'  --  Ž
		WHEN 181 THEN U&'\00B5'  --  µ
		WHEN 182 THEN U&'\00B6'  --  ¶
		WHEN 183 THEN U&'\00B7'  --  ·
		WHEN 184 THEN U&'\017E'  --  ž
		WHEN 185 THEN U&'\00B9'  --  ¹
		WHEN 186 THEN U&'\00BA'  --  º
		WHEN 187 THEN U&'\00BB'  --  »
		WHEN 188 THEN U&'\0152'  --  Œ
		WHEN 189 THEN U&'\0153'  --  œ
		WHEN 190 THEN U&'\0178'  --  Ÿ
		WHEN 191 THEN U&'\00BF'  --  ¿
		--
		WHEN 192 THEN U&'\00C0'  --  À
		WHEN 193 THEN U&'\00C1'  --  Á
		WHEN 194 THEN U&'\00C2'  --  Â
		WHEN 195 THEN U&'\00C3'  --  Ã
		WHEN 196 THEN U&'\00C4'  --  Ä
		WHEN 197 THEN U&'\00C5'  --  Å
		WHEN 198 THEN U&'\00C6'  --  Æ
		WHEN 199 THEN U&'\00C7'  --  Ç
		WHEN 200 THEN U&'\00C8'  --  È
		WHEN 201 THEN U&'\00C9'  --  É
		WHEN 202 THEN U&'\00CA'  --  Ê
		WHEN 203 THEN U&'\00CB'  --  Ë
		WHEN 204 THEN U&'\00CC'  --  Ì
		WHEN 205 THEN U&'\00CD'  --  Í
		WHEN 206 THEN U&'\00CE'  --  Î
		WHEN 207 THEN U&'\00CF'  --  Ï
		--
		WHEN 208 THEN U&'\00D0'  --  Ð
		WHEN 209 THEN U&'\00D1'  --  Ñ
		WHEN 210 THEN U&'\00D2'  --  Ò
		WHEN 211 THEN U&'\00D3'  --  Ó
		WHEN 212 THEN U&'\00D4'  --  Ô
		WHEN 213 THEN U&'\00D5'  --  Õ
		WHEN 214 THEN U&'\00D6'  --  Ö
		WHEN 215 THEN U&'\00D7'  --  ×
		WHEN 216 THEN U&'\00D8'  --  Ø
		WHEN 217 THEN U&'\00D9'  --  Ù
		WHEN 218 THEN U&'\00DA'  --  Ú
		WHEN 219 THEN U&'\00DB'  --  Û
		WHEN 220 THEN U&'\00DC'  --  Ü
		WHEN 221 THEN U&'\00DD'  --  Ý
		WHEN 222 THEN U&'\00DE'  --  Þ
		WHEN 223 THEN U&'\00DF'  --  ß
		--
		WHEN 224 THEN U&'\00E0'  --  à
		WHEN 225 THEN U&'\00E1'  --  á
		WHEN 226 THEN U&'\00E2'  --  â
		WHEN 227 THEN U&'\00E3'  --  ã
		WHEN 228 THEN U&'\00E4'  --  ä
		WHEN 229 THEN U&'\00E5'  --  å
		WHEN 230 THEN U&'\00E6'  --  æ
		WHEN 231 THEN U&'\00E7'  --  ç
		WHEN 232 THEN U&'\00E8'  --  è
		WHEN 233 THEN U&'\00E9'  --  é
		WHEN 234 THEN U&'\00EA'  --  ê
		WHEN 235 THEN U&'\00EB'  --  ë
		WHEN 236 THEN U&'\00EC'  --  ì
		WHEN 237 THEN U&'\00ED'  --  í
		WHEN 238 THEN U&'\00EE'  --  î
		WHEN 239 THEN U&'\00EF'  --  ï
		--
		WHEN 240 THEN U&'\00F0'  --  ð
		WHEN 241 THEN U&'\00F1'  --  ñ
		WHEN 242 THEN U&'\00F2'  --  ò
		WHEN 243 THEN U&'\00F3'  --  ó
		WHEN 244 THEN U&'\00F4'  --  ô
		WHEN 245 THEN U&'\00F5'  --  õ
		WHEN 246 THEN U&'\00F6'  --  ö
		WHEN 247 THEN U&'\00F7'  --  ÷
		WHEN 248 THEN U&'\00F8'  --  ø
		WHEN 249 THEN U&'\00F9'  --  ù
		WHEN 250 THEN U&'\00FA'  --  ú
		WHEN 251 THEN U&'\00FB'  --  û
		WHEN 252 THEN U&'\00FC'  --  ü
		WHEN 253 THEN U&'\00FD'  --  ý
		WHEN 254 THEN U&'\00FE'  --  þ
		WHEN 255 THEN U&'\00FF'  --  ÿ
		END END
@

/*
 * Returns a DATE from a JD Edwards "Julian" date integer in CYYDDD format
 * 
 * From https://stackoverflow.com/questions/63455575/db2-can-you-write-a-function-or-macro-emedded-in-the-sql-to-simplify-a-complex
 */

CREATE OR REPLACE FUNCTION DB_CYYDDD_TO_DATE(I INTEGER) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS DATE
RETURN
    '1899-12-31'::DATE + (I/1000) YEARS + MOD(I, 1000) DAYS

@

/*
 * Returns a DATE from a date integer in CYYMMDD format
 * 
 * https://stackoverflow.com/questions/63258886/how-to-convert-db2-date-to-yyymmdd-in-android
 */

CREATE OR REPLACE FUNCTION DB_CYYMMDD_TO_DATE(I INTEGER) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS DATE
RETURN
    '1899-11-30'::DATE + (I/10000) YEARS + MOD(I/100, 100) MONTHS + MOD(I, 100) DAYS

@

/*
 * Shows the first 4 runs of characters that are not "plain" printable 7-bit ASCII values
 */

CREATE OR REPLACE FUNCTION DB_EXTRACT_SPECIAL_CHARACTERS ( C CLOB(2M OCTETS) ) RETURNS CLOB(2M OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
             REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,1)
||  COALESCE(REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,2),'')
||  COALESCE(REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,3),'')
||  COALESCE(REGEXP_EXTRACT(C,'[^\u0020-\u007E\u0009\u000A\u000D]+',1,4),'')

@

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
 
@

/*
 * Replaces Greek characters with Latin equivalents
 */

CREATE OR REPLACE FUNCTION DB_GREEK_TO_LATIN(I VARCHAR(32000))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32000)
RETURN (
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
 I
,'ε','e')
,'ρ','r')
,'τ','t')
,'υ','y')
,'θ','u')
,'ι','i')
,'ο','o')
,'π','p')
,'α','a')
,'σ','s')
,'δ','d')
,'φ','f')
,'γ','g')
,'η','h')
,'ξ','j')
,'κ','k')
,'λ','l')
,'ζ','z')
,'χ','x')
,'ψ','c')
,'ω','v')
,'β','b')
,'ν','n')
,'μ','m')
,'Ε','E')
,'Ρ','R')
,'Τ','T')
,'Υ','Y')
,'Θ','U')
,'Ι','I')
,'Ο','O')
,'Π','P')
,'Α','A')
,'Σ','S')
,'Δ','D')
,'Φ','F')
,'Γ','G')
,'Η','H')
,'Ξ','J')
,'Κ','K')
,'Λ','L')
,'Ζ','Z')
,'Χ','X')
,'Ψ','C')
,'Ω','V')
,'Β','B')
,'Ν','N')
,'Μ','M')
)
@

/*
 * Returns the insert range number of a row on a COLUMN organized table when passed the RID_BIT() function 
 */
CREATE OR REPLACE FUNCTION DB_INSERT_RANGE(ROWID VARCHAR (16) FOR BIT DATA) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    ASCII(SUBSTR(ROWID, 8, 1))

@

/*
 * Returns 1 if the input string only contains 7-bit ASCII characters, otherwise returns 0.
 */

CREATE OR REPLACE FUNCTION DB_IS_ASCII ( C CLOB(2M OCTETS) ) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'^[\u0000-\u007F]*$')
@

/*
 * Returns 1 is the input string can be CAST to an BIGINT, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_BIGINT(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
  
  RETURN CASE WHEN CAST(i AS BIGINT) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 if the input string can be CAST to a DATE, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_DATE(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22007';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
    
  RETURN CASE WHEN CAST(i AS DATE) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 is the input string can be CAST to a DECFLOAT, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_DECFLOAT(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
--  
  RETURN CASE WHEN CAST(i AS DECFLOAT) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 is the input string can be CAST to a DECIMAL(31,8), else returns 0
 */

    CREATE OR REPLACE FUNCTION DB_IS_DECIMAL(i VARCHAR(64)) RETURNS INTEGER
        CONTAINS SQL /*ALLOW PARALLEL*/
        NO EXTERNAL ACTION
        DETERMINISTIC
    BEGIN 
      DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
      DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
      
      RETURN CASE WHEN CAST(i AS DECIMAL(31,8)) IS NOT NULL THEN 1 END;
    END

@

/*
 * Returns 1 is the input string can be CAST to an INTEGER, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_INTEGER(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
  
  RETURN CASE WHEN CAST(i AS INTEGER) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 if the input string only holds characters from the ISO-8859-1 (aka Latin-1) codepage, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_LATIN1 ( C CLOB(2M OCTETS) ) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'^[\u0000-\u007F\u00A0-\u00FF]*$')
@

/*
 * Returns 1 if the input string only holds characters from the ISO-8859-15 (aka Latin-9) codepage, else returns 0
 * 
 */

CREATE OR REPLACE FUNCTION DB_IS_LATIN9 ( C CLOB(2M OCTETS) ) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'^[\u0000-\u007F\u00A0-\u00A3\u00A5\u00A7\u00A9-\u00B3\u00B5-\u00B7\u00B9-\u00BB\u00BF-\u00FF\u20AC\u0160\0161\u017D\u017E\u0152\u0153\u0178]*$')
@

/*
 * Returns 1 if the input string can be CAST to an SMALLINT, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_SMALLINT(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
  
  RETURN CASE WHEN CAST(i AS SMALLINT) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 if the input string can be CAST to a TIME, else returns 0 Returns 1 is the input string can be CAST to a TIMESTAMP, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_TIME(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22007';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
  
  RETURN CASE WHEN CAST(i AS TIME) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 is the input string can be CAST to a TIMESTAMP, else returns 0
 */

CREATE OR REPLACE FUNCTION DB_IS_TIMESTAMP(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/ 
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22007';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN 0;
  
  RETURN CASE WHEN CAST(i AS TIMESTAMP) IS NOT NULL THEN 1 END;
END
@

/*
 * Returns 1 if the input string is a valid UTF-8 encoding, otherwise returns 0.
 */

/*
    https://stackoverflow.com/questions/397250/unicode-regex-invalid-xml-characters
    
    Excludes private use area \uE000-\uFFFD
    
    Does include, e.g. <control> characters
*/
CREATE OR REPLACE FUNCTION DB_IS_VALID_UTF8 ( c CLOB(2M OCTETS) )
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
      REGEXP_LIKE(C,'^[\u0009\u000a\u000d\u0020-\uD7FF]*$')
--    REGEXP_LIKE(C,'^[\u0009\u000a\u000d\u0020-\uD7FF\uE000-\uFFFD]*$')
@

/*
 * Convert JSON string to XML (jsonx format)
 * 
 * 
 * It is an alternative to the Java UDF used in the developer works article below.
 * Based on https://www.ibm.com/developerworks/library/x-db2JSONpt1/
 *      and https://www.ibm.com/support/knowledgecenter/SS9H2Y_7.2.0/com.ibm.dp.doc/json_jsonxconversionrules.html
 * 
 * Note:    This function has only be tested on a simple sample JSON string. 
 * Note:    This function is quite possibly slower or much slower than the Java UDF
 * Note:    This function probably does ont work for special characters and escaped characters
 */
CREATE OR REPLACE FUNCTION DB_JSON_TO_XML(I CLOB(2G))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS XML
RETURN
XMLPARSE(DOCUMENT
REGEXP_REPLACE(
 REGEXP_REPLACE(
  REGEXP_REPLACE(
   REGEXP_REPLACE(
    REGEXP_REPLACE(   
     REGEXP_REPLACE(
      REGEXP_REPLACE(  
       REGEXP_REPLACE(
        REGEXP_REPLACE(  
         REGEXP_REPLACE(I
        ,'\"([\w\-\ ]+)\"\s*:\s*null\s*[,]*'				,'<json:null name="$1"/>')					  -- replace nulls
   		,'\"([\w\-\ ]+)\"\s*:\s*\"(.+)\"\s*[,]*'		    ,'<json:string name="$1">$2</json:string>')   -- replace strings
        ,'\"([\w\-\ ]+)\"\s*:\s*(\d+)\s*[,]*'				,'<json:number name="$1">$2</json:number>')	  -- replace numbers
        ,'\"([\w\-\ ]+)\"\s*:\s*((?:false)|(?:true))\s*[,]*','<json:boolean name="$1">$2</json:boolean>') -- replace booleans
        ,'(\s*)\"([\w\-\ ]+)\"\s*:\s*\{'					,'$1<json:object name="$2">')				  -- replace objects
        ,'(\s*)\"([\w\-\ ]+)\"\s*:\s*\['				    ,'$1<json:array name="$2">')				  -- replace arrays
        ,'(\s*)\](\s*)[,]*'								    ,'$1</json:array>$2')						  -- end arrays
        ,'(\s*)\}(\s*)[,]*'								    ,'$1</json:object>$2')						  -- end objects
		,'(\s+)\"(.*)\"[,]*'							    ,'$1<json:string>$2</json:string>')			  -- replace array elements
        ,'\{'					,'<json:object xmlns:json="http://www.ibm.com/xmlns/prod/2009/jsonx">')	   -- add schema
        PRESERVE WHITESPACE
)

@

/*
 * Convert a string from latin-1 codepage to UTF-8
 */

/*
 * Replaces the 96 Latin-1 code-points with Unicode UTF-8 Code points
 * 
 * I.e. Performs a codepage conversion from Latin-1 to UTF-8
 * 
 */
CREATE OR REPLACE FUNCTION DB_LATIN1_TO_UTF8(I VARCHAR(32672 OCTETS))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32672 OCTETS)
RETURN (
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
 I
,x'C3',x'C383')
,x'C2',x'C382') 
,x'A2',x'C2A2')
,x'E2',x'C3A2')
,x'A6',x'C2A6')
,x'C0',x'C380'),x'C1',x'C381')                              ,x'C4',x'C384'),x'C5',x'C385'),x'C6',x'C386'),x'C7',x'C387'),x'C8',x'C388'),x'C9',x'C389'),x'CA',x'C38A'),x'CB',x'C38B'),x'CC',x'C38C'),x'CD',x'C38D'),x'CE',x'C38E'),x'CF',x'C38F')
,x'D0',x'C390'),x'D1',x'C391'),x'D2',x'C392'),x'D3',x'C393'),x'D4',x'C394'),x'D5',x'C395'),x'D6',x'C396'),x'D7',x'C397'),x'D8',x'C398'),x'D9',x'C399'),x'DA',x'C39A'),x'DB',x'C39B'),x'DC',x'C39C'),x'DD',x'C39D'),x'DE',x'C39E'),x'DF',x'C39F')
               ,x'A1',x'C2A1')               ,x'A3',x'C2A3'),x'A4',x'C2A4'),x'A5',x'C2A5')               ,x'A7',x'C2A7'),x'A8',x'C2A8'),x'A9',x'C2A9'),x'AA',x'C2AA'),x'AB',x'C2AB'),x'AC',x'C2AC'),x'AD',x'C2AD'),x'AE',x'C2AE'),x'AF',x'C2AF')
,x'B0',x'C2B0'),x'B1',x'C2B1'),x'B2',x'C2B2'),x'B3',x'C2B3'),x'B4',x'C2B4'),x'B5',x'C2B5'),x'B6',x'C2B6'),x'B7',x'C2B7'),x'B8',x'C2B8'),x'B9',x'C2B9'),x'BA',x'C2BA'),x'BB',x'C2BB'),x'BC',x'C2BC'),x'BD',x'C2BD'),x'BE',x'C2BE'),x'BF',x'C2BF')
,x'E0',x'C3A0'),x'E1',x'C3A1')               ,x'E3',x'C3A3'),x'E4',x'C3A4'),x'E5',x'C3A5'),x'E6',x'C3A6'),x'E7',x'C3A7'),x'E8',x'C3A8'),x'E9',x'C3A9'),x'EA',x'C3AA'),x'EB',x'C3AB'),x'EC',x'C3AC'),x'ED',x'C3AD'),x'EE',x'C3AE'),x'EF',x'C3AF')
,x'F0',x'C3B0'),x'F1',x'C3B1'),x'F2',x'C3B2'),x'F3',x'C3B3'),x'F4',x'C3B4'),x'F5',x'C3B5'),x'F6',x'C3B6'),x'F7',x'C3B7'),x'F8',x'C3B8'),x'F9',x'C3B9'),x'FA',x'C3BA'),x'FB',x'C3BB'),x'FC',x'C3BC'),x'FD',x'C3BD'),x'FE',x'C3BE'),x'FF',x'C3BF')
)

@

/*
 * Replaces Latin characters with Greek equivalents
 */

CREATE OR REPLACE FUNCTION DB_LATIN_TO_GREEK(I VARCHAR(32000))
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32000)
RETURN (
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
 I
,'e','ε')
,'r','ρ')
,'t','τ')
,'y','υ')
,'u','θ')
,'i','ι')
,'o','ο')
,'p','π')
,'a','α')
,'s','σ')
,'d','δ')
,'f','φ')
,'g','γ')
,'h','η')
,'j','ξ')
,'k','κ')
,'l','λ')
,'z','ζ')
,'x','χ')
,'c','ψ')
,'v','ω')
,'b','β')
,'n','ν')
,'m','μ')
,'E','Ε')
,'R','Ρ')
,'T','Τ')
,'Y','Υ')
,'U','Θ')
,'I','Ι')
,'O','Ο')
,'P','Π')
,'A','Α')
,'S','Σ')
,'D','Δ')
,'F','Φ')
,'G','Γ')
,'H','Η')
,'J','Ξ')
,'K','Κ')
,'L','Λ')
,'Z','Ζ')
,'X','Χ')
,'C','Ψ')
,'V','Ω')
,'B','Β')
,'N','Ν')
,'M','Μ')
)
@

/*
 * Returns the Row Id from a LOCK_NAME
 */

CREATE OR REPLACE FUNCTION DB_LOCK_NAME_TO_RID(LOCK_NAME VARCHAR(32)) 
    CONTAINS SQL --ALLOW PARALLEL
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS BIGINT
RETURN 
SELECT
    COALESCE(
        (MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),48)
       + MAX(CASE WHEN NAME = 'PAGEID'             THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),16) 
       + MAX(CASE WHEN NAME = 'ROWID'              THEN BIGINT(VALUE) END))
    ,    MAX(CASE WHEN NAME = 'TSN'                THEN BIGINT(VALUE) END)
    )
FROM
    TABLE( MON_FORMAT_LOCK_NAME(LOCK_NAME))

@

/*
 * Returns true if a value would need the ESCAPE_CHARATER setting to allow EXTERNAL TABLE to EXPORT in text format
 * 
 * If you have a line feed in a column, you need to set ESCAPE_CHARACTER to allow it to be exported
 * If you have a Carriage return in a column, you need to set CRINSTRING YES or set ESCAPE_CHARACTER to allow it to be exported
 * If you have the word NULL (any case) or a pipe in a column, you need to set ESCAPE_CHARACTER  or change NULL_VALUE and/or DELIMITER 
 * 

 CREATE EXTERNAL TABLE '/tmp/tmp.txt' USING ( REMOTESOURCE YES ESCAPE_CHARACTER '\' DELIMITER '|' CRINSTRING YES ) 
 AS VALUES 
   ( 'line feed'     , chr(10) )  -- needs to have ESCAPE_CHARACTER set else you will get SQL20569N with Reason code 3
 , ( 'Carriage return', chr(13) )  -- needs to have ESCAPE_CHARACTER set or set CRINSTRING YES else you will get SQL20569N with Reason code 3
 , ( 'nul1 word'     , 'NULL'  )  -- needs to have ESCAPE_CHARACTER set or change the NULL_VALUE to something different else you will get SQL20569N rc3
 , ( 'pipe'          , '|'     )  -- needs to have ESCAPE_CHARACTER set or change the DELIMITER  to something different else you will get SQL20569N rc3
 , ( 'backslash'     , '\'     )  -- only gets escaped if used as the ESCAPE_CHARACTER
 , ( 'double quote'  , '"'     )  -- does not get escaped on export 
 , ( 'single quote'  , ''''    )  -- does not get escaped on export
 , ( 'zero byte'     ,  x'00'  )  -- does not get escaped on export
 , ( 'NUL1 value'    , NULL    )  -- does not get escaped on export

 * 
*/

CREATE OR REPLACE FUNCTION DB_NEEDS_ESCAPING ( c CLOB(2M OCTETS) )
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS SMALLINT
RETURN
    REGEXP_LIKE(C,'((NULL)|([\|\u000a\u000d]))',1,'i')

@

/*
 * Apply Unicode normalization NFKC (Normalization Form Compatibility Composition) rules to a string
 */

CREATE OR REPLACE FUNCTION DB_NORMALIZE_UNICODE_NFKC (S VARCHAR(32672 OCTETS)) RETURNS VARCHAR(32672 OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
    XMLCAST(XMLQUERY('fn:normalize-unicode($S, ''NFKC'')' ) AS VARCHAR(32672 OCTETS))

@

/*
 * Removes characters in a string that are not "plain" printable 7-bit ASCII values or TAB, LF and CR
 */

CREATE OR REPLACE FUNCTION DB_REMOVE_SPECIAL_CHARACTERS ( C CLOB(2M OCTETS) ) RETURNS CLOB(2M OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
    REGEXP_REPLACE(C,'[^\u0020-\u007E\u0009\u000A\u000D]+','')

@

/*
 * Trim trailing whitespace characters such as such No Break Space as well as Tab, New Line, Form Feed and Carriage Returns.
 * 
 * The inbuilt RTRIM() function only trims U+0020 SPACE characters (i.e. 0x20 in UTF-8 and ASCII )
 * 
 * This function is usefull if you need to match what e.g. a Java RTRIM function would do
 * 
 * It trims the set of characters that have the Unicode whitespace property or are Tab, New Line, Form Feed and Carriage Return
 *  I.e. it trims the set is defined by [\t\n\f\r\p{Z}]
 * 
 *  This is the same set that are java.lang.Character.isWhitespace()    
 *
 */

CREATE OR REPLACE FUNCTION DB_RTRIM_WHITESPACE ( C CLOB(2M OCTETS) ) RETURNS CLOB(2M OCTETS)
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURN
    REGEXP_REPLACE(C,'\s+$','')

@

/*
 * Returns the SQL error message for the passed SQLCODE. Returns NULL is the SQLCODE is invalid
 */

CREATE OR REPLACE FUNCTION DB_SQLERRM
(
    MSGID VARCHAR(9)
,   TOKENS VARCHAR(70)
,   TOKEN_DELIMITER VARCHAR(1)
,   LOCALE VARCHAR(33)
,   SHORTMSG INTEGER
) 
RETURNS VARCHAR(32672 OCTETS)
    CONTAINS SQL --ALLOW PARALLEL
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
    DECLARE R VARCHAR(32672 OCTETS);
  DECLARE EXIT HANDLER FOR SQLEXCEPTION RETURN NULL;
  
  SET R = SYSPROC.SQLERRM ( MSGID, TOKENS, TOKEN_DELIMITER, LOCALE, SHORTMSG);
  
  RETURN R;
END

@

/*
 * CASTs the input to an BIGINT but returns an error containing the value if it can't be cast to an BIGINT
 * 
 * We can't allow this UDF to be parallel, so it will cause performance issue if used in production code.
 * But it is fine for it's intended use of debuging things
 */

CREATE OR REPLACE FUNCTION DB_TO_BIGINT_DEBUG(i VARCHAR(64), msg VARCHAR(128) DEFAULT null) RETURNS BIGINT
    --CONTAINS SQL /*ALLOW PARALLEL*/   -- fails on MPP with SQL0487N if use these options
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN COALESCE(RAISE_ERROR('70001','Value "' || i || '"' || COALESCE(' for ' || msg || ' ','') ||' cannot be converted to BIGINT'),0);
  --
  RETURN CAST(i AS BIGINT);
END
@

/*
 * CASTs the input to a BIGINT but returns NULL if the value can't be CAST successfully
 */

CREATE OR REPLACE FUNCTION DB_TO_BIGINT(i VARCHAR(64)) RETURNS BIGINT
    CONTAINS SQL /*ALLOW PARALLEL*/
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN NULL;
  --
  RETURN CAST(i AS BIGINT);
END
@

/*
 * CASTs the input to an DATE but returns an error containing the value if it can't be cast to an DATE
 * 
 * We can't allow this UDF to be parallel, so it will cause performance issue if used in production code.
 * But it is fine for it's intended use of debuging things
 */

CREATE OR REPLACE FUNCTION DB_TO_DATE_DEBUG(i VARCHAR(64), msg VARCHAR(128) DEFAULT null) RETURNS DATE
    --CONTAINS SQL /*ALLOW PARALLEL*/   -- fails on MPP with SQL0487N if use these options
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN COALESCE(RAISE_ERROR('70001','Value "' || i || '"' || COALESCE(' for ' || msg || ' ','') ||' cannot be converted to DATE'),'0001-01-01');
  --
  RETURN CAST(i AS DATE);
END
@

/*
 * CASTs the input to a DATE but returns NULL if the value can't be CAST successfully
 */

CREATE OR REPLACE FUNCTION DB_TO_DATE(i VARCHAR(64)) RETURNS DATE
    CONTAINS SQL /*ALLOW PARALLEL*/
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN NULL;
  --
  RETURN CAST(i AS DATE);
END
@

/*
 * CASTs the input to a DECFLOAT but returns an error containing the value if it can't be cast to DECFLOAT
 */

CREATE OR REPLACE FUNCTION DB_TO_DECFLOAT_DEBUG(i VARCHAR(64), msg VARCHAR(128) DEFAULT null) RETURNS DECFLOAT
    --CONTAINS SQL /*ALLOW PARALLEL*/   -- fails on MPP with SQL0487N if use these options
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN COALESCE(RAISE_ERROR('70001','Value "' || i || '"' || COALESCE(' for ' || msg || ' ','') ||' cannot be converted to DECFLOAT'),0);
  --
  RETURN CAST(i AS DECFLOAT);
END
@

/*
 * CASTs the input to a DECFLOAT but returns NULL if the value can't be CAST successfully
 */

CREATE OR REPLACE FUNCTION DB_TO_DECFLOAT(i VARCHAR(64)) RETURNS DECFLOAT
    CONTAINS SQL /*ALLOW PARALLEL*/
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN NULL;
  --
  RETURN CAST(i AS DECFLOAT);
END
@

/*
 * CASTs the input to an INTEGER but returns an error containing the value if it can't be cast to an INTEGER
 */

CREATE OR REPLACE FUNCTION DB_TO_INTEGER_DEBUG(i VARCHAR(64), msg VARCHAR(128) DEFAULT null) RETURNS INTEGER
    --CONTAINS SQL /*ALLOW PARALLEL*/   -- fails on MPP with SQL0487N if use these options
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN COALESCE(RAISE_ERROR('70001','Value "' || i || '"' || COALESCE(' for ' || msg || ' ','') ||' cannot be converted to INTEGER'),0);
  --
  RETURN CAST(i AS INTEGER);
END
@

/*
 * CASTs the input to an INTEGER but returns NULL if the value can't be CAST successfully
 */

CREATE OR REPLACE FUNCTION DB_TO_INTEGER(i VARCHAR(64)) RETURNS INTEGER
    CONTAINS SQL /*ALLOW PARALLEL*/
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN NULL;
  --
  RETURN CAST(i AS INTEGER);
END
@

/*
 * CASTs the input to an TIMESTAMP but returns an error containing the value if it can't be cast to an TIMESTAMP
 * 
 * We can't allow this UDF to be parallel, so it will cause performance issue if used in production code.
 * But it is fine for it's intended use of debuging things
 */

CREATE OR REPLACE FUNCTION DB_TO_TIMESTAMP_DEBUG(i VARCHAR(64), msg VARCHAR(128) DEFAULT null) RETURNS TIMESTAMP
    --CONTAINS SQL /*ALLOW PARALLEL*/   -- fails on MPP with SQL0487N if use these options
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN COALESCE(RAISE_ERROR('70001','Value "' || i || '"' || COALESCE(' for ' || msg || ' ','') ||' cannot be converted to TIMESTAMP'),'0001-01-01');
  --
  RETURN CAST(i AS TIMESTAMP);
END
@

/*
 * CASTs the input to a TIMESTAMP but returns NULL if the value can't be CAST successfully
 */

CREATE OR REPLACE FUNCTION DB_TO_TIMESTAMP(i VARCHAR(64)) RETURNS TIMESTAMP
    CONTAINS SQL /*ALLOW PARALLEL*/
    NO EXTERNAL ACTION
    DETERMINISTIC
BEGIN 
  DECLARE NOT_VALID CONDITION FOR SQLSTATE '22018';
  DECLARE EXIT HANDLER FOR NOT_VALID RETURN NULL;
  --
  RETURN CAST(i AS TIMESTAMP);
END
@

/*
 * Returns the tuple sequence number of a row on a COLUMN organized table when passed the RID_BIT() function
 * 
 * Since Db2 11.5.3 you can use the RID() function on a column organised table to return the tuple sequence number
 *   so this function is not needed from that level onwards
 */
CREATE OR REPLACE FUNCTION DB_TSN(RID_BIT VARCHAR (16) FOR BIT DATA) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS BIGINT
RETURN
            ASCII(SUBSTR(RID_BIT, 5, 1))*4294967296 +
            ASCII(SUBSTR(RID_BIT, 4, 1))*16777216 +
            ASCII(SUBSTR(RID_BIT, 3, 1))*65536 +
            ASCII(SUBSTR(RID_BIT, 2, 1))*256 +
            ASCII(SUBSTR(RID_BIT, 1, 1))

@

/*
 * The inverse of HEX(). Converts a a hexadecimal string into a character string
 *  
 *  See my comments on DB_BINARY_TO_CHARACTER.sql
*/
CREATE OR REPLACE FUNCTION DB_UNHEX(A VARCHAR(32672 OCTETS)) 
    NO EXTERNAL ACTION
    DETERMINISTIC
RETURNS VARCHAR(32672 OCTETS)
RETURN DB_BINARY_TO_CHARACTER(HEXTORAW(A))

@

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

@
 
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

@

/*
 * WLM Workloads 
 */

CREATE OR REPLACE VIEW DB_WORKLOADS AS
SELECT
    WORKLOADNAME
,   EVALUATIONORDER
,   ENABLED
,   COALESCE(ATTRIBUTES,'') AS ATTRIBUTES
,   REMARKS
FROM SYSCAT.WORKLOADS W
LEFT JOIN
(
    SELECT
        workloadid
    ,   'ALTER WORKLOAD "' || WORKLOADNAME || '" ADD ' 
        || LISTAGG(CONNATTRTYPE || '(''' || RTRIM(CONNATTRVALUE) || ''')',CHR(10)) 
            WITHIN GROUP( ORDER BY CONNATTRTYPE, CONNATTRVALUE)  AS ATTRIBUTES
    FROM
        SYSCAT.WORKLOADCONNATTR
    GROUP BY
        WORKLOADID
    ,   WORKLOADNAME
)
    AS A
USING ( WORKLOADID )
@

/*
 * WLM Workload DDL 
 */

CREATE OR REPLACE VIEW DB_WORKLOAD_DDL AS
SELECT
    WORKLOADNAME
,   'CREATE WORKLOAD "' || WORKLOADNAME || '" ' || COALESCE(ATTRIBUTES,'')
    || CHR(10) || 'POSITION AT ' || EVALUATIONORDER
    || CASE WHEN ENABLED = 'N'        THEN '' ELSE CHR(10) ||'DISABLE' END
    || CASE WHEN ALLOWACCESS = 'N'    THEN '' ELSE CHR(10) ||'DISALLOW DB ACCESS' END
    || CASE WHEN MAXDEGREE = -1       THEN '' ELSE CHR(10) ||'MAXIMUM DEGREE ' || MAXDEGREE  END
    || CASE WHEN PARENTSERVICECLASSNAME = 'SYSDEFAULTUSERCLASS'
             AND SERVICECLASSNAME       = 'SYSDEFAULTSUBCLASS'
                                      THEN '' ELSE CHR(10) || 'SERVICE CLASS "' || SERVICECLASSNAME || '"' || COALESCE('UNDER "' || PARENTSERVICECLASSNAME || '"','') END 
    || CASE WHEN COLLECTACTDATA = 'N' THEN '' ELSE CHR(10) || 'COLLECT ACTIVITY DATA ON '
        || CASE COLLECTACTPARTITION WHEN 'C' THEN 'COORDINATOR MEMBER' WHEN 'D' THEN 'ALL MEMBERS' END
        || CASE COLLECTACTDATA 
                WHEN 'D' THEN ' WITH DETAILS'
                WHEN 'S' THEN ' WITH DETAILS SECTION'
                WHEN 'V' THEN ' WITH DETAILS SECTION INCLUDE ACTUALS BASE'
                WHEN 'X' THEN ' WITH DETAILS SECTION INCLUDE ACTUALS BASE AND VALUES'
                WHEN 'W' THEN ' WITHOUT DETAILS'
                WHEN 'N' THEN ' NONE'
                ELSE ''  END
        END
    || CASE WHEN COLLECTACTMETRICS = 'N'  THEN '' ELSE CHR(10) || 'COLLECT ACTIVITY METRICS '
         || CASE COLLECTACTMETRICS 
            WHEN 'B' THEN ' BASE'
            WHEN 'E' THEN ' EXTENDED'
            WHEN 'N' THEN ' NONE' -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTUOWDATA <> 'N'    THEN '' ELSE CHR(10) || 'COLLECT UNIT OF WORK DATA '
         || CASE COLLECTUOWDATA 
            WHEN 'B' THEN ' BASE'
            WHEN 'P' THEN ' BASE INCLUDE '  || SUBSTR(COLLECTUOWDATAOPTIONS,2) -- not tested
            WHEN 'N' THEN ' NONE' -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTAGGACTDATA = 'N'  THEN '' ELSE CHR(10) || 'COLLECT AGGREGATE ACTIVITY'
         || CASE COLLECTAGGACTDATA 
            WHEN 'B' THEN ' BASE' 
            WHEN 'E' THEN ' EXTENDED'
            WHEN 'N' THEN ' NONE'  -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTAGGUOWDATA = 'N'  THEN '' ELSE CHR(10) || 'COLLECT AGGREGATE UNIT OF WORK DATA '
         || CASE COLLECTAGGUOWDATA 
            WHEN 'B' THEN ' BASE'
            WHEN 'N' THEN ' NONE' -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTLOCKWAIT = 'N'    THEN '' ELSE CHR(10) || 'COLLECT LOCK WAIT DATA'
         || ' FOR LOCKS WAITING MORE THAN ' || CASE WHEN MOD(LOCKWAITVALUE,1000) = 0 THEN LOCKWAITVALUE / 1000 || ' SECONDS'  ELSE LOCKWAITVALUE * 1000 || ' MICROSECONDS' END
         || CASE COLLECTLOCKWAIT 
            WHEN 'H' THEN ' WITH HISTORY'
            WHEN 'V' THEN ' WITH HISTORY AND VALUES'
            WHEN 'W' THEN ' WITHOUT HISTORY'
            WHEN 'N' THEN ' NONE'-- default
            ELSE '' END
        END    
    || CASE WHEN COLLECTLOCKTIMEOUT = 'W' THEN '' ELSE CHR(10) || 'COLLECT LOCK TIMEOUT DATA' 
         || CASE COLLECTLOCKTIMEOUT 
            WHEN 'H' THEN ' WITH HISTORY'
            WHEN 'V' THEN ' WITH HISTORY AND VALUES'
            WHEN 'W' THEN ' WITHOUT HISTORY' -- default
            WHEN 'N' THEN ' NONE'
            ELSE '' END
        END
    || CASE WHEN COLLECTDEADLOCK = 'W'    THEN '' ELSE CHR(10) || 'COLLECT DEADLOCK DATA'
         || CASE COLLECTDEADLOCK 
            WHEN 'H' THEN ' WITH HISTORY'
            WHEN 'V' THEN ' WITH HISTORY AND VALUES'
            WHEN 'W' THEN ' WITHOUT HISTORY' -- default
            ELSE '' END
        END
--    || CASE WHEN THEN '' ELSE CHR(10) || 'ACTIVITY ESTIMATEDCOST HISTOGRAM TEMPLATE "' --SYSDEFAULTHISTOGRAM"
--    || CASE WHEN THEN '' ELSE CHR(10) || 'ACTIVITY EXECUTETIME HISTOGRAM TEMPLATE "' --SYSDEFAULTHISTOGRAM"
--    || CASE WHEN THEN '' ELSE CHR(10) || 'ACTIVITY INTERARRIVALTIME HISTOGRAM TEMPLATE ' --"SYSDEFAULTHISTOGRAM"
--    || CASE WHEN THEN '' ELSE CHR(10) || 'ACTIVITY LIFETIME HISTOGRAM TEMPLATE ' --"SYSDEFAULTHISTOGRAM"
--    || CASE WHEN THEN '' ELSE CHR(10) || 'ACTIVITY QUEUETIME HISTOGRAM TEMPLATE ' --"SYSDEFAULTHISTOGRAM"
--    || CASE WHEN THEN '' ELSE CHR(10) || 'UOW LIFETIME HISTOGRAM TEMPLATE ' --"SYSDEFAULTHISTOGRAM"@
        AS DDL
FROM
    SYSCAT.WORKLOADS W
LEFT JOIN
(
    SELECT
        WORKLOADID
    ,   LISTAGG(CHR(10) || '    ' || CONNATTRTYPE || '(''' || RTRIM(CONNATTRVALUE) || ''')')
            WITHIN GROUP( ORDER BY CONNATTRTYPE, CONNATTRVALUE)  AS ATTRIBUTES
    FROM
        SYSCAT.WORKLOADCONNATTR
    GROUP BY
        WORKLOADID
)
    AS A
USING ( WORKLOADID )
--LEFT JOIN SYSCAT.HISTOGRAMTEMPLATEUSE  -- TO-DO

@

/*
 * Shows total rows read etc by Workload defined on the database
 */

CREATE OR REPLACE VIEW DB_WORKLOAD_ACTIVITY AS
SELECT  
    WORKLOAD_NAME           AS WORKLOAD
,   SERVICE_CLASS
,   M.CONNECTIONS
,   M.ACTIVE
,   M.ACTIVE_USERS
,   M.CONNECTED_USERS
,   M.ROWS_READ
,   M.ROWS_MODIFIED
,   M.ROWS_RETURNED
,   M.TOTAL_ACT_TIME
,   CASE WHEN AGENTPRIORITY = -32768 THEN 0 ELSE AGENTPRIORITY END    AS AGENT_PRI
,   CASE WHEN PREFETCHPRIORITY <> '' THEN PREFETCHPRIORITY ELSE (SELECT PREFETCHPRIORITY FROM SYSCAT.SERVICECLASSES P WHERE P.SERVICECLASSID = S.PARENTID ) END
             AS PREF_PRI
,   CASE WHEN BUFFERPOOLPRIORITY <> '' THEN BUFFERPOOLPRIORITY ELSE (SELECT BUFFERPOOLPRIORITY FROM SYSCAT.SERVICECLASSES P WHERE P.SERVICECLASSID = S.PARENTID ) END
             AS BUFF_PRI
--,       MAXDEGREE
FROM
    SYSCAT.SERVICECLASSES  S
INNER JOIN
(
    SELECT
        SERVICE_CLASS_ID
    --
    ,   CASE WHEN WORKLOAD_NAME IS NULL THEN 'NONE'
            WHEN WORKLOAD_NAME = 'SYSDEFAULTUSERWORKLOAD'   THEN 'DEFAULT USER' 
            WHEN WORKLOAD_NAME = 'SYSDEFAULTADMWORKLOAD'    THEN 'DEFAULT ADMIN'
            WHEN WORKLOAD_NAME = 'SYSDEFAULTSYSTEMWORKLOAD' THEN 'DEFAULT SYSTEM' 
            WHEN WORKLOAD_NAME = 'SYSDEFAULTMAINTWORKLOAD'  THEN 'DEFAULT MAINT' 
        ELSE WORKLOAD_NAME END AS WORKLOAD_NAME
    --    
    ,      CASE WHEN SERVICE_SUPERCLASS_NAME IN ('SYSDEFAULTUSERCLASS','SYSDEFAULTSYSTEMCLASS') THEN 'DEFAULT' ELSE SERVICE_SUPERCLASS_NAME END 
        || CASE WHEN SERVICE_SUBCLASS_NAME IN ('SYSDEFAULTSUBCLASS','SYSDEFAULTSYSTECLASS') THEN '' ELSE '.' || SERVICE_SUBCLASS_NAME END    AS SERVICE_CLASS  
    --
    ,  SUM(ROWS_READ)       AS ROWS_READ
    ,  SUM(ROWS_READ)       AS ROWS_MODIFIED
    ,  SUM(ROWS_READ)       AS ROWS_RETURNED
    ,  SUM(TOTAL_ACT_TIME)  AS TOTAL_ACT_TIME
    --            
    ,   SUM(CONNECTIONS) AS CONNECTIONS
    ,   SUM(ACTIVE)      AS ACTIVE
    --
    ,   SUBSTR((LISTAGG(CASE WHEN ACTIVE_USER <> '' THEN ',' || ACTIVE_USER ELSE '' END,'') WITHIN GROUP ( ORDER BY  SESSION_AUTH_ID)) || ' ',2)
            AS ACTIVE_USERS
    --
    ,  TRIM(LISTAGG(TRIM(SESSION_AUTH_ID),',') WITHIN GROUP ( ORDER BY  SESSION_AUTH_ID))
            AS CONNECTED_USERS
    --
    FROM
        (
            SELECT 
                SERVICE_CLASS_ID  
            ,   SESSION_AUTH_ID
            ,   WORKLOAD_NAME
            ,   SERVICE_SUPERCLASS_NAME
            ,   SERVICE_SUBCLASS_NAME        
            ,   COUNT(DISTINCT APPLICATION_HANDLE)      AS CONNECTIONS
            ,   COUNT(DISTINCT CASE WHEN WORKLOAD_OCCURRENCE_STATE = 'UOWEXEC' THEN APPLICATION_HANDLE END) AS ACTIVE
            ,   MAX(CASE WHEN WORKLOAD_OCCURRENCE_STATE = 'UOWEXEC' THEN TRIM(SESSION_AUTH_ID) ELSE '' END) AS ACTIVE_USER
            ,   SUM(ROWS_READ)       AS ROWS_READ
            ,   SUM(ROWS_READ)       AS ROWS_MODIFIED
            ,   SUM(ROWS_READ)       AS ROWS_RETURNED
            ,   SUM(TOTAL_ACT_TIME)  AS TOTAL_ACT_TIME
            FROM
                TABLE(MON_GET_UNIT_OF_WORK(NULL, -2))
            WHERE APPLICATION_HANDLE <> MON_GET_APPLICATION_HANDLE()
            AND   WORKLOAD_OCCURRENCE_STATE <> 'TRANSIENT'
            GROUP BY
                SERVICE_CLASS_ID  
            ,   SESSION_AUTH_ID
            ,   WORKLOAD_NAME
            ,   SERVICE_SUPERCLASS_NAME
            ,   SERVICE_SUBCLASS_NAME
        ) MS
        GROUP BY
            SERVICE_CLASS_ID  
        ,   WORKLOAD_NAME
        ,   SERVICE_SUPERCLASS_NAME
        ,   SERVICE_SUBCLASS_NAME
     ) M
ON
    S.SERVICECLASSID = M.SERVICE_CLASS_ID 
@

/*
 * Shows thread/agent consumption of currently executing queries on the most constrained partition
 * 
 * Use this if DB_WLM_CONSTRAINED_REOURCE shows threads is the most constrained resource  
 * 
 */

CREATE OR REPLACE VIEW DB_WLM_THREAD_CONSUMPTION AS
SELECT 
    A.APPLICATION_HANDLE
,   A.UOW_ID
,   A.ACTIVITY_ID
,   A.LOCAL_START_TIME
,   SECONDS_BETWEEN(CURRENT_TIMESTAMP, A.LOCAL_START_TIME)    AS TOTAL_RUNTIME_SECS
,   B.APPLICATION_NAME
,   B.SESSION_AUTH_ID
,   B.CLIENT_IPADDR
,   A.ACTIVITY_STATE
,   A.MEMBER
,   STMT_TEXT
FROM
    TABLE(MON_GET_ACTIVITY  (NULL,-2)) AS A
,   TABLE(MON_GET_CONNECTION(NULL,-2)) AS B
WHERE
     A.APPLICATION_HANDLE = B.APPLICATION_HANDLE
AND  A.MEMBER = B.MEMBER 
AND  A.ACTIVITY_STATE IN ('EXECUTING', 'IDLE') 
AND  A.MEMBER = A.COORD_PARTITION_NUM 
AND  A.ADM_BYPASSED = 0
@

/*
 * Shows percentage of statements queued and queue time at a database member level
 * 
 */

CREATE OR REPLACE VIEW DB_WLM_QUEUING_SUMMARY AS
SELECT
    MEMBER
,   ACT_COMPLETED_TOTAL         AS STMTS_COMPLETED
,   ACT_ABORTED_TOTAL           AS STMTS_FAILED
,   WLM_QUEUE_ASSIGNMENTS_TOTAL AS STMTS_QUEUED
,   DEC((FLOAT(WLM_QUEUE_ASSIGNMENTS_TOTAL)/FLOAT(ACT_COMPLETED_TOTAL + ACT_ABORTED_TOTAL)) * 100, 5, 2) AS PCT_STMTS_QUEUED
,   TOTAL_APP_RQST_TIME /1000                                                                            AS TOTAL_RQST_TIME_SEC
,   TOTAL_APP_RQST_TIME / NULLIF((ACT_COMPLETED_TOTAL + ACT_ABORTED_TOTAL),0)                            AS AVG_RQST_TIME_MS
,   WLM_QUEUE_TIME_TOTAL AS TOTAL_QUEUE_TIME_MS, WLM_QUEUE_TIME_TOTAL / NULLIF(WLM_QUEUE_ASSIGNMENTS_TOTAL,0)      AS AVG_QUEUE_TIME_MS
FROM
    TABLE(MON_GET_DATABASE(-2)) AS T

@

/*
 * Shows any queries in the package cache that have been queue do to WLM concurrency limits 
 * 
*/

CREATE OR REPLACE VIEW DB_WLM_QUEUED_STATEMENTS AS
SELECT
    WLM_QUEUE_TIME_TOTAL
,   WLM_QUEUE_ASSIGNMENTS_TOTAL
,   NUM_EXECUTIONS
,   COORD_STMT_EXEC_TIME
,   QUERY_COST_ESTIMATE
,   STMT_TEXT
FROM
       TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2))
WHERE
    WLM_QUEUE_TIME_TOTAL > 0
    
@

/*
 * Shows currently queued queries and estimated sortheap requirements 
 * 
*/

CREATE OR REPLACE VIEW DB_WLM_QUEUED_ACTIVITY AS
WITH TOTAL_MEM(CFG_MEM) AS (SELECT BIGINT(MAX(VALUE)) FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr' ) 
SELECT A.APPLICATION_HANDLE
,    A.UOW_ID
,    A.ACTIVITY_ID
,    A.ENTRY_TIME
,    TIMESTAMPDIFF(2
,    (CURRENT_TIMESTAMP - A.ENTRY_TIME)) AS TIME_QUEUED_SECONDS
,    B.APPLICATION_NAME
,    B.SESSION_AUTH_ID
,    B.CLIENT_IPADDR
,    A.ACTIVITY_STATE
,    A.ESTIMATED_SORT_SHRHEAP_TOP                                      AS EST_MEM_USAGE
,    A.MEMBER
,    DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(CFG_MEM))*100,5,2) AS EST_QUERY_PCT_MEM_USAGE
,    STMT_TEXT
FROM TABLE(MON_GET_ACTIVITY  (NULL,-2)) AS A
,    TABLE(MON_GET_CONNECTION(NULL,-2)) AS B
,    TOTAL_MEM C
WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE)
AND (A.MEMBER = B.MEMBER)
AND (A.ACTIVITY_STATE = 'QUEUED')
AND (A.MEMBER=A.COORD_PARTITION_NUM)
--AND (DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(CFG_MEM))*100,5,2)) > 25
-- ORDER BY EST_MEM_USAGE DESC
@

/*
 * Shows memory consumption of currently executing queries on the most constrained partition
 * 
 * Use this if DB_WLM_CONSTRAINED_REOURCE shows memory is the most constrained resource  
 * 
 */

CREATE OR REPLACE VIEW DB_WLM_MEMORY_CONSUMPTION AS
WITH 
    TOTAL_MEM    AS (SELECT MAX(BIGINT(VALUE)) AS CFG_MEM FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr' )
,   MAX_MEM_PART AS (SELECT MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T ORDER BY SORT_SHRHEAP_ALLOCATED DESC FETCH FIRST 1 ROWS ONLY)
,   MEM_USAGE_ON_MEMBER AS (
        SELECT APPLICATION_HANDLE, UOW_ID, ACTIVITY_ID, SORT_SHRHEAP_ALLOCATED
        FROM
            MAX_MEM_PART Q
        ,   TABLE(MON_GET_ACTIVITY(NULL, Q.MEMBER)) AS T
    WHERE ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE'
    )
SELECT
    A.APPLICATION_HANDLE
,   A.UOW_ID
,   A.ACTIVITY_ID
,   A.LOCAL_START_TIME
,   SECONDS_BETWEEN( CURRENT_TIMESTAMP, A.LOCAL_START_TIME)                                 AS RUNTIME_SECS
,   TIMESTAMPDIFF(2, (CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000    AS WAIT_ON_CLIENT_SECS
,   A.WLM_QUEUE_TIME_TOTAL / 1000                                                           AS QUEUED_SECS
,   B.APPLICATION_NAME
,   B.SESSION_AUTH_ID
,   B.CLIENT_IPADDR
,   A.ACTIVITY_STATE
,   A.ADM_BYPASSED
,   A.ESTIMATED_SORT_SHRHEAP_TOP                    AS EST_MEM_USAGE
,   C.SORT_SHRHEAP_ALLOCATED                        AS MEM_USAGE_CURR
,   D.CFG_MEM
,   DEC((FLOAT(C.SORT_SHRHEAP_ALLOCATED)    /FLOAT(D.CFG_MEM))*100,5,2)     AS QUERY_MEM_USED_PCT
,   DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(D.CFG_MEM))*100,5,2)     AS QUERY_MEM_EST_PCT
,   STMT_TEXT 
FROM 
    TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A
,   TABLE(MON_GET_CONNECTION(NULL,-2)) AS B
,   MEM_USAGE_ON_MEMBER AS C
,   TOTAL_MEM AS D 
WHERE 
    A.APPLICATION_HANDLE = B.APPLICATION_HANDLE 
AND A.MEMBER             = B.MEMBER
AND A.APPLICATION_HANDLE = C.APPLICATION_HANDLE 
AND A.MEMBER             = A.COORD_PARTITION_NUM
AND A.UOW_ID             = C.UOW_ID
AND A.ACTIVITY_ID        = C.ACTIVITY_ID 

@

/*
 * Shows the most constrained WLM resource (threads vs sort)
 * 
 */

CREATE OR REPLACE VIEW DB_WLM_CONSTRAINED_RESOURCE AS
SELECT
    MAX(DEC((FLOAT(SORT_SHRHEAP_ALLOCATED)/FLOAT(SHEAPTHRES_SHR))*100, 5,2)) AS SORTMEM_USED_PCT
,   MAX(DEC((FLOAT(STMTS)/FLOAT(LOAD_TRGT))*100,5,2))                        AS THREADS_USED_PCT
FROM
    (SELECT MAX(VALUE) AS LOAD_TRGT                          FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt')
,   (SELECT VALUE AS SHEAPTHRES_SHR , MEMBER AS SHEAP_MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'     )
,   (SELECT SORT_SHRHEAP_ALLOCATED  , MEMBER AS ALLOC_MEMBER FROM TABLE(MON_GET_DATABASE(-2)))
,   (
        SELECT COUNT(*) AS STMTS
        FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) 
        WHERE 
            ADM_BYPASSED = 0
        AND ACTIVITY_STATE IN ('EXECUTING','IDLE')
        AND MEMBER = COORD_PARTITION_NUM
    )
WHERE
    SHEAP_MEMBER = ALLOC_MEMBER

@

/*
 * Provides a denormalized view of your WLM configuration
 * 
 * Note that this code makes various assumptions about how your WLM configuration is structured
 *   and only shows certain apsects.
 * Please do customise as you need to fully catpure your particualar usages of WLM
 */


CREATE OR REPLACE VIEW DB_WLM_CONFIG AS
SELECT
    COALESCE(S.PARENTSERVICECLASSNAME || ' -> ' ,'') || S.SERVICECLASSNAME      AS OBJECT
,   S.PREFETCHPRIORITY     AS PREFETCH
,   S.OUTBOUNDCORRELATOR   AS OB_CORRELATOR 
,   W.CONNECTION_ATTRIBUTES
,   T.THRESHOLDS
,   WA.WORKCLASSNAME
,   WA.WORK_ACTIONS
--,   CASE WORKLOADTYPE WHEN 1 THEN 'CUSTOM' WHEN 2 THEN 'MIXED' WHEN 3 THEN 'INTERACTIVE' WHEN 4 THEN 'BATCH' ELSE '' END AS WORKLOADTYPE
FROM
    SYSCAT.SERVICECLASSES S
LEFT JOIN
(
    SELECT
        PARENTSERVICECLASSNAME
    ,   SERVICECLASSNAME
    ,   LISTAGG(RTRIM(CONNATTRTYPE) || ' (' || CONNATTRVALUES || ')',CHR(10))
            WITHIN GROUP( ORDER BY CONNATTRTYPE)  AS CONNECTION_ATTRIBUTES
    FROM
    (    SELECT
            PARENTSERVICECLASSNAME
        ,   SERVICECLASSNAME
        ,   CONNATTRTYPE
        ,   LISTAGG(RTRIM(CONNATTRVALUE),', ')
                WITHIN GROUP( ORDER BY CONNATTRVALUE)  AS CONNATTRVALUES
        FROM    
            (   SELECT
                    PARENTSERVICECLASSNAME
                ,   SERVICECLASSNAME
                ,   CONNATTRTYPE
                ,   CONNATTRVALUE
                FROM
                    SYSCAT.WORKLOADS W
                JOIN
                    SYSCAT.WORKLOADCONNATTR
                USING
                    (   WORKLOADID  )
                WHERE
                    ENABLED = 'Y'
             )
         GROUP BY
             PARENTSERVICECLASSNAME
         ,   SERVICECLASSNAME
         ,   CONNATTRTYPE
         )
    GROUP BY
        PARENTSERVICECLASSNAME
    ,   SERVICECLASSNAME
) W
ON S.SERVICECLASSNAME = W.SERVICECLASSNAME
AND ( S.PARENTSERVICECLASSNAME = W.PARENTSERVICECLASSNAME OR (S.PARENTSERVICECLASSNAME IS NULL AND W.PARENTSERVICECLASSNAME IS NULL))
LEFT JOIN
-- Threshholds
(
    SELECT
        SERVICECLASSID
    ,   LISTAGG(/*THRESHOLDNAME || ' : ' || */RULE || ' -> ' || RTRIM(ACTION)
            || CASE WHEN ENABLED = 'N' THEN ' (disabled)' ELSE '' END
        , CHR(10)) WITHIN GROUP( ORDER BY THRESHOLDNAME, MAXVALUE )  AS THRESHOLDS
    FROM
    (
        SELECT 
            DOMAINID            AS SERVICECLASSID
        ,   THRESHOLDNAME
        ,   THRESHOLDPREDICATE || ' > ' || MAXVALUE AS RULE
        ,   CASE EXECUTION WHEN 'R' THEN 'Remap' WHEN 'S' THEN 'Stop' WHEN 'C' THEN 'Continue' WHEN 'F' THEN 'Force off' ELSE EXECUTION END AS ACTION 
        ,   VIOLATIONRECORDLOGGED AS LOG
        ,   ENABLED
        ,   CASE ENFORCEMENT WHEN 'D' THEN 'Database' WHEN 'P' THEN 'Partition' WHEN 'W' THEN 'Workload occurrence' END AS ENFORCEMENT
        ,   MAXVALUE
        FROM 
            SYSCAT.THRESHOLDS
        WHERE
            DOMAIN IN ( 'SP', 'SB' )
        --AND ENABLED = 'Y' 
    )
    GROUP BY
        SERVICECLASSID
) T
USING ( SERVICECLASSID )
LEFT JOIN
-- Work Actions
(   SELECT
        SERVICECLASSID
    ,   WORKCLASSNAME
    ,   LISTAGG(CASE "TYPE" WHEN 'WORK TYPE' THEN 
            CASE VALUE1 WHEN 1 THEN 'ALL' WHEN 2 THEN 'READ' WHEN 3 THEN 'WRITE' WHEN 4 THEN 'CALL' WHEN 5 THEN 'DML' WHEN 6 THEN 'DDL' WHEN 7 THEN 'LOAD' ELSE '?' END
                ELSE "TYPE" || VALUE1 || COALESCE(' - ' || VALUE2,'') END
        , CHR(10) ) 
            WITHIN GROUP( ORDER BY TYPE DESC )  AS WORK_ACTIONS
    FROM
    (
        SELECT
            WC.WORKCLASSNAME
        ,   WCA.WORKCLASSSETNAME
        ,   WA.ACTIONSETNAME
        ,   "TYPE"
        ,   DECFLOAT(VALUE1)    VALUE1
        ,   CASE WHEN VALUE2 > 8e36 THEN INFINITY ELSE DECFLOAT(VALUE2) END VALUE2
        ,   VALUE3
        ,   EVALUATIONORDER
        ,   ACTIONNAME
        ,   ACTIONID
        ,   ACTIONTYPE
        ,   COALESCE(REFOBJECTID, OBJECTID)     AS SERVICECLASSID
        ,   REFOBJECTTYPE
        ,   SECTIONACTUALSOPTIONS
        ,   OBJECTTYPE
        ,   OBJECTNAME
        FROM SYSCAT.WORKCLASSATTRIBUTES WCA
        JOIN SYSCAT.WORKCLASSES         WC  USING ( WORKCLASSID, WORKCLASSSETID )
        JOIN SYSCAT.WORKCLASSSETS       WCS USING (              WORKCLASSSETID ) 
        JOIN SYSCAT.WORKACTIONS         WA  USING ( WORKCLASSID                 )
        JOIN SYSCAT.WORKACTIONSETS      WAS USING (              WORKCLASSSETID )
        WHERE
            WA.ENABLED = 'Y'
        AND WAS.ENABLED = 'Y'
        AND WAS.OBJECTTYPE = 'b'  -- Link at Work Object Set level to Service Super Class
    )
    GROUP BY
        SERVICECLASSID
    ,   WORKCLASSNAME
) WA
USING ( SERVICECLASSID )
WHERE
    S.SERVICECLASSNAME <> 'SYSDEFAULTSUBCLASS'
-- Now include Database level thresholds
UNION ALL
SELECT 
--    THRESHOLDNAME   AS OBJECT
    'Database Threasholds' AS OBJECT
,   ''      AS PREFETCH
,   ''      AS OB_CORRELATOR 
,   ''      AS CONNECTION_ATTRIBUTES
,   THRESHOLDS
,   ''      AS WORKCLASSNAME
,   ''      AS WORK_ACTIONS
FROM
(   SELECT
--        THRESHOLDNAME
        LISTAGG(/*THRESHOLDNAME || ' : ' || */RULE || ' -> ' || ACTION, CHR(10)) WITHIN GROUP( ORDER BY MAXVALUE )  AS THRESHOLDS
    FROM
    (
        SELECT 
            THRESHOLDNAME
        ,   THRESHOLDPREDICATE || ' > ' || MAXVALUE AS RULE
        ,   CASE EXECUTION WHEN 'R' THEN 'Remap' WHEN 'S' THEN 'Stop' WHEN 'C' THEN 'Continue' WHEN 'F' THEN 'Force off' ELSE EXECUTION END AS ACTION 
        ,   VIOLATIONRECORDLOGGED AS LOG
        ,   ENABLED
        ,   CASE ENFORCEMENT WHEN 'D' THEN 'Database' WHEN 'P' THEN 'Partition' WHEN 'W' THEN 'Workload occurrence' END AS ENFORCEMENT
        ,   MAXVALUE
        FROM 
            SYSCAT.THRESHOLDS
        WHERE
            DOMAIN = 'DB'
        AND ENABLED = 'Y'
    )
--    GROUP BY
--        THRESHOLDNAME
)
--ORDER BY 1

@

/*
 * Current coordinator activity by status and whether the query bypassed the adaptive workload manager
 * 
 * EXECUTING - queries are currently processing a request in the database engine. 
 * IDLE - query is blocked on the client (i.e. waiting for the next client request). 
 * QUEUED – query is waiting for resources so that they can be admitted. 
 * 
 * Two counts are reported per state for this query; the total number of activities and the number that bypassed admission control. 
 * 
 * Bypassed activities do not directly cause queuing. 
 * 
*/

CREATE OR REPLACE VIEW DB_WLM_ACTIVITY_STATE AS
SELECT
    ACTIVITY_STATE
,   COUNT(*)                 AS ACTIVITIES
,   SUM(INT(ADM_BYPASSED))   AS BYPASSED
FROM
    TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T
WHERE
    MEMBER = COORD_PARTITION_NUM
GROUP BY
    ACTIVITY_STATE

@

/*
 * Returns Work Load Management metrics by current activity
 */

/*
Derived from the query shown here  https://www.ibm.com/support/knowledgecenter/en/SSHRBY/com.ibm.swg.im.dashdb.admin.wlm.doc/doc/adaptive_wlm_why_queued_usage.html

Returns the following information:

    Resource information (effective_query_degree, sort_shrheap_allocated, sort_shrheap_top)
    Whether the query bypassed the adaptive workload manager (adm_bypassed)
    The current state (EXECUTING or IDLE)
    Information that you can use to identify the source of the query, such as the session authorization ID, application name, and statement tex
    
*/
CREATE OR REPLACE VIEW DB_WLM_ACTIVITY AS
WITH
    TOTAL_MEM (CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER  FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr')
,   LOADTRGT  (LOADTRGT)        AS (SELECT MAX(VALUE)     FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt')
,   CPUINFO   (CPUS_PER_HOST)   AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES()))
,   PARTINFO  (PART_PER_HOST)   AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T 
                                    WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY )
SELECT 
    A.MEMBER
,   A.COORD_MEMBER
,   A.ACTIVITY_STATE
,   A.APPLICATION_HANDLE
,   A.UOW_ID
,   A.ACTIVITY_ID
,   B.APPLICATION_NAME
,   B.SESSION_AUTH_ID
,   B.CLIENT_IPADDR
,   A.ENTRY_TIME
,   A.LOCAL_START_TIME
,   CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) 
         THEN TIMESTAMPDIFF(2, CHAR(A.LOCAL_START_TIME - A.ENTRY_TIME))
         ELSE A.WLM_QUEUE_TIME_TOTAL/1000 END                                            AS TOTAL_QUEUETIME_SECONDS
,   CASE WHEN (A.LOCAL_START_TIME IS NOT NULL)
         THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME)) ELSE NULL END AS TOTAL_RUNTIME_SECONDS
,   CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) 
         THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000
                                                                           ELSE NULL END AS TOTAL_CLIENT_WAIT_SECONDS
,   A.ADM_BYPASSED
--/*11.5.0*/,   A.ADM_RESOURCE_ACTUALS
,   A.EFFECTIVE_QUERY_DEGREE
,   DEC((FLOAT(A.EFFECTIVE_QUERY_DEGREE)/(FLOAT(D.LOADTRGT) * FLOAT(E.CPUS_PER_HOST) / FLOAT(F.PART_PER_HOST)))*100,5,2) AS THREADS_USED_PCT
,   A.QUERY_COST_ESTIMATE
,   A.ESTIMATED_RUNTIME
,   A.ESTIMATED_SORT_SHRHEAP_TOP                                            AS ESTIMATED_SORTMEM_USED_PAGES
,   DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT
,   A.SORT_SHRHEAP_ALLOCATED                                                AS SORTMEM_USED_PAGES
,   DEC((FLOAT(A.SORT_SHRHEAP_ALLOCATED)/FLOAT(C.CFG_MEM)) * 100, 5, 2)     AS SORTMEM_USED_PCT
,   SORT_SHRHEAP_TOP                                                        AS PEAK_SORTMEM_USED_PAGES
,   DEC((FLOAT(A.SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2)           AS PEAK_SORTMEM_USED_PCT
,   C.CFG_MEM                                                               AS CONFIGURED_SORTMEM_PAGES
,   STMT_TEXT
FROM
    TABLE(MON_GET_ACTIVITY(NULL,-2))   AS A
,   TABLE(MON_GET_CONNECTION(NULL,-1)) AS B
,   TOTAL_MEM AS C
,   LOADTRGT AS D
,   CPUINFO AS E
,   PARTINFO AS F
WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER)

@

/*
 * Returns CREATE TABLE DDL that coresponds to the colum definitions of VIEWs but with NOT NULL used for columns without NULL values
 * 
 * Note you need to runstats your view for the NULL to NOT NULL feature to work. Otheriwse just use the DB_VIEW_TABLE_DDL view
 * E.g.
 *
 *      ALTER VIEW MY_SCHEMA.MY_VIEW ENABLE QUERY OPTIMIZATION@
 *      call admin_cmd('RUNSTATS ON VIEW MY_SCHEMA.MY_VIEW WITH DISTRIBUTION')@
 * 
 * Then if you don't need the view as a stat view, drop the optimization
 * 
 *      ALTER VIEW MY_SCHEMA.MY_VIEW DISABLE QUERY OPTIMIZATION@
 */

CREATE OR REPLACE VIEW DB_VIEW_TABLE_IMPROVED_DDL AS
SELECT
    TABSCHEMA  AS VIEWSCHEMA
,   TABNAME    AS VIEWNAME
,   'CREATE TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" (' 
    || LISTAGG(CAST(CHR(10) AS VARCHAR(32000 OCTETS)) || CASE WHEN COL_SEQ > 0 THEN ',   ' ELSE '    ' END 
          || '"' || COLNAME || '"'
          || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
          || DATATYPE_DDL
          ) WITHIN GROUP (ORDER BY COLNO) 
    || CHR(10) || ')' AS DDL
,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
FROM
(   SELECT C.*
       ,    SUM(50 + LENGTH(DATATYPE_DDL) )
                 OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
       FROM
       (
            SELECT
                TABSCHEMA
            ,   TABNAME
            ,   COLNAME
            ,   COLNO
            ,   CASE
                WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                     || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                     || CASE WHEN C.CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END                WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                THEN TYPENAME || '(' || LENGTH || ')'  
                WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                THEN TYPENAME
                WHEN TYPENAME IN ('TIMESTAMP')
                THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                ELSE TYPENAME END 
            || CASE WHEN NULLS = 'N' THEN ' NOT NULL' 
                    WHEN COLCARD > 0 AND NUMNULLS = 0 THEN ' /* made */ NOT NULL' ELSE '' END                        AS DATATYPE_DDL
            ,    COLNO                                                                    AS COL_SEQ
        FROM
            SYSCAT.COLUMNS C JOIN SYSCAT.TABLES USING ( TABSCHEMA, TABNAME ) 
        WHERE   TYPE IN ('V')
       ) C
      )
GROUP BY
    TABSCHEMA
,   TABNAME
,   CUMULATIVE_LENGTH/32000

@

/*
 * Returns CREATE TABLE DDL that corresponds to the column definitions of VIEWs
 */

CREATE OR REPLACE VIEW DB_VIEW_TABLE_DDL AS
SELECT
    TABSCHEMA  AS VIEWSCHEMA
,   TABNAME    AS VIEWNAME
,   'CREATE TABLE "' || TABSCHEMA || '"."' || TABNAME || '" (' 
    || LISTAGG(CAST(CHR(10) AS VARCHAR(32000 OCTETS)) || CASE WHEN COL_SEQ > 0 THEN ',   ' ELSE '    ' END 
          || '"' || COLNAME || '"'
          || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
          || DATATYPE_DDL
          ) WITHIN GROUP (ORDER BY COLNO) 
    || CHR(10) || ')' AS DDL
,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
FROM
(   SELECT C.*
       ,    SUM(50 + LENGTH(DATATYPE_DDL) )
                 OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
       FROM
       (
            SELECT
                TABSCHEMA
            ,   TABNAME
            ,   COLNAME
            ,   COLNO
            ,   CASE
                WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                     || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                     || CASE WHEN C.CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END                WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                THEN TYPENAME || '(' || LENGTH || ')'  
                WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                THEN TYPENAME
                WHEN TYPENAME IN ('TIMESTAMP')
                THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                ELSE TYPENAME END 
            || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
            ,    COLNO                                                                    AS COL_SEQ
        FROM
            SYSCAT.COLUMNS C JOIN SYSCAT.TABLES USING ( TABSCHEMA, TABNAME ) 
        WHERE   TYPE IN ('V')
       ) C
      )
GROUP BY
    TABSCHEMA
,   TABNAME
,   CUMULATIVE_LENGTH/32000

@

/*
 * Returns the DDL used to create VIEWs
 */

CREATE OR REPLACE VIEW DB_VIEW_DDL AS
SELECT  V.VIEWSCHEMA
,       V.VIEWNAME
,       V.TEXT        AS DDL
,       DB_FORMAT_SQL(TEXT)  AS FORMATTED_DDL
FROM
    SYSCAT.VIEWS  V
INNER JOIN
    SYSCAT.TABLES T
ON
    T.TABSCHEMA = V.VIEWSCHEMA 
AND T.TABNAME   = V.VIEWNAME
AND T.TYPE = 'V'  -- exclude MQTs
@

/*
 * Returns a count of activity by User and Workload
 */

CREATE OR REPLACE VIEW DB_USER_WORKLOADS AS
SELECT
    CASE WHEN SESSION_AUTH_ID <> SYSTEM_AUTH_ID THEN SESSION_AUTH_ID || '(' || SYSTEM_AUTH_ID || ')' 
        ELSE SYSTEM_AUTH_ID END AS USERID
,   CASE WHEN WORKLOAD_NAME IS NULL THEN 'NONE'
        WHEN WORKLOAD_NAME = 'SYSDEFAULTUSERWORKLOAD'   THEN 'DEFAULT USER' 
        WHEN WORKLOAD_NAME = 'SYSDEFAULTADMWORKLOAD'    THEN 'DEFAULT ADMIN'
        WHEN WORKLOAD_NAME = 'SYSDEFAULTSYSTEMWORKLOAD' THEN 'DEFAULT SYSTEM' 
        WHEN WORKLOAD_NAME = 'SYSDEFAULTMAINTWORKLOAD'  THEN 'DEFAULT MAINT' 
    ELSE WORKLOAD_NAME END AS WORKLOAD_NAME
,   CASE WHEN S.SERVICE_SUPERCLASS_NAME IS NULL THEN '' 
            WHEN S.SERVICE_SUPERCLASS_NAME IN ('SYSDEFAULTUSERCLASS','SYSDEFAULTSYSTEMCLASS') THEN 'DEFAULT' 
            ELSE S.SERVICE_SUPERCLASS_NAME END 
    || CASE WHEN S.SERVICE_SUBCLASS_NAME IN ('SYSDEFAULTSUBCLASS','SYSDEFAULTSYSTECLASS') THEN '' 
            ELSE CASE WHEN S.SERVICE_SUPERCLASS_NAME IS NOT NULL THEN '.' ELSE '' END 
                 || S.SERVICE_SUBCLASS_NAME END    
                          AS SERVICE_CLASS  
,   APPLICATION_NAME
,   CLIENT_USER
                          ,   WORKLOAD_OCCURRENCE_STATE   AS STATE
,   COUNT(DISTINCT APPLICATION_HANDLE)  AS CONNECTIONS
,   COUNT(DISTINCT UOW_ID)              AS UOWS
FROM
    TABLE(WLM_GET_SERVICE_CLASS_WORKLOAD_OCCURRENCES(default, default, -2)) S
GROUP BY
    SYSTEM_AUTH_ID
,   SESSION_AUTH_ID
,   APPLICATION_NAME
,   CLIENT_USER
,   WORKLOAD_NAME
,   SERVICE_SUPERCLASS_NAME
,   SERVICE_SUBCLASS_NAME
,   WORKLOAD_OCCURRENCE_STATE

@

/*
 * Shows last time the database members were last restarted
 */

CREATE OR REPLACE VIEW DB_UPTIME AS
SELECT 
    DB2_STATUS
,   DB2START_TIME
,   TIMEZONEID
,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER) AS MEMBERS
,          DAYS_BETWEEN(CURRENT_TIMESTAMP, DB2START_TIME)       AS DAYS
,   MOD(  HOURS_BETWEEN(CURRENT_TIMESTAMP, DB2START_TIME),24)   AS HOURS
,   MOD(MINUTES_BETWEEN(CURRENT_TIMESTAMP, DB2START_TIME),60) AS MINUTES
,   MOD(SECONDS_BETWEEN(CURRENT_TIMESTAMP, DB2START_TIME),60) AS SECONDS
FROM
    TABLE(MON_GET_INSTANCE(-2))
GROUP BY
    DB2_STATUS
,   DB2START_TIME
,   TIMEZONEID
@

/*
 * Lists all possible WLM threshold types
 */

CREATE OR REPLACE VIEW DB_THRESHOLD_TYPES AS
SELECT
    RTRIM(THRESHOLD_TYPE)   AS THRESHOLD_TYPE
,   THRESHOLD_CATEGORY
,   QUEUING
,   THRESHOLD_DESCRIPTION
,   THRESHOLD_PREDICATE
,   DOMAINS
,   ENFORCEMENT
,   NOTES
FROM TABLE(
VALUES
 ('No','Activity','Upper bound for the amount of time the database manager allows an activity to run. The amount of time does not include the time that the activity was queued by a WLM concurrency threshold'
    ,'ACTIVITYTOTALRUNTIME          ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Activity','upper bound for the amount of time the database manager allows an activity to run.'
    ,'ACTIVITYTOTALRUNTIMEINALLSC   ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','SUBCLASS','MEMBER','')
,('No','Activity','upper bound for the amount of time the database manager will allow an activity to execute, including the time the activity was queued.'
    ,'ACTIVITYTOTALTIME             ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Aggregate','The maximum amount of system temporary space that can be consumed by a set of statements in a service class on a member'
    ,'AGGSQLTEMPSPACE               ' , '> integer-value K | M | G                                                                ','SUBCLASS','MEMBER','')
,('Yes','Aggregate','Upper bound on the number of recognized database coordinator activities that can run concurrently on all members in the specified domain'
    ,'CONCURRENTDBCOORDACTIVITIES   ' , '> integer-value  AND QUEUEDACTIVITIES > [0|integer-value|UNBOUNDED]                      ','DATABASE, work action, SUPERCLASS, SUBCLASS','DATABASE, MEMBER (pS only)','')
-- https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.admin.wlm.doc/doc/r0051917.html
-- A value of zero means that any new database coordinator activities will be prevented from executing.
-- CALL statements are not controlled by this threshold, but all nested child activities started within the called routine are under this threshold's control
-- User-defined functions are controlled by this threshold, but child activities nested in a user-defined function are not controlled.
-- Trigger actions that invoke CALL statements and the child activities of these CALL statements are not controlled by this threshold
,('No','Aggregate','Upper bound on the number of concurrent occurrences for the workload on each member'
    ,'CONCURRENTWORKLOADACTIVITIES  ' , '> integer-value                                                                          ','WORKLOAD','MEMBER','')
,('No','Aggregate','Upper bound on the number of concurrent coordinator activities and nested activities for the workload on each member'
    ,'CONCURRENTWORKLOADOCCURRENCES ' , '> integer-value                                                                          ','WORKLOAD','WORKLOAD OCCURRENCE','')
,('No','Connection','Upper bound for the amount of time the database manager will allow a connection to remain idle'
    ,'CONNECTIONIDLETIME            ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES                             ','DATABASE, SUPERCLASS','DATABASE','')
--If you specify the STOP EXECUTION action with CONNECTIONIDLETIME thresholds, the connection for the application is dropped when the threshold is exceeded. 
--  Any subsequent attempt by the application to access the data server will receive SQLSTATE 5U026.
,('No','Activity','Upper bound for the amount of processor time that an activity may consume during its lifetime on a particular member'
    ,'CPUTIME                       ' , '> integer-value HOUR | HOURS | MINUTE | MINUTES | SECOND | SECONDS  CHECKING EVERY integer-value SECONDS','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','MEMBER','')
,('No','Activity','Upper bound for the amount of processor time that an activity may consume on a particular member while it is executing in a particular service subclass'
    ,'CPUTIMEINSC                   ' , '> integer-value HOUR | HOURS | MINUTE | MINUTES | SECOND | SECONDS  CHECKING EVERY integer-value SECONDS','SUBCLASS','MEMBER','')
,('No','Activity','Defines one or more data tag values specified on a table space that the activity touches'
    ,'DATATAGINSC                   ' , '[NOT] IN (integer-constant, ...)                                                         ','SUBCLASS','MEMBER','')
,('No','Activity','upper bound for the optimizer-assigned cost (in timerons) of an activity'
    ,'ESTIMATEDSQLCOST              ' , '> bigint-value                                                                           ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
--a threshold for a work action definition domain is created using a CREATE WORK ACTION SET or ALTER WORK ACTION SET statement, and the work action set must be applied to a workload or a database
,('No','Activity','The maximum shared sort memory that may be requested by a query as a percentage of the total database shared sort memory (sheapthres_shr).'
    ,'SORTSHRHEAPUTIL               ' , '> integer-value PERCENT  AND BLOCKING ADMISSION FOR integer-value                        ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','Available from Db2 11.5.2.0')
,('No','Activity','Upper bound on the number of rows that may be read by an activity during its lifetime on a particular member'
    ,'SQLROWSREAD                   ' , '> bigint-value                                                                           ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Activity','Upper bound on the number of rows that may be read by an activity on a particular member while it is executing in a service subclass'
    ,'SQLROWSREADINSC               ' , '> bigint-value  CHECKING EVERY integer-value SECOND | SECONDS                            ','SUBCLASS','MEMBER','')
,('No','Activity','Upper bound for the number of rows returned to a client application from the application server'
    ,'SQLROWSRETURNED               ' , '> integer-value                                                                          ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('No','Activity','The maximum amount of system temporary space that can be consumed by an SQL statement on a member'
    ,'SQLTEMPSPACE                  ' , '> integer-value K | M | G                                                                ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
,('Yes (enforced at 0)','Aggregate','Upper bound on the number of coordinator connections that can run concurrently on a member'
    ,'TOTALMEMBERCONNECTIONS        ' , '> integer-value                                                                          ','DATABASE'  ,'MEMBER','not enforced for users with DBADM or WLMADM authority.')
,('Yes','Aggregate','Upper bound on the number of coordinator connections that can run concurrently on a member in a specific service superclass'
    ,'TOTALSCMEMBERCONNECTIONS      ' , '> integer-value AND QUEUEDCONNECTIONS > [0|integer-value|UNBOUNDED]                        ','SUPERCLASS','MEMBER','') 
-- Specifies a queue size for when the maximum number of coordinator connections is exceeded.
-- Specifying UNBOUNDED will queue every connection that exceeds the specified maximum number of coordinator connections
---   and the threshold-exceeded-actions will never be executed. The default is zero.
,('No','Unit of Work','Upper bound for the amount of time the database manager will allow a unit of work to execute'
    ,'UOWTOTALTIME                  ' , '> integer-value DAY | DAYS | HOUR | HOURS | MINUTE | MINUTES | SECONDS                   ','DATABASE, work action, SUPERCLASS, SUBCLASS, WORKLOAD','DATABASE','')
) AS T(QUEUING, THRESHOLD_CATEGORY, THRESHOLD_DESCRIPTION, THRESHOLD_TYPE, THRESHOLD_PREDICATE, DOMAINS, ENFORCEMENT, NOTES )

@

/*
 * WLM Thresholds 
 */

CREATE OR REPLACE VIEW DB_THRESHOLDS AS
SELECT 
    THRESHOLDNAME       AS THRESHOLD_NAME
,   THRESHOLDPREDICATE || ' > ' || MAXVALUE AS RULE
,   CASE EXECUTION WHEN 'R' THEN 'Remap' WHEN 'S' THEN 'Stop' WHEN 'C' THEN 'Continue' WHEN 'F' THEN 'Force off' ELSE EXECUTION END AS ACTION 
,   VIOLATIONRECORDLOGGED AS LOG
,   ENABLED
,   CASE ENFORCEMENT WHEN 'D' THEN 'Database' WHEN 'P' THEN 'Partition' WHEN 'W' THEN 'Workload occurrence' END AS ENFORCEMENT
FROM 
    SYSCAT.THRESHOLDS

@

/*
 * Lists user CREATEd and DECLAREd global temporary tables
 */

CREATE OR REPLACE VIEW DB_TEMP_TABLES AS
SELECT 
    TABSCHEMA
,   TABNAME
,   INSTANTIATOR        AS OWNER
,   TEMPTABTYPE         AS TYPE
,   INSTANTIATION_TIME
,   COLCOUNT
,   PARTITION_MODE
,   ONCOMMIT
,   ONROLLBACK
,   LOGGED
,   TAB_ORGANIZATION    AS TABLEORG
FROM
    TABLE(ADMIN_GET_TEMP_TABLES(null,null,null))
UNION ALL
SELECT 
    TABSCHEMA
,   TABNAME
,   OWNER
,   'CGTT'              AS TYPE
,   NULL                AS INSTANTIATION_TIME
,   COLCOUNT
,   PARTITION_MODE
,   ONCOMMIT
,   ONROLLBACK
,   LOGGED
,   TABLEORG
FROM
    SYSCAT.TABLES
WHERE
    TYPE = 'G'

@

/*
 * Simple DDL generator for DB2 Declared Global Temp Tables
 * 
 * Note that it does NOT include the following as they are not avaiable from the ADMIN table function
 * - DISTRIBUTE ON
 * - ORGANIZE BY
 * -  String Units
 * 
 * NOTE that if your table DDL will end up being more than 32 thousand bytes, the DDL will be split over more than 1 row. 
 *    This is to avoid the length of the generate DDL breaking the max length of a VARCHAR used by LISTAGG 
 */

CREATE OR REPLACE VIEW DB_TEMP_TABLE_QUICK_DDL AS
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   C.DDL_SPLIT_SEQ + 1                   AS DDL_LINE_NO
,   CASE WHEN DDL_SPLIT_SEQ = 0 THEN      -- Top 
         'DECLARE GLOBAL TEMPORARY TABLE "' ||  TABSCHEMA || '"."' || TABNAME || '"' || CHR(10) || '(' || CHR(10) 
    ELSE '' END
    || COLUMNS || CHR(10)                 -- Middle
    || ')'                                -- End
      AS DDL
FROM
    TABLE(ADMIN_GET_TEMP_TABLES(NULL,NULL,NULL)) T
JOIN 
(
  SELECT
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
      ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS))
                  || CASE WHEN COL_SEQ > 1 THEN CHR(10) || ',   ' ELSE '    ' END 
                  || '"' || COLNAME || '"'
                  || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
                  || DATATYPE_DDL
                  || CASE WHEN DEFAULT_VALUE_DDL <> '' THEN ' ' || DEFAULT_VALUE_DDL ELSE '' END 
                  ) WITHIN GROUP (ORDER BY COLNO) AS COLUMNS
      FROM
          (SELECT C.*
           ,    SUM(50 + LENGTH(DATATYPE_DDL) + LENGTH(DEFAULT_VALUE_DDL) )
                     OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
           FROM
           (
                SELECT
                    TABSCHEMA
                ,   TABNAME
                ,   COLNAME
                ,   COLNO
                ,   CASE
                        WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPH', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                        THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' WHEN TYPENAME = 'VARGRAPH' THEN 'VARGRAPHIC' ELSE TYPENAME END
                             || '(' || LENGTH
                             || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END || ')'
                        WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                        THEN TYPENAME || '(' || LENGTH || ')'  
                        WHEN TYPENAME LIKE 'TIMESTAM%' AND SCALE = 6
                        THEN 'TIMESTAMP'
                        WHEN TYPENAME LIKE ('TIMESTAM%')    -- cater for the DATATYPE column being truncated in the ADMIN function
                        THEN 'TIMESTAMP' || '(' || RTRIM(CHAR(SCALE))  || ')'
                        WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                        THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                        WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                        THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                        WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                        ELSE TYPENAME END 
                    || CASE WHEN INLINE_LENGTH <> 0 THEN ' INLINE LENGTH ' || INLINE_LENGTH ELSE '' END
                    || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
                ,   CASE WHEN DEFAULT IS NOT NULL THEN ' DEFAULT ' || DEFAULT ELSE '' END        AS DEFAULT_VALUE_DDL 
                ,   COLNO + 1                                                                    AS COL_SEQ
                FROM
                    TABLE(ADMIN_GET_TEMP_COLUMNS(NULL,NULL,NULL)) C
           ) C
          )
      GROUP BY
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000
    ) AS C
USING ( TABSCHEMA, TABNAME )

@

/*
 * Shows current system and user temporary tablespace usage by user
 */

CREATE OR REPLACE VIEW DB_TEMP_SPACE AS
  SELECT
      USER_NAME
  ,   TABSCHEMA  
  ,   TABNAME
  ,   DECIMAL(DECIMAL(SUM(SIZE_PAGES) * 16,21,2) / 1024 / 1024,7,2) AS SIZE_GB
  ,   SUM(ROWS_INSERTED)   AS ROWS_INSERTED
  ,   SUM(ROWS_READ)       AS ROWS_READ
  ,   MIN(TIMESTAMP(CREATE_CONNECT_TIME,0))   AS CREATE_CONNECT_TIME
  ,   CASE MIN(TEMPTABTYPE) WHEN 'S' THEN 'temp' WHEN 'D' THEN 'DGTT' WHEN 'C' THEN 'CGTT' END         AS TYPE
  ,   SMALLINT(MAX(COLCOUNT))                AS COLUMNS
  ,   MIN(PARTITION_MODE)                    AS HASH
  ,   CASE WHEN MIN(LOGGED) IN ('','Y') THEN 'Y' ELSE 'N' END    AS LOGGED
  FROM
  (
  SELECT
      I.USER_NAME
  ,   CASE WHEN I.TEMPTABTYPE = 'S' THEN '' ELSE T.TABSCHEMA END                    AS TABSCHEMA
  ,   CASE WHEN I.TEMPTABTYPE = 'S' THEN 'Query temp table(s)' ELSE T.TABNAME END   AS  TABNAME
  ,     COALESCE(T.DATA_OBJECT_L_PAGES,0) 
      + COALESCE(T.INDEX_OBJECT_L_PAGES,0)
      + COALESCE(T.LOB_OBJECT_L_PAGES,0)
      + COALESCE(T.LONG_OBJECT_L_PAGES,0)
      + COALESCE(T.XDA_OBJECT_L_PAGES,0)
            AS SIZE_PAGES
  ,   T.ROWS_INSERTED
  ,   T.ROWS_READ
  ,   I.TEMPTABTYPE
  ,   I.CREATE_CONNECT_TIME
  ,   I.COLCOUNT
  ,   I.PARTITION_MODE
  ,   I.ONCOMMIT
  ,   I.ONROLLBACK
  ,   I.LOGGED
  FROM (
    SELECT 
            TABSCHEMA
    ,       TABNAME
    ,       INSTANTIATOR    AS USER_NAME
    ,       TEMPTABTYPE
    ,       INSTANTIATION_TIME   AS CREATE_CONNECT_TIME
    ,       COLCOUNT
    ,       PARTITION_MODE
    ,       ONCOMMIT
    ,       ONROLLBACK
    ,       LOGGED
    FROM  TABLE(ADMIN_GET_TEMP_TABLES(null,null,null))
    UNION ALL
    SELECT
            '<' || APPLICATION_HANDLE || '><' || SYSTEM_AUTH_ID || '>' AS   TABSCHEMA
    ,       NULL            AS TABNAME
    ,       SYSTEM_AUTH_ID  AS USER_NAME
    ,       'S'             AS TEMPTABTYPE
    ,       CONNECTION_START_TIME   AS CREATE_CONNECT_TIME
    ,       NULL            AS COLCOUNT
    ,       NULL            AS PARTITION_MODE
    ,       NULL            AS ONCOMMIT
    ,       NULL            AS ONROLLBACK
    ,       NULL            AS LOGGED
    FROM TABLE(MON_GET_CONNECTION(NULL,-1))
    ) AS I
    , TABLE(MON_GET_TABLE(I.TABSCHEMA,I.TABNAME,-2)) T
 )
GROUP BY USER_NAME, TABSCHEMA, TABNAME
@

/*
 * Lists all temporal tables 
 * 
 * Note that the TEMPORALTYPE in SYSCAT.TABLES is not accurate when the table is MAINTAINED BY USER
 * 
 */

CREATE OR REPLACE VIEW DB_TEMPORAL_TABLES AS
SELECT
     T.TABSCHEMA
,    T.TABNAME
,    T.TEMPORALTYPE
,    CASE WHEN BT.BEGINCOLNAME IS NOT NULL AND ST.BEGINCOLNAME IS NOT NULL THEN 'Bitemporal table'
          WHEN BT.BEGINCOLNAME IS NOT NULL                                 THEN 'Application-period temporal table'
          WHEN                                 ST.BEGINCOLNAME IS NOT NULL THEN 'System-period temporal table'
     END AS TEMPORAL_TYPE
,    CASE WHEN SUBSTR(T.PROPERTY,29,1) = 'Y' THEN 'MAINTAINED BY USER' ELSE 'MAINTAINED BY SYSTEM' END    AS MAINTAINED_BY
,    BT.BEGINCOLNAME        BUSINESS_TIME_BEGIN_COLNAME
,    BT.ENDCOLNAME          BUSINESS_TIME_END_COLNAME
,    ST.BEGINCOLNAME        SYSTEM_TIME_BEGIN_COLNAME
,    ST.ENDCOLNAME          SYSTEM_TIME_END_COLNAME
FROM
    SYSCAT.TABLES    T
LEFT JOIN
    SYSCAT.PERIODS  BT 
ON
    T.TABSCHEMA = BT.TABSCHEMA AND T.TABNAME = BT.TABNAME AND BT.PERIODNAME = 'BUSINESS_TIME'
LEFT JOIN
    SYSCAT.PERIODS  ST 
ON
    T.TABSCHEMA = ST.TABSCHEMA AND T.TABNAME = ST.TABNAME AND ST.PERIODNAME = 'SYSTEM_TIME'
WHERE
    T.TEMPORALTYPE <> 'N' OR SUBSTR(PROPERTY,29,1) = 'Y'
    
@

/*
 * Shows if a table is in a non NORMAL status
 * 
 * See https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0052897.html 
 * for decodes of the status columns:
    LOAD_STATUS 
        IN_PROGRESS
        PENDING
        NULL (if there is no load in progress for the table and the table is not in load pending state)
    INPLACE_REORG_STATUS 
        ABORTED (in a PAUSED state, but unable to RESUME; STOP is required)
        EXECUTING
        PAUSED
        NULL (if no inplace reorg has been performed on the table)

 *
 * The code below uses MON_GET_UTILITY to avoid the call to ADMIN_GET_TAB_INFO from geting lock timeout if there are any in-progress loads
 */

CREATE OR REPLACE VIEW DB_TABLE_STATUS AS
WITH L AS (
    SELECT
        *
    FROM
        TABLE(MON_GET_UTILITY(-2))
    WHERE
        OBJECT_TYPE = 'TABLE'
    AND UTILITY_TYPE = 'LOAD'
    AND UTILITY_DETAIL NOT LIKE '%ONLINE LOAD%' 
)
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   T.STATUS
,   I.AVAILABLE
,   I.REORG_PENDING
,   I.INPLACE_REORG_STATUS
,   I.LOAD_STATUS
,   I.READ_ACCESS_ONLY
,   I.NO_LOAD_RESTART
,   I.NUM_REORG_REC_ALTERS
,   I.INDEXES_REQUIRE_REBUILD
,   MAX(DBPARTITIONNUM)         AS MAX_DBPARTITIONNUM
,   MIN(DBPARTITIONNUM)         AS MIN_DBPARTITIONNUM
,   MAX(DATA_PARTITION_ID)      AS MAX_DATA_PARTITION_ID
,   MIN(DATA_PARTITION_ID)      AS MIN_DATA_PARTITION_ID
FROM
    SYSCAT.TABLES  T
,   TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
WHERE
    T.TABSCHEMA = I.TABSCHEMA
AND T.TABNAME   = I.TABNAME
AND ( T.TABSCHEMA, T.TABNAME ) NOT IN (SELECT OBJECT_SCHEMA, OBJECT_NAME FROM L L)
AND T.TABSCHEMA <> 'SYSIBM'
GROUP BY
    T.TABSCHEMA
,   T.TABNAME
,   T.STATUS
,   I.AVAILABLE
,   I.REORG_PENDING
,   I.INPLACE_REORG_STATUS
,   I.LOAD_STATUS
,   I.READ_ACCESS_ONLY
,   I.NO_LOAD_RESTART
,   I.NUM_REORG_REC_ALTERS
,   I.INDEXES_REQUIRE_REBUILD
UNION ALL
SELECT
    OBJECT_SCHEMA
,   OBJECT_NAME
,   'L'                  AS STATUS
,   'Y'                  AS AVAILABLE
,   ''                   AS REORG_PENDING
,   ''                   AS INPLACE_REORG_STATUS
,   'IN_PROGRESS'        AS LOAD_STATUS
,   CASE WHEN UTILITY_DETAIL LIKE '%ONLINE LOAD%' THEN  'Y' ELSE 'N' END  AS READ_ACCESS_ONLY
,   ''                   AS NO_LOAD_RESTART
,   NULL                 AS NUM_REORG_REC_ALTERS
,   NULL                 AS INDEXES_REQUIRE_REBUILD
,   NULL                 AS MAX_DBPARTITIONNUM
,   NULL                 AS MIN_DBPARTITIONNUM
,   NULL                 AS MAX_DATA_PARTITION_ID
,   NULL                 AS MIN_DATA_PARTITION_ID
FROM L

@

/*
 * Shows table statistics and rows modified since last runstats
 */

CREATE OR REPLACE VIEW DB_TABLE_STATISTICS AS
SELECT
    TABSCHEMA
,   TABNAME
,   STATS_TIME
,   CARD
,   STATS_ROWS_MODIFIED
,   RTS_ROWS_MODIFIED
,   CASE WHEN STATS_ROWS_MODIFIED > 0 AND DECFLOAT(STATS_ROWS_MODIFIED) / CARD > 0.5 THEN 1 ELSE 0 END AS AUTO_STATS_CANDIDATE
    /* the actual algorithm is more complex that this, but this is a reasonalbe approximation */
FROM
    SYSCAT.TABLES
LEFT JOIN
(
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   MAX(NULLIF(STATS_ROWS_MODIFIED,POWER(2::BIGINT,32)-1))    AS STATS_ROWS_MODIFIED  -- the number of rows modified since the last RUNSTATS.
    ,   MAX(NULLIF(RTS_ROWS_MODIFIED,POWER(2::BIGINT,32)-1)  )    AS RTS_ROWS_MODIFIED    -- the number of rows modified since last real-time statistics collection.
    FROM
        TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS T
    WHERE
        TAB_TYPE <> 'EXTERNAL_TABLE'
    GROUP BY
        TABSCHEMA
    ,   TABNAME
)
    USING ( TABSCHEMA, TABNAME )
WHERE
    TYPE NOT IN ('A','N','V','W')

@

/*
 * Tables, Views, Nicknames, MQTs and other objects from the SYSCAT.TABLES catalog view 
 */

CREATE OR REPLACE VIEW DB_TABLES AS
SELECT
     TABSCHEMA
,    TABNAME
,       CASE TYPE
            WHEN 'T' THEN 'TABLE'
            WHEN 'V' THEN 'VIEW'
            WHEN 'S' THEN 'MQT'
            WHEN 'G' THEN 'CGTT'
            WHEN 'N' THEN 'NNAME'   -- Nickname
            WHEN 'A' THEN 'ALIAS'
            ELSE TYPE
        END AS TABLE_TYPE
/*DB_BLU*/,       CASE WHEN TYPE IN ('T','S','G') THEN 
/*DB_BLU*/            CASE TABLEORG WHEN 'C' THEN 'COL' WHEN 'R' THEN 'ROW' END ELSE '' 
/*DB_BLU*/         END   AS ORG
,       CARD
,       CASE WHEN FPAGES > 0
             THEN FPAGES * (SELECT PAGESIZE FROM SYSCAT.TABLESPACES TB WHERE T.TBSPACE = TB.TBSPACE)
        ELSE 0 END                                  AS DATA_BYTES /*! Size of data  pages allocated to this object. Excludes index pages */
,       PCTPAGESSAVED  AS PCT_PAGES_SAVED                  /*! Percentage pages saved by ROW or COLUMN compression. PCTPAGESSAVED */
,       AVGROWSIZE     AS AVG_ROW_SIZE                     /* AVGROWLEN */
,       INT(100.0 * NPAGES / FPAGES)                AS FILL       /*  The percentage of pages allocated that actually have rows. NPAGES / FPAGES */
,       SUBSTR(CREATE_TIME,1,19)                    AS CREATE_DATETIME
/*DB_09_7_0_0*/,       LASTUSED
,       COALESCE(RTRIM(BASE_TABSCHEMA) || '.' || RTRIM(BASE_TABNAME),'') || COALESCE(REMARKS,'') AS ALIAS_OR_COMMENT
FROM
    SYSCAT.TABLES    T
    
@

/*
 * Lists tablespaces showing page size, max size (if set) etc
 */

CREATE OR REPLACE VIEW DB_TABLESPACES AS 
SELECT
    T.TBSPACE
,   NULLIF(DECIMAL(M.TBSP_MAX_SIZE/(1024*1024*1024.0),9,1),0)   MAX_SIZE_PER_MEMBER_GB
,   M.SUM_MAX_SIZE/(1024*1024*1024) SUM_MAX_SIZE_GB
,   T.PAGESIZE/1024 || 'K'    AS PAGE_SIZE
,   T.EXTENTSIZE             AS EXTENT_SIZE
,   CASE WHEN T.DATATYPE = 'A' THEN 'REGULAR' 
         WHEN T.DATATYPE = 'L' THEN 'LARGE'
         WHEN T.DATATYPE = 'T' THEN 'SYSTEM TEMPORARY'
         WHEN T.DATATYPE = 'U' THEN 'USER TEMPORARY'
    END                                                    AS TBSPACE_TYPE
,   CASE WHEN TBSP_USING_AUTO_STORAGE =1 THEN 'AUTOMATIC STORAGE'
         WHEN T.TBSPACETYPE = 'D'  THEN 'DATABASE'
         WHEN T.TBSPACETYPE = 'S'  THEN 'SYSTEM'
         END                                                AS MANAGED_BY
,   T.SGNAME
,   T.DBPGNAME
,   B.BPNAME
,   D.DATASLICES
,   M.TBSP_STATE          
,   M.TBSP_TRACKMOD_STATE
,   COALESCE(t.REMARKS,'')      AS COMMENTS
FROM 
    SYSCAT.TABLESPACES T
INNER JOIN
    SYSCAT.BUFFERPOOLS B
ON
    T.BUFFERPOOLID = B.BUFFERPOOLID
LEFT OUTER JOIN
(	SELECT
	    TBSP_NAME
	,   MIN(TBSP_USING_AUTO_STORAGE)  AS TBSP_USING_AUTO_STORAGE
	,   MAX(TBSP_EXTENT_SIZE)         AS TBSP_EXTENT_SIZE
	,   MAX(TBSP_STATE)               AS TBSP_STATE
	,   MAX(TBSP_TRACKMOD_STATE)      AS TBSP_TRACKMOD_STATE
	,   MAX(TBSP_PAGE_SIZE)           AS TBSP_PAGE_SIZE
	,   MAX(TBSP_MAX_SIZE)            AS TBSP_MAX_SIZE
	,   NULLIF(SUM(CASE WHEN TBSP_MAX_SIZE = -1 THEN 0 ELSE TBSP_MAX_SIZE END),0) AS SUM_MAX_SIZE
	FROM
	       TABLE (MON_GET_TABLESPACE(NULL,-2)) T
    GROUP BY
       TBSP_NAME
) M
ON
    T.TBSPACE = M.TBSP_NAME
LEFT OUTER JOIN
(   SELECT
        DBPGNAME
    ,   LISTAGG(DBPARTITIONNUM, ',') WITHIN GROUP (ORDER BY DBPARTITIONNUM ASC) AS DATASLICES
    FROM 
        SYSCAT.DBPARTITIONGROUPDEF
    GROUP BY 
        DBPGNAME
) D
ON
    T.DBPGNAME = D.DBPGNAME
    
@

/*
 * Reports of the progress of any background extent movement such as as initiated by ALTER TABLESPACE REDUE MAX
 */

CREATE OR REPLACE VIEW DB_TABLESPACE_REDUCE_PROGRESS AS
SELECT TBSP_NAME                                         AS TBSPACE
,      SUM(NUM_EXTENTS_MOVED)                            AS EXTENTS_MOVED
,      SUM(NUM_EXTENTS_LEFT)                             AS EXTENTS_LEFT
,      DEC(ROUND(MAX(TOTAL_MOVE_TIME)/1000/60.0,2),9,2)  AS DURATION_MINS
,      DECIMAL((SUM(NUM_EXTENTS_MOVED) / ((SUM(NUM_EXTENTS_MOVED) + SUM(NUM_EXTENTS_LEFT)) *1.0))*100,5,2) AS PCT_COMPLETE
,      DEC(SUM(TOTAL_MOVE_TIME) * 1.0/SUM(NUM_EXTENTS_MOVED),6,1)                                   AS EXTENTS_PER_SEC
--,      TIMESTAMP(CURRENT TIMESTAMP,0) + ((SUM(TOTAL_MOVE_TIME)*1000.0/SUM(NUM_EXTENTS_MOVED))*SUM(NUM_EXTENTS_LEFT)) SECONDS  AS EST_FINISH_DT
FROM
       TABLE( MON_GET_EXTENT_MOVEMENT_STATUS(NULL,-2)) 
WHERE
       TOTAL_MOVE_TIME > 0
GROUP BY
      TBSP_NAME
@

/*
 * Shows any data skew at the tablespace level. Only shows data for tablespaces touched since the last Db2 restart
 */

CREATE OR REPLACE VIEW DB_TABLESPACE_QUICK_SKEW AS
SELECT 
    TBSP_NAME    
,   MAX(TBSP_PAGE_TOP) * MAX(TBSP_PAGE_SIZE) / 1048576  AS MAX_TOP_MB
,   MIN(TBSP_PAGE_TOP) * MAX(TBSP_PAGE_SIZE) / 1048576  AS MIN_TOP_MB
,   DECIMAL( (MAX(TBSP_USED_PAGES) - AVG(TBSP_USED_PAGES)) * COUNT(*) * MAX(TBSP_PAGE_SIZE) / POWER(1024.0,3),17,3) AS WASTED_GB
,   DECIMAL((1 - AVG(TBSP_PAGE_TOP*1.0)/ NULLIF(MAX(TBSP_PAGE_TOP),0))*100,5,2)    AS SKEW
,   MAX(CASE WHEN MEMBER_ASC_RANK = 1  THEN MEMBER END) AS SMALLEST_MEMBER
,   MAX(CASE WHEN MEMBER_DESC_RANK = 1 THEN MEMBER END) AS LARGEST_MEMBER
FROM
    (SELECT T.*
    ,       ROW_NUMBER() OVER (PARTITION BY TBSP_NAME ORDER BY TBSP_USED_PAGES ASC)  AS MEMBER_ASC_RANK
    ,       ROW_NUMBER() OVER (PARTITION BY TBSP_NAME ORDER BY TBSP_USED_PAGES DESC) AS MEMBER_DESC_RANK
    FROM
     TABLE(MON_GET_TABLESPACE(NULL,-2)) T
     ) T
GROUP BY 
    TBSP_NAME
HAVING COUNT(*) > 1
@

/*
 * Returns the size of each tablespaces that has been touched since the last Db2 restart
 */

CREATE OR REPLACE VIEW DB_TABLESPACE_QUICK_SIZE AS 
SELECT  
     TBSP_NAME
,    ROUND(100 * (DECFLOAT(S.TBSP_USED_PAGES) / S.TBSP_USABLE_PAGES),2)     AS PCT_USED
,    INTEGER(ROUND((S.TBSP_USED_PAGES   * TBSP_PAGE_SIZE) /1073741824.0,0)) AS USED_GB
,    INTEGER(ROUND((S.TBSP_USABLE_PAGES * TBSP_PAGE_SIZE) /1073741824.0,0)) AS USABLE_GB
,    INTEGER(ROUND((S.TBSP_PAGE_TOP     * TBSP_PAGE_SIZE) /1073741824.0,0)) AS HWM_GB
,    BIGINT(ROUND((S.TBSP_MAX_SIZE     * TBSP_PAGE_SIZE) /1073741824.0,0))  AS MAX_GB
,    DATASLICES
,    INTEGER(ROUND((S.TBSP_MAX_USED_PAGES * DATASLICES * TBSP_PAGE_SIZE) /BIGINT(1073741824),0))    AS SKEW_USED_GB
,    INTEGER(ROUND((S.TBSP_MAX_USABLE_PAGES * DATASLICES * TBSP_PAGE_SIZE) /BIGINT(1073741824),0))  AS SKEW_USABLE_GB
,    INTEGER(ROUND((S.TBSP_MAX_PAGE_TOP     * DATASLICES * TBSP_PAGE_SIZE) /BIGINT(1073741824),0))  AS SKEW_HWM_GB
FROM
(   SELECT
        TBSP_NAME
    ,   MAX(TBSP_PAGE_SIZE) AS TBSP_PAGE_SIZE
    ,   SUM(BIGINT(TBSP_USABLE_PAGES))  AS TBSP_USABLE_PAGES
    ,   MAX(BIGINT(TBSP_USABLE_PAGES))  AS TBSP_MAX_USABLE_PAGES
    ,   SUM(BIGINT(TBSP_USED_PAGES))    AS TBSP_USED_PAGES
    ,   MAX(BIGINT(TBSP_USED_PAGES))    AS TBSP_MAX_USED_PAGES
    ,   SUM(BIGINT(TBSP_PAGE_TOP))      AS TBSP_PAGE_TOP
    ,   MAX(BIGINT(TBSP_PAGE_TOP))      AS TBSP_MAX_PAGE_TOP
    ,   SUM(BIGINT(TBSP_FREE_PAGES))    AS TBSP_FREE_PAGES
    ,   NULLIF(MAX(SUM(BIGINT(TBSP_MAX_SIZE)),0),0)      AS TBSP_MAX_SIZE
    ,   COUNT(*)                        AS DATASLICES
    FROM   
        TABLE(MON_GET_TABLESPACE(NULL,-2)) S
    GROUP BY
        TBSP_NAME
) AS S

@

/*
 * Tablespace activity metrics using same SQL as dsmtop tablespaces screen
 */

-- SQL taken from dsmtop
CREATE OR REPLACE VIEW DB_TABLESPACE_ACTIVITY AS
SELECT  -- CASE WHEN TBSP_STATE <> 'NORMAL' THEN CAST ('!' || TBSP_NAME AS varchar (30)) ELSE CAST (TBSP_NAME AS varchar (30)) END AS TBSP_NAME
  TBSP_NAME
, CASE WHEN TBSP_CONTENT_TYPE = 'ANY'     THEN VARCHAR('Regular', 16)
       WHEN TBSP_CONTENT_TYPE = 'LARGE'   THEN VARCHAR('Large', 16)
       WHEN TBSP_CONTENT_TYPE = 'SYSTEMP' THEN VARCHAR('System temporary', 16)
       WHEN TBSP_CONTENT_TYPE = 'USRTEMP' THEN VARCHAR('User temporary', 16)
       ELSE                                    VARCHAR('Unknown', 16)  END AS TBSP_CONTENT_TYPE
, TBSP_STATE
, SUM(MTSP.POOL_DATA_L_READS + MTSP.POOL_TEMP_DATA_L_READS + MTSP.POOL_XDA_L_READS + MTSP.POOL_TEMP_XDA_L_READS + MTSP.POOL_INDEX_L_READS + MTSP.POOL_TEMP_INDEX_L_READS + MTSP.POOL_COL_L_READS + MTSP.POOL_TEMP_COL_L_READS) AS POOL_L_READS
, SUM(MTSP.POOL_DATA_P_READS + MTSP.POOL_INDEX_P_READS + MTSP.POOL_XDA_P_READS + MTSP.POOL_TEMP_DATA_P_READS + MTSP.POOL_TEMP_INDEX_P_READS + MTSP.POOL_TEMP_XDA_P_READS + MTSP.POOL_COL_P_READS + MTSP.POOL_TEMP_COL_P_READS) AS POOL_P_READS
, SUM(MTSP.POOL_DATA_LBP_PAGES_FOUND + MTSP.POOL_INDEX_LBP_PAGES_FOUND + MTSP.POOL_XDA_LBP_PAGES_FOUND + MTSP.POOL_COL_LBP_PAGES_FOUND - MTSP.POOL_ASYNC_DATA_LBP_PAGES_FOUND - MTSP.POOL_ASYNC_INDEX_LBP_PAGES_FOUND - MTSP.POOL_ASYNC_XDA_LBP_PAGES_FOUND - MTSP.POOL_ASYNC_COL_LBP_PAGES_FOUND)
                                                                                                                                        AS ALL_HIT_RATIO_NUMER
, SUM(MTSP.POOL_ASYNC_DATA_READS + MTSP.POOL_ASYNC_INDEX_READS + MTSP.POOL_ASYNC_XDA_READS + MTSP.POOL_ASYNC_COL_READS)                 AS ASYNC_READS
, SUM(MTSP.POOL_ASYNC_DATA_READ_REQS + MTSP.POOL_ASYNC_INDEX_READ_REQS + MTSP.POOL_ASYNC_XDA_READ_REQS + MTSP.POOL_ASYNC_COL_READ_REQS) AS ASYNC_READ_REQ
, SUM(MTSP.POOL_DATA_WRITES + MTSP.POOL_INDEX_WRITES + MTSP.POOL_XDA_WRITES + MTSP.POOL_COL_WRITES + MTSP.DIRECT_WRITES)                AS WRITES
, SUM(MTSP.POOL_ASYNC_DATA_WRITES + MTSP.POOL_ASYNC_INDEX_WRITES + MTSP.POOL_ASYNC_XDA_WRITES + MTSP.POOL_ASYNC_COL_WRITES)             AS ASYNC_WRITES
, SUM(MTSP.DIRECT_WRITES)     AS DIRECT_WRITES
, SUM(MTSP.POOL_DATA_WRITES)  AS POOL_DATA_WRITES
, SUM(MTSP.POOL_INDEX_WRITES) AS POOL_INDEX_WRITES
, SUM(MTSP.DIRECT_READS)      AS DIRECT_READS
, SUM(MTSP.DIRECT_READ_REQS)  AS DIRECT_READ_REQS
, SUM(MTSP.POOL_READ_TIME + MTSP.DIRECT_READ_TIME)   AS READ_TIME_MS
, SUM(MTSP.POOL_DATA_P_READS + MTSP.POOL_INDEX_P_READS + MTSP.POOL_TEMP_DATA_P_READS + MTSP.POOL_TEMP_INDEX_P_READS + MTSP.DIRECT_READS) AS TOTAL_READS
, SUM(MTSP.POOL_WRITE_TIME + MTSP.DIRECT_WRITE_TIME) AS WRITE_TIME_MS
, SUM(MTSP.DIRECT_WRITES + MTSP.POOL_DATA_WRITES + MTSP.POOL_INDEX_WRITES) AS TOTAL_WRITES
, COUNT(*) AS NUM_DBP
, SUM(TBSP_PAGE_SIZE * (MTSP.POOL_ASYNC_DATA_READS + MTSP.POOL_ASYNC_INDEX_READS + MTSP.POOL_ASYNC_XDA_READS + MTSP.POOL_ASYNC_COL_READS)) AS READ_BYTES
, SUM(TBSP_USED_PAGES * TBSP_PAGE_SIZE)  AS USED_SPACE_BYTES
, SUM(TBSP_TOTAL_PAGES * TBSP_PAGE_SIZE) AS TOTAL_SPACE_BYTES
, CASE WHEN
     SUM(TBSP_EXTENT_SIZE) = 0 THEN NULL ELSE CAST (
    SUM(TBSP_TOTAL_PAGES) * 1.0 /
     SUM(TBSP_EXTENT_SIZE) AS double) END AS NUM_EXTENT
, CASE WHEN MAX(TBSP_TYPE) = 'DMS' THEN
     SUM(TBSP_PAGE_TOP * TBSP_PAGE_SIZE) ELSE NULL END AS TOP_SPACE_BYTES
, CASE WHEN MAX(TBSP_TYPE) = 'DMS' THEN
     SUM(TBSP_MAX_PAGE_TOP * TBSP_PAGE_SIZE) ELSE NULL END AS MAX_TOP_SPACE_BYTES
, CAST (CASE WHEN MAX(TBSP_TYPE) = 'DMS' AND SUM(TBSP_TOTAL_PAGES) <> 0 THEN
     SUM(TBSP_USED_PAGES) * 1.0 /
     SUM(TBSP_TOTAL_PAGES) ELSE NULL END AS double) AS PERCENT_FULL
, CASE WHEN
     MAX(TBSP_MAX_PAGE_TOP) = 0 THEN NULL ELSE CAST (1 -
     AVG(TBSP_USED_PAGES) * 1.0 /
     MAX(TBSP_MAX_PAGE_TOP) AS double) END AS DATA_SKEW
, CASE WHEN
     MAX(MTSP.POOL_DATA_L_READS + MTSP.POOL_TEMP_DATA_L_READS + MTSP.POOL_XDA_L_READS + MTSP.POOL_TEMP_XDA_L_READS + MTSP.POOL_INDEX_L_READS + MTSP.POOL_TEMP_INDEX_L_READS + MTSP.POOL_COL_L_READS + MTSP.POOL_TEMP_COL_L_READS) = 0 THEN NULL ELSE (1 -
     AVG(MTSP.POOL_DATA_L_READS + MTSP.POOL_TEMP_DATA_L_READS + MTSP.POOL_XDA_L_READS + MTSP.POOL_TEMP_XDA_L_READS + MTSP.POOL_INDEX_L_READS + MTSP.POOL_TEMP_INDEX_L_READS + MTSP.POOL_COL_L_READS + MTSP.POOL_TEMP_COL_L_READS) * 1.0 /
     MAX(MTSP.POOL_DATA_L_READS + MTSP.POOL_TEMP_DATA_L_READS + MTSP.POOL_XDA_L_READS + MTSP.POOL_TEMP_XDA_L_READS + MTSP.POOL_INDEX_L_READS + MTSP.POOL_TEMP_INDEX_L_READS + MTSP.POOL_COL_L_READS + MTSP.POOL_TEMP_COL_L_READS)) END AS IO_SKEW
, MAX(TBSP_TYPE) AS TBSP_TYPE
, CASE WHEN MAX(FS_CACHING) = 0 THEN VARCHAR('Yes', 3) ELSE VARCHAR('No', 3) END AS FS_CACHING
, CASE WHEN MAX(TBSP_USING_AUTO_STORAGE) = 1 THEN VARCHAR('Yes', 3) ELSE VARCHAR('No', 3) END AS TBSP_USING_AUTO_STORAGE
, CASE WHEN MAX(TBSP_AUTO_RESIZE_ENABLED) = 1 THEN VARCHAR('Yes', 3) ELSE VARCHAR('No', 3) END AS TBSP_AUTO_RESIZE_ENABLED
, CASE WHEN MAX(TBSP_AUTO_RESIZE_ENABLED) = 1 AND MAX(TBSP_LAST_RESIZE_FAILED) = 1 THEN VARCHAR('Yes', 3) WHEN MAX(TBSP_AUTO_RESIZE_ENABLED) = 1 AND MAX(TBSP_LAST_RESIZE_FAILED) <> 1 THEN VARCHAR('No', 3)  ELSE NULL END AS TBSP_LAST_RESIZE_FAILED
, MIN(TBSP_LAST_RESIZE_TIME) AS TBSP_LAST_RESIZE_TIME
, SUM(MTSP.FILES_CLOSED) AS FILES_CLOSED
, SUM(POOL_NO_VICTIM_BUFFER) AS POOL_NO_VICTIM_BUFFER
, SUM(MTSP.UNREAD_PREFETCH_PAGES) AS UNREAD_PREFETCH_PAGES
, SUM(MTSP.POOL_XDA_L_READS + MTSP.POOL_TEMP_XDA_L_READS) AS XDA_L_READS
, SUM(MTSP.POOL_XDA_P_READS + MTSP.POOL_TEMP_XDA_P_READS) AS XDA_P_READS
, SUM(MTSP.POOL_XDA_WRITES)                AS XDA_WRITES
, SUM(TBSP_PAGE_SIZE)                      AS TBSP_PAGE_SIZE_BYTES
, SUM(TBSP_PAGE_SIZE * TBSP_EXTENT_SIZE)   AS EXTENT_SIZE_BYTES
, SUM(TBSP_PAGE_SIZE * TBSP_PREFETCH_SIZE) AS PREFETCH_SIZE_BYTES
, MIN(TABLESPACE_MIN_RECOVERY_TIME) AS MIN_RECOVERY_TIME
, SUM(MTSP.POOL_DATA_WRITES + MTSP.POOL_INDEX_WRITES + MTSP.POOL_XDA_WRITES + MTSP.POOL_COL_WRITES + MTSP.DIRECT_WRITES + MTSP.POOL_DATA_L_READS + MTSP.POOL_INDEX_L_READS + MTSP.POOL_TEMP_DATA_L_READS + MTSP.POOL_TEMP_INDEX_L_READS + MTSP.POOL_XDA_L_READS + MTSP.POOL_TEMP_XDA_L_READS + MTSP.POOL_COL_L_READS + MTSP.POOL_TEMP_COL_L_READS) AS IO
    FROM               TABLE(MON_GET_TABLESPACE(NULL,-2)) AS MTSP
      LEFT OUTER JOIN SYSCAT.BUFFERPOOLS                  AS BP    ON MTSP.TBSP_CUR_POOL_ID = BP.BUFFERPOOLID
      LEFT OUTER JOIN  TABLE(MON_GET_BUFFERPOOL(NULL,-2)) AS MBP   ON BP.BPNAME = MBP.BP_NAME AND MTSP.MEMBER = MBP.MEMBER
GROUP BY
    TBSP_NAME
,   TBSP_CONTENT_TYPE
,   TBSP_STATE
@

/*
 * Shows the data skew of database partitioned tables.
 */

CREATE OR REPLACE VIEW DB_TABLE_SKEW AS
SELECT
    TABSCHEMA
,   TABNAME
,   M.MAX_DATA_BYTES / (1024*1024) AS MAX_DATA_MB
,   M.MIN_DATA_BYTES / (1024*1024) AS MIN_DATA_MB
--,   M.AVG_DATA_BYTES / (1024*1024) AS AVG_TABLE_MB
,   DECIMAL((((MAX_DATA_BYTES - AVG_DATA_BYTES) * MEMBERS) / (1024*1024)),17,1) AS WASTED_MB
,   M.SKEW
,   M.LARGEST_MEMBER
,   M.DATA_BYTES / (1024*1024)  AS DATA_MB
,   M.INDEX_BYTES / (1024*1024) AS INDEX_MB
--,   TBSPACE
--,   D.DISTRIBUTION_KEY
--,   T.CARD
--,   T.PCTPAGESSAVED                                     AS PCT_COMPRESSED
--,   D.MAX_DIST_COLCARD
--,   T.OWNER
--,   T.LASTUSED
--,   T.CREATE_TIME
FROM
(   SELECT  
        TABSCHEMA
    ,   TABNAME
    ,   COUNT(*)                                            AS MEMBERS
    ,   MAX(DATA_BYTES)                                     AS MAX_DATA_BYTES
    ,   MIN(DATA_BYTES)                                     AS MIN_DATA_BYTES
    ,   AVG(DATA_BYTES)                                     AS AVG_DATA_BYTES
    ,   SUM(DATA_BYTES)                                     AS DATA_BYTES    
    ,   MAX(DATA_BYTES) - AVG(DATA_BYTES)::BIGINT           AS SKEWED_BYTES
    ,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(DATA_BYTES)),0)/ NULLIF(MAX(DECFLOAT(DATA_BYTES)),0))*100,5,2) END    AS SKEW
    ,   MAX(CASE WHEN MEMBER_ASC_RANK  = 1 THEN MEMBER END) AS SMALLEST_MEMBER
    ,   MAX(CASE WHEN MEMBER_DESC_RANK = 1 THEN MEMBER END) AS LARGEST_MEMBER
    ,   MAX(INDEX_BYTES)                                    AS MAX_INDEX_BYTES
    ,   MIN(INDEX_BYTES)                                    AS MIN_INDEX_BYTES
    ,   SUM(INDEX_BYTES)                                    AS INDEX_BYTES
    FROM
    (   SELECT 
            TABSCHEMA
        ,   TABNAME
        ,   MEMBER
        ,   SUM(DATA_L_KB)  * 1024                AS DATA_BYTES
        ,   SUM(INDEX_L_KB) * 1024                AS INDEX_BYTES
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(DATA_L_KB) ASC)  AS MEMBER_ASC_RANK
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(DATA_L_KB) DESC) AS MEMBER_DESC_RANK
        FROM   
        (
        SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   I.DBPARTITIONNUM AS MEMBER
        ,   MAX(T.TABLEORG) AS TABLEORG
        ,   SUM(DATA_OBJECT_L_SIZE +                       LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE) AS DATA_L_KB
        ,   SUM(                      INDEX_OBJECT_L_SIZE                                                                                ) AS INDEX_L_KB
        ,   SUM(DATA_OBJECT_P_SIZE +                       LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE) AS DATA_P_KB
        ,   SUM(                      INDEX_OBJECT_P_SIZE                                                                                ) AS INDEX_P_KB
        ,   SUM(RECLAIMABLE_SPACE)  AS RECLAIMABLE_KB
        FROM
            SYSCAT.TABLES  T
        JOIN   
            TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
        ON  
            T.TABSCHEMA = I.TABSCHEMA
        AND T.TABNAME   = I.TABNAME
        AND T.TYPE IN ('T','S')
        AND NOT (T.TABSCHEMA = 'SYSIBM' AND SUBSTR(T.PROPERTY,21,1) = 'Y')      -- ignore synopsis tables
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
        ,   I.DBPARTITIONNUM
        ) M
    GROUP BY
            TABSCHEMA
    ,       TABNAME
    ,       MEMBER
) M
    GROUP BY
            TABSCHEMA
    ,       TABNAME
) M


@

/*
 * Returns an accurate size of each table using ADMIN_GET_TAB_INFO(). The view can be slow to return on large systems if you don't filter
 */

CREATE OR REPLACE VIEW DB_TABLE_SIZE AS
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   MAX(DATA_L_KB + INDEX_L_KB + SYN_L_KB, DATA_P_KB + INDEX_P_KB + SYN_P_KB) AS SIZE_KB
,   CASE WHEN  DATA_L_KB + INDEX_L_KB + SYN_L_KB > DATA_P_KB + INDEX_P_KB + SYN_P_KB THEN 'LOGICAL'
          WHEN DATA_L_KB + INDEX_L_KB + SYN_L_KB < DATA_P_KB + INDEX_P_KB + SYN_P_KB THEN 'PHYSICAL'
          ELSE 'LOG = PHYS' END AS SIZE_SOURCE
,   DATA_L_KB
,   DATA_P_KB
,   INDEX_L_KB
,   INDEX_P_KB
,   SYN_L_KB
,   SYN_P_KB
,   RECLAIMABLE_KB
,   PCTPAGESSAVED
FROM
(
    SELECT
        T.*
    ,   COALESCE(   -- Get Synopsis logical table size for BLU tables
            (SELECT SUM(DATA_OBJECT_L_SIZE + INDEX_OBJECT_L_SIZE + LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE)
                FROM
                    TABLE(ADMIN_GET_TAB_INFO(T.SYN_TABSCHEMA, T.SYN_TABNAME)) S
                WHERE
                    S.TABSCHEMA = T.SYN_TABSCHEMA
                AND S.TABNAME   = T.SYN_TABNAME
                AND T.TABLEORG = 'C'
        ),0) AS SYN_L_KB
    ,   COALESCE(   -- Get Synopsis physical table size for BLU tables
            (SELECT SUM(DATA_OBJECT_P_SIZE + INDEX_OBJECT_P_SIZE + LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE)
                FROM
                    TABLE(ADMIN_GET_TAB_INFO(T.SYN_TABSCHEMA, T.SYN_TABNAME)) S
                WHERE
                    S.TABSCHEMA = T.SYN_TABSCHEMA
                AND S.TABNAME   = T.SYN_TABNAME
                AND T.TABLEORG = 'C'
        ),0) AS SYN_P_KB
        FROM
    (
        SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   MAX(T.TABLEORG)      AS TABLEORG
        ,   MAX(T.PCTPAGESSAVED) AS PCTPAGESSAVED
        ,   SUM(DATA_OBJECT_L_SIZE +                       LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE) AS DATA_L_KB
        ,   SUM(                      INDEX_OBJECT_L_SIZE                                                                                ) AS INDEX_L_KB
        ,   SUM(DATA_OBJECT_P_SIZE +                       LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE) AS DATA_P_KB
        ,   SUM(                      INDEX_OBJECT_P_SIZE                                                                                ) AS INDEX_P_KB
        ,   SUM(RECLAIMABLE_SPACE)  AS RECLAIMABLE_KB
        ,   'SYSIBM'  AS SYN_TABSCHEMA
        ,   COALESCE(   (SELECT D.TABNAME FROM SYSCAT.TABDEP D WHERE T.TABSCHEMA = D.BSCHEMA AND T.TABNAME = D.BNAME AND D.DTYPE = '7')
                        ,'00DUMMY00'
                    ) AS SYN_TABNAME
        FROM
            SYSCAT.TABLES  T
        JOIN   
            TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
        ON  T.TYPE IN ('T','S')
        AND NOT (T.TABSCHEMA = 'SYSIBM' AND SUBSTR(T.PROPERTY,21,1) = 'Y')  
        AND I.TABSCHEMA = T.TABSCHEMA
        AND I.TABNAME   = T.TABNAME
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
    )
        T
) T
@

/*
 * Returns a simplistic estimate of how the size of each table compares to what you might expect given the column encoding rates
 * 
 * In otherwords, this view can help spot tables that have had many random UPDATEs or DELETEs 
 *    where extents of pages can't be reclaimed as not *all* rows in those extents have been deleted
 * It is very much only an estimate, and for various reasons is not particually accurate.
 * Still it can be a usefull, quick indication of tables that might benifit from re-building or reinserting.
 * 
 * Very loosly based on detectSparseBluTables.sh  from https://www.ibm.com/support/pages/node/305221
 * 
 */
   
CREATE OR REPLACE VIEW DB_TABLE_QUICK_SPARSITY AS
SELECT
    ROW_NUMBER() OVER( ORDER BY COL_SIZE_GB - EST_MEM_SIZE_GB DESC NULLS LAST)  AS RANK
,   QUANTIZE( ( ( COL_SIZE_GB - EST_MEM_SIZE_GB ) / COL_SIZE_GB ) * 100, 0.1 ) AS SPARSE_PCT
,   COL_SIZE_GB - EST_MEM_SIZE_GB       AS DELTA_GB  
,   *
FROM
(   SELECT
        T.TABSCHEMA
    ,   T.TABNAME
    ,   QUANTIZE( ( AVGENCODEDCOLLEN * CARD ) / POWER(2,30) ,.00)     AS EST_MEM_SIZE_GB
    ,   QUANTIZE( ( COALESCE(COL_OBJECT_L_PAGES, T.FPAGES)* TS.PAGESIZE::DECFLOAT) / POWER(2,30),.00)  AS COL_SIZE_GB
    ,   QUANTIZE(AVGENCODEDCOLLEN,0)            AS EST_MEM_BYTES
    ,   RAW_LEN_BYTES 
    ,   ROWS_DELETED
    ,   QUANTIZE(  COALESCE(COL_OBJECT_L_PAGES, T.FPAGES)* TS.PAGESIZE::DECFLOAT / DECFLOAT(NULLIF(CARD,0)),0) AS BYTES_PER_ROW
    ,   T.NPAGES
    ,   T.FPAGES
    ,   T.PCTPAGESSAVED
    ,   AVG_PCTENCODED
    ,   MIN_PCTENCODED
    ,   T.CARD
    --    ,   DECIMAL((1 - DECFLOAT(NULLIF(ST.AVG_TABLE_BYTES,0))/ NULLIF(ST.MAX_TABLE_BYTES,0))*100,5,2)     AS SKEW
    --,   RECLAIMABLE_SPACE*1000 as RECLAIMABLE
    FROM
        SYSCAT.TABLES  T
    JOIN
    (   SELECT
            TABSCHEMA
        ,   TABNAME
        ,   DECIMAL(SUM(CASE WHEN TYPENAME NOT IN ('CLOB','LOB','DBCLOB') THEN AVGENCODEDCOLLEN END),9,3) AS AVGENCODEDCOLLEN -- Ignore spurious values for LOBs. They are not encoded in BLU.
        ,   DECIMAL(SUM(CASE WHEN AVGCOLLEN > 0 THEN AVGCOLLEN ELSE LENGTH END)) AS RAW_LEN_BYTES
        ,   AVG(PCTENCODED)         AS AVG_PCTENCODED
        ,   MIN(PCTENCODED)         AS MIN_PCTENCODED
        FROM
            SYSCAT.COLUMNS C
        WHERE
            AVGENCODEDCOLLEN > 0
        GROUP BY
            C.TABSCHEMA
        ,   C.TABNAME
    )
        USING ( TABSCHEMA, TABNAME )
    LEFT OUTER JOIN
            SYSCAT.TABLESPACES              TS
    ON
        T.TBSPACEID = TS.TBSPACEID      
    LEFT JOIN
    (   SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   SUM(M.COL_OBJECT_L_PAGES)   AS COL_OBJECT_L_PAGES
        ,   SUM(ROWS_DELETED)           AS ROWS_DELETED
        FROM
            SYSCAT.TABLES  T
        ,   TABLE(MON_GET_TABLE(T.TABSCHEMA, T.TABNAME, -2)) M
        WHERE
            T.TABSCHEMA = M.TABSCHEMA
        AND T.TABNAME   = M.TABNAME
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
    ) M
        USING ( TABSCHEMA, TABNAME )
WHERE
    TABSCHEMA NOT LIKE 'SYS%'
AND T.TYPE IN ('T','S')
)

@

/*
 * Shows the data skew of database partitioned tables. Only shows data for tables touched since the last Db2 restart
 */

CREATE OR REPLACE VIEW DB_TABLE_QUICK_SKEW AS
SELECT
    TABSCHEMA
,   TABNAME
,   M.MAX_TABLE_BYTES / (1024*1024) AS MAX_TABLE_MB
,   M.MIN_TABLE_BYTES / (1024*1024) AS MIN_TABLE_MB
,   DECIMAL((((MAX_TABLE_BYTES - AVG_TABLE_BYTES) * MEMBERS) / (1024*1024)),17,3) AS WASTED_MB
,   M.SKEW
,   M.LARGEST_MEMBER
--,   TBSPACE
--,   D.DISTRIBUTION_KEY
--,   T.CARD
--,   T.PCTPAGESSAVED                                     AS PCT_COMPRESSED
--,   D.MAX_DIST_COLCARD
--,   T.OWNER
--,   T.LASTUSED
--,   T.CREATE_TIME
FROM
(   SELECT  
        TABSCHEMA
    ,   TABNAME
    ,   COUNT(*)                                            AS MEMBERS
    ,   MAX(TABLE_BYTES)                                    AS MAX_TABLE_BYTES
    ,   MIN(TABLE_BYTES)                                    AS MIN_TABLE_BYTES
    ,   MAX(TABLE_BYTES) - AVG(TABLE_BYTES)::BIGINT         AS SKEWED_BYTES
    ,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(TABLE_BYTES)),0)/ NULLIF(MAX(DECFLOAT(TABLE_BYTES)),0))*100,5,2) END    AS SKEW
    ,   MAX(CASE WHEN MEMBER_ASC_RANK  = 1 THEN MEMBER END) AS SMALLEST_MEMBER
    ,   MAX(CASE WHEN MEMBER_DESC_RANK = 1 THEN MEMBER END) AS LARGEST_MEMBER
    ,   AVG(TABLE_BYTES)                                    AS AVG_TABLE_BYTES
    ,   SUM(TABLE_BYTES)                                    AS SUM_TABLE_BYTES
    ,   MAX(INDEX_BYTES)                                    AS MAX_INDEX_BYTES
    ,   MIN(INDEX_BYTES)                                    AS MIN_INDEX_BYTES
    FROM
    (   SELECT 
            TABSCHEMA
        ,   TABNAME
        ,   MEMBER
        ,   SUM(TABLE_OBJECT_L_BYTES)                 AS TABLE_BYTES
        ,   SUM(INDEX_OBJECT_L_BYTES)                 AS INDEX_BYTES
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(TABLE_OBJECT_L_BYTES) ASC)  AS MEMBER_ASC_RANK
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(TABLE_OBJECT_L_BYTES) DESC) AS MEMBER_DESC_RANK
        FROM   
        (
            SELECT  
                M.*
            , ( COALESCE( DATA_OBJECT_L_PAGES,0)
              + COALESCE(  COL_OBJECT_L_PAGES,0)
              + COALESCE( LONG_OBJECT_L_PAGES,0)
              + COALESCE(  LOB_OBJECT_L_PAGES,0)
              + COALESCE(  XDA_OBJECT_L_PAGES,0)) * TS.PAGESIZE  AS TABLE_OBJECT_L_BYTES
            --
            ,   COALESCE(INDEX_OBJECT_L_PAGES,0)  * TS.PAGESIZE  AS INDEX_OBJECT_L_BYTES 
            FROM
                TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS M
            INNER JOIN
                SYSCAT.TABLESPACES TS ON M.TBSP_ID = TS.TBSPACEID
        ) M
        GROUP BY
                TABSCHEMA
        ,       TABNAME
        ,       MEMBER
        ) M
    GROUP BY
            TABSCHEMA
    ,       TABNAME
) M

@

/*
 * Returns the size of each table. For tables not touched since the last Db2 restart, the size is an estimate based on catalog statistics
 */

CREATE OR REPLACE VIEW DB_TABLE_QUICK_SIZE AS
WITH MON AS
(   SELECT  
        TABSCHEMA
    ,   TABNAME
    ,   COUNT(*)                                            AS MEMBERS
    ,   SUM(TABLE_BYTES)                                    AS TABLE_BYTES
    ,   SUM(INDEX_BYTES)                                    AS INDEX_BYTES
    ,   MAX(TABLE_BYTES)                                    AS MAX_TABLE_BYTES
    ,   AVG(TABLE_BYTES)                                    AS AVG_TABLE_BYTES
    FROM
    (   SELECT 
            TABSCHEMA
        ,   TABNAME
        ,   MEMBER
        ,   SUM(TABLE_OBJECT_L_BYTES)                 AS TABLE_BYTES
        ,   SUM(INDEX_OBJECT_L_BYTES)                 AS INDEX_BYTES
--        ,   SUM(ROWS_READ)                            AS ROWS_READ
--        ,   SUM(ROWS_INSERTED)                        AS ROWS_INSERTED
--        ,   SUM(ROWS_UPDATED)                         AS ROWS_UPDATED
--        ,   SUM(ROWS_DELETED)                         AS ROWS_DELETED
        FROM   
        (
            SELECT  
                M.*
            , ( COALESCE( DATA_OBJECT_L_PAGES,0)
              + COALESCE(  COL_OBJECT_L_PAGES,0)
              + COALESCE( LONG_OBJECT_L_PAGES,0)
              + COALESCE(  LOB_OBJECT_L_PAGES,0)
              + COALESCE(  XDA_OBJECT_L_PAGES,0)) * TS.PAGESIZE  AS TABLE_OBJECT_L_BYTES
            --
            ,   COALESCE(INDEX_OBJECT_L_PAGES,0)  * TS.PAGESIZE  AS INDEX_OBJECT_L_BYTES 
            FROM
                TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS M
            INNER JOIN
                SYSCAT.TABLESPACES TS ON M.TBSP_ID = TS.TBSPACEID
        ) M
        GROUP BY
                TABSCHEMA
        ,       TABNAME
        ,       MEMBER
        ) ST
    GROUP BY
            TABSCHEMA
    ,       TABNAME
)
SELECT
    SMALLINT(RANK() OVER(ORDER BY COALESCE(ST.TABLE_BYTES, T.NPAGES      * TS.PAGESIZE) DESC NULLS LAST)) AS RANK
,   RTRIM(T.TABSCHEMA)                                  AS TABSCHEMA
,   T.TABNAME
,   T.COLCOUNT                                          AS COLS
,   T.CARD                                                              AS CARD
--,   T.OWNER                                             AS OWNER
--,   T.TBSPACE                                           AS TBSPACE
,   CASE WHEN ST.TABLE_BYTES IS NOT NULL THEN 'L_PAGES' ELSE 'STATS' END                            AS SIZE_SOURCE
,   INTEGER( ROUND((COALESCE(ST.TABLE_BYTES, T.NPAGES      * TS.PAGESIZE)) / DECFLOAT(1048576)))    AS DATA_MB
,   INTEGER( ROUND((COALESCE(ST.INDEX_BYTES, IS.INDEX_PAGES * TS.PAGESIZE)) / DECFLOAT(1048576)))   AS INDEX_MB
,   COALESCE(INTEGER( ROUND(S.TABLE_BYTES / DECFLOAT(1048576))),0)                                  AS SYN_MB
,   DECIMAL((S.TABLE_BYTES / DECFLOAT(ST.TABLE_BYTES))*100,7,2)                                     AS SYN_PCT
,   DECIMAL((1 - DECFLOAT(NULLIF(ST.AVG_TABLE_BYTES,0))/ NULLIF(ST.MAX_TABLE_BYTES,0))*100,5,2)     AS SKEW
,   QUANTIZE((COALESCE(ST.TABLE_BYTES, T.NPAGES      * TS.PAGESIZE) / DECFLOAT(NULLIF(CARD,0))),0.01)     AS BYTES_PER_ROW
,   QUANTIZE(MEM_LEN,0.01)                                                                          AS MEM_LEN
,   T.PCTPAGESSAVED
,   RTRIM(DECIMAL(100/NULLIF(DECFLOAT(100)-NULLIF(PCTPAGESSAVED,-1),0),5,2)) || ':1'                AS RATIO
,   C.AVG_PCTENCODED                                                                                AS PCTENCODED
,   C.AVG_ENCODED_LEN_BYTES                                                                         AS AVGENCODEDLEN
,   CASE T.TABLEORG WHEN 'C' THEN 'COLUMN' WHEN 'R' THEN 'ROW' END      AS TABLE_ORG
,   T.STATS_TIME
,   T.LASTUSED                                                          AS LAST_USED_DATE
,   DATE(T.CREATE_TIME)                                                 AS CREATE_DATE
--,   COALESCE(ST.ROWS_READ,-1)                           AS ROWS_READ
--,   COALESCE(ST.ROWS_INSERTED,-1)                       AS ROWS_INSERTED
--,   COALESCE(ST.ROWS_UPDATED,-1)                        AS ROWS_UPDATED
--,   COALESCE(ST.ROWS_DELETED,-1)                        AS ROWS_DELETED
FROM    SYSCAT.TABLES                   T
JOIN    (
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   SUM(CASE WHEN AVGENCODEDCOLLEN >= 0 THEN AVGENCODEDCOLLEN END)              AS MEM_LEN 
    ,   DECIMAL(AVG(PCTENCODED),5,2)       AS AVG_PCTENCODED 
    ,   DECIMAL(AVG(CASE WHEN TYPENAME NOT IN ('CLOB','LOB','DBCLOB') THEN AVGENCODEDCOLLEN END),9,3) AS AVG_ENCODED_LEN_BYTES -- Ignore spurious values for LOBs. They are not encoded in BLU.
    FROM
        SYSCAT.COLUMNS              
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ) AS C
ON  
     T.TABSCHEMA = C.TABSCHEMA
AND  T.TABNAME   = C.TABNAME      
LEFT OUTER JOIN
        SYSCAT.TABLESPACES              TS
ON
    T.TBSPACEID = TS.TBSPACEID      
LEFT OUTER JOIN
        MON           ST
ON      
    T.TABSCHEMA = ST.TABSCHEMA
AND T.TABNAME   = ST.TABNAME
LEFT OUTER JOIN
    SYSCAT.TABDEP   SD
ON
    T.TABSCHEMA = SD.BSCHEMA
AND T.TABNAME   = SD.BNAME
AND               SD.DTYPE = '7'
LEFT OUTER JOIN
    MON           S --Synonpsis tables
ON
    SD.TABSCHEMA = S.TABSCHEMA
AND SD.TABNAME   = S.TABNAME
LEFT OUTER JOIN
        (SELECT 
                TABSCHEMA
        ,       TABNAME
        ,       SUM(NLEAF) * 1.3                        AS INDEX_PAGES
        FROM    SYSCAT.INDEXES
        WHERE
                NLEAF >= 0
        GROUP BY
                TABSCHEMA
        ,       TABNAME
        )
            IS
ON      T.TABSCHEMA = IS.TABSCHEMA
AND     T.TABNAME   = IS.TABNAME
WHERE
        T.TYPE      NOT IN ('A','N','V','W')
AND NOT (T.TABSCHEMA = 'SYSIBM' AND T.TABNAME LIKE 'SYN%')
@

/*
 * Generates quick DDL for tables. Provided AS-IS. It is accurate for most simple tables. Does not include FKs, generated column expression or support range partitioned and MDC tables or other complex DDL structure
 */

CREATE OR REPLACE VIEW DB_TABLE_QUICK_DDL AS
/*
Simple DDL generator for DB2

Many things are not supported. Use db2look, IBM Data Studio or some other method for more complete DDL support.

Notable exclusions include
   Foreign Keys
   Unique Keys
   (full support of) Identity columns
   MDC
   Range Partitioning
   etc

If your table DDL will end up being more than 32 thousand bytes, the DDL will be split over more than 1 row. 
  This is to avoid the length of the generate DDL breaking the max length of a VARCHAR used by LISTAGG 

*/
WITH T AS (
          SELECT CASE WHEN TRANSLATE(TABSCHEMA,'','ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_') = '' 
                           THEN RTRIM(TABSCHEMA)
               ELSE '"' || RTRIM(TABSCHEMA) || '"' END AS SCHEMA
  ,       CASE WHEN TRANSLATE(TABNAME,'','ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_') = '' 
               THEN TABNAME
               ELSE '"' || RTRIM(TABNAME) || '"' END AS TABLE 
  ,       T.*
  ,       CASE TYPE WHEN 'G' THEN VARCHAR('CREATE GLOBAL TEMPORARY TABLE ')
                    WHEN 'A' THEN 'CREATE OR REPLACE ALAIS '
                    WHEN 'N' THEN 'CREATE OR REPLACE NICKNAME '
                             ELSE 'CREATE TABLE '
                    END AS CREATE
  FROM
        SYSCAT.TABLES  T
  WHERE   TYPE NOT IN ('V')
  )
  , C AS (
  SELECT
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
      ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS))
                  || CASE WHEN COL_SEQ > 0 THEN VARCHAR(CHR(10) || ',   ') ELSE '    ' END 
                  || '"' || COLNAME || '"'
                  || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
                  || DATATYPE_DDL
                  || GENERATED_DDL
                  || CASE WHEN DEFAULT_VALUE_DDL <> '' THEN ' ' || DEFAULT_VALUE_DDL ELSE '' END 
                  || CASE WHEN OTHER_DDL         <> '' THEN ' ' || OTHER_DDL         ELSE '' END 
                  ) WITHIN GROUP (ORDER BY COLNO) AS COLUMNS
      FROM
          (SELECT C.*
           ,    SUM(50 + LENGTH(DATATYPE_DDL) + LENGTH(DEFAULT_VALUE_DDL) + LENGTH(OTHER_DDL))
                     OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
           FROM
           (
                SELECT
                    TABSCHEMA
                ,   TABNAME
                ,   COLNAME
                ,   COLNO
                ,   CASE
                        WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                        THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END
                             || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                             || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
                        WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                        THEN TYPENAME || '(' || LENGTH || ')'  
                        WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                        THEN TYPENAME
                        WHEN TYPENAME IN ('TIMESTAMP')
                        THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                        WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                        THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                        WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                        THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                        WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                        ELSE TYPENAME END 
                    || CASE WHEN INLINE_LENGTH <> 0 THEN ' INLINE LENGTH ' || INLINE_LENGTH ELSE '' END
                    || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
                ,   CASE WHEN DEFAULT IS NOT NULL THEN ' DEFAULT ' || DEFAULT ELSE '' END        AS DEFAULT_VALUE_DDL 
                ,   CASE WHEN HIDDEN = 'I' THEN 'IMPLICITLY HIDDEN ' ELSE '' END                 AS OTHER_DDL
                ,   ROW_NUMBER() OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) - 1        AS COL_SEQ
                ,   CASE WHEN GENERATED <> '' THEN  ' GENERATED' 
                    || CASE GENERATED WHEN 'A' THEN ' ALWAYS' WHEN 'D' THEN ' BY DEFUALT' ELSE '' END
                    || ' AS ' || CASE WHEN IDENTITY = 'Y' THEN 'IDENTITY' WHEN ROWBEGIN = 'Y' THEN 'ROW BEGIN' WHEN ROWEND = 'Y' THEN 'ROW END'
                              WHEN TRANSACTIONSTARTID = 'Y' THEN 'TRANSACTION START ID' ELSE VARCHAR(TEXT,1000) END 
                    ELSE '' END   AS GENERATED_DDL
                FROM
                    SYSCAT.COLUMNS
                WHERE
                    NOT (RANDDISTKEY = 'Y' AND HIDDEN = 'I') -- Don't generate DDL for hidden RANDOM_DISTRIBUTION_KEY columns
           ) C
          )
      GROUP BY
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000
  ) 
  SELECT
      T.TABSCHEMA
  ,   T.TABNAME
  ,   C.DDL_SPLIT_SEQ + 1                   AS DDL_LINE_NO
  ,   CASE WHEN DDL_SPLIT_SEQ = 0 THEN      -- Top 
           CREATE ||  SCHEMA || '.' || TABLE || CHR(10) || '(' || CHR(10) ELSE '' 
      END
      || COLUMNS || CHR(10)                 -- Middle
      || CASE WHEN DDL_SPLIT_SEQ = MAX(DDL_SPLIT_SEQ) OVER( PARTITION BY T.TABSCHEMA, T.TABNAME)
         THEN
                CASE WHEN T.TEMPORALTYPE IN ('A','B') OR SUBSTR(T.PROPERTY,29,1) = 'Y' THEN COALESCE(',   PERIOD BUSINESS_TIME ("' || BT.BEGINCOLNAME || '", "' || BT.ENDCOLNAME || '")' || CHR(10),'') ELSE '' END
             || CASE WHEN T.TEMPORALTYPE IN ('S','B') OR SUBSTR(T.PROPERTY,29,1) = 'Y' THEN COALESCE(',   PERIOD SYSTEM_TIME ("'   || ST.BEGINCOLNAME || '", "' || ST.ENDCOLNAME || '")' || CHR(10),'') ELSE '' END
             || CASE WHEN                                SUBSTR(T.PROPERTY,29,1) = 'Y' THEN 'MAINTAINED BY USER' || CHR(10) ELSE '' END
             || CASE WHEN PK.TYPE = 'P' 
             THEN ',   '
                  || CASE WHEN PK.CONSTNAME NOT LIKE 'SQL%' THEN 'CONSTRAINT ' || PK.CONSTNAME ELSE '' END
                  || ' PRIMARY KEY ( ' || PK_COLS 
                  || COALESCE(', ' || PK.PERIODNAME || CASE PK.PERIODPOLICY WHEN 'O' THEN ' WITHOUT OVERLAPS' ELSE '' END,'') || ' )'
                  || CASE WHEN PK.ENFORCED = 'N' THEN ' NOT ENFORCED' ELSE ' ENFORCED' END
                  || CASE PK.ENABLEQUERYOPT WHEN 'N' THEN ' DISABLE QUERY OPTIMIZATION' ELSE '' END                  
                  || CHR(10)  
             ELSE ''
             END
             || ')' || CHR(10)
             || CASE WHEN T.TABLEORG = 'C' THEN 'ORGANIZE BY COLUMN ' || CHR(10)  
                     WHEN T.TABLEORG = 'R' THEN 'ORGANIZE BY ROW '    || CHR(10)  ELSE '' END
             || CASE WHEN D.RANDDISTKEY = 'Y'      THEN 'DISTRIBUTE BY RANDOM' || CHR(10)
                     WHEN D.DISTRIBUTION_KEY <> '' THEN 'DISTRIBUTE BY (' || DISTRIBUTION_KEY || ')' || CHR(10) 
                ELSE ''  END
             || CASE WHEN T.TBSPACE IS NOT NULL THEN 'IN "' || T.TBSPACE || '"' || CHR(10)  ELSE '' END
         ELSE '' END
        AS DDL
  FROM
      T
  JOIN 
      C
  ON
      T.TABSCHEMA = C.TABSCHEMA AND T.TABNAME = C.TABNAME
  LEFT OUTER JOIN
      SYSCAT.TABCONST PK
  ON
     PK.TABSCHEMA = T.TABSCHEMA AND PK.TABNAME = T.TABNAME AND PK.TYPE = 'P'
  LEFT OUTER JOIN
(   SELECT
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
    ,   LISTAGG('"' || K.COLNAME || '"',', ') WITHIN GROUP (ORDER BY K.COLSEQ)   AS PK_COLS
    FROM
        SYSCAT.KEYCOLUSE K
    LEFT JOIN -- exclude period columns from the column list
        SYSCAT.PERIODS  B1 ON K.TABSCHEMA = B1.TABSCHEMA AND K.TABNAME = B1.TABNAME AND K.COLNAME = B1.BEGINCOLNAME AND B1.PERIODNAME = 'BUSINESS_TIME'
    LEFT JOIN
        SYSCAT.PERIODS  B2 ON K.TABSCHEMA = B2.TABSCHEMA AND K.TABNAME = B2.TABNAME AND K.COLNAME = B2.ENDCOLNAME   AND B2.PERIODNAME = 'BUSINESS_TIME'
    WHERE
        B1.TABNAME IS NULL
    AND B2.TABNAME IS NULL
    GROUP BY
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
) K
  ON
     PK.TABSCHEMA = K.TABSCHEMA AND PK.TABNAME = K.TABNAME AND PK.CONSTNAME = K.CONSTNAME
LEFT OUTER JOIN
(	
	SELECT
	    TABSCHEMA
	,   TABNAME
	,   SUBSTR(LISTAGG(CASE WHEN PARTKEYSEQ > 0 THEN ', "' || COLNAME || '"' ELSE '' END) WITHIN GROUP (ORDER BY PARTKEYSEQ ),3) AS DISTRIBUTION_KEY
	,   MAX(RANDDISTKEY)    AS RANDDISTKEY
	FROM
	    SYSCAT.COLUMNS
	GROUP BY
	    TABSCHEMA 
	,   TABNAME
) D
ON
    T.TABSCHEMA = D.TABSCHEMA AND T.TABNAME = D.TABNAME
LEFT JOIN
    SYSCAT.PERIODS  BT 
ON
    T.TABSCHEMA = BT.TABSCHEMA AND T.TABNAME = BT.TABNAME AND BT.PERIODNAME = 'BUSINESS_TIME'
LEFT JOIN
    SYSCAT.PERIODS  ST 
ON
    T.TABSCHEMA = ST.TABSCHEMA AND T.TABNAME = ST.TABNAME AND ST.PERIODNAME = 'SYSTEM_TIME'

@

/*
 * Provide a (possibly inaccurate) estimate of when a table might have last been updated
 */

CREATE OR REPLACE VIEW DB_TABLE_LAST_UPDATED_ESTIMATE AS
SELECT
    TABSCHEMA
,   TABNAME
,   CASE WHEN STATS_ROWS_MODIFIED = 0 THEN STATS_TIME::DATE     -- Use last stats time if not IUD since that time
         WHEN M.TABNAME IS NULL                                 -- Use last Db2 start time if no monitering data
         OR (STATS_ROWS_MODIFIED = 0 AND ROWS_INSERTED = 0 AND ROWS_UPDATED = 0 AND ROWS_DELETED = 0)  -- or if no IUDs since last restart
         THEN (SELECT MIN(DB2START_TIME)::DATE FROM TABLE(MON_GET_INSTANCE(-2)))
         ELSE NULL
        END             AS LAST_UPDATED_DATE
,   STATS_ROWS_MODIFIED
,   ROWS_INSERTED
,   ROWS_UPDATED
,   ROWS_DELETED 
FROM
    SYSCAT.TABLES
LEFT JOIN (
    SELECT 
        TABSCHEMA
    ,   TABNAME
    ,   SUM(NULLIF(STATS_ROWS_MODIFIED,POWER(2::BIGINT,32)-1)) AS STATS_ROWS_MODIFIED
    ,   SUM(ROWS_INSERTED)       AS ROWS_INSERTED
    ,   SUM(ROWS_UPDATED )       AS ROWS_UPDATED
    ,   SUM(ROWS_DELETED )       AS ROWS_DELETED
   FROM
        TABLE(MON_GET_TABLE(NULL, NULL, -2))
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ) M USING ( TABSCHEMA, TABNAME )
WHERE TYPE = 'T'

@

/*
 * Lists all table functions, and generates SQL to select from them
 */

CREATE OR REPLACE VIEW DB_TABLE_FUNCTIONS AS
SELECT
    ROUTINESCHEMA       AS TABSCHEMA
,   ROUTINEMODULENAME
,   ROUTINENAME         AS TABNAME
,   SPECIFICNAME
,   'SELECT *'||                                 ' FROM TABLE( ' ||  R.ROUTINENAME || ' (' || COALESCE(PARMS,'') || '))s' AS SELECT_STAR_STMT
,   'SELECT ' || COALESCE(COLS,'*') || CHR(10) || 'FROM TABLE( ' ||  R.ROUTINENAME || ' (' || COALESCE(PARMS,'') || '))s' AS SELECT_COLS_STMT
FROM
    SYSCAT.ROUTINES R
LEFT JOIN
(   SELECT
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
    ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS)) 
              || COALESCE(
                LOWER(RTRIM(PARMNAME)) || ' =>' || CASE WHEN PARMNAME IN ('DBPARTITIONNUM') THEN ' -2' ELSE ' DEFAULT' END
            ,':'||TRIM(P.ORDINAL))
            ,', ') WITHIN GROUP ( ORDER BY P.ORDINAL)  AS PARMS
    FROM
        SYSCAT.ROUTINEPARMS P
    WHERE
        P.ROWTYPE IN ('B','O','P')
    GROUP BY
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
) P
    USING
    ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
LEFT JOIN
(   SELECT
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
    ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS)) || PARMNAME,' ,') WITHIN GROUP ( ORDER BY P.ORDINAL)  AS COLS
    FROM
        SYSCAT.ROUTINEPARMS P
    WHERE
        P.ROWTYPE IN ('R','C','S')
    AND P.PARMNAME IS NOT NULL
    GROUP BY
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
) P
    USING
    ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
WHERE
    R.ROUTINETYPE = 'F'
AND R.ORIGIN IN ('Q','E')
--AND R.ROUTINESCHEMA = 'SYSPROC'
--AND R.ROUTINENAME NOT LIKE '%\_V97%' ESCAPE '\'
--AND R.ROUTINENAME NOT LIKE '%\_V91%' ESCAPE '\'
--AND R.ROUTINENAME NOT LIKE 'HEALTH_'
--AND SUBSTR(R.ROUTINENAME,1,5) <> 'SNAP_'

@

/*
 * Lists all table function columns in the database
 */

CREATE OR REPLACE VIEW DB_TABLE_FUNCTION_COLUMNS AS
SELECT
    ROUTINESCHEMA       AS TABSCHEMA
,   ROUTINEMODULENAME
,   ROUTINENAME         AS TABNAME
,   SPECIFICNAME
,   ROWTYPE
,   PARMNAME            AS COLNAME
,   ORDINAL             AS COLNO
,   LENGTH
,   STRINGUNITSLENGTH
,   SCALE 
,   REMARKS
FROM
    SYSCAT.ROUTINEPARMS P
WHERE
    P.ROWTYPE IN ('R','C','S')
AND P.PARMNAME IS NOT NULL

@

/*
 * Table activity metrics such as rows read and number of table scans
 */

CREATE OR REPLACE VIEW DB_TABLE_ACTIVITY AS
SELECT
    TABSCHEMA
,   TABNAME    
,   SUM(ROWS_READ)        AS ROWS_READ    
,   SUM(ROWS_INSERTED)    AS ROWS_INSERTED
,   SUM(ROWS_UPDATED)     AS ROWS_UPDATED 
,   SUM(ROWS_DELETED)     AS ROWS_DELETED 
--               With the skew calc below skip the catalog partition and MLN number 1 as that is (usually) where runstats runs
,   DECIMAL((1 - DECFLOAT(NULLIF(AVG(CASE WHEN MEMBER > 1 THEN ROWS_READ     END),0))/ NULLIF(MAX(CASE WHEN MEMBER > 1 THEN ROWS_READ     END),0))*100,5,2) AS ROWS_READ_SKEW
,   DECIMAL((1 - DECFLOAT(NULLIF(AVG(CASE WHEN MEMBER > 1 THEN ROWS_INSERTED END),0))/ NULLIF(MAX(CASE WHEN MEMBER > 1 THEN ROWS_INSERTED END),0))*100,5,2) AS ROWS_INSERTED_SKEW
,   DECIMAL((1 - DECFLOAT(NULLIF(AVG(CASE WHEN MEMBER > 1 THEN ROWS_UPDATED  END),0))/ NULLIF(MAX(CASE WHEN MEMBER > 1 THEN ROWS_UPDATED  END),0))*100,5,2) AS ROWS_UPDATED_SKEW
,   DECIMAL((1 - DECFLOAT(NULLIF(AVG(CASE WHEN MEMBER > 1 THEN ROWS_DELETED  END),0))/ NULLIF(MAX(CASE WHEN MEMBER > 1 THEN ROWS_READ     END),0))*100,5,2) AS ROWS_DELETED_SKEW
,   MAX(CASE WHEN ROWS_READ_RANK = 1 THEN MEMBER END) AS TOP_ROWS_READ_MEMBER
,   SUM(OBJECT_DATA_P_READS + OBJECT_COL_P_READS + OBJECT_XDA_P_READS) AS OBJECT_P_READS
,   SUM(OBJECT_DATA_L_READS + OBJECT_COL_L_READS + OBJECT_XDA_L_READS) AS OBJECT_L_READS
,   DECIMAL(ROUND(100*( 1- ( SUM(OBJECT_DATA_P_READS + OBJECT_COL_P_READS + OBJECT_XDA_P_READS) / NULLIF(SUM(OBJECT_DATA_L_READS + OBJECT_COL_L_READS + OBJECT_XDA_L_READS),0)::DECFLOAT)),2),5,2) AS HIT_RATIO
,   ROUND(SUM(NUM_COLUMNS_REFERENCED) / SUM(SECTION_EXEC_WITH_COL_REFERENCES)::DECFLOAT) AVG_COLUMNS_REFERENCED
,   MAX(TABLE_SCANS)            AS TABLE_SCANS
,   MAX(NUM_COLUMNS_REFERENCED) AS NUM_COLUMNS_REFERENCED
FROM
(
    SELECT *
    ,   ROW_NUMBER() OVER(PARTITION BY TABSCHEMA,   TABNAME ORDER BY ROWS_READ DESC) AS ROWS_READ_RANK
    FROM
        TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS T
    WHERE
        TAB_TYPE <> 'EXTERNAL_TABLE'
    )
GROUP BY
    TABSCHEMA
,   TABNAME

@

/*
 * Shows the Synopsis table name for each column organized table
 */

CREATE OR REPLACE VIEW DB_SYNOPSIS_TABLES AS 
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   D.TABSCHEMA     AS SCHEMA
,   D.TABNAME       AS SYNOPSIS_TABNAME
FROM
    SYSCAT.TABLES   T
INNER JOIN
    SYSCAT.TABDEP   D
ON
    T.TABSCHEMA = D.BSCHEMA
AND T.TABNAME   = D.BNAME
AND               D.DTYPE = '7'
--INNER JOIN
--    SYSCAT.TABLES  S
--ON
--    D.TABSCHEMA = S.TABSCHEMA
--AND D.TABNAME   = S.TABNAME
@

/*
 * Shows the size of each Synopsis table created for each Column Organized Table
 */

CREATE OR REPLACE VIEW DB_SYNOPSIS_SIZE AS
SELECT
     T.TABSCHEMA
,    T.TABNAME
,    DATA_L_KB
,    SYN_L_KB
,    BIGINT(((MIN(1012, (COLCOUNT * 2) + 2 )) * EXTENTSIZE * DATASLICES * PAGESIZE ::BIGINT * 4 /* assume 4 insert ranges */ ) /1024) AS MIN_SYN_KB
,    COLCOUNT
,    EXTENTSIZE
,    DATASLICES
,    PAGESIZE
,    CARD
,    PCTPAGESSAVED
,    DATA_P_KB
,    SYN_P_KB
,    INDEX_L_KB
,    INDEX_P_KB
,    TBSPACE
,    SYN_TABNAME
FROM
(
    SELECT
        T.*
    ,   COALESCE(   -- Get Synopsis logical table size for BLU tables
            (SELECT SUM(DATA_OBJECT_L_SIZE + INDEX_OBJECT_L_SIZE + LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE)
                FROM
                    TABLE(ADMIN_GET_TAB_INFO(T.SYN_TABSCHEMA, T.SYN_TABNAME)) S
                WHERE
                    S.TABSCHEMA = T.SYN_TABSCHEMA
                AND S.TABNAME   = T.SYN_TABNAME
                AND T.TABLEORG = 'C'
        ),0) AS SYN_L_KB
    ,   COALESCE(   -- Get Synopsis physical table size for BLU tables
            (SELECT SUM(DATA_OBJECT_P_SIZE + INDEX_OBJECT_P_SIZE + LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE)
                FROM
                    TABLE(ADMIN_GET_TAB_INFO(T.SYN_TABSCHEMA, T.SYN_TABNAME)) S
                WHERE
                    S.TABSCHEMA = T.SYN_TABSCHEMA
                AND S.TABNAME   = T.SYN_TABNAME
                AND T.TABLEORG = 'C'
        ),0) AS SYN_P_KB
        FROM
    (
        SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   MAX(T.COLCOUNT) AS COLCOUNT
        ,   MAX(T.CARD)     AS CARD
        ,   MAX(T.PCTPAGESSAVED)  AS PCTPAGESSAVED
        ,   MAX(T.TBSPACE)  AS TBSPACE
        ,   MAX(T.TABLEORG) AS TABLEORG
        ,   COUNT(DBPARTITIONNUM)   AS DATASLICES
        ,   SUM(DATA_OBJECT_L_SIZE +                       LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE) AS DATA_L_KB
        ,   SUM(                      INDEX_OBJECT_L_SIZE                                                                                ) AS INDEX_L_KB
        ,   SUM(DATA_OBJECT_P_SIZE +                       LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE) AS DATA_P_KB
        ,   SUM(                      INDEX_OBJECT_P_SIZE                                                                                ) AS INDEX_P_KB
        ,   SUM(RECLAIMABLE_SPACE)  AS RECLAIMABLE_KB
        ,   'SYSIBM'  AS SYN_TABSCHEMA
        ,   COALESCE(   (SELECT D.TABNAME FROM SYSCAT.TABDEP D WHERE T.TABSCHEMA = D.BSCHEMA AND T.TABNAME = D.BNAME AND D.DTYPE = '7')
                        ,'00DUMMY00'
                    ) AS SYN_TABNAME
        FROM
            SYSCAT.TABLES  T
        JOIN   
            TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
        ON  T.TYPE IN ('T','S')
        AND NOT (T.TABSCHEMA = 'SYSIBM' AND SUBSTR(T.PROPERTY,21,1) = 'Y')  
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
    )
        T
) T
JOIN SYSCAT.TABLESPACES USING (TBSPACE )

@

/*
 * Shows the total used and available size of the storage paths available to the database
 */

CREATE OR REPLACE VIEW DB_STORAGE AS
/*
 *  This view can't tell if the storage paths point to a shared or didicated filesystem for each database partition
 *   Currenly we just remove temp storage groups as a poot attempt to work-around that issue
 */
SELECT
    STORAGE_GROUP_NAME
,   DB_STORAGE_PATH
,   CASE WHEN DBPARTITIONNUM = 0 THEN 'NP' ELSE 'P' END PART
,   ROUND(SUM(FS_TOTAL_SIZE)       / power(1024.0,3),0)  AS SIZE_GB
,   ROUND(SUM(FS_USED_SIZE)        / power(1024.0,3),0)  AS USED_GB
,   ROUND(SUM(STO_PATH_FREE_SIZE)  / power(1024.0,3),0)  AS FREE_GB
,   ROUND((SUM(FS_USED_SIZE) / SUM(FS_TOTAL_SIZE)::DECFLOAT) * 100,2)  AS PCT_FULL
,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(FS_TOTAL_SIZE)),0)/ NULLIF(MAX(DECFLOAT(FS_TOTAL_SIZE)),0))*100,5,2) END   AS SIZE_SKEW
,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(FS_USED_SIZE )),0)/ NULLIF(MAX(DECFLOAT(FS_USED_SIZE )),0))*100,5,2) END   AS USED_SKEW
FROM TABLE(ADMIN_GET_STORAGE_PATHS(NULL,-2)) AS T
WHERE
    STORAGE_GROUP_NAME NOT LIKE '%TEMP%'
GROUP BY
    STORAGE_GROUP_NAME
,   DB_STORAGE_PATH
,   CASE WHEN DBPARTITIONNUM = 0 THEN 'NP' ELSE 'P' END

@

/*
 * Returns data from the package cache. Shows recently executed SQL statements
 */
    
CREATE OR REPLACE VIEW DB_STMT_CACHE AS
SELECT  
    MAX(STMT_TEXT::VARCHAR(32672 OCTETS)) AS STMT_TEXT
--,   COUNT(DISTINCT MEMBER)    AS SLICES
--,   TIMESTAMP(MAX(MAX_COORD_STMT_EXEC_TIMESTAMP),0) AS MAX_EXEC_TIMESTAMP
,   MAX(NUM_EXECUTIONS)              AS NUM_EXECS
,   MAX(QUERY_COST_ESTIMATE)         AS COST
,                    MAX(TOTAL_ACT_TIME)       / 1000.0                                              AS     ACTIVITY_SECS
,   DECIMAL(DECFLOAT(SUM(TOTAL_ACT_TIME))      / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_ACTIVITY_SECS
,                    MAX(TOTAL_ACT_WAIT_TIME)  / 1000.0                                              AS     WAIT_SECS
,   DECIMAL(DECFLOAT(SUM(TOTAL_ACT_WAIT_TIME)) / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_WAIT_SECS
,                    MAX(STMT_EXEC_TIME)       / 1000.0                                              AS     EXEC_SECS
,   DECIMAL(DECFLOAT(SUM(STMT_EXEC_TIME))      / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_EXEC_SECS
,                    MAX(TOTAL_CPU_TIME)       /1000.0                                               AS     CPU_SECS
,   DECIMAL(DECFLOAT(SUM(TOTAL_CPU_TIME))      / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_CPU_SECS
,   SUM(ROWS_READ    )              AS ROWS_READ    
,   SUM(ROWS_RETURNED)              AS ROWS_RETURNED
,   SUM(ROWS_MODIFIED)              AS ROWS_MODIFIED
,   SUM(ROWS_INSERTED)              AS ROWS_INSERTED
,   SUM(ROWS_UPDATED )              AS ROWS_UPDATED
,   SUM(ROWS_DELETED )              AS ROWS_DELETED
--,   (DIRECT_READS)         AS DIRECT_READS
--    , (DIRECT_WRITES)        AS DIRECT_WRITES
,   SUM(TOTAL_HASH_GRPBYS)                 AS HASH_GRPBYS
,   SUM(TOTAL_SORTS)                       AS SORTS
,   SUM(TOTAL_HASH_JOINS)                  AS HASH_JOINS
,                   MAX(TOTAL_SECTION_SORT_TIME) /1000.0                                               AS    SORT_SECS
--,    INT(total_col_vector_consumers)        AS VECTORS
--, SORT_CONSUMER_SHRHEAP_TOP 
--,SORT_HEAP_TOP SORT_SHRHEAP_TOP
--, EXT_TABLE_RECV_WAIT_TIME        --BIGINT  ext_table_recv_wait_time - Total agent wait time for external table readers monitor element
--, EXT_TABLE_RECVS_TOTAL           --BIGINT  ext_table_recvs_total - Total row batches received from external table readers monitor element
--, EXT_TABLE_RECV_VOLUME           --BIGINT  ext_table_recv_volume - Total data received from external table readers monitor element
--, EXT_TABLE_READ_VOLUME           --BIGINT  ext_table_read_volume - Total data read by external table readers monitor element
--, EXT_TABLE_SEND_WAIT_TIME        --BIGINT  ext_table_send_wait_time - Total agent wait time for external table writers monitor element
--, EXT_TABLE_SENDS_TOTAL           --BIGINT  ext_table_sends_total - Total row batches sent to external table writers monitor element
--, EXT_TABLE_SEND_VOLUME           --BIGINT  ext_table_send_volume - Total data sent to external table writers monitor element
--, EXT_TABLE_WRITE_VOLUME          
,   DECIMAL(ROUND(1.0 - DECIMAL(SUM(POOL_DATA_P_READS))/NULLIF(SUM(POOL_DATA_L_READS),0),4)*100,5,2)   AS DATA_HIT_PCT
,   DECIMAL(ROUND(1.0 - DECIMAL(SUM(POOL_INDEX_P_READS))/NULLIF(SUM(POOL_INDEX_L_READS),0),4)*100,5,2) AS INDEX_HIT_PCT
,   DECIMAL(ROUND(1.0 - (DECIMAL(SUM(POOL_TEMP_DATA_P_READS) +  SUM(POOL_TEMP_INDEX_P_READS))/NULLIF((SUM(POOL_TEMP_DATA_L_READS) + SUM(POOL_TEMP_INDEX_L_READS)),0)),4)*100,5,2) AS TEMP_HIT_PCT
,   MIN(INSERT_TIMESTAMP)::DATE      AS  STMT_CACHE_DATE
,   MIN(INSERT_TIMESTAMP)::TIME      AS  TIME
FROM
    TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) AS T
GROUP BY
    EXECUTABLE_ID

@

/*
 * Activation/quiesce status of database members. Shows if database is explicitly activated and last activation time
 */

CREATE OR REPLACE VIEW DB_STATUS AS
SELECT 
    DB_STATUS
,   DB_ACTIVATION_STATE
,   DB_CONN_TIME            AS DB_ACTIVATION_TIME
--,   LAST_BACKUP
,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER) AS MEMBERS
,          DAYS_BETWEEN(CURRENT_TIMESTAMP, DB_CONN_TIME)       AS DAYS
,   MOD(  HOURS_BETWEEN(CURRENT_TIMESTAMP, DB_CONN_TIME),24)   AS HOURS
,   MOD(MINUTES_BETWEEN(CURRENT_TIMESTAMP, DB_CONN_TIME),60) AS MINUTES
,   MOD(SECONDS_BETWEEN(CURRENT_TIMESTAMP, DB_CONN_TIME),60) AS SECONDS
FROM
    TABLE(MON_GET_DATABASE(-2))
GROUP BY
    DB_STATUS
,   DB_ACTIVATION_STATE
,   DB_CONN_TIME
--,   LAST_BACKUP
@

/*
 * List all views that are enabled for query optimization
 */

CREATE OR REPLACE VIEW DB_STATS_PROFILES AS
SELECT  T.TABSCHEMA
,       T.TABNAME
,       T.STATS_TIME
,       T.STATISTICS_PROFILE
,       T.CARD
FROM
    SYSCAT.TABLES T
WHERE
    STATISTICS_PROFILE IS NOT NULL
    
@

/*
 * List all views that are enabled for query optimization
 */

CREATE OR REPLACE VIEW DB_STATISTICAL_VIEWS AS
SELECT  V.VIEWSCHEMA
,       V.VIEWNAME
,       T.STATS_TIME
,       T.STATISTICS_PROFILE
,       T.CARD
,       V.TEXT        AS DDL
FROM
    SYSCAT.VIEWS  V
INNER JOIN
    SYSCAT.TABLES T
ON
    T.TABSCHEMA = V.VIEWSCHEMA 
AND T.TABNAME   = V.VIEWNAME
AND T.TYPE = 'V'
AND SUBSTR(T.PROPERTY,13,1) = 'Y'
@

/*
 * Use to lookup the full description of an SQLSTATE error message
 */

CREATE OR REPLACE VIEW DB_SQLSTATE AS
WITH T(I) AS (VALUES(0) UNION ALL SELECT I + 1 FROM T WHERE I <= 59999)
SELECT * FROM
(
    SELECT
        I AS SQLSTATE
    ,   DB_SQLERRM ( RIGHT(DIGITS(I),5) , '', '', 'EN_US', 1)     AS SHORT_MESSAGE
    ,   DB_SQLERRM ( RIGHT(DIGITS(I),5) , '', '', 'EN_US', 0)     AS FULL_MESSAGE
    FROM T
)
WHERE
    SHORT_MESSAGE IS NOT NULL

@

/*
 * Use to lookup the full description of an SQLCODE error message
 */

CREATE OR REPLACE VIEW DB_SQLCODE AS
WITH T(I) AS (VALUES(1) UNION ALL SELECT I + 1 FROM T WHERE I <= 32766)
SELECT * FROM
(
    SELECT
         I AS SQLCODE
    ,   DB_SQLERRM ('SQL' || I || 'N', '', '', 'EN_US', 1)     AS SHORT_MESSAGE
    ,   DB_SQLERRM ('SQL' || I || 'N', '', '', 'EN_US', 0)     AS FULL_MESSAGE
    ,   REGEXP_REPLACE(SYSPROC.SQLERRM ('SQL' || I || 'N', '', '', 'EN_US', 0),'([\w\"]+)[ \t\f]*[\n\r][ \t\f]*([\w\"]+)','\1 \2') AS FULL_MESSAGE_NO_WORD_WRAP
    FROM T
)
WHERE
    SHORT_MESSAGE IS NOT NULL

@

/*
 * Shows tops sort consuming statements from the package cache
 */

CREATE OR REPLACE VIEW DB_SORTS_STATEMENT AS
SELECT * FROM (
SELECT
    CAST(STMT_TEXT AS VARCHAR(4000 OCTETS))                          AS STMT_TEXT
,   MAX(SORT_SHRHEAP_TOP)                                            AS SHRHEAP_TOP
,   MAX(ESTIMATED_SORT_SHRHEAP_TOP)                                  AS EST_SHRHEAP_TOP
,   MAX(SORT_CONSUMER_SHRHEAP_TOP)                                   AS MAX_CONSUMER
,   SUM(TOTAL_SORTS + TOTAL_HASH_JOINS + TOTAL_HASH_GRPBYS)          AS CONSUMERS
,   SUM(SORT_OVERFLOWS + HASH_JOIN_OVERFLOWS + HASH_GRPBY_OVERFLOWS) AS OVERFLOWS
FROM
    TABLE(MON_GET_PKG_CACHE_STMT(NULL, NULL, NULL, -2))
GROUP BY
    CAST(STMT_TEXT AS VARCHAR(4000 OCTETS))
ORDER BY
    SHRHEAP_TOP DESC
)
@

/*
 * Shows tops sort consuming current queries
 */

CREATE OR REPLACE VIEW DB_SORTS_CURRENT AS
SELECT * FROM (
SELECT
    CAST(STMT_TEXT AS VARCHAR(4000 OCTETS))                          AS STMT_TEXT
,   MAX(SORT_SHRHEAP_TOP)                                            AS SHRHEAP_TOP
,   MAX(ESTIMATED_SORT_SHRHEAP_TOP)                                  AS EST_SHRHEAP_TOP
,   MAX(SORT_CONSUMER_SHRHEAP_TOP)                                   AS MAX_CONSUMER
,   SUM(TOTAL_SORTS + TOTAL_HASH_JOINS + TOTAL_HASH_GRPBYS)          AS CONSUMERS
,   SUM(SORT_OVERFLOWS + HASH_JOIN_OVERFLOWS + HASH_GRPBY_OVERFLOWS) AS OVERFLOWS
FROM
    TABLE(MON_GET_ACTIVITY(NULL, -2))
GROUP BY
    CAST(STMT_TEXT AS VARCHAR(4000 OCTETS))
ORDER BY
    SHRHEAP_TOP DESC
)
@

/*
 * Current SQL by sortheap usage
 */

CREATE OR REPLACE VIEW DB_SORTHEAP_USAGE AS
SELECT * FROM(
SELECT
     MAX(VARCHAR(STMT_TEXT,32000))      AS STMT_TEXT
,    APPLICATION_HANDLE
,    SUM(SORT_HEAP_TOP)             * 4 / 1024  AS SORTHEAP_MB            
,    SUM(SORT_SHRHEAP_TOP)          * 4 / 1024  AS SHR_HEAP_MB            -- Total SHEAPTHRES_SHR consumed by this SQL
,    SUM(SORT_CONSUMER_SHRHEAP_TOP) * 4 / 1024  AS SHR_HEAP_CONS_MB       -- Highest SHEAPTHRES_SHR consumed by any one opeartor
,    MAX(ACTIVITY_STATE)                AS ACTIVITY_STATE
,    MAX(QUERY_COST_ESTIMATE)           AS QUERY_COST_ESTIMATE
,    MAX(ACTIVITY_TYPE)                 AS ACTIVITY_TYPE
,    SUM(ACTIVE_SORTS_TOP)              AS ACTIVE_SORTS_TOP
,    SUM(ACTIVE_SORT_CONSUMERS_TOP)     AS ACTIVE_SORT_CONSUMERS_TOP
,    SUM(ESTIMATED_SORT_CONSUMERS_TOP)  AS ESTIMATED_SORT_CONSUMERS_TOP
,    SUM(ESTIMATED_SORT_SHRHEAP_TOP)    AS ESTIMATED_SORT_SHRHEAP_TOP
,    SUM(POST_SHRTHRESHOLD_SORTS)       AS POST_SHRTHRESHOLD_SORTS
,    SUM(POST_THRESHOLD_SORTS)          AS POST_THRESHOLD_SORTS
/*10.5*/,    SUM(SORT_CONSUMER_HEAP_TOP)    AS SORT_CONSUMER_HEAP_TOP
/*10.5*/,    SUM(SORT_CONSUMER_SHRHEAP_TOP) AS SORT_CONSUMER_SHRHEAP_TOP
,    SUM(SORT_OVERFLOWS)                AS SORT_OVERFLOWS
,    SUM(TOTAL_SECTION_SORTS)           AS TOTAL_SECTION_SORTS
,    SUM(TOTAL_SECTION_SORT_PROC_TIME)  AS TOTAL_SECTION_SORT_PROC_TIME
,    SUM(TOTAL_SECTION_SORT_TIME)       AS TOTAL_SECTION_SORT_TIME
,    SUM(TOTAL_SORTS)                   AS TOTAL_SORTS
--
,    UOW_ID
,    ACTIVITY_ID
,    MAX(COORD_MEMBER)                  AS COORD_MEMBER
FROM
/*DB=*/     TABLE(MON_GET_ACTIVITY(NULL, -2)) 
GROUP BY
     APPLICATION_HANDLE
,    UOW_ID
,    ACTIVITY_ID   
ORDER BY
    SUM(SORT_SHRHEAP_TOP) DESC)SS
    
@

/*
 * List special registers, current application id and other session level variables
 */

CREATE OR REPLACE VIEW DB_SESSION_VARIABLES AS
SELECT * FROM (VALUES
 ( 'MONITOR ELEMENT', 'APPLICATION_HANDLE'  , CHAR((MON_GET_APPLICATION_HANDLE())   )
        , 'values MON_GET_APPLICATION_HANDLE()'
        ,'')                        
,( 'MONITOR ELEMENT', 'APPLICATION_NAME'    , (SELECT APPLICATION_NAME from table(MON_GET_CONNECTION( MON_GET_APPLICATION_HANDLE(), -1)))           
      , 'SELECT APPLICATION_NAME from table(MON_GET_CONNECTION( MON_GET_APPLICATION_HANDLE(), -1))'
      , 'jdbc:clientProgramName=<name>' )
,( 'MONITOR ELEMENT', 'WORKLOAD'
      , (SELECT WORKLOAD_NAME FROM TABLE(WLM_GET_SERVICE_CLASS_WORKLOAD_OCCURRENCES('', '', -1)) WHERE APPLICATION_HANDLE = MON_GET_APPLICATION_HANDLE())
      , 'SELECT WORKLOAD_NAME FROM TABLE(WLM_GET_SERVICE_CLASS_WORKLOAD_OCCURRENCES('''', '''', -1)) WHERE APPLICATION_HANDLE = MON_GET_APPLICATION_HANDLE()'
      , 'call WLM_SET_CLIENT_INFO(NULL, NULL, NULL, NULL, ''SYSDEFAULTADMWORKLOAD|AUTOMATIC'')')
,( 'SPECIAL REGISTER' ,'CLIENT_ACCTNG'                           ,CURRENT CLIENT_ACCTNG                           ,'values CURRENT CLIENT_ACCTNG'                          ,'CALL WLM_SET_CLIENT_INFO(NULL, NULL, NULL, ''<acctstr>'', NULL)'  )
,( 'SPECIAL REGISTER' ,'CLIENT_APPLNAME'                         ,CURRENT CLIENT_APPLNAME                         ,'values CURRENT CLIENT_APPLNAME'                        ,'CALL WLM_SET_CLIENT_INFO(NULL, NULL, ''<applname>'', NULL, NULL)' )
,( 'SPECIAL REGISTER' ,'CLIENT_USERID'                           ,CURRENT CLIENT_USERID                           ,'values CURRENT CLIENT_USERID'                          ,'CALL WLM_SET_CLIENT_INFO(''<userid>'', NULL, NULL, NULL ,NULL)'  )
,( 'SPECIAL REGISTER' ,'CLIENT_WRKSTNNAME'                       ,CURRENT CLIENT_WRKSTNNAME                       ,'values CURRENT CLIENT_WRKSTNNAME'                      ,'CALL WLM_SET_CLIENT_INFO(NULL, ''<wrkstname>'', NULL, NULL, NULL)')
,( 'SPECIAL REGISTER' ,'DATE'                                    ,CHAR(CURRENT DATE)                              ,'values CURRENT DATE'                                   ,'change the system clock time!' )
,( 'SPECIAL REGISTER' ,'DBPARTITIONNUM'                          ,CHAR(CURRENT DBPARTITIONNUM)                    ,'values CURRENT DBPARTITIONNUM'                         ,'jdbc:connectNode=<x>')               
,( 'SPECIAL REGISTER' ,'DECFLOAT ROUNDING MODE'                  ,CURRENT DECFLOAT ROUNDING MODE                  ,'values CURRENT DECFLOAT ROUNDING MODE'                  ,'CALL ADMIN_CMD(''UPDATE DB CFG USING DECFLT_ROUNDING new_value'')' )
,( 'SPECIAL REGISTER' ,'DEFAULT TRANSFORM GROUP'                 ,CURRENT DEFAULT TRANSFORM GROUP                 ,'values CURRENT DEFAULT TRANSFORM GROUP'                ,'SET CURRENT DEFAULT TRANSFORM GROUP')
,( 'SPECIAL REGISTER' ,'DEGREE'                                  ,CURRENT DEGREE                                  ,'values CURRENT DEGREE'                                 ,'SET CURRENT DEGREE')
,( 'SPECIAL REGISTER' ,'EXPLAIN MODE'                            ,CURRENT EXPLAIN MODE                            ,'values CURRENT EXPLAIN MODE'                           ,'SET CURRENT EXPLAIN MODE')
,( 'SPECIAL REGISTER' ,'EXPLAIN SNAPSHOT'                        ,CURRENT EXPLAIN SNAPSHOT                        ,'values CURRENT EXPLAIN SNAPSHOT'                       ,'SET CURRENT EXPLAIN SNAPSHOT')
,( 'SPECIAL REGISTER' ,'FEDERATED ASYNCHRONY'                    ,CHAR(CURRENT FEDERATED ASYNCHRONY)              ,'values CURRENT FEDERATED ASYNCHRONY'                   ,'SET CURRENT FEDERATED ASYNCHRONY') 
,( 'SPECIAL REGISTER' ,'IMPLICIT XMLPARSE OPTION'                ,CURRENT IMPLICIT XMLPARSE OPTION                ,'values CURRENT IMPLICIT XMLPARSE OPTION'               ,'SET CURRENT IMPLICIT XMLPARSE OPTION')
,( 'SPECIAL REGISTER' ,'ISOLATION'                               ,CURRENT ISOLATION                               ,'values CURRENT ISOLATION'                              ,'SET CURRENT ISOLATION')
,( 'SPECIAL REGISTER' ,'LOCALE LC_MESSAGES'                      ,CURRENT LOCALE LC_MESSAGES                      ,'values CURRENT LOCALE LC_MESSAGES'                     ,'SET CURRENT LOCALE LC_MESSAGES')
,( 'SPECIAL REGISTER' ,'LOCALE LC_TIME'                          ,CURRENT LOCALE LC_TIME                          ,'values CURRENT LOCALE LC_TIME'                         ,'SET CURRENT LOCALE LC_TIME')
,( 'SPECIAL REGISTER' ,'LOCK TIMEOUT'                            ,CHAR(CURRENT LOCK TIMEOUT)                      ,'values CURRENT LOCK TIMEOUT'                           ,'SET CURRENT LOCK TIMEOUT')
,( 'SPECIAL REGISTER' ,'MAINTAINED TABLE TYPES FOR OPTIMIZATION' ,CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION ,'values CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION','SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION')
,( 'SPECIAL REGISTER' ,'MDC ROLLOUT MODE'                        ,CURRENT MDC ROLLOUT MODE                        ,'values CURRENT MDC ROLLOUT MODE'                       ,'SET CURRENT MDC ROLLOUT MODE')
,( 'SPECIAL REGISTER' ,'MEMBER'                                  ,CHAR(CURRENT MEMBER)                            ,'values CURRENT MEMBER'                                 ,'')
,( 'SPECIAL REGISTER' ,'OPTIMIZATION PROFILE'                    ,CURRENT OPTIMIZATION PROFILE                    ,'values CURRENT OPTIMIZATION PROFILE'                   ,'SET CURRENT OPTIMIZATION PROFILE')
,( 'SPECIAL REGISTER' ,'PACKAGE PATH'                            ,CURRENT PACKAGE PATH                            ,'values CURRENT PACKAGE PATH'                           ,'SET CURRENT PACKAGE PATH')
,( 'SPECIAL REGISTER' ,'PATH'                                    ,CURRENT PATH                                    ,'values CURRENT PATH'                                   ,'SET CURRENT PATH')
,( 'SPECIAL REGISTER' ,'QUERY OPTIMIZATION'                      ,CHAR(CURRENT QUERY OPTIMIZATION)                ,'values CURRENT QUERY OPTIMIZATION'                     ,'SET CURRENT QUERY OPTIMIZATION')
,( 'SPECIAL REGISTER' ,'REFRESH AGE'                             ,CHAR(CURRENT REFRESH AGE)                       ,'values CURRENT REFRESH AGE'                            ,'SET CURRENT REFRESH AGE')
,( 'SPECIAL REGISTER' ,'SCHEMA'                                  ,CURRENT SCHEMA                                  ,'values CURRENT SCHEMA'                                 ,'SET CURRENT SCHEMA')
,( 'SPECIAL REGISTER' ,'SERVER'                                  ,CURRENT SERVER                                  ,'values CURRENT SERVER'                                 ,'')
,( 'SPECIAL REGISTER' ,'SQL_CCFLAGS'                             ,CURRENT SQL_CCFLAGS                             ,'values CURRENT SQL_CCFLAGS'                            ,'SET CURRENT SQL_CCFLAGS')
,( 'SPECIAL REGISTER' ,'TEMPORAL BUSINESS_TIME'                  ,CHAR(CURRENT TEMPORAL BUSINESS_TIME)            ,'values CURRENT TEMPORAL BUSINESS_TIME'                 ,'SET CURRENT TEMPORAL BUSINESS_TIME date_or_timestamp')
,( 'SPECIAL REGISTER' ,'TEMPORAL SYSTEM_TIME'                    ,CHAR(CURRENT TEMPORAL SYSTEM_TIME)              ,'values CURRENT TEMPORAL SYSTEM_TIME'                   ,'SET CURRENT TEMPORAL SYSTEM_TIME date_or_timestamp')
,( 'SPECIAL REGISTER' ,'TIME'                                    ,CHAR(CURRENT TIME)                              ,'values CURRENT TIME'                                   ,'change the system clock time!' )
,( 'SPECIAL REGISTER' ,'TIMESTAMP'                               ,CHAR(CURRENT TIMESTAMP)                         ,'values CURRENT TIMESTAMP'                              ,'change the system clock time!' )
,( 'SPECIAL REGISTER' ,'TIMEZONE'                                ,CHAR(CURRENT TIMEZONE)                          ,'values CURRENT TIMEZONE'                               ,'')
,( 'SPECIAL REGISTER' ,'USER'                                    ,CURRENT USER                                    ,'values CURRENT USER'                                   ,'SET SESSION AUTHORIZATION other_user')
,( 'SPECIAL REGISTER' ,'SESSION_USER'                            ,SESSION_USER                                    ,'values SESSION_USER'                                   ,'SET SESSION AUTHORIZATION other_user')
,( 'SPECIAL REGISTER' ,'SYSTEM_USER'                             ,SYSTEM_USER                                     ,'values SYSTEM_USER'                                    ,'')
,( 'VARIABLE'         ,'CLIENT_HOST          '                   ,(VALUES CLIENT_HOST              )              ,'values CLIENT_HOST           '                         ,'SET CLIENT_HOST           ') --    contains the host name of the current client, as returned by the operating system.
,( 'VARIABLE'         ,'CLIENT_IPADDR        '                   ,(VALUES CLIENT_IPADDR            )              ,'values CLIENT_IPADDR         '                         ,'SET CLIENT_IPADDR         ') --    contains the IP address of the current client, as returned by the operating system.
--,( 'VARIABLE'         ,'CLIENT_ORIGUSERID    '                   ,(VALUES CLIENT_ORIGUSERID        )              ,'values CLIENT_ORIGUSERID     '                         ,'SET CLIENT_ORIGUSERID     ') --    contains the original user identifier, as supplied by an application, usually from a multiple-tier server environment.
--,( 'VARIABLE'         ,'CLIENT_USRSECTOKEN   '                   ,(VALUES CHAR(CLIENT_USRSECTOKEN) )              ,'values CLIENT_USRSECTOKEN    '                         ,'SET CLIENT_USRSECTOKEN    ') --    contains a security token, as supplied by an application, usually from a multiple-tier server environment.
,( 'VARIABLE'         ,'MON_INTERVAL_ID      '                   ,(VALUES CHAR(MON_INTERVAL_ID)    )              ,'values MON_INTERVAL_ID       '                         ,'SET MON_INTERVAL_ID       ') --    contains the identifier for the current monitoring interval.
,( 'VARIABLE'         ,'NLS_STRING_UNITS     '                   ,(VALUES NLS_STRING_UNITS         )              ,'values NLS_STRING_UNITS      '                         ,'SET NLS_STRING_UNITS      ') --    specifies the default string units that are used when defining character and graphic data types in a Unicode database.
,( 'VARIABLE'         ,'PACKAGE_NAME         '                   ,(VALUES PACKAGE_NAME             )              ,'values PACKAGE_NAME          '                         ,'SET PACKAGE_NAME          ') --    contains the name of the currently executing package.
,( 'VARIABLE'         ,'PACKAGE_SCHEMA       '                   ,(VALUES PACKAGE_SCHEMA           )              ,'values PACKAGE_SCHEMA        '                         ,'SET PACKAGE_SCHEMA        ') --    contains the schema name of the currently executing package.
,( 'VARIABLE'         ,'PACKAGE_VERSION      '                   ,(VALUES CHAR(PACKAGE_VERSION)    )              ,'values PACKAGE_VERSION       '                         ,'SET PACKAGE_VERSION       ') --    contains the version identifier of the currently executing package.
,( 'VARIABLE'         ,'ROUTINE_MODULE       '                   ,(VALUES ROUTINE_MODULE           )              ,'values ROUTINE_MODULE        '                         ,'SET ROUTINE_MODULE        ') --    contains the module name of the currently executing routine.
,( 'VARIABLE'         ,'ROUTINE_SCHEMA       '                   ,(VALUES ROUTINE_SCHEMA           )              ,'values ROUTINE_SCHEMA        '                         ,'SET ROUTINE_SCHEMA        ') --    contains the schema name of the currently executing routine.
,( 'VARIABLE'         ,'ROUTINE_SPECIFIC_NAME'                   ,(VALUES ROUTINE_SPECIFIC_NAME    )              ,'values ROUTINE_SPECIFIC_NAME '                         ,'SET ROUTINE_SPECIFIC_NAME ') --    contains the specific name of the currently executing routine.
,( 'VARIABLE'         ,'ROUTINE_TYPE         '                   ,(VALUES ROUTINE_TYPE             )              ,'values ROUTINE_TYPE          '                         ,'SET ROUTINE_TYPE          ') --    contains the type of the currently executing routine.
,( 'VARIABLE'         ,'SQL_COMPAT           '                   ,(VALUES SQL_COMPAT               )              ,'values SQL_COMPAT            '                         ,'SET SQL_COMPAT            ') --    specifies the SQL compatibility mode. Its value determines which set of syntax rules are applied to SQL queries.
,( 'VARIABLE'         ,'TRUSTED_CONTEXT      '                   ,(VALUES TRUSTED_CONTEXT          )              ,'values TRUSTED_CONTEXT       '                         ,'SET TRUSTED_CONTEXT       ') --    contains the name of the trusted context that was matched to establish the current trusted connection.
,( 'SCALAR FUNCTION'  ,'INSTANCE_AUTHID'                         ,(VALUES AUTH_GET_INSTANCE_AUTHID())             ,'values AUTH_GET_INSTANCE_AUTHID()'                     ,'')
) x(TYPE, NAME, CURRENT_VALUE, SQL_TO_GET, SQL_TO_SET)

@

/*
 * WLM Service Classes 
 */

CREATE OR REPLACE VIEW DB_SERVICE_CLASSES AS
SELECT
    COALESCE(S.PARENTSERVICECLASSNAME || '.' ,'') || S.SERVICECLASSNAME      AS SERVICE_CLASS  
,   CPUSHARES      || CASE CPUSHARETYPE      WHEN 'H' THEN ' HARD' WHEN 'S' THEN ' SOFT' ELSE '' END AS CPU_SHARE
,   RESOURCESHARES || CASE RESOURCESHARETYPE WHEN 'H' THEN ' HARD' WHEN 'S' THEN ' SOFT' ELSE '' END AS RESOURCE_SHARE
,   CASE WHEN AGENTPRIORITY = -32768 THEN 0 ELSE AGENTPRIORITY END    AS AGENT_PRI
,   PREFETCHPRIORITY    AS PREF_PRI
,   BUFFERPOOLPRIORITY  AS BUFF_PRI
FROM
    SYSCAT.SERVICECLASSES S
WHERE
    SERVICECLASSNAME       NOT LIKE 'SYS%'

@

/*
 * WLM Workload DDL 
 */

CREATE OR REPLACE VIEW DB_SERVICE_CLASS_DDL AS
SELECT
    SERVICECLASSNAME
,   PARENTSERVICECLASSNAME
--,   COALESCE(S.PARENTSERVICECLASSNAME || '.' ,'') || S.SERVICECLASSNAME      AS SERVICE_CLASS  
,   'CREATE SERVICE CLASS ' || SERVICECLASSNAME
    ||  CASE WHEN PARENTSERVICECLASSNAME IS NOT NULL THEN CHR(10) || '    UNDER ' || PARENTSERVICECLASSNAME ELSE '' END
    ||  CASE WHEN WORKLOADTYPE > 1 
            THEN CHR(10) || '    FOR WORKLOAD TYPE ' || CASE WORKLOADTYPE WHEN 1 THEN 'CUSTOM' WHEN 2 THEN 'MIXED' WHEN 3 THEN 'INTERACTIVE' WHEN 4 THEN 'BATCH' END ELSE '' END
    ||  CASE WHEN NOT RESOURCESHARES = 1000 AND RESOURCESHARETYPE = 'S' THEN 
            CHR(10) || '    ' || CASE RESOURCESHARETYPE WHEN 'S' THEN 'SOFT' WHEN 'H' THEN 'HARD' ELSE '' END || ' RESOURCE SHARES ' || RESOURCESHARES ELSE '' END
    ||  CASE WHEN NOT      CPUSHARES = 1000 AND      CPUSHARETYPE = 'H' THEN 
            CHR(10) || '    ' || CASE CPUSHARETYPE WHEN 'S' THEN 'SOFT' WHEN 'H' THEN 'HARD' ELSE '' END || ' CPU SHARES ' || RESOURCESHARES ELSE '' END
    ||  CASE WHEN NOT      CPULIMIT = -1 THEN 
                      ' CPULIMIT ' || CPULIMIT ELSE '' END
    ||  CASE WHEN MINRESOURCESHAREPCT > 0 THEN CHR(10) || '    MINIMUM RESOURCE SHARE ' || MINRESOURCESHAREPCT || ' PERCENT' ELSE '' END
    ||  CASE WHEN ADMISSIONQUEUEORDER NOT IN ('','F') THEN CHR(10) || '    ADMISSION QUEUE ORDER LATENCY' ELSE '' END
    ||  CASE WHEN NOT (DEGREESCALEBACK = 'D' AND PARENTSERVICECLASSNAME IS NOT NULL)
              AND NOT (DEGREESCALEBACK = 'Y' AND PARENTSERVICECLASSNAME IS NULL) 
               THEN CHR(10) || '    DEGREE SCALEBACK ' || CASE DEGREESCALEBACK WHEN 'Y' THEN 'ON' WHEN 'N' THEN 'NO' WHEN 'D' THEN 'DEFAULT' END
           ELSE '' END
    ||  CASE WHEN NOT (MAXDEGREE = -1 AND PARENTSERVICECLASSNAME IS     NULL)
              AND NOT (MAXDEGREE = -2 AND PARENTSERVICECLASSNAME IS NOT NULL) THEN CHR(10) || '    MAXIMUM DEGREE '  || CASE MAXDEGREE WHEN -1 THEN 'NONE' WHEN -2 THEN 'DEFAULT' ELSE MAXDEGREE END ELSE '' END
    || CASE WHEN PREFETCHPRIORITY = ' ' THEN '' ELSE CHR(10) || 'PREFETCH PRIORITY'
        || CASE PREFETCHPRIORITY
            WHEN 'H' THEN ' HIGH'
            WHEN 'M' THEN ' MEDIUM'
            WHEN 'L' THEN ' LOW'
            ELSE '' END
        END
    || CASE WHEN OUTBOUNDCORRELATOR IS NULL THEN '' ELSE CHR(10) || 'OUTBOUND CORRELATOR ''' || OUTBOUNDCORRELATOR || '''' END
    || CASE WHEN BUFFERPOOLPRIORITY = ' ' THEN '' ELSE CHR(10) || 'BUFFERPOOL PRIORITY'
        || CASE BUFFERPOOLPRIORITY
            WHEN 'H' THEN ' HIGH'
            WHEN 'M' THEN ' MEDIUM'
            WHEN 'L' THEN ' LOW'
            ELSE '' END
        END
    || CASE WHEN COLLECTACTDATA = 'N' THEN '' ELSE CHR(10) || 'COLLECT ACTIVITY DATA ON '
        || CASE COLLECTACTPARTITION WHEN 'C' THEN 'COORDINATOR MEMBER' WHEN 'D' THEN 'ALL MEMBERS' END
        || CASE COLLECTACTDATA 
                WHEN 'D' THEN ' WITH DETAILS'
                WHEN 'S' THEN ' WITH DETAILS SECTION'
                WHEN 'V' THEN ' WITH DETAILS SECTION INCLUDE ACTUALS BASE'
                WHEN 'X' THEN ' WITH DETAILS SECTION INCLUDE ACTUALS BASE AND VALUES'
                WHEN 'W' THEN ' WITHOUT DETAILS'
                WHEN 'N' THEN ' NONE'
                ELSE ''  END
        END
    || CASE WHEN COLLECTAGGACTDATA = 'N' THEN '' ELSE CHR(10) || 'COLLECT AGGREGATE ACTIVITY DATA NONE'
         || CASE COLLECTAGGACTDATA 
            WHEN 'B' THEN ' BASE'
            WHEN 'E' THEN ' EXTENDED'
            WHEN 'N' THEN ' NONE' -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTAGGREQDATA = 'N' THEN '' ELSE CHR(10) || 'COLLECT AGGREGATE REQUEST DATA'
         || CASE COLLECTAGGREQDATA 
            WHEN 'B' THEN ' BASE'
            WHEN 'N' THEN ' NONE' -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTAGGUOWDATA = 'N'  THEN '' ELSE CHR(10) || 'COLLECT AGGREGATE UNIT OF WORK DATA'
         || CASE COLLECTAGGUOWDATA 
            WHEN 'B' THEN ' BASE'
            WHEN 'N' THEN ' NONE' -- default
            ELSE '' END
        END
    || CASE WHEN COLLECTREQMETRICS = 'N' THEN '' ELSE CHR(10) || 'COLLECT REQUEST METRICS'
         || CASE COLLECTREQMETRICS 
            WHEN 'B' THEN ' BASE' 
            WHEN 'E' THEN ' EXTENDED'
            WHEN 'N' THEN ' NONE'  -- default
            ELSE '' END
        -- to-add - Histogram clause
        END
    AS DDL
FROM
    SYSCAT.SERVICECLASSES S
--LEFT JOIN SYSCAT.HISTOGRAMTEMPLATEUSE  -- TO-DO

@

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
@

/*
 * Lists all Sequences
 * 
 * Note that if you have done an ALTER SEQUENCE RESTART WITH
 *   but not then taken a new sequence value with e.g. VALUES NEXT VAL FOR seqeuence
 *   then you won't see the new restart value via the Db2 catalog views
 *   It is in the table "packed descriptor" which db2look can access,
 *   or you could use e.g.  
 *      db2cat -p sequence -d YOURDB -s SEQ_SCHEMA -n SEQ_NAME -t | grep Restart
 *   to see the unsed RESTART value
 */

CREATE OR REPLACE VIEW DB_SEQUENCES AS
SELECT
    SEQSCHEMA
,   SEQNAME
,      CASE SEQTYPE WHEN 'I' THEN 'IDENTITY' WHEN 'S' THEN 'SEQUENCE' END AS SEQTYPE
,   NEXTCACHEFIRSTVALUE
,   CACHE
,   START
,   INCREMENT
,   MINVALUE
,   MAXVALUE
,   CYCLE
--,   SEQID
FROM
    SYSCAT.SEQUENCES

@

/*
 * Lists all schemas in the database
 */

CREATE OR REPLACE VIEW DB_SCHEMAS AS
SELECT
    SCHEMANAME
,   DEFINER
,   CREATE_TIME
,   REMARKS
,   DESCRIPTION
FROM
    SYSCAT.SCHEMATA
LEFT JOIN
    (VALUES
     ('DB2GSE',               'IBM DB2 Geodetic Spatial Extender catalog views')
    ,('DB2INST1',             'IBM DB2 Database Instance Owner schema')
    ,('DB2OE',                'IBM DB2 Optimization Expert - Workload index advisor tables')
    ,('DB2OSC',               'IBM DB2 Optimization Service Center tables?')
    ,('DSCSTMALERT',          '')
    ,('DSJOBMGR',             'dashDB scheduling')
    ,('DSSCHED',              'dashDB scheduling')
    ,('DSSHSV1',              'dashDB internal')
    ,('DSWEB',                '')
    ,('DSWEBSECURITY',        '')
    ,('GOSALES',              'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESDW',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESHR',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESMR',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('GOSALESRT',            'Sample tables. Originally use by Cognos for demonstrations')
    ,('HEALTHMETRICS',        '')
    ,('IBMADT',               'dashDB internal')
    ,('IBMIOCM',              '')
    ,('IBMOTS',               'dashDB internal')
    ,('IBMPDQ',               'dashDB metadata about the instance')
    ,('IBMCONSOLE',           'Db2 Managment Console tables')
    ,('IBM_DSM_VIEWS',        '')
    ,('IBM_RTMON',            '')
    ,('IBM_RTMON_BASELINE',   '')
    ,('IBM_RTMON_DATA',       '')
    ,('IBM_RTMON_EVMON',      '')
    ,('IBM_RTMON_METADATA',   '')
    ,('IDAX',                 'Db2 In Database Analytics')
    ,('NULLID',               'Db2 Package sets')
    ,('NULLIDR1',             'Db2 REOPT ONCE Package sets')
    ,('NULLIDRA',             'Db2 REOPT ALWAYS Package sets')
    ,('OPM',                  'IBM Optim Performance Manager')
    ,('OQT',                  'IBM Optim Query Workload Tuner')
    ,('PROCMGMT',             'IBM Data Server Manager')
    ,('QUERYTUNER',           'IBM Optim Query Worlkoad Tuner')
    ,('SPARKCOL',             '')
    ,('SQLJ',                 'SQLJ Packages')
    ,('ST_INFORMTN_SCHEMA',   'Geospatial extender')
    ,('SYSCAT',               'Db2 System Catalog Views')
    ,('SYSFUN',               'Db2 Alternative System Functions')
    ,('SYSIBM',               'Db2 System Catalog Tables, functions etc')
    ,('SYSIBMADM',            'Db2 Built-in monitoring functions and views')
    ,('SYSIBMINTERNAL',       'Db2 internal routines')
    ,('SYSIBMTS',             '')
    ,('SYSPROC',              'Db2 Built-in procedures')
    ,('SYSPUBLIC',            'Public aliases')
    ,('SYSSTAT',              'Db2 System Catalog Statistics Views')
    ,('SYSTOOLS',             'Used by a variety of IBM tools. Home to Explain tables and other such things')
) AS D (SCHEMANAME, DESCRIPTION )
USING
    ( SCHEMANAME )

@

/*
 * Lists all scalar functions in the database
 */

/*
 * Note that SYSCAT.FUNCTIONS has been deprecated sincde DB2 7.1, so we use SYSCAT.ROUTINES
 */
CREATE OR REPLACE VIEW DB_SCALAR_FUNCTIONS AS
SELECT
    ROUTINESCHEMA     AS FUNCSCHEMA
,   ROUTINENAME       AS FUNCNAME
,   ROUTINEMODULENAME AS MODULENAME
,   COALESCE(PARMS,'')       AS PARMS
,   SPECIFICNAME
,   LANGUAGE
,   DIALECT
,      CASE WHEN LANGUAGE <> '' THEN 'LANGUAGE ' || RTRIM(LANGUAGE) ELSE '' END
    || CASE DETERMINISTIC WHEN 'Y' THEN ' DETERMINISTIC'
                      WHEN 'N' THEN ' NOT DETERMINISTIC'
    ELSE '' END
    || CASE EXTERNAL_ACTION WHEN 'Y' THEN ' EXTERNAL ACTION'
                         WHEN 'N' THEN ' NO EXTERNAL ACTION'
    ELSE '' END 
    || CASE FENCED WHEN 'Y' THEN ' FENCED'
               WHEN 'N' THEN ' NOT FENCED'
    ELSE '' END 
    || CASE THREADSAFE WHEN 'Y' THEN ' THREADSAFE'
                   WHEN 'N' THEN ' NOT THREADSAFE'
    ELSE '' END 
    || CASE PARALLEL WHEN 'Y' THEN ' ALLOW PARALLEL'
                  WHEN 'N' THEN ' DISALLOW PARALLEL'
    ELSE '' END  
    || CASE SQL_DATA_ACCESS 
                            WHEN 'R' THEN ' READS SQL DATA'
                            WHEN 'C' THEN ' CONTAINS SQL'
                            WHEN 'M' THEN ' MODIFIES SQL DATA'
                            WHEN 'N' THEN ' NO SQL'
    ELSE '' END 
    || CASE SECURE WHEN 'Y' THEN ' SECURED'
    --               WHEN 'N' THEN ' NOT SECURED'       this is the default
    ELSE '' END 
        AS OPTIONS
,   CASE WHEN TEXT_BODY_OFFSET > 0 THEN SUBSTR(TEXT,TEXT_BODY_OFFSET) ELSE '' END   AS TEXT_BODY
,   COALESCE(CALL_STMT,'')   AS USAGE_STMT
,   REMARKS         AS COMMENTS
FROM  
    SYSCAT.ROUTINES 
LEFT JOIN
(    SELECT 
         ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME
     ,   LISTAGG(
             COALESCE(VARCHAR(PARMNAME,32000) || ' ','')
             || CASE
                    WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB') 
                    THEN     CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END
                          || '(' || LENGTH || ')'
                    WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                    THEN TYPENAME
                    WHEN TYPENAME IN ('TIMESTAMP') OR (TYPENAME IN ('DECIMAL') AND SCALE = 0)
                    THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                    WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                    THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                    WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                    ELSE TYPENAME END 
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) AS PARMS 
     FROM
         SYSCAT.ROUTINEPARMS
     WHERE
        ROWTYPE IN ('P','B')
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
LEFT JOIN
(    SELECT 
         ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME      
     ,   'values "' || ROUTINESCHEMA || '"."' || ROUTINENAME || '" (' ||
         LISTAGG(
                CASE 
                    WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'VARGAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB')    THEN  ''''''
                    WHEN TYPENAME IN ('TIMESTAMP')           THEN 'CURRENT_TIMESTAMP'
                    WHEN TYPENAME IN ('DATE')                THEN 'CURRENT_DATE'
                    WHEN TYPENAME IN ('TIME')                THEN 'CURRENT_TIME'
                    WHEN TYPENAME IN ('DECIMAL','DECFLOAT')  THEN '0.0' 
                                                             ELSE '0'
                END
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) || ')' AS CALL_STMT 
     FROM
         SYSCAT.ROUTINEPARMS
     WHERE
        ROWTYPE IN ('P','B')
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
WHERE
    FUNCTIONTYPE = 'S'

@

/*
 * Generate runstats commands
 * 
 * TO-DO - add a sensible sampleing default based on #rows * # columns
 */

CREATE OR REPLACE VIEW DB_RUNSTATS AS
SELECT  T.TABSCHEMA
,       T.TABNAME
,       'CALL ADMIN_CMD(''RUNSTATS ON TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" '
        || CASE WHEN STATISTICS_PROFILE IS NOT NULL THEN 'USE PROFILE' 
             ELSE 'WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL' 
--             || CASE WHEN CARD * COLCOUNT > 10000000000 THEN ' TABLESAMPLE SYSTEM (1) ' END
             END 
        || '''' AS RUNSTATS
,       T.STATS_TIME
,       T.STATISTICS_PROFILE
,       T.CARD
FROM
    SYSCAT.TABLES T
WHERE
        TYPE IN ('S','T')
OR  (   T.TYPE = 'V' AND SUBSTR(T.PROPERTY,13,1) = 'Y' )
@

/*
 * Shows runstats queued for processing by Db2 Automatic maintenance or real-time stats
 */

CREATE OR REPLACE VIEW DB_RUNSTATS_QUEUE AS
SELECT * FROM(
    SELECT
        'Auto stats'        AS COLLECT_TYPE
    ,   QUEUE_POSITION
    ,   OBJECT_SCHEMA       AS TABSCHEMA
    ,   OBJECT_NAME         AS TABNAME
    ,   OBJECT_TYPE
    ,   OBJECT_STATUS       AS STATUS
    ,   ''                  AS REQUEST_TYPE
    ,   QUEUE_ENTRY_TIME
    ,   JOB_SUBMIT_TIME     AS SUBMIT_START_TIME
    ,   MEMBER
    FROM TABLE(MON_GET_AUTO_RUNSTATS_QUEUE()) AS T
    UNION ALL
    SELECT 
        'Real-time stats'   AS COLLECT_TYPE
    ,   QUEUE_POSITION
    ,   OBJECT_SCHEMA       AS TABSCHEMA
    ,   OBJECT_NAME         AS TABNAME
    ,   OBJECT_TYPE
    ,   REQUEST_STATUS      AS OBJECT_STATUS
    ,   REQUEST_TYPE
    ,   QUEUE_ENTRY_TIME
    ,   EXECUTION_START_TIME    AS SUBMIT_START_TIME
    ,   MEMBER
    FROM
        TABLE(MON_GET_RTS_RQST()) AS T
    ORDER BY COLLECT_TYPE, QUEUE_POSITION ASC
)

@

/*
 * Shows auto and manual runstats history from the db2optstats log. Defaults to entries for the current day
 */

CREATE OR REPLACE VIEW DB_RUNSTATS_LOG AS
SELECT * FROM(
    SELECT TIMESTAMP
    ,      TIMEZONE                             AS TZ
    ,      OBJNAME_QUALIFIER                    AS TABSCHEMA
    ,      OBJNAME                              AS TABNAME
    ,      SUBSTR(SECOND_EVENTQUALIFIER, 1, 20) AS COLLECT_TYPE 
    ,      AUTH_ID
    ,      SUBSTR(OBJTYPE, 1, 30)               AS OBJTYPE
    ,      SUBSTR(EVENTSTATE, 1, 8)             AS RESULT
    ,      SUBSTR(COALESCE(THIRD_EVENTQUALIFIER,''), 1, 15) AS REASON
    FROM
           TABLE(SYSPROC.PD_GET_DIAG_HIST('OPTSTATS', '', '',DB_DIAG_FROM_TIMESTAMP,DB_DIAG_TO_TIMESTAMP,DB_DIAG_MEMBER)) AS SL
    WHERE
        OBJNAME_QUALIFIER IS NOT NULL
    AND EVENTSTATE <> 'start'
    ORDER BY
        TIMESTAMP
)SS

@

/*
 * Shows current database registry variables set on the database server (Db2set)
 */

CREATE OR REPLACE VIEW DB_REGISTRY_VARIABLES AS
SELECT
    REG_VAR_NAME
,   REG_VAR_VALUE
,   CASE WHEN REG_VAR_VALUE <> REG_VAR_ON_DISK_VALUE THEN REG_VAR_ON_DISK_VALUE ELSE '' END AS ON_DISK_VALUE
,   REG_VAR_DEFAULT_VALUE       AS DEFAULT_VALUE
,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER) AS MEMBERS
FROM
     TABLE(ENV_GET_REG_VARIABLES(-2, 0))
GROUP BY
    REG_VAR_NAME
,   REG_VAR_VALUE
,   REG_VAR_DEFAULT_VALUE
,   REG_VAR_ON_DISK_VALUE
@

/*
 * Generates an ADMIN_MOVE_TABLE (AMT) that can recreate a column organized table with a new dictonary using LOAD. Generally use on SMALLish TABLES only. The table is READ ONLY while AMT runs
 */

CREATE OR REPLACE VIEW DB_REBUILD_DICTIONARY AS
SELECT 
    TABSCHEMA
,   TABNAME
,   TBSPACE
,   PCTPAGESSAVED
,   AVG_PCTENCODED
,   CARD
,   NPAGES
,   FPAGES
,   'CALL ADMIN_MOVE_TABLE (''' || RTRIM(TABSCHEMA)  || ''',''' 
    || TABNAME || ''','''','''','''','''','''','''','''',''ALLOW_READ_ACCESS,COPY_USE_LOAD NONRECOVERABLE'',''MOVE'')' --    || '-- ' || CARD || ' / ' || NPAGES   
        AS REBUILD_STMT
,   'CALL ADMIN_CMD (''RUNSTATS ON TABLE "' || RTRIM(TABSCHEMA)  || '"."' || TABNAME || '"' 
    || CASE WHEN STATISTICS_PROFILE IS NOT NULL THEN ' USE PROFILE' ELSE ' WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL' END || ''')' 
        AS RUNSTATS_STMT
FROM
    SYSCAT.TABLES T
JOIN
    (SELECT TABNAME, TABSCHEMA, DECIMAL(AVG(PCTENCODED),5,2) AVG_PCTENCODED FROM SYSCAT.COLUMNS GROUP BY TABNAME, TABSCHEMA ) USING (TABNAME, TABSCHEMA)
WHERE TYPE NOT IN ('A','N','V','W') 
AND TABSCHEMA NOT LIKE 'SYS%'
AND T.TABLEORG = 'C'
@

/*
 * Lists all stored procedures on the database. Includes the parameter signature and an example CALL statement for each procedure
 */

CREATE OR REPLACE VIEW DB_PROCEDURES AS
SELECT
    ROUTINESCHEMA   AS PROCSCHEMA
,   ROUTINENAME     AS PROCNAME
,   COALESCE(PARMS,'')       AS PARMS
,   SPECIFICNAME
,   COALESCE(CALL_STMT,'')   AS CALL_STMT
,   LANGUAGE
,   TIMESTAMP(CREATE_TIME,0) AS CREATE_DATETIME
,   REMARKS         AS COMMENTS
FROM
    SYSCAT.ROUTINES 
LEFT JOIN
(    SELECT 
         ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME
     ,   LISTAGG(
             VARCHAR(PARMNAME,32000) || ' '
			 || CASE
			        WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB') 
			        THEN     CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END
			              || '(' || LENGTH || ')'
			        WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
			        THEN TYPENAME
			        WHEN TYPENAME IN ('TIMESTAMP') OR (TYPENAME IN ('DECIMAL') AND SCALE = 0)
			        THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
			        WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
			        THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
			        WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
			        ELSE TYPENAME END 
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) AS PARMS 
     FROM
         SYSCAT.ROUTINEPARMS
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
LEFT JOIN
( SELECT ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME      
     ,   'call "' || ROUTINESCHEMA || '"."' || ROUTINENAME || '" (' ||
         LISTAGG(
             VARCHAR(PARMNAME,32000) || ' => ' 
             || CASE WHEN ROWTYPE = 'O' THEN '?' 
                    WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'VARGAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB')    THEN  ''''''
                    WHEN TYPENAME IN ('TIMESTAMP')           THEN 'CURRENT_TIMESTAMP'
                    WHEN TYPENAME IN ('DATE')                THEN 'CURRENT_DATE'
                    WHEN TYPENAME IN ('TIME')                THEN 'CURRENT_TIME'
                    WHEN TYPENAME IN ('DECIMAL','DECFLOAT')  THEN '0.0' 
                                                             ELSE '0'
                END
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) || ');' AS CALL_STMT 
     FROM
         SYSCAT.ROUTINEPARMS
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
WHERE
    ROUTINETYPE = 'P'

@

/*
 * Returns the CREATE PROCEDURE DDL for all stored procedures on the database
 */

CREATE OR REPLACE VIEW DB_PROCEDURE_DDL AS
SELECT
    ROUTINESCHEMA   AS PROCSCHEMA
,   ROUTINENAME     AS PROCNAME
,   SPECIFICNAME
,   TEXT            AS DDL
FROM
    SYSCAT.ROUTINES
WHERE
    ROUTINETYPE = 'P'

@

/*
 * Lists all the direct privileges granted on the system, including those gained via object ownership. Also include database level privileges, set session user privlies etc
 * 
 * This view extends the provided SYSIBMADM.PRIVILEGES view to also include
 * 
 *  - any Privileges given on objects that are owned by a user, role, group or PUBLIC
 *  - any database level authorities granted to a user, role, group or PUBLIC
 *  - any SET SESSION_USER privliges granted to a user
 *  - any ROLEs that a user, role, group or PUBLIC is a member of
 *
 * In this way, the view provides all of the GRANTs that have been explictly or implicitly performed on a system
 * , including privileges granted at database creation time to the instance owner
 * 
 * The view shows on direct privileges that a user, role, group or PUBLIC has,
 * , not any in-direct privliges that are inherited from a role or group membership, or from PUBLIC.
 * 
 */

CREATE OR REPLACE VIEW DB_PRIVILEGES AS
	SELECT DISTINCT
		AUTHID
	,	AUTHIDTYPE
	,	PRIVILEGE
	,	GRANTABLE
	,	OBJECTNAME
	,	OBJECTSCHEMA
	,	OBJECTTYPE
	,   'REVOKE ' || CASE PRIVILEGE WHEN 'REFERENCE' THEN 'REFERENCES' ELSE PRIVILEGE END || ' ON ' 
	    || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
	    || CASE WHEN OBJECTSCHEMA = '' THEN '' ELSE '"' || OBJECTSCHEMA ||  '".' END
	    || CASE WHEN OBJECTNAME   = '' THEN '' ELSE '"' || OBJECTNAME ||  '"' END || ' FROM ' 
	    || CASE WHEN AUTHID = 'PUBLIC' AND AUTHIDTYPE = 'G' THEN 'PUBLIC' 
	       ELSE CASE AUTHIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || AUTHID ||  '"' END AS REVOKE_STMT
    ,   'GRANT '  || CASE PRIVILEGE WHEN 'REFERENCE' THEN 'REFERENCES' ELSE PRIVILEGE END || ' ON '
        || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
        || CASE WHEN OBJECTSCHEMA = '' THEN '' ELSE '"' || OBJECTSCHEMA ||  '".' END 
        || CASE WHEN OBJECTNAME   = '' THEN '' ELSE '"' || OBJECTNAME ||  '"' END || ' TO ' 
        || CASE WHEN AUTHID = 'PUBLIC' AND AUTHIDTYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE AUTHIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || AUTHID ||  '"' END
        || CASE WHEN GRANTABLE = 'G' THEN ' WITH GRANT OPTION' ELSE '' END                                                        AS GRANT_STMT
	FROM
	    SYSIBMADM.PRIVILEGES
UNION ALL
    SELECT
        OWNER            AS AUTHID
    ,   OWNERTYPE        AS AUTHIDTYPE
    ,   'OWNER'          AS PRIVILEGE
    ,   'N'              AS GRANTABLE
    ,   OBJECTNAME
    ,   OBJECTSCHEMA
    ,   OBJECTTYPE
    ,   'TRANSFER OWNERSHIP OF ' || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
        || ' "' || OBJECTSCHEMA ||  '"."' || OBJECTNAME ||  '"' || ' TO USER SOME_OTHER_USER PRESERVE PRIVILEGES ' 
         AS REVOKE_STMT
    ,   'TRANSFER OWNERSHIP OF ' || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
        || ' "' || OBJECTSCHEMA ||  '"."' || OBJECTNAME ||  '"' || ' TO ' 
        || CASE WHEN OWNER = 'PUBLIC' AND OWNERTYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE OWNERTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || OWNER ||  '"' END AS GRANT_STMT
    FROM 
        SYSIBMADM.OBJECTOWNERS
    WHERE
        OWNER <> 'SYSIBM'
UNION ALL
	SELECT DISTINCT
	    A.GRANTEE                                    AS AUTHID
	,   A.GRANTEETYPE                                AS AUTHIDTYPE
	,   B.PRIVILEGE
	,   CASE WHEN B.AUTH = 'G' THEN 'Y' ELSE 'N' END AS GRANTABLE
	,   CURRENT SERVER                               AS OBJECTNAME
	,   ''                                           AS OBJECTSCHEMA
	,   CAST ('DATABASE' AS VARCHAR (11))            AS OBJECTTYPE
    ,   'REVOKE ' || PRIVILEGE || ' ON DATABASE FROM ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEETYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END AS REVOKE_STMT
    ,   'GRANT '  || PRIVILEGE || ' ON DATABASE TO ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEETYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END 
           || CASE WHEN AUTH = 'G' THEN ' WITH GRANT OPTION' ELSE '' END                                                            AS GRANT_STMT
	FROM SYSCAT.DBAUTH A          
	, LATERAL(VALUES
	    (BINDADDAUTH         ,'BINDADD')
	,   (CONNECTAUTH         ,'CONNECT')
	,   (CREATETABAUTH       ,'CREATETAB')
	,   (DBADMAUTH           ,'DBADM')
	,   (EXTERNALROUTINEAUTH ,'CREATE_EXTERNAL_ROUTINE')
	,   (IMPLSCHEMAAUTH      ,'IMPLICIT_SCHEMA')      
	,   (LOADAUTH            ,'LOAD')
	,   (NOFENCEAUTH         ,'CREATE_NOT_FENCED_ROUTINE') 
	,   (QUIESCECONNECTAUTH  ,'QUIESCE_CONNECT')
	,   (LIBRARYADMAUTH      ,'LIBRARYADMAUTH')
	,   (SECURITYADMAUTH     ,'SECADM')
	,   (SQLADMAUTH          ,'SQLADM')
	,   (WLMADMAUTH          ,'WLMADM')
	,   (EXPLAINAUTH         ,'EXPLAIN')
	,   (DATAACCESSAUTH      ,'DATAACCESS')
	,   (ACCESSCTRLAUTH      ,'ACCESSCTRL')
	) B ( AUTH, PRIVILEGE )
	WHERE  B.AUTH IN ('Y','G')
UNION ALL
	SELECT DISTINCT
	    TRUSTEDID               AS AUTHID
	,   TRUSTEDIDTYPE           AS AUTHIDTYPE
	,   'SETSESSIONUSER'        AS PRIVILEGE
	,   'N'                     AS GRANTABLE
	,   SURROGATEAUTHID         AS OBJECTNAME
	,   ''                      AS OBJECTSCHEMA
	,   SURROGATEAUTHIDTYPE     AS OBJECTTYPE
    ,   'REVOKE SETSESSIONUSER ON ' || CASE SURROGATEAUTHIDTYPE WHEN 'U' THEN 'USER ' || SURROGATEAUTHID ELSE 'PUBLIC' END || ' FROM ' 
        || CASE TRUSTEDIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || TRUSTEDID || '"'          AS REVOKE_STMT
    ,   'GRANT  SETSESSIONUSER ON ' || CASE SURROGATEAUTHIDTYPE WHEN 'U' THEN 'USER ' || SURROGATEAUTHID ELSE 'PUBLIC' END || ' TO '
        || CASE TRUSTEDIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || TRUSTEDID || '"'          AS GRANT_STMT 
	FROM
	    SYSCAT.SURROGATEAUTHIDS
	WHERE
	    TRUSTEDIDTYPE <> 'C'  -- exclude SYSATSCONTEXT
UNION ALL
    SELECT GRANTEE              AS AUTHID
    ,      GRANTEETYPE          AS AUTHIDTYPE
    ,      'MEMBERSHIP'         AS PRIVILEGE
    ,      ADMIN                AS GRANTABLE
    ,      ROLENAME             AS OBJECTNAME
    ,      ''                   AS OBJECTSCHEMA
    ,      'ROLE'               AS OBJECTTYPE
    ,   'REVOKE ROLE FROM ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEETYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END AS REVOKE_STMT
    ,   'GRANT ROLE TO ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END
        || CASE WHEN ADMIN = 'Y' THEN ' WITH ADMIN OPTION' ELSE '' END                                                        AS GRANT_STMT
    FROM SYSCAT.ROLEAUTH

@

/*
 * Lists all Primary Keys in the database
 */

CREATE OR REPLACE VIEW DB_PRIMARY_KEYS AS
SELECT
    TABSCHEMA
,   TABNAME
,   CONSTNAME
,   LISTAGG(COLNAME,', ') WITHIN GROUP (ORDER BY COLSEQ) AS PK_COLS
,   MAX(ENFORCED)   AS ENFORCED
FROM
    SYSCAT.TABCONST C
JOIN
    SYSCAT.KEYCOLUSE
USING
    ( TABSCHEMA , TABNAME, CONSTNAME ) 
WHERE  
    C.TYPE = 'P'
GROUP BY
    TABSCHEMA
,   TABNAME
,   CONSTNAME
@

/*
 * Generates DDL for all Primary Keys and Unique Constraints in the database
 */

CREATE OR REPLACE VIEW DB_PRIMARY_KEY_DDL AS
SELECT
    TABSCHEMA
,   TABNAME
,   CONSTNAME
,   'ALTER TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" ADD' 
    || CASE WHEN CONSTNAME NOT LIKE 'SQL%' THEN ' CONSTRAINT "' || CONSTNAME || '"' ELSE '' END
    || CASE C.TYPE WHEN 'P' THEN ' PRIMARY KEY ' WHEN 'U' THEN ' UNIQUE ' END
    || '(' || COL_LIST  
    || COALESCE(', ' || PERIODNAME || CASE PERIODPOLICY WHEN 'O' THEN ' WITHOUT OVERLAPS ' ELSE '' END,'')
    || ')'
    || CASE ENFORCED WHEN 'Y' THEN ' ENFORCED' WHEN 'N' THEN ' NOT ENFORCED' END
    || CASE ENABLEQUERYOPT WHEN 'N' THEN ' DISABLE QUERY OPTIMIZATION' ELSE '' END
        AS DDL
FROM
    SYSCAT.TABCONST C
JOIN
(   SELECT
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
    ,   LISTAGG('"' || K.COLNAME || '"',', ') WITHIN GROUP (ORDER BY K.COLSEQ)   AS COL_LIST
    FROM
        SYSCAT.KEYCOLUSE K
    LEFT JOIN -- exclude period columns from the column list
        SYSCAT.PERIODS  B1 ON K.TABSCHEMA = B1.TABSCHEMA AND K.TABNAME = B1.TABNAME AND K.COLNAME = B1.BEGINCOLNAME AND B1.PERIODNAME = 'BUSINESS_TIME'
    LEFT JOIN
        SYSCAT.PERIODS  B2 ON K.TABSCHEMA = B2.TABSCHEMA AND K.TABNAME = B2.TABNAME AND K.COLNAME = B2.ENDCOLNAME   AND B2.PERIODNAME = 'BUSINESS_TIME'
    WHERE
        B1.TABNAME IS NULL
    AND B2.TABNAME IS NULL
    GROUP BY
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
)
USING
    ( TABSCHEMA , TABNAME, CONSTNAME ) 
WHERE  
    C.TYPE IN ( 'P', 'U' )

@

/*
 * Lists and Row and Column Access Control (RCAC) permissions you have applied on the system (from SYSCAT.CONTORLS)
 */

CREATE OR REPLACE VIEW DB_PERMISSIONS AS
SELECT 
    TABSCHEMA
,   TABNAME
,   CONTROLNAME
,       'CREATE OR REPLACE PERMISSION "' || CONTROLNAME || '  ON "' || TABSCHEMA || '"."' || TABNAME || CHR(34) 
    || ' FOR ROWS WHERE ' || RULETEXT
    || ' ENFORCED FOR ALL ACCESS ' || CASE ENABLE WHEN 'Y' THEN 'ENABLE' ELSE 'DISABLE' END
    AS DDL
FROM
    SYSCAT.CONTROLS
@

/*
 * Lists file system paths used by the database
 */

CREATE OR REPLACE VIEW DB_PATHS AS 
SELECT
    TYPE
,   PATH
,   LISTAGG(DBPARTITIONNUM,',') WITHIN GROUP (ORDER BY DBPARTITIONNUM) AS MEMBERS
FROM
(   SELECT
        TYPE
    ,   REGEXP_REPLACE(PATH,'([^0-9])[0-9]{4}([^0-9])','\1xxxx\2')    AS PATH
    ,   DBPARTITIONNUM
    FROM TABLE(SYSPROC.ADMIN_LIST_DB_PATHS()) AS T
)
GROUP BY
    TYPE
,   PATH

@

/*
 * Lists all objects in the catalog. Tables, Columns, Indexes etc. Essentially a UNION of all the SYSCAT catalog views
 */

CREATE OR REPLACE VIEW DB_OBJECTS 
         (       CATALOG_VIEW                  ,OBJECT_PARENT               ,OBJECT_NAME             ,SPECIFIC_NAME           ,OBJECT_TYPE       ,CREATE_DATETIME           ,MODIFY_DATETIME )
AS
          SELECT 'ATTRIBUTES'                  ,TYPESCHEMA                  ,TYPEMODULENAME          ,''                      ,TYPEMODULENAME    ,CAST(NULL AS TIMESTAMP(0)),CAST(NULL AS TIMESTAMP(0)) FROM SYSCAT.ATTRIBUTES
UNION ALL SELECT 'AUDITPOLICIES'               ,''                          ,AUDITPOLICYNAME         ,''                      ,ERRORTYPE         ,CREATE_TIME       ,NULL               FROM SYSCAT.AUDITPOLICIES
UNION ALL SELECT 'BUFFERPOOLS'                 ,''                          ,BPNAME                  ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.BUFFERPOOLS
UNION ALL SELECT 'CASTFUNCTIONS'               ,FROM_TYPESCHEMA             ,FROM_TYPEMODULENAME     ,SPECIFICNAME            ,FROM_TYPESCHEMA   ,NULL              ,NULL               FROM SYSCAT.CASTFUNCTIONS
UNION ALL SELECT 'CHECKS'                      ,TABSCHEMA                   ,CONSTNAME               ,''                      ,TYPE              ,CREATE_TIME       ,NULL               FROM SYSCAT.CHECKS
UNION ALL SELECT 'COLCHECKS'                   ,TABSCHEMA                   ,CONSTNAME               ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLCHECKS
UNION ALL SELECT 'COLGROUPCOLS'                ,TABSCHEMA                   ,TABNAME || '.' || COLNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLGROUPCOLS
UNION ALL SELECT 'COLGROUPDISTCOUNTS'          ,''                          ,''                      ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.COLGROUPDISTCOUNTS
UNION ALL SELECT 'COLGROUPS'                   ,COLGROUPSCHEMA              ,COLGROUPNAME            ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLGROUPS
UNION ALL SELECT 'COLIDENTATTRIBUTES'          ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLIDENTATTRIBUTES
UNION ALL SELECT 'COLLATIONS'                  ,COLLATIONSCHEMA             ,COLLATIONNAME           ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLLATIONS
UNION ALL SELECT 'COLOPTIONS'                  ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.COLOPTIONS
UNION ALL SELECT 'COLUMNS'                     ,RTRIM(TABSCHEMA) || '.' ||TABNAME        ,COLNAME                 ,''                      ,TYPENAME          ,NULL              ,NULL               FROM SYSCAT.COLUMNS
UNION ALL SELECT 'CONDITIONS'                  ,CONDSCHEMA                  ,CONDMODULENAME          ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.CONDITIONS
UNION ALL SELECT 'CONTEXTATTRIBUTES'           ,''                          ,CONTEXTNAME             ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.CONTEXTATTRIBUTES
UNION ALL SELECT 'CONTEXTS'                    ,''                          ,CONTEXTNAME             ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.CONTEXTS
UNION ALL SELECT 'CONTROLS'                    ,CONTROLSCHEMA               ,CONTROLNAME             ,''                      ,CONTROLTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.CONTROLS
UNION ALL SELECT 'DATAPARTITIONEXPRESSION'     ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.DATAPARTITIONEXPRESSION
UNION ALL SELECT 'DATAPARTITIONS'              ,TABSCHEMA                   ,DATAPARTITIONNAME       ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.DATAPARTITIONS
UNION ALL SELECT 'DATATYPES'                   ,TYPESCHEMA                  ,TYPEMODULENAME          ,''                      ,TYPEMODULENAME    ,CREATE_TIME       ,NULL               FROM SYSCAT.DATATYPES
UNION ALL SELECT 'DBPARTITIONGROUPDEF'         ,''                          ,DBPGNAME                ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.DBPARTITIONGROUPDEF
UNION ALL SELECT 'DBPARTITIONGROUPS'           ,''                          ,DBPGNAME                ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.DBPARTITIONGROUPS
UNION ALL SELECT 'EVENTMONITORS'               ,''                          ,EVMONNAME               ,''                      ,TARGET_TYPE       ,NULL              ,NULL               FROM SYSCAT.EVENTMONITORS
UNION ALL SELECT 'EVENTS'                      ,''                          ,EVMONNAME               ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.EVENTS
UNION ALL SELECT 'EVENTTABLES'                 ,TABSCHEMA                   ,EVMONNAME               ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.EVENTTABLES
UNION ALL SELECT 'FULLHIERARCHIES'             ,SUB_SCHEMA                  ,SUB_NAME                ,''                      ,METATYPE          ,NULL              ,NULL               FROM SYSCAT.FULLHIERARCHIES
UNION ALL SELECT 'FUNCMAPPINGS'                ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,SERVERTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.FUNCMAPPINGS
UNION ALL SELECT 'FUNCPARMS'                   ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,ROWTYPE           ,NULL              ,NULL               FROM SYSCAT.FUNCPARMS
UNION ALL SELECT 'FUNCTIONS'                   ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,CHAR(RETURN_TYPE) ,CREATE_TIME       ,NULL               FROM SYSCAT.FUNCTIONS
UNION ALL SELECT 'HIERARCHIES'                 ,SUB_SCHEMA                  ,SUB_NAME                ,''                      ,METATYPE          ,NULL              ,NULL               FROM SYSCAT.HIERARCHIES
UNION ALL SELECT 'HISTOGRAMTEMPLATEBINS'       ,''                          ,TEMPLATENAME            ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.HISTOGRAMTEMPLATEBINS
UNION ALL SELECT 'HISTOGRAMTEMPLATES'          ,''                          ,TEMPLATENAME            ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.HISTOGRAMTEMPLATES
UNION ALL SELECT 'INDEXES'                     ,INDSCHEMA                   ,INDNAME                 ,''                      ,INDEXTYPE         ,CREATE_TIME       ,NULL               FROM SYSCAT.INDEXES
UNION ALL SELECT 'INDEXEXPLOITRULES'           ,IESCHEMA                    ,IENAME                  ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXEXPLOITRULES
UNION ALL SELECT 'INDEXEXTENSIONMETHODS'       ,IESCHEMA                    ,METHODNAME              ,RANGESPECIFICNAME       ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXEXTENSIONMETHODS
UNION ALL SELECT 'INDEXEXTENSIONPARMS'         ,IESCHEMA                    ,IENAME                  ,''                      ,TYPENAME          ,NULL              ,NULL               FROM SYSCAT.INDEXEXTENSIONPARMS
UNION ALL SELECT 'INDEXEXTENSIONS'             ,IESCHEMA                    ,IENAME                  ,KEYGENSPECIFICNAME      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.INDEXEXTENSIONS
UNION ALL SELECT 'INDEXOPTIONS'                ,INDSCHEMA                   ,INDNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXOPTIONS
UNION ALL SELECT 'INDEXPARTITIONS'             ,INDSCHEMA                   ,INDNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.INDEXPARTITIONS
UNION ALL SELECT 'INDEXXMLPATTERNS'            ,INDSCHEMA                   ,INDNAME                 ,''                      ,TYPEMODEL         ,NULL              ,NULL               FROM SYSCAT.INDEXXMLPATTERNS
UNION ALL SELECT 'INVALIDOBJECTS'              ,OBJECTSCHEMA                ,OBJECTMODULENAME        ,''                      ,OBJECTTYPE        ,NULL              ,NULL               FROM SYSCAT.INVALIDOBJECTS
UNION ALL SELECT 'LIBRARIES'                   ,LIBSCHEMA                   ,LIBNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.LIBRARIES
UNION ALL SELECT 'LIBRARYBINDFILES'            ,LIBSCHEMA                   ,LIBNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.LIBRARYBINDFILES
UNION ALL SELECT 'LIBRARYVERSIONS'             ,LIBSCHEMA                   ,LIBNAME                 ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.LIBRARYVERSIONS
UNION ALL SELECT 'MEMBERSUBSETS'               ,''                          ,SUBSETNAME              ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.MEMBERSUBSETS
UNION ALL SELECT 'MODULEOBJECTS'               ,OBJECTSCHEMA                ,OBJECTMODULENAME        ,SPECIFICNAME            ,OBJECTTYPE        ,NULL              ,NULL               FROM SYSCAT.MODULEOBJECTS
UNION ALL SELECT 'MODULES'                     ,MODULESCHEMA                ,MODULENAME              ,''                      ,MODULETYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.MODULES
UNION ALL SELECT 'NAMEMAPPINGS'                ,LOGICAL_SCHEMA              ,LOGICAL_NAME            ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.NAMEMAPPINGS
UNION ALL SELECT 'NICKNAMES'                   ,TABSCHEMA                   ,TABNAME                 ,''                      ,REMOTE_TYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.NICKNAMES
UNION ALL SELECT 'NODEGROUPDEF'                ,''                          ,NGNAME                  ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.NODEGROUPDEF
UNION ALL SELECT 'NODEGROUPS'                  ,''                          ,NGNAME                  ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.NODEGROUPS
UNION ALL SELECT 'PACKAGES'                    ,PKGSCHEMA                   ,PKGNAME                 ,''                      ,BOUNDBYTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.PACKAGES
UNION ALL SELECT 'PERIODS'                     ,TABSCHEMA                   ,PERIODNAME              ,''                      ,PERIODTYPE        ,NULL              ,NULL               FROM SYSCAT.PERIODS
UNION ALL SELECT 'PREDICATESPECS'              ,FUNCSCHEMA                  ,FUNCNAME                ,SPECIFICNAME            ,''                ,NULL              ,NULL               FROM SYSCAT.PREDICATESPECS
UNION ALL SELECT 'PROCEDURES'                  ,PROCSCHEMA                  ,PROCNAME                ,SPECIFICNAME            ,PROGRAM_TYPE      ,CREATE_TIME       ,NULL               FROM SYSCAT.PROCEDURES
UNION ALL SELECT 'PROCPARMS'                   ,PROCSCHEMA                  ,PROCNAME                ,SPECIFICNAME            ,TYPENAME          ,NULL              ,NULL               FROM SYSCAT.PROCPARMS
UNION ALL SELECT 'REFERENCES'                  ,TABSCHEMA                   ,CONSTNAME               ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.REFERENCES
UNION ALL SELECT 'ROLES'                       ,''                          ,ROLENAME                ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.ROLES
UNION ALL SELECT 'ROUTINEOPTIONS'              ,ROUTINESCHEMA               ,ROUTINEMODULENAME       ,SPECIFICNAME            ,''                ,NULL              ,NULL               FROM SYSCAT.ROUTINEOPTIONS
UNION ALL SELECT 'ROUTINEPARMOPTIONS'          ,ROUTINESCHEMA               ,ROUTINENAME             ,SPECIFICNAME            ,''                ,NULL              ,NULL               FROM SYSCAT.ROUTINEPARMOPTIONS
UNION ALL SELECT 'ROUTINEPARMS'                ,ROUTINESCHEMA               ,ROUTINEMODULENAME       ,SPECIFICNAME            ,ROWTYPE           ,NULL              ,NULL               FROM SYSCAT.ROUTINEPARMS
UNION ALL SELECT 'ROUTINES'                    ,ROUTINESCHEMA               ,ROUTINEMODULENAME       ,SPECIFICNAME            ,ROUTINETYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.ROUTINES
UNION ALL SELECT 'ROUTINESFEDERATED'           ,ROUTINESCHEMA               ,ROUTINENAME             ,SPECIFICNAME            ,ROUTINETYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.ROUTINESFEDERATED
UNION ALL SELECT 'ROWFIELDS'                   ,TYPESCHEMA                  ,TYPEMODULENAME          ,''                      ,TYPEMODULENAME    ,NULL              ,NULL               FROM SYSCAT.ROWFIELDS
UNION ALL SELECT 'SCHEMATA'                    ,SCHEMANAME                  ,SCHEMANAME              ,''                      ,DEFINERTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.SCHEMATA
UNION ALL SELECT 'SCPREFTBSPACES'              ,''                          ,SERVICECLASSNAME        ,''                      ,DATATYPE          ,NULL              ,NULL               FROM SYSCAT.SCPREFTBSPACES
UNION ALL SELECT 'SECURITYLABELACCESS'         ,''                          ,''                      ,''                      ,GRANTEETYPE       ,NULL              ,NULL               FROM SYSCAT.SECURITYLABELACCESS
UNION ALL SELECT 'SECURITYLABELCOMPONENTS'     ,''                          ,COMPNAME                ,''                      ,COMPTYPE          ,CREATE_TIME       ,NULL               FROM SYSCAT.SECURITYLABELCOMPONENTS
UNION ALL SELECT 'SECURITYLABELS'              ,''                          ,SECLABELNAME            ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.SECURITYLABELS
UNION ALL SELECT 'SECURITYPOLICIES'            ,''                          ,SECPOLICYNAME           ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.SECURITYPOLICIES
UNION ALL SELECT 'SECURITYPOLICYCOMPONENTRULES',''                          ,READACCESSRULENAME      ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.SECURITYPOLICYCOMPONENTRULES
UNION ALL SELECT 'SECURITYPOLICYEXEMPTIONS'    ,''                          ,ACCESSRULENAME          ,''                      ,GRANTEETYPE       ,NULL              ,NULL               FROM SYSCAT.SECURITYPOLICYEXEMPTIONS
UNION ALL SELECT 'SEQUENCES'                   ,SEQSCHEMA                   ,SEQNAME                 ,''                      ,DEFINERTYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.SEQUENCES
UNION ALL SELECT 'SERVEROPTIONS'               ,''                          ,WRAPNAME                ,''                      ,SERVERTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.SERVEROPTIONS
UNION ALL SELECT 'SERVERS'                     ,''                          ,WRAPNAME                ,''                      ,SERVERTYPE        ,NULL              ,NULL               FROM SYSCAT.SERVERS
UNION ALL SELECT 'SERVICECLASSES'              ,''                          ,SERVICECLASSNAME        ,''                      ,CPUSHARETYPE      ,CREATE_TIME       ,NULL               FROM SYSCAT.SERVICECLASSES
UNION ALL SELECT 'STATEMENTS'                  ,PKGSCHEMA                   ,PKGNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.STATEMENTS
UNION ALL SELECT 'STOGROUPS'                   ,''                          ,SGNAME                  ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.STOGROUPS
UNION ALL SELECT 'SURROGATEAUTHIDS'            ,''                          ,''                      ,''                      ,TRUSTEDIDTYPE     ,NULL              ,NULL               FROM SYSCAT.SURROGATEAUTHIDS
UNION ALL SELECT 'TABCONST'                    ,TABSCHEMA                   ,CONSTNAME               ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.TABCONST
UNION ALL SELECT 'TABLES'                      ,TABSCHEMA                   ,TABNAME                 ,''                      ,TYPE              ,CREATE_TIME       ,NULL               FROM SYSCAT.TABLES
UNION ALL SELECT 'TABLESPACES'                 ,''                          ,DBPGNAME                ,''                      ,TBSPACETYPE       ,CREATE_TIME       ,NULL               FROM SYSCAT.TABLESPACES
UNION ALL SELECT 'TABOPTIONS'                  ,TABSCHEMA                   ,TABNAME                 ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.TABOPTIONS
UNION ALL SELECT 'THRESHOLDS'                  ,''                          ,THRESHOLDNAME           ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.THRESHOLDS
UNION ALL SELECT 'TRANSFORMS'                  ,TYPESCHEMA                  ,TYPENAME                ,SPECIFICNAME            ,CHAR(TYPEID)      ,NULL              ,NULL               FROM SYSCAT.TRANSFORMS
UNION ALL SELECT 'TRIGGERS'                    ,TRIGSCHEMA                  ,TRIGNAME                ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.TRIGGERS
UNION ALL SELECT 'TYPEMAPPINGS'                ,TYPESCHEMA                  ,TYPENAME                ,''                      ,TYPE_MAPPING      ,CREATE_TIME       ,NULL               FROM SYSCAT.TYPEMAPPINGS
UNION ALL SELECT 'USAGELISTS'                  ,USAGELISTSCHEMA             ,USAGELISTNAME           ,''                      ,OBJECTTYPE        ,NULL              ,NULL               FROM SYSCAT.USAGELISTS
UNION ALL SELECT 'USEROPTIONS'                 ,''                          ,SERVERNAME              ,''                      ,AUTHIDTYPE        ,NULL              ,NULL               FROM SYSCAT.USEROPTIONS
UNION ALL SELECT 'VARIABLES'                   ,VARSCHEMA                   ,VARMODULENAME           ,''                      ,TYPEMODULENAME    ,CREATE_TIME       ,NULL               FROM SYSCAT.VARIABLES
UNION ALL SELECT 'VIEWS'                       ,VIEWSCHEMA                  ,VIEWNAME                ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.VIEWS
UNION ALL SELECT 'WORKACTIONS'                 ,''                          ,ACTIONNAME              ,''                      ,ACTIONTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKACTIONS
UNION ALL SELECT 'WORKACTIONSETS'              ,''                          ,ACTIONSETNAME           ,''                      ,OBJECTTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKACTIONSETS
UNION ALL SELECT 'WORKCLASSATTRIBUTES'         ,''                          ,WORKCLASSNAME           ,''                      ,TYPE              ,NULL              ,NULL               FROM SYSCAT.WORKCLASSATTRIBUTES
UNION ALL SELECT 'WORKCLASSES'                 ,''                          ,WORKCLASSNAME           ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKCLASSES
UNION ALL SELECT 'WORKCLASSSETS'               ,''                          ,WORKCLASSSETNAME        ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKCLASSSETS
UNION ALL SELECT 'WORKLOADCONNATTR'            ,''                          ,WORKLOADNAME            ,''                      ,CONNATTRTYPE      ,NULL              ,NULL               FROM SYSCAT.WORKLOADCONNATTR
UNION ALL SELECT 'WORKLOADS'                   ,''                          ,WORKLOADNAME            ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.WORKLOADS
UNION ALL SELECT 'WRAPOPTIONS'                 ,''                          ,WRAPNAME                ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.WRAPOPTIONS
UNION ALL SELECT 'WRAPPERS'                    ,''                          ,WRAPNAME                ,''                      ,WRAPTYPE          ,NULL              ,NULL               FROM SYSCAT.WRAPPERS
UNION ALL SELECT 'XDBMAPGRAPHS'                ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.XDBMAPGRAPHS
UNION ALL SELECT 'XDBMAPSHREDTREES'            ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.XDBMAPSHREDTREES
UNION ALL SELECT 'XSROBJECTCOMPONENTS'         ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,CREATE_TIME       ,NULL               FROM SYSCAT.XSROBJECTCOMPONENTS
UNION ALL SELECT 'XSROBJECTDETAILS'            ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,''                ,NULL              ,NULL               FROM SYSCAT.XSROBJECTDETAILS
UNION ALL SELECT 'XSROBJECTHIERARCHIES'        ,SCHEMALOCATION              ,TARGETNAMESPACE         ,''                      ,HTYPE             ,NULL              ,NULL               FROM SYSCAT.XSROBJECTHIERARCHIES
UNION ALL SELECT 'XSROBJECTS'                  ,OBJECTSCHEMA                ,OBJECTNAME              ,''                      ,OBJECTTYPE        ,CREATE_TIME       ,NULL               FROM SYSCAT.XSROBJECTS

@

/*
 * Find object by tbspace-id and object-id for error messages such as SQL1477N that return object id in error
 */

CREATE OR REPLACE VIEW DB_OBJECT_IDS AS
	SELECT
	    TBSPACEID
	,   TABLEID             AS OBJECT_ID
    ,   'TABLE'             AS OBJECT_CLASS
	,   TYPE                AS OBJECT_TYPE
	,   TABSCHEMA           AS OBJECT_SCHEMA
	,   TABNAME             AS OBJECT_NAME
	FROM
	    SYSCAT.TABLES
UNION ALL 
    SELECT
        TBSPACEID
    ,   INDEX_OBJECTID      AS OBJECT_ID    
    ,   'INDEX'             AS OBJECT_CLASS 
    ,   INDEXTYPE           AS OBJECT_TYPE  
    ,   INDSCHEMA           AS OBJECT_SCHEMA
    ,   INDNAME             AS OBJECT_NAME  
    FROM
        SYSCAT.INDEXES
UNION ALL
    SELECT
        TBSPACEID
    ,   PARTITIONOBJECTID   AS OBJECT_ID    
    ,   'DATA PARTITION'    AS OBJECT_CLASS 
    ,   'RANGE'             AS OBJECT_TYPE  
    ,   DATAPARTITIONNAME   AS OBJECT_SCHEMA
    ,   TABNAME             AS OBJECT_NAME  
    FROM
        SYSCAT.DATAPARTITIONS
UNION ALL
SELECT
    TBSP_ID                 AS OBJECT_ID    
,   TAB_FILE_ID             AS OBJECT_CLASS 
,   'TEMP TABLE'            AS OBJECT_TYPE  
,   TEMPTABTYPE             AS OBJECT_SCHEMA
,   TABSCHEMA               AS OBJECT_NAME  
,   TABNAME                 
FROM
    SYSIBMADM.ADMINTEMPTABLES

@

/*
 * Lists all MON_, ENV_ and WLM_ system table functions, and generates SQL to select from them
 */

CREATE OR REPLACE VIEW DB_MONITOR_TABLE_FUNCTIONS AS
SELECT
    ROUTINESCHEMA
,   ROUTINENAME
,   SPECIFICNAME
,   'SELECT *'||                                 ' FROM TABLE( ' ||  R.ROUTINENAME || ' (' || COALESCE(PARMS,'') || '))s' AS SELECT_STAR_STMT
,   'SELECT ' || COALESCE(COLS,'*') || CHR(10) || 'FROM TABLE( ' ||  R.ROUTINENAME || ' (' || COALESCE(PARMS,'') || '))s' AS SELECT_COLS_STMT
FROM
    SYSCAT.ROUTINES R
LEFT JOIN
(   SELECT
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
    ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS)) 
              || COALESCE(
                LOWER(RTRIM(PARMNAME)) || ' =>' || CASE WHEN PARMNAME IN ('DBPARTITIONNUM') THEN ' -2' ELSE ' DEFAULT' END
            ,':'||TRIM(P.ORDINAL))
            ,', ') WITHIN GROUP ( ORDER BY P.ORDINAL)  AS PARMS
    FROM
        SYSCAT.ROUTINEPARMS P
    WHERE
        P.ROWTYPE IN ('B','O','P')
    GROUP BY
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
) P
    USING
    ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
LEFT JOIN
(   SELECT
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
    ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS)) || PARMNAME,' ,') WITHIN GROUP ( ORDER BY P.ORDINAL)  AS COLS
    FROM
        SYSCAT.ROUTINEPARMS P
    WHERE
        P.ROWTYPE IN ('R','C','S')
    AND P.PARMNAME IS NOT NULL
    GROUP BY
        ROUTINESCHEMA
    ,   ROUTINENAME
    ,   SPECIFICNAME
) P
    USING
    ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
WHERE
    R.ROUTINETYPE = 'F'
AND R.ORIGIN IN ('Q','E')
AND R.ROUTINESCHEMA = 'SYSPROC'
AND R.ROUTINENAME NOT LIKE '%\_V97%' ESCAPE '\'
AND R.ROUTINENAME NOT LIKE '%\_V91%' ESCAPE '\'
AND R.ROUTINENAME NOT LIKE 'HEALTH_'
AND SUBSTR(R.ROUTINENAME,1,5) <> 'SNAP_'

@

/*
 * Shows STMM and manual memory area changes from the db2diag.log. Set the DB_DIAG_FROM_TIMESTAMP variable to see data before today
 */

CREATE OR REPLACE VIEW DB_MEMORY_CHANGE_HISTORY AS
SELECT
    TIMESTAMP
,   MEMBER
,   MESSAGE
,   REGEXP_SUBSTR(MESSAGE,'[^"]*"([^"]*)"',1,1,'',1)::VARCHAR(128) AS NAME
,   REGEXP_SUBSTR(MESSAGE,'From:\s+"([0-9]+)"',1,1,'',1)::VARCHAR(128) AS FROM_VALUE
,   REGEXP_SUBSTR(MESSAGE,'To:\s+"([0-9]+)"',1,1,'',1)::VARCHAR(128)   AS TO_VALUE
,   AUTH_ID
,   EDUNAME
,   FUNCTION
FROM
(
    SELECT 
        REGEXP_REPLACE(
            COALESCE(
                MSG
            ,   REGEXP_SUBSTR(FULLREC,'CHANGE  : (.*)',1,1,'',1)
            ),'[\s]+',' ')::VARCHAR(256)   AS MESSAGE
    ,   T.*
    FROM
        TABLE(PD_GET_DIAG_HIST('MAIN', 'ALL','',DB_DIAG_FROM_TIMESTAMP,DB_DIAG_TO_TIMESTAMP,DB_DIAG_MEMBER)) T
    )
WHERE
    FUNCTION IN ('sqlbAlterBufferPoolAct','sqlfLogUpdateCfgParam')

@

/*
 * Shows the size of each data slice . Use to check for overall system data Skew
 */

CREATE OR REPLACE VIEW DB_MEMBER_QUICK_SIZE AS
SELECT 
    T.MEMBER
,   DECIMAL(ROUND(T.TBSP_USED_KB     / (1024 * 1024.0),3),17,3) AS USED_GB
,   DECIMAL(ROUND(T.TBSP_PAGE_TOP_KB / (1024 * 1024.0),3),17,3) AS PAGE_TOP_GB
,   DECIMAL(ROUND(T.TBSP_TOTAL_KB    / (1024 * 1024.0),3),17,3) AS TBSP_TOTAL_GB
FROM
(    SELECT
        T.MEMBER
	,   SUM(T.TBSP_PAGE_TOP    * T.TBSP_PAGE_SIZE / BIGINT(1024))  AS TBSP_PAGE_TOP_KB
	,   SUM(T.TBSP_TOTAL_PAGES * T.TBSP_PAGE_SIZE / BIGINT(1024))  AS TBSP_TOTAL_KB
	,   SUM(T.TBSP_USED_PAGES  * T.TBSP_PAGE_SIZE / BIGINT(1024))  AS TBSP_USED_KB
	FROM
        TABLE(MON_GET_TABLESPACE(NULL,-2)) T
	GROUP BY 
	    T.MEMBER
) T
@

/*
 * Shows current transaction log usage
 */

CREATE OR REPLACE VIEW DB_LOG_USED AS
SELECT * FROM (
SELECT
    MEMBER
,   DECIMAL(TOTAL_LOG_USED / ((TOTAL_LOG_AVAILABLE + TOTAL_LOG_USED) * 1.0)*100,5,2)  AS PCT_LOG_USED
,   ROW_NUMBER() OVER(ORDER BY TOTAL_LOG_USED DESC, MEMBER)     AS RANK
,   (TOTAL_LOG_AVAILABLE + TOTAL_LOG_USED)      /(1024*1024)    AS LOG_SPACE_MB
,   TOTAL_LOG_USED /(1024*1024)                                 AS LOG_USED_MB 
,   APPLID_HOLDING_OLDEST_XACT
,   FIRST_ACTIVE_LOG
,   LAST_ACTIVE_LOG
,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || APPLID_HOLDING_OLDEST_XACT || ' )'')'      AS FORCE_STATMET
FROM TABLE(MON_GET_TRANSACTION_LOG(-2))
)
--WHERE RANK < 4
@

/*
 * Shows log archive events from database history file
 */

CREATE OR REPLACE VIEW DB_LOGS_ARCHIVED AS
SELECT
    TIMESTAMP(START_TIME)               AS LOG_ARCHIVE_TS
,   H.DBPARTITIONNUM                      AS MEMBER
,   NUM_LOG_ELEMS                       AS ARCHIVED_LOG_FILE_COUNT
,   NUM_LOG_ELEMS * VALUE * 4096        AS ARCHIVED_LOG_SIZE_BYTES
--,   QUANTIZE(DECFLOAT(SUM(NUM_LOG_ELEMS * VALUE * 4096)) / POWER(2,30),.1)   AS ARCHIVED_LOG_SIZE_GBYTES
FROM SYSIBMADM.DB_HISTORY H
JOIN SYSIBMADM.DBCFG      C ON C.DBPARTITIONNUM = H.DBPARTITIONNUM 
WHERE 
    C.NAME ='logfilsiz'
AND H.OPERATION = 'X' 
AND H.OPERATIONTYPE IN ('N','P','1')
@

/*
 * Shows applications that are waiting on locks
 */

CREATE OR REPLACE VIEW DB_LOCK_WAITS AS
SELECT
    L.*
,   'call admin_cmd(''force application (' || HLD_APPLICATION_HANDLE || ')'')' AS FORCE_BLOCKER_APPLICATION_STMT 
FROM
    SYSIBMADM.MON_LOCKWAITS L
@

/*
 * Shows all current locks and lock requests on the system along with the SQL Statement holding or requesting the lock
 */

CREATE OR REPLACE VIEW DB_LOCK_STATEMENTS AS
SELECT 
    A.STMT_TEXT
,   L.*
FROM
(
    SELECT 
        T.TABSCHEMA
    ,   T.TABNAME
    ,   L.LOCK_OBJECT_TYPE     AS TYPE
    ,   L.LOCK_MODE            AS MODE
    ,   L.LOCK_STATUS          AS STATUS
    ,   SUM(L.LOCK_COUNT)      AS LOCKS
    ,   SUM(L.LOCK_HOLD_COUNT) AS WITH_HOLD     --The number of holds placed on the lock. Holds are placed on locks by cursors registered with the WITH HOLD clause and some utilities. Locks with holds are not released when transactions are committed. 
    ,   C.APPLICATION_NAME   
    ,   C.SYSTEM_AUTH_ID     AS AUTH_ID
    ,   C.CONNECTION_START_TIME
    ,   C.APPLICATION_HANDLE
    ,   'SELECT ''CALL WLM_CANCEL_ACTIVITY( '  || C.APPLICATION_HANDLE || ','' || UOW_ID || '','' || ACTIVITY_ID || '')'' FROM TABLE(MON_GET_ACTIVITY(' || C.APPLICATION_HANDLE || ',-2))' 
                                                                                        AS GEN_CANCEL_ACTIVITY_STMT
    ,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || C.APPLICATION_HANDLE || ' )'')'      AS FORCE_STATMET
    FROM
        TABLE(MON_GET_LOCKS(NULL,-2 )) L
    LEFT JOIN 
        TABLE(MON_GET_CONNECTION(NULL,-2)) C USING (APPLICATION_HANDLE, MEMBER )
    LEFT JOIN 
        SYSCAT.TABLES T 
    ON 
        L.TBSP_ID = T.TBSPACEID AND L.TAB_FILE_ID = T.TABLEID 
    GROUP BY
        T.TABSCHEMA
    ,   T.TABNAME
    ,   C.APPLICATION_NAME
    ,   C.SYSTEM_AUTH_ID
    ,   C.CONNECTION_START_TIME
    ,   L.TBSP_ID
    ,   L.TAB_FILE_ID
    ,   L.LOCK_OBJECT_TYPE
    ,   L.LOCK_MODE
    ,   L.LOCK_STATUS
    ,   C.APPLICATION_HANDLE
) L
LEFT JOIN
    ( SELECT * FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) WHERE MEMBER = COORD_PARTITION_NUM ) AS A
USING
    ( APPLICATION_HANDLE )


@

/*
 * Shows all current locks on the system (run WITH UR)
 */

CREATE OR REPLACE VIEW DB_LOCKS AS
SELECT 
    T.TABSCHEMA
,   T.TABNAME
,   LOCK_OBJECT_TYPE     AS TYPE
,   LOCK_MODE            AS MODE
,   LOCK_STATUS          AS STATUS
,   SUM(LOCK_COUNT)      AS LOCKS
,   SUM(LOCK_HOLD_COUNT) AS WITH_HOLD     --The number of holds placed on the lock. Holds are placed on locks by cursors registered with the WITH HOLD clause and some utilities. Locks with holds are not released when transactions are committed. 
,   A.APPLICATION_NAME   
,   A.SYSTEM_AUTH_ID     AS AUTH_ID
,   A.CONNECTION_START_TIME
,   A.APPLICATION_HANDLE
,   'SELECT ''CALL WLM_CANCEL_ACTIVITY( ' || A.APPLICATION_HANDLE || ','' || UOW_ID || '','' || ACTIVITY_ID || '')'' FROM TABLE(MON_GET_ACTIVITY(' || A.APPLICATION_HANDLE || ',-2))' 
                                                                                    AS GEN_CANCEL_ACTIVITY_STMT
,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || A.APPLICATION_HANDLE || ' )'')'      AS FORCE_STATMET
FROM
    TABLE(MON_GET_LOCKS(NULL,-2 )) L
LEFT JOIN 
    TABLE(MON_GET_CONNECTION(NULL,-2)) A USING (APPLICATION_HANDLE, MEMBER )
LEFT JOIN 
    SYSCAT.TABLES T 
ON 
    L.TBSP_ID = T.TBSPACEID AND L.TAB_FILE_ID = T.TABLEID 
GROUP BY
    T.TABSCHEMA
,   T.TABNAME
,   A.APPLICATION_NAME
,   A.SYSTEM_AUTH_ID
,   A.CONNECTION_START_TIME
,   SYSTEM_AUTH_ID
,   CONNECTION_START_TIME
,   TBSP_ID
,   TAB_FILE_ID
,   LOCK_OBJECT_TYPE
,   LOCK_MODE
,   LOCK_STATUS
,   A.APPLICATION_HANDLE

@

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
@

/*
 * Returns any lock escalation messages from the diag.log. Set the DB_DIAG_FROM_TIMESTAMP variable to see data before today
 */

CREATE OR REPLACE VIEW DB_LOCK_ESCALATIONS AS
SELECT
    TIMESTAMP
,   TIMEZONE
,   MEMBER
,   DBNAME
,   PID
,   SUBSTR(MSG,1,1024) MSG
FROM 
    TABLE(PD_GET_DIAG_HIST( 'MAIN', 'DX','', DB_DIAG_FROM_TIMESTAMP, DB_DIAG_TO_TIMESTAMP, DB_DIAG_MEMBER ))
WHERE FUNCTION = 'sqldEscalateLocks'
@

/*
 * Lists all rows locks on the system, and generates SQL to SELECT the locked row(s).
 */

CREATE OR REPLACE VIEW DB_LOCKED_ROWS AS
SELECT 
    F.TABSCHEMA
,   F.TABNAME
,   F.TBSP_NAME
,   COALESCE(F.RID,F.TSNID) AS RID
,   'SELECT * FROM "' || F.TABSCHEMA  || '"."' || F.TABNAME || '" AS T'
    || ' WHERE RID(T) = ' || COALESCE(F.RID,F.TSNID)
    || ' AND DATASLICEID = '  || F.DATA_PARTITION_ID
    ||' WITH UR' AS SELECT_LOCKED_ROW
,   L.LOCK_MODE            AS MODE
,   L.LOCK_STATUS          AS STATUS
,   L.LOCK_COUNT           AS LOCKS
,   L.LOCK_HOLD_COUNT      AS WITH_HOLD     --The number of holds placed on the lock. Holds are placed on locks by cursors registered with the WITH HOLD clause and some utilities. Locks with holds are not released when transactions are committed. 
,   A.APPLICATION_NAME   
,   A.SYSTEM_AUTH_ID     AS AUTH_ID
,   A.CONNECTION_START_TIME
,   A.APPLICATION_HANDLE
,   'SELECT ''CALL WLM_CANCEL_ACTIVITY( ' || A.APPLICATION_HANDLE || ','' || UOW_ID || '','' || ACTIVITY_ID || '')'' FROM TABLE(MON_GET_ACTIVITY(' || A.APPLICATION_HANDLE || ',-2))' 
                                                                                    AS GEN_CANCEL_ACTIVITY_STMT
,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || A.APPLICATION_HANDLE || ' )'')'      AS FORCE_STATMET
,   L.LOCK_NAME
FROM
    TABLE(MON_GET_LOCKS(NULL,-2 )) L
LEFT JOIN 
    TABLE(MON_GET_CONNECTION(NULL,-2)) A USING (APPLICATION_HANDLE, MEMBER )
JOIN
    LATERAL(SELECT
             MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),48)
           + MAX(CASE WHEN NAME = 'PAGEID'            THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),16) 
           + MAX(CASE WHEN NAME = 'ROWID'             THEN BIGINT(VALUE) END)   AS RID
    ,   MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN INT(VALUE) ELSE 0 END)    AS DATA_PARTITION_ID
    ,   MAX(CASE WHEN NAME = 'TABSCHEMA' THEN RTRIM(VALUE) ELSE '' END)         AS TABSCHEMA
    ,   MAX(CASE WHEN NAME = 'TABNAME'   THEN       VALUE  ELSE '' END)         AS TABNAME
    ,   MAX(CASE WHEN NAME = 'TBSP_NAME' THEN       VALUE  ELSE '' END)         AS TBSP_NAME
    ,   MAX(CASE WHEN NAME = 'TSNID'     THEN BIGINT(VALUE)  ELSE -1 END)       AS TSNID
    FROM
        TABLE(MON_FORMAT_LOCK_NAME(L.LOCK_NAME)) F
    ) F
ON 1=1
WHERE 
    L.LOCK_OBJECT_TYPE = 'ROW'

@

/*
 * Show progress on any LOAD statements
 * 
 * TO-DO, filter other utilities out (or change the name of the view...)
 */

CREATE OR REPLACE VIEW DB_LOAD_PROGRESS AS
SELECT
    SNAPSHOT_TIMESTAMP      -- TIMESTAMP   The date and time that the snapshot was taken.
,   UTILITY_ID              -- INTEGER     utility_id - Utility ID . Unique to a database partition.
,   PROGRESS_SEQ_NUM        --  INTEGER     progress_seq_num - Progress sequence number . If serial, the number of the phase. If concurrent, then could be NULL.
,   UTILITY_STATE           -- VARCHAR(16)     utility_state - Utility state . This interface returns a text identifier based on the defines in sqlmon.h
,   PROGRESS_DESCRIPTION   -- VARCHAR(2048)   progress_description - Progress description
,   PROGRESS_START_TIME    -- TIMESTAMP   progress_start_time - Progress start time . Start time if the phase has started, otherwise NULL.
--,   SUM(CASE WHEN PROGRESS_WORK_METRIC = 'BYTES' THEN PROGRESS_TOTAL_UNITS ELSE 0 END) AS BYTES
,   SUM(CASE WHEN PROGRESS_WORK_METRIC = 'ROWS'  THEN PROGRESS_TOTAL_UNITS ELSE 0 END) AS ROWS
FROM
    TABLE(SNAP_GET_UTIL_PROGRESS(-2))
GROUP BY
    SNAPSHOT_TIMESTAMP 
,   UTILITY_ID          
,   PROGRESS_SEQ_NUM    
,   UTILITY_STATE       
,   PROGRESS_DESCRIPTION
,   PROGRESS_START_TIME

@

/*
 * Show history of LOAD operations from the database history file
 */

CREATE OR REPLACE VIEW DB_LOAD_HISTORY AS
SELECT
    MIN(START_TIMESTAMP) AS START_TIMESTAMP    
,   MAX(END_TIMESTAMP)   AS END_TIMESTAMP
,   TABSCHEMA
,   TABNAME
,   LOAD_MODE
,   COMMAND
,   MIN(SQLCODE)         AS MIN_SQLCODE
,   MAX(SQLCODE)         AS MAX_SQLCODE
,   COUNT(*)             AS MEMBERS
FROM
(
    SELECT 
--    DBPARTITIONNUM
    --,   EID
        TIMESTAMP(START_TIME,0)  AS START_TIMESTAMP
    --,   SEQNUM
    ,   TIMESTAMP(END_TIME,0)    AS END_TIMESTAMP
    --,   NUM_LOG_ELEMS
    --,   FIRSTLOG
    --,   LASTLOG
    --,   BACKUP_ID
    ,   TABSCHEMA
    ,   TABNAME
    --,   COMMENT
    ,   VARCHAR(REGEXP_REPLACE(CMD_TEXT,'NODE[0-9]+','NODExxxx'),4000) AS COMMAND
    --,   NUM_TBSPS
    --,   TBSPNAMES
    --,   OPERATION
    ,   CASE OPERATIONTYPE WHEN 'I' THEN 'INSERT' WHEN 'R' THEN 'REPLACE' END AS LOAD_MODE
    --,   OBJECTTYPE
    --,   LOCATION
    --,   DEVICETYPE
    --,   ENTRY_STATUS
    --,   SQLCAID
    --,   SQLCABC
    ,   SQLCODE
    --,   SQLERRML
    --,   SQLERRMC
    --,   SQLERRP
    --,   SQLERRD1
    --,   SQLERRD2
    --,   SQLERRD3
    --,   SQLERRD4
    --,   SQLERRD5
    --,   SQLERRD6
    --,   SQLWARN
    --,   SQLSTATE
    FROM
        SYSIBMADM.DB_HISTORY
    WHERE
        OPERATION = 'L'
)
GROUP BY
    COMMAND
,   TABSCHEMA
,   TABNAME
,   LOAD_MODE

@

/*
 * Database version and release information
 */

CREATE OR REPLACE VIEW DB_LEVEL AS
SELECT
    I.SERVICE_LEVEL
,   I.FIXPACK_NUM
,   I.BLD_LEVEL
,   I.PTF
,   S.OS_NAME
,   S.OS_VERSION
,   S.OS_RELEASE
,   S.HOST_NAME          
FROM
    SYSIBMADM.ENV_INST_INFO I
INNER JOIN
    SYSIBMADM.ENV_SYS_INFO  S
ON 1=1

@

/*
 * Lists any invalid or inoperative objects
 * 
 * Note that you can call 
 *    ADMIN_REVALIDATE_DB_OBJECTS()                         -- to revalidate all objects
 *    ADMIN_REVALIDATE_DB_OBJECTS(NULL, 'MY_SCHEMA', NULL)  -- to revalidate all objects in a given schema
 *    ADMIN_REVALIDATE_DB_OBJECTS('VIEW, NULL, NULL)        -- to revalidate all objects of a given type
 *   etc
 *
 * The view generates calls that will revalidate each individual object
 */

CREATE OR REPLACE VIEW DB_INVALID_OBJECTS AS
SELECT
--    I.*
   'call ADMIN_REVALIDATE_DB_OBJECTS(''' 
    || CASE OBJECTTYPE
    WHEN 'F' THEN CASE R.ROUTINETYPE WHEN 'F' THEN 'FUNCTION' WHEN 'P' THEN 'PROCEDURE' WHEN 'M' THEN 'METHOD' END
--    WHEN 'F' THEN 
    WHEN 'v' THEN 'GLOBAL_VARIABLE'
    WHEN '2' THEN 'MASK'
    WHEN 'y' THEN 'PERMISSION'
    WHEN 'B' THEN 'TRIGGER'
    WHEN 'R' THEN 'TYPE'
    WHEN '3' THEN 'USAGELIST'
    WHEN 'V' THEN 'VIEW'
    END
    || ''',''' || OBJECTSCHEMA || ''',''' || COALESCE(I.ROUTINENAME,OBJECTNAME) || ''')' AS REVALIDATE_STMT   
,   I.*
FROM
    SYSCAT.INVALIDOBJECTS I
LEFT OUTER JOIN
    SYSCAT.ROUTINES R 
ON
    R.ROUTINESCHEMA = I.OBJECTSCHEMA
AND R.ROUTINENAME   = I.ROUTINENAME
AND R.ROUTINEMODULENAME IS NOT DISTINCT FROM I.OBJECTMODULENAME
    

@

/*
 * Lists all indexes, including the columns and data types of that make up the index.
 */

CREATE OR REPLACE VIEW DB_INDEXES AS
SELECT
    TABSCHEMA
,   TABNAME
,   INDSCHEMA
,   INDNAME
,   INDEX_COLUMN_DDL
FROM
   SYSCAT.INDEXES
JOIN
    (   SELECT
            INDSCHEMA
        ,   INDNAME
        ,   LISTAGG('"' || COLNAME || '" ' 
            || CASE
                WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                     || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                     || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
                WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                THEN TYPENAME || '(' || LENGTH || ')'  
                WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                THEN TYPENAME
                WHEN TYPENAME IN ('TIMESTAMP')
                THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                ELSE TYPENAME END 
            || CASE WHEN INLINE_LENGTH <> 0 THEN ' INLINE LENGTH ' || INLINE_LENGTH ELSE '' END
            || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS INDEX_COLUMN_DDL
        FROM
            SYSCAT.INDEXES
        JOIN
            SYSCAT.INDEXCOLUSE
        USING
            ( INDSCHEMA, INDNAME )
        JOIN
            SYSCAT.COLUMNS
        USING
            ( TABSCHEMA, TABNAME, COLNAME )
        GROUP BY
            INDSCHEMA
        ,   INDNAME
    ) AS C
USING
    ( INDSCHEMA, INDNAME )

@

/*
 *  Generates DDL for all indxes on the database
 */

CREATE OR REPLACE VIEW DB_INDEX_DDL AS
SELECT
    TABSCHEMA
,   TABNAME
,   INDSCHEMA
,   INDNAME
,     'CREATE ' 
    || CASE WHEN UNIQUERULE IN ('P', 'U') THEN 'UNIQUE ' ELSE '' END
    || 'INDEX "' || INDNAME || '" ON "' || TABNAME || '"'
    || ' (' || COLUMN_DDL || ')'
    || COALESCE('INCLUDE (' || INCLUDE_COLUMN_DDL || ')','')
    || CASE INDEXTYPE WHEN 'CLUS' THEN ' CLUSTERED' ELSE '' END 
    || CASE WHEN REVERSE_SCANS = 'Y' THEN ' ALLOW REVERSE SCANS' ELSE ' DISALLOW REVERSE SCANS' END
        AS DDL
FROM
   SYSCAT.INDEXES
JOIN
    (   SELECT
            INDSCHEMA
        ,   INDNAME
        ,   LISTAGG('"' || COLNAME || '"'
                || CASE COLORDER WHEN 'D' THEN ' DESC' ELSE '' END
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS COLUMN_DDL
        FROM
            SYSCAT.INDEXCOLUSE
        WHERE
            COLORDER <> 'I'
        GROUP BY
            INDSCHEMA
        ,   INDNAME
    ) AS C
USING
    ( INDSCHEMA, INDNAME )
LEFT JOIN
    (   SELECT
            INDSCHEMA
        ,   INDNAME
        ,   LISTAGG('"' || COLNAME || '"'
                || CASE COLORDER WHEN 'D' THEN ' DESC' ELSE '' END
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS INCLUDE_COLUMN_DDL
        FROM
            SYSCAT.INDEXCOLUSE
        WHERE
            COLORDER = 'I'
        GROUP BY
            INDSCHEMA
        ,   INDNAME
    ) AS I
USING
    ( INDSCHEMA, INDNAME )
WHERE
    INDEXTYPE IN ('CLUS', 'REG ')

@
  
/*
 * Lists all Identity columns
 * 
 *  * Note that if you have done an ALTER IDENTITY RESTART WITH
 *   but not then taken a new identity value
 *   then you won't see the new restart value via the Db2 catalog views
 *   It is in the table "packed descriptor" which db2look can access,
 *   or you could use e.g.  
 *      db2cat -p sequence -d YOURDB -s SEQ_SCHEMA -n SEQ_NAME -t | grep Restart
 *   to see the unsed RESTART value
 */

CREATE OR REPLACE VIEW DB_IDENTITY_COLUMNS AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   C.TYPENAME
,   C.NULLS
,   NEXTCACHEFIRSTVALUE
,   CACHE
,   START
,   INCREMENT
,   MINVALUE
,   MAXVALUE
,   CYCLE
--,   SEQID
FROM
     SYSCAT.COLIDENTATTRIBUTES  I
JOIN SYSCAT.COLUMNS             C  USING (TABSCHEMA, TABNAME,  COLNAME)
--JOIN SYSCAT.SEQUENCES   S  USING (SEQID)

@

/*
 * Returns a description of each DB view, function and variable
 */

CREATE OR REPLACE VIEW DB_HELP AS
SELECT
    TABNAME                 AS NAME
,   'VIEW'                  AS TYPE
,   COALESCE(REMARKS,'')    AS COMMENT
FROM    SYSCAT.TABLES WHERE TYPE = 'V' AND TABSCHEMA = CURRENT_SCHEMA
AND TABNAME LIKE 'DB\_%' ESCAPE '\'
UNION ALL
SELECT
    FUNCNAME                AS NAME
,   'FUNCTION'              AS TYPE
,   COALESCE(REMARKS,'')    AS COMMENT
FROM    SYSCAT.FUNCTIONS
WHERE
    FUNCSCHEMA = CURRENT_SCHEMA
AND FUNCNAME LIKE 'DB\_%' ESCAPE '\'
UNION ALL
SELECT
    VARNAME                 AS NAME
,   'VARIABLE'              AS TYPE
,   COALESCE(REMARKS,'')    AS COMMENT
FROM    SYSCAT.VARIABLES
WHERE 
    VARSCHEMA = CURRENT_SCHEMA
AND VARNAME LIKE 'DB\_%' ESCAPE '\'

@

/*
 * Generate ADMIN_DROP_SCHEMA statements that you can then run to drop all objects in a schema and the schema
 */

 --Generate SQL command to drop all objects in the schema and drop the schema

CREATE OR REPLACE VIEW DB_GEN_DROP_SCHEMA AS
SELECT 
    SCHEMANAME
,   'CALL SYSPROC.ADMIN_DROP_SCHEMA(' || RTRIM(SCHEMANAME) || ', NULL, ''SYSTOOLS'', ''ADMIN_DROP_SCHEMA_ERROR_TABLE'')'  AS STMT
,   'SET DB_SYSTOOLS = ''SYSTOOLS'' ' || CHR(10) || CHR(10) || 'SET DB_ADMIN_DROP_SCHEMA = ''ADMIN_DROP_SCHEMA'''         AS SETUP_STMT
,   'DROP TABLE SYSTOOLS.ADMIN_DROP_SCHEMA'  AS CLEANUP_STMT
FROM
    SYSCAT.SCHEMATA
@

/*
 * Returns the CREATE FUNCTION DDL for all user defined functions on the database
 */

CREATE OR REPLACE VIEW DB_FUNCTION_DDL AS
SELECT
    ROUTINESCHEMA   AS FUNCSCHEMA
,   ROUTINENAME     AS FUNCNAME
,   SPECIFICNAME
,   TEXT            AS DDL
FROM
    SYSCAT.ROUTINES
WHERE
    FUNCTIONTYPE = 'F'

@

/*
 * Lists all Foreign Keys in the database
 */

CREATE OR REPLACE VIEW DB_FOREIGN_KEYS AS
WITH COLS AS (
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
    ,   LISTAGG('"' || COLNAME || '"',', ') WITHIN GROUP (ORDER BY COLSEQ) AS COL_LIST
    FROM
        SYSCAT.KEYCOLUSE
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
)
SELECT
    TABSCHEMA
,   TABNAME
,   REFTABSCHEMA    AS PARENT_SCHEMA
,   REFTABNAME      AS PARENT_TABNAME
,   COL_LIST        AS CHILD_COLS
,   PARENT_COLS
,   JOIN_CLAUSE
,   ENFORCED        AS ENFORCED
,   DELETERULE
,   UPDATERULE
,   COLCOUNT
,   CONSTNAME
,   REFKEYNAME
FROM
    SYSCAT.TABCONST C
JOIN
    SYSCAT.REFERENCES
USING
    ( TABSCHEMA , TABNAME, CONSTNAME )
JOIN
    COLS
USING
    ( TABSCHEMA , TABNAME, CONSTNAME ) 
JOIN
(
    SELECT TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, CONSTNAME AS REFKEYNAME, COL_LIST AS PARENT_COLS 
    FROM COLS
)
USING
    ( REFTABSCHEMA, REFTABNAME, REFKEYNAME )
JOIN (
    SELECT 
        TABSCHEMA, TABNAME, CONSTNAME
    ,   VARCHAR(LISTAGG('C."' || COLNAME || '" = P."' || REFCOLNAME || '"', ' AND ') WITHIN GROUP (ORDER BY COLSEQ),4000) AS JOIN_CLAUSE
    FROM
          SYSCAT.REFERENCES R
    JOIN  SYSCAT.KEYCOLUSE  C USING (    TABSCHEMA,    TABNAME, CONSTNAME ) 
    JOIN  (SELECT CONSTNAME REFKEYNAME, TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, COLNAME AS REFCOLNAME, COLSEQ FROM SYSCAT.KEYCOLUSE)
                            P USING ( REFTABSCHEMA, REFTABNAME, REFKEYNAME, COLSEQ )
    GROUP BY
        TABSCHEMA, TABNAME, CONSTNAME
    )              
    USING ( CONSTNAME, TABSCHEMA, TABNAME )

@

/*
 * Generates DDL for all Foreign Keys in the database
 */

CREATE OR REPLACE VIEW DB_FOREIGN_KEY_DDL AS
WITH COLS AS (
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
    ,   LISTAGG('"' || COLNAME || '"',', ') WITHIN GROUP (ORDER BY COLSEQ) AS COL_LIST
    FROM
        SYSCAT.KEYCOLUSE
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
)
SELECT
    TABSCHEMA
,   TABNAME
,   REFTABSCHEMA    AS PARENT_SCHEMA
,   REFTABNAME      AS PARENT_TABNAME
,   'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" ADD' 
    || CASE WHEN CONSTNAME NOT LIKE 'SQL%' THEN ' CONSTRAINT "' || CONSTNAME || '"' ELSE '' END
    || ' FOREIGN KEY (' || COL_LIST || ') REFERENCES "' || REFTABSCHEMA || '"."' || REFTABNAME || '"'
    || CASE WHEN PARENT_COLS = COL_LIST THEN '' ELSE '(' || PARENT_COLS || ')' END
    || CASE ENFORCED WHEN 'Y' THEN ' ENFORCED' WHEN 'N' THEN ' NOT ENFORCED' END
    || CASE ENABLEQUERYOPT WHEN 'N' THEN ' DISABLE QUERY OPTIMIZATION' ELSE '' END
    || CASE DELETERULE WHEN 'A' THEN '' ELSE ' ON DELETE ' || CASE DELETERULE WHEN 'C' THEN 'CASCADE' WHEN 'N' THEN 'SET NULL' WHEN 'R' THEN 'RESTRICT' END END
    || CASE UPDATERULE WHEN 'A' THEN '' ELSE ' ON UPDATE RESTRICT ' END 
        AS DDL
,   CONSTNAME
,   REFKEYNAME
FROM
    SYSCAT.TABCONST C
JOIN
    SYSCAT.REFERENCES
USING
    ( TABSCHEMA , TABNAME, CONSTNAME )
JOIN
    COLS
USING
    ( TABSCHEMA , TABNAME, CONSTNAME ) 
JOIN
(
    SELECT TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, CONSTNAME AS REFKEYNAME, COL_LIST AS PARENT_COLS 
    FROM COLS
)
USING
    ( REFTABSCHEMA, REFTABNAME, REFKEYNAME )
JOIN (
    SELECT 
        TABSCHEMA, TABNAME, CONSTNAME
    ,   VARCHAR(LISTAGG('C."' || COLNAME || '" = P."' || REFCOLNAME || '"', ' AND ') WITHIN GROUP (ORDER BY COLSEQ),4000) AS JOIN_CLAUSE
    FROM
          SYSCAT.REFERENCES R
    JOIN  SYSCAT.KEYCOLUSE  C USING (    TABSCHEMA,    TABNAME, CONSTNAME ) 
    JOIN  (SELECT CONSTNAME REFKEYNAME, TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, COLNAME AS REFCOLNAME, COLSEQ FROM SYSCAT.KEYCOLUSE)
                            P USING ( REFTABSCHEMA, REFTABNAME, REFKEYNAME, COLSEQ )
    GROUP BY
        TABSCHEMA, TABNAME, CONSTNAME
    )              
    USING ( CONSTNAME, TABSCHEMA, TABNAME )
@

/*
 * Metrics about any external table statements in progress
 */

CREATE OR REPLACE VIEW DB_EXTERNAL_TABLE_PROGRESS AS
SELECT
    LOCAL_START_TIME::TIMESTAMP(0)      AS START_DATETIME
,   ROWS_INSERTED
,   ROWS_MODIFIED
,   EXT_TABLE_RECV_WAIT_TIME/1000   AS RECV_WAIT_SECS
,   EXT_TABLE_SEND_WAIT_TIME/1000   AS SEND_WAIT_SECS
--,   EXT_TABLE_RECVS_TOTAL           AS RECVS_TOTAL
,   DEC(ROUND(EXT_TABLE_RECV_VOLUME /POWER(1024.0,3),2),7,2)     AS RECV_GB   
,   DEC(ROUND(EXT_TABLE_SEND_VOLUME /POWER(1024.0,3),2),7,2)     AS SEND_GB 
,   DEC(ROUND(EXT_TABLE_READ_VOLUME /POWER(1024.0,3),2),7,2)     AS READ_GB   
,   DEC(ROUND(EXT_TABLE_WRITE_VOLUME/POWER(1024.0,3),2),7,2)     AS WRITE_GB
--,   EXT_TABLE_SENDS_TOTAL           AS SENDS_TOTAL   
,   STMT_TEXT
,   MEMBER
,   APPLICATION_HANDLE
FROM
     TABLE(MON_GET_ACTIVITY(NULL, -2)) AS T
WHERE
    EXT_TABLE_RECVS_TOTAL > 0 
OR  EXT_TABLE_SENDS_TOTAL > 0
@

/*
 * Shows information about tables referenced along in access plans in the explain tables
 */

CREATE OR REPLACE VIEW DB_EXPLAIN_TABLES AS
SELECT
    RANK() OVER(ORDER BY EXPLAIN_TIME DESC) AS SEQ
,   EXPLAIN_TIME
,   TABSCHEMA
,   TABNAME
,   D.DISTRIBUTION_KEY
,   D.DISTRIBUTION_COLUMN_COUNT
,   D.DISTRIBUTION_KEY_TYPES
,   S.ROW_COUNT      
,   S.COLUMN_COUNT   
,   S.WIDTH          
,   S.PAGES          
,   S.CREATE_TIME    
,   S.STATISTICS_TIME
,   S.DISTINCT       
,   S.TABLESPACE_NAME
FROM
(    SELECT
        EXPLAIN_TIME
    ,   OBJECT_SCHEMA        AS TABSCHEMA
    ,   OBJECT_NAME          AS TABNAME
    ,   MAX(ROW_COUNT)       AS ROW_COUNT
    ,   MAX(COLUMN_COUNT)    AS COLUMN_COUNT
    ,   MAX(WIDTH)           AS WIDTH
    ,   MAX(PAGES)           AS PAGES
    ,   MAX(CREATE_TIME)     AS CREATE_TIME
    ,   MAX(STATISTICS_TIME) AS STATISTICS_TIME
    ,   MAX(DISTINCT)        AS DISTINCT
    ,   MAX(TABLESPACE_NAME) AS TABLESPACE_NAME
    ,   MAX(OVERHEAD)                      AS OVERHEAD
    ,   MAX(TRANSFER_RATE)                 AS TRANSFER_RATE
    ,   MAX(PREFETCHSIZE)                  AS PREFETCHSIZE
    ,   MAX(EXTENTSIZE)                    AS EXTENTSIZE
    ,   MAX(CLUSTER)                       AS CLUSTER
    ,   MAX(NLEAF)                         AS NLEAF
    ,   MAX(NLEVELS)                       AS NLEVELS
    ,   MAX(FULLKEYCARD)                   AS FULLKEYCARD
    ,   MAX(OVERFLOW)                      AS OVERFLOW
    ,   MAX(FIRSTKEYCARD)                  AS FIRSTKEYCARD
    ,   MAX(FIRST2KEYCARD)                 AS FIRST2KEYCARD
    ,   MAX(FIRST3KEYCARD)                 AS FIRST3KEYCARD
    ,   MAX(FIRST4KEYCARD)                 AS FIRST4KEYCARD
    ,   MAX(SEQUENTIAL_PAGES)              AS SEQUENTIAL_PAGES
    ,   MAX(DENSITY)                       AS DENSITY
    ,   MAX(STATS_SRC)                     AS STATS_SRC
    ,   MAX(AVERAGE_SEQUENCE_GAP)          AS AVERAGE_SEQUENCE_GAP
    ,   MAX(AVERAGE_SEQUENCE_FETCH_GAP)    AS AVERAGE_SEQUENCE_FETCH_GAP
    ,   MAX(AVERAGE_SEQUENCE_PAGES)        AS AVERAGE_SEQUENCE_PAGES
    ,   MAX(AVERAGE_SEQUENCE_FETCH_PAGES)  AS AVERAGE_SEQUENCE_FETCH_PAGES
    ,   MAX(AVERAGE_RANDOM_PAGES)          AS AVERAGE_RANDOM_PAGES
    ,   MAX(AVERAGE_RANDOM_FETCH_PAGES)    AS AVERAGE_RANDOM_FETCH_PAGES
    ,   MAX(NUMRIDS)                       AS NUMRIDS
    ,   MAX(NUMRIDS_DELETED)               AS NUMRIDS_DELETED
    ,   MAX(NUM_EMPTY_LEAFS)               AS NUM_EMPTY_LEAFS
    ,   MAX(ACTIVE_BLOCKS)                 AS ACTIVE_BLOCKS
    ,   MAX(NUM_DATA_PARTS)                AS NUM_DATA_PARTS
    ,   MAX(NULLKEYS)                      AS NULLKEYS
    FROM
        SYSTOOLS.EXPLAIN_OBJECT
    WHERE
        OBJECT_TYPE IN ('TA','CO') 
    AND NOT (OBJECT_SCHEMA = 'SYSIBM' AND OBJECT_NAME LIKE 'SYN%')
    GROUP BY
       EXPLAIN_TIME, OBJECT_SCHEMA, OBJECT_NAME
) S
LEFT JOIN
(
--CREATE OR REPLACE VIEW DB_DISTRIBUTION_KEYS AS
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   LISTAGG('"' || COLNAME || '"', ', ') WITHIN GROUP (ORDER BY PARTKEYSEQ) AS DISTRIBUTION_KEY
    ,   COUNT(*)                                                AS DISTRIBUTION_COLUMN_COUNT
    ,   LISTAGG(CASE
                WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                     || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                     || CASE WHEN C.CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
                WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                THEN TYPENAME || '(' || LENGTH || ')'  
                WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                THEN TYPENAME
                WHEN TYPENAME IN ('TIMESTAMP')
                THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                ELSE TYPENAME END 
            ,   ',' ) WITHIN GROUP (ORDER BY PARTKEYSEQ )     AS DISTRIBUTION_KEY_TYPES
    FROM
        SYSCAT.TABLES T JOIN SYSCAT.COLUMNS C USING ( TABSCHEMA, TABNAME )
    WHERE 
        TYPE NOT IN ('A','N','V','W')
    AND PARTKEYSEQ > 0
    AND TABSCHEMA NOT IN ('SYSIBM')
    GROUP BY
        TABSCHEMA 
    ,   TABNAME
) AS D
USING
    (TABSCHEMA, TABNAME )

@

/*
 * Shows the Original and Optimized SQL for each statement in the explain tables
 */

CREATE OR REPLACE VIEW DB_EXPLAIN_STMT AS
SELECT
    ROW_NUMBER() OVER(ORDER BY EXPLAIN_TIME DESC) AS SEQ
,   O.TOTAL_COST        AS COST
,   O.QUERY_DEGREE      AS DEGREE
,   O.STATEMENT_TEXT    AS STMT  
,   DB_FORMAT_SQL(O.STATEMENT_TEXT)   AS STMT_FORMATED
,   P.STATEMENT_TEXT                  AS OPTIMIZED_STMT
,   DB_FORMAT_SQL(P.STATEMENT_TEXT)   AS OPTIMIZED_STMT_FORMATED
--,   PREDICATES
,   EXPLAIN_TIME
,   STMTNO
,   SECTNO
FROM SYSTOOLS.EXPLAIN_STATEMENT O
LEFT JOIN
    SYSTOOLS.EXPLAIN_STATEMENT  P
USING 
    ( EXPLAIN_TIME, STMTNO, SECTNO )
--LEFT JOIN
--(
--    SELECT
--        EXPLAIN_TIME
--    ,   STMTNO
--    ,   SECTNO
--    ,   LISTAGG(PREDICATE_ID || '/' || OPERATOR_ID || ' ' || CHAR(HOW_APPLIED,5) || ' : ' || TO_CHAR(DECIMAL(FILTER_FACTOR,7,6),'0.9999') || ' : ' || PREDICATE_TEXT, CHR(10)) 
--            WITHIN GROUP (ORDER BY PREDICATE_ID, OPERATOR_ID )  AS PREDICATES
--    FROM
--        SYSTOOLS.EXPLAIN_PREDICATE 
--    GROUP BY
--        EXPLAIN_TIME, STMTNO, SECTNO
--)
--USING
--    ( EXPLAIN_TIME, STMTNO, SECTNO )
WHERE 
    O.EXPLAIN_LEVEL = 'O'
AND P.EXPLAIN_LEVEL IN ('P','S')

@

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

@

/*
 * Lists for all event monitors on the database
 */

CREATE OR REPLACE VIEW DB_EVENT_MONITORS AS 
SELECT
    EVMONNAME
,   TARGET_TYPE
,   OWNER
,   AUTOSTART
,   CASE    EVENT_MON_STATE(EVMONNAME)
            WHEN 0 THEN '0 - Inactive'
            WHEN 1 THEN '1 - Active'
    END                                     AS STATE
,   'SET EVENT MONITOR ' || EVMONNAME || ' STATE ' || CHAR(1 - EVENT_MON_STATE(EVMONNAME))
                                              AS SWITCH_STATE_STMT
FROM
     SYSCAT.EVENTMONITORS M
@

/*
 * Generates DDL for all event monitors on the database
 * 
 * db2look does not do this https://www.ibm.com/support/pages/how-can-i-export-ddl-my-event-monitor-definitions
 *   so we need to do it ourselves
 * 
 * TO DO.  Add  DBPARTITIONNUM and target tablespace etc
 */
        
CREATE OR REPLACE VIEW DB_EVENT_MONITOR_DDL AS 
SELECT
    EVMONNAME
,   'CREATE EVENT MONITOR "' || EVMONNAME 
        || CHR(10) || '" FOR ' || E.EVENTS
        || COALESCE(' MAXFILES '   || MAXFILES,'') 
        || COALESCE(' BUFFERSIZE ' || NULLIF(BUFFERSIZE,4),'')
        || CASE WHEN    IO_MODE = 'N' THEN ' NONBLOCKED' ELSE '' END
        || CASE WHEN WRITE_MODE = 'R' THEN ' REPLACE'    ELSE '' END
        || CHR(10) || 'WRITE TO ' || CASE TARGET_TYPE WHEN 'F' THEN 'FILE ''' || TARGET || '''' 
                                                  WHEN 'P' THEN 'PIPE ''' || TARGET || ''''
                                                  WHEN 'T' THEN 'TABLE' || T.TABLES 
                                                  ELSE '' END
        || CASE AUTOSTART WHEN 'Y' THEN  CHR(10) ||  'AUTOSTART' ELSE '' END     AS DDL
FROM
     SYSCAT.EVENTMONITORS M
JOIN 
(   SELECT
        EVMONNAME
    ,   LISTAGG(TYPE
                || COALESCE(' WHERE ' || FILTER,'')
        ,', ') AS EVENTS
    FROM
        SYSCAT.EVENTS
    GROUP BY
        EVMONNAME
) E
    USING (EVMONNAME)
LEFT JOIN
(   SELECT
        EVMONNAME
    ,   CHR(10) || '    ' 
        || LISTAGG(LOGICAL_GROUP || REPEAT(' ', 30 - LENGTH(LOGICAL_GROUP))
            || COALESCE(' ( TABLE "' || RTRIM(TABSCHEMA)  || '"."' || TABNAME || '"' 
            || CASE WHEN TABOPTIONS IS NOT NULL THEN ' ' || TABOPTIONS ELSE '' END
            || CASE WHEN PCTDEACTIVATE <> 100 THEN ' PCTDEACTIVATE ' || PCTDEACTIVATE ELSE '' END
            || ')','')
        ,CHR(10) || ',   ') AS TABLES
    FROM
        SYSCAT.EVENTTABLES t 
    GROUP BY
        EVMONNAME
) T
    USING (EVMONNAME)
@

/*
 * Returns the current native encryption settings for the database
 * 
 */

CREATE OR REPLACE VIEW DB_ENCRYPTION AS
SELECT
    OBJECT_NAME AS DATABASE_NAME
,   ALGORITHM
,   ALGORITHM_MODE
,   KEY_LENGTH
,   MASTER_KEY_LABEL
,   KEYSTORE_NAME
,   KEYSTORE_TYPE
,   KEYSTORE_HOST
,   KEYSTORE_IP
,   KEYSTORE_IP_TYPE
,   PREVIOUS_MASTER_KEY_LABEL
,   AUTH_ID
,   APPL_ID
,   ROTATION_TIME          
FROM
    TABLE(SYSPROC.ADMIN_GET_ENCRYPTION_INFO())

@

/*
 * Shows the distribution key of each table with a distribution key in the database
 */

CREATE OR REPLACE VIEW DB_DISTRIBUTION_KEYS AS
SELECT
    TABSCHEMA
,   TABNAME
,   LISTAGG('"' || COLNAME || '"', ', ') WITHIN GROUP (ORDER BY PARTKEYSEQ) AS DISTRIBUTION_KEY
,   COUNT(*)                                                AS DISTRIBUTION_COLUMN_COUNT
,   LISTAGG(CASE
            WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
            THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                 || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                 || CASE WHEN C.CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
            WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
            THEN TYPENAME || '(' || LENGTH || ')'  
            WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
            THEN TYPENAME
            WHEN TYPENAME IN ('TIMESTAMP')
            THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
            WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
            THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
            WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
            THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
            WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
            ELSE TYPENAME END 
        ,   ',' ) WITHIN GROUP (ORDER BY PARTKEYSEQ )     AS DISTRIBUTION_KEY_TYPES
FROM
    SYSCAT.TABLES T JOIN SYSCAT.COLUMNS C USING ( TABSCHEMA, TABNAME )
WHERE 
    TYPE NOT IN ('A','N','V','W')
AND PARTKEYSEQ > 0
AND TABSCHEMA NOT IN ('SYSIBM')
GROUP BY
    TABSCHEMA 
,   TABNAME
@

/*
 * Shows size of table dictionaries for each table, and statistics on how they were built
 */

CREATE OR REPLACE VIEW DB_DICTIONARIES AS
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   MAX(I.BUILDER)            BUILDER
,   MAX(I.OBJECT_TYPE)        OBJECT_TYPE
,   MAX(I.BUILD_TIMESTAMP)    BUILD_TIMESTAMP
,   AVG(I.SIZE)               SIZE
,   MAX(I.ROWS_SAMPLED)       ROWS_SAMPLED
--,   PCTPAGESSAVED
--,   AVGCOMPRESSEDROWSIZE
FROM
    SYSCAT.TABLES  T
,   TABLE(ADMIN_GET_TAB_DICTIONARY_INFO( T.TABSCHEMA, T.TABNAME)) AS I
WHERE
    T.TABSCHEMA = I.TABSCHEMA
AND T.TABNAME   = I.TABNAME
AND T.TYPE NOT IN ('A','N','V','W')
AND T.TABSCHEMA NOT IN ('SYSIBM')
GROUP BY
    T.TABSCHEMA
,   T.TABNAME

@

/*
 * Shows records from Db2's diag.log file(s)
 * 
 * Note that Global Variables are used to set the time range of records returned, and from which database member
 *   These defualt to showing entires for the current date
 * If you need a different time range, set the variables like this
 *
 *   SET DB.DB_DIAG_FROM_TIMESTAMP = CURRENT_DATE - 7 DAYS      -- defaults to today
 *   SET DB.DB_DIAG_TO_TIMESTAMP   = CURRENT_TEIMSTAMP
 *   SET DB.DB_DIAG_MEMBER INTEGER = 0                          -- defaults to all members (-2)
 * 
 * Note that some diag.log entries don't populate the MSG column.
 *   For those, this view attempts to pull relevent message from the FULLREC
 * 
 */

CREATE OR REPLACE VIEW DB_DIAG AS
SELECT 
    TIMESTAMP
,   TIMEZONE
,   DBPARTITIONNUM      AS MEMBER
,   COALESCE(LEVEL,'')  AS LEVEL
,   COALESCE(IMPACT,'') AS IMPACT
,   COALESCE(MSG,REGEXP_SUBSTR(FULLREC,'((MESSAGE :)|( sqlerrmc: )|(Received sqlcode -)|(sqlcode: )|(sqluMCReadFromDevice)|(Skipping database))|(sqlsGet955DiagMessage).*')) 
        AS MSG
,   AUTH_ID 
,   FULLREC
,   RECTYPE
,   PID
,   TID
FROM TABLE(PD_GET_DIAG_HIST('MAIN', 'ALL','',DB_DIAG_FROM_TIMESTAMP,DB_DIAG_TO_TIMESTAMP,DB_DIAG_MEMBER))

@

/*
 * Db2 diag.log records with some arguably uninteresting records filtered out
 *
 * It is debatable what you should filter out when looking at the diag log
 *
 * What is below is only one persons view, from one engagement
 */
CREATE OR REPLACE VIEW DB_DIAG_FILTERED AS
SELECT * FROM DB_DIAG
WHERE  LEVEL <> 'I'
AND    RECTYPE IN ('DX' )
AND    FULLREC NOT LIKE '%Started archive for log file %'
AND    FULLREC NOT LIKE '%Client Information for lock escalation not available on non-coordinator node%'
AND    FULLREC NOT LIKE '%Extent Movement started on table space%'
AND    FULLREC NOT LIKE '%Performance metrics for extent movement%'
AND    FULLREC NOT LIKE '%The extent movement operation has moved all extents it could.%'
AND    FULLREC NOT LIKE '%TClear pool state EM_STARTED%'
AND    FULLREC NOT LIKE '%Started retrieve for log file%' 
AND    FULLREC NOT LIKE '%FUNCTION: DB2 UDB, database utilities, sqlubMWWarn,%'
AND    FULLREC NOT LIKE '%ABP_SUSPEND_TASK_PRO%'
AND    FULLREC NOT LIKE '%ABP_DELETE_TASK_PRO%'
AND    FULLREC NOT LIKE '%DIA8003C The interrupt  has been received.%'
AND    FULLREC NOT LIKE '%DSQLCA has already been built%'
AND    FULLREC NOT LIKE '%DIA8003C The interrupt  has been received%'
AND    FULLREC NOT LIKE '%ABP_SUSPEND_TASK_PRO%'  --Suspend the task processor%'
AND    FULLREC NOT LIKE '%Reorg Indexes Rolled Back%' 
AND    FULLREC NOT LIKE '%sqlrreorg_indexes%'
AND    FULLREC NOT LIKE '%FCM Automatic/Dynamic Resource Adjustment%' 
AND    FULLREC NOT LIKE '%db2HmonEvalReorg%'
AND    (    MSG IS NULL 
        OR 
        (   MSG NOT LIKE 'ADM4000W  A catalog cache overflow condition has occurred%'
        AND MSG NOT LIKE 'ADM1843I  Started retrieve for log file%'
        AND MSG NOT LIKE 'ADM1844I  Started archive for log file%'
        AND MSG NOT LIKE 'ADM1845I  Completed retrieve for log file%'
        AND MSG NOT LIKE 'ADM1846I  Completed archive for log file%'
        AND MSG NOT LIKE 'ADM5501I  The database manager is performing lock escalation%'
        AND MSG NOT LIKE 'ADM5502W  The escalation of %'  -- "nnnn" locks on table
        AND MSG NOT LIKE 'ADM9504W  Index reorganization on table%' 
        AND MSG NOT LIKE 'ADM6075W  The database has been placed in the WRITE SUSPENDED state.%'
        AND MSG NOT LIKE 'ADM6076W  The database is no longer in the WRITE SUSPEND state. %'
        AND MSG NOT LIKE 'ADM6008I  Extents within the following table space have been updated%'
        AND MSG NOT LIKE '%SQLCA has already been built%'
        AND MSG NOT LIKE '%DIA8050E Event monitor already active or inactive%'
        )
    )

@

/*
 * Show an estimate of the size of the database via summing the sizes of all the active tablespaces in MON_GET_TABLESPACE
 */

CREATE OR REPLACE VIEW DB_DB_QUICK_SIZE AS
SELECT
    CASE DBPARTITIONNUM WHEN 0 THEN 'Single-Partition Data' ELSE 'Partitioned Data' END   AS DATA_SET
,   SUM(TBSP_USED_BYTES        )/POWER(2,30) AS USED_GB
,   SUM(TBSP_FREE_BYTES        )/POWER(2,30) AS FREE_GB
,   SUM(TBSP_USABLE_BYTES      )/POWER(2,30) AS USABLE_GB
,   SUM(TBSP_TOTAL_BYTES       )/POWER(2,30) AS TOTAL_GB
,   SUM(TBSP_PAGE_TOP_BYTES    )/POWER(2,30) AS HWM_GB           -- TABLE Space high watermark
,   SUM(TBSP_PENDING_FREE_BYTES)/POWER(2,30) AS PENDING_FREE_GB  -- Pending free pages in table space
,   SUM(TBSP_MAX_PAGE_TOP_BYTES)/POWER(2,30) AS MAX_USED_GB      -- MAXimum table space page high watermark 
,   DECIMAL( (MAX(TBSP_USED_BYTES) - AVG(TBSP_USED_BYTES)) * COUNT(*) / POWER(1024.0,3),17,1) AS WASTED_GB
,   DECIMAL((1 - AVG(TBSP_PAGE_TOP_BYTES)::DECFLOAT/ NULLIF(MAX(TBSP_PAGE_TOP_BYTES),0))*100,5,2)       AS SKEW_PCT
FROM
(   SELECT
        DBPARTITIONNUM    
    ,   SUM(TBSP_USED_PAGES         * TBSP_PAGE_SIZE) AS TBSP_USED_BYTES         
    ,   SUM(TBSP_FREE_PAGES         * TBSP_PAGE_SIZE) AS TBSP_FREE_BYTES       
    ,   SUM(TBSP_USABLE_PAGES       * TBSP_PAGE_SIZE) AS TBSP_USABLE_BYTES       
    ,   SUM(TBSP_TOTAL_PAGES        * TBSP_PAGE_SIZE) AS TBSP_TOTAL_BYTES 
    ,   SUM(TBSP_PENDING_FREE_PAGES * TBSP_PAGE_SIZE) AS TBSP_PENDING_FREE_BYTES
    ,   SUM(TBSP_PAGE_TOP           * TBSP_PAGE_SIZE) AS TBSP_PAGE_TOP_BYTES
    ,   SUM(TBSP_MAX_PAGE_TOP       * TBSP_PAGE_SIZE) AS TBSP_MAX_PAGE_TOP_BYTES
    FROM
        TABLE(MON_GET_TABLESPACE(NULL,-2)) T
    GROUP BY
         DBPARTITIONNUM
) 
GROUP BY
        CASE DBPARTITIONNUM WHEN 0 THEN 'Single-Partition Data' ELSE 'Partitioned Data' END
@

/*
 * Lists all the partition groups on the database
 */

CREATE OR REPLACE VIEW DB_DB_PARTITION_GROUPS AS
SELECT
    DBPGNAME
,   LISTAGG(DBPARTITIONNUM, ',') WITHIN GROUP (ORDER BY DBPARTITIONNUM ASC) AS DATASLICES
FROM 
    SYSCAT.DBPARTITIONGROUPDEF
GROUP BY 
    DBPGNAME

@

/*
 * Shows current database manager configuration parameter values
 */

CREATE OR REPLACE VIEW DB_DBM_CFG AS
SELECT
       UPPER(NAME)      AS NAME
,      CASE WHEN VALUE_FLAGS = 'NONE' THEN '' ELSE VALUE_FLAGS END AS METHOD
,      VALUE
,      CASE WHEN NAME in ('cf_mem_sz','instance_memory','java_heap_sz' )
         THEN DECIMAL(VALUE*4/1024,11,2) END AS SIZE_MB
,      CASE WHEN VALUE <> DEFERRED_VALUE THEN SUBSTR(DEFERRED_VALUE,1,15) ELSE '' END AS DEFERRED_VAL    
,      'call admin_cmd(''UPDATE DBM CFG USING ' || UPPER(NAME) || ' ' || COALESCE(VALUE,'') 
       || CASE WHEN VALUE_FLAGS = 'AUTOMATIC' THEN ' AUTOMATIC ' ELSE '' END || ' IMMEDIATE'');' AS UPDATE_STMT
FROM
(
	SELECT 
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
	FROM
	    SYSIBMADM.DBMCFG
	GROUP BY
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
)

@

/*
 * Shows current database configuration parameter values
 */

CREATE OR REPLACE VIEW DB_DB_CFG AS
SELECT
       SUBSTR(UPPER(NAME),1,20) AS NAME
,      CASE WHEN VALUE_FLAGS = 'NONE' THEN '' ELSE VALUE_FLAGS END AS METHOD
,      VALUE
,      CASE WHEN NAME in ('app_ctl_heap_sz', 'appgroup_mem_sz', 'appl_memory', 'applheapsz', 'catalogcache_sz'
                        ,'cf_db_mem_sz', 'cf_gbp_sz', 'cf_lock_sz', 'cf_sca_sz', 'database_memory', 'dbheap'
                        , 'hadr_spool_limit', 'groupheap_ratio', 'locklist', 'logbufsz', 'mon_pkglist_sz'
                        , 'pckcachesz', 'sheapthres_shr'
                        , 'sortheap', 'stat_heap_sz', 'stmtheap', 'util_heap_sz' )
         THEN DECIMAL(VALUE*4/1024,11,2) END AS SIZE_MB
,      CASE WHEN VALUE <> DEFERRED_VALUE THEN SUBSTR(DEFERRED_VALUE,1,15) ELSE '' END AS DEFERRED_VAL    
,       MEMBERS
,      'call admin_cmd(''UPDATE DB CFG USING ' || UPPER(NAME) || ' ' || COALESCE(VALUE,'') 
       || CASE WHEN VALUE_FLAGS = 'AUTOMATIC' THEN ' AUTOMATIC ' ELSE '' END || ' IMMEDIATE'');' AS UPDATE_STMT
FROM
(
	SELECT 
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
	,   MIN(MEMBER) AS MIN_MEMBER
	,   MAX(MEMBER) AS MAX_MEMBER
	,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER)  AS MEMBERS
	,   COUNT(*)           AS MEMBER_COUNT
	,   COUNT(*) OVER()   AS ALL_MEMBER_COUNT
	FROM
	    SYSIBMADM.DBCFG
	GROUP BY
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
)

@

/*
 * Shows database configuration changes from the db2diag.log. 
 */

CREATE OR REPLACE VIEW DB_DB_CFG_CHANGE_HISTORY AS
SELECT
    TIMESTAMP
,   MEMBER
,   REGEXP_SUBSTR(MESSAGE,'[^"]*"([^"]*)"',1,1,'',1)::VARCHAR(128)        AS NAME
,   REGEXP_SUBSTR(MESSAGE,'From:\s+"\-?([0-9]+)"',1,1,'',1)::VARCHAR(128) AS FROM_VALUE
,   REGEXP_SUBSTR(MESSAGE,'To:\s+"\-?([0-9]+)"',1,1,'',1)::VARCHAR(128)   AS TO_VALUE
,   AUTH_ID
,   EDUNAME
--,   MESSAGE
FROM
(
    SELECT 
        REGEXP_REPLACE(
            COALESCE(
                MSG
            ,   REGEXP_SUBSTR(FULLREC,'CHANGE  : (.*)',1,1,'',1)
            ),'[\s]+',' ')::VARCHAR(256)   AS MESSAGE
    ,   T.*
    FROM
        TABLE(PD_GET_DIAG_HIST('MAIN', 'EI','',NULL,NULL,-2)) T
    )
WHERE
    FUNCTION IN ('sqlfLogUpdateCfgParam')
--AND     EDUNAME NOT LIKE 'db2stmm%'     -- filter out Self Tuning entries
--ORDER BY 
--    TIMESTAMP, MEMBER   DESC

@

/*
 * Lists all distribution keys that are (probably) ones that Db2 has picked automatically, rather an having been picked by a User
 */

/*
 * Returns what the default distribution key would be for each table based on an approximation of the rules
 *  used by Db2 Warehouse if no distribution key is given by the user
 * 
 * This may, or may not be the acutal distribution key on the table
 * 
 * Use with a query such as

    SELECT * FROM DB_DB2W_DEFAULT_DISTRIBUTION_KEYS 
             JOIN DB_DISTRIBUTION_KEYS USING ( TABSCHEMA, TABNAME )
    WHERE DISTRIBUTION_KEY = DEFAULT_DISTRIBUTION_KEY
    AND   DISTRIBUTION_KEY <> 'RANDOM_DISTRIBUTION_KEY'

 * to see which tables on your system are likley to have a defaulted distribution key
 * 
 * Defaulted distribution keys are rarely the most optimial key that could be picked for a given workload,
 *  and can also suffer from data skew if values in the key columns are not well distributed.
 * 
 * It can be a good idea to review these tables to manully pick better distribution keys
 *
 * Note that the code below does not take into account any Foreign Keys that were part of the CREATE TABLE DDL
 *   Columns in FKs at table creation time are also used in the full rules used by Db2 Warehouse
 */

CREATE OR REPLACE VIEW DB_DB2W_DEFAULT_DISTRIBUTION_KEYS AS 
SELECT
    TABSCHEMA
,   TABNAME
,   LISTAGG('"' || COLNAME || '"',', ') WITHIN GROUP (ORDER BY DIST_KEY_PREFERENCE_ORDER) AS DEFAULT_DISTRIBUTION_KEY
FROM
(
    SELECT ROW_NUMBER() OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY DIST_KEY_PREFERENCE) AS DIST_KEY_PREFERENCE_ORDER
    ,   *
    FROM
    (   SELECT
            TABSCHEMA
        ,   TABNAME
        ,   COLNAME
        ,   COLNO
        ,   CASE
                WHEN IDENTITY = 'Y' THEN 0
                WHEN TYPENAME = 'BIGINT'   OR (TYPENAME = 'DECIMAL' AND SCALE = 0 AND LENGTH > 10) THEN 10000 
                WHEN TYPENAME = 'INTEGER'  OR (TYPENAME = 'DECIMAL' AND SCALE = 0 AND LENGTH > 5 ) THEN 20000
                WHEN TYPENAME = 'SMALLINT' OR (TYPENAME = 'DECIMAL' AND SCALE = 0 AND LENGTH > 3 ) THEN 30000
                WHEN (TYPENAME = 'BINARY' AND LENGTH BETWEEN 4 AND 40 )
                OR   (TYPENAME = 'CHARACTER' AND ( TYPESTRINGUNITS = 'OCTETS' OR CODEPAGE = 0) AND LENGTH BETWEEN 4 AND 40 )
                OR   (TYPENAME = 'CHARACTER' AND   TYPESTRINGUNITS = 'CODEUNITS32'   AND STRINGUNITSLENGTH BETWEEN 0 AND 10 )
                OR   (TYPENAME = 'BINARY' AND LENGTH BETWEEN 4 AND 40 )
                OR   (TYPENAME LIKE '%GRAPHIC' AND  TYPESTRINGUNITS = 'CODEUNITS16'  AND STRINGUNITSLENGTH BETWEEN 2 AND 20 )
                OR   (TYPENAME LIKE '%GRAPHIC' AND  TYPESTRINGUNITS = 'CODEUNITS32'  AND STRINGUNITSLENGTH BETWEEN 0 AND 10 )
                OR   (TYPENAME = 'VARBINARY' AND LENGTH BETWEEN 4 AND 32 )
                OR   (TYPENAME = 'VARCHAR' AND ( TYPESTRINGUNITS = 'OCTETS' OR CODEPAGE = 0) AND LENGTH BETWEEN 4 AND 32 )
                OR   (TYPENAME = 'VARCHAR' AND   TYPESTRINGUNITS = 'CODEUNITS32'         AND STRINGUNITSLENGTH BETWEEN 0 AND 8 )
                                                                                                   THEN 40000
                WHEN TYPENAME IN ('TIMESTAMP','TIME')                                              THEN 50000
                ELSE                                                                                    90000
                END                                                                                    
            + CASE WHEN NULLS = 'Y'            THEN 5000 ELSE 0 END
            + CASE WHEN DEFAULT IS NULL        THEN 2000 ELSE 0 END
            + CASE WHEN GENERATED IN ('A','D') THEN 2000 ELSE 0 END
            + COLNO
                AS DIST_KEY_PREFERENCE
        FROM
            SYSCAT.COLUMNS
        WHERE TYPENAME NOT IN ('LONG VARCHAR','CLOB','DBCLOB','BLOB','XML')
        AND NOT ROWCHANGETIMESTAMP = 'Y'
    )
)
WHERE DIST_KEY_PREFERENCE_ORDER <= 3
GROUP BY
    TABSCHEMA
,   TABNAME
@

/*
 * Generates DDL for Primary and Unique Constraints
 * 
 * See db_foreign_key_ddl.sql for FK DDL
 */

CREATE OR REPLACE VIEW DB_CONSTRAINT_DDL AS
-- PKs and UKs
SELECT
    TABSCHEMA
,   TABNAME
,   CONSTNAME
,     'ALTER TABLE "' || TABNAME || '" ADD CONSTRAINT "'
    || CONSTNAME || '"'
    || CASE TYPE WHEN 'U' THEN ' UNIQUE ' WHEN 'P' THEN ' PRIMARY KEY ' END
    || ' (' || COLUMN_DDL || ')'
    || CASE WHEN ENFORCED = 'Y' THEN ' ENFORCED' WHEN ENFORCED = 'N' THEN ' NOT ENFORCED' END
    || CASE WHEN ENABLEQUERYOPT = 'Y' THEN ' ENABLE' WHEN 'N' THEN ' DISABLE' END || ' QUERY OPTIMIZATION'
        AS DDL
FROM
   SYSCAT.TABCONST
JOIN
    (   SELECT
            TABSCHEMA
        ,   TABNAME
        ,   CONSTNAME
        ,   LISTAGG('"' || COLNAME || '"'
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS COLUMN_DDL
        FROM
            SYSCAT.KEYCOLUSE
        GROUP BY
            TABSCHEMA
        ,   TABNAME
        ,   CONSTNAME
    ) AS C
USING
    ( TABSCHEMA, TABNAME, CONSTNAME )

@

/*
 * Shows the COLCARD, FREQ_VALUEs and HIGH2KEY statistics stored for each column.
 */

CREATE OR REPLACE VIEW DB_COLUMN_STATS AS
SELECT  
    C.TABSCHEMA
,   C.TABNAME
,   C.COLNAME
,   C.COLNO
,   C.COLCARD
,   D.FREQ_VALUES
,   C.NUMNULLS
,   CASE WHEN C.TYPENAME IN ('VARCHAR','LONG VARCHAR','BLOB','CLOB','GRAPHIC','VARGRAPHIC','DBCLOB')
                THEN C.AVGCOLLEN ELSE NULL END      AVGLEN
,   C.LOW2KEY
,   C.HIGH2KEY
,   HIGH2VALUE
--,   TYPE_MAX
,   CASE WHEN HIGH2VALUE > 0 THEN QUANTIZE(HIGH2VALUE / TYPE_MAX, 0.0001) END  AS PCT_OF_MAX
FROM
(   SELECT *
    ,   CASE TYPENAME 
            WHEN 'SMALLINT' THEN 32767
            WHEN 'INTEGER'  THEN 2147483647
            WHEN 'BIGINT'   THEN 9223372036854775807
            WHEN 'DECIMAL'  THEN POWER(10::DECFLOAT,LENGTH - SCALE) -1  END AS TYPE_MAX
    ,   CASE WHEN TYPENAME IN ('BIGINT','INTEGER','SMALLINT','DECIMAL','DOUBLE','REAL','DECFLOAT')
              AND HIGH2KEY IS NOT NULL 
              AND HIGH2KEY <> ''
              AND SUBSTR(HIGH2KEY,1,1) <> x'00'
             THEN DECFLOAT(HIGH2KEY) END AS HIGH2VALUE
    FROM 
        SYSCAT.COLUMNS
) C
LEFT JOIN
(
    SELECT
        D.TABSCHEMA
    ,   D.TABNAME
    ,   D.COLNAME
--    ,   STDDEV(CASE WHEN D.TYPE = 'Q' THEN D.VALCOUNT END ) AS QUARTILE_STDDEV
    ,   LISTAGG(RTRIM(D.COLVALUE) || '(' || (DECIMAL((D.VALCOUNT * 100.00) /NULLIF(T.CARD,0),5,2)) || '%)', ',')
                WITHIN GROUP (ORDER BY D.SEQNO ) AS FREQ_VALUES
    FROM
        SYSCAT.COLDIST D
    INNER JOIN
        SYSCAT.TABLES T
    ON  
        D.TABSCHEMA = T.TABSCHEMA 
    AND D.TABNAME   = T.TABNAME
    WHERE
        D.TYPE = 'F'
    AND D.VALCOUNT > -1
    GROUP BY
        D.TABSCHEMA
    ,   D.TABNAME
    ,   D.COLNAME
)   D 
ON  
    C.TABSCHEMA = D.TABSCHEMA 
AND C.TABNAME   = D.TABNAME
AND C.COLNAME   = D.COLNAME

@

/*
 * Lists all table and view columns in the database
 */

CREATE OR REPLACE VIEW DB_COLUMNS AS
SELECT  
    C.TABSCHEMA
,   C.TABNAME
,   T.TYPE
,   C.COLNAME
,   C.COLNO
,   C.COLCARD
,   C.LENGTH
,   C.STRINGUNITSLENGTH
,   CASE WHEN TYPENAME IN ('BLOB','CLOB','DCLOB') THEN INLINE_LENGTH ELSE LENGTH END
    * CASE C.TYPESTRINGUNITS WHEN 'CODEUNITS32' THEN 4 WHEN 'CODEUNITS16' THEN 2 ELSE 1 END
        AS MAX_ON_PAGE_LENGTH_BYTES
,   SCALE 
,   INLINE_LENGTH
,   NULLS
,   DEFAULT
,   HIDDEN 
FROM
    SYSCAT.COLUMNS C
INNER JOIN
    SYSCAT.TABLES T
USING
   ( TABSCHEMA, TABNAME )
@

/*
 * Lists all table function, nickname, table and view columns in the database
 */

CREATE OR REPLACE VIEW DB_COLUMNS_ALL AS
SELECT
    ROUTINESCHEMA       AS TABSCHEMA
,   ROUTINEMODULENAME   AS MODULENAME
,   ROUTINENAME         AS TABNAME
,   'F'                 AS TYPE
,   PARMNAME            AS COLNAME
,   CAST(NULL AS INTEGER)   AS COLCARD
,   ORDINAL             AS COLNO
,   LENGTH
,   STRINGUNITSLENGTH
,   SCALE 
,   CAST(NULL AS INTEGER)   AS INLINE_LENGTH
,   'Y'                     AS NULLS
,   ''                      AS DEFAULT
,   'N'                     AS HIDDEN 
,   SPECIFICNAME
,   REMARKS
FROM
    SYSCAT.ROUTINEPARMS P
WHERE
    P.ROWTYPE IN ('R','C','S')
AND P.PARMNAME IS NOT NULL
UNION ALL    
SELECT  
    C.TABSCHEMA
,   ''                  AS MODULENAME
,   C.TABNAME
,   T.TYPE
,   C.COLNAME
,   C.COLNO
,   C.COLCARD
,   C.LENGTH
,   C.STRINGUNITSLENGTH
,   SCALE 
,   INLINE_LENGTH
,   NULLS
,   DEFAULT
,   HIDDEN 
,   ''                  AS SPECIFICNAME
,   C.REMARKS
FROM
    SYSCAT.COLUMNS C
INNER JOIN
    SYSCAT.TABLES T
USING
   ( TABSCHEMA, TABNAME )
@

/*
 * Generates SQL that can be run to find max used sizes for column data-types, which can then be used to generate redesigned DDL
 */

CREATE OR REPLACE VIEW DB_COLUMN_REDESIGN AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   COLNO
,   'INSERT INTO DBT_COLUMN_REDESIGN'  AS INSERT_LINE
,   'SELECT'
    || CHR(10) || '    ''' || TABSCHEMA || ''' AS TABSCHEMA'
    || CHR(10) || ',   ''' || TABNAME   || ''' AS TABNAME'
    || CHR(10) || ',   ''' || COLNAME   || ''' AS COLNAME'
    || CHR(10) || ',   '   || COLNO     || '   AS COLNAME'
    || CHR(10) || ',   ''' || TYPESCHEMA || ''' AS TYPESCHEMA'
    || CHR(10) || ',   ''' || TYPENAME   || ''' AS TYPENAME'
    || CHR(10) || ',   '   || LENGTH     || ' AS LENGTH'
    || CHR(10) || ',   '   || SCALE      || ' AS SCALE'
    || CHR(10) || ',   ' || COALESCE('''' || TYPESTRINGUNITS   || '''','NULL') || ' AS TYPESTRINGUNITS'
    || CHR(10) || ',   ' || COALESCE(CHAR(STRINGUNITSLENGTH),'NULL') || ' AS STRINGUNITSLENGTH'
    || CHR(10) || ',   ''' || NULLS             || ''' AS NULLS'
    || CHR(10) || ',   ' || COALESCE('' || C.CODEPAGE         || '','NULL') || ' AS CODEPAGE'
    || CHR(10) || ',   COUNT(*) AS ROW_COUNT'
    || CHR(10) || ',   ' || CASE WHEN CARD < 50000000 AND (COLCARD/CARD::DECFLOAT) > .95     THEN 'COUNT(DISTINCT ' || '"' || COLNAME || '"'  || ')' ELSE 'NULL' END || ' AS DISTINCT_COUNT'
    || CHR(10) || ',   COUNT(*) - COUNT(' || '"' || COLNAME || '"'  || ') AS NULL_COUNT'
    || CHR(10) || ',   MAX(' || '"' || COLNAME || '"'  || ') AS MAX_VALUE'
    || CHR(10) || ',   MIN(' || '"' || COLNAME || '"'  || ') AS MIN_VALUE'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('SMALLINT','INTEGER','DECFLOAT','DECIMAL','FLOAT','REAL','DOUBLE')  THEN  'AVG(' || '"' || COLNAME || '"'  || ') '
                                 WHEN TYPENAME IN ('BIGINT')                                                           THEN  'AVG(DECFLOAT("' || COLNAME || '")'  || ') '
                                                         ELSE 'NULL' END || ' AS AVG_VALUE'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR','VARGRAPHIC') THEN 'MAX(LENGTH(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'MAX(LENGTH(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                 WHEN TYPENAME IN ('DECIMAL','SMALLINT','INTEGER','BIGINT','DECFLOAT' ) THEN 'MAX(BIGINT(LOG10(ABS(NULLIF(' || '"' || RTRIM(COLNAME) || '"'  || ',0))))+1)'
                                     ELSE 'NULL' END || ' AS MAX_LENGTH'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR')    AND TYPESTRINGUNITS = 'OCTETS' THEN 'MAX(LENGTH4(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER' ) AND TYPESTRINGUNITS = 'OCTETS' THEN 'MAX(LENGTH4(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                                         ELSE 'NULL' END || ' AS MAX_LENGTH4'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR','VARGRAPHIC') THEN 'MIN(LENGTH(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'MIN(LENGTH(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                                         ELSE 'NULL' END || ' AS MIN_LENGTH'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR','VARGRAPHIC') THEN 'AVG(LENGTH(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'AVG(LENGTH(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                                         ELSE 'NULL' END || ' AS AVG_LENGTH'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('DECFLOAT','FLOAT','REAL','DOUBLE') OR (TYPENAME = 'DECIMAL' AND SCALE > 0 )
                                THEN 'MAX(LENGTH(RTRIM(DECIMAL(ABS(' || '"' || COLNAME || '"'  || ') -TRUNC(ABS(' || '"' || COLNAME || '"'  || ')),31,31),''0'')) -1)' 
                      WHEN TYPENAME IN ('TIMESTAMP')                                  AND SCALE > 0 THEN 'MAX(LENGTH(RTRIM("' || COLNAME || '",''0'')) - 20)' ELSE 'NULL' END || ' AS MAX_SCALE'
--
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('CHARACTER','VARCHAR','GRAPHIC','VARGRAPHIC' ) AND C.CODEPAGE <> 0 THEN 'SUM(REGEXP_LIKE("' || COLNAME || '",''^[0-9]+$''))' ELSE 'NULL' END || ' AS ONLY_DIGITS_COUNT' 
--  trailing spaces
--  only hex values    
--  only ascii / single byte UTF-8 characters
--                     
    || CHR(10) || ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
            AS SELECT_STMT
FROM
    SYSCAT.COLUMNS C JOIN SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
WHERE
    T.TYPE NOT IN ('A','N','V','W')
AND T.TABSCHEMA NOT LIKE 'SYS%'
AND C.TYPESCHEMA NOT IN ('DB2GSE')

@

/*
 * Returns common separated lists of column names for all tables
 */

CREATE OR REPLACE VIEW DB_COLUMN_LIST AS
SELECT  
    TABSCHEMA
,   TABNAME
,   LISTAGG('"' || COLNAME || '"', ',')               WITHIN GROUP (ORDER BY COLNO)   AS COMMA_LIST
,   LISTAGG('"' || COLNAME || '"', CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNO)   AS LF_LIST
,   LISTAGG(       COLNAME       , ',')               WITHIN GROUP (ORDER BY COLNO)   AS COMMA_UNQUOTED_LIST
,   LISTAGG(       COLNAME       , CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNO)   AS LF_UNQUOTED_LIST
,   LISTAGG('"' || COLNAME || '"', ',')               WITHIN GROUP (ORDER BY COLNAME) AS COMMA_SORTED_LIST
,   LISTAGG('"' || COLNAME || '"', CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNAME) AS LF_SORTED_LIST
,   LISTAGG(       COLNAME       , ',')               WITHIN GROUP (ORDER BY COLNAME) AS COMMA_UNQUOTED_SORTED_LIST
,   LISTAGG(       COLNAME       , CHR(10) || ',   ') WITHIN GROUP (ORDER BY COLNAME) AS LF_UNQUOTED_SORTED_LIST
FROM
    SYSCAT.COLUMNS C
GROUP BY
    TABSCHEMA
,   TABNAME

@

/*
 * Shows any column group statistics that have been defined
 */

CREATE OR REPLACE VIEW DB_COLUMN_GROUPS AS
SELECT
    C.TABSCHEMA
,   C.TABNAME
,   C.COLUMNS
,   G.COLGROUPCARD
FROM
(
	SELECT  TABSCHEMA, TABNAME, COLGROUPID
	,       LISTAGG('"' || COLNAME || '"',', ') WITHIN GROUP (ORDER BY ORDINAL) AS COLUMNS
	FROM
            SYSCAT.COLGROUPCOLS
	GROUP BY
	       TABSCHEMA, TABNAME, COLGROUPID
)   AS C
INNER JOIN 
        SYSCAT.COLGROUPS G
ON
   C.COLGROUPID = G.COLGROUPID
@

/*
 * Shows the average encoded length in bytes for columns in COLUMN ORGANIZED tables
 */

CREATE OR REPLACE VIEW DB_COLUMN_ENCODING AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNO
,   COLNAME
,   CASE WHEN TYPENAME NOT IN ('CLOB','LOB','DBCLOB') THEN DECIMAL(AVGENCODEDCOLLEN,9,3) END AS AVGENCODEDCOLLEN -- Ignore spurious values for LOBs. They are not encoded in BLU.
,   PCTENCODED
,   TYPENAME
,   LENGTH
,   TYPESTRINGUNITS
,   SCALE
,   NULLS
,   AVGCOLLEN
,   QUANTIZE(AVGCOLLEN::DECFLOAT/NULLIF(AVGENCODEDCOLLEN,0) ,00.001) AS RATIO
,   AVGCOLLENCHAR
,   QUANTIZE(AVGCOLLEN::DECFLOAT/NULLIF(AVGCOLLENCHAR,0)    ,00.001) AS CHAR_RATIO
,   COLCARD
,   NUMNULLS
,   T.CARD        AS TABLE_CARD
FROM
    SYSCAT.COLUMNS 
INNER JOIN
    SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
WHERE
    T.TABLEORG = 'C'
    

@

/*
 * Generates the data type DDL text for columns. Note the DDL is UNOFFICIAL and INCOMPLETE, is provided AS-IS and Db2look might well produce something different
 */

CREATE OR REPLACE VIEW DB_COLUMN_DDL AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   COLNO
,   CASE
        WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
        THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
             || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
             || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
        WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
        THEN TYPENAME || '(' || LENGTH || ')'  
        WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
        THEN TYPENAME
        WHEN TYPENAME IN ('TIMESTAMP')
        THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
        WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
        THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
        WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
        THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
        WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
        ELSE TYPENAME END 
    || CASE WHEN INLINE_LENGTH <> 0 THEN ' INLINE LENGTH ' || INLINE_LENGTH ELSE '' END
    || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
,   CASE WHEN DEFAULT IS NOT NULL THEN ' DEFAULT ' || DEFAULT ELSE '' END        AS DEFAULT_VALUE_DDL 
,   CASE WHEN HIDDEN = 'I' THEN 'IMPLICITLY HIDDEN ' ELSE '' END                 AS OTHER_DDL
,   SUM(CASE WHEN COLNAME = 'RANDOM_DISTRIBUTION_KEY' AND HIDDEN = 'I' THEN 0 ELSE 1 END) 
        OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO)                     AS COL_SEQ
FROM
    SYSCAT.COLUMNS
@

/*
 * Shows where Db2 is configured to COLLECT ACTIVITY DATA for any activity event monitors
 *
 * Db2 can collect information about an activity by specifying COLLECT ACTIVITY DATA for any of the following
 * - service class
 * - workload
 * - work action
 * - threshold
 * 
 */

CREATE OR REPLACE VIEW DB_COLLECT_ACTIVITY AS
SELECT
    'THRESHOLD'         AS COLECTION_OBJECT_TYPE
,   THRESHOLDNAME       AS COLLECTION_OBJECT_NAME
,   COLLECTACTDATA
,   COLLECTACTPARTITION
,   'ALTER THRESHOLD "' || THRESHOLDNAME || '" COLLECT ACTIVITY DATA NONE'    AS DISABLE_DDL
FROM
    SYSCAT.THRESHOLDS
WHERE
    COLLECTACTDATA <> 'N'
UNION ALL
SELECT
    'WORKLOAD'          AS COLECTION_OBJECT_TYPE
,   WORKLOADNAME        AS COLLECTION_OBJECT_NAME
,   COLLECTACTDATA
,   COLLECTACTPARTITION
,   'ALTER WORKLOAD "' || WORKLOADNAME || '" COLLECT ACTIVITY DATA NONE' AS DISABLE_DDL
FROM
    SYSCAT.WORKLOADS
WHERE
    COLLECTACTDATA <> 'N'
UNION ALL
SELECT
    'SERVICE CLASS'     AS COLECTION_OBJECT_TYPE
,   COALESCE(PARENTSERVICECLASSNAME || '.','') || SERVICECLASSNAME  
                        AS COLLECTION_OBJECT_NAME
,   COLLECTACTDATA
,   COLLECTACTPARTITION
,   'ALTER SERVICE CLASS "' || SERVICECLASSNAME || COALESCE(' UNDER "' || PARENTSERVICECLASSNAME || '"','') || '" COLLECT ACTIVITY DATA NONE' AS DISABLE_DDL
FROM
    SYSCAT.SERVICECLASSES
WHERE
    COLLECTACTDATA <> 'N'
UNION ALL
SELECT
    'WORK ACTION'       AS COLECTION_OBJECT_TYPE
,   ACTIONSETNAME || '.'  || WORKCLASSNAME || '.'  || ACTIONNAME
                        AS COLLECTION_OBJECT_NAME
,   ACTIONTYPE AS COLLECTACTDATA            -- TO-DO, decode to be consistent with COLLECTACTDATA values
,   ACTIONTYPE AS COLLECTACTPARTITION       -- TO-DO, decode to be consistent with COLLECTACTPARTITION values
,   'ALTER WORK ACTION SET "' || WORKCLASSNAME || '" COLLECT ACTIVITY DATA NONE'    AS DISABLE_DDL
FROM SYSCAT.WORKACTIONS
WHERE 
    ACTIONTYPE IN (
        'D' -- Collect activity data with details at the coordinating member of the activity.
    ,   'F' -- Collect activity data with details, section, and values at the coordinating member of the activity.
    ,   'G' -- Collect activity details and section at the coordinating member of the activity and collect activity data at all members.
    ,   'H' -- Collect activity details, section, and values at the coordinating member of the activity and collect activity data at all members.
    ,   'S' -- Collect activity data with details and section at the coordinating member of the activity.
    ,   'V' -- Collect activity data with details and values at the coordinating member.                                          
    ,   'W' -- Collect activity data without details at the coordinating member.                                                  
    ,   'X' -- Collect activity data with details at the coordinating member and collect activity data at all members.            
    ,   'Y' -- Collect activity data with details and values at the coordinating member and collect activity data at all members. 
    ,   'Z' -- Collect activity data without details at all members.                                                              
)


@

/*
 * Helps pick suitable columns for table distribution. Generates skew check and ADMIN_MOVE_TABLE sql for all columns. Up to you to pick which column(s) to use
 */

CREATE OR REPLACE VIEW DB_CHANGE_DISTRIBUTION_KEY AS
SELECT
    C.TABSCHEMA
,   C.TABNAME
,   C.COLNAME
,   C.COLNO
,   C.PARTKEYSEQ
,   C.COLCARD
,   QUANTIZE(100 * (C.COLCARD::DECFLOAT / T.CARD)         ,00.01) AS PCT_UNIQUE
,   QUANTIZE(100 * (D.VALCOUNT::DECFLOAT/NULLIF(T.CARD,0)),00.01) AS TOP_VALUE_PERCENT
,   C.TYPENAME
,   C.NULLS
,   C.NUMNULLS
,   'call admin_move_table(''' || RTRIM(C.TABSCHEMA) ||''',''' || C.TABNAME || ''','''','''','''','''',''"' || C.COLNAME 
        || '"'','''','''',''ALLOW_READ_ACCESS'
        || CASE WHEN CARD BETWEEN 1 AND 10000
                THEN ',COPY_USE_LOAD'  -- Use LOAD on small tables to force a dictonary to be created even though the table might have fewer rows per partition than the ADC threashold
                ELSE '' END            -- Use INSERT on large tables to benefit from improved string compression in Db2W
        || ''',''MOVE'')'
        AS CHANGE_STMT
--    , 'INSERT INTO DB.DB2_DISTRIBUTION' 
,   'SELECT ''' || RTRIM(C.TABSCHEMA) || ''' TABSCHEMA ,''' 
    || C.TABNAME || ''' TABNAME ,''' || C.COLNAME || ''' COLNAMES, SLICE, COUNT(*) AS ROW_COUNT FROM (SELECT'
    || ' COALESCE(MOD(ABS(COALESCE(HASH4("' || C.COLNAME || '"),-1)),23),0) + 1 AS SLICE FROM "'
    || RTRIM(C.TABSCHEMA) || '"."' || C.TABNAME || '"'
    || ') S GROUP BY SLICE'
        AS CHECK_SQL 
FROM
    SYSCAT.COLUMNS  C
JOIN
    SYSCAT.TABLES   T
ON  
    C.TABSCHEMA = T.TABSCHEMA 
AND C.TABNAME   = T.TABNAME
LEFT OUTER JOIN
    SYSCAT.COLDIST  D
ON  
    C.TABSCHEMA = D.TABSCHEMA 
AND C.TABNAME   = D.TABNAME
AND C.COLNAME   = D.COLNAME
AND D.TYPE = 'F'
AND D.SEQNO = 1
@

/*
 * Generates LOAD RESETDICTONARY commands with appropriate table sampling clause for BLU tables. Use to "prime" a dictonary when rebuilding a column organised table
 */

CREATE OR REPLACE VIEW DB_BUILD_DICTIONARY AS
SELECT 
    TABSCHEMA
,   TABNAME
,   TBSPACE
,   PCTPAGESSAVED
,   AVG_PCTENCODED
,   CARD
,   NPAGES
,   FPAGES
,   CEIL( UNCOMPRESSED_DATA_GB / 64)  AS MODOLUS
,   DECIMAL(UNCOMPRESSED_DATA_GB,17,2) UNCOMPRESSED_DATA_GB
,   DECIMAL(UNCOMPRESSED_DATA_GB_PER_SLICE,17,2)  UNCOMPRESSED_DATA_GB_PER_SLICE
,   'CALL ADMIN_CMD(''LOAD FROM (SELECT * FROM "' || TABSCHEMA  || '"."' || TABNAME || '"' 
/* we want to sample so that no more than 128 GB of uncompressed data is sent to LOAD in on a given data slice 
 *    https://www.ibm.com/support/pages/db2-how-it-works-load-cdeanalyzefrequency-and-maxanalyzesize
 * 
 * So if a table is 5000 GBs, and we have 23 data slices, we have  values 5000 / 23 = 217 GB per slice
 *  so if we target say hitting 64 GB per partition, we want a MOD number of  VALUES CEIL(217.0 / 64)
 * 
 * However as LOAD from CURSOR is single threaded, I don't think I need the divide by # data slices, so 
*/
        || CASE WHEN UNCOMPRESSED_DATA_GB > 64  THEN ' WHERE MOD(ABS(HASH4(ROWID)),' || CEIL( UNCOMPRESSED_DATA_GB / 64) || ')=0' ELSE '' END
        || ' WITH UR) OF CURSOR MODIFIED BY CDEANALYZEFREQUENCY=100 REPLACE RESETDICTIONARYONLY INTO '
        || '"' || TABSCHEMA || '"."' || TABNAME || '_NEW" NONRECOVERABLE'')'
        AS STMT
FROM
    (SELECT *
    ,    (( NPAGES  * 32768 ) / DECFLOAT(POWER(1024,3))) * (100.0 / (100 - PCTPAGESSAVED))       AS UNCOMPRESSED_DATA_GB
    ,   ((( NPAGES  * 32768 ) / DECFLOAT(POWER(1024,3))) * (100.0 / (100 - PCTPAGESSAVED))) / 23 AS UNCOMPRESSED_DATA_GB_PER_SLICE
    FROM SYSCAT.TABLES
    ) T
JOIN
    (SELECT TABNAME, TABSCHEMA, DECIMAL(AVG(PCTENCODED),5,2) AVG_PCTENCODED FROM SYSCAT.COLUMNS GROUP BY TABNAME, TABSCHEMA ) USING (TABNAME, TABSCHEMA)
WHERE TYPE NOT IN ('A','N','V','W')
AND TABSCHEMA NOT LIKE 'SYS%'
AND T.TABLEORG = 'C'

@

/*
 * Shows config parameters relevant for BLU in DB2 10.5/11.1/11.5.0.1 and attempts to compare against best practice guidelines
 */

CREATE OR REPLACE VIEW DB_BEST_PRACTICE_BLU_CFG AS
WITH BP_BLU_CFG ( CFG_NAME, BP_VALUE, BP_MIN_VALUE, BP_MAX_VALUE, BP_COMMENT) AS ( values
    ( 'dft_table_org'      ,'COLUMN'    ,   NULL, NULL, 'Should be COLUMN' )
,   ( 'pagesize'           ,'32768'     ,   NULL, NULL, 'Should be 32K')
,   ( 'dft_extent_sz'      ,'4'         ,   NULL, NULL, 'Should be 4 pages' )
,   ( 'dft_degree'         ,'-1'        ,   NULL, NULL, 'Should be set to ANY (-1)' )
,   ( 'catalogcache_sz'    ,''          ,   NULL, NULL, 'Should be set to a value that is higher than the default (maxappls*5)')
,   ( 'maxappls'           ,'AUTOMATIC' ,   NULL, NULL, 'catalogcache_sz should be at least 5 times this value')
,   ( 'self_tuning_mem'    ,'OFF'       ,   NULL, NULL, 'Can be OFF or ON. Typically OFF')
,   ( 'sortheap'           ,NULL        ,      5,   20, 'Should be  5-20% of the value of the SHEAPTHRES_SHR parameter.')
,   ( 'sheapthres_shr'     ,NULL        ,     39,   50, 'Should be 39-50% of DATABASE_MEMORY database configuration parameter.')
--,   ( 'intra_parallel'     ,'YES'       ,   NULL, NULL, 'Should be ON, or enabled at the workload level with MAXIMUM DEGREE DEFAULT')
,   ( 'sheapthres'         ,'0'         ,   NULL, NULL, 'Keep at the default of 0. BLU sort memory is specifed with SHEAPTHRES_SHR).')
,   ( 'database_memory'    ,'AUTOMATIC' ,1000000, NULL, 'Should be AUTOMATIC and typically be 85%-90% of INSTANCE_MEMORY, and be least 1,000,000 4K pages')
,   ( 'instance_memory'    ,''          ,   NULL, NULL, 'Should be 80-90% of physical RAM. If AUTOMATIC Db2 picks at startup time 75-95% of system RAM')
,   ( 'auto_maint'         ,'ON'        ,   NULL, NULL, 'Should be ON')
,   ( 'auto_reorg'         ,'ON'        ,   NULL, NULL, 'Should be ON to enable automatic background REORG RECLAIM EXTENTS for BLU')
,   ( 'DB2_WORKLOAD'       ,'ANALYTICS' ,   NULL, NULL, 'Should be set to ANALYTICS to tell DB2 this datqabase is mostly for BLU workload')
,   ( 'util_heap_sz'       ,'AUTOMATIC' ,   NULL, NULL, '')
,   ( 'DB2_RESOURCE_POLICY','AUTOMATIC' ,   NULL, NULL, '')
,   ( 'IBMDEFAULTBP'       ,NULL        ,     20,   50, 'Should be 40% of db memory for low concurrency and 25% of db mem for high concurrency')
,   ( 'wlm_agent_load_trgt',''          ,     8,    32, 'Should be at least 8')
,   ( 'wlm_admission_ctrl' ,'YES'        ,   NULL, NULL, 'Should be on')
)
SELECT
    CASE 
		WHEN BP_VALUE = 'AUTOMATIC' AND VALUE <> 'AUTOMATIC' AND METHOD <> 'AUTOMATIC' THEN 'Should be Automatic'
		WHEN BP_MIN IS NOT NULL AND "PCT_OF_X" IS NOT NULL AND "PCT_OF_X" < DECFLOAT(BP_MIN) THEN 'Lower than advised relative size'
		WHEN BP_MAX IS NOT NULL AND "PCT_OF_X" IS NOT NULL AND "PCT_OF_X" > DECFLOAT(BP_MAX) THEN 'Higher than advised relative size'
        WHEN BP_MIN IS NOT NULL AND "PCT_OF_X" IS     NULL AND "VALUE" < DECFLOAT(BP_MIN) THEN 'Lower than advised range'
        WHEN BP_MAX IS NOT NULL AND "PCT_OF_X" IS     NULL AND "VALUE" > DECFLOAT(BP_MAX) THEN 'Higher than advised range'
		WHEN BP_MIN IS NULL AND BP_MIN IS NULL AND BP_VALUE <> METHOD AND BP_VALUE <> "VALUE" THEN 'Not Best Practice'  
		ELSE '' END AS ASSESMENT 
,   S.*
FROM
(   
    SELECT 
        CFG_TYPE 
    ,   SUBSTR(UPPER(NAME),1,20) NAME
    ,   BIGINT(SIZE)                       AS SIZE_BYTES
    ,   DECIMAL(SIZE/1024.0/1024/1024,7,2) AS SIZE_GB
    ,   CASE WHEN VALUE_FLAGS = 'NONE' THEN '' ELSE VALUE_FLAGS END AS METHOD
    ,   SUBSTR(VALUE,1,15) VALUE
    ,   CASE WHEN VALUE <> DEFERRED_VALUE THEN SUBSTR(DEFERRED_VALUE,1,15) ELSE '' END AS DEFERRED_VAL 
    ,   BP_VALUE
    ,   BP_MIN_VALUE AS BP_MIN
    ,   BP_MAX_VALUE AS BP_MAX
    ,   PCT_OF_X
    ,   BP_COMMENT 
    ,   MEMBERS
    FROM    
    (
        SELECT
            CFG_TYPE 
        ,   NAME
        ,   SIZE
        ,   VALUE_FLAGS
        ,   VALUE
        ,   DEFERRED_VALUE 
        ,   PCT_OF_X
        ,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER)  AS MEMBERS
        FROM
        (      
            SELECT
                CASE WHEN NAME IN ('mon_heap_sz','java_heap_sz','audit_buf_sz','instance_memory','sheapthres','aslheapsz','fcm_num_buffers'
                    , 'app_ctl_heap_sz', 'appgroup_mem_sz', 'appl_memory', 'applheapsz', 'catalogcache_sz'
                     ,'cf_db_mem_sz', 'cf_gbp_sz', 'cf_lock_sz', 'cf_sca_sz', 'database_memory', 'dbheap'
                     , 'hadr_spool_limit', 'groupheap_ratio', 'locklist', 'logbufsz', 'mon_pkglist_sz'
                     , 'pckcachesz', 'sheapthres_shr'
                      , 'sortheap', 'stat_heap_sz', 'stmtheap', 'util_heap_sz'  )
                     OR CFG_TYPE IN ('BP')
                     THEN BIGINT(4096) * VALUE END AS SIZE
             ,       CASE WHEN NAME   = 'sheapthres_shr' 
                          OR CFG_TYPE = 'BP' 
                          THEN DECIMAL(100 * float(value) / MAX(CASE WHEN NAME = 'database_memory' THEN VALUE END) OVER(PARTITION BY MEMBER),5,2) 
                          WHEN NAME = 'sortheap' 
                          THEN DECIMAL(100 * float(value) / MAX(CASE WHEN NAME = 'sheapthres_shr' THEN VALUE  END) OVER(PARTITION BY MEMBER),5,2) 
                      END  AS PCT_OF_X    
             ,   S.*
             FROM 
             (    SELECT 'DB CFG'  AS CFG_TYPE, S.*                                          FROM SYSIBMADM.DBCFG  S UNION ALL
                  SELECT 'DBM CFG' AS CFG_TYPE, S.*, NULL AS DBPARTITIONNUM, NULL AS MEMBER  FROM SYSIBMADM.DBMCFG S UNION ALL
                  select
                      'REGVAR'      AS CFG_TYPE
                  ,   REG_VAR_NAME  AS NAME
                  ,   REG_VAR_VALUE AS VALUE    
                  ,   ''            AS VALUE_FLAGS
                  ,   CASE WHEN REG_VAR_VALUE <> REG_VAR_ON_DISK_VALUE THEN SUBSTR(REG_VAR_ON_DISK_VALUE,1,30) ELSE '' END AS DEFERRED_VALUE
                  ,   ''            AS DEFERRED_VALUE_FLAGS
                  ,   'VARCHAR'     AS DATATYPE
                 ,    NULL AS DBPARTITIONNUM
                 ,    MEMBER
                 FROM
                    TABLE(ENV_GET_REG_VARIABLES(-2, 0))
                 UNION ALL
                   select 'BP' AS CFG_TYPE
                   , b.BPNAME AS name
                   , CHAR((B.PAGESIZE / 4096) * BIGINT(M.BP_CUR_BUFFSZ)) AS VALUE
                   ,       CASE WHEN m.AUTOMATIC = 1 then 'AUTOMATIC' ELSE '' END AS VALUE_FLAGS
                   ,       '' AS DEFERRED_VALUE
                   ,       '' AS DEFERRED_VALUE_FLAGS
                   ,       'VARCHAR' AS DATATYPE
                , null as DBPARTITIONNUM
                , m.MEMBER
                 FROM
                     TABLE(MON_GET_BUFFERPOOL( NULL, -2)) M
                 INNER JOIN SYSCAT.BUFFERPOOLS B 
                 ON
                    M.BP_NAME = B.BPNAME
             ) S
            ) S
            GROUP BY
                CFG_TYPE 
            ,   NAME
            ,   SIZE
            ,   VALUE_FLAGS
            ,   VALUE
            ,   DEFERRED_VALUE 
            ,   PCT_OF_X
     )  S           
        LEFT OUTER JOIN BP_BLU_CFG bp
     ON
        S.NAME = BP.CFG_NAME
     WHERE
         BP.CFG_NAME IS NOT NULL
     OR  S.CFG_TYPE = 'BP'
) S
@

/*
 * Lists current completed backup images from SYSIBMADM.DB_HISTORY
 */

CREATE OR REPLACE VIEW DB_BACKUPS AS
SELECT
        TIMESTAMP(START_TIME,0)                       AS START_DATETIME
,       TIMESTAMP(END_TIME,0)                         AS END_DATETIME
,             HOURS_BETWEEN(END_TIME, START_TIME)     AS HOURS
,       MOD(MINUTES_BETWEEN(END_TIME, START_TIME),60) AS MINS
,       MOD(SECONDS_BETWEEN(END_TIME, START_TIME),60) AS SECS
,       COMMENT                                       AS OPERATION
,       CASE OPERATIONTYPE
            WHEN 'D' THEN 'Delta Offline'
            WHEN 'E' THEN 'Delta Online'
            WHEN 'F' THEN 'Offline'
            WHEN 'I' THEN 'Incremental Offline'
            WHEN 'N' THEN 'Online'
            WHEN 'O' THEN 'Incremental Online'
        END                                           AS BACKUP_TYPE
,       LOCATION                                      AS BACKUP_LOCATION
,       SQLCODE
,       NUM_TBSPS
,       MEMBERS
,       TBSPNAMES   AS TABLESPACES
FROM
(   SELECT
        START_TIME
    ,   END_TIME
    ,   COMMENT
    ,   OPERATIONTYPE
    ,   LOCATION
    ,   SQLCODE
    ,   NUM_TBSPS
    ,   TBSPNAMES
    ,   LISTAGG(DBPARTITIONNUM,',') WITHIN GROUP ( ORDER BY DBPARTITIONNUM) AS MEMBERS
    FROM
	(   SELECT DISTINCT    -- Use distinct because we get duplicate entries back from DB_HISTORY
		    START_TIME
		,   END_TIME
		,   COMMENT
		,   OPERATIONTYPE
		,   LOCATION
		,   SQLCODE
		,   NUM_TBSPS
	    ,   VARCHAR(TBSPNAMES,32000) AS TBSPNAMES -- Convert the BLOB to VARCHAR to allow the aggregation
	    ,   DBPARTITIONNUM
	    FROM
	        SYSIBMADM.DB_HISTORY H
	    WHERE
	        OPERATION = 'B'
	) AS SS
       GROUP BY
        START_TIME
    ,   END_TIME
    ,   COMMENT
    ,   OPERATIONTYPE
    ,   LOCATION
    ,   SQLCODE
    ,   NUM_TBSPS
    ,   TBSPNAMES
) AS S
@

/*
 * Activities queued for processing by Db2 Automatic maintenance
 */

CREATE OR REPLACE VIEW DB_AUTO_MAINT_QUEUE AS
SELECT * FROM(
SELECT  
        QUEUE_POSITION
/*DB_DP*/,       MEMBER
,       JOB_STATUS
,       JOB_TYPE
,       OBJECT_TYPE
,       OBJECT_NAME
,       JOB_DETAILS
FROM
      TABLE(MON_GET_AUTO_MAINT_QUEUE()) AS T
ORDER BY MEMBER, QUEUE_POSITION )SS

@

/*
 * Shows how many rows per second are being returned, read, inserted etc for active applications
 */

CREATE OR REPLACE VIEW DB_APP_ROWS_PER_SEC AS
SELECT
    APPLICATION_HANDLE      AS HANDLE
,   MIN(LOCAL_START_TIME)   AS LOCAL_START_TIME
,   SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME)) AS DURATION_SEC
--,   MINUTES_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME)) AS DURATION_MIN
,   SUM(ROWS_RETURNED ) AS ROWS_RETURNED
,   SUM(ROWS_RETURNED ) / MAX(1,SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME))) AS RETURNED_PER_SEC
,   SUM(ROWS_READ    ) AS ROWS_READ
,   SUM(ROWS_READ    ) / MAX(1,SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME))) AS READ_PER_SEC
,   SUM(ROWS_INSERTED) AS ROWS_INSERTED
,   SUM(ROWS_INSERTED) / MAX(1,SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME))) AS INSERTED_PER_SEC
,   SUM(ROWS_MODIFIED) AS ROWS_MODIFIED
,   SUM(ROWS_MODIFIED) / MAX(1,SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME))) AS MODIFIED_PER_SEC
,   SUM(ROWS_UPDATED ) AS ROWS_UPDATED
,   SUM(ROWS_UPDATED ) / MAX(1,SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME))) AS UPDATES_PER_SEC
,   SUM(ROWS_DELETED ) AS ROWS_DELETED
,   SUM(ROWS_DELETED ) / MAX(1,SECONDS_BETWEEN(CURRENT_TIMESTAMP, MIN(LOCAL_START_TIME))) AS DELETED_PER_SEC
,   MAX(VARCHAR(T.STMT_TEXT,32000)) STMT_TEXT
,   MAX(COORD_STMT_EXEC_TIME)   AS COORD_STMT_EXEC_TIME
,   MAX(STMT_EXEC_TIME)         AS STMT_EXEC_TIME
FROM
    TABLE(MON_GET_ACTIVITY(NULL, -2)) AS T
WHERE
    STMT_TEXT NOT LIKE '%DB_APPL_ROWS_PER_SEC%'
GROUP BY
   APPLICATION_HANDLE

@

/*
 * Generates statements to clean up any failed ADMIN_MOVE_TABLE jobs
 */

CREATE OR REPLACE VIEW DB_ADMIN_MOVE_TABLE_CANCEL AS
/* Also see http://www-01.ibm.com/support/docview.wss?uid=swg21672377  if an ADMIN_MOVE_TABLE with CANCEL option fails
*/
SELECT 'CALL ADMIN_MOVE_TABLE (''' || TABSCHEMA || ''',''' || TABNAME || ''','''','''','''','''','''','''','''','''',''CANCEL'')' AS STMT
FROM
    SYSTOOLS.ADMIN_MOVE_TABLE
WHERE 
    KEY = 'STATUS'
AND VALUE <> 'COMPLETE'
@

/*
 * Shows current SQL activity (at a member level)
 */

/*
There are more columns in the underlying table function that I have selected.  
*/
CREATE OR REPLACE VIEW DB_ACTIVITY AS
SELECT
    LOCAL_START_TIME::TIMESTAMP(0) START_TIME
,   LAST_REFERENCE_TIME    
,   MEMBER
,   APPLICATION_HANDLE
,   ROWS_READ
,   ROWS_INSERTED
--,   ROWS_MODIFIED
,   ROWS_UPDATED
,   ROWS_DELETED
,   T.STMT_TEXT
,   EFFECTIVE_ISOLATION
,   EFFECTIVE_QUERY_DEGREE
,   CLIENT_USERID
,   CLIENT_WRKSTNNAME
,   ACTIVITY_ID
,   ACTIVITY_TYPE
,   ACTIVITY_STATE
,   APPL_ID
,   CLIENT_ACCTNG
,   CLIENT_APPLNAME
,   NUM_AGENTS
,   AGENTS_TOP
,   COORD_STMT_EXEC_TIME
,   STMT_EXEC_TIME
,   TOTAL_SECTION_TIME
,   TOTAL_SECTION_PROC_TIME
,   TOTAL_EXTENDED_LATCH_WAIT_TIME
,   TOTAL_EXTENDED_LATCH_WAITS
,   TOTAL_COL_TIME
,   TOTAL_COL_PROC_TIME
,   TOTAL_COL_EXECUTIONS
,   EXT_TABLE_RECV_WAIT_TIME
,   EXT_TABLE_RECVS_TOTAL
,   EXT_TABLE_RECV_VOLUME
,   EXT_TABLE_SENDS_TOTAL
,   EXT_TABLE_SEND_VOLUME
,   TOTAL_COL_VECTOR_CONSUMERS
,   ACTIVE_SORT_CONSUMERS_TOP
,   SORT_SHRHEAP_TOP
,   FCM_TQ_RECV_WAITS_TOTAL
,   FCM_MESSAGE_RECV_WAITS_TOTAL
,   FCM_RECV_WAITS_TOTAL
,   ESTIMATED_SORT_SHRHEAP_TOP
,   ESTIMATED_RUNTIME
FROM
    TABLE(MON_GET_ACTIVITY(NULL, -2)) AS T

@
COMMENT ON TABLE DB_ACTIVITY IS 'Shows current SQL activity (at a member level)' @
COMMENT ON TABLE DB_ADMIN_MOVE_TABLE_CANCEL IS 'Generates statements to clean up any failed ADMIN_MOVE_TABLE jobs' @
COMMENT ON TABLE DB_APP_ROWS_PER_SEC IS 'Shows how many rows per second are being returned, read, inserted etc for active applications' @
COMMENT ON TABLE DB_AUTO_MAINT_QUEUE IS 'Activities queued for processing by Db2 Automatic maintenance' @
COMMENT ON TABLE DB_BACKUPS IS 'Lists current completed backup images from SYSIBMADM.DB_HISTORY' @
COMMENT ON TABLE DB_BEST_PRACTICE_BLU_CFG IS 'Shows config parameters relevant for BLU in DB2 10.5/11.1/11.5.0.1 and attempts to compare against best practice guidelines' @
COMMENT ON TABLE DB_BUILD_DICTIONARY IS 'Generates LOAD RESETDICTONARY commands with appropriate table sampling clause for BLU tables. Use to "prime" a dictonary when rebuilding a column organised table' @
COMMENT ON TABLE DB_CHANGE_DISTRIBUTION_KEY IS 'Helps pick suitable columns for table distribution. Generates skew check and ADMIN_MOVE_TABLE sql for all columns. Up to you to pick which column(s) to use' @
COMMENT ON TABLE DB_COLLECT_ACTIVITY IS 'Shows where Db2 is configured to COLLECT ACTIVITY DATA for any activity event monitors' @
COMMENT ON TABLE DB_COLUMN_DDL IS 'Generates the data type DDL text for columns. Note the DDL is UNOFFICIAL and INCOMPLETE, is provided AS-IS and Db2look might well produce something different' @
COMMENT ON TABLE DB_COLUMN_ENCODING IS 'Shows the average encoded length in bytes for columns in COLUMN ORGANIZED tables' @
COMMENT ON TABLE DB_COLUMN_GROUPS IS 'Shows any column group statistics that have been defined' @
COMMENT ON TABLE DB_COLUMN_LIST IS 'Returns common separated lists of column names for all tables' @
COMMENT ON TABLE DB_COLUMN_REDESIGN IS 'Generates SQL that can be run to find max used sizes for column data-types, which can then be used to generate redesigned DDL' @
COMMENT ON TABLE DB_COLUMNS_ALL IS 'Lists all table function, nickname, table and view columns in the database' @
COMMENT ON TABLE DB_COLUMNS IS 'Lists all table and view columns in the database' @
COMMENT ON TABLE DB_COLUMN_STATS IS 'Shows the COLCARD, FREQ_VALUEs and HIGH2KEY statistics stored for each column.' @
COMMENT ON TABLE DB_CONSTRAINT_DDL IS 'Generates DDL for Primary and Unique Constraints' @
COMMENT ON TABLE DB_DB2W_DEFAULT_DISTRIBUTION_KEYS IS 'Lists all distribution keys that are (probably) ones that Db2 has picked automatically, rather an having been picked by a User' @
COMMENT ON TABLE DB_DB_CFG_CHANGE_HISTORY IS 'Shows database configuration changes from the db2diag.log. ' @
COMMENT ON TABLE DB_DB_CFG IS 'Shows current database configuration parameter values' @
COMMENT ON TABLE DB_DBM_CFG IS 'Shows current database manager configuration parameter values' @
COMMENT ON TABLE DB_DB_PARTITION_GROUPS IS 'Lists all the partition groups on the database' @
COMMENT ON TABLE DB_DB_QUICK_SIZE IS 'Show an estimate of the size of the database via summing the sizes of all the active tablespaces in MON_GET_TABLESPACE' @
COMMENT ON TABLE DB_DIAG_FILTERED IS 'Db2 diag.log records with some arguably uninteresting records filtered out' @
COMMENT ON TABLE DB_DIAG IS 'Shows records from Db2''s diag.log file(s)' @
COMMENT ON TABLE DB_DICTIONARIES IS 'Shows size of table dictionaries for each table, and statistics on how they were built' @
COMMENT ON TABLE DB_DISTRIBUTION_KEYS IS 'Shows the distribution key of each table with a distribution key in the database' @
COMMENT ON TABLE DB_ENCRYPTION IS 'Returns the current native encryption settings for the database' @
COMMENT ON TABLE DB_EVENT_MONITOR_DDL IS 'Generates DDL for all event monitors on the database' @
COMMENT ON TABLE DB_EVENT_MONITORS IS 'Lists for all event monitors on the database' @
COMMENT ON TABLE DB_EXPLAIN_PREDICATES IS 'Shows predicates used in an access plan, and check if the filter factors have default values' @
COMMENT ON TABLE DB_EXPLAIN_STMT IS 'Shows the Original and Optimized SQL for each statement in the explain tables' @
COMMENT ON TABLE DB_EXPLAIN_TABLES IS 'Shows information about tables referenced along in access plans in the explain tables' @
COMMENT ON TABLE DB_EXTERNAL_TABLE_PROGRESS IS 'Metrics about any external table statements in progress' @
--COMMENT ON TABLE DB_EXTERNAL_TABLES IS 'Lists all named (i.e. non transient) external tables' @
COMMENT ON TABLE DB_FOREIGN_KEY_DDL IS 'Generates DDL for all Foreign Keys in the database' @
COMMENT ON TABLE DB_FOREIGN_KEYS IS 'Lists all Foreign Keys in the database' @
COMMENT ON TABLE DB_FUNCTION_DDL IS 'Returns the CREATE FUNCTION DDL for all user defined functions on the database' @
COMMENT ON TABLE DB_GEN_DROP_SCHEMA IS 'Generate ADMIN_DROP_SCHEMA statements that you can then run to drop all objects in a schema and the schema' @
COMMENT ON TABLE DB_HELP IS 'Returns a description of each DB view, function and variable' @
COMMENT ON TABLE DB_IDENTITY_COLUMNS IS 'Lists all Identity columns' @
COMMENT ON TABLE DB_INDEX_DDL IS ' Generates DDL for all indxes on the database' @
COMMENT ON TABLE DB_INDEXES IS 'Lists all indexes, including the columns and data types of that make up the index.' @
COMMENT ON TABLE DB_INVALID_OBJECTS IS 'Lists any invalid or inoperative objects' @
COMMENT ON TABLE DB_LEVEL IS 'Database version and release information' @
COMMENT ON TABLE DB_LOAD_HISTORY IS 'Show history of LOAD operations from the database history file' @
COMMENT ON TABLE DB_LOAD_PROGRESS IS 'Show progress on any LOAD statements' @
COMMENT ON TABLE DB_LOCKED_ROWS IS 'Lists all rows locks on the system, and generates SQL to SELECT the locked row(s).' @
COMMENT ON TABLE DB_LOCK_ESCALATIONS IS 'Returns any lock escalation messages from the diag.log. Set the DB_DIAG_FROM_TIMESTAMP variable to see data before today' @
COMMENT ON TABLE DB_LOCK_MODES IS 'Describes the possible values of the LOCK_MODE_CODE column' @
COMMENT ON TABLE DB_LOCKS IS 'Shows all current locks on the system (run WITH UR)' @
COMMENT ON TABLE DB_LOCK_STATEMENTS IS 'Shows all current locks and lock requests on the system along with the SQL Statement holding or requesting the lock' @
COMMENT ON TABLE DB_LOCK_WAITS IS 'Shows applications that are waiting on locks' @
COMMENT ON TABLE DB_LOGS_ARCHIVED IS 'Shows log archive events from database history file' @
COMMENT ON TABLE DB_LOG_USED IS 'Shows current transaction log usage' @
COMMENT ON TABLE DB_MEMBER_QUICK_SIZE IS 'Shows the size of each data slice . Use to check for overall system data Skew' @
COMMENT ON TABLE DB_MEMORY_CHANGE_HISTORY IS 'Shows STMM and manual memory area changes from the db2diag.log. Set the DB_DIAG_FROM_TIMESTAMP variable to see data before today' @
COMMENT ON TABLE DB_MONITOR_TABLE_FUNCTIONS IS 'Lists all MON_, ENV_ and WLM_ system table functions, and generates SQL to select from them' @
COMMENT ON TABLE DB_OBJECT_IDS IS 'Find object by tbspace-id and object-id for error messages such as SQL1477N that return object id in error' @
COMMENT ON TABLE DB_OBJECTS IS 'Lists all objects in the catalog. Tables, Columns, Indexes etc. Essentially a UNION of all the SYSCAT catalog views' @
COMMENT ON TABLE DB_PATHS IS 'Lists file system paths used by the database' @
COMMENT ON TABLE DB_PERMISSIONS IS 'Lists and Row and Column Access Control (RCAC) permissions you have applied on the system (from SYSCAT.CONTORLS)' @
COMMENT ON TABLE DB_PRIMARY_KEY_DDL IS 'Generates DDL for all Primary Keys and Unique Constraints in the database' @
COMMENT ON TABLE DB_PRIMARY_KEYS IS 'Lists all Primary Keys in the database' @
COMMENT ON TABLE DB_PRIVILEGES IS 'Lists all the direct privileges granted on the system, including those gained via object ownership. Also include database level privileges, set session user privlies etc' @
COMMENT ON TABLE DB_PROCEDURE_DDL IS 'Returns the CREATE PROCEDURE DDL for all stored procedures on the database' @
COMMENT ON TABLE DB_PROCEDURES IS 'Lists all stored procedures on the database. Includes the parameter signature and an example CALL statement for each procedure' @
COMMENT ON TABLE DB_REBUILD_DICTIONARY IS 'Generates an ADMIN_MOVE_TABLE (AMT) that can recreate a column organized table with a new dictonary using LOAD. Generally use on SMALLish TABLES only. The table is READ ONLY while AMT runs' @
COMMENT ON TABLE DB_REGISTRY_VARIABLES IS 'Shows current database registry variables set on the database server (Db2set)' @
COMMENT ON TABLE DB_RUNSTATS_LOG IS 'Shows auto and manual runstats history from the db2optstats log. Defaults to entries for the current day' @
COMMENT ON TABLE DB_RUNSTATS_QUEUE IS 'Shows runstats queued for processing by Db2 Automatic maintenance or real-time stats' @
COMMENT ON TABLE DB_RUNSTATS IS 'Generate runstats commands' @
COMMENT ON TABLE DB_SCALAR_FUNCTIONS IS 'Lists all scalar functions in the database' @
COMMENT ON TABLE DB_SCHEMAS IS 'Lists all schemas in the database' @
COMMENT ON TABLE DB_SEQUENCES IS 'Lists all Sequences' @
COMMENT ON TABLE DB_SERVERS IS 'Lists all Federated Servers created on the database' @
COMMENT ON TABLE DB_SERVICE_CLASS_DDL IS 'WLM Workload DDL ' @
COMMENT ON TABLE DB_SERVICE_CLASSES IS 'WLM Service Classes ' @
COMMENT ON TABLE DB_SESSION_VARIABLES IS 'List special registers, current application id and other session level variables' @
COMMENT ON TABLE DB_SORTHEAP_USAGE IS 'Current SQL by sortheap usage' @
COMMENT ON TABLE DB_SORTS_CURRENT IS 'Shows tops sort consuming current queries' @
COMMENT ON TABLE DB_SORTS_STATEMENT IS 'Shows tops sort consuming statements from the package cache' @
COMMENT ON TABLE DB_SQLCODE IS 'Use to lookup the full description of an SQLCODE error message' @
COMMENT ON TABLE DB_SQLSTATE IS 'Use to lookup the full description of an SQLSTATE error message' @
COMMENT ON TABLE DB_STATISTICAL_VIEWS IS 'List all views that are enabled for query optimization' @
COMMENT ON TABLE DB_STATS_PROFILES IS 'List all views that are enabled for query optimization' @
COMMENT ON TABLE DB_STATUS IS 'Activation/quiesce status of database members. Shows if database is explicitly activated and last activation time' @
COMMENT ON TABLE DB_STMT_CACHE IS 'Returns data from the package cache. Shows recently executed SQL statements' @
COMMENT ON TABLE DB_STORAGE IS 'Shows the total used and available size of the storage paths available to the database' @
COMMENT ON TABLE DB_SYNOPSIS_SIZE IS 'Shows the size of each Synopsis table created for each Column Organized Table' @
COMMENT ON TABLE DB_SYNOPSIS_TABLES IS 'Shows the Synopsis table name for each column organized table' @
COMMENT ON TABLE DB_TABLE_ACTIVITY IS 'Table activity metrics such as rows read and number of table scans' @
COMMENT ON TABLE DB_TABLE_FUNCTION_COLUMNS IS 'Lists all table function columns in the database' @
COMMENT ON TABLE DB_TABLE_FUNCTIONS IS 'Lists all table functions, and generates SQL to select from them' @
COMMENT ON TABLE DB_TABLE_LAST_UPDATED_ESTIMATE IS 'Provide a (possibly inaccurate) estimate of when a table might have last been updated' @
COMMENT ON TABLE DB_TABLE_QUICK_DDL IS 'Generates quick DDL for tables. Provided AS-IS. It is accurate for most simple tables. Does not include FKs, generated column expression or support range partitioned and MDC tables or other complex DDL structure' @
COMMENT ON TABLE DB_TABLE_QUICK_SIZE IS 'Returns the size of each table. For tables not touched since the last Db2 restart, the size is an estimate based on catalog statistics' @
COMMENT ON TABLE DB_TABLE_QUICK_SKEW IS 'Shows the data skew of database partitioned tables. Only shows data for tables touched since the last Db2 restart' @
COMMENT ON TABLE DB_TABLE_QUICK_SPARSITY IS 'Returns a simplistic estimate of how the size of each table compares to what you might expect given the column encoding rates' @
COMMENT ON TABLE DB_TABLE_SIZE IS 'Returns an accurate size of each table using ADMIN_GET_TAB_INFO(). The view can be slow to return on large systems if you don''t filter' @
COMMENT ON TABLE DB_TABLE_SKEW IS 'Shows the data skew of database partitioned tables.' @
COMMENT ON TABLE DB_TABLESPACE_ACTIVITY IS 'Tablespace activity metrics using same SQL as dsmtop tablespaces screen' @
COMMENT ON TABLE DB_TABLESPACE_QUICK_SIZE IS 'Returns the size of each tablespaces that has been touched since the last Db2 restart' @
COMMENT ON TABLE DB_TABLESPACE_QUICK_SKEW IS 'Shows any data skew at the tablespace level. Only shows data for tablespaces touched since the last Db2 restart' @
COMMENT ON TABLE DB_TABLESPACE_REDUCE_PROGRESS IS 'Reports of the progress of any background extent movement such as as initiated by ALTER TABLESPACE REDUE MAX' @
COMMENT ON TABLE DB_TABLESPACES IS 'Lists tablespaces showing page size, max size (if set) etc' @
COMMENT ON TABLE DB_TABLES IS 'Tables, Views, Nicknames, MQTs and other objects from the SYSCAT.TABLES catalog view ' @
COMMENT ON TABLE DB_TABLE_STATISTICS IS 'Shows table statistics and rows modified since last runstats' @
COMMENT ON TABLE DB_TABLE_STATUS IS 'Shows if a table is in a non NORMAL status' @
COMMENT ON TABLE DB_TEMPORAL_TABLES IS 'Lists all temporal tables ' @
COMMENT ON TABLE DB_TEMP_SPACE IS 'Shows current system and user temporary tablespace usage by user' @
COMMENT ON TABLE DB_TEMP_TABLE_QUICK_DDL IS 'Simple DDL generator for DB2 Declared Global Temp Tables' @
COMMENT ON TABLE DB_TEMP_TABLES IS 'Lists user CREATEd and DECLAREd global temporary tables' @
COMMENT ON TABLE DB_THRESHOLDS IS 'WLM Thresholds ' @
COMMENT ON TABLE DB_THRESHOLD_TYPES IS 'Lists all possible WLM threshold types' @
COMMENT ON TABLE DB_UPTIME IS 'Shows last time the database members were last restarted' @
COMMENT ON TABLE DB_USER_WORKLOADS IS 'Returns a count of activity by User and Workload' @
COMMENT ON TABLE DB_VIEW_DDL IS 'Returns the DDL used to create VIEWs' @
COMMENT ON TABLE DB_VIEW_TABLE_DDL IS 'Returns CREATE TABLE DDL that corresponds to the column definitions of VIEWs' @
COMMENT ON TABLE DB_VIEW_TABLE_IMPROVED_DDL IS 'Returns CREATE TABLE DDL that coresponds to the colum definitions of VIEWs but with NOT NULL used for columns without NULL values' @
COMMENT ON TABLE DB_WLM_ACTIVITY IS 'Returns Work Load Management metrics by current activity' @
COMMENT ON TABLE DB_WLM_ACTIVITY_STATE IS 'Current coordinator activity by status and whether the query bypassed the adaptive workload manager' @
COMMENT ON TABLE DB_WLM_CONFIG IS 'Provides a denormalized view of your WLM configuration' @
COMMENT ON TABLE DB_WLM_CONSTRAINED_RESOURCE IS 'Shows the most constrained WLM resource (threads vs sort)' @
COMMENT ON TABLE DB_WLM_MEMORY_CONSUMPTION IS 'Shows memory consumption of currently executing queries on the most constrained partition' @
COMMENT ON TABLE DB_WLM_QUEUED_ACTIVITY IS 'Shows currently queued queries and estimated sortheap requirements ' @
COMMENT ON TABLE DB_WLM_QUEUED_STATEMENTS IS 'Shows any queries in the package cache that have been queue do to WLM concurrency limits ' @
COMMENT ON TABLE DB_WLM_QUEUING_SUMMARY IS 'Shows percentage of statements queued and queue time at a database member level' @
COMMENT ON TABLE DB_WLM_THREAD_CONSUMPTION IS 'Shows thread/agent consumption of currently executing queries on the most constrained partition' @
COMMENT ON TABLE DB_WORKLOAD_ACTIVITY IS 'Shows total rows read etc by Workload defined on the database' @
COMMENT ON TABLE DB_WORKLOAD_DDL IS 'WLM Workload DDL ' @
COMMENT ON TABLE DB_WORKLOADS IS 'WLM Workloads ' @
COMMENT ON FUNCTION DB_BASE64_DECODE IS 'Converts a Base64 string into a binary value' @
COMMENT ON FUNCTION DB_BASE64_ENCODE IS 'Converts a binary value into a Base64 text string' @
COMMENT ON FUNCTION DB_BINARY_TO_CHARACTER IS 'Converts a BINARY value to a character string. I.e. removes the FOR BIT DATA tag from a binary string' @
COMMENT ON FUNCTION DB_CHR IS 'Converts ASCII Latin-9 decimal code values to a UTF-8 value. A Netezza compatible version of CHR.' @
COMMENT ON FUNCTION DB_CYYDDD_TO_DATE IS 'Returns a DATE from a JD Edwards "Julian" date integer in CYYDDD format' @
COMMENT ON FUNCTION DB_CYYMMDD_TO_DATE IS 'Returns a DATE from a date integer in CYYMMDD format' @
COMMENT ON FUNCTION DB_EXTRACT_SPECIAL_CHARACTERS IS 'Shows the first 4 runs of characters that are not "plain" printable 7-bit ASCII values' @
COMMENT ON FUNCTION DB_FORMAT_SQL IS 'A very simple SQL formatter - adds line-feeds before various SQL keywords and characters to the passed SQL code' @
COMMENT ON FUNCTION DB_GREEK_TO_LATIN IS 'Replaces Greek characters with Latin equivalents' @
COMMENT ON FUNCTION DB_INSERT_RANGE IS 'Returns the insert range number of a row on a COLUMN organized table when passed the RID_BIT() function ' @
COMMENT ON FUNCTION DB_IS_ASCII IS 'Returns 1 if the input string only contains 7-bit ASCII characters, otherwise returns 0.' @
COMMENT ON FUNCTION DB_IS_BIGINT IS 'Returns 1 is the input string can be CAST to an BIGINT, else returns 0' @
COMMENT ON FUNCTION DB_IS_DATE IS 'Returns 1 if the input string can be CAST to a DATE, else returns 0' @
COMMENT ON FUNCTION DB_IS_DECFLOAT IS 'Returns 1 is the input string can be CAST to a DECFLOAT, else returns 0' @
COMMENT ON FUNCTION DB_IS_DECIMAL IS 'Returns 1 is the input string can be CAST to a DECIMAL(31,8), else returns 0' @
COMMENT ON FUNCTION DB_IS_INTEGER IS 'Returns 1 is the input string can be CAST to an INTEGER, else returns 0' @
COMMENT ON FUNCTION DB_IS_LATIN1 IS 'Returns 1 if the input string only holds characters from the ISO-8859-1 (aka Latin-1) codepage, else returns 0' @
COMMENT ON FUNCTION DB_IS_LATIN9 IS 'Returns 1 if the input string only holds characters from the ISO-8859-15 (aka Latin-9) codepage, else returns 0' @
COMMENT ON FUNCTION DB_IS_SMALLINT IS 'Returns 1 if the input string can be CAST to an SMALLINT, else returns 0' @
COMMENT ON FUNCTION DB_IS_TIME IS 'Returns 1 if the input string can be CAST to a TIME, else returns 0 Returns 1 is the input string can be CAST to a TIMESTAMP, else returns 0' @
COMMENT ON FUNCTION DB_IS_TIMESTAMP IS 'Returns 1 is the input string can be CAST to a TIMESTAMP, else returns 0' @
COMMENT ON FUNCTION DB_IS_VALID_UTF8 IS 'Returns 1 if the input string is a valid UTF-8 encoding, otherwise returns 0.' @
COMMENT ON FUNCTION DB_JSON_TO_XML IS 'Convert JSON string to XML (jsonx format)' @
COMMENT ON FUNCTION DB_LATIN1_TO_UTF8 IS 'Convert a string from latin-1 codepage to UTF-8' @
COMMENT ON FUNCTION DB_LATIN_TO_GREEK IS 'Replaces Latin characters with Greek equivalents' @
COMMENT ON FUNCTION DB_LOCK_NAME_TO_RID IS 'Returns the Row Id from a LOCK_NAME' @
COMMENT ON FUNCTION DB_NEEDS_ESCAPING IS 'Returns true if a value would need the ESCAPE_CHARATER setting to allow EXTERNAL TABLE to EXPORT in text format' @
COMMENT ON FUNCTION DB_NORMALIZE_UNICODE_NFKC IS 'Apply Unicode normalization NFKC (Normalization Form Compatibility Composition) rules to a string' @
COMMENT ON FUNCTION DB_REMOVE_SPECIAL_CHARACTERS IS 'Removes characters in a string that are not "plain" printable 7-bit ASCII values or TAB, LF and CR' @
COMMENT ON FUNCTION DB_RTRIM_WHITESPACE IS 'Trim trailing whitespace characters such as such No Break Space as well as Tab, New Line, Form Feed and Carriage Returns.' @
COMMENT ON FUNCTION DB_SQLERRM IS 'Returns the SQL error message for the passed SQLCODE. Returns NULL is the SQLCODE is invalid' @
COMMENT ON FUNCTION DB_TO_BIGINT_DEBUG IS 'CASTs the input to an BIGINT but returns an error containing the value if it can''t be cast to an BIGINT' @
COMMENT ON FUNCTION DB_TO_BIGINT IS 'CASTs the input to a BIGINT but returns NULL if the value can''t be CAST successfully' @
COMMENT ON FUNCTION DB_TO_DATE_DEBUG IS 'CASTs the input to an DATE but returns an error containing the value if it can''t be cast to an DATE' @
COMMENT ON FUNCTION DB_TO_DATE IS 'CASTs the input to a DATE but returns NULL if the value can''t be CAST successfully' @
COMMENT ON FUNCTION DB_TO_DECFLOAT_DEBUG IS 'CASTs the input to a DECFLOAT but returns an error containing the value if it can''t be cast to DECFLOAT' @
COMMENT ON FUNCTION DB_TO_DECFLOAT IS 'CASTs the input to a DECFLOAT but returns NULL if the value can''t be CAST successfully' @
COMMENT ON FUNCTION DB_TO_INTEGER_DEBUG IS 'CASTs the input to an INTEGER but returns an error containing the value if it can''t be cast to an INTEGER' @
COMMENT ON FUNCTION DB_TO_INTEGER IS 'CASTs the input to an INTEGER but returns NULL if the value can''t be CAST successfully' @
COMMENT ON FUNCTION DB_TO_TIMESTAMP_DEBUG IS 'CASTs the input to an TIMESTAMP but returns an error containing the value if it can''t be cast to an TIMESTAMP' @
COMMENT ON FUNCTION DB_TO_TIMESTAMP IS 'CASTs the input to a TIMESTAMP but returns NULL if the value can''t be CAST successfully' @
COMMENT ON FUNCTION DB_TSN IS 'Returns the tuple sequence number of a row on a COLUMN organized table when passed the RID_BIT() function' @
COMMENT ON FUNCTION DB_UNHEX IS 'The inverse of HEX(). Converts a a hexadecimal string into a character string' @
COMMENT ON FUNCTION DB_WIN1252_LATIN1_TO_UTF8 IS 'Changes Windows-1252 codepoints that have been incorrectly loaded as Latin-1 (ISO-8859-1) into their correct UTF-8 encoding' @
COMMENT ON FUNCTION DB_WIN1252_LATIN9_TO_UTF8 IS 'Changes Windows-1252 codepoints that have been incorrectly loaded as Latin-9 (ISO-8859-15) into their correct UTF-8 encoding' @

COMMENT ON VARIABLE DB_DIAG_FROM_TIMESTAMP        IS 'Limits rows returned in DB_DIAG to entries more recent than this value' @
COMMENT ON VARIABLE DB_DIAG_TO_TIMESTAMP          IS 'Limits rows returned in DB_DIAG to entries older than this value'       @
COMMENT ON VARIABLE DB_DIAG_MEMBER                IS 'Limits rows returned in DB_DIAG to entries from this member. -1 = current member. -2 = all members' @

