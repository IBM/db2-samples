*****************************************************************************
* README for DB2 Java Sample Wrapper
*
* NOTE:
* Inside this README file the samples and function directories are relative
* paths to the DB2 instance directory. Moreover, this README file assumes that
* the DB2 instance is installed at $HOME/sqllib, where $HOME represents the
* home directory of the current user.  For example, if your DB2 instance is
* installed at /home/db2inst1/sqllib, than the full path of the samples
* directory is /home/db2inst1/sqllib/samples and the full path of the function
* directory is /home/db2inst1/sqllib/function.
*
* The samples/wrapper_sdk_java directory contains this README file, the javadoc
* files for the Java Wrapper API classes and the Java files for creating the
* Java sample flat-file wrapper.
*
* This README file describes the sample files in this directory.
* It is recommended that you copy the files from this directory to your
* working directory prior to building the sample program.
*
* To access and build the DB2 Java sample wrapper under the 
* samples/wrapper_sdk_java directory, you must:
*
* 1. Install the DB2 Base Application Development Tools
* 2. Install the DB2 Sample Applications
*
* To run the DB2 Java sample wrapper under the samples/wrapper_sdk_java
* directory, you must install the DB2 Enterprise Server Edition.
*
* For information on developing Java wrappers for federated databases,
* see the IBM DB2 Information Integrator Wrapper Developer's Guide and
* the IBM DB2 Information Integrator Java API Reference for Developing
* Wrappers.
*
* For the latest information on developing and building Java applications 
* for DB2, visit the DB2 Java website at 
* http://www.software.ibm.com/data/db2/java.
*
*****************************************************************************
*
*               QUICKSTART
*
*  1) Copy the files samples/wrapper_sdk_java/*.java to your working directory.
*
*  2) To deploy the Java sample wrapper, ensure that you have write permission
*     to the $HOME/sqllib/function directory.
*
*  3) Compile and deploy the Java sample wrapper to sqllib/function by running
*     the following command from a DB2 CLP window in your working directory. 
*        javac -classpath $HOME/sqllib/java/db2qgjava.jar:$CLASSPATH \
*              -d $HOME/sqllib/function \
*              UnfencedFileWrapper.java \
*              UnfencedFileServer.java \
*              UnfencedFileNickname.java \
*              FencedFileWrapper.java \
*              FencedFileServer.java \
*              FencedFileNickname.java \
*              FileConnection.java \
*              FileQuery.java \
*              FileExecDesc.java
*
*  4) To run the Java sample wrapper, you need to:
*
*     1. Enable the database for federation.
*        By default, your database manager configuration parameter FEDERATED is
*        set to NO. If this is true, update the database manager configuration
*        using the following command:
*          db2 update dbm cfg using FEDERATED YES
*
*     2. Set the database manager configuration parameter JDK_PATH to point to
*        a valid JDK installation. To achieve that replace <your_jdk_path> in
*        the following command to the actual path for your JDK installation and
*        execute the command:
*          db2 update dbm cfg using JDK_PATH <your_jdk_path>
*        You can use an empty string, '', if you have a JDK installed under
*        $HOME/sqllib/java/jdk directory.
*
*     3. Increase the heap size for the Java VM.
*        By default, the Java VM heap size is set to 512 blocks of 4k.
*        The recommended value for the sample wrapper is 1024 blocks of 4k
*        or more. To set the Java VM heap size to 1024 blocks of 4k execute
*        the following command:
*          db2 update dbm cfg using JAVA_HEAP_SZ 1024
*
*     4. After you have updated the database manager configuration, you have
*        to restart DB2 using the following commands:
*          db2 terminate
*          db2stop
*          db2start
*
*     5. Create a sample data file by executing the following commands:
*        echo "1,first string"  > $HOME/sample_file_a.txt
*        echo "2,second string" >> $HOME/sample_file_a.txt
*        echo "3,third string"  >> $HOME/sample_file_a.txt
*
*     6. Connect to your database and create the wrapper by executing the
*        appropriate command for your operating system:
*        
*        AIX:
*          db2 "create wrapper file_wrapper library 'libdb2qgjava.a' \
*              options( UNFENCED_WRAPPER_CLASS 'UnfencedFileWrapper')"
*        Linux:
*          db2 "create wrapper file_wrapper library 'libdb2qgjava.so' \
*              options( UNFENCED_WRAPPER_CLASS 'UnfencedFileWrapper')"
*        HPUX:
*          db2 "create wrapper file_wrapper library 'libdb2qgjava.sl' \
*              options( UNFENCED_WRAPPER_CLASS 'UnfencedFileWrapper')"
*        Solaris:
*          db2 "create wrapper file_wrapper library 'libdb2qgjava.so' \
*              options( UNFENCED_WRAPPER_CLASS 'UnfencedFileWrapper')"
*
*     7. Create a server and a nickname by executing the following commands:
*          db2 "create server file_server wrapper file_wrapper"
*          db2 "create nickname file_a(number integer, text char(20)) \
*              for server file_server options(file_path '$HOME/sample_file_a.txt')"
*
*     8. Retrieve data from the sample nickname with the command:
*          db2 "select * from file_a"
*
******************************************************************************
*
*               Java Sample Wrapper Description
*
* The Java Sample Wrapper demonstrate the process to build a Java wrapper for
* DB2 Information Integrator. A wrapper allows DB2 to obtain information from
* data sources that have a common programmatic interface. The process of
* writing a Java Wrapper consists in implementing a set of services in a
* collection of classes that extend and use the DB2 Information Integrator
* Java API for Developing Wrappers.
* For more information on the Java Sample Wrapper, refer to the Java Sample
* Wrapper source code files.
*
******************************************************************************

