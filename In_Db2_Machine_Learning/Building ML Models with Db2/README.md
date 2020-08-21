# Instructions

This repository contains notebooks and datasets that will allow Db2 customers build ML models with IBM Db2's in-database machine learning capabilities.

# Table of Contents
1. [Prerequistes](#Prerequisites)
2. [Downloading the Dataset](#Downloads)
3. [Loading the Dataset into a Db2 Table](#Loading)
4. [Notebook-specific requirements](#Notebook-specific)
5. [Troubleshooting](#Troubleshooting)
6. [Other Resources](#Resources)

## 1. Prerequisites <a name="Prerequisites"></a>

You must meet the following requirements to use the machine learning functionality in Db2:
- Install the `ibm_db` python package
- Enable IDAX Stored Procedures for ML in your Db2 instance

### 1.1 Installing the ibm_db python package 

Please follow the documentation [here](https://github.com/ibmdb/python-ibmdb#-installation) to install the `ibm_db` python package. This will allow you to connect to and communicate with your Db2 instance.


### 1.2 Enable IDAX Stored Proceduces for ML in your Db2 instance

Please follow the documentation [here](https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.ml.doc/doc/ml_prereqs.html) to enable ML functionality in your Db2 instance.


## 2. Downloading the Datasets <a name="Downloads"></a>
### 2.1 Regression with GoSales

Download the file [GoSales.csv](Datasets/GoSales.csv) from the `Datasets` directory

### 2.2 Classification with Titanic

Download the file [Titanic.csv](Datasets/Titanic.csv) from the `Datasets` directory

## 3. Loading the Dataset into a Db2 Table <a name="Loading"></a>

To load the TITANIC dataset into your Db2 table:

```
db2 start
db2 connect to <database_name>

db2 "CREATE TABLE <table_schema>.<table_name> (
PASSENGERID INTEGER NOT NULL,
SURVIVED INTEGER,
PCLASS INTEGER,
NAME VARCHAR(255),
SEX VARCHAR(6),
AGE DECIMAL(5,2),
SIBSP INTEGER,
PARCH INTEGER,
TICKET VARCHAR(255),
FARE DECIMAL(30,5),
CABIN VARCHAR(255),
EMBARKED VARCHAR(3),
PRIMARY KEY (PASSENGERID))
ORGANIZE BY ROW;"

db2 "IMPORT FROM "<full_path_to_csv>" OF DEL skipcount 1 INSERT INTO 
<table_schema>.<table_name>(PASSENGERID, SURVIVED, PCLASS, NAME, SEX, AGE, SIBSP, PARCH, TICKET, FARE, CABIN, EMBARKED)"
```

For loading the GO_SALES data you can take the following steps:

```
db2start
connect to <database_name>

db2 "CREATE TABLE <table_schema>.<table_name> (
ID INTEGER NOT NULL,
GENDER VARCHAR(3),
AGE INTEGER,
MARITAL_STATUS VARCHAR(30),
PROFESSION VARCHAR(30),
IS_TENT INTEGER,
PRODUCT_LINE VARCHAR(30),
PURCHASE_AMOUNT DECIMAL(30, 5),
PRIMARY KEY (ID))
ORGANIZE BY ROW;"

db2 "IMPORT FROM "<full_path_to_csv>" OF DEL skipcount 1 INSERT INTO 
<table_schema>.<table_name>(ID, GENDER, AGE, MARITAL_STATUS, PROFESSION, IS_TENT, PRODUCT_LINE, PURCHASE_AMOUNT)"
```

## 4. Notebook-specific requirements <a name="Notebook-specific"></a>
### 4.1 Using the Classification Notebook
To use the [classification demo](Notebooks/Classification_Demo.ipynb) notebook, please ensure that the following Python libraries are installed in your development environment:
- [Pandas](https://pandas.pydata.org/pandas-docs/stable/getting_started/install.html)
- [Numpy](https://pypi.org/project/numpy/)
- [IPython](https://ipython.org/install.html)
- [Scipy](https://www.scipy.org/install.html)
- [Itertools](https://docs.python.org/3/library/itertools.html)
- [Matplotlib](https://matplotlib.org/users/installing.html)
- [Seaborn](https://pypi.org/project/seaborn/#description)

Once the above prerequisites have been met, ensure that:
- The parameters in the connection string variable `conn_str` have been changed to your particular Db2 instance (cell 2)
- The value of the variable `schema` has been changed to the appropriate schema where the ML pipeline will be executed (cell 2)
- The value `DATA.TITANIC` in cells 8, 11, 14, 17, and 18 is changed to the `<schema_name>.<table_name>` where the csv data was loaded (section 3)

### 4.2 Using the Regression Notebook
To use the [regression demo](Notebooks/Regression_Demo.ipynb) notebook, please ensure that the following Python libraries are installed in your development environment:
- [Pandas](https://pandas.pydata.org/pandas-docs/stable/getting_started/install.html)
- [Numpy](https://pypi.org/project/numpy/)
- [Matplotlib](https://matplotlib.org/users/installing.html)

Also make sure that you have the [InDBMLModules.py](lib/InDBMLModules.py) file in the same directory as your notebook.

Once the above prerequisites have been met, ensure that:
- The parameters in the connection string variable `conn_str` have been changed to your particular Db2 instance (cell 3)
- The value `DATA.GO_SALES` in cells 6,10, and 11 is changed to the `<schema_name>.<table_name>` where the csv data was loaded (section 3)

## 5. Troubleshooting <a name="Troubleshooting"></a>

When using a jupyter notebook, some users may find that they are unable to import a module that has been successfully installed via pip.

Check `sys.executable` to see which Python and environment you're running in, and `sys.path` to see where it looks to import modules:

```
import sys
print(sys.executable)
print(sys.path)
```

If the path in `sys.executable` is not in `sys.path`, you can add it using the following:
`sys.path.append('/path/from/sys.executable')`

## 6. Demo Videos <a name="Resources"></a>

Find step-by-step demonstrations here:
- [Classification with Db2](https://youtu.be/jCgschThiRQ)
- [Linear Regression with Db2](https://youtu.be/RpX0iHL97dc)

Db2 Machine Learning [Documentation](https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.ml.doc/doc/ml_prereqs.html)