--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

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
