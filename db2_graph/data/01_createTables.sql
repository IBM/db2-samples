-- #----------------------------------------------------------------------------------------------#
-- #  NAME:     01_createTables.sql                                                               #
-- #                                                                                              #
-- #----------------------------------------------------------------------------------------------#
-- #                     DISCLAIMER OF WARRANTIES AND LIMITATION OF LIABILITY                     #
-- #                                                                                              #
-- #  (C) COPYRIGHT International Business Machines Corp. 2018, 2019 All Rights Reserved          #
-- #  Licensed Materials - Property of IBM                                                        #
-- #                                                                                              #
-- #  US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA    #
-- #  ADP Schedule Contract with IBM Corp.                                                        #
-- #                                                                                              #
-- #  The following source code ("Sample") is owned by International Business Machines            #
-- #  Corporation ("IBM") or one of its subsidiaries and is copyrighted and licensed, not sold.   #
-- #  You may use, copy, modify, and distribute the Sample in any form without payment to IBM,    #
-- #  for the purpose of assisting you in the creation of Python applications using the ibm_db    #
-- #  library.                                                                                    #
-- #                                                                                              #
-- #  The Sample code is provided to you on an "AS IS" basis, without warranty of any kind. IBM   #
-- #  HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT    #
-- #  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. #
-- #  Some jurisdictions do not allow for the exclusion or limitation of implied warranties, so   #
-- #  the above limitations or exclusions may not apply to you. IBM shall not be liable for any   #
-- #  damages you suffer as a result of using, copying, modifying or distributing the Sample,     #
-- #  even if IBM has been advised of the possibility of such damages.                            #
-- #----------------------------------------------------------------------------------------------#

------------------------------------------------
-- DDL Statements for Table "DEMO    "."PATIENT"
------------------------------------------------
 

CREATE TABLE "DEMO    "."PATIENT"  (
		  "PATIENT_ID" VARCHAR(20 OCTETS) NOT NULL, 
		  "SUBSCRIPTION_ID" VARCHAR(20 OCTETS))
      IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DEMO    "."PATIENT"

ALTER TABLE "DEMO    "."PATIENT" 
	ADD PRIMARY KEY
		("PATIENT_ID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "DEMO    "."POLICYHOLDER"
------------------------------------------------
 

CREATE TABLE "DEMO    "."POLICYHOLDER"  (
		  "POLICYHOLDER_ID" VARCHAR(20 OCTETS) NOT NULL , 
		  "FNAME" VARCHAR(50 OCTETS) , 
		  "LNAME" VARCHAR(50 OCTETS) , 
		  "RISK_SCORE" INTEGER , 
		  "HIGH_RISK" SMALLINT )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DEMO    "."POLICYHOLDER"

ALTER TABLE "DEMO    "."POLICYHOLDER" 
	ADD PRIMARY KEY
		("POLICYHOLDER_ID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "DEMO    "."SERVICE"
------------------------------------------------
 

CREATE TABLE "DEMO    "."SERVICE"  (
		  "SERVICE_ID" VARCHAR(20 OCTETS) NOT NULL , 
		  "SERVICE_NAME" VARCHAR(50 OCTETS) , 
		  "RISK_SCORE" INTEGER )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DEMO    "."SERVICE"

ALTER TABLE "DEMO    "."SERVICE" 
	ADD PRIMARY KEY
		("SERVICE_ID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "DEMO    "."INCHARGE"
------------------------------------------------
 

CREATE TABLE "DEMO    "."INCHARGE"  (
		  "INCHARGE_ID" VARCHAR(20 OCTETS) NOT NULL , 
		  "FNAME" VARCHAR(50 OCTETS) , 
		  "LNAME" VARCHAR(50 OCTETS) , 
		  "RISK_SCORE" INTEGER , 
		  "SERVICE_ID" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DEMO    "."INCHARGE"

ALTER TABLE "DEMO    "."INCHARGE" 
	ADD PRIMARY KEY
		("INCHARGE_ID")
	ENFORCED;


-- DDL Statements for Index on Table "DEMO    "."INCHARGE"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INCHARGE_SERVICE_INDEX" ON "DEMO    "."INCHARGE"
                ("SERVICE_ID" ASC)

                COMPRESS NO
                INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."POLICYHOLDER_CONNECTION"
------------------------------------------------
 

CREATE TABLE "DEMO    "."POLICYHOLDER_CONNECTION"  (
		  "POLICYHOLDER_ID" VARCHAR(20 OCTETS) , 
		  "POLICYHOLDER_ASSOCIATE_ID" VARCHAR(20 OCTETS) , 
		  "LEVEL" INTEGER )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."POLICYHOLDER_CONNECTION"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."POLICYHOLDER_CONNECTION_POLICYHOLDER_INDEX" ON "DEMO    "."POLICYHOLDER_CONNECTION" 
		("POLICYHOLDER_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."POLICYHOLDER_CONNECTION"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."POLICYHOLDER_CONNECTION_ASSOCIATE_INDEX" ON "DEMO    "."POLICYHOLDER_CONNECTION" 
		("POLICYHOLDER_ASSOCIATE_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."POLICYHOLDER_CONNECTION"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."POLICYHOLDER_CONNECTION_INDEX" ON "DEMO    "."POLICYHOLDER_CONNECTION" 
		("POLICYHOLDER_ID" ASC,
		 "POLICYHOLDER_ASSOCIATE_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."CLAIM"
------------------------------------------------
 

CREATE TABLE "DEMO    "."CLAIM"  (
		  "CLAIM_ID" VARCHAR(20 OCTETS) NOT NULL , 
		  "CHARGE" DECIMAL(10,2) , 
		  "CLAIM_DATE" TIMESTAMP , 
		  "DURATION" INTEGER , 
		  "INSURED_ID" VARCHAR(20 OCTETS) , 
		  "DIAGNOSIS" VARCHAR(100 OCTETS) , 
		  "PERSON_INCHARGE_ID" VARCHAR(20 OCTETS) , 
		  "TYPE" VARCHAR(50 OCTETS) , 
		  "POLICYHOLDER_ID" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DEMO    "."CLAIM"

ALTER TABLE "DEMO    "."CLAIM" 
	ADD PRIMARY KEY
		("CLAIM_ID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "DEMO    "."CLAIM_SIMILARITY"
------------------------------------------------
 

CREATE TABLE "DEMO    "."CLAIM_SIMILARITY"  (
		  "CLAIM_ID" VARCHAR(20 OCTETS) , 
		  "SIM_CLAIM_ID" VARCHAR(20 OCTETS) , 
		  "SIMILARITY_SCORE" INTEGER )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."CLAIM_SIMILARITY"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."CLAIM_SIMILARITY_CLAIM_INDEX" ON "DEMO    "."CLAIM_SIMILARITY" 
		("CLAIM_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."CLAIM_SIMILARITY"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."CLAIM_SIMILARITY_SIM_CLAIM_INDEX" ON "DEMO    "."CLAIM_SIMILARITY" 
		("SIM_CLAIM_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."CLAIM_SIMILARITY"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."CLAIM_SIMILARITY_INDEX" ON "DEMO    "."CLAIM_SIMILARITY" 
		("CLAIM_ID" ASC,
		 "SIM_CLAIM_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."POLICYHOLDER_OF_CLAIM"
------------------------------------------------
 

CREATE TABLE "DEMO    "."POLICYHOLDER_OF_CLAIM"  (
		  "CLAIM_ID" VARCHAR(20 OCTETS) , 
		  "POLICYHOLDER_ID" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."POLICYHOLDER_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."POLICYHOLDER_OF_CLAIM_CLAIM_INDEX" ON "DEMO    "."POLICYHOLDER_OF_CLAIM" 
		("CLAIM_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."POLICYHOLDER_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."POLICYHOLDER_OF_CLAIM_POLICYHOLDER_INDEX" ON "DEMO    "."POLICYHOLDER_OF_CLAIM" 
		("POLICYHOLDER_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."POLICYHOLDER_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."POLICYHOLDER_OF_CLAIM_INDEX" ON "DEMO    "."POLICYHOLDER_OF_CLAIM" 
		("CLAIM_ID" ASC,
		 "POLICYHOLDER_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."INCHARGE_OF_CLAIM"
------------------------------------------------
 

CREATE TABLE "DEMO    "."INCHARGE_OF_CLAIM"  (
		  "CLAIM_ID" VARCHAR(20 OCTETS) , 
		  "PERSON_INCHARGE_ID" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."INCHARGE_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INCHARGE_OF_CLAIM_CLAIM_INDEX" ON "DEMO    "."INCHARGE_OF_CLAIM" 
		("CLAIM_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."INCHARGE_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INCHARGE_OF_CLAIM_INCHARGE_INDEX" ON "DEMO    "."INCHARGE_OF_CLAIM" 
		("PERSON_INCHARGE_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."INCHARGE_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INCHARGE_OF_CLAIM_INDEX" ON "DEMO    "."INCHARGE_OF_CLAIM" 
		("CLAIM_ID" ASC,
		 "PERSON_INCHARGE_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."INSURED_OF_CLAIM"
------------------------------------------------
 

CREATE TABLE "DEMO    "."INSURED_OF_CLAIM"  (
		  "CLAIM_ID" VARCHAR(20 OCTETS) , 
		  "PATIENT_ID" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."INSURED_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INSURED_OF_CLAIM_CLAIM_INDEX" ON "DEMO    "."INSURED_OF_CLAIM" 
		("CLAIM_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."INSURED_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INSURED_OF_CLAIM_PATIENT_INDEX" ON "DEMO    "."INSURED_OF_CLAIM" 
		("PATIENT_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."INSURED_OF_CLAIM"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."INSURED_OF_CLAIM_INDEX" ON "DEMO    "."INSURED_OF_CLAIM" 
		("CLAIM_ID" ASC,
		 "PATIENT_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."DISEASE"
------------------------------------------------
 

CREATE TABLE "DEMO    "."DISEASE"  (
		  "DISEASEID" VARCHAR(20 OCTETS) NOT NULL , 
		  "CONCEPT_NAME" VARCHAR(100 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 


-- DDL Statements for Primary Key on Table "DEMO    "."DISEASE"

ALTER TABLE "DEMO    "."DISEASE" 
	ADD PRIMARY KEY
		("DISEASEID")
	ENFORCED;



------------------------------------------------
-- DDL Statements for Table "DEMO    "."DISEASE_ONTOLOGY"
------------------------------------------------
 

CREATE TABLE "DEMO    "."DISEASE_ONTOLOGY"  (
		  "PARENTDISEASE" VARCHAR(20 OCTETS) , 
		  "CHILDDISEASE" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."DISEASE_ONTOLOGY"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."DISEASE_ONTOLOGY_PARENTDISEASE_INDEX" ON "DEMO    "."DISEASE_ONTOLOGY" 
		("PARENTDISEASE" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."DISEASE_ONTOLOGY"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."DISEASE_ONTOLOGY_CHILDDISEASE_INDEX" ON "DEMO    "."DISEASE_ONTOLOGY" 
		("CHILDDISEASE" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."DISEASE_ONTOLOGY"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."DISEASE_ONTOLOGY_INDEX" ON "DEMO    "."DISEASE_ONTOLOGY" 
		("PARENTDISEASE" ASC,
		 "CHILDDISEASE" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

------------------------------------------------
-- DDL Statements for Table "DEMO    "."HAS_DISEASE"
------------------------------------------------
 

CREATE TABLE "DEMO    "."HAS_DISEASE"  (
		  "PATIENT_ID" VARCHAR(20 OCTETS) , 
		  "DISEASEID" VARCHAR(20 OCTETS) )   
		 IN "USERSPACE1"  
		 ORGANIZE BY ROW; 






-- DDL Statements for Indexes on Table "DEMO    "."HAS_DISEASE"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."HAS_DISEASE_PATIENT_INDEX" ON "DEMO    "."HAS_DISEASE" 
		("PATIENT_ID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."HAS_DISEASE"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."HAS_DISEASE_DISEASEID_INDEX" ON "DEMO    "."HAS_DISEASE" 
		("DISEASEID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;

-- DDL Statements for Indexes on Table "DEMO    "."HAS_DISEASE"

SET SYSIBM.NLS_STRING_UNITS = 'SYSTEM';

CREATE INDEX "DEMO    "."HAS_DISEASE_PATIENT_DISEASEID_INDEX" ON "DEMO    "."HAS_DISEASE" 
		("PATIENT_ID" ASC,
		 "DISEASEID" ASC)
		
		COMPRESS NO 
		INCLUDE NULL KEYS ALLOW REVERSE SCANS;



create view demo.service_of_claim
(
  claim_id,
  service_id
)
as
  (select claim_id, service_id
  from demo.incharge ic, demo.incharge_of_claim link
  where link.PERSON_INCHARGE_ID=ic.INCHARGE_ID);