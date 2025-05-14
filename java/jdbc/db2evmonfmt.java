//*************************************************************************
// (c) Copyright IBM Corp. 2008 All rights reserved.
//
// The following sample of source code ("Sample") is owned by International
// Business Machines Corporation or one of its subsidiaries ("IBM") and is
// copyrighted and licensed, not sold. You may use, copy, modify, and
// distribute the Sample in any form without payment to IBM, for the purpose of
// assisting you in the development of your applications.
//
// The Sample code is provided to you on an "AS IS" basis, without warranty of
// any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
// IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
// not allow for the exclusion or limitation of implied warranties, so the above
// limitations or exclusions may not apply to you. IBM shall not be liable for
// any damages you suffer as a result of using, copying, modifying or
// distributing the Sample, even if IBM has been advised of the possibility of
// such damages.
//*************************************************************************
//
// SOURCE FILE NAME: db2evmonfmt.java
//
// SAMPLE: Extract the XML report from the event monitor
//
// Steps to run the sample with command line window:
//
//   1) Copy the following file to your working directory and ensure that
//      directory has write permission:
//
//      <install_path>/samples/java/jdbc/db2evmonfmt.java
//      <install_path>/samples/java/jdbc/*.xsl
//
//   2) Modify the CLASSPATH to include:
//
//         <install_path>/sqllib/java/db2java.zip
//         <install_path>/sqllib/java/db2jcc.jar
//         <install_path>/sqllib/java/db2jcc_license_cu.jar
//         <install_path>/sqllib/java/<jdkDirName>/lib
//         <install_path>/sqllib/lib
//         <install_path>/sqllib/function
//         <install_path>/sqllib/java/sqlj.zip
//      where <jdkDirName> is the name of the
//      jdk directory under <install_path>/sqllib/java.
//
//   3) Modify the PATH to include <install_path>/sqllib/java/<jdkDirName>/bin,
//      <install_path>/sqllib/lib.
//
//   4) Modify the LD_LIBRARY_PATH to include <install_path>/sqllib/lib
//
//   5) Compile the source file with: javac db2evmonfmt.java
//
//   6) Run the program: java db2evmonfmt -h
//      for command line options.
//
// USAGE:
//
//   db2evmonfmt -d <dbname> [-ue <uetable> | -wtt <wttEvmonName>] [ -u userid -p passwd ]
//               < -fxml | -ftext [-ss stylesheet] >
//               [ -id <eventid>     ]
//               [ -type <eventype>  ]
//               [ -hours <hours>    ]
//               [ -w <workloadname> ]
//               [ -s <serviceclass> ]
//               [ -a <applname>     ]
//
//  OR
//
//  db2evmonfmt -f xmlfile < -fxml | -ftext [-ss stylesheet] >
//
//   where:
//
//        dbname     : Database name
//        uetable    : Name of the unformatted event table
//        wttEvmonName  : Name of the write to table event monitor. Note: event monitor name is case sensitive.
//        userid     : User ID
//        passwd     : Password
//
//        xmlfile    : Input XML file to format
//
//        fxml       : Pretty print the XML document to stdout
//        ftext      : Format XML document to text using the default XSLT
//                     stylesheet, pipe to stdout
//
//        stylesheet : Use the following XSLT stylesheet to format to format
//                     the XML documents
//
//        id         : Display all events matching <eventid>
//        type       : Display all events matching event type <eventtype>
//        hours      : Display all events that have occurred in the last
//                     <hours> hours
//        w          : Display all events where the event is part of
//                     workload <workloadname>
//
//                     For the Lock Event monitor, this will display all events
//                     where the lock requestor is part of <workloadname>
//
//        s          : Display all events where the event is part of
//                     service class <serviceclass>
//
//                     For the Lock Event monitor, this will display all events
//                     where the lock requestor is part of <serviceclass>
//
//        a          : Display all events where the event is part of
//                     application name <applname>
//
//                     For the Lock Event monitor, this will display all events
//                     where the lock requestor is part of <applname>
//
//  For write to table event monitors, only dbname, wtt tag, output type(text or pretty print) are supported.
//  See example No.4. 
//
//  Examples:
//
//  1. Get all events that are part of workload PAYROLL in the last 32 hours from
//     UE table PKG in database SAMPLE.
//
//     java db2evmonfmt -d SAMPLE -ue PKG -ftext -hours 32 -w PAYROLL
//
//  2. Get all events of type LOCKTIMEOUT that have occurred in the last 48
//     from UE table LOCK in database SAMPLE.
//
//     java db2evmonfmt -d SAMPLE -ue LOCK -ftext -hours 48 -type LOCKTIMEOUT
//
//  3. Format the event contained in the file LOCK.XML using stylesheet
//     MYREPORT.xsl
//
//     java db2evmonfmt -f lock.xml -ftext -ss myreport.xsl
//  
//  4. Get all events from the write to table event monitor T1 in database sample:
//     java db2evmonfmt -d sample -wtt T1 -ftext
//
//*************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//**************************************************************************/

import java.lang.*;                   // for String class
import java.io.*;                     // for ...Stream classes
import java.io.Writer;                     // for ...Stream classes
import COM.ibm.db2.app.StoredProc;    // Stored Proc classes
import java.sql.*;                    // for JDBC classes
import com.ibm.db2.jcc.*;             // for XML class
import java.util.*;                   // Utility classes

import javax.xml.transform.*;
import javax.xml.transform.stream.*;

import org.w3c.dom.Document;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.DocumentBuilder;
import org.w3c.dom.*;

import org.xml.sax.*;
import javax.xml.parsers.*;
import org.xml.sax.helpers.*;
import javax.xml.validation.*;
import javax.xml.transform.*;
import javax.xml.transform.stream.StreamSource;

/*!
 *  /brief Class db2evmonfmt
 *
 *  Class extracts the XML records from an Event Monitor Raw Table and
 *  formats the XML report to stdout.
 */
public class db2evmonfmt
{
   static String dbName = "";
   static String userid = "";
   static String passwd = "";
   static String uetable = "";
   static String wttEvmonName = "";

   static String styleSheet = "";
   static String xmlInputFilename = "";
   static String xmlSchemaInputFilename = "";

   static Boolean bPrettyPrint = false;
   static Boolean bFormatText = false;

   static String workloadName = "";
   static String serviceClass = "";
   static String applName     = "";

   static SAXParserFactory fFactory;
   static SAXParser parser;

   static int eventID = -1;
   static String eventType = "";
   static int hours = 0;
   static String mode = "";

   public static final int EVENT_ID   = 0;
   public static final int EVENT_TYPE = 1;
   public static final int EVENT_WORKLOAD = 2;
   public static final int EVENT_SRVCLASS = 3;
   public static final int EVENT_APPLNAME = 4;

   static String lockEvent = "<db2_lock_event";
   static String uowEvent = "<db2_uow_event";
   static String pkgCacheEvent = "<db2_pkgcache_event";
   static String chgHistEvent = "<db2_change_history_event";

   /*!
    *  /brief Main Driver
    *
    *  Main function driver that formats the XML report to stdout.
    */
   public static void main(String argv[])
   {
      try
      {
         //--------------------------------------------------------
         // Parse the Command Line Arguements
         //--------------------------------------------------------
         ParseArguments(argv);
         Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();

         //--------------------------------------------------------
         // Retrieve the XML documents from the database
         //--------------------------------------------------------
         if ((dbName.length() != 0) && (uetable.length() != 0) && (mode.equals("UE")))
         {
            RetrieveXMLDocumentsFromEvmonUE();
         }
         //-----------------------------------------------------------
         // If the event monitor is write to table, pass it to handler
         //-----------------------------------------------------------
         else if ((dbName.length() != 0) && (wttEvmonName.length() != 0) && (mode.equals("WTT")))
         {
            wttTypeHandler();
         }
         //--------------------------------------------------------
         // Format the input file document
         //--------------------------------------------------------
         else if (xmlInputFilename.length() != 0)
         {
            FormatInputXMLFile();
         }
      }
      catch (Exception f)
      {
         System.out.println(f.getMessage());
         System.out.println();
      }

      return ;
   } // end main


   /*!
    *  /brief wttTypeHandler
    *
    *  Function looks up evmon type and then routes code to the type specific
    *  formatting functions
    */
   public static void wttTypeHandler() throws Exception
   {
     Connection con = null;
     PreparedStatement stmt_type = null;
     String type = "";
     try
     {
        //----------------------------------------------------------
        // Connect to database
        //----------------------------------------------------------
        con= DriverManager.getConnection(dbName, userid, passwd);
        con.setAutoCommit(false);
        SetTenantToSystem(con);

        wttEvmonName = wttEvmonName.trim();

        //----------------------------------------------------------
        // Retrieve event monitor from syscat. Try first with evmon
        // name enclosed in quotes (i.e. respect case of input evmon
        // name). If evmon cannot be found as input, try upper case
        // since DB2 would naturally upper case the evmon name when
        // created if user did not create the name using quotations. 
        //----------------------------------------------------------
        String type_query = "SELECT TYPE FROM SYSCAT.EVENTS "+
                            "WHERE EVMONNAME = '" + wttEvmonName + "'";
        stmt_type = con.prepareStatement(type_query, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);

        ResultSet rs_type = stmt_type.executeQuery();

        if (!rs_type.isBeforeFirst())
        {
           rs_type.close();
           stmt_type.close();

           wttEvmonName = wttEvmonName.toUpperCase();

           type_query = "SELECT TYPE FROM SYSCAT.EVENTS "+
                            "WHERE EVMONNAME = '" + wttEvmonName + "'";

           stmt_type = con.prepareStatement(type_query, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
           rs_type = stmt_type.executeQuery();
        }

        rs_type.beforeFirst(); 

        //----------------------------------------------------------
        // Apply different functions for different types of monitor
        //----------------------------------------------------------
        if (rs_type.next())
        {
           type = rs_type.getString("TYPE");
        }
        if ( type.equals("PKGCACHEBASE") || type.equals("PKGCACHEDETAILED") )
        {
           RetrieveXMLDocumentsFromEvmonPKG();
        }
        else if ( type.equals("DEADLOCKS") || type.equals("DETAILEDDEADLOCKS") || type.equals("LOCKING") )
        {
           RetrieveXMLDocumentsFromEvmonLCK();
        }
        else if ( type.equals("UOW") )
        {
           RetrieveXMLDocumentsFromEvmonUOW();
        }
        else if ( type.equals("CHANGEHISTORY") )
        {
           RetrieveXMLDocumentsFromEvmonChgHist();
        }
        else
        {
           System.out.println("Type of event monitor is not found");
        }
        rs_type.close();
        stmt_type.close();
     }
     catch (SQLException e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        if (con != null)
        {
           try
           {
              con.rollback();
           }
           catch (Exception error)
           {
           }
        }
        else
        {
            System.out.println("Connection to db " + dbName + " can't be established.");
            System.out.println(e);
        }
        System.exit(1);
     }
     catch (Exception e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        System.exit(1);
     }
   }

   /*!
    *   Brief RetrieveXMLDocumentsFromEvmonChgHist
    *   
    *   Function to extract XMl document from change history event
    */
   public static void RetrieveXMLDocumentsFromEvmonChgHist() throws Exception
   {
     Connection con = null;
     Blob xmlRow = null;
     PreparedStatement stmt_fin = null;
     PreparedStatement stmt_chghist = null;
     PreparedStatement stmt_dbcfg = null;
     PreparedStatement stmt_ddl = null;
     PreparedStatement stmt_evs = null;
     PreparedStatement stmt_reg = null;
     PreparedStatement stmt_txn = null;
     PreparedStatement stmt_ustart = null;
     PreparedStatement stmt_ustop = null;
     PreparedStatement stmt_uloc = null;
     PreparedStatement stmt_uphase = null;
     String dbcfgName = "";
     String dbcfgSchema = "";
     String chghistName = "";
     String chghistSchema = "";
     String ddlName = "";
     String ddlSchema = "";
     String evsName = "";
     String evsSchema = "";
     String regName = "";
     String regSchema = "";
     String txnName = "";
     String txnSchema = "";
     String ustartName = "";
     String ustartSchema = "";
     String ustopName = "";
     String ustopSchema = "";
     String ulocName = "";
     String ulocSchema = "";
     String uphaseName = "";
     String uphaseSchema = "";
     byte[] docHeader = new byte[101];
     String reportType = null;

     try
     {
       con = DriverManager.getConnection(dbName, userid, passwd);
       con.setAutoCommit(false);
       SetTenantToSystem(con);

       //-----------------------------------------------------------------------
       // Get names and schemas for all the tables of change hist event monitor
       //-----------------------------------------------------------------------
       String dbcfgTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                         "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                         "LOGICAL_GROUP = 'DBDBMCFG'";
       String ddlTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'DDLSTMTEXEC'";
       String evsTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'EVMONSTART'";
       String regTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'REGVAR'";
       String txnTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'TXNCOMPLETION'";
       String ustartTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                          "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                          "LOGICAL_GROUP = 'UTILSTART'";
       String ustopTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                         "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                         "LOGICAL_GROUP = 'UTILSTOP'";
       String ulocTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                        "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                        "LOGICAL_GROUP = 'UTILLOCATION'";
       String uphaseTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                          "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                          "LOGICAL_GROUP = 'UTILPHASE'";
       String chghistTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES " +
                           "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                           "LOGICAL_GROUP = 'CHANGESUMMARY'";
       stmt_dbcfg = con.prepareStatement(dbcfgTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_ddl = con.prepareStatement(ddlTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_evs = con.prepareStatement(evsTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_reg = con.prepareStatement(regTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_txn = con.prepareStatement(txnTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_ustart = con.prepareStatement(ustartTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_ustop = con.prepareStatement(ustopTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_uloc = con.prepareStatement(ulocTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_uphase = con.prepareStatement(uphaseTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_chghist = con.prepareStatement(chghistTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       ResultSet rs_dbcfg = stmt_dbcfg.executeQuery();
       ResultSet rs_ddl = stmt_ddl.executeQuery();
       ResultSet rs_evs = stmt_evs.executeQuery();
       ResultSet rs_reg = stmt_reg.executeQuery();
       ResultSet rs_txn = stmt_txn.executeQuery();
       ResultSet rs_ustart = stmt_ustart.executeQuery();
       ResultSet rs_ustop = stmt_ustop.executeQuery();
       ResultSet rs_uloc = stmt_uloc.executeQuery();
       ResultSet rs_uphase = stmt_uphase.executeQuery();
       ResultSet rs_chghist = stmt_chghist.executeQuery();
       rs_dbcfg.beforeFirst();
       rs_chghist.beforeFirst();

       if (rs_dbcfg.next())
       {
         dbcfgName = "\"" + rs_dbcfg.getString("TABNAME") + "\"";
         dbcfgSchema = "\"" + rs_dbcfg.getString("TABSCHEMA") + "\"";
       }
       if (rs_ddl.next())
       {
         ddlName = "\"" + rs_ddl.getString("TABNAME") + "\"";
         ddlSchema = "\"" + rs_ddl.getString("TABSCHEMA") + "\"";
       }
       if (rs_evs.next())
       {
         evsName = "\"" + rs_evs.getString("TABNAME") + "\"";
         evsSchema = "\"" + rs_evs.getString("TABSCHEMA") + "\"";
       }
       if (rs_reg.next())
       {
         regName = "\"" + rs_reg.getString("TABNAME") + "\"";
         regSchema = "\"" + rs_reg.getString("TABSCHEMA") + "\"";
       }
       if (rs_txn.next())
       {
         txnName = "\"" + rs_txn.getString("TABNAME") + "\"";
         txnSchema = "\"" + rs_txn.getString("TABSCHEMA") + "\"";
       }
       if (rs_ustart.next())
       {
         ustartName = "\"" + rs_ustart.getString("TABNAME") + "\"";
         ustartSchema = "\"" + rs_ustart.getString("TABSCHEMA") + "\"";
       }
       if (rs_ustop.next())
       {
         ustopName = "\"" + rs_ustop.getString("TABNAME") + "\"";
         ustopSchema = "\"" + rs_ustop.getString("TABSCHEMA") + "\"";
       }
       if (rs_uloc.next())
       {
         ulocName = "\"" + rs_uloc.getString("TABNAME") + "\"";
         ulocSchema = "\"" + rs_uloc.getString("TABSCHEMA") + "\"";
       }
       if (rs_uphase.next())
       {
         uphaseName = "\"" + rs_uphase.getString("TABNAME") + "\"";
         uphaseSchema = "\"" + rs_uphase.getString("TABSCHEMA") + "\"";
       }
       if (rs_chghist.next())
       {
         chghistName = "\"" + rs_chghist.getString("TABNAME") + "\"";
         chghistSchema = "\"" + rs_chghist.getString("TABSCHEMA") + "\"";
       }
       
       //-------------------------------------------------------------------------------
       // Retrieve xml, if the table exist, add corresponding query to the query string
       //-------------------------------------------------------------------------------
       String queryChghist = "WITH ";
       if ( !dbcfgName.equals("") )
       {
         queryChghist +=  "DBDBMCFG(EVENT_ID, " +
                                   "EVENT_TIMESTAMP, " +
                                   "MEMBER, " +
                                   "DBCFGROW " +
                          ") AS (" +
                          "select event_id, " +
                                 "event_timestamp, " +
                                 "member, " +
                                 "xmlagg( " +
                                 "xmlelement(name \"dbcfg_row\", " +
                                            "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                            "xmlelement(name \"cfg_name\", cfg_name), " +
                                            "xmlelement(name \"cfg_value\", cfg_value), " +
                                            "xmlelement(name \"cfg_value_flags\", cfg_value_flags), " +
                                            "xmlelement(name \"cfg_old_value\", cfg_old_value), " +
                                            "xmlelement(name \"cfg_old_value_flags\", cfg_old_value_flags), " +
                                            "xmlelement(name \"collection_type\", collection_type), " +
                                            "xmlelement(name \"deferred\", deferred) ) ) " +
                          "from " + dbcfgSchema + "." + dbcfgName + " " +
                          "group by event_id, event_timestamp, member) ";
       }
       if (!ddlName.equals("") )
       {
         queryChghist += ", DDLSTMTEXEC(EVENT_ID, " +
                                       "EVENT_TIMESTAMP, " +
                                       "MEMBER, " +
                                       "DDL) " +
                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " +
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"ddlstmt_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"partition_key\", partition_key), " +
                                             "xmlelement(name \"global_transaction_id\", global_transaction_id), " +
                                             "xmlelement(name \"local_transaction_id\", local_transaction_id), " +
                                             "xmlelement(name \"savepoint_id\", savepoint_id), " +
                                             "xmlelement(name \"uow_id\", uow_id), " +
                                             "xmlelement(name \"ddl_classification\", ddl_classification), " +
                                             "xmlelement(name \"stmt_text\", stmt_text) ) ) " +
                          "from " + ddlSchema + "." + ddlName + " " +
                          "group by event_id, event_timestamp, member) ";
       }
       if (!evsName.equals(""))
       {
         queryChghist += ", EVMONSTART(EVENT_ID, " +
                                      "EVENT_TIMESTAMP, " +
                                      "MEMBER, " +
                                      "ESROW) " +
                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " +
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"evmonstart_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"db2start_time\", db2start_time), " +
                                             "xmlelement(name \"db_conn_time\", db_conn_time) ) ) " +
                           "from " + evsSchema + "." + evsName + " " +
                           "group by event_id, event_timestamp, member) ";
       }
       if (!regName.equals(""))
       {
         queryChghist += ", REGVAR(EVENT_ID, " +
                                  "EVENT_TIMESTAMP, " +
                                  "MEMBER, " +
                                  "REGROW) " +
                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " +
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"regvar_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"regvar_collection_type\", regvar_collection_type), " +
                                             "xmlelement(name \"regvar_level\", regvar_level), " +
                                             "xmlelement(name \"regvar_name\", regvar_name), " +
                                             "xmlelement(name \"regvar_old_value\", regvar_old_value), " +
                                             "xmlelement(name \"regvar_value\", regvar_value) ) ) " +
                          "from " + regSchema + "." + regName + " " +
                          "group by event_id, event_timestamp, member)";
       }

       if (!txnName.equals(""))
       {
         queryChghist += ", TXNC(EVENT_ID, " +
                                "EVENT_TIMESTAMP, " +
                                "member, " +
                                "TXNROW) " +

                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " +
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"txn_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"global_transaction_id\", global_transaction_id), " +
                                             "xmlelement(name \"local_transaction_id\", local_transaction_id), " +
                                             "xmlelement(name \"savepoint_id\", savepoint_id), " +
                                             "xmlelement(name \"txn_completion_status\", txn_completion_status), " +
                                             "xmlelement(name \"uow_id\", uow_id) ) ) " +
                          "from " + txnSchema + "." + txnName + " " +
                          "group by event_id, event_timestamp, member) ";
       }
       if (!ustartName.equals(""))
       {
         queryChghist += ", UTILSTART(EVENT_ID, " +
                                     "EVENT_TIMESTAMP, " +
                                     "MEMBER, " +
                                     "STARTROW) " +
                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " + 
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"utilstart_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"num_tbsps\", num_tbsps), " +
                                             "xmlelement(name \"object_name\", object_name), " +
                                             "xmlelement(name \"object_schema\", object_schema), " +
                                             "xmlelement(name \"object_type\", object_type), " +
                                             "xmlelement(name \"tbsp_names\", tbsp_names), " +
                                             "xmlelement(name \"utility_detail\", utility_detail), " +
                                             "xmlelement(name \"utility_invocation_id\", utility_invocation_id), " +
                                             "xmlelement(name \"utility_invoker_type\", utility_invoker_type), " +
                                             "xmlelement(name \"utility_operation_type\", utility_operation_type), " +
                                             "xmlelement(name \"utility_priority\", utility_priority), " +
                                             "xmlelement(name \"utility_start_type\", utility_start_type), " +
                                             "xmlelement(name \"utility_type\", utility_type) ) ) " +
                           "from " + ustartSchema + "." + ustartName + " " +
                           "group by event_id, event_timestamp, member) ";
       }
       if (!ulocName.equals(""))
       {
         queryChghist += ", UTILLOC(EVENT_ID, " +
                                   "EVENT_TIMESTAMP, " +
                                   "MEMBER, " +
                                  "LOCROW) " +
                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " +
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"utilloc_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"device_type\", device_type), " +
                                             "xmlelement(name \"location\", location), " +
                                             "xmlelement(name \"location_type\", location_type), " +
                                             "xmlelement(name \"utility_invocation_id\", utility_invocation_id), " +
                                             "xmlelement(name \"utility_type\", utility_type) ) ) " +
                           "from " + ulocSchema + "." + ulocName + " " +
                           "group by event_id, event_timestamp, member) ";
       }
       if (!ustopName.equals(""))
       {
         queryChghist += ", UTILSTOP(EVENT_ID, " +
                                    "EVENT_TIMESTAMP, " +
                                    "MEMBER, " +
                                    "STOPROW) " +
                           "AS ( " +
                           "select event_id, " +
                                  "event_timestamp, " +
                                  "member, " +
                                  "xmlagg( " +
                                  "xmlelement(name \"utilstop_row\", " +
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                             "xmlelement(name \"sqlcabc\", sqlcabc), " +
                                             "xmlelement(name \"sqlcaid\", sqlcaid), " +
                                             "xmlelement(name \"sqlcode\", sqlcode), " +
                                             "xmlelement(name \"sqlerrd1\", sqlerrd1), " +
                                             "xmlelement(name \"sqlerrd2\", sqlerrd2), " +
                                             "xmlelement(name \"sqlerrd3\", sqlerrd3), " +
                                             "xmlelement(name \"sqlerrd4\", sqlerrd4), " +
                                             "xmlelement(name \"sqlerrd5\", sqlerrd5), " +
                                             "xmlelement(name \"sqlerrd6\", sqlerrd6), " +
                                             "xmlelement(name \"sqlerrm\", sqlerrm), " +
                                             "xmlelement(name \"sqlstate\", sqlstate), " +
                                             "xmlelement(name \"sqlwarn\", sqlwarn), " +
                                             "xmlelement(name \"start_event_id\", start_event_id), " +
                                             "xmlelement(name \"start_event_timestamp\", start_event_timestamp), " +
                                             "xmlelement(name \"utility_invocation_id\", utility_invocation_id), " +
                                             "xmlelement(name \"utility_stop_type\", utility_stop_type), " +
                                             "xmlelement(name \"utility_type\", utility_type) ) ) " +
                         "from " + ustopSchema + "." + ustopName + " " +
                         "group by event_id, event_timestamp, member)";
       }
       if (!uphaseName.equals(""))
       {
         queryChghist += ", UTILPHASE(EVENT_ID, " +
                 "EVENT_TIMESTAMP, " +
                 "MEMBER, " +
                 "PHASEROW) " +
       "AS ( " +
       "select event_id, " +
              "event_timestamp, " +
              "member, " +
              "xmlagg( " +
              "xmlelement(name \"utilphase_row\", " +
                         "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                         "xmlelement(name \"object_name\", object_name), " +
                         "xmlelement(name \"object_schema\", object_schema), " +
                         "xmlelement(name \"object_type\", object_type), " +
                         "xmlelement(name \"phase_start_event_id\", phase_start_event_id), " +
                         "xmlelement(name \"phase_start_event_timestamp\", phase_start_event_timestamp), " +
                         "xmlelement(name \"utility_invocation_id\", utility_invocation_id), " +
                         "xmlelement(name \"utility_phase_detail\", utility_phase_detail), " +
                         "xmlelement(name \"utility_phase_type\", utility_phase_type), " +
                         "xmlelement(name \"utility_type\", utility_type) ) ) " +
       "from " + uphaseSchema + "." + uphaseName + " " +
       "group by event_id, event_timestamp, member) ";
       }

       queryChghist += "SELECT A.EVENT_ID, " +
              "A.EVENT_TIMESTAMP, " +
              "A.MEMBER, " +
              "xmlserialize(xmlelement(name \"db2_change_history_event\", " +
                         "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                         "xmlattributes(a.event_id as \"id\", " +
                                       "a.event_type as \"type\", " +
                                       "a.event_timestamp as \"timestamp\", " +
                                       "a.member as \"member\", " +
                                       "'1050300' as \"release\"), " +
                         "xmlelement(name \"event_summary\", " +
                                    "xmlelement(name \"appl_id\", appl_id), " +
                                    "xmlelement(name \"appl_name\", appl_name), " +
                                    "xmlelement(name \"application_handle\", application_handle), " +
                                    "xmlelement(name \"backup_timestamp\", backup_timestamp), " +
                                    "xmlelement(name \"client_acctng\", client_acctng), " +
                                    "xmlelement(name \"client_applname\", client_applname), " +
                                    "xmlelement(name \"client_hostname\", client_hostname), " +
                                    "xmlelement(name \"client_pid\", client_pid), " +
                                    "xmlelement(name \"client_platform\", client_platform), " +
                                    "xmlelement(name \"client_port_number\", client_port_number), " +
                                    "xmlelement(name \"client_protocol\", client_protocol), " +
                                    "xmlelement(name \"client_userid\", client_userid), " +
                                    "xmlelement(name \"client_wrkstnname\", client_wrkstnname), " +
                                    "xmlelement(name \"coord_member\", coord_member), " +
                                    "xmlelement(name \"session_authid\", session_authid), " +
                                    "xmlelement(name \"system_authid\", system_authid), " +
                                    "xmlelement(name \"utility_invocation_id\", utility_invocation_id), " +
                                    "xmlelement(name \"utility_type\", utility_type) )";
       if (!dbcfgName.equals(""))
       {
         queryChghist += ", xmlelement(name \"dbcfg_rows\", " +
                                      "DBCFGROW)";
       }
       if (!ddlName.equals(""))
       {
         queryChghist += ", xmlelement(name \"ddlstmt_rows\", " +
                                      "DDL)";
       }
       if (!evsName.equals(""))
       {
         queryChghist += ", xmlelement(name \"evmonstart_rows\", " +
                                      "ESROW)";
       }
       if (!regName.equals(""))
       {
         queryChghist += ", xmlelement(name \"regvar_rows\", " +
                                      "REGROW)";
       }
       if (!txnName.equals(""))
       {
         queryChghist += ", xmlelement(name \"txn_rows\", " +
                                      "TXNROW)";
       }
       if (!ustartName.equals(""))
       {
         queryChghist += ", xmlelement(name \"utilstart_rows\", " +
                                      "STARTROW)";
       }
       if (!ulocName.equals(""))
       {
         queryChghist += ", xmlelement(name \"utilloc_rows\", " +
                                      "LOCROW)";
       }
       if (!ustopName.equals(""))
       {
         queryChghist += ", xmlelement(name \"utilstop_rows\", " +
                                      "STOPROW)";
       }
       if (!uphaseName.equals(""))
       {
         queryChghist += ", xmlelement(name \"utilphase_rows\", " +
                                      "PHASEROW)";
       }
       queryChghist +=  ") as Blob(20M) ) as XMLREPORT " +
                        "from " + chghistSchema + "." + chghistName + " AS A ";
       if (!dbcfgName.equals(""))
       {
         queryChghist += "left join DBDBMCFG as B " +
                         "on A.EVENT_ID = B.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = B.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = B.MEMBER ";
       }
       if (!ddlName.equals(""))
       {
         queryChghist += "left join DDLSTMTEXEC AS C " +
                         "on A.EVENT_ID = C.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = C.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = C.MEMBER ";
       }
       if (!evsName.equals(""))
       {
         queryChghist += "left join EVMONSTART AS D " +
                         "on A.EVENT_ID = D.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = D.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = D.MEMBER ";
       } 
       if (!regName.equals(""))
       {
         queryChghist += "left join REGVAR AS E " +
                         "on A.EVENT_ID = E.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = E.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = E.MEMBER ";
       }
       if (!txnName.equals(""))
       {
         queryChghist += "left join TXNC AS F " +
                         "on A.EVENT_ID = F.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = F.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = F.MEMBER ";
       }
       if (!ustartName.equals(""))
       {
         queryChghist += "left join UTILSTART AS G " +
                         "on A.EVENT_ID = G.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = G.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = G.MEMBER ";
       }
       if (!ulocName.equals(""))
       {
         queryChghist += "left join UTILLOC AS H " +
                         "on A.EVENT_ID = H.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = H.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = H.MEMBER ";
       }
       if (!ustopName.equals(""))
       {
         queryChghist += "left join UTILSTOP AS I " +
                         "on A.EVENT_ID = I.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = I.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = I.MEMBER ";
       }
       if (!uphaseName.equals(""))
       {
         queryChghist += "left join UTILPHASE AS J " +
                         "on A.EVENT_ID = J.EVENT_ID AND " +
                         "A.EVENT_TIMESTAMP = J.EVENT_TIMESTAMP AND " +
                         "A.MEMBER = J.MEMBER ";
       }
       queryChghist += "order by A.EVENT_ID, A.EVENT_TIMESTAMP, A.MEMBER";

       stmt_fin = con.prepareStatement(queryChghist);
       ResultSet rs_fin = stmt_fin.executeQuery();
       
       //---------------------------------------
       // Apply stylesheet to the resulting xml
       //---------------------------------------
       if (rs_fin.next())
       {
         do
         {
           xmlRow = rs_fin.getBlob("XMLREPORT");
           if (bPrettyPrint == true)
           {
              System.out.println("Row Number: " + rs_fin.getRow());
              System.out.println(" ");
              PrettyPrintXML(xmlRow.getBinaryStream());
              System.out.println(" ");
           }
           else if (bFormatText == true)
           {
              docHeader = xmlRow.getBytes(1, 100);
              reportType = new String(docHeader);
              if (reportType.indexOf(chgHistEvent) != -1)
              {
                 ChangeHistoryReportFormatter(xmlRow.getBinaryStream());
              }
              else
              {
                 System.out.println(" ");
                 System.out.println("Tool does not support the XML document type");
                 System.out.println(reportType);
                 System.out.println(" ");
              }
           }
         }
         while (rs_fin.next());
       }
       else
       {
         System.out.println("Result set is empty");
       }
       System.out.println(" ");
       rs_fin.close();
       rs_chghist.close();
       rs_dbcfg.close();
       rs_ddl.close();
       rs_evs.close();
       rs_reg.close();
       rs_txn.close();
       rs_ustart.close();
       rs_ustop.close();
       rs_uloc.close();
       rs_uphase.close();
       stmt_fin.close();
       stmt_chghist.close();
       stmt_dbcfg.close();
       stmt_ddl.close();
       stmt_evs.close();
       stmt_reg.close();
       stmt_txn.close();
       stmt_ustart.close();
       stmt_ustop.close();
       stmt_uloc.close();
       stmt_uphase.close();
     }
     catch (SQLException e)
     {
       System.out.println(e.getMessage());
       System.out.println();
       if (con != null)
       {
         try
         {
           con.rollback();
         }
         catch (Exception error)
         {
         }
       }
       else
       {
          System.out.println("Connection to db " + dbName + " can't be established.");
          System.out.println(e);
       }
       System.exit(1);
     }
     catch (Exception e)
     {
       System.out.println(e.getMessage());
       System.out.println();
       System.exit(1);
     }
   }




   /*!
    *   /brief RetrieveXMLDocumentsFromEvmonLCK
    *
    *   Function to extract XML document from lock event
    */
   public static void RetrieveXMLDocumentsFromEvmonLCK() throws Exception
   {
     Connection con = null;
     Blob xmlRow = null;
     PreparedStatement stmt_fin = null;
     PreparedStatement stmt_lpa = null;
     PreparedStatement stmt_lpt = null;
     PreparedStatement stmt_lck = null;
     PreparedStatement stmt_type = null;
     PreparedStatement stmt_liv = null;
     String lpaName = "";
     String lptName = "";
     String lckName = "";
     String livName = "";
     String lpaSchema = "";
     String lptSchema = "";
     String lckSchema = "";
     String livSchema = "";
     String lockType = "";
     byte[] docHeader = new byte[101];
     String reportType = null;

     try
     {
       con = DriverManager.getConnection(dbName, userid, passwd);
       con.setAutoCommit(false);
       SetTenantToSystem(con);
     
       //---------------------------------------------------
       // Get names and schemas for tables of locking evnet
       //---------------------------------------------------
       String lpaTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'LOCK_PARTICIPANT_ACTIVITIES'";
       String lptTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'LOCK_PARTICIPANTS'";
       String lckTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'LOCK'";
       String livTab = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                       "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                       "LOGICAL_GROUP = 'LOCK_ACTIVITY_VALUES'";
       stmt_lpa = con.prepareStatement(lpaTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_lpt = con.prepareStatement(lptTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_lck = con.prepareStatement(lckTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       stmt_liv = con.prepareStatement(livTab, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
       ResultSet rs_lpa = stmt_lpa.executeQuery();
       ResultSet rs_lpt = stmt_lpt.executeQuery();
       ResultSet rs_lck = stmt_lck.executeQuery();
       ResultSet rs_liv = stmt_liv.executeQuery();
       rs_lpa.beforeFirst();
       rs_lpt.beforeFirst();
       rs_lck.beforeFirst();
       rs_liv.beforeFirst();
       
       if (rs_lpa.next())
       {
          lpaName = "\"" + rs_lpa.getString("TABNAME") + "\"";
          lpaSchema = "\"" + rs_lpa.getString("TABSCHEMA") + "\"";
       }
       if (rs_lpt.next())
       {
          lptName = "\"" + rs_lpt.getString("TABNAME") + "\"";
          lptSchema = "\"" + rs_lpt.getString("TABSCHEMA") + "\"";
       }
       if (rs_lck.next())
       {
          lckName = "\"" + rs_lck.getString("TABNAME") + "\"";
          lckSchema = "\"" + rs_lck.getString("TABSCHEMA") + "\"";
       }
       if (rs_liv.next())
       {
          livName = "\"" + rs_liv.getString("TABNAME") + "\"";
          livSchema = "\"" + rs_liv.getString("TABSCHEMA") + "\"";
       }

       //------------------------------------------------------------------
       // Build query for locking evnet, add parts if it is deadlock event
       //------------------------------------------------------------------
       String queryLCK =
       "WITH VARINPUTTED(EVENT_ID," +
                        "EVENT_TYPE," +
                        "EVENT_TIMESTAMP," +
                        "PARTICIPANT_NO," +
                        "ACTIVITY_ID," +
                        "UOW_ID," +
                        "INPVAR" +
                        ") " +
       "AS ( " +
       "select event_id," +
              "event_type," +
              "event_timestamp," +
              "participant_no," +
              "activity_id," +
              "uow_id," +
              "xmlagg(" +
              "xmlelement(name \"db2_input_variable\"," +
                         "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' )," +
                         "xmlelement(name \"stmt_value_index\", stmt_value_index)," +
                         "xmlelement(name \"stmt_value_isreopt\"," +
                                    "xmlattributes(stmt_value_isreopt as \"id\")," +
                                    "stmt_value_isreopt)," +
                         "xmlelement(name \"stmt_value_isnull\"," +
                                    "xmlattributes(stmt_value_isnull as \"id\")," +
                                    "stmt_value_isnull)," +
                         "xmlelement(name \"stmt_value_type\", stmt_value_type)," +
                         "xmlelement(name \"stmt_value_data\", stmt_value_data))) " +
       "from " + livSchema + "." + livName + " " +
       "group by event_id, event_type, event_timestamp, participant_no, activity_id, uow_id), " +
       "PARTICIPANT_ACTIVITIES(EVENT_ID, " +
                              "EVENT_TYPE, " +
                              "EVENT_TIMESTAMP, " +
                              "PARTICIPANT_NO, " +
                              "XMLACT) " +
       "AS (  " +
           "select a.event_id, " +
                  "a.event_type, " +
                  "a.event_timestamp, " +
                  "a.participant_no, " +
                  "xmlagg( " +
                        "xmlelement(name \"db2_activity\", "+
                                   "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), "+
                                   "xmlattributes(lcase(activity_type) as \"type\"), "+
                        "xmlelement(name \"db2_activity_details\", " +
                                  "xmlelement(name \"activity_id\", A.activity_id), " +
                                  "xmlelement(name \"uow_id\", A.uow_id), " +
                                  "xmlelement(name \"package_name\", package_name), " +
                                  "xmlelement(name \"package_schema\", package_schema), " +
                                  "xmlelement(name \"package_version_id\", package_version_id), " +
                                  "xmlelement(name \"consistency_token\", consistency_token), " +
                                  "xmlelement(name \"section_number\", section_number), " +
                                  "xmlelement(name \"reopt\", reopt), " +
                                  "xmlelement(name \"incremental_bind\", incremental_bind), " +
                                  "xmlelement(name \"effective_isolation\", effective_isolation), " +
                                  "xmlelement(name \"effective_query_degree\", effective_query_degree), " +
                                  "xmlelement(name \"stmt_unicode\", stmt_unicode), " +
                                  "xmlelement(name \"stmt_lock_timeout\", stmt_lock_timeout), " +
                                  "xmlelement(name \"stmt_type\", "+
                                             "xmlattributes(stmt_type as \"id\"), "+
                                             "stmt_type), " +
                                  "xmlelement(name \"stmt_operation\", stmt_operation), " +
                                  "xmlelement(name \"stmt_query_id\", stmt_query_id), " +
                                  "xmlelement(name \"stmt_nest_level\", stmt_nest_level), " +
                                  "xmlelement(name \"stmt_invocation_id\", stmt_invocation_id), " +
                                  "xmlelement(name \"stmt_source_id\", stmt_source_id), " +
                                  "xmlelement(name \"stmt_pkgcache_id\", stmt_pkgcache_id), " +
                                  "xmlelement(name \"stmt_text\", stmt_text), " +
                                  "xmlelement(name \"stmt_first_use_time\", stmt_first_use_time), " +
                                  "xmlelement(name \"stmt_last_use_time\", stmt_last_use_time), " +
                                  "xmlelement(name \"query_actual_degree\", query_actual_degree), " +
                                  "xmlelement(name \"stmtno\", stmtno)), " +
                        "INPVAR)) " +
           "from " + lpaSchema + "." + lpaName + " as A " +
           "left join VARINPUTTED AS B " +
           "on A.event_id = B.event_id and " +
           "A.event_type = B.event_type and " +
           "A.event_timestamp = B.event_timestamp and " +
           "A.participant_no = B.participant_no and " +
           "A.activity_id = B.activity_id and " +
           "A.uow_id = B.uow_id " +
           "group by A.event_id, A.event_type, A.event_timestamp, A.participant_no), " +

           " " +
       "PARTICIPANTS(EVENT_ID, " +
                    "EVENT_TYPE, " +
                    "EVENT_TIMESTAMP, " +
                    "XMLPART) " +   
       "AS ( " +
           "select x.event_id, " +
                  "x.event_type, " +
                  "x.event_timestamp, " +
                  "xmlagg( " +
                         "xmlelement(name \"db2_participant\",  " +
                                    "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                    "xmlattributes(x.participant_no as \"no\", " +
                                                  "ucase(participant_type) as \"type\", "+
                                                  "deadlock_member as \"deadlock_member\", "+
                                                  "participant_no_holding_lk as \"participant_no_holding_lk\", " +
                                                  "application_handle as \"application_handle\"),  " +
                                    "xmlelement(name \"db2_object_requested\", " +
                                               "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                               "xmlattributes(lcase(object_requested) as \"type\"), " +
                                               "xmlelement(name \"lock_name\", lock_name), " +
                                               "xmlelement(name \"lock_object_type\", lock_object_type), " +
                                               "xmlelement(name \"lock_attributes\", lock_attributes), " +
                                               "xmlelement(name \"lock_current_mode\", lock_current_mode), " +
                                               "xmlelement(name \"lock_mode_requested\", "+
                                                          "xmlattributes(lock_mode_requested as \"id\"), "+
                                                          "lock_mode_requested), " +
                                               "xmlelement(name \"lock_mode\", "+
                                                          "xmlattributes(lock_mode as \"id\"), "+
                                                          "lock_mode), " +
                                               "xmlelement(name \"lock_count\", lock_count), " +
                                               "xmlelement(name \"lock_hold_count\", lock_hold_count), " +
                                               "xmlelement(name \"lock_rriid\", lock_rriid), " +
                                               "xmlelement(name \"lock_status\", "+
                                                          "xmlattributes(lock_status as \"id\"), "+
                                                          "lock_status), " +
                                               "xmlelement(name \"lock_release_flags\", lock_release_flags), " +
                                               "xmlelement(name \"tablespace_name\", tablespace_name), " +
                                               "xmlelement(name \"table_name\", "+
                                                          "xmlattributes(table_file_id as \"id\"), "+
                                                          "table_name), " +
                                               "xmlelement(name \"table_schema\", table_schema), " +
                                               "xmlelement(name \"lock_object_type_id\", lock_object_type_id), " +
                                               "xmlelement(name \"lock_wait_start_time\", lock_wait_start_time), " +
                                               "xmlelement(name \"lock_wait_end_time\", lock_wait_end_time), " +
                                               "xmlelement(name \"threshold_name\", threshold_name), " +
                                               "xmlelement(name \"threshold_id\", threshold_id), " +
                                               "xmlelement(name \"queued_agents\", queued_agents)), " +
                                    "xmlelement(name \"db2_app_details\", " +
                                               "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                               "xmlelement(name \"application_handle\", application_handle), " +
                                               "xmlelement(name \"appl_id\", appl_id), " +
                                               "xmlelement(name \"appl_name\", appl_name), " +
                                               "xmlelement(name \"auth_id\", auth_id), " +
                                               "xmlelement(name \"agent_tid\", agent_tid), " +
                                               "xmlelement(name \"coord_agent_tid\", coord_agent_tid), " +
                                               "xmlelement(name \"agent_status\", "+
                                                          "xmlattributes(agent_status as \"id\"), "+
                                                          "agent_status), " +
                                               "xmlelement(name \"appl_action\", appl_action), " +
                                               "xmlelement(name \"lock_timeout_val\", lock_timeout_val), " +
                                               "xmlelement(name \"lock_wait_val\", lock_wait_val), " +
                                               "xmlelement(name \"workload_id\", workload_id), " +
                                               "xmlelement(name \"workload_name\", workload_name), " +
                                               "xmlelement(name \"service_class_id\", service_class_id), " +
                                               "xmlelement(name \"service_subclass_name\", service_subclass_name), " +
                                               "xmlelement(name \"current_request\", current_request), " +
                                               "xmlelement(name \"lock_escalation\", lock_escalation), " +
                                               "xmlelement(name \"past_activities_wrapped\", past_activities_wrapped), " +
                                               "xmlelement(name \"client_userid\", client_userid), " +
                                               "xmlelement(name \"client_wrkstnname\", client_wrkstnname), " +
                                               "xmlelement(name \"client_applname\", client_applname), " +
                                               "xmlelement(name \"client_acctng\", client_acctng), " +
                                               "xmlelement(name \"utility_invocation_id\", utility_invocation_id), " +
                                               "xmlelement(name \"service_superclass_name\", service_superclass_name), " +
                                               "xmlelement(name \"tenant_id\", tenant_id), " +
                                               "xmlelement(name \"tenant_name\", tenant_name)), " +
                                    "xmlact)) " +
           "from " + lptSchema + "." + lptName + " AS X " +
           "LEFT JOIN PARTICIPANT_ACTIVITIES AS Y " +
           "ON X.EVENT_ID = Y.EVENT_ID AND " +
           "X.EVENT_TYPE = Y.EVENT_TYPE AND " +
           "X.EVENT_TIMESTAMP = Y.EVENT_TIMESTAMP AND " +
           "X.PARTICIPANT_NO = Y.PARTICIPANT_NO " +
           "GROUP BY X.EVENT_ID, X.EVENT_TYPE, X.EVENT_TIMESTAMP), " +
       
       "DL_ATTR(EVENT_ID, EVENT_TYPE, EVENT_TIMESTAMP, "+
               "DLATTR) " +
       "AS ( "+
       "select event_id, event_type, event_timestamp, "+
              "xmlagg( " +
                     "xmlelement(name \"db2_participant\", "+
                                "xmlnamespaces(default 'http://www.ibm.com/xmlns/prod/db2/mon'), " +
                                "xmlattributes(participant_no as \"no\", " +
                                              "participant_type as \"type\", " +
                                              "deadlock_member as \"deadlock_member\", " +
                                              "participant_no_holding_lk as \"participant_no_holding_lk\", " +
                                              "application_handle as \"application_handle\"))) " +
       "from " + lptSchema + "." + lptName + " " +
       "where event_type = 'DEADLOCK' " +
       "group by event_id, event_type, event_timestamp), " +

       "DL_GRAPH(EVENT_ID, EVENT_TYPE, EVENT_TIMESTAMP, "+
                "DLGRAPH) " +
       "AS ( " +
       "select A.event_id, A.event_type, A.event_timestamp, " +
              "xmlagg( " +
              "xmlelement(name \"db2_deadlock_graph\", " +
                         "xmlnamespaces(default 'http://www.ibm.com/xmlns/prod/db2/mon'), " +
                         "xmlattributes(dl_conns as \"dl_conns\", " +
                                       "rolled_back_participant_no as \"rolled_back_participant_no\", " +
                                       "deadlock_type as \"type\"), " +
                         "DLATTR) ) " +
       "from " + lckSchema + "." + lckName + " as A, " +
       "DL_ATTR as B " +
       "where A.event_id = B.event_id and " +
       "A.event_type = B.event_type and " +
       "A.event_timestamp = B.event_timestamp " +
       "group by A.event_id, A.event_type, A.event_timestamp) " +
   
       "SELECT xmlserialize(xmlelement(name \"db2_lock_event\", " +
                                      "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ), " +
                                      "xmlattributes(A.event_id as \"id\", " +
                                                    "A.event_type as \"type\", " +
                                                    "A.event_timestamp as \"timestamp\", " +
                                                    "A.member as \"member\"), " +
                                      "DLGRAPH, " +
                                      "xmlpart) as BLOB(20M)) as XMLREPORT " +
       "FROM " + lckSchema + "." + lckName + " as A " +
       "LEFT JOIN PARTICIPANTS as B " +
       "ON A.EVENT_ID = B.EVENT_ID AND " +
       "A.EVENT_TYPE = B.EVENT_TYPE AND " +
       "A.EVENT_TIMESTAMP = B.EVENT_TIMESTAMP " +
       "LEFT JOIN DL_GRAPH AS C " +
       "ON A.EVENT_ID = C.EVENT_ID AND " +
       "A.EVENT_TYPE = C.EVENT_TYPE AND " +
       "A.EVENT_TIMESTAMP = C.EVENT_TIMESTAMP " +
       "ORDER BY A.EVENT_ID, A.EVENT_TYPE, A.EVENT_TIMESTAMP";

       stmt_fin = con.prepareStatement(queryLCK);
       ResultSet rs_fin = stmt_fin.executeQuery();
     
       //-------------------------------------------------------------
       // Apply stylesheet to resulting xml
       //-------------------------------------------------------------
       if (rs_fin.next())
       {
         do
         { 
           xmlRow = rs_fin.getBlob("XMLREPORT");
           if (bPrettyPrint == true)
           {
              System.out.println("Row Number: " + rs_fin.getRow());
              System.out.println(" ");
              PrettyPrintXML(xmlRow.getBinaryStream());
              System.out.println(" ");
           }
           else if (bFormatText == true)
           {
              docHeader = xmlRow.getBytes(1, 100);
              reportType = new String(docHeader);
              if (reportType.indexOf(lockEvent) != -1)
              {
                 LockReportFormatter(xmlRow.getBinaryStream());
              }
              else
              {
                 System.out.println(" ");
                 System.out.println("Tool does not support the XML document type");
                 System.out.println(reportType);
                 System.out.println(" ");
              }
           }
         }
         while (rs_fin.next());
       }
       else
       {
         System.out.println("Result set is empty");
       }
       System.out.println(" ");
       rs_fin.close();
       rs_lpa.close();
       rs_lpt.close();
       rs_lck.close();
       rs_liv.close();
       stmt_fin.close();
       stmt_lpa.close();
       stmt_lpt.close();
       stmt_lck.close();
       stmt_liv.close();
     }  
     catch (SQLException e)
     {
       System.out.println(e.getMessage());
       System.out.println();
       if (con != null)
       {
         try
         {
           con.rollback();
         }
         catch (Exception error)
         {
         }
       }
       else
       {
          System.out.println("Connection to db " + dbName + " can't be established.");
          System.out.println(e);
       }
       System.exit(1);
     }
     catch (Exception e)
     {
       System.out.println(e.getMessage());
       System.out.println();
       System.exit(1);
     }
   }

  
   /*!
    *  /brief RetrieveXMLDocumentsFromEvmonPKG
    *
    *  Function calls to get xml documents from Package Cache
    */
   public static void RetrieveXMLDocumentsFromEvmonPKG() throws Exception
   {
     Connection con = null;
     Blob xmlRow = null;
     PreparedStatement stmt_fin = null;
     PreparedStatement stmt_pkgargs = null;
     PreparedStatement stmt_pkg = null;
     String palName = "";
     String pkcName = "";
     String palSchema = "";
     String pkcSchema = "";
     byte[] docHeader = new byte[101];
     String reportType = null;
   
     try
     {
        //----------------------------------------------------------------------
        // Establish the connection to the database
        //----------------------------------------------------------------------
        con = DriverManager.getConnection(dbName, userid, passwd);
        con.setAutoCommit(false);
        SetTenantToSystem(con);

        //----------------------------------------------------------------------
        // Get names for pkgcache, pkgcache_stmt_args table
        //----------------------------------------------------------------------
        String tab_pkgcache = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                              "WHERE EVMONNAME = '" + wttEvmonName + "' AND "+
                              "LOGICAL_GROUP = 'PKGCACHE'";
        String tab_pkgarg = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                            "WHERE EVMONNAME = '" + wttEvmonName + "' AND "+
                            "LOGICAL_GROUP = 'PKGCACHE_STMT_ARGS'";
        stmt_pkg = con.prepareStatement(tab_pkgcache, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
        stmt_pkgargs = con.prepareStatement(tab_pkgarg, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs_pkgcache = stmt_pkg.executeQuery();
        ResultSet rs_pkgargs = stmt_pkgargs.executeQuery();
        rs_pkgcache.beforeFirst();
        rs_pkgargs.beforeFirst();
        
        if (rs_pkgcache.next())
        {
           pkcName = "\"" + rs_pkgcache.getString("TABNAME") + "\"";
           pkcSchema = "\"" + rs_pkgcache.getString("TABSCHEMA") + "\"";
        }
        if (rs_pkgargs.next())
        {
           palName = "\"" + rs_pkgargs.getString("TABNAME") + "\"";
           palSchema = "\"" + rs_pkgargs.getString("TABSCHEMA") + "\"";
        }

        //-----------------------------------------------------------------------
        // Build query for pkgcache event
        //-----------------------------------------------------------------------
        String queryPKG = "WITH PKG_ARG_LIST(EVENT_ID, EVENT_TIMESTAMP, MEMBER, PKG_ARGS) AS ("+
                               "select event_id,event_timestamp,member, "+
                               "xmlagg(xmlelement(name \"db2_input_variable\", "+
                                                 "xmlelement(name \"stmt_value_index\", stmt_value_index),"+
                                                 "xmlelement(name \"stmt_value_isreopt\","+
                                                            "xmlattributes(stmt_value_isreopt as \"id\"),"+
                                                            "stmt_value_isreopt),"+
                                                 "xmlelement(name \"stmt_value_isnull\", "+
                                                            "xmlattributes(stmt_value_isnull as \"id\"), "+
                                                            "stmt_value_isnull), "+
                                                 "xmlelement(name \"stmt_value_type\", rtrim(stmt_value_type), "+
                                                 "xmlelement(name \"stmt_value_data\", stmt_value_data) ) ) )"+
                               "from " + palSchema + "." + palName + " " +
                               "group by event_id, event_timestamp, member) " +
                          "SELECT A.event_id,A.event_timestamp,A.member, "+
                                 "xmlserialize(xmlelement(name \"db2_pkgcache_event\","+
                                            "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ),"+
                                            "xmlattributes('PKGCACHEBASE' as \"type\","+
                                                          "A.event_id as \"id\","+
                                                          "A.event_timestamp as \"timestamp\","+
                                                          "A.member as \"member\","+
                                                          "'10050300' as \"release\"),"+
                                            "xmlelement(name \"section_type\", section_type),"+
                                            "xmlelement(name \"insert_timestamp\", insert_timestamp),"+
                                            "xmlelement(name \"executable_id\", hex(executable_id)),"+
                                            "xmlelement(name \"package_schema\", package_schema),"+
                                            "xmlelement(name \"package_name\", package_name),"+
                                            "xmlelement(name \"package_version_id\", package_version_id),"+
                                            "xmlelement(name \"section_number\", section_number),"+
                                            "xmlelement(name \"effective_isolation\","+
                                                       "xmlattributes('2' as \"id\"),"+
                                                       "effective_isolation),"+
                                            "xmlelement(name \"num_executions\", num_executions),"+
                                            "xmlelement(name \"num_exec_with_metrics\", num_exec_with_metrics),"+
                                            "xmlelement(name \"prep_time\", prep_time),"+
                                            "xmlelement(name \"last_metrics_update\", last_metrics_update),"+
                                            "xmlelement(name \"num_coord_exec\", num_coord_exec),"+ 
                                            "xmlelement(name \"num_coord_exec_with_metrics\", num_coord_exec_with_metrics),"+
                                            "xmlelement(name \"stmt_type_id\", stmt_type_id),"+
                                            "xmlelement(name \"query_cost_estimate\", query_cost_estimate),"+
                                            "xmlelement(name \"stmt_pkg_cache_id\", stmt_pkg_cache_id),"+
                                            "xmlelement(name \"stmt_text\", stmt_text),"+
                                            "xmlelement(name \"comp_env_desc\", hex(comp_env_desc)),"+
                                            "xmlelement(name \"section_env\", section_env),"+
                                            "xmlparse(document metrics),"+
                                            "xmlelement(name \"routine_id\", routine_id),"+
                                            "xmlelement(name \"query_data_tag_list\", query_data_tag_list),"+
                                            "xmlelement(name \"total_stats_fabrication_time\", total_stats_fabrication_time),"+
                                            "xmlelement(name \"total_stats_fabrications\", total_stats_fabrications),"+
                                            "xmlelement(name \"total_sync_runstats_time\", total_sync_runstats_time),"+
                                            "xmlelement(name \"total_sync_runstats\", total_sync_runstats),"+
                                            "xmlelement(name \"max_coord_stmt_exec_timestamp\", max_coord_stmt_exec_timestamp),"+
                                            "B.PKG_ARGS,"+
                                            "xmlelement(name \"max_coord_stmt_exec_time\", max_coord_stmt_exec_time),"+
                                            "xmlelement(name \"stmtno\", stmtno),"+
                                            "xmlelement(name \"num_routines\", num_routines),"+
                                            "xmlelement(name \"stmtid\", stmtid),"+
                                            "xmlelement(name \"planid\", planid), " +
                                            "xmlelement(name \"semantic_env_id\", semantic_env_id), " +
                                            "xmlelement(name \"active_hash_grpbys_top\", active_hash_grpbys_top), " +
                                            "xmlelement(name \"active_hash_joins_top\", active_hash_joins_top), " +
                                            "xmlelement(name \"active_olap_funcs_top\", active_olap_funcs_top), " +
                                            "xmlelement(name \"active_peas_top\", active_peas_top), " +
                                            "xmlelement(name \"active_peds_top\", active_peds_top), " +
                                            "xmlelement(name \"active_sort_consumers_top\", active_sort_consumers_top), " +
                                            "xmlelement(name \"active_sorts_top\", active_sorts_top), " +
                                            "xmlelement(name \"active_col_vector_consumers_top\", active_col_vector_consumers_top), " +
                                            "xmlelement(name \"sort_consumer_heap_top\", sort_consumer_heap_top), " +
                                            "xmlelement(name \"sort_consumer_shrheap_top\", sort_consumer_shrheap_top), " +
                                            "xmlelement(name \"prep_warning\", prep_warning), " +
                                            "xmlelement(name \"prep_warning_reason\", prep_warning_reason), " +
                                            "xmlelement(name \"sort_heap_top\", sort_heap_top), " +
                                            "xmlelement(name \"sort_shrheap_top\", sort_shrheap_top), " +
                                            "xmlelement(name \"estimated_sort_shrheap_top\", estimated_sort_shrheap_top), " +
                                            "xmlelement(name \"estimated_sort_consumers_top\", estimated_sort_consumers_top), " +
                                            "xmlelement(name \"estimated_runtime\", estimated_runtime), " +
                                            "xmlelement(name \"agents_top\", agents_top), " +
                                            "xmlelement(name \"tenant_id\", tenant_id)) " +
                                            "as BLOB(20M)) as XMLREPORT " +
                          "from " + pkcSchema + "." + pkcName  + " as A " +
                          "left join PKG_ARG_LIST as B "+
                          "on A.event_id = B.event_id and A.event_timestamp = B.event_timestamp and A.member = B.member " +
                          "order by A.event_id, A.event_timestamp, A.member" ;
        stmt_fin = con.prepareStatement(queryPKG); 
        ResultSet rs_fin = stmt_fin.executeQuery();
        
        //------------------------------------------------------------------------
        // Apply stylesheet to resulting xml
        //------------------------------------------------------------------------
        if (rs_fin.next())
        {
          do
          {
             xmlRow = rs_fin.getBlob("XMLREPORT");
             if (bPrettyPrint == true)
             {
                System.out.println("Row Number: " + rs_fin.getRow());
                System.out.println(" ");
                PrettyPrintXML(xmlRow.getBinaryStream());
                System.out.println(" ");
             }
             else if (bFormatText == true)
             {
                docHeader = xmlRow.getBytes(1, 100);
                reportType = new String(docHeader);
                if (reportType.indexOf(pkgCacheEvent) != -1)
                {  
                   PkgCacheReportFormatter(xmlRow.getBinaryStream());
                }
                else
                {
                   System.out.println(" ");
                   System.out.println("Tool does not support the XML document type");
                   System.out.println(reportType);
                   System.out.println(" ");
                }
             }
          }
          while (rs_fin.next()); 
        }
        else
        {
           System.out.println("Result set is empty");
        }
        System.out.println(" ");
        rs_fin.close();
        rs_pkgcache.close();
        rs_pkgargs.close();
        stmt_fin.close();
        stmt_pkg.close();
        stmt_pkgargs.close();
     }
     catch (SQLException e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        if (con != null)
        {
           try
           {
              con.rollback();
           }
           catch (Exception error)
           {
           }
        }
        else
        {
           System.out.println("Connection to db " + dbName + " can't be established.");
           System.out.println(e);
        }
        System.exit(1);
     }
     catch (Exception e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        System.exit(1);
     }
  }


   /*!
    *  /brief RetrieveXMLDocumentsFromEvmonUOW
    *
    *  Function calls to get xml documents from UOW
    */
   public static void RetrieveXMLDocumentsFromEvmonUOW() throws Exception
   {
     Connection                 con = null;
     Blob                    xmlRow = null;
     PreparedStatement     stmt_uow = null;
     PreparedStatement     stmt_exe = null;
     PreparedStatement     stmt_pkg = null;
     PreparedStatement     stmt_fin = null;
     CallableStatement     callstmt = null;
     String uow_name = "";
     String exe_name = "";
     String pkg_name = "";
     String uow_schema = "";
     String exe_schema = "";
     String pkg_schema = "";
     byte[] docHeader = new byte[101];
     String reportType = null;

     try
     {
        //-------------------------------------------------------
        // Establish the connection to the database
        //-------------------------------------------------------
        con = DriverManager.getConnection(dbName, userid, passwd);
        con.setAutoCommit(false);
        SetTenantToSystem(con);
        
        //-------------------------------------------------------
        // Get names for uow, matrics, package table
        //-------------------------------------------------------
        String tab_uow = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                          "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                          "LOGICAL_GROUP = 'UOW'";
        
        stmt_uow = con.prepareStatement(tab_uow, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs_uow = stmt_uow.executeQuery();

        String tab_exe = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                         "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                         "LOGICAL_GROUP = 'UOW_EXECUTABLE_LIST'";
        stmt_exe = con.prepareStatement(tab_exe, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs_exe = stmt_exe.executeQuery();
        
        String tab_pkg = "SELECT TABSCHEMA, TABNAME FROM SYSCAT.EVENTTABLES "+
                         "WHERE EVMONNAME = '" + wttEvmonName + "' AND " +
                         "LOGICAL_GROUP = 'UOW_PACKAGE_LIST'";
        stmt_pkg = con.prepareStatement(tab_pkg, ResultSet.TYPE_SCROLL_INSENSITIVE, ResultSet.CONCUR_UPDATABLE);
        ResultSet rs_pkg = stmt_pkg.executeQuery();
        
        rs_uow.beforeFirst();
        rs_exe.beforeFirst();
        rs_pkg.beforeFirst();
        if (rs_uow.next())
        {
           uow_name = "\"" + rs_uow.getString("TABNAME") + "\"";
           uow_schema = "\"" + rs_uow.getString("TABSCHEMA") + "\"";
        }
        if (rs_exe.next())
        {
           exe_name = "\"" + rs_exe.getString("TABNAME") + "\"";
           exe_schema = "\"" + rs_exe.getString("TABSCHEMA") + "\"";
        }
        if (rs_pkg.next())
        {
           pkg_name = "\"" + rs_pkg.getString("TABNAME") + "\"";
           pkg_schema = "\"" + rs_pkg.getString("TABSCHEMA") + "\"";
        }
         
        String queryUOW = "WITH EXEC_LIST(MEMBER,APPLICATION_ID,UOW_ID,EXEC_ENTRIES) AS ("+
                               "select member,application_id,uow_id,"+
                                      "xmlagg(xmlelement(name \"executable_entry\","+
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ),"+
                                             "xmlelement(name \"executable_id\", hex(executable_id)),"+
                                             "xmlelement(name \"num_executions\", num_executions),"+
                                             "xmlelement(name \"rows_read\", rows_read),"+
                                             "xmlelement(name \"total_cpu_time\", total_cpu_time),"+
                                             "xmlelement(name \"total_act_time\", total_act_time),"+
                                             "xmlelement(name \"total_act_wait_time\", total_act_wait_time),"+
                                             "xmlelement(name \"lock_wait_time\", lock_wait_time),"+
                                             "xmlelement(name \"lock_waits\", lock_waits),"+
                                             "xmlelement(name \"total_sorts\", total_sorts),"+
                                             "xmlelement(name \"post_threshold_sorts\", post_threshold_sorts),"+
                                             "xmlelement(name \"post_shrthreshold_sorts\", post_shrthreshold_sorts),"+
                                             "xmlelement(name \"sort_overflows\", sort_overflows)))"+
                               "from " + exe_schema + "." + exe_name +
                               " group by member, application_id, uow_id), "+
                               "PKG_LIST(MEMBER,APPLICATION_ID,UOW_ID,PKG_ENTRIES) AS ("+
                               "select member,application_id,uow_id,"+
                                      "xmlagg(xmlelement(name \"package_entry\","+
                                             "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ),"+
                                             "xmlelement(name \"package_id\", package_id),"+
                                             "xmlelement(name \"package_elapsed_time\", package_elapsed_time),"+
                                             "xmlelement(name \"invocation_id\", invocation_id),"+
                                             "xmlelement(name \"routine_id\", routine_id),"+
                                             "xmlelement(name \"nesting_level\", nesting_level)))"+
                               "from " + pkg_schema + "." + pkg_name +
                               " group by member, application_id, uow_id) " +
                          "SELECT A.UOW_ID, A.APPLICATION_ID, A.MEMBER, " +
                                 "xmlserialize(xmlelement(name \"db2_uow_event\", "+
                                 "xmlnamespaces( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon' ),"+
                                 "xmlattributes(A.UOW_ID as \"id\",A.STOP_TIME as \"timestamp\",A.MEMBER as \"member\","+
                                               "mon_interval_id as \"mon_interval_id\", " +
                                               "'UOW' as \"type\", '10050300' as \"release\" ),"+
                                 "xmlelement(name \"completion_status\", completion_status),"+
                                 "xmlelement(name \"start_time\", start_time),"+
                                 "xmlelement(name \"stop_time\", stop_time),"+
                                 "xmlelement(name \"connection_time\", connection_time),"+
                                 "xmlelement(name \"application_name\", application_name),"+
                                 "xmlelement(name \"application_handle\", application_handle),"+
                                 "xmlelement(name \"application_id\", A.application_id),"+
                                 "xmlelement(name \"uow_id\", A.uow_id),"+
                                 "xmlelement(name \"workload_occurrence_id\", workload_occurrence_id),"+
                                 "xmlelement(name \"coord_member\", coord_member),"+
                                 "xmlelement(name \"member_activation_time\", member_activation_time),"+
                                 "xmlelement(name \"workload_name\", workload_name),"+
                                 "xmlelement(name \"workload_id\", workload_id),"+
                                 "xmlelement(name \"service_superclass_name\", service_superclass_name),"+
                                 "xmlelement(name \"service_subclass_name\", service_subclass_name),"+
                                 "xmlelement(name \"service_class_id\", service_class_id),"+
                                 "xmlelement(name \"session_authid\", session_authid),"+
                                 "xmlelement(name \"system_authid\", system_authid),"+
                                 "xmlelement(name \"client_pid\", client_pid),"+
                                 "xmlelement(name \"client_product_id\", client_product_id),"+
                                 "xmlelement(name \"client_platform\", client_platform),"+
                                 "xmlelement(name \"client_protocol\", client_protocol),"+
                                 "xmlelement(name \"client_userid\", client_userid),"+
                                 "xmlelement(name \"client_wrkstnname\", client_wrkstnname),"+
                                 "xmlelement(name \"client_applname\", client_applname),"+
                                 "xmlelement(name \"client_acctng\", client_acctng),"+
                                 "xmlelement(name \"local_transaction_id\", local_transaction_id),"+
                                 "xmlelement(name \"global_transaction_id\", global_transaction_id),"+
                                 "xmlparse(document metrics),"+
                                 "xmlelement(name \"client_hostname\", client_hostname),"+
                                 "xmlelement(name \"client_port_number\", client_port_number),"+
                                 "xmlelement(name \"uow_log_space_used\", uow_log_space_used),"+
                                 "xmlelement(name \"package_list\", "+
                                            "xmlelement(name \"package_list_size\", package_list_size),"+
                                            "xmlelement(name \"package_list_exceeded\", package_list_exceeded),"+
                                            "xmlelement(name \"package_list_entries\", C.PKG_ENTRIES))," +
                                 "xmlelement(name \"executable_list\","+
                                            "xmlelement(name \"executable_list_size\", executable_list_size),"+
                                            "xmlelement(name \"executable_list_truncated\", executable_list_truncated),"+
                                            "xmlelement(name \"executable_list_entries\", B.EXEC_ENTRIES)),"+
                                 "xmlelement(name \"intra_parallel_state\", intra_parallel_state),"+
                                 "xmlelement(name \"member_subset_id\", member_subset_id)," +
                                 "xmlelement(name \"tenant_name\", tenant_name),"+
                                 "xmlelement(name \"tenant_id\", tenant_id))"+
                                 " as Blob(20M) ) as XMLREPORT"+
                          " from " + uow_schema + "." + uow_name + " as A " +
                          "left join EXEC_LIST as B " +
                          "on A.member = B.member and A.application_id = B.application_id " +
                          "and A.uow_id = B.uow_id " + 
                          "left join PKG_LIST as C " +
                          "on A.member = C.member and A.application_id = C.application_id "+
                          "and A.uow_id = C.uow_id " + 
                          "order by A.UOW_ID, A.APPLICATION_ID, A.MEMBER";
        stmt_fin = con.prepareStatement(queryUOW);
        ResultSet rs_fin = stmt_fin.executeQuery();
        
        if (rs_fin.next())
        {
          do
          {
             xmlRow = rs_fin.getBlob("XMLREPORT");
             if (bPrettyPrint == true)
             {
                System.out.println("Row Number: " + rs_fin.getRow());
                System.out.println(" ");
                PrettyPrintXML(xmlRow.getBinaryStream());
                System.out.println(" ");
             }
             else if (bFormatText == true)
             {
                docHeader = xmlRow.getBytes(1, 100);
                reportType = new String(docHeader);
                if (reportType.indexOf(uowEvent) != -1)
                {
                   UOWReportFormatter(xmlRow.getBinaryStream());
                }
                else
                {
                   System.out.println(" ");
                   System.out.println("Tool does not support the XML document type");
                   System.out.println(reportType);
                   System.out.println(" ");
                }
             }
          }
          while (rs_fin.next()); 
        }
        else
        {
           System.out.println("Result set is empty");
        }
        System.out.println(" ");
        rs_fin.close();
        rs_uow.close();
        rs_exe.close();
        rs_pkg.close();
        stmt_fin.close();
        stmt_uow.close();
        stmt_exe.close();
        stmt_pkg.close();
     }
     catch (SQLException e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        if (con != null)
        {
           try
           {
              con.rollback();
           }
           catch (Exception error)
           {
           }
        }
        else
        {
           System.out.println("Connection to db " + dbName + " can't be established.");
           System.out.println(e);
        }
        System.exit(1);
     }
     catch (Exception e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        System.exit(1);
     }
  }
     
   /*!
    *  /brief RetrieveXMLDocumentsFromEvmonUE
    *
    *  Function calls the EVMON_FORMAT_UE_TO_XML table function
    */
   public static void RetrieveXMLDocumentsFromEvmonUE() throws Exception
   {
     Connection                 con = null;
     Blob                   xmlRow  = null;
     PreparedStatement         stmt = null;
     CallableStatement     callstmt = null;
     Boolean        bFirstCondition = true;
     int               paramIndex[] = { 0, 0, 0, 0, 0 };
     int                  paramCount = 0;
     byte[] docHeader = new byte[101];
     String reportType = null;

     try
     {

       //----------------------------------------------------------
       // Establish the connection to the database
       //----------------------------------------------------------
       con = DriverManager.getConnection(dbName, userid, passwd);
       con.setAutoCommit(false);
       SetTenantToSystem(con);

       //----------------------------------------------------------
       // Let us query the UE table and retrieve the events.
       //
       // We will execute table function: EVMON_FORMAT_UE_TO_XML to
       // retrieve the XML data. The table function takes a subquery
       // as input. The subquery will is a simple select stmt that
       // will retrieve all the rows from the UE table.
       //
       //  EVMON_FORMAT_UE_TO_XML( options
       //                          FOR EACH ROW OF (SELECT * from <UE Table>))
       //
       //----------------------------------------------------------
       String queryUETable =
           "SELECT evmon.xmlreport FROM TABLE ( " +
           "EVMON_FORMAT_UE_TO_XML( 'LOG_TO_FILE'," +
                                    "FOR EACH ROW OF ( " +
                                    "SELECT * FROM " + uetable.trim() + " ";

       //----------------------------------------------------------
       // Setup the the WHERE clause
       //----------------------------------------------------------
       if (   (hours != 0)
           || (eventType.length() != 0)
           || (eventID > 0)
           || (workloadName.length() > 0)
           || (serviceClass.length() > 0)
           || (applName.length() > 0)
          )
       {
          queryUETable += " WHERE";

          if (eventID > 0)
          {
             if (bFirstCondition == false)
             {
                queryUETable += " AND";
             }
             bFirstCondition = false;

             queryUETable += " EVENT_ID = ?";
             paramIndex[EVENT_ID] = (++paramCount);
          }

          if (hours != 0)
          {
             if (bFirstCondition == false)
             {
                queryUETable += " AND";
             }
             bFirstCondition = false;

             queryUETable +=
               " EVENT_TIMESTAMP >= CURRENT_TIMESTAMP - " + hours + " hours";
          }

          if (eventType.length() != 0)
          {
             if (bFirstCondition == false)
             {
                queryUETable += " AND";
             }
             bFirstCondition = false;

             queryUETable += " EVENT_TYPE = ?";
             paramIndex[EVENT_TYPE] = (++paramCount);
          }

          if (workloadName.length() != 0)
          {
             if (bFirstCondition == false)
             {
                queryUETable += " AND";
             }
             bFirstCondition = false;

             queryUETable += " WORKLOAD_NAME = ?";
             paramIndex[EVENT_WORKLOAD] = (++paramCount);
          }

          if (serviceClass.length() != 0)
          {
             if (bFirstCondition == false)
             {
                queryUETable += " AND";
             }
             bFirstCondition = false;

             queryUETable += " SERVICE_SUBCLASS_NAME = ?";
             paramIndex[EVENT_SRVCLASS] = (++paramCount);
          }

          if (applName.length() != 0)
          {
             if (bFirstCondition == false)
             {
                queryUETable += " AND";
             }
             bFirstCondition = false;

             queryUETable += " APPL_NAME = ?";
             paramIndex[EVENT_APPLNAME] = (++paramCount);
          }
       }
       queryUETable += " ORDER BY EVENT_ID, " +
                                 "EVENT_TIMESTAMP, " +
                                 "EVENT_TYPE, " +
                                 "MEMBER ))) AS evmon";

       //----------------------------------------------------------
       // Setup the Input and Output parameters
       //----------------------------------------------------------
       stmt = con.prepareStatement(queryUETable);

       if (paramIndex[EVENT_ID] > 0)
       {
          stmt.setInt(paramIndex[EVENT_ID]++, eventID);
       }

       if (paramIndex[EVENT_TYPE] > 0)
       {
          stmt.setString(paramIndex[EVENT_TYPE]++, eventType.toUpperCase());
       }

       if (paramIndex[EVENT_WORKLOAD] > 0)
       {
          stmt.setString(paramIndex[EVENT_WORKLOAD]++, workloadName.toUpperCase());
       }

       if (paramIndex[EVENT_SRVCLASS] > 0)
       {
          stmt.setString(paramIndex[EVENT_SRVCLASS]++, serviceClass.toUpperCase());
       }

       if (paramIndex[EVENT_APPLNAME] > 0)
       {
          stmt.setString(paramIndex[EVENT_APPLNAME]++, applName);
       }

       //----------------------------------------------------------
       // Execute the SQL statement
       //----------------------------------------------------------
       System.out.println(queryUETable);
       System.out.println(" ");

       ResultSet rs = stmt.executeQuery();

       //----------------------------------------------------------
       // Retrieve the data from the result set
       //----------------------------------------------------------
       if (rs.next())
       {
         do
         {
            xmlRow = rs.getBlob("XMLREPORT");

            //----------------------------------------------------------
            // Pretty Print the XML document to stdout
            //----------------------------------------------------------
            if (bPrettyPrint == true)
            {
               System.out.println("Row Number: " + rs.getRow());
               System.out.println(" ");
               PrettyPrintXML(xmlRow.getBinaryStream());
               System.out.println(" ");
            }

            //----------------------------------------------------------
            // Format the XML document to stdout based on the XML
            // stylesheet
            //----------------------------------------------------------
            else if (bFormatText == true)
            {
               docHeader = xmlRow.getBytes(1, 100);
               reportType = new String(docHeader);

               //----------------------------------------------------------
               // The XML report is from the Lock Event Monitor.
               // Call the XML to handle the db2LockReport
               //----------------------------------------------------------
               if (reportType.indexOf(lockEvent) != -1)
               {
                  LockReportFormatter(xmlRow.getBinaryStream());
               }
               else if (reportType.indexOf(uowEvent) != -1)
               {
                  UOWReportFormatter(xmlRow.getBinaryStream());
               }
               else if (reportType.indexOf(pkgCacheEvent) != -1)
               {
                  PkgCacheReportFormatter(xmlRow.getBinaryStream());
               }
               else
               {
                  System.out.println(" ");
                  System.out.println("Tool does not support the XML document type");
                  System.out.println(reportType);
                  System.out.println(" ");
               }

            }
         }
         while (rs.next());
       }
       else
       {
         System.out.println("Result set is empty");
       }
       System.out.println(" ");

       //----------------------------------------------------------
       // Close the statement and result set
       //----------------------------------------------------------
       rs.close();
       stmt.close();
     }
     catch (SQLException e)
     {
        System.out.println(e.getMessage());
        System.out.println();

        if (con != null)
        {
          try
          {
            con.rollback();
          }
          catch (Exception error )
          {
          }
        }
        else
        {
           System.out.println("Connection to db " + dbName + " can't be established.");
           System.err.println(e) ;
        }

        System.exit(1);
     }
     catch (Exception e)
     {
        System.out.println(e.getMessage());
        System.out.println();
        System.exit(1);
     }
   }

   /*!
    *  /brief FormatInputXMLFile
    *
    *  Formats the input XML file
    */
   public static void FormatInputXMLFile() throws Exception
   {
      File xmlFile = new File(xmlInputFilename);

      if (xmlFile.exists())
      {
         InputStream xmlFileStream = new FileInputStream(xmlFile);

         //----------------------------------------------------------
         // Pretty Print the XML document to stdout
         //----------------------------------------------------------
         if (bPrettyPrint == true)
         {
            PrettyPrintXML(xmlFileStream);
         }
         //----------------------------------------------------------
         // Format the XML document to stdout based on the XML
         // stylesheet
         //----------------------------------------------------------
         else if (bFormatText == true)
         {
            char [] docHeader = new char[101];
            InputStreamReader xmlHeader = new InputStreamReader(
                                            new FileInputStream(xmlFile));

            xmlHeader.read(docHeader, 1, 100);
            String reportType = new String(docHeader);

            //----------------------------------------------------------
            // The XML report is from the Lock Event Monitor.
            // Call the XML to handle the db2LockReport
            //----------------------------------------------------------
            if (reportType.indexOf(lockEvent) != -1)
            {
               LockReportFormatter(xmlFileStream);
            }
            else if (reportType.indexOf(uowEvent) != -1)
            {
               UOWReportFormatter(xmlFileStream);
            }
            else if (reportType.indexOf(pkgCacheEvent) != -1)
            {
               PkgCacheReportFormatter(xmlFileStream);
            }
            else
            {
               System.out.println(" ");
               System.out.println("Tool does not support XML document type");
               System.out.println(" ");
            }
         }
      }
      else
      {
         System.out.println(" ");
         System.out.println("Input XML file '"+xmlInputFilename+"' does not exist.");
         System.out.println(" ");
      }
   }

   /*!
    *  /brief PrettyPrintXML
    *
    *  Function will pretty print the XML document using the XML
    *  stylesheet.
    */
   public static void PrettyPrintXML(InputStream xmlSource)
   {
     try
     {
        TransformerFactory tFactory = TransformerFactory.newInstance();

        String xmlStyleSheet = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
        xmlStyleSheet += " <xsl:stylesheet version=\"1.0\" ";
        xmlStyleSheet += "xmlns:xsl=\"http://www.w3.org/1999/XSL/Transform\" ";
        xmlStyleSheet += "xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" ";
        xmlStyleSheet += "xmlns:lm=\"http://www.ibm.com/xmlns/prod/db2/mon\" ";
        xmlStyleSheet += "xmlns:xalan=\"http://xml.apache.org/xslt\" >";
        xmlStyleSheet += "<xsl:output method=\"xml\" version=\"1.0\" ";
        xmlStyleSheet += "encoding=\"UTF-8\" indent=\"yes\" xalan:indent-amount=\"2\" />";
        xmlStyleSheet += "<xsl:strip-space elements=\"*\" />";
        xmlStyleSheet += "<xsl:template match=\"*\" >";
        xmlStyleSheet += "<xsl:copy>";
        xmlStyleSheet += "<xsl:copy-of select=\"@*\" />";
        xmlStyleSheet += "<xsl:apply-templates />";
        xmlStyleSheet += "</xsl:copy>";
        xmlStyleSheet += "</xsl:template>";
        xmlStyleSheet += "</xsl:stylesheet>";

        Source xsl = new StreamSource(
                         new ByteArrayInputStream(xmlStyleSheet.getBytes()));
        Transformer xmlTrans = tFactory.newTransformer(xsl);

        Source xmlData = new StreamSource(xmlSource);
        Result output  = new StreamResult(System.out);

        xmlTrans.transform(xmlData, output);

     }
     catch (TransformerConfigurationException s)
     {
        System.out.println(s.getMessage());
        System.out.println();
        System.exit(1);
     }
     catch (TransformerException f)
     {
        System.out.println(f.getMessage());
        System.out.println();
        System.exit(1);
     }
   }

   /*!
    *  /brief ChangeHistoryReportFormatter
    *
    *  Function will format the Change History report based on the XML stylesheet
    */
   public static void ChangeHistoryReportFormatter(InputStream xmlSource)
   {
     try
     {  
        TransformerFactory tFactory = TransformerFactory.newInstance();
        File stylesheet = null;
        if (styleSheet.length() == 0)
        {
          stylesheet = new File("DB2EvmonChangeHistory.xsl");
        }
        else
        {
          stylesheet = new File(styleSheet);
        }
        Source xsl = new StreamSource(stylesheet);
        Transformer xmlTrans = tFactory.newTransformer(xsl);
        Source xmlData = new StreamSource(xmlSource);
        Result output = new StreamResult(System.out);
        xmlTrans.transform(xmlData, output);
     }
     catch (TransformerConfigurationException s)
     {
        System.out.println(s.getMessage());
        System.out.println();
        System.exit(1);
     }
     catch (TransformerException f)
     {
        System.out.println(f.getMessage());
        System.out.println();
        System.exit(1);
     }
   }

   /*!
    *  /brief LockReportFormatter
    *
    *  Function will format the Lock Report based on the XML stylesheet
    */
   public static void LockReportFormatter(InputStream xmlSource)
   {
     try
     {
        TransformerFactory tFactory = TransformerFactory.newInstance();

        //----------------------------------------------------------
        // Load the XML stylesheet from the current directory
        //----------------------------------------------------------
        File stylesheet = null;
        if (styleSheet.length() == 0)
        {
           stylesheet = new File("DB2EvmonLocking.xsl");
        }
        else
        {
           stylesheet = new File(styleSheet);
        }

        Source xsl  = new StreamSource(stylesheet);
        Transformer xmlTrans = tFactory.newTransformer(xsl);

        Source xmlData = new StreamSource(xmlSource);
        Result output  = new StreamResult(System.out);

        xmlTrans.transform(xmlData, output);

     }
     catch (TransformerConfigurationException s)
     {
        System.out.println(s.getMessage());
        System.out.println();
        System.exit(1);
     }
     catch (TransformerException f)
     {
        System.out.println(f.getMessage());
        System.out.println();
        System.exit(1);
     }
   }

   /*!
    *  /brief UOWReportFormatter
    *
    *  Function will format the UOW Report based on the XML stylesheet
    */
   public static void UOWReportFormatter(InputStream xmlSource)
   {
     try
     {
        TransformerFactory tFactory = TransformerFactory.newInstance();

        //----------------------------------------------------------
        // Load the XML stylesheet from the current directory
        //----------------------------------------------------------
        File stylesheet = null;
        if (styleSheet.length() == 0)
        {  
           stylesheet = new File("DB2EvmonUOW.xsl");
        }
        else
        {
           stylesheet = new File(styleSheet);
        }
        Source xsl  = new StreamSource(stylesheet);
        Transformer xmlTrans = tFactory.newTransformer(xsl);
        Source xmlData = new StreamSource(xmlSource);
        Result output  = new StreamResult(System.out);

        xmlTrans.transform(xmlData, output);

     }
     catch (TransformerConfigurationException s)
     {
        System.out.println(s.getMessage());
        System.out.println();
        System.exit(1);
     }
     catch (TransformerException f)
     {
        System.out.println(f.getMessage());
        System.out.println();
        System.exit(1);
     }
   }
   /*!
    *  /brief PkgCacheReportFormatter
    *
    *  Function will format the Pkg Cache Report based on the XML stylesheet
    */
   public static void PkgCacheReportFormatter(InputStream xmlSource)
   {
     try
     {
        TransformerFactory tFactory = TransformerFactory.newInstance();

        //----------------------------------------------------------
        // Load the XML stylesheet from the current directory
        //----------------------------------------------------------
        File stylesheet = null;
        if (styleSheet.length() == 0)
        {
           stylesheet = new File("DB2EvmonPkgCache.xsl");
        }
        else
        {
           stylesheet = new File(styleSheet);
        }

        Source xsl  = new StreamSource(stylesheet);
        Transformer xmlTrans = tFactory.newTransformer(xsl);

        Source xmlData = new StreamSource(xmlSource);
        Result output  = new StreamResult(System.out);

        xmlTrans.transform(xmlData, output);
     }
     catch (TransformerConfigurationException s)
     {
        System.out.println(s.getMessage());
        System.out.println();
        System.exit(1);
     }
     catch (TransformerException f)
     {
        System.out.println(f.getMessage());
        System.out.println();
        System.exit(1);
     }
   }

   /*!
    *  /brief ParseArguments
    *
    *  Parse the command line arguements.
    *
    */
   public static void ParseArguments(String argv[]) throws Exception
   {
      int   count = 0;
      char  value;
      char  optionChar;
      Boolean bDisplayHelp = false;
      Exception usage = new Exception(
      "USAGE:                                                                    \n" +
      "                                                                          \n" +
      "  db2evmonfmt -d <dbname> [-ue <uetable> | -wtt <wttEvmonName>] [ -u userid -p passwd ]    \n" +
      "              < -fxml | -ftext [-ss stylesheet] >                         \n" +
      "              [ -id <eventid>     ]                                       \n" +
      "              [ -type <eventype>  ]                                       \n" +
      "              [ -hours <hours>    ]                                       \n" +
      "              [ -w <workloadname> ]                                       \n" +
      "              [ -s <serviceclass> ]                                       \n" +
      "              [ -a <applname>     ]                                       \n" +
      "                                                                          \n" +
      " OR                                                                       \n" +
      "                                                                          \n" +
      " db2evmonfmt -f xmlfile < -fxml | -ftext [-ss stylesheet] >               \n" +
      "                                                                          \n" +
      "  where:                                                                  \n" +
      "                                                                          \n" +
      "       dbname     : Database name                                         \n" +
      "       uetable    : Name of the unformatted event monitor                 \n" +
      "       wttEvmonName : Name of the unit of work event monitor              \n" +
      "       userid     : User ID                                               \n" +
      "       passwd     : Password                                              \n" +
      "                                                                          \n" +
      "       xmlfile    : Input XML file to format                              \n" +
      "                                                                          \n" +
      "       fxml       : Pretty print the XML document to stdout               \n" +
      "       ftext      : Format XML document to text using the default XSLT    \n" +
      "                    stylesheet, pipe to stdout                            \n" +
      "                                                                          \n" +
      "       stylesheet : Use the following XSLT stylesheet to format to format \n" +
      "                    the XML documents                                     \n" +
      "                                                                          \n" +
      "       id         : Display all events matching <eventid>                 \n" +
      "       type       : Display all events matching event type <eventtype>    \n" +
      "       hours      : Display all events that have occurred in the last     \n" +
      "                    <hours> hours                                         \n" +
      "       w          : Display all events where the event is part of         \n" +
      "                    workload <workloadname>                               \n" +
      "                                                                          \n" +
      "                    For the Lock Event monitor, this will display all     \n" +
      "                    events where the lock requestor is part of            \n" +
      "                    <workloadname>                                        \n" +
      "                                                                          \n" +
      "       s          : Display all events where the event is part of         \n" +
      "                    service class <serviceclass>                          \n" +
      "                                                                          \n" +
      "                    For the Lock Event monitor, this will display all     \n" +
      "                    events where the lock requestor is part of            \n" +
      "                    <serviceclass>                                        \n" +
      "                                                                          \n" +
      "       a          : Display all events where the event is part of         \n" +
      "                    application name <applname>                           \n" +
      "                                                                          \n" +
      "                    For the Lock Event monitor, this will display all     \n" +
      "                    events where the lock requestor is part of <applname> \n" +
      "                                                                          \n" +
      " For WTT events, only dbname, wtt tag, output type(text or pretty print)  \n" +
      " are supported.                                                           \n" +
      "                                                                          \n" +
      " Examples:                                                                \n" +
      "                                                                          \n" +
      " 1. Get all events that are part of workload PAYROLL in the last 32 hours \n" +
      "    from UE table PKG in database SAMPLE.              \n" +
      "                                                                          \n" +
      "    java db2evmonfmt -d SAMPLE -ue PKG -ftext -hours 32 -w PAYROLL         \n" +
      "                                                                          \n" +
      " 2. Get all events of type LOCKTIMEOUT that have occurred in the last 24  \n" +
      "    hours from UE table LOCK in database SAMPLE.                     \n" +
      "                                                                          \n" +
      "    java db2evmonfmt -d SAMPLE -ue LOCK -ftext -hours 24 -type LOCKTIMEOUT \n" +
      "                                                                          \n" +
      " 3. Format the event contained in the file LOCK.XML using stylesheet      \n" +
      "    MYREPORT.xsl                                                          \n" +
      "                                                                          \n" +
      "    java db2evmonfmt -f lock.xml -ftext -ss myreport.xsl                  \n" +
      "                                                                          \n" +
      " 4. Get all events from WTT table T1 in database sample:                  \n" +
      "                                                                          \n" +
      "    java db2evmonfmt -d SAMPLE -wtt T1 -ftext                             \n" +
      "\n");

      if( argv.length < 2 ||
         ( argv.length == 1 &&
           ( argv[0].equals( "?" )               ||
             argv[0].equals( "-?" )              ||
             argv[0].equals( "/?" )              ||
             argv[0].equalsIgnoreCase( "-h" )    ||
             argv[0].equalsIgnoreCase( "/h" )    ||
             argv[0].equalsIgnoreCase( "-help" ) ||
             argv[0].equalsIgnoreCase( "/help" ) ) ) )
      { 
        throw usage;
      }

      while ((count + 1 <= argv.length) && (bDisplayHelp == false))
      {
         if (argv[count].equals("-d"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               dbName = "jdbc:db2:" + argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-u"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               userid = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-p"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               passwd = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-ue"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               uetable = argv[count+1];
               mode = "UE";
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-wtt"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               wttEvmonName = argv[count+1];
               mode = "WTT";
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-id"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               eventID = Integer.parseInt(argv[count+1]);
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-type"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               eventType = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-hours"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               hours = Integer.parseInt(argv[count+1]);
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-fxml"))
         {
            bPrettyPrint = true;
            count++;
            continue;
         }
         else if (argv[count].equals("-ftext"))
         {
            bFormatText = true;
            count++;
            continue;
         }
         else if (argv[count].equals("-ss"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               styleSheet = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-f"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               xmlInputFilename = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-w"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               workloadName = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-s"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               serviceClass = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else if (argv[count].equals("-a"))
         {
            if (    (count + 1 < argv.length)
                 && (!argv[count+1].startsWith("-"))
               )
            {
               applName = argv[count+1];
            }
            else
            {
               bDisplayHelp = true;
            }
         }
         else
         {
            bDisplayHelp = true;
         }
         count = count + 2;
      }

      // Display help if:
      //
      // 1. dbname or evmon name is set to zero and no format options
      //    are specified
      // 2. Or input XML file is not specified
      if (   bDisplayHelp
          || (    ((dbName.length() == 0) || ((uetable.length() == 0) && (wttEvmonName.length() == 0)))
               && (xmlInputFilename.length() == 0)
             )
          || (   (bFormatText == false)
              && (bPrettyPrint == false)
             )
         )
      {  
         throw usage;
      }
   }

   /*!
    *  /brief SetTenantToSystem 
    *
    * Sets the current tenant to SYSTEM 
    */
   private static void SetTenantToSystem(Connection con)
   {
      Statement stmt = null;
   
      try
      {
         stmt = con.createStatement();
         stmt.execute("SET CURRENT TENANT SYSTEM");

         //----------------------------------------------------------
         // Close the statement and result set
         //----------------------------------------------------------
         stmt.close();
      }
      catch (SQLException e)
      {
         System.out.println(e.getMessage());
         System.out.println();
         try
         {
           con.rollback();
         }
         catch (Exception error )
         {
           System.out.println(e.getMessage());
           System.out.println();
         }
         System.exit(1);
      }
      catch (Exception e)
      {
         System.out.println(e.getMessage());
         System.out.println();
         System.exit(1);
      }
   }
}

/*!
 *  /brief Class SimpleErrorHandler
 *
 *  SimpleErrorHandler handles all SAX parsing errors.
 */
class SimpleErrorHandler implements ErrorHandler
{
   public void warning(SAXParseException e) throws SAXParseException {
       System.out.format("Warning (%d:%d): %s\n",
                          e.getLineNumber(),
                          e.getColumnNumber(),
                          e.getMessage());
       throw(e);
   }

   public void error(SAXParseException e) throws SAXParseException {
       System.out.format("Error (%d:%d): %s\n",
                          e.getLineNumber(),
                          e.getColumnNumber(),
                          e.getMessage());
       throw(e);
   }

   public void fatalError(SAXParseException e) throws SAXParseException {
       System.out.format("Fatal Error (%d:%d): %s\n",
                          e.getLineNumber(),
                          e.getColumnNumber(),
                          e.getMessage());
       throw(e);
   }
}

