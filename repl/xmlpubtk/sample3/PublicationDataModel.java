import java.util.*;
import com.ibm.db2.tools.repl.publication.*;


/**
 * The PublicationDataModel class holds the actual data that is keeping track of the updates.
 * It does this in two hashtables:
 *
 *   data:   This is the raw data.
 *             Key:    Database name (String)
 *             Value:  A Hashtable
 *                Key:    Table Name (TableName)
 *                Value:  The count of updates for that table (Count).
 *
 *   dbTotals:  This is a cache of all the total counts for a database.
 *             Key:    Database name (String)
 *             Value:  The count of all the updates for this database.
 *
 * @author tjacopi
 *
 */
public class PublicationDataModel {

  protected Hashtable data = new Hashtable();
  protected Hashtable dbTotals = new Hashtable();

  /**
   * All the database names.
   * @return Enumeration   The list of Strings (database names).
   */
  public Enumeration getDbNames() {
    return data.keys();
  }

  /**
   * Get the number of databases.
   * @return int  The number of unique dbs.
   */
  public int getDbNameCount() {
    return data.size();
  }

  /**
   * Get all the table names for a specific database.
   * @param dbName        The database name
   * @return Enumeration  The list of TableName objects.
   */
  public Enumeration getTableNamesForDb(String dbName) {
    Enumeration enum = null;
    Hashtable ht = (Hashtable) data.get(dbName);
    if (ht != null) {
      enum = ht.keys();
    }
    return enum;
  }

  /**
   * Gets the Count object for the database & table name.
   * @param dbName        The database name
   * @param tableName     The table name.  Null if you want the count for all the tables in the database
   * @param createIfNotPresent  True:  create a new entry if dbName & tableName not found.  False, just return null.
   * @return Count        The count for that database/table.
   */
  public Count getCountFor(String dbName, TableName tableName, boolean createIfNotPresent) {
    Count count = null;
    if (tableName == null) {
      count = (Count) dbTotals.get(dbName);
    } else {
      Hashtable dbValues = (Hashtable) data.get(dbName);
      if (dbValues == null) {
        if (createIfNotPresent) {
          dbValues = new Hashtable();
          data.put(dbName, dbValues);
        } else {
          return null;
        }
      };

      count = (Count) dbValues.get(tableName);
      if (count == null) {
        if (createIfNotPresent) {
          count = new Count();
          TableName tn2 = new TableName(tableName.ownerName, tableName.tblName);
          dbValues.put(tn2, count);
        } else {
          return null;
        }
      };
    }

    return count;
  }
/*
  public Hashtable getData() {
    return data;
  }

  public Hashtable getDbTotals() {
    return data;
  }
*/

  /**
   * Adds the new values to the data.
   * @param dbName        The database name
   * @param tableName     The table name.
   * @param updateCount   The count to add.
   * @param currentInterval  The updates came from this interval.
   * @param recalcDbTotals   True:  recalc the totals for the db.  False, do not recalc.  If you have many updates
   *                         for the same DB, only change this flag to true for the last update.
   */
  public void add(String dbName, TableName tableName, Count updateCount, int currentInterval, boolean recalcDbTotals) {
    Count count = getCountFor(dbName, tableName, true);

    count.add(updateCount, currentInterval);

    if (recalcDbTotals) {
      recalcDbTotalsFor(dbName);
    };

  }

  /**
   * Adds the new data to the existing data.
   * @param newPubModel   The new data.
   * @param currentInterval  The updates came from this interval.
   */
  public void add(PublicationDataModel newPubModel, int currentInterval) {
    Vector updatedDbs = new Vector();

    for (Enumeration enum = newPubModel.getDbNames(); enum.hasMoreElements();) {
      String dbName = (String) enum.nextElement();
      updatedDbs.add(dbName);
      for (Enumeration enum2 = newPubModel.getTableNamesForDb(dbName); enum2.hasMoreElements();) {
        TableName tableName = (TableName) enum2.nextElement();
        Count newCount = newPubModel.getCountFor(dbName, tableName, false);

        add(dbName, tableName, newCount, currentInterval, false);
      }
    }

    for (int i=updatedDbs.size()-1; i>=0; i--) {
      String dbName = (String) updatedDbs.elementAt(i);
      recalcDbTotalsFor(dbName);
    }

  }

  /**
   * Adds the new data to the existing data.
   * @param pubMsg   All data in this Transaction will be added.
   */
  public void add(TransactionMsg pubMsg) {
    TableName tempName = new TableName();
    String  dbName = pubMsg.getDbName();

    Vector rows = pubMsg.getRows();
    for (int i=rows.size()-1; i>=0; i--) {
      Row row = (Row) rows.elementAt(i);
      processRow( dbName, row, tempName);
    }
  }



  /**
   * Adds the new data to the existing data.
   * @param rowMsg   All data in this Transaction will be added.
   */
  public void add(RowOperationMsg rowMsg) {
    TableName tempName = new TableName();

    String dbName = rowMsg.getDbName();
    processRow( dbName, rowMsg.getRow(), tempName);
  }

  /**
   * Adds the data from one row to the existing data.
   * @param dbName        The database name
   * @param tempName      A temporary tableName object we can use (so we dont need to create a new one each time)
   * @param row           The row.
   */
  private void processRow(String dbName, Row row, TableName tempName) {

    if (row != null) {
      Count count = null;
      tempName.ownerName = row.getSrcOwner();    // do this so we dont have to reallocate new TableName objects when we find existing ones
      tempName.tblName = row.getSrcName();
      Count tempCount = getCountFor(dbName, tempName, true);

      int rowOperation = row.getRowOperation();
      if (rowOperation == Row.InsertOperation) {
        tempCount.rowsInserted++;
      } if (rowOperation == Row.DeleteOperation) {
        tempCount.rowsDeleted++;
      } if (rowOperation == Row.UpdateOperation) {
        tempCount.rowsUpdated++;
      };
    }

   }


  /**
   * Rebuilds the dbTotals hashtable based on all the data.
   * @param dbName        The database name
   */
  private void recalcDbTotalsFor(String dbName) {
    Hashtable myDbValues = (Hashtable) data.get(dbName);
    if (myDbValues != null) {
      Count newCount = new Count();
      int maxInsertInterval = 0;
      int maxDeleteInterval = 0;
      int maxUpdateInterval = 0;
      for (Enumeration enum = myDbValues.elements(); enum.hasMoreElements();) {
        Count count = (Count) enum.nextElement();
        if (maxInsertInterval < count.lastInsertInterval) {
          maxInsertInterval = count.lastInsertInterval;
        };
        if (maxUpdateInterval < count.lastUpdateInterval) {
          maxUpdateInterval = count.lastUpdateInterval;
        };
        if (maxDeleteInterval < count.lastDeleteInterval) {
          maxDeleteInterval = count.lastDeleteInterval;
        };
        newCount.add(count, 0);
      }
      newCount.lastDeleteInterval = maxDeleteInterval;
      newCount.lastUpdateInterval = maxUpdateInterval;
      newCount.lastInsertInterval = maxInsertInterval;
      dbTotals.put(dbName, newCount);
    }
  }

}
