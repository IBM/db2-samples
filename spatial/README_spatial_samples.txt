README file for Db2 Spatial Analytics Samples

*
*
* (C) COPYRIGHT INTERNATIONAL BUSINESS MACHINES CORPORATION 2000, 2021.
*
     ALL RIGHTS RESERVED.
*


File: samples/spatial/README_spatial_samples.txt

The Db2 Spatial Analytics samples consist of one demo program.
  - One sample is based on banking (branches, customers, employees).
    This banking demo is written in SQL scripts run by the command-line
    processor (CLP).
This file briefly introduces the demo and indicates where to look for
further information.


= = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = =
The Banking Demo is implemented in SQL scripts that are run with the Db2
command line processor. You can use the demo and scripts as a tutorial.
The scripts and README file "saBankDemoREADME.txt" are located in the
"bank" subdirectory (sqllib/extenders/samples/spatial/bank).
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

