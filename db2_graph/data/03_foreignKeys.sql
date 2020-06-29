-- -- #----------------------------------------------------------------------------------------------#
-- #  NAME:     03_foreignKeys.sql                                                                #
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

-- DDL Statements for Foreign Keys on Table "DEMO    "."INCHARGE"
ALTER TABLE "DEMO    "."INCHARGE" 
	ADD CONSTRAINT "SQL200310154721750" FOREIGN KEY
		("SERVICE_ID")
	REFERENCES "DEMO    "."SERVICE"
		("SERVICE_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."POLICYHOLDER_CONNECTION"

ALTER TABLE "DEMO    "."POLICYHOLDER_CONNECTION" 
	ADD CONSTRAINT "SQL200310155154010" FOREIGN KEY
		("POLICYHOLDER_ID")
	REFERENCES "DEMO    "."POLICYHOLDER"
		("POLICYHOLDER_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."POLICYHOLDER_CONNECTION" 
	ADD CONSTRAINT "SQL200310155154020" FOREIGN KEY
		("POLICYHOLDER_ASSOCIATE_ID")
	REFERENCES "DEMO    "."POLICYHOLDER"
		("POLICYHOLDER_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."CLAIM_SIMILARITY"

ALTER TABLE "DEMO    "."CLAIM_SIMILARITY" 
	ADD CONSTRAINT "SQL200317155711880" FOREIGN KEY
		("CLAIM_ID")
	REFERENCES "DEMO    "."CLAIM"
		("CLAIM_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."CLAIM_SIMILARITY" 
	ADD CONSTRAINT "SQL200317155711890" FOREIGN KEY
		("SIM_CLAIM_ID")
	REFERENCES "DEMO    "."CLAIM"
		("CLAIM_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."POLICYHOLDER_OF_CLAIM"

ALTER TABLE "DEMO    "."POLICYHOLDER_OF_CLAIM" 
	ADD CONSTRAINT "SQL200317155943020" FOREIGN KEY
		("CLAIM_ID")
	REFERENCES "DEMO    "."CLAIM"
		("CLAIM_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."POLICYHOLDER_OF_CLAIM" 
	ADD CONSTRAINT "SQL200317155943030" FOREIGN KEY
		("POLICYHOLDER_ID")
	REFERENCES "DEMO    "."POLICYHOLDER"
		("POLICYHOLDER_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."INCHARGE_OF_CLAIM"

ALTER TABLE "DEMO    "."INCHARGE_OF_CLAIM" 
	ADD CONSTRAINT "SQL200317160212310" FOREIGN KEY
		("CLAIM_ID")
	REFERENCES "DEMO    "."CLAIM"
		("CLAIM_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."INCHARGE_OF_CLAIM" 
	ADD CONSTRAINT "SQL200317160212320" FOREIGN KEY
		("PERSON_INCHARGE_ID")
	REFERENCES "DEMO    "."INCHARGE"
		("INCHARGE_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."INSURED_OF_CLAIM"

ALTER TABLE "DEMO    "."INSURED_OF_CLAIM" 
	ADD CONSTRAINT "SQL200317160636150" FOREIGN KEY
		("CLAIM_ID")
	REFERENCES "DEMO    "."CLAIM"
		("CLAIM_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."INSURED_OF_CLAIM" 
	ADD CONSTRAINT "SQL200317160636160" FOREIGN KEY
		("PATIENT_ID")
	REFERENCES "DEMO    "."PATIENT"
		("PATIENT_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."DISEASE_ONTOLOGY"

ALTER TABLE "DEMO    "."DISEASE_ONTOLOGY" 
	ADD CONSTRAINT "SQL200318103239700" FOREIGN KEY
		("PARENTDISEASE")
	REFERENCES "DEMO    "."DISEASE"
		("DISEASEID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."DISEASE_ONTOLOGY" 
	ADD CONSTRAINT "SQL200318103239710" FOREIGN KEY
		("CHILDDISEASE")
	REFERENCES "DEMO    "."DISEASE"
		("DISEASEID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

-- DDL Statements for Foreign Keys on Table "DEMO    "."HAS_DISEASE"

ALTER TABLE "DEMO    "."HAS_DISEASE" 
	ADD CONSTRAINT "SQL200318103406530" FOREIGN KEY
		("PATIENT_ID")
	REFERENCES "DEMO    "."PATIENT"
		("PATIENT_ID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;

ALTER TABLE "DEMO    "."HAS_DISEASE" 
	ADD CONSTRAINT "SQL200318103406540" FOREIGN KEY
		("DISEASEID")
	REFERENCES "DEMO    "."DISEASE"
		("DISEASEID")
	ON DELETE NO ACTION
	ON UPDATE NO ACTION
	ENFORCED
	ENABLE QUERY OPTIMIZATION;






