*******************************************************************************
   README for II Federated User Mapping LDAP Sample Plugin on UNIX Platforms
*******************************************************************************

I) Note:
--------

 In this README file, the /samples and /function directories are relative 
 paths to the DB2 instance directory. We assume that your DB2 instance is 
 installed at $DB2PATH. For example, if $DB2PATH is /home/db2inst1/sqllib, 
 then the full paths of the /samples and /function directories should be 
 /home/db2inst1/sqllib/samples and /home/db2inst1/sqllib/function.

 This Java sample plugin demonstrates the process to build a Java plugin for
 the federated server to get user mapping information from an external 
 repository such as a LDAP server.

 The string enclosed by < and > represents that you need to customize to 
 your own string. For example <iiAuthid> should be replaced by your real 
 userid to logon to the federated server.

 Prerequisite: This LDAP plugin sample requires you have Java Development Kit
               JDK 1.4.1 or higher installed.

II) What is each file about?
----------------------------

 This README and the sample codes are under the /samples/federated/umplugin/ldap
 directory. To access this directory to deploy the sample plugin, you must 
 install the DB2 Application Development Client. 

 schema.ldif
    LDAP schema extension for user mapping assumed by this sample plugin.
    It should be loaded to the LDAP server.

 entry.ldif
    A few LDAP user mapping entries used for testing this sample plugin.
    It should be loaded to the LDAP server.

 UserMappingRepositoryLDAP 
    The derived java class that contains the actual connect, fetchUM 
    and disconnect implementations. 

 UserMappingCryptoLDAP.java 
    The derived java class that contains the actual encode, decode, 
    encrypt, decrypt implementations. 

 UserMappingSetupLDAP.java 
    The java class that sets up the sample plugin's configuration 
    parameters in a file with the matching name, i.e., 
    UserMappingRepositoryLDAP.cfg.

 UserMappingLookupLDAP.java
    The java class that calls the lookupUM method of UserMappingRepository 
    class to perform the standalone lookup test before integrating into
    the federated server. 
    Note UserMappingRepositoryLDAP class inherited lookupUM method
    from its parent, i.e., UserMappingRepository class.

III) How to deploy this sample plugin?
--------------------------------------

1) Copy /samples/federated/umplugin/ldap/* to an empty working directory.

2) Compile and archive the java codes with the following commands:
     javac -classpath $DB2PATH/java/db2umplugin.jar:$CLASSPATH \
       -d . \
       ./UserMappingRepositoryLDAP.java \
       ./UserMappingCryptoLDAP.java \
       ./UserMappingSetupLDAP.java \
       ./UserMappingLookupLDAP.java

     jar -cfM0 UserMappingRepositoryLDAP.jar .
 
   You must add your JDK path into UNIX $PATH environment variable
   in order to use the right javac, jar and java commands.

Before you proceed further, you need to ensure the following:
A) know your LDAP server's configuration information such as 
   host name or IP address, port number, userid/password, 
   SSL setting as well as related certificates etc. 
B) load /samples/federated/umplugin/ldap/schema.ldif and 
   /samples/federated/umplugin/ldap/entry.ldif to your LDAP server
   in order to try out the sample plugin.

3) Setup the config file UserMappingRepositoryLDAP.cfg with the commond:
     java -classpath $DB2PATH/java/db2umplugin.jar:./UserMappingRepositoryLDAP.jar:$CLASSPATH UserMappingSetupLDAP
   
   You must follow the prompt of the setup program to enter the
   required parameters very carefully, There is no default provided.

4) Run the lookup test with the commamd: 
  java -classpath $DB2PATH/java/db2umplugin.jar:./UserMappingRepositoryLDAP.jar:$CLASSPATH \
    UserMappingLookupLDAP -server <remoteServerName> -authid <iiAuthid> -instance <iiInstance> -database <iiDatabase> 

   You must specify the server, authid, instance and database in the command line
   in order for the plugin to find the right user mapping entry.

5) Integrate the sample plugin with the federated server.
   Ensure you have write permission to /function directory and copy your
   UserMappingRepositoryLDAP.jar and UserMappingRepositoryLDAP.cfg over. 

6) Test if the sample plugin is used by the federated server.

  6.1) Set the database manager configuration parameter FEDERATED to YES.
       db2 update dbm cfg using FEDERATED YES

  6.2) Set the database manager configuration parameter JDK_PATH correctly.
       db2 update dbm cfg using JDK_PATH <your_jdk_path>
       You can use an empty string, '', if you have used JDK installed 
       under $DB2PATH/java directory.

  6.3) After you have updated the database manager configuration, you have
       to restart DB2 and create a few things:
       db2 terminate
       db2stop
       db2start
       db2 "create database <iiDatabase>"
       db2 "connect to <iiDatabase> user newton using <newtonPassword>"
       db2 "create table newton.t1(c1 int)"
       db2 "connect reset"
 
  6.4) Connect to your database, create wrapper and/or server with DB2_UM_PLUGIN
       option specified.
       db2 "connect to <iiDatabase> user <iiAuthid> using <iiPassword>"
       db2 "create wrapper drda"
       db2 "create server <iiRemoteServerName> type DB2/CS version 8 wrapper drda authorization <iiAuthid> password <iiPassword> options (dbname <iiDatabase>, DB2_UM_PLUGIN 'UserMappingRepositoryLDAP');
       db2 "create nickname <iiAuthid>.nick1 for <iiRemoteServerName>.newton.t1"

       Note: This last create nickname statement internally will invoke 
       the sample plugin to read user mapping (iiAuthid->newton) information
       back from the LDAP server in order to create the nickname successfully. 

IV. How to deploy your own LDAP plugin starting from this sample codes? 

Starting from the sample codes, 

1) schema.ldif and entry.ldif contains schema extension for user mapping
   and some user mapping entries that this sample plugin assumed. 
   In your case, you need to customize your UserMappingRepositoryLDAP.java, 
   UserMappingCryptoLDAP.java implementation to fit your own LDAP schema 
   extension and user mapping entry layout.
2) Use UserMappingRepositorySetup.java to set up the configuration file.
3) Use UserMappingRepositoryLookup.java to test the lookup.
4) Be careful that if you decide to rename UserMappingRepositoryLDAP to
something else, ensure all the relevant files are renamed consistently
that include UserMappingRepositoryLDAP.java, UserMappingRepositoryLDAP.jar
and UserMappingRepositoryLDAP.cfg. 
 
For more information on developing Java user mapping plugin, please
see the Federated System Guide.
