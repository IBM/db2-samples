This repository holds the dataset and prerequisite notes/instructions required to do a hands-on walkthrough alongside the Db2 with WKC & Watson Studio demo.


## Prerequisites
Please complete the following requirements in order to follow along with this demo. 
1. Have a Cloud Pak for Data cluster (this demo was not made for the public cloud IBM Cloud) with the Watson Knowledge Catalog and Watson Studio services installed. The Watson Studio should already have the machine learning instance activated
2. `TelcoCustomers.csv` should already be loaded into a Db2 table. For instructions on how to load the Telco dataset into a Db2 table, reference below.


## Downloading & Loading the Dataset into a Db2 Table
Download the file TelcoCustomers.csv located in this repository. To load the TELCO dataset into your Db2 table:

```
db2start
db2 connnect to <database_name>


db2 "CREATE TABLE <table_schema>.<table_name>  (
                  "CUSTOMERID" VARCHAR(20 OCTETS) ,
                  "GENDER" VARCHAR(12 OCTETS) ,
                  "EMAIL" VARCHAR(60 OCTETS) ,
                  "PHONENUMBER" VARCHAR(36 OCTETS) ,
                  "SENIORCITIZEN" INTEGER ,
                  "PARTNER" VARCHAR(6 OCTETS) ,
                  "DEPENDENTS" VARCHAR(6 OCTETS) ,
                  "TENURE" INTEGER ,
                  "PHONESERVICE" VARCHAR(6 OCTETS) ,
                  "MULTIPLELINES" VARCHAR(32 OCTETS) ,
                  "INTERNETSERVICE" VARCHAR(22 OCTETS) ,
                  "ONLINESECURITY" VARCHAR(38 OCTETS) ,
                  "ONLINEBACKUP" VARCHAR(38 OCTETS) ,
                  "DEVICEPROTECTION" VARCHAR(38 OCTETS) ,
                  "TECHSUPPORT" VARCHAR(38 OCTETS) ,
                  "STREAMINGTV" VARCHAR(38 OCTETS) ,
                  "STREAMINGMOVIES" VARCHAR(38 OCTETS) ,
                  "CONTRACT" VARCHAR(28 OCTETS) ,
                  "PAPERLESSBILLING" VARCHAR(6 OCTETS) ,
                  "PAYMENTMETHOD" VARCHAR(50 OCTETS) ,
                  "MONTHLYCHARGES" DOUBLE ,
                  "TOTALCHARGES" DOUBLE ,
                  "CHURN" VARCHAR(6 OCTETS) );"
                
db2 "IMPORT FROM TelcoCustomers.csv OF DEL skipcount 1 INSERT INTO <table.schema>.<table_name>"
```
