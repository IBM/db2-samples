# Deploying an External Model in Db2

This repository contains notebooks and datasets that will allow Db2 customers to deploy an externally created model in IBM Db2 with a Python UDF, and call that model to make predictions.

## Table of Contents
0. [Prerequistes](#Prerequisites)
1. [Download the GoSales Data, Create, and Export the External Model](#Create)
2. [Create and Upload the UDF File](#Upload)
3. [Register the UDF](#Register)
4. [Download and Store the Test Data in a Db2 Table](#ImportData)
5. [Call your UDF to Make a Prediction](#Predict)
6. [Create and Call your UDF to Make a Prediction using REST services ](#RESTAPI)
7. [Reference and Further Reading](#Reference)


## 0. Prerequisites <a name="Prerequisites"></a>

You must have the following dependencies installed on the machine where your IBM Db2 instance resides:
- [Scikit-learn](https://scikit-learn.org/stable/install.html)
- [Joblib](https://joblib.readthedocs.io/en/latest/installing.html)

## 1. Download the GoSales Data, Create, and Export the External Model <a name="Create"></a>

First, download the [GoSales.csv](GoSales.csv) file, and run the notebook [Create External LR Model](CreatinganExternalModel.ipynb) to create a linear regression model. Note that you may have to modify the file path in cell 60 a path of your choice. This notebook will save a linear regressor created with scikit-learn and save it as a joblib file. You may also choose to skip this step and directly download the [sample model provided](external_model.joblib).

Next, import your joblib file to the machine where your IBM Db2 instance resides. This can be done with sftp as follows:

```
sftp <uid>@<hostname>
cd <path_where_you_want_to_put_the_file>
put <path_to_local_joblib_file>
```

## 2. Create and Upload the UDF File <a name="Upload"></a>

Once the model joblib file has been successfully uploaded, you will then need to create a Python UDF file.

Download the Python UDF file provided: [lin_regressor.py](lin_regressor.py). Note that you may have to change the file path in line 7 to the path where you have saved the joblib file.

Upload the UDF file to all Db2 nodes or to a network drive that is accessible from all Db2 nodes, for example, `home/test/sqllib/function/routine/lin_regressor.py`. Because Python UDXs are executed as Db2 fenced processes, the UDX file must be readable for the fenced user ID.

## 3. Register the UDF <a name="Register"></a>

Register the UDF using the following CREATE FUNCTION statement:

```
CREATE FUNCTION predict_price(float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float, float) \
returns float LANGUAGE PYTHON  parameter style \
NPSGENERIC  FENCED  NOT THREADSAFE  NO FINAL CALL  ALLOW PARALLEL  NO DBINFO  DETERMINISTIC  NO EXTERNAL ACTION \
RETURNS NULL ON NULL INPUT  NO SQL \
external name 'home/test/sqllib/function/routine/lin_regressor.py'
```

Note that you may have to change the file path in the last line to the file path where the `lin_regressor.py` file was saved.

## 4. Download and Store the Test Data in a Db2 Table <a name="ImportData"></a>

Download the [test data](UDFTestData.csv) csv file.

Import the data into a Db2 Table using the following:

```
db2start
connect to <database_name>

db2 "CREATE TABLE <table_schema>.<table_name> (
ID INT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE),
F FLOAT,
M FLOAT,
MARRIED FLOAT,
SINGLE FLOAT,
UNSPECIFIED FLOAT,
EXECUTIVE FLOAT,
HOSPITALITY FLOAT,
OTHER FLOAT,
PROFESSIONAL FLOAT,
RETAIL FLOAT,
RETIRED FLOAT,
SALES FLOAT,
STUDENT FLOAT,
TRADES FLOAT,
CAMPING_EQUIPMENT FLOAT,
GOLF_EQUIPMENT FLOAT,
MOUNTAINEERING_EQUIPMENT FLOAT,
OUTDOOR_PROTECTION FLOAT,
PERSONAL_ACCESSORIES FLOAT,
AGE FLOAT,
IS_TENT  FLOAT,
PRIMARY KEY (ID))
ORGANIZE BY ROW;"

db2 "IMPORT FROM "<full_path_to_csv>" OF DEL skipcount 1 INSERT INTO 
<table_schema>.<table_name>(F, M, MARRIED, SINGLE, UNSPECIFIED, EXECUTIVE, HOSPITALITY, OTHER, PROFESSIONAL, RETAIL, RETIRED, SALES, STUDENT, TRADES, CAMPING_EQUIPMENT, GOLF_EQUIPMENT, MOUNTAINEERING_EQUIPMENT, OUTDOOR_PROTECTION, PERSONAL_ACCESSORIES, AGE, IS_TENT)"
```

It is important to note that the data being fed into the model must be in the same form as the data used to train the model - that is, the table columns should be in the same order and the data should be transformed similarly to the training data.

## 5. Call your UDF to Make a Prediction <a name="Predict"></a>

Call the UDF to make a prediction either from the command line or via a Jupyter notebook with the following SQL commands:


First we create a temporary view using the transformed test data that does not include the primary key column "ID" as it was not used in the model building process, and will cause an error to be thrown

```
db2 "CREATE VIEW TEST_INPUT AS SELECT F, M, MARRIED, SINGLE, UNSPECIFIED, EXECUTIVE, HOSPITALITY, OTHER, PROFESSIONAL, RETAIL, RETIRED, SALES, STUDENT, TRADES, CAMPING_EQUIPMENT, GOLF_EQUIPMENT, MOUNTAINEERING_EQUIPMENT, OUTDOOR_PROTECTION, PERSONAL_ACCESSORIES, AGE, IS_TENT FROM <table_schema>.<table_name>;"
```

Then, call the UDF to make a prediction

```
db2 "SELECT *, predict_price(F, M, MARRIED, SINGLE, UNSPECIFIED, EXECUTIVE, HOSPITALITY, 
OTHER, PROFESSIONAL, RETAIL, RETIRED, SALES, STUDENT, TRADES, CAMPING_EQUIPMENT, 
GOLF_EQUIPMENT, MOUNTAINEERING_EQUIPMENT, OUTDOOR_PROTECTION, PERSONAL_ACCESSORIES, 
AGE, IS_TENT) as model_prediction from TEST_INPUT;"
```

## 6. Create and Call your UDF to Make a Prediction using a REST API <a name="RESTAPI"></a>

Use the three "Db2 RESTful..." notebooks to create a REST services that can call the UDF to make a prediction.  Two services are created -- one where you give it the features for the model from your applicaiton and the other where the features are already in a table, and you point the service to the correct row in the table.  This would be useful in mobile and other applications where it is not convenient to connect to the database directly, but instead call a service that gets the prediction for you.   

1.  Download the notebooks to a directory where you keep Jupyter notebooks
2.  Edit the Db2 RESTful Prep External Py UDF.ipynb notebook to use your database connect information and credentials and run it to prepare your database with the needed objects and grants.
3.  Edit the Db2 RESTful Get Token for External Py UDF.ipynb notebook to use your database connect information and credentials. It will be called by the notebook that creates and uses the services to get the needed token for the Db2 REST endpoint.
4.   Run the Db2 RESTful External Py UDF.ipynb for examples of creating and running services that use the UDF.

## 7. Reference and Further Reading <a name="Reference"></a>

- [Creating Python UDX in Db2](https://www.ibm.com/support/knowledgecenter/SSHRBY/com.ibm.swg.im.dashdb.udx.doc/doc/udx_t_create_udx_python.html)
- [Deploying Python UDX in Db2](https://www.ibm.com/support/knowledgecenter/SSHRBY/com.ibm.swg.im.dashdb.udx.doc/doc/udx_t_deploying_python.html)