-- #----------------------------------------------------------------------------------------------#
-- #  NAME:     02_import.sql                                                                     #
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

import from CLAIM.csv OF DEL INSERT INTO DEMO.CLAIM;
import from HAS_DISEASE.csv OF DEL INSERT INTO DEMO.HAS_DISEASE;
import from INCHARGE_OF_CLAIM.csv OF DEL INSERT INTO DEMO.INCHARGE_OF_CLAIM;
import from INCHARGE.csv OF DEL INSERT INTO DEMO.INCHARGE;
import from INSURED_OF_CLAIM.csv OF DEL INSERT INTO DEMO.INSURED_OF_CLAIM;
import from PATIENT.csv OF DEL INSERT INTO DEMO.PATIENT;
import from POLICYHOLDER_OF_CLAIM.csv OF DEL INSERT INTO DEMO.POLICYHOLDER_OF_CLAIM;
import from POLICYHOLDER_CONNECTION.csv OF DEL INSERT INTO DEMO.POLICYHOLDER_CONNECTION;
import from CLAIM_SIMILARITY.csv OF DEL INSERT INTO DEMO.CLAIM_SIMILARITY;
import from POLICYHOLDER.csv OF DEL INSERT INTO DEMO.POLICYHOLDER;
import from DISEASE.csv OF DEL INSERT INTO DEMO.DISEASE;
import from SERVICE.csv OF DEL INSERT INTO DEMO.SERVICE;
import from DISEASE_ONTOLOGY.csv OF DEL INSERT INTO DEMO.DISEASE_ONTOLOGY;
