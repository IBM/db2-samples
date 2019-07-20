import java.awt.*;
import java.awt.datatransfer.*;
import java.awt.event.*;
import javax.swing.*;
import com.ibm.db2.tools.repl.publication.*;

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
  protected JMenuItem activateSubMI = null;
  protected JMenuItem deactivateSubMI = null;
  protected JMenuItem selectAllMI = null;
  protected JCheckBoxMenuItem timeShadingMI = null;
  protected JCheckBoxMenuItem viewTablesMI = null;

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

      // Build the View menu
      menu = new JMenu("View");
      viewTablesMI = new JCheckBoxMenuItem("Tables");
      viewTablesMI.addActionListener(this);
      menu.add(viewTablesMI);
      timeShadingMI = new JCheckBoxMenuItem("Time Shading");
      timeShadingMI.addActionListener(this);
      menu.add(timeShadingMI);
      menuBar.add(menu);

      // Build the Subscription menu
      menu = new JMenu("Subscription");
      activateSubMI = new JMenuItem("Activate...");
      activateSubMI.addActionListener(this);
      menu.add(activateSubMI);
      deactivateSubMI = new JMenuItem("Deactivate...");
      deactivateSubMI.addActionListener(this);
      menu.add(deactivateSubMI);
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
      if (source == timeShadingMI) {
        tablePanel.setTimeShading( timeShadingMI.isSelected() );
      } else if (source == viewTablesMI) {
        tablePanel.setShowTables( viewTablesMI.isSelected() );
      } else if (source == copyMI) {
        Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
        StringSelection ss = new StringSelection(tablePanel.getSelectedContentsAsString());
        clipboard.setContents(ss, ss);
      } else if (source == selectAllMI) {
        tablePanel.selectAll();
      } else if (source == exitMI) {
        System.exit(0);
      } else if (source == aboutMI) {
        JOptionPane.showMessageDialog(this, "DB2 Replication Sample");
      } else if (source == activateSubMI) {
        manageSubscriptions(true);
      } else if (source == deactivateSubMI) {
        manageSubscriptions(false);
      }
    }

	/**
    * This will prompt the user for the subscription name, and then either activate or deactivate it.
	 * @param isActivate  true:  the user wants to activate a subscription.  False :  they want to deactivate it.
	 */
    protected void manageSubscriptions(boolean isActivate) {

      // Craete and show sub dialog.
      SubscriptionDialog subDialog = new SubscriptionDialog(this,
                                       (isActivate? "Activate Subscription" : "Deactivate Subscription") );
      subDialog.pack();
      subDialog.show();

      if ( subDialog.wasOkPressed() ) {
        ControlMsg msg = null;
        String subscriptionName = subDialog.getSubscriptionName();
        String qManager = subDialog.getQueueMgrName();
        String qName    = subDialog.getQueueName();
        if (subscriptionName != null    && qManager != null    && qName != null &&
            subscriptionName.length()>0 && qManager.length()>0 && qName.length()>0 ) {
          if (isActivate) {
            System.out.println("Attempting to activate subscription " + subscriptionName + " at queue manager " + qManager + " on admin queue " + qName);
            msg = new ActivateSubscriptionMsg(subscriptionName);
          } else {
            System.out.println("Attempting to deactivate subscription " + subscriptionName + " at queue manager " + qManager + " on admin queue " + qName);
            msg = new DeactivateSubscriptionMsg(subscriptionName);
          }

          try {
            msg.send(qManager, qName);                         // Send the request
          } catch (Exception ex) {
            System.out.println("Message failed...error " + ex);
          }
        } else {
          System.out.println("Message not sent because either subscription name, queue manager, or queue name was not specified");
        }
      }

    }

}
