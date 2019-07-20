This directory contains sample programs for Replication.  In particular, this
note discusses the Q Replication sample files.

-------------------------------------------------------------------------------

Samples to set up Q replication and event publishing


q/asnqdefq

This sample script is an example that shows how Q replication and event
publishing interact with WebSphere MQ.  It includes commands to create queues
and queue definitions.  Use this sample script to quickly create and set up a
Q replication environment.


q/asnctlw.sql
q/asnctlz.sql

These sample scripts create control tables for replication.


asnqwxml

This directory shows an example of a web-based application for event publishing.
The sample demonstrates how to use an XML publication in a business scenario.


q/asnqspC.SQC

This sample program is an example of a stored procedure that is written in C.


q/asnqspcreate.sql

This sample script can create a stored procedure that is written in SQL.


q/asnqspSQL.sql

This sample script is an example of a SQL stored procedure that is written in
SQL.

-------------------------------------------------------------------------------

Samples to operate Q replication programs


q/qcapture_api.C

This sample C program contains code to start the Q Capture program.


q/qcapture_api_nt.mak

This makefile builds the code for the qcapture_api.c sample program on
Windows operating systems.


q/qcapture_api_unix.mak

This makefile builds the code for the qcapture_api.c sample program on Linux
and UNIX operating systems.


q/qapply_api.C

This sample C program contains code to start the Q Apply program.


q/qapply_api_nt.mak

This makefile builds the code for the qapply_api.c sample program on Windows
operating systems.


q/qapply_api_unix.mak

This makefile builds the code for the qapply_api.c sample program on Linux
and UNIX operating systems.


mon/monitor_api.c

This sample C program contains code to start the Replication Alert Monitor.


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

q/mqcap.xsd

The XML schema document for messages produced by the Q Capture program


q/mqsub.xsd

The XML schema document for messages from a user application to a Q Capture
program.

-------------------------------------------------------------------------------

There are 3 directories in V9:

samples/repl/q contains asnctlw.sql (UDB sample qrepl control tables)
and asnctlz.sql (z/OS sample qrepl control tables).

samples/repl/sql contains asnctlw.sql (UDB sample SQL repl control tables)
and asnctlz.sql (z/OS sample SQL repl control tables).

samples/repl/mon contains asnmctlw.sql (UDB sample monitor control tables)
and asnmctlz.sql (z/OS sample monitor control tables).

These sample scripts create control tables for replication.

