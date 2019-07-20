package com.ibm.db2.tools.repl.publication.support;

import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;

import javax.xml.parsers.SAXParserFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import com.ibm.db2.tools.repl.publication.*;
import java.util.*;
import java.math.*;

/**
 * This class is the Handler for a SAX parse of XML publication documents.   As
 * parsing the message, the handler will create the correct subclass of Msg (like
 * TransactionMsg).  This Msg can be fetched by calling getMsg() after the parse.
 * Note that the handler only saves the last Msg, so if you parse multiple documents,
 * you should call getMsg() after each document.
 *
 * @author tjacopi
 */
public class PublicationHandler extends DefaultHandler  {
    private static final String EmptyString = "";
    private static final String MsgElement = "msg";
    private static final String DbNameAttr = "dbName";

    private static final String TransactionElement = "trans";
    private static final String IsLastAttr = "isLast";
    private static final String SegmentNumAttr = "segmentNum";
    private static final String CmitLSNAttr = "cmitLSN";
    private static final String CmitTimeAttr = "cmitTime";
    private static final String AuthIDAttr = "authID";
    private static final String CorrelationIDAttr = "correlationID";
    private static final String PlanNameAttr = "planName";

    private static final String InsertRowElement = "insertRow";
    private static final String DeleteRowElement = "deleteRow";
    private static final String UpdateRowElement = "updateRow";
    private static final String SubNameAttr = "subName";
    private static final String SrcOwnerAttr = "srcOwner";
    private static final String SrcNameAttr = "srcName";
    private static final String RowNumAttr = "rowNum";
    private static final String HasLOBColsAttr = "hasLOBCols";

    private static final String ColumnElement = "col";
    private static final String NameAttr = "name";
    private static final String IsKeyAttr = "isKey";
    private static final String BeforeValElement = "beforeVal";
    private static final String AfterValElement = "afterVal";

    private static final String IntegerElement = "integer";
    private static final String VarcharElement = "varchar";
    private static final String LongVarcharElement = "longvarchar";
    private static final String CharElement = "char";
    private static final String VargraphicElement = "vargraphic";
    private static final String LongVargraphicElement = "longvargraphic";
    private static final String GraphicElement = "graphic";
    private static final String BitVarcharElement = "bitvarchar";
    private static final String BitLongVarcharElement = "bitlongvarchar";
    private static final String BitCharElement = "bitchar";
    private static final String SmallintElement = "smallint";
    private static final String BigintElement = "bigint";
    private static final String FloatElement = "float";
    private static final String RealElement = "real";
    private static final String DoubleElement = "double";
    private static final String DecimalElement = "decimal";
    private static final String DateElement = "date";
    private static final String TimeElement = "time";
    private static final String TimestampElement = "timestamp";
    private static final String RowIdElement = "rowid";
    private static final String BlobElement = "blob";
    private static final String ClobElement = "clob";
    private static final String DBlobElement = "dblob";

    private static final String RowOpElement = "rowOp";
    private static final String LOBElement = "lob";

    private static final String ColNameAttr = "colName";
    private static final String TotalDataLenAttr = "totalDataLen";
    private static final String DataLenAttr = "dataLen";

    private static final String SubDeactivatedElement = "subDeactivated";
    private static final String StateInfoAttr = "stateInfo";

    private static final String LoadDoneElement = "loadDoneRcvd";
    private static final String ErrorRptElement = "errorRpt";
    private static final String ErrorMsgAttr = "errorMsg";

    private static final String HeartbeatElement = "heartbeat";
    private static final String LastCmitTimeAttr = "lastcmitTime";
    private static final String SendQNameAttr = "sendQName";

    private static final String SubSchemaElement = "subSchema";
    private static final String AllChangedRowsAttr = "allChangedRows";
    private static final String BeforeValuesAttr = "beforeValues";
    private static final String ChangedColsOnlyAttr = "changedColsOnly";
    private static final String HasLoadPhaseAttr = "hasLoadPhase";
    private static final String DbServerTypeAttr = "dbServerType";
    private static final String DbReleaseAttr = "dbRelease";
    private static final String DbInstanceAttr = "dbInstance";
    private static final String CapReleaseAttr = "capRelease";

    private static final String TypeAttr = "type";
    private static final String LenAttr = "len";
    private static final String PrecisionAttr = "precision";
    private static final String ScaleAttr = "scale";
    private static final String CodepageAttr = "codepage";

    private static final String AddColumnElement = "addColumn";

    private static final String StrTrue     = "1";
    private static final String XsiNullAttr = "xsi:nil";

    // The following are temporary variables to hold the building of the final object
    // as we parse.
    protected Msg          msg    = null;              // Msg built here
    protected ColumnSchema col    = null;              // Column built here
    protected Row          row    = null;              // Row built here
    protected Vector       rowList  = null;
    protected Vector       colList  = null;
    protected Column  colValue  = null;
    protected Object       dataValue  = null;
    protected String       savedDataType  = null;
    protected boolean      useColValue  = true;
    protected boolean      xsiNullIndicator = false;


    protected String       dbName = null;
    protected StringBuffer chars  = null;                // Holds chars as we are parsing.
    protected int          suggestedBufferSize = 100;    // Gets increased for Blobs

    /** Create a new handler.
     */
    public PublicationHandler() {
      ;
    }

    /** Get the Msg that was created as a result of the parse.
     *  @return Msg     The msg subclass defined by the document, or null if error.
     */
    public Msg getMsg() {
      return msg;
    }

    public void characters( char buf [], int offset, int len ) throws SAXException
      {
        if (chars == null) {
          chars = new StringBuffer(suggestedBufferSize);
        }
        chars.append(buf, offset, len);
      }
    public void error( SAXParseException e ) throws SAXParseException
      {
        System.out.println( "** Error " + ", line " + e.getLineNumber() + ", uri " + e.getSystemId() );
        System.out.println( "   " + e.getMessage() );
        throw e;
      }
    public void warning( SAXParseException err ) throws SAXParseException
      {
        System.out.println( "** Warning" + ", line " + err.getLineNumber() + ", uri " + err.getSystemId() );
        System.out.println( "   " + err.getMessage() );
      }


    /** Called when a new document starts.  Null out everthing to remove and knowledge of
     * a previous parse.
     */
    public void startDocument() throws SAXException  {

      // --------------------------------------------------------------
      // Starting parse.  Insure everything is null to begin, so we dont see any
      // traces of previous documents.
      // --------------------------------------------------------------
      msg = null;
      chars = null;
      col    = null;
      row    = null;
      rowList  = null;
      colList  = null;
      colValue  = null;
      dbName = null;
      dataValue  = null;
      savedDataType  = null;
      suggestedBufferSize = 100;
    }


    public void endDocument() throws SAXException {

      // --------------------------------------------------------------
      // Finished parse.  Null out all temporary vars so the garbage collector can do its thing.
      // --------------------------------------------------------------
      col    = null;
      row    = null;
      rowList  = null;
      colValue  = null;
      chars = null;
      colList  = null;
      dbName = null;
      dataValue  = null;
      savedDataType  = null;
    }


    public void startElement( String namespaceURI, String lName, String qName, Attributes attrs ) throws SAXException       {
      chars = null;                       // Always blank out at start of element
      xsiNullIndicator = getBooleanAttribute(attrs, XsiNullAttr, false);

      // See what type of element we have, then call the appropiate routine to create the java objects
      if (TransactionElement.equals(qName) ) {
        buildTransactionMsg(attrs);
        rowList = new Vector();
      } else if (MsgElement.equals(qName) ) {
        dbName = getAttribute(attrs, DbNameAttr);
        suggestedBufferSize = 100;
      } else if (RowOpElement.equals(qName) ) {
        buildRowOpMsg(attrs);
      } else if (SubDeactivatedElement.equals(qName) ) {
        buildSubDeactivatedMsg(attrs);
      } else if (AddColumnElement.equals(qName) ) {
        buildAddColumnMsg(attrs);
      } else if (LoadDoneElement.equals(qName) ) {
        buildLoadDoneReceivedMsg(attrs);
      } else if (ErrorRptElement.equals(qName) ) {
        buildErrorRptMsg(attrs);
      } else if (HeartbeatElement.equals(qName) ) {
        buildHeartbeatMsg(attrs);
      } else if (SubSchemaElement.equals(qName) ) {
        buildSubSchemaMsg(attrs);
      } else if (LOBElement.equals(qName) ) {
        buildLOBMsg(attrs);
      } else if (InsertRowElement.equals(qName) ) {
        buildRowMsg(attrs);
        row.setRowOperation(Row.InsertOperation);
      } else if (DeleteRowElement.equals(qName) ) {
        buildRowMsg(attrs);
        row.setRowOperation(Row.DeleteOperation);
      } else if (UpdateRowElement.equals(qName) ) {
        buildRowMsg(attrs);
        row.setRowOperation(Row.UpdateOperation);
      } else if (ColumnElement.equals(qName) ) {
        if (useColValue) {
          buildColumn(attrs);
        } else {
          buildColumnSchema(attrs);
        }
      } else if (isDataTypeElement(qName) ) {
        savedDataType = qName;
//    } else {
//      System.out.println("Unsupported element " + qName );
      }
    }

    public void endElement( String namespaceURI, String sName, String qName ) throws SAXException {

      // When an element ends, move all "temporary" values that we were building into their final place.
      if (TransactionElement.equals(qName) ) {
        ((TransactionMsg) msg).setRows(rowList);     // No more rows, so set the list.
        rowList = null;
        row = null;

      } else if (InsertRowElement.equals(qName) ||
                 DeleteRowElement.equals(qName) ||
                 UpdateRowElement.equals(qName) ) {
        row.setColumns(colList);                     // take all the found cols and add them to the row.
        colList = null;

      } else if (SubSchemaElement.equals(qName) ) {
        ((SubscriptionSchemaMsg) msg).setColumns(colList);   // take all the found cols and add them to the msg.
        colList = null;

      } else if (RowOpElement.equals(qName) ) {
        ((RowOperationMsg) msg).setRow(row);
        row = null;

      } else if (AddColumnElement.equals(qName) ) {
        ((AddColumnMsg) msg).setColumn(col);
        col = null;

      } else if (LOBElement.equals(qName) ) {
        ((LOBMsg) msg).setLobType(savedDataType);
        ((LOBMsg) msg).setValue(dataValue);
        dataValue = null;
        savedDataType = null;

      } else if (MsgElement.equals(qName) ) {
        msg.setDbName(dbName);
      } else if (BeforeValElement.equals(qName) ) {
        buildDataValue(savedDataType);
        colValue.setBeforeValue(dataValue);
        colValue.setBeforeValuePresent(true);
        dataValue = null;
      } else if (AfterValElement.equals(qName) ) {
        // We can ignore this because the value will get built when the datatype element
        // ends, and the value will be set when the col element ends
        ;
      } else if (ColumnElement.equals(qName) ) {
        savedDataType = null;

        if (colList != null) {                     // If we have a list
          if (col != null) {                       // ..then see what kind of column we have
            colList.add(col);                      // ..add this column to it
          } else if (colValue != null) {           // ..or do we have one of these?
            colList.add(colValue);                 // ..add this column to it
          }
        };

        if (useColValue && dataValue != null) {
          colValue.setValue(dataValue);
          dataValue = null;
        } else {
          ;
        }
      } else if ( isDataTypeElement(qName) ) {
        buildDataValue(savedDataType);
      }
    }


    protected void buildTransactionMsg(Attributes attrs) {
      TransactionMsg tMsg = new TransactionMsg();
      tMsg.setLast( getBooleanAttribute(attrs, IsLastAttr, false) );
      tMsg.setSegmentNumber( getIntegerAttribute(attrs, SegmentNumAttr, 0) );
      tMsg.setCommitLSN( getAttribute(attrs, CmitLSNAttr) );
      tMsg.setCommitTime( getAttribute(attrs, CmitTimeAttr) );
      tMsg.setAuthID( getAttribute(attrs, AuthIDAttr) );
      tMsg.setCorrelationID( getAttribute(attrs, CorrelationIDAttr) );
      tMsg.setPlanName( getAttribute(attrs, PlanNameAttr) );

      msg = tMsg;
    }

    protected void buildRowOpMsg(Attributes attrs) {
      RowOperationMsg rMsg = new RowOperationMsg();
      rMsg.setLast( getBooleanAttribute(attrs, IsLastAttr, false) );
      rMsg.setCommitLSN( getAttribute(attrs, CmitLSNAttr) );
      rMsg.setCommitTime( getAttribute(attrs, CmitTimeAttr) );
      rMsg.setAuthID( getAttribute(attrs, AuthIDAttr) );
      rMsg.setCorrelationID( getAttribute(attrs, CorrelationIDAttr) );
      rMsg.setPlanName( getAttribute(attrs, PlanNameAttr) );

      msg = rMsg;
    }

    protected void buildSubSchemaMsg(Attributes attrs) {
      SubscriptionSchemaMsg sdMsg = new SubscriptionSchemaMsg();
      sdMsg.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      sdMsg.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      sdMsg.setSrcName( getAttribute(attrs, SrcNameAttr) );
      sdMsg.setSendQueueName( getAttribute(attrs, SendQNameAttr) );
      sdMsg.setAllChangedRows( getBooleanAttribute(attrs, AllChangedRowsAttr, false) );
      sdMsg.setBeforeValues( getBooleanAttribute(attrs, BeforeValuesAttr, false) );
      sdMsg.setOnlyChangedCols( getBooleanAttribute(attrs, ChangedColsOnlyAttr, false) );
      sdMsg.setLoadPhase( getAttribute(attrs, HasLoadPhaseAttr) );
      sdMsg.setDb2ServerType( getAttribute(attrs, DbServerTypeAttr) );
      sdMsg.setDb2ReleaseLevel( getAttribute(attrs, DbReleaseAttr) );
      sdMsg.setDb2InstanceName( getAttribute(attrs, DbInstanceAttr) );
      sdMsg.setQCaptureReleaseLevel( getAttribute(attrs, CapReleaseAttr) );
      colList = new Vector();                              // To store the column elements
      useColValue  = false;                                // Use ColumnSchema, not Column

      msg = sdMsg;
    }

    protected void buildSubDeactivatedMsg(Attributes attrs) {
      SubscriptionDeactivatedMsg sdMsg = new SubscriptionDeactivatedMsg();
      sdMsg.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      sdMsg.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      sdMsg.setSrcName( getAttribute(attrs, SrcNameAttr) );
      sdMsg.setStateInformation( getAttribute(attrs, StateInfoAttr) );

      msg = sdMsg;
    }

    protected void buildLoadDoneReceivedMsg(Attributes attrs) {
      LoadDoneReceivedMsg sdMsg = new LoadDoneReceivedMsg();
      sdMsg.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      sdMsg.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      sdMsg.setSrcName( getAttribute(attrs, SrcNameAttr) );
      sdMsg.setStateInformation( getAttribute(attrs, StateInfoAttr) );

      msg = sdMsg;
    }

    protected void buildErrorRptMsg(Attributes attrs) {
      ErrorReportMsg sdMsg = new ErrorReportMsg();
      sdMsg.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      sdMsg.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      sdMsg.setSrcName( getAttribute(attrs, SrcNameAttr) );
      sdMsg.setMsgText( getAttribute(attrs, ErrorMsgAttr) );

      msg = sdMsg;
    }

    protected void buildAddColumnMsg(Attributes attrs) {
      AddColumnMsg sdMsg = new AddColumnMsg();
      sdMsg.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      sdMsg.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      sdMsg.setSrcName( getAttribute(attrs, SrcNameAttr) );
      useColValue  = false;                                  // Use ColumnSchema, not Column

      msg = sdMsg;
    }

    protected void buildHeartbeatMsg(Attributes attrs) {
      HeartbeatMsg sdMsg = new HeartbeatMsg();
      sdMsg.setLastCommitTime( getAttribute(attrs, LastCmitTimeAttr) );
      sdMsg.setSendQueueName( getAttribute(attrs, SendQNameAttr) );

      msg = sdMsg;
    }

    protected void buildRowMsg(Attributes attrs) {
      row = new Row();
      row.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      row.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      row.setSrcName( getAttribute(attrs, SrcNameAttr) );
      row.setRowNumber( getIntegerAttribute(attrs, RowNumAttr, 0) );
      row.setHasLOBColumns( getBooleanAttribute(attrs, HasLOBColsAttr, false) );

      colList = new Vector();                                // For following cols
      useColValue  = true;

      if (rowList != null) {
        rowList.add(row);
      };
    }

    protected void buildLOBMsg(Attributes attrs) {
      LOBMsg lMsg = new LOBMsg();
      lMsg.setSubscriptionName( getAttribute(attrs, SubNameAttr) );
      lMsg.setLast( getBooleanAttribute(attrs, IsLastAttr, false) );
      lMsg.setSrcOwner( getAttribute(attrs, SrcOwnerAttr) );
      lMsg.setSrcName( getAttribute(attrs, SrcNameAttr) );
      lMsg.setRowNumber( getIntegerAttribute(attrs, RowNumAttr, 0) );
      lMsg.setColumnName( getAttribute(attrs, ColNameAttr) );
      lMsg.setTotalDataLength( getIntegerAttribute(attrs, TotalDataLenAttr, 0) );

      int dataLen =  getIntegerAttribute(attrs, DataLenAttr, 0);
      lMsg.setSegmentLength( dataLen  );
      if (dataLen > suggestedBufferSize) {        // If the size is bigger
        suggestedBufferSize = dataLen;            // ..then save it so we can allocate the right buffer size later
      };

      msg = lMsg;
    }

    protected void buildColumnSchema(Attributes attrs) {
      col = new ColumnSchema();
      col.setName( getAttribute(attrs, NameAttr) );
      col.setType( getAttribute(attrs, TypeAttr) );
      col.setLength( getIntegerAttribute(attrs, LenAttr, 0) );
      col.setPrecision( getIntegerAttribute(attrs, PrecisionAttr, 0) );
      col.setScale( getIntegerAttribute(attrs, ScaleAttr, 0) );
      col.setCodepage( getIntegerAttribute(attrs, CodepageAttr, 0) );
      col.setKey( getBooleanAttribute(attrs, IsKeyAttr, false) );
    }

    protected void buildColumn(Attributes attrs) {
      colValue = new Column();
      colValue.setName( getAttribute(attrs, NameAttr) );
      colValue.setKey( getBooleanAttribute(attrs, IsKeyAttr, false) );
    }

   protected boolean isDataTypeElement(String elementName) {
     return IntegerElement.equals(elementName) ||
            VarcharElement.equals(elementName) ||
            LongVarcharElement.equals(elementName) ||
            CharElement.equals(elementName) ||
            VargraphicElement.equals(elementName) ||
            LongVargraphicElement.equals(elementName) ||
            GraphicElement.equals(elementName) ||
            BitVarcharElement.equals(elementName) ||
            BitLongVarcharElement.equals(elementName) ||
            BitCharElement.equals(elementName) ||
            SmallintElement.equals(elementName) ||
            BigintElement.equals(elementName) ||
            FloatElement.equals(elementName) ||
            RealElement.equals(elementName) ||
            DoubleElement.equals(elementName) ||
            DecimalElement.equals(elementName) ||
            DateElement.equals(elementName) ||
            TimeElement.equals(elementName) ||
            TimestampElement.equals(elementName) ||
            RowIdElement.equals(elementName) ||
            BlobElement.equals(elementName) ||
            ClobElement.equals(elementName) ||
            DBlobElement.equals(elementName);
   }


    /** Take the string representation of the data stored in strValue, and
     *  interpert is as of type dataType, and build the correct java object in dataValue.
     *  @param  dataType  The datatype to use when interpting strValue.
     */
   protected void buildDataValue(String dataType) {
     dataValue = null;
     if (xsiNullIndicator) {
       return;
     }

     String strValue = EmptyString;                     // This holds the string representation of the data value
     if (chars != null) {                               // If we got any chars
       strValue = chars.toString();                     // ...then lets use them...
     };

     try {
       if (IntegerElement.equals(dataType) ) {
         dataValue = new Integer(strValue);
       } else if (VarcharElement.equals(dataType) ||
                  LongVarcharElement.equals(dataType) ||
                  CharElement.equals(dataType)  ||
                  VargraphicElement.equals(dataType) ||
                  LongVargraphicElement.equals(dataType) ||
                  GraphicElement.equals(dataType)  ||
                  ClobElement.equals(dataType)  ||
                  DBlobElement.equals(dataType)  ||
                  DateElement.equals(dataType)  ||
                  TimeElement.equals(dataType)  ||
                  TimestampElement.equals(dataType)  ||
                  CharElement.equals(dataType) ) {
         dataValue = strValue;
       } else if (SmallintElement.equals(dataType) ) {
         dataValue = new Short(strValue);
       } else if (BigintElement.equals(dataType) ) {
         dataValue = new BigInteger(strValue);
       } else if (DecimalElement.equals(dataType) ) {
         dataValue = new BigDecimal(strValue);
       } else if (FloatElement.equals(dataType) ) {
         if (strValue.length() > 12) {                            //
           dataValue = new Double(strValue);
         } else {
           dataValue = new Float(strValue);
         }
       } else if (DoubleElement.equals(dataType) ) {
         dataValue = new Double(strValue);
       } else if (RealElement.equals(dataType) ) {
         dataValue = new Float(strValue);
       } else if (BitVarcharElement.equals(dataType) ||
                  BitLongVarcharElement.equals(dataType) ||
                  BitCharElement.equals(dataType) ||
                  BitCharElement.equals(dataType) ||
                  RowIdElement.equals(dataType) ||
                  BlobElement.equals(dataType) ) {
         int numBytes = strValue.length()/2;
         byte[] bytes = new byte[numBytes];

         // Need to do faster byte parsing
         for (int i=0; i<numBytes; i++) {
           String tempStr = strValue.substring(i*2, (i*2)+2);   // Convert 1 byte at a time!
           bytes[i] = Byte.parseByte(tempStr, 16);
         }
       } else {
         System.out.println("Ingorning Unsupported datatype " + dataType);
       }

     } catch(Throwable t) {
       System.out.println("Caught and ingored error when trying to parse " + strValue + " as " + dataType);
       t.printStackTrace();
     }
   }


    protected int getIntegerAttribute(Attributes attrs, String attrName, int defaultValue) {
      int returnValue = defaultValue;
      String value = getAttribute(attrs, attrName, null);
      if (value != null) {
        try {
          returnValue = Integer.parseInt(value);
        } catch(Throwable t) {
          System.out.println("Caught and ingored error when trying to parse " + value + " as int");
          t.printStackTrace();
        }
      }

      return returnValue;
    }

    protected boolean getBooleanAttribute(Attributes attrs, String attrName, boolean defaultValue) {
      boolean returnValue = defaultValue;
      String value = getAttribute(attrs, attrName, null);
      if (value != null) {
        returnValue = value.equals(StrTrue);
      }

      return returnValue;
    }

    protected String getAttribute(Attributes attrs, String attrName) {
       return getAttribute(attrs, attrName, null);
    }

    protected String getAttribute(Attributes attrs, String attrName, String defaultValue) {
      String value = defaultValue;
      if (attrs != null) {
        value = attrs.getValue(attrName);
        if (value == null) {
          value = defaultValue;
        }
      }

      return value;
    }

  }
