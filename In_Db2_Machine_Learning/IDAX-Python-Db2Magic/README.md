# Building a Linear Regression Model in a Db2 Database using Db2's built-in ML Stored Procedures
## IDE: Jupyter Notebook and its Db2 Magic Commands Extension
In this tutorial, you'll create a Linear Regression model in a Db2 database using Db2's built-in ML stored procedures - in-database advanaced analytics (IDAX) stored procedures (SPs). For executing the SQL statements and the IDAX SPs, you'll use Jupyter Notebook and its Db2 extension [Db2 Magic Commands](https://ibm.github.io/db2-jupyter/). Db2 Magic Commands is a convenience solution to to embed SQL statements, then run them against a Db2 database, in Jupyter notebook.

## Prerequisite
1. Configure a Db2 database with IDAX feature as per these [here] steps.(https://www.ibm.com/docs/en/db2/11.5?topic=learning-prerequisites-machine-in-db2).
2. Load this [dataset](https://raw.githubusercontent.com/IBM/db2-samples/master/In_Db2_Machine_Learning/Building%20ML%20Models%20with%20Db2/Datasets/GoSalesSubSet/GoSalesSubSet.csv) into your Db2 database as per the following steps:
into your Db2 database using the following steps:


db2start
connect to <database_name>

db2 "CREATE TABLE GOSALES.GOSALES_FULL (
ID INTEGER NOT NULL,
GENDER VARCHAR(3),
AGE INTEGER,
MARITAL_STATUS VARCHAR(30),
PROFESSION VARCHAR(30),
PURCHASE_AMOUNT DECIMAL(30, 5),
PRIMARY KEY (ID))";

db2 "IMPORT FROM \"<full_path_to_csv>\" OF DEL skipcount 1 INSERT INTO GOSALES.GOSALES_FULL(ID, GENDER, AGE,
MARITAL_STATUS, PROFESSION, PURCHASE_AMOUNT)"

3. Download the following two files to the same folder from which you'll run your Jupyter Notebook:
**Building an In-database Linear Regression Model using IDAX SPs of Db2.ipynb**
**db2-gosales.env**

db2-gosales.env provides Db2 connection information to the Python code in the Jupyter notebook (first file). This file has the following keys. Replace their values (right side of =) with values for your database connection.
db=DATABASE
username=USERNAME
password=PASSWORD
hostname=HOSTNAME
port=PORT

Now you can run run the Jupyter notebook in an interactive mode. The notebook will guide you through the entire workflow of building, using, and evaluating a Linear Regression model inside Db2. 
