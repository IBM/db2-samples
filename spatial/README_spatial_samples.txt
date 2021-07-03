README file for Db2 Spatial Analytics Samples

*
*
* (C) COPYRIGHT INTERNATIONAL BUSINESS MACHINES CORPORATION 2000, 2021.
*
     ALL RIGHTS RESERVED.
*


File: samples/spatial/README_spatial_samples.txt

The Db2 Spatial Analytics samples consist of one demo program 
and one jupyter notebook.
  1. The demo program (bank) sample is based on banking (branches, customers, employees).
     This banking demo is written in SQL scripts run by the command-line
     processor (CLP).
  2. The jupyter notebook (location) is based on using spatial data to find
     a new location for company MYCO that is expanding.

This file briefly introduces the demo and indicates where to look for
further information.

Note: as of Db2 V11.5.6 these samples are not part of a Db2 installation.

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
The Banking Demo is implemented in SQL scripts that are run with the Db2
command line processor. You can use the demo and scripts as a tutorial.
The scripts and README file "saBankDemoREADME.txt" are located in the
"bank" subdirectory (samples/spatial/bank).
The following excerpt from that file gives an introduction to the demo:
*****************************************************************************
  Banking Customer Analysis Sample

  This demo illustrates adding a spatial dimension to an existing
  information system. The existing system did not contain any explicit
  location (spatial) data. However, the existing system did contain implicit
  location data in the form of addresses.  By spatially enabling the existing
  database, the user expands the business analysis capabilities of the system.

  A bank that has customers with accounts at two branches needs to use the
  spatial attribute of the existing data along with census demographic data
  to perform various kinds of spatial analysis.  The analysis consists of
  comparing customer, branch, and demographic data, as well as profiling
  customers and doing market analysis.  The bank looks for prospective
  customers by finding average balances for customers within three miles of
  the branch, determining what areas the primary customers live in, and
  searching for similar areas.

  Note: Although this demo focuses on a banking application, it is equally
  applicable to different businesses such as retail, insurance, and so on.
*****************************************************************************

For UNIX, the Banking Demo is driven by a Korn shell script called
"saBankDemoRunBankDemo". To display usage information, enter
       saBankDemoRunBankDemo -h

For Windows, the Banking Demo is driven by a batch file which is TBD.

Before you run the demo, look at the "saBankDemoREADME.txt" file. This
README file describes the prerequisites and explains how to run the demo.

After the Banking Demo runs, the complete record of its actions can be found
in the file "sa_bank.log" which is in the "tmp", subdirectory under the home
directory of the user who ran the demo.

= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
The Location demo is implemented as Jupyter notebook along with a supporting 
SQL script to load the data. 
You can use the demo as tutorial into using Jupyter notebooks.
The scripts and README file "README.txt" are located in the
"location" subdirectory (samples/spatial/location).

The demo is a Spatial Analytics Jupyter notebook version of the Spatial Extender demo found here:
https://www.ibm.com/blogs/cloud-archive/2015/08/location-location-location/

Files:
samples/location/location_demo.ipynb - the Jupyter notebook
samples/location/load_data.sql       - support script to create the data tables run from the notebook
samples/location/README.txt          - a more detailed README
samples/data/geo_county.zip          - GEO_COUNTY table dataset
samples/data/geo_customer.zip        - GEO_CUSTOMER table dataset
