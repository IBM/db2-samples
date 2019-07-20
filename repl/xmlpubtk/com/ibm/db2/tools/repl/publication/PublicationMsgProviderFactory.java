package com.ibm.db2.tools.repl.publication;

import  com.ibm.db2.tools.repl.publication.support.*;

/**
 * The PublicationMsgProviderFactory class is used to create a default implmenentation of
 * a PublicationMsgProvider.  Once you create a provider, you need to add a PublicationListener
 * and call "dispatchMsgs" to start the messages.
 *
 * @author tjacopi
 *
 * To change the template for this generated type comment go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
public class PublicationMsgProviderFactory {

   /**
    * This will create a default message provider.
    * @return PublicationMsgProvider  The default provider.
    */
   public static PublicationMsgProvider createPublicationMsgProvider() throws Exception {
     return new PublicationMsgProviderImpl();
   }

}
