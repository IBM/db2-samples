import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.table.*;
import javax.swing.event.*;
import java.util.*;

/**
 * The MonitorTablePanel creates a JTable to show the values.  It starts a timer, and checks
 * the PublicationListener every few seconds to get any recent updates.  If there were updates,
 * it adds them to the values that are currently showing in the JTable.
 *
 * @author tjacopi
 *
 */
public class MonitorTablePanel extends JPanel implements ActionListener {

    protected static String[] colNames = {"Table Name", "Rows Inserted", "Rows Updated", "Rows Deleted"};

    protected JScrollPane         tableScrollPane = null;
    protected DefaultTableModel   tableModel      = null;
    protected PublicationListener pubListener     = null;
    protected JTable              table           = null;
    protected javax.swing.Timer   timer           = null;


    public MonitorTablePanel(String qmgrName, String qName, String topicName) {
      setLayout( new BorderLayout() );

      // The pubListener will listen to the queue
      pubListener = new PublicationListener(qmgrName, qName, topicName);
      pubListener.start();                                     // Start listening to the queue

      // Now create the JTable
      tableModel = new DefaultTableModel(colNames, 0);         // The model for the table uses the data model
      table = new JTable(tableModel);
      tableScrollPane = new JScrollPane(table);
	   add("Center", tableScrollPane );

      // Start a timer to receive updates.  When this timer pops, we will fetch the updates
      // and add them to our data model
      timer = new javax.swing.Timer(4000, this );
      timer.start();
    }


	/**
    * This is called to get any updates and add them to the current values in the table.
	 */
    protected void checkForDataUpdates() {
      Hashtable updates = pubListener.getUpdates();        // Get the new updates since last getUpdates() call
      for (Enumeration enum = updates.keys(); enum.hasMoreElements();) {
        String id = (String) enum.nextElement();           // The qualified name of the table
        Count count = (Count) updates.get(id);             // ..and its recent changes...
        int rowIndex = getTableModelRowFor(id);            // Get the row for the table (will create a new row if does not exist)
        updateRow(rowIndex, count);                        // And add the updates to it...
      }
    }


	/**
    * Get the index of the row for the passed in key.  If the key is not found, a new
    * row is created in the table in the correct (sorted) location, with values of "0".
    * @param  key  The qualified table name which is in the first column of the table.
    * @return int  The index of the row in the table model
	 */
    protected int getTableModelRowFor(String key) {

      int numRows = tableModel.getRowCount();
      if (numRows == 0) {                    // If tableModel is empty
        createRowAt(0, key);
        return 0;
      };

      // Do a binary search to find the key
      int foundIndex = -1;
      int low = 0;
      int high = numRows - 1;
      while (low <= high && foundIndex == -1 ) {
        int mid = (low + high) / 2;
        String str = tableModel.getValueAt(mid, 0).toString();
        int c = key.compareTo(str);
        if (c < 0)
          high = mid - 1;
        else if (c > 0)
          low = mid + 1;
        else
          foundIndex = mid;
      }

      // If not found, insert a new row where it should have been found.
      if (foundIndex == -1) {
        if (low >= numRows) {
          foundIndex = numRows;
        } else if (high < 0) {
          foundIndex = 0;
        } else {
          String strLow = tableModel.getValueAt(low, 0).toString();
          if (key.compareTo(strLow) > 0) {
            foundIndex = low+1;
          } else {
            String strHigh = tableModel.getValueAt(high, 0).toString();
            if (key.compareTo(strHigh) > 0) {
              foundIndex = high + 1;
            } else {
              foundIndex = high;
            }
          }
        }
        createRowAt(foundIndex, key);
      };

      return foundIndex;
    }


	/**
    * Create a new row at the specified index.  The new row has "0" for its values.
    * @param  index  Add the new row at this index.
    * @param  key  The qualified table name which is in the first column of the table.
	 */
    protected void createRowAt(int index, String key) {
      String[] newRow = {key, "0", "0", "0"};                      // Make the new row
      tableModel.addRow(newRow);                                   // Add it at the bottom
      int lastRowIndex = tableModel.getRowCount()-1;               // Get the index
      tableModel.moveRow(lastRowIndex, lastRowIndex, index);       // And move it to the right place
    }

	/**
    * Update the specified row with the new values in the Count structure.
    * @param  rowIndex  The row in the table model.
    * @param  count     The Count structure with the new updates.
	 */
    protected void updateRow(int rowIndex, Count count) {
      if (count.rowsInserted >0) {
        addToCell(rowIndex, 1, count.rowsInserted);
      };
      if (count.rowsUpdated >0) {
        addToCell(rowIndex, 2, count.rowsUpdated);
      };
      if (count.rowsDeleted >0) {
        addToCell(rowIndex, 3, count.rowsDeleted);
      };
    }

	/**
    * Add the specified value to this table cell.
    * @param  rowIndex  The row in the table model.
    * @param  colIndex  The col in the table model.
    * @param  amount    The amount to add to the cell.
	 */
    protected void addToCell(int rowIndex, int colIndex, int amount) {
      try {
        String strOldValue = (String) tableModel.getValueAt(rowIndex, colIndex); // The old value as a string
        int intOldValue = Integer.parseInt(strOldValue);             // Convert to an int
        int intNewValue = intOldValue + amount;                      // Now add to it
        String strNewValue = Integer.toString(intNewValue);          // Back to a string
        tableModel.setValueAt(strNewValue, rowIndex, colIndex);      // And set it to the table
      } catch(Throwable t) {
        System.out.println("Caught " + t + " when adding counts");
        t.printStackTrace();
      }
    }

	/**
    * Get whatever is selected as a string.
    * @return  String  The selected values.
	 */
    public String getSelectedContentsAsString() {
      StringBuffer strBuffer = new StringBuffer(100);
      int[] rows = table.getSelectedRows();
      boolean firstTime = true;
      for (int i=0; i<rows.length; i++) {
        for (int j=0; j<colNames.length; j++) {
          if (!firstTime) {
            strBuffer.append(" ");
          };
          String s = (String) tableModel.getValueAt(rows[i], j);
          strBuffer.append(s);
          firstTime = false;
        }
      }

      return strBuffer.toString();
    }


	/**
    * Select everything in the table.
	 */
    public void selectAll() {
      table.selectAll();
    }

	/**
    * This is called whenever the timer pops.
	 */
    public void actionPerformed(ActionEvent e) {
      // We cannot call checkForDataUpdates() directly here, because we are on
      // the timer thread.  Instead, post a msg to the event thread.
      SwingUtilities.invokeLater( new CheckDataRunnable() );    // Post to event thread
    }

    class CheckDataRunnable implements Runnable {
      public void run() {
        checkForDataUpdates();                                  // runs on event thread
      }
    }
}
