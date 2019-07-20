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

    protected JScrollPane tableScrollPane;
    protected PublicationTableModel tableModel;
    protected PublicationTableCellRenderer cellRenderer;
    protected PublicationListener  pubListener;
    protected JTable table;
    protected javax.swing.Timer timer     = null;
    protected int currentInterval = 0;
    protected int lastUpdateInterval = 0;

    public MonitorTablePanel(String qmgrName, String qName, String topicName) {

      setLayout( new BorderLayout() );

      // The pubListener will listen to the queue
      pubListener = new PublicationListener(qmgrName, qName, topicName);
      pubListener.start();                                     // Start listening to the queue

      // Now setup the JTable
      PublicationDataModel pdm = new PublicationDataModel();   // Build a new model of the data
      tableModel = new PublicationTableModel(pdm);             // The model for the table uses the data model
      table = new JTable(tableModel);
      tableScrollPane = new JScrollPane(table);

      // Tell each column to use our custom cell renderer.  This is to paint the DB total lines in
      // bold, as well as set the background for recent updates columns.
      TableColumnModel colModel = table.getColumnModel();
      cellRenderer = new PublicationTableCellRenderer();
      int colCount = colModel.getColumnCount();
      for (int i=0; i<colCount; i++) {
        TableColumn tc = colModel.getColumn(i);
        tc.setCellRenderer(cellRenderer);
      }

      // Start a timer to receive updates.  When this timer pops, we will fetch the updates
      // and add them to our data model
      timer = new javax.swing.Timer(4000, this );
      timer.start();

	   add("Center", tableScrollPane );
    }


    /**
     * Set if the cell backgrounds should be different if the values where recently changed.
     * @param timeShading  true = shade the rows that recently changed.  False = use the standard background
     */
    public void setTimeShading(boolean timeShading) {
      cellRenderer.setTimeShading(timeShading);
    }

    /**
     * Get the current value of the time shading.
     * @return boolean  true = shade the rows that recently changed.  False = use the standard background
     */
    public boolean getTimeShading() {
      return cellRenderer.getTimeShading();
    }

    /**
     * Set if we should show detail information about the individual tables.
     * @param timeShading  true = show the tables.  False = only show a summary line for the db
     */
    public void setShowTables(boolean showTables) {
      tableModel.setShowTables(showTables);
    }

	/**
    * Get whatever is selected as a string.
    * @return  String  The selected values.
	 */
    public String getSelectedContentsAsString() {
      StringBuffer strBuffer = new StringBuffer(100);
      int[] rows = table.getSelectedRows();
      boolean firstTime = true;
      int numCols = table.getModel().getColumnCount();
      for (int i=0; i<rows.length; i++) {
        for (int j=0; j<numCols; j++) {
          if (!firstTime) {
            strBuffer.append(" ");
          };
          String s = tableModel.getValueAt(rows[i], j).toString();
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
    * This is called to get any updates and add them to the current values in the table.
	 */
    protected void checkForDataUpdates() {
      currentInterval++;                                          // Advance to the next interval
      cellRenderer.setCurrentInterval(currentInterval);           // ..and let the renderer know about it
      PublicationDataModel pdm = pubListener.getUpdates();        // Get the new updates since last getUpdates() call
      int numDbs = pdm.getDbNameCount();                          // The count of databases updated
      if (numDbs >0) {                                            // Was anything updated?
        lastUpdateInterval = currentInterval;                     // ..yes
        tableModel.addNewData(pdm, currentInterval);              // ..and add the new data to the existing ones
      } else {                                                    // ..no updates
        if (lastUpdateInterval + 2 >= currentInterval  &&         // If we had recent updates, force a
            cellRenderer.getTimeShading() ) {                     // and we are time shading
          table.repaint();                                        // ..then we need to repaint so recent updates fade out
        };
      }
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
