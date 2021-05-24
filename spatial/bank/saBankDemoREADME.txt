README file for Db2 Spatial Analytics Bank Demo
Db2 LUW


*
*
* (C) COPYRIGHT INTERNATIONAL BUSINESS MACHINES CORPORATION 2002 - 2021.
*     ALL RIGHTS RESERVED.
*


This sample script demonstrates Db2 Spatial Analytics administration, 
SQL stored procedures, and spatial functions.

*****************************************************************************

WARNING: Some of these samples may change your database or database manager
         configuration.  Run the samples against a "test" database only,
         such as the Db2 SAMPLE database.

*****************************************************************************

QUICKSTART

   1. Start the database manager (with the db2start command).

   2. Start the sample (with the saBankDemoRunBankDemo command).

*****************************************************************************

Documentation



For more information about Db2 Spatial Analytics, see either of the following
sources. The scripts in this Bank Demo use the term "User's Guide" to refer 
to both of these sources of information:

- The equivalent Spatial Analytics topics in the Db2 Documentation.
 https://www.ibm.com/docs/en/db2/11.5?topic=data-db2-spatial-analytics

For the latest information about programming, compiling, and running Db2
Spatial Analytics applications, refer to
TODO fix link
http://www.ibm.com/software/data/spatial/db2spatial



*****************************************************************************

Command syntax


	saBankDemoRunBankDemo [-i | -n | -c | -b | -h]  [<database_name>]

	-i	Interactive mode: A description of each step is shown before
		you are prompted to execute the step. Explains the story
		board of the bank scenario and the spatial administrative
		actions necessary to set up the database. After the database
		is set up, you are prompted to perform several queries.

	-n	Non-interactive mode: Follows the same steps as the 
		interactive mode but does not prompt you at each step.
		This mode can be used to set up a database for visualization 
		or for further spatial analysis with SQL.

	-c	Completion mode: All the demo steps run in non-interactive
		mode. At the end, the script notifies you of success or
		failure.

	-b	Basic mode: This mode is tutorial oriented, in which you
		follow a written script to perform all the database setup
		steps on the db2gse command-line processor (CLP) or Db2
		Command Editor.
		The database is spatially enabled and only non-spatial data is 
		loaded. You perform the remaining steps.  You also construct
		a series of spatial queries using the Db2 CLP or the 
		DB2 Command Editor.

	If database <databasename> does not exist, the demo creates it. The
	default database name is sa_bank. 
	The schema name is sa_demo (you cannot modify the schema name).



*****************************************************************************

Prerequisites



 1. Before you start the sample program, ensure that the following steps have
    been done in advance:

    - Db2 Spatial Analytics is enabled, if needed.

    - The Db2 default instance is created.

    - The Database manager is started (with the db2start command).

    - The DB2PATH environment variable points to the sqllib directory.

    - The user ID under which this demo is invoked has either SYSADM
      or DBADM authority.

 2. If you are running this demo a second time, delete all of the previous
    message and exception files that have the following form:
    On UNIX,
	 ~/tmp/*.msg and ~/tmp/*.shp

    On Windows, 
	%TEMP%\*.msg and %TEMP%\*.shp 

The following steps are needed if the instance is not configured
as a warehouse (that is the registry DB2_WORKLOAD is not set to ANALYTICS).
 3. If you are going to create a new database or use an existing database,
    ensure that the following parameters are updated to at least the listed
    values:

    Parameter       Min value  CO  Explanation/Description
    ------------    ---------  --  ------------------------------------------
    APPLHEAPSZ         10242   no  various (also for enable_db)
    STMTHEAP           16384  yes  Various platforms raise "query too complex"
                                   warnings

       CO => Configurable Online

    Note: Some of these parameters are not online configurable, and you must 
    stop and restart the DB2 instance for the new values to take effect.

    If these parameters are not set to the values listed above, the demo will
    prompt you to ask if you want the demo to update these values for
    the database. If you reply "yes," the demo stops and restarts the DB2
    instance.


 4. This demo requires larger buffer pools and table spaces than provided by
    the default buffer pool and table space. 

    CREATE object              Page size Explanation/Description
    -------------------------- --------- --------------------------------
    TABLESPACE                       8K  Import a shapefile with more columns
                                          than fit on a 4K page size
    TEMPORARY TABLESPACE            32K  Complex ad hoc queries
    USER TEMPORARY TABLESPACE       32K  Spatial grid index advisor
    BUFFERPOOL                       8K  Use with 8K table space
    BUFFERPOOL                      32K  Use with 32K table space
 
    If these database objects do not exist, the demo will prompt you to
    ask if you want the demo to create them. If you reply "yes," the demo 
    stops and restarts the DB2 instance for them to take effect. 


*****************************************************************************

File descriptions

saBankDemoREADME.txt      	- This file
saBankDemoRunBankDemo		- Main demo script (Korn Shell)
saBankDemoRunBankDemo.bat	- Main demo script (Windows batch file)
saBankDemoDDL.db2		      - Creates non-spatial data tables
saBankDemoTableData.db2		- Loads non-spatialdata 
saBankDemoSpatialSQL.db2	- Miscellaneous spatial queries
saBankDemoViewDDL.db2		- Creates spatial analysis views
saBankDemoRefresh.db2		- Drops all the tables and views

*****************************************************************************

Background

Time and space will become the cornerstone of 21st-century data warehouses.
The time dimension is already frequently used in OLAP and multidimensional
analysis tools.  The next frontier is to add the space dimension to 
data to discover and exploit the spatial intelligence of the data warehouse.

Spatial data (also called location data and geographic data) consists of
values that denote the location of objects and areas with respect to one
another.  Spatial objects include those that comprise the Earth's surface
and those that occupy it.  They make up both the natural environment (for
example rivers, forests, hills and deserts) and the cultural environment
(cities, residences, office buildings, landmarks, and so on). 

Virtually every database already has spatial data -- addresses -- and
virtually every business can benefit from making their data spatially aware.

It is estimated that 80% of the world's databases have a spatial element.
This data, however, is not usable because it is stored in text form, and
SQL does not know if 12 Main Street is close to 141 Langdon Street. This
address data is at the core of most commercial enterprises, yet the semantic
content is not exploited.  The ability to leverage the value of this
existing data asset is central to spatial analysis.

IBM has focused research efforts on creating an extensible data management
infrastructure for more than a decade.  The results of these efforts have
become a major component of IBM's Db2 Database, which includes
access to heterogeneous data and to non-IBM, non-relational data sources.

The ability to model complex data and objects (geospatial data, text, images
and other user-defined data types) directly in the database gives users 
four key benefits:

-  Enhances the business value of existing applications and data
-  Improves business intelligence with integrated searching across all data
   types
-  Facilitates the development of new applications and queries
-  Improves overall application performance


*****************************************************************************

Banking customer analysis sample

This demo illustrates adding a spatial dimension to an existing information 
system. The existing system did not contain any explicit location (spatial) 
data. However, the existing system did contain implicit location data in the
form of addresses.  By spatially enabling the existing database, the user 
expands the business analysis capabilities of the system.

Note: Although this demo focuses on a banking application, it is equally 
applicable to different businesses such as retail, insurance, and so on.

A bank that has customers with accounts at two branches needs to use the
spatial attribute of the existing data along with census demographic data
to perform various kinds of spatial analysis.  The analysis consists of
comparing customer, branch, and demographic data, as well as profiling
customers and doing market analysis.  The bank looks for prospective
customers by finding average balances for customers within three miles of
the branch, determining what areas the primary customers live in, and
searching for similar areas.

The demographic and spatial reference data has an explicit spatial component.
The initial data is in shapefile format. Shapefile format is an ESRI standard 
for storing spatial information and has become an industry standard. For more 
information, see the ESRI Web site at
http://www.esri.com/library/whitepapers/pdfs/shapefile.pdf.

The customer, branch and employee tables contain the address information
and corresponding latitude and longitude values.

The demo script illustrates how to use the spatial administration commands
and prepare a database for spatial data visualization using ESRI's 
ArcExplorer.  The sample also explains how to use the spatial routines, and 
outlines how spatial analysis can be used in a banking scenario.

The demo script runs in four modes that are described in the command syntax.

*****************************************************************************

Duration

Most of the demo steps take seconds to run, but the steps below might
take several minutes:

- Creating the database

- Spatially enabling the database, if needed

- Importing shapefile data

*****************************************************************************
