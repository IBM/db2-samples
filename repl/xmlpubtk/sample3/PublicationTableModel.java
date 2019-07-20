import java.util.*;
import javax.swing.table.*;


/**
 * The PublicationTableModel class supplies the logic that maps from an AbstractTableModel to
 * the PublicationDataModel (which actually holds the data).  It knows if we are doing things
 * like actually showing the detail for tables.
 *
 * The mapping is done via the dataMapping and rowIndexes variables as follows:
 *   dataMapping:  This is a vector that holds a list of "DataMap" structures, one per database.
 *                 A dataMap has the database name, and a list of tables in that database that
 *                 we are displaying.
 *   rowIndexes:   This is the JTable row index of the database entry for the DataMap.
 *                 If we are not showing the tables, then the rowIndex maps directly to the DataMap
 *                   (ie, the third row index is the thrid DataMap).
 *                 What this does is help us find the correct DataMap via a rowIndex more quickly.
 *                 When the JTable calls getValueAt(row, col), then we can translate the row to the
 *                 correct DataMap more quickly.
 *
 * @author tjacopi
 *
 */
public class PublicationTableModel extends AbstractTableModel {

  protected static final int NUM_COLS = 4;
  protected static final String[] colNames = {"Name", "Rows Inserted", "Rows Updated", "Rows Deleted"};

  protected PublicationDataModel dataModel = null;
  protected Vector dataMapping = new Vector();
  protected int[]  rowIndexes = null;
  protected boolean bShowTables = false;

  public PublicationTableModel(PublicationDataModel model) {
    dataModel = model;
    buildDataMapping();
  }

  public String getColumnName(int col) {
    return colNames[col];
  }

  public int getColumnCount() {
    return colNames.length;
  }

  public int getRowCount() {
    int count = dataMapping.size();                         // Add all the Database summary lines
    if (bShowTables) {
      for (int i=dataMapping.size()-1; i>=0; i--) {         // Then for each one....
        DataMap map = (DataMap) dataMapping.elementAt(i);
        if (map.tableNames != null) {
          count = count + map.tableNames.size();            // add the number of tables in that db
        };
      }
    }

    return count;
  }


  /**
   * The JTable calls this to the the value of a particular cell.
   * @param row  The row.
   * @param col  The column.
   * @return Object  The object to be shown in the cell.
   */
  public Object getValueAt(int row, int col) {
    Object value = null;

    if (bShowTables) {                                  // Are we showing the tables?
      int dbIndex = 0;
      boolean bStop = false;
      for (int i=1; i<rowIndexes.length && !bStop; i++) {  // Traverse the rowIndexes array
        if (row >= rowIndexes[i]) {
          dbIndex = i;                                     // The previous one is the one we want
        } else {
          bStop = true;                                    // Aaah, past the index, so we can leave
        }
      }

      DataMap map = (DataMap) dataMapping.elementAt(dbIndex);
      int remainingIndex = row - rowIndexes[dbIndex];      // Calc the index into the tables list
      if (remainingIndex == 0 ) {                          // if its a 0, then its a database summary entry
        if (col == 0) {
          value = map.dbName;
        } else {
          Count count = dataModel.getCountFor(map.dbName, null, false);
          value = getDisplayCol(col, count);              // And create a StringWithInterval object to display it
        }

      } else {                                            // Its a table entry...
        TableName tableName = (TableName) map.tableNames.elementAt(remainingIndex-1);  // get the table name
        if (col == 0 ) {
          value = "    " + tableName;                     // add spaces so name appears indented under db name
        } else {
          Count count = dataModel.getCountFor(map.dbName, tableName, false);
          value = getDisplayCol(col, count);              // And create a StringWithInterval object to display it
        }
      }

    } else {                                                 // We are not showing the tables.
      DataMap map = (DataMap) dataMapping.elementAt(row);    // Just use the row as a direct index to the DataMap
      if (col == 0) {
        value = map.dbName;
      } else {
        Count count = dataModel.getCountFor(map.dbName, null, false);  // Get the summary count
        value = getDisplayCol(col, count);                   // And create a StringWithInterval object to display it
      }
   }

    return value;
  }

  /**
   * Add a new data model to the existing one.
   * @param newData  The new data.
   * @param interval This data was created in this interval (used for timeshading)
   */
  public void addNewData(PublicationDataModel newData, int interval) {
    dataModel.add(newData, interval);
    buildDataMapping();
    fireTableDataChanged();
  }

  /**
   * Gets the index of the DataMap object for this JTable row.
   * @param  row   The row in the JTable.
   * @returm int   The index of the DataMap.
   */
  protected int getDataMapIndexForRow(int row) {
    int dbIndex = 0;
    if (bShowTables) {
      boolean bStop = false;
      for (int i=1; i<rowIndexes.length && !bStop; i++) {
        if (row >= rowIndexes[i]) {
          dbIndex = i;                    // The previous one is the one we want
        } else {
          bStop = true;
        }
      }
    } else {                              // Not showing tables, so the indexes map directly
      dbIndex = row;
    }

    return dbIndex;
  }


  /**
   * Crteate the correct object used to display the value for the column.  The first
   * column uses a string (db name and table names), the others use a StringWithInterval.
   * @param  col     The column being displayed
   * @param  count   The Count for the column.
   * @returm Object  Either a String or StringWithInterval.
   */
  private Object getDisplayCol(int col, Count count) {
    int   intValue = 0;
    int   interval = 0;

    if (col == 1) {
      intValue = count.rowsInserted;
      interval = count.lastInsertInterval;
    } else if (col == 2) {
      intValue = count.rowsUpdated;
      interval = count.lastUpdateInterval;
    } else if (col == 3) {
      intValue = count.rowsDeleted;
      interval = count.lastDeleteInterval;
    }

    String text = Integer.toString(intValue);

    return new StringWithInterval(text, interval);
  }


  /**
   * This function builds an array that maps every row number to a specific entry
   * in the data model.
   */
  private void buildDataMapping() {
    int numDbs = dataModel.getDbNameCount();
    rowIndexes = new int[numDbs];
    dataMapping = new Vector(numDbs);
    int rowNum    = 0;
    int dbCounter = 0;

    for (Enumeration enum = dataModel.getDbNames(); enum.hasMoreElements();) {
      String dbName = (String) enum.nextElement();
      rowIndexes[dbCounter] = rowNum;
      rowNum++;                                 // increment for the db line
      Vector tableNames = new Vector();
      for (Enumeration enum2 = dataModel.getTableNamesForDb(dbName); enum2.hasMoreElements();) {
        TableName tableName = (TableName) enum2.nextElement();
        tableNames.add(tableName);
        rowNum++;
      }

      dataMapping.add(  new DataMap(dbName, tableNames) );
      dbCounter++;
    }

  }


  /**
   * Is the row index for a databse summary row?
   * @param  row   The index.
   * @return boolean  True: the index is a summary row.  False :  its a table row
   */
  public boolean isDbRow(int row) {
    boolean dbRow = false;
    if (bShowTables) {
      for (int i=0; i<rowIndexes.length && dbRow == false; i++) {
        if (rowIndexes[i] == row) {
          dbRow = true;
        }
      }
    } else {                                 // If not showing tables...
      dbRow = true;                          // ...then everthing is a summary row
    }
    return dbRow;
  }


  /**
   * Set the ability to show the table detail data.
   * @param  showTables  True:  show the details for the tables.
   */
  public void setShowTables(boolean showTables) {
    if (bShowTables != showTables) {
      bShowTables = showTables;
      fireTableDataChanged();                // Tell the JTable that we updated all the data.
    };
  }

  public boolean areTablesShowing() {
    return bShowTables;
  }


  class DataMap {
    public Vector tableNames = null;
    public String dbName = null;

    public DataMap() {;}
    public DataMap(String dbName, Vector tableNames) {
      this.dbName = dbName;
      this.tableNames = tableNames;
    }
  }

}
