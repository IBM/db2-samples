import java.util.*;
import java.awt.*;
import javax.swing.table.*;
import javax.swing.*;


/**
 * The PublicationTableCellRenderer will do the following:
 *   1.  Show the database summary lines in bold
 *   2.  Right justify the numbers.
 *   3.  Shade the background of the recently updated cells.
 *
 * @author tjacopi
 *
 */
public class PublicationTableCellRenderer extends DefaultTableCellRenderer {

  protected Font  defaultFont = null;
  protected Font  boldFont = null;
  protected Color normalBackground = null;
  protected Color recentUpdateBk1Color = new Color(195, 255, 255);
  protected Color recentUpdateBk2Color = new Color(190, 255, 255);
  protected Color recentUpdateBk3Color = new Color(230, 255, 255);
  protected int   currentInterval = 0;
  protected boolean bShowTimeShading = false;


  /**
   * Set if the cell backgrounds should be different if the values where recently changed.
   * @param timeShading  true = shade the rows that recently changed.  False = use the standard background
   */
  public void setTimeShading(boolean timeShading) {
    bShowTimeShading = timeShading;
  }

  /**
   * Get the current value of the time shading.
   * @return boolean  true = shade the rows that recently changed.  False = use the standard background
   */
  public boolean getTimeShading() {
    return bShowTimeShading;
  }

  /**
   * This lets the renderer know what the current interval is (for timeshading).  Cells that
   * are within two intervals of this one have a different background.
   * @param newInterval  The new interval.
   */
  public void setCurrentInterval(int newInterval) {
    currentInterval = newInterval;
  }


  /**
   * Called when the JTable renders a cell.
   */
  public Component getTableCellRendererComponent(JTable table,
                                               Object value,
                                               boolean isSelected,
                                               boolean hasFocus,
                                               int row,
                                               int column) {
    JLabel c = (JLabel) super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, column);
    PublicationTableModel tm = (PublicationTableModel) table.getModel();
    if (defaultFont == null) {                         // If first time
      defaultFont = c.getFont();                       // ..then save the current font as the default
      boldFont = defaultFont.deriveFont(Font.BOLD);    // ..and create a bold version of it
      normalBackground = getBackground();              // ..and save the background
    };

    if (tm.isDbRow(row) ) {                            // If is a database row
      c.setFont(boldFont);                             // ..then use bold
    } else {
      c.setFont(defaultFont);                          // ..else just use the default font
    }

    if (column == 0) {                                 // If the database name column...
      if (!isSelected)                                 // ..and selected...
        c.setBackground(normalBackground);             // ..then use the default background
      c.setHorizontalAlignment(SwingConstants.LEFT);   // and left justify
    } else {
      if (!isSelected)  {                              // Only timeshade unselected rows
        if (bShowTimeShading && value instanceof StringWithInterval) {
          StringWithInterval intervalString = (StringWithInterval) value;
          int cellInterval = intervalString.getInterval();
          int intervalDelta = currentInterval - cellInterval;
          switch (intervalDelta) {
            case 0:
              c.setBackground(recentUpdateBk2Color);
              break;
            case 1:
              c.setBackground(recentUpdateBk3Color);
              break;
            default:
              c.setBackground(normalBackground);
              break;
          }
        } else {
          c.setBackground(normalBackground);
        }
      }

      c.setHorizontalAlignment(SwingConstants.RIGHT);
    }

    return c;
  }

}
