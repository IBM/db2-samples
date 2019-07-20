import java.awt.*;
import java.awt.datatransfer.*;
import java.awt.event.*;
import javax.swing.*;

/**
 * The SubscriptionDialog is a small dialog that prompts for the subscription name, queue manager, and
 * queue name for activating and deactivating subscriptions.
 *
 * @author tjacopi
 *
 */
public class SubscriptionDialog extends JDialog implements ActionListener {
  protected JTextField subNameTF = null;
  protected JTextField qMgrNameTF = null;
  protected JTextField qNameTF = null;
  protected JButton    okBt    = null;
  protected JButton    cancelBt = null;
  protected boolean    okPressed = false;

  public SubscriptionDialog(JFrame parent, String title) {
      super(parent, title, true);

      getContentPane().setLayout( new BorderLayout() );

      JPanel textFieldPanel = buildTextFieldPanel();
      JPanel buttonPanel = buildButtonPanel();

  	   getContentPane().add("North", textFieldPanel);
  	   getContentPane().add("South", buttonPanel);
    }


	/**
    * Build the panel with the text fields.
	 * @return JPanel  The panel.
	 */
    protected JPanel buildTextFieldPanel() {
      JPanel panel = new JPanel();
      panel.setLayout( new GridLayout(3,2) );

      panel.add( new JLabel("Queue Manager") );
      panel.add( qMgrNameTF = new JTextField() );
      panel.add( new JLabel("Admin Queue") );
      panel.add( qNameTF = new JTextField() );
      panel.add( new JLabel("Subscription Name") );
      panel.add( subNameTF = new JTextField() );

      return panel;
    }

	/**
    * Build the panel with the buttons.
	 * @return JPanel  The panel.
	 */
    protected JPanel buildButtonPanel() {
      JPanel panel  = new JPanel();
      JPanel panel2 = new JPanel();
      panel2.setLayout( new FlowLayout(FlowLayout.RIGHT) );

      panel2.add( okBt = new JButton("Ok") );
      okBt.addActionListener(this);
      panel2.add( cancelBt = new JButton("Cancel") );
      cancelBt.addActionListener(this);

      panel.add(panel2);
      return panel;
    }


	/**
    * This is called whenever a user picks a menu item.
	 * @param e   The event for the action.
	 */
    public void actionPerformed(ActionEvent e) {
      Object source = e.getSource();
      if (source == okBt) {
        okPressed = true;
        dispose();
      } else if (source == cancelBt) {
        dispose();
      }
    }

    public boolean wasOkPressed() {
      return okPressed;
    }



	/**
    * Return the text of the subscription name that the user entered.
	 * @return String   The subscription name that user entered.
	 */
    public String getSubscriptionName() {
      return subNameTF.getText();
    }

	/**
    * Return the queue name that the user entered.
	 * @return String   The queue name that user entered.
	 */
    public String getQueueName() {
      return qNameTF.getText();
    }

	/**
    * Return the queue manager name that the user entered.
	 * @return String   The queue manager that user entered.
	 */
    public String getQueueMgrName() {
      return qMgrNameTF.getText();
    }
}
