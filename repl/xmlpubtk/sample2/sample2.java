import java.awt.*;
import java.awt.event.*;
import javax.swing.*;


/**
 * The sample2 class is the small class to create a new frame and make it visible.
 *
 * @author tjacopi
 *
 */
public class sample2  {


  public static void main(String args[]) {
    try {
      UIManager.setLookAndFeel("com.sun.java.swing.plaf.windows.WindowsLookAndFeel");
    } catch (Exception e) {
      e.printStackTrace();
    }

    // Get the arguments the user passed in
    String qManager  = parseArgsFor("-qmgr", args);
    String qName = parseArgsFor("-queue", args);
    String topicName = parseArgsFor("-topic", args);

    // Insure qManager and either qName or topicName was specified
    if (qManager != null && (qName != null || topicName != null)  ) {
   	MonitorFrame frame = new MonitorFrame(qManager, qName, topicName);
	   frame.addWindowListener(new WindowAdapter() {
	      public void windowClosing(WindowEvent e) {System.exit(0);}
    	});
	   frame.pack();
	   frame.setVisible(true);
    } else {
      printHelp();
      System.exit(0);
    }
  }


  protected static void printHelp() {
    System.out.println("Usage:  java sample2 -qmgr <queueManager> (-queue <queue name> | -topic <topic name>) ");
    System.out.println("  example:  java sample2 -qmgr DefaultQMGR -queue myPubQ");
    System.out.println("          - or -       ");
    System.out.println("  example:  java sample2 -qmgr DefaultQMGR -topic myTopic");
  }

  protected static String parseArgsFor(String argName, String[] args) {
    String argValue = null;
    for (int i =0; i<args.length-1 && argValue == null; i++) {
      if (argName.equals(args[i]) ) {
        argValue = args[i+1];
      }
    }
    return argValue;
  }
}
