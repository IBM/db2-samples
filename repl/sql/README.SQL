
This directory contains sample programs for Replication.  In particular, this
note discusses the SQL Replication sample files.

-------------------------------------------------------------------------------

sql/apply_api.c
sql/apply_api_nt.mak
sql/apply_api_unix.mak

This sample program is an example of invoking the Apply API from within an
application.

-------------------------------------------------------------------------------

sql/ASNDONE.smp

ASNDONE is invoked by the Apply program after set subscription processing
completes, regardless of success or failure.  ASNDONE can be modified to meet
the requirements of your installation.  For example, the user exit can examine
the UOW table to discover rejected transactions and initiate further actions,
such as issuing a message or generating an alert.

-------------------------------------------------------------------------------

sql/ASNLOAD.smp

This sample program contains 4 major code paths:

    - one using DB2 EXPORT/IMPORT utilities
      (EXPORT/sqluexpt and IMPORT/sqluimpt utilities).

    - one using DB2 EXPORT/LOAD utilities
      (EXPORT/sqluexpr and LOAD/db2load utilities).

    - one using DB2 CROSSLOADER utility
      (CROSSLOADER/db2load utility).

    - one returning an error return code for an ALTERNATE FULL REFRESH to Apply
      (Return Code 1) if a use of the utilities is not applicable.


sql/asnload.h

This header file contains all common define clause declarations and macro
definitions used in the ASNLOAD.SMP and asnparseini.C.  It declares common
variables and defines types that are used in the whole package.


sql/asnload.ini

This sample file is used to configure the input for ASNLOAD.


sql/asnparseini.C

This sample file contains the logic for parsing the inifile asnload.ini.

-------------------------------------------------------------------------------

sql/capture_api.c
sql/capture_api_nt.mak
sql/capture_api_unix.mak

This sample program is an example of invoking the Capture API from within an
application.

-------------------------------------------------------------------------------

mig8/sql/mig8400.sql
mig8/sql/mig8fed.sql
mig8/sql/mig8udb.sql
mig8/sql/mig8zos.sql

V8 Replication Migration backup scripts.


mig8/sql/asnmigpw.C

This sample program migrates a version 7 Apply password file to a version 8
password file format.

-------------------------------------------------------------------------------

mon/monitor_api.c

This sample program contains code to start the Replication Alert Monitor.


mon/monitor_api_nt.mak

This makefile builds the code for the monitor_api.c sample program on Windows
operating systems.


mon/monitor_api_unix.mak

This makefile builds the code for the monitor_api.c sample program on Linux
and UNIX operating systems.


mon/asnmail.smp

This sample program is the IBM Replication Alert Monitor user exit, and is invoked
by the Alert Monitor program if a notification email is to be sent.

-------------------------------------------------------------------------------

sql/asnctlw.sql
sql/asnctlz.sql

These sample scripts create control tables for replication.

-------------------------------------------------------------------------------
