import java.awt.*;
import java.awt.datatransfer.*;
import java.awt.event.*;
import javax.swing.*;


/**
 * The MonitorFrame is the JFrame that holds the MonitorTablePanel.  It provides support
 * for the menu items.
 *
 * @author tjacopi
 *
 */
public class MonitorFrame extends JFrame implements ActionListener {
  protected MonitorTablePanel tablePanel = null;
  protected JMenuItem copyMI = null;
  protected JMenuItem exitMI = null;
  protected JMenuItem aboutMI = null;
  protected JMenuItem selectAllMI = null;

    public MonitorFrame(String qmgrName, String qName, String topicName) {
      super("Replication Montior - " + qmgrName + " : " +((qName!=null)?qName:topicName)   );

      getContentPane().setLayout( new BorderLayout() );

      tablePanel = new MonitorTablePanel(qmgrName, qName, topicName);
  	   getContentPane().add("Center", tablePanel);

      JMenuBar menuBar = buildMenuBar();
      setJMenuBar(menuBar);
    }

	/**
    * Create the menubar on the frame.
	 * @return JMenuBar  The menubar.
	 */
    protected JMenuBar buildMenuBar() {
      JMenuBar menuBar = new JMenuBar();
      JMenu menu;

      // Build the File menu
      menu = new JMenu("File");
      exitMI = new JMenuItem("Exit");
      exitMI.addActionListener(this);
      menu.add(exitMI);
      menuBar.add(menu);

      // Build the Edit menu
      menu = new JMenu("Edit");
      copyMI = new JMenuItem("Copy");
      copyMI.addActionListener(this);
      menu.add(copyMI);
      menuBar.add(menu);

      // Build the Selected menu
      menu = new JMenu("Selected");
      selectAllMI = new JMenuItem("Select All");
      selectAllMI.addActionListener(this);
      menu.add(selectAllMI);
      menuBar.add(menu);

      // Build the File menu
      menu = new JMenu("Help");
      aboutMI = new JMenuItem("About...");
      aboutMI.addActionListener(this);
      menu.add(aboutMI);
      menuBar.add(menu);

      return menuBar;
    }

	/**
    * This is called whenever a user picks a menu item.
	 * @param e   The event for the action.
	 */
    public void actionPerformed(ActionEvent e) {
      Object source = e.getSource();
      if (source == copyMI) {
        Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
        StringSelection ss = new StringSelection(tablePanel.getSelectedContentsAsString());
        clipboard.setContents(ss, ss);
      } else if (source == selectAllMI) {
        tablePanel.selectAll();
      } else if (source == exitMI) {
        System.exit(0);
      } else if (source == aboutMI) {
        JOptionPane.showMessageDialog(this, "DB2 Replication Sample");
      }
    }

}
