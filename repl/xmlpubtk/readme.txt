I. Contents
   This zip file contains the following:
     1.  The *.jar file for the XML Publication toolkit
     2.  The javadoc for the XML Publication toolkit
     3.  Several small samples that use the toolkit


II. Installation
    To install the toolkit, you need to do the following:
     1.  Unzip the file into a directory of your choice.
     2.  Place the xmlPubTk.jar file in your classpath.
     3.  The toolkit requires the xerces parser to work (not shipped as part of
         the toolkit), which needs to be in the classpath.
         If you have DB2 Control Center installed, you have an parser and
         can add the following jar files to your classpath:
            \sqllib\tools\xml-apis.jar;
            \sqllib\tools\xercesImpl.jar;
     4.  Of course, you need all the *.jar files from MQ.  These jar files have the JMS support.


III.  Samples
   There are a set of programs given, which to the following:
     -  LoadQueue  This is a program meant to be run with one of the other samples.  This puts
                   a message on a queue or publishes it to a topic.  This simulates the
                   capture program writing the xml publication messages, so you dont have to
                   actually run capture to test the samples.
     -  sample1    This is a the easiest sample that listens to a queue and writes to a command line.
     -  sample2    This is a bit more complex, and keeps track of updates to tables, and shows the running
                   total in a window.
     -  sample3    This expands on sample3, allowing subtotalling of the updates by database and shading
                   of the most recently updated cells.  In addition, the sample shows how to send control
                   messages to QCapture that activate and deactivate subscriptions.

   The programs take the following parameters.
     -qmgr :  the name of the queue manager
     -queue :  The queue name (for a point-to-point style)
     -topic :  The topic name (for a publish/subscribe style)

     The -qmgr parameter is always required, and then you must specify either "-queue" or "-topic".
     Note that the sample1 program does not support "-topic" to make it as short as possible.

   To run the samples, you need to do the following:
      1.  Have the name of a MQ QueueManager and MQ Queue available.  You can use an existing queue manager
          and queue....or you can create new ones (when creating the Queue, select "Local" as the type).
      2.  Setup your classpath as listed under installation.
      3.  The code for the samples is in a *.jar file under each sample directory.  Modify your CLASSPATH to
          include that *.jar file.
      3.  Go to the loadQueue directory and run the LoadQueue program by:

              "java LoadQueue -qmgr <your queue mgr name> -queue <your queue name>"

          This will put messages on the queue.  You need to leave this program running if your queue is
          not persistant.
       4. Go to the sample1 directory and run the sample program by:

              "java sample1 -qmgr <your queue mgr name> -queue <your queue name>"

          You should see a count of rows changed.


    Note in order to use topic in the publish/subscribe style, a MessageBroker must be installed
    and running.  You can read about that in "WebSphere MQ Using Java" (SC34-6066-02) on page 26
    titled "Additional setup for publish/subscribe mode".
