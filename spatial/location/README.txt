README file for Db2 Spatial Analytics Location Sample

*
*
* (C) COPYRIGHT INTERNATIONAL BUSINESS MACHINES CORPORATION 2021.
*
     ALL RIGHTS RESERVED.
*


File: samples/spatial/location/README.txt

The Db2 Spatial Analytics sample consists of a Jupyter notebook with
supporting SQL script init_env.sql.
This file briefly introduces each demo and indicates where to look for
further information.


= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
The demo is implemented in Jupyter notebook creating and using a locally
created database. It uses the Db2 command line provess (CLP) 
and the IBM Python driver to interact with the database and local instance. 
You can use the demo and scripts as a tutorial to work with a Jupyter notebook,
perform queries and display data on a map.
The data used is located in spatial/samples/data and consists of two tables:
- a customer table containing customer (fake) information.
- a county table containing all US counties with census information.

The script load_data.sql assumes that the CSV files with the data are co-located 
with the notebook and scripts. Thus, prior to running the script in the notebook
extract the data 
spatial/data/geo_customer.zip
spatial/data/geo_county.zip
followed by either copying the data to the directory of the script and notebook 
or change the SQL script to point to the appropriate path for the files. 

The following excerpt from that file gives an introduction to the demo:
*****************************************************************************
This demo illustrates adding a spatial dimension to an existing information system. 
The existing system did not contain any explicit location (spatial) data. 
However, the existing system did contain implicit location data in the 
form of addresses. By spatially enabling the existing database, 
the user expands the business analysis capabilities of the system.

This demo is a a jupyter notebook version of
https://www.ibm.com/blogs/cloud-archive/2015/08/location-location-location/

In this scenario, a small company (MYCO) has two offices, but business has been growing and there are
now customers across the country. Many of the customers have expressed a preference to meet company 
representatives in person. The company owners want to explore where to open a new office.

Some of the questions in MYCO company owners want to answer are:

We already have some ideas where to open a new office. 
- How can we find out which of these potential locations can serve the most customers?
- How can we reach the customers with the highest business volume?
- Are there other locations that should be considered?

Spatial analysis functions can help find the answers.

On Db2 Warehouse on Cloud the geospatial data used to bring this example to life can be found in the SAMPLE schema. 
It contains data about customers in the GEO_CUSTOMER table and county data in the GEO_COUNTY table 
in the Spatial Extender format and need conversion into the Spatial Analytics format first.
However, this notebook also works with Spatial Extender. Only the DB2GSE schema is necessary to be used in 
queries for any spatial functions.
You can use the Tables menu to view the structure and browse the content of these tables.

For more information on Spatial Analytics visit the documentation: 
https://www.ibm.com/docs/en/db2/11.5?topic=data-db2-spatial-analytics