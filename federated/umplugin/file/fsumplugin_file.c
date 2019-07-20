/******************************************************************************
**
** Source File Name: fsumpluginfile.c
**
** (C) COPYRIGHT International Business Machines Corp. 2007
** All Rights Reserved
** Licensed Materials - Property of IBM
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
** Function = Sample plug-in that provides an interface for accessing
** user mapping entries that are stored in a text file.
**
** Operating System: All
**
*******************************************************************************/
#include <stdio.h>
#include <string.h>
#include "fsumplugin.h"
#include "fsumplugin_file.h"

/* Declare the utility functions. The FSUMPluginInit function
resolves the addresses of these functions. */
FSUMlogErrorMsgFP  *FSUMlogErrorMsg = NULL;
FSUMaddUMOptionFP  *FSUMaddUMOption = NULL;
FSUMallocateFP     *FSUMallocate = NULL;
FSUMdeallocateFP   *FSUMdeallocate = NULL;

#if defined ( _WIN32 )
#define snprintf _snprintf
#endif

/* The function that decrypts the password. */
void decryptPassword(const char* a_encryptedPwd,
                     size_t a_encryptedPwdLen,
                     char** a_decryptedPwd,
                     size_t* a_decryptedPwdLen)
{
   sqlint32 i;
   char* password;
   void* buffer;
   /* Encrypt all passwords in the external repository.
      In this sample, passwords are encrypted by reversing
      the bytes. This simple encryption is used only
      to demonstrate the process of decryption. Customize
      the encryption to match the security
      that your environment uses.
   */
   *a_decryptedPwdLen = a_encryptedPwdLen;

   /* Add 1 byte for '\0' */
   FSUMallocate (*a_decryptedPwdLen + 1, &buffer);
  
   password = (char*)buffer;

   /* Decrypt the password. In this sample, the decryption copies
   the bytes in the reverse order. Customize the decryption to match
   the security that your environment uses.*/
   for (i = 0; i < a_encryptedPwdLen; i++)
   {
      password[i] = a_encryptedPwd[a_encryptedPwdLen - 1 - i];
   }

   password[i] = '\0';

   *a_decryptedPwd = password;

}

/* Implementation of the FSUMconnect API. The plug-in must implement this API. */
SQL_API_RC SQL_API_FN myConnect(void** a_FSUMRepository, 
                                const char* a_cfgFilePath)
{
   SQL_API_RC rc = FSUM_PLUGIN_OK;
   char errMsgBuffer[FSUM_MAX_ERROR_MSG_SIZE];
   size_t errMsgLen;
   FILE *configFile = NULL;
   FILE *umFile = NULL;
   char umFileName[FSUM_MAX_NAME_LEN +1]; /* leave room for '\0' */
   char configFileFullPathName[FSUM_MAX_PATH_LEN + FSUM_MAX_NAME_LEN + 1] = {'\0'};
   size_t fileSize;

   /* Add the path to the configuration file. */
   /* The configuration file and the plug-in must be in the
      same directory. If the federated server calls the API, 
      a_cfgFilePath points to a string that represents the path
      of the plug-in. */
   if(a_cfgFilePath != NULL)
   {
      strncat(configFileFullPathName, a_cfgFilePath, FSUM_MAX_PATH_LEN);
   }

   /* Add the name of the configuration file. */
   strncat(configFileFullPathName, FSUM_CONFIG_FILE_NAME, FSUM_MAX_NAME_LEN);

   /* Get the file name and path from the fsumplugin_file.cfg file. */
   configFile = fopen(configFileFullPathName, "rb");
   if (configFile == NULL)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
		                      "UMPlugin myConnect: cannot open file "FSUM_CONFIG_FILE_NAME"\n");

      /* Log the error message */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 
 
      /* Set the error return code */
      rc = FSUM_CONNECTION_ERROR;
      goto exit;
   }

   /* Calculate the size of the file name, including
      the full path. */
   fseek(configFile, 0L, SEEK_END);
   fileSize = ftell(configFile);

   /* Go back to beginning of the file. */
   fseek(configFile, 0L, SEEK_SET);

   /* Read the entire file into memory. */
   fread (umFileName, fileSize, 1, configFile);

   /* Check if an error occurred while handling file. */
   rc = ferror(configFile);
   if (rc != 0)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
		                      "UMPlugin myConnect: failed to read from fsumplugin_file.cfg");
 
      /* Log the error message. */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code. */
      rc = FSUM_CONNECTION_ERROR;
      goto exit;
   }

   /* Close the configuration file. */
   fclose(configFile);

   /* Set the null terminator. */
   umFileName[fileSize] = '\0';

   /* Open the user mapping file. */
   umFile = fopen ((char*)umFileName, "rb");
   if (umFile == NULL)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
		                      "UMPlugin myConnect: failed to open um repository file %s", umFileName);

      /* Log the error message. */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code. */
      rc = FSUM_CONNECTION_ERROR;
      goto exit;
   }

   /* Send the handle to the opened file to the caller. */
   *a_FSUMRepository = (void*)umFile;

exit:

   return rc;
}

/* Implementation of the FSUMfetchUM API. The plug-in must implement
this API. */
SQL_API_RC SQL_API_FN myFetchUM (void* a_FSUMRepository, 
                                 FSUMEntry* a_entry)
{
   SQL_API_RC rc = FSUM_PLUGIN_OK;
   SQL_API_RC utilRc = FSUM_PLUGIN_UTIL_OK;
   char errMsgBuffer[FSUM_MAX_ERROR_MSG_SIZE];
   size_t errMsgLen;
   char searchKey[FSUM_MAX_SEARCH_KEY_SIZE + 1];
   size_t searchKeySize = 0;
   size_t fileSize;
   size_t i;
   size_t j;

   void* buffer = NULL;
   char* startp;
   char* entryStartp;

   size_t optionChainSize = 0;
   char* optionChainStartp = NULL;
   char* optionStartp = NULL;
   size_t charCount = 0;

   char* optionName = NULL;
   size_t optionNameSize;
   char* optionValue = NULL;
   size_t optionValueSize;

   char* remotePassword = NULL;
   size_t remotePasswordSize = 0;

   int found = 0;
   int done = 0;
   int isRemotePasswordOption = 0;

   /* Get back the handle to the opened file. */
   FILE * fd = (FILE*) a_FSUMRepository;

   /* Calculate the file size. */
   fseek(fd, 0L, SEEK_END);
   fileSize = ftell(fd);
   
   /* Check for an error after calculating the file size. */
   rc = ferror(fd);
   if (rc != 0)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
		                      "UMPlugin myFetchUM: failed to get the size of file");

      /* Log the error message. */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code. */
      rc = FSUM_LOOKUP_ERROR;
      goto exit;        
   } 

   /* Allocate the buffer to hold the user mapping information. */
   utilRc = FSUMallocate(fileSize, &buffer);
   if (utilRc != FSUM_PLUGIN_UTIL_OK)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
		                      "UMPlugin myFetchUM: failed to allocate memory for %d bytes", fileSize);

      /* Log the error message. */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code. */
      rc = FSUM_LOOKUP_ERROR;
      goto exit;     
   }
   startp = (char*)buffer;

   /* Go back to the beginning of the file. */
   fseek(fd, 0L, SEEK_SET);

   /* Read the entire file into memory. */
   i = fread (startp, fileSize, 1, fd);

   /* Check for an error when handling the opened file. */
   rc = ferror(fd);
   if (rc != 0)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
		                      "UMPlugin myFetchUM: failed to read from file");
 
      /* Log the error message. */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code. */
      rc = FSUM_LOOKUP_ERROR;
      goto exit;        
   } 

   /* Construct the search key. */
   searchKeySize = a_entry->fsInstanceNameLen + sizeof (char) +
                   a_entry->fsDatabaseNameLen + sizeof (char) +
                   a_entry->fsServerNameLen   + sizeof (char) +
                   a_entry->fsAuthIDLen       + sizeof (char);

   /* SearchKeySize + 1 for the extra null terminator. */
   snprintf(searchKey, searchKeySize + 1, 
            "%s%c%s%c%s%c%s%c",
            a_entry->fsInstanceName,
            FSUM_IDENTIFIER_SEPARATOR,
            a_entry->fsDatabaseName,
            FSUM_IDENTIFIER_SEPARATOR,
            a_entry->fsServerName,
            FSUM_IDENTIFIER_SEPARATOR,
            a_entry->fsAuthID,
            FSUM_IDENTIFIER_SEPARATOR);

   /* Search the user mapping entries. */
   entryStartp = startp;
   charCount = 0;
   while (charCount < fileSize && !found)
   {
      /* Find the user mapping entry. */
      if(strncmp(entryStartp, searchKey, searchKeySize) == 0)
      {
         found = 1;
      }
      else
      {
         /* Move to the next entry. */
         for (i = charCount;
              (i <= fileSize) &&
              (strncmp(&startp[i], FSUM_UM_ENTRY_SEPARATOR, ENTRY_SEPARATOR_SIZE) != 0);
              i++);
         /* Plus 1 to skip the FSUM_UM_ENTRY_SEPARATOR */
         charCount = i + ENTRY_SEPARATOR_SIZE;
         if(charCount < fileSize)
         {
            entryStartp = &startp[charCount];
         }
	  }
   }
   if (found)
   {
      /* The option chain begins after the search key. */
      /*DB2INST1;GLOBALDB;ORA10G;NEWTON;REMOTE_AUTHID:J15USER1;REMOTE_PASSWORD:j15user1*/
      optionChainStartp = &entryStartp[searchKeySize];

      /* Calculate the length of the option chain. */
      optionChainSize = 0;
      for (optionChainSize = 0;
           charCount < fileSize &&
           (strncmp(&optionChainStartp[optionChainSize],
                    FSUM_UM_ENTRY_SEPARATOR,
                    ENTRY_SEPARATOR_SIZE) != 0);
           optionChainSize++, charCount++);

      /* Traverse the option chain. */
      optionNameSize = 0;
      optionValueSize = 0;
      j = 0;

      /* Start with the first option in the chain. */
      optionStartp = optionChainStartp;
      charCount = 0;

      /* Perform a check. */
      done = (charCount >= fileSize)?1:0;

      while (!done)
      {
         /* Get the size of the option name. */
         optionNameSize = 0;
         for (i = 0;
              (charCount++ <= optionChainSize) &&
               optionStartp[i] != FSUM_OPTION_NAME_VALUE_SEPARATOR &&
               (strncmp(&optionStartp[i], FSUM_UM_ENTRY_SEPARATOR, ENTRY_SEPARATOR_SIZE) != 0) &&
               optionStartp[i] != FSUM_IDENTIFIER_SEPARATOR; i++)
         {
            optionNameSize++;
         }

         /* Get the size of the option value. Do not include the FSUM_FSUM_OPTION_NAME_VALUE_SEPARATOR.*/
         optionValueSize = 0;
         for (i = optionNameSize + 1;
              (charCount++ <= optionChainSize) &&
               optionStartp[i] != FSUM_OPTION_NAME_VALUE_SEPARATOR &&
               (strncmp(&optionStartp[i], FSUM_UM_ENTRY_SEPARATOR, ENTRY_SEPARATOR_SIZE) != 0) &&
               optionStartp[i] != FSUM_IDENTIFIER_SEPARATOR; i++)
         {
            optionValueSize++;
         }

         /* Get the option name. */
         if (optionNameSize > 0)
         {
            /* Allocate the buffer to hold the option name. */
            utilRc = FSUMallocate(optionNameSize, &buffer);
            if (utilRc != FSUM_PLUGIN_UTIL_OK)
            {
               /* Construct the error message. */
               errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
                                "UMPlugin myFetchUM: failed to allocate memory of %d bytes for option name", optionNameSize);
 
               /* Log the error message. */
               FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

               /* Set the error return code. */
               rc = FSUM_LOOKUP_ERROR;
               goto exit;     
            }
            optionName = (char*)buffer;
            strncpy (optionName, optionStartp, optionNameSize);
            /* Check if the option name is REMOTE_PASSWORD. */
            if(strncmp(optionName, FSUM_REMOTE_PASSWORD_OPTION, optionNameSize) == 0)
            {
               isRemotePasswordOption = 1;
            }
            else
            {
               isRemotePasswordOption = 0;
            }
         }
         else
         {
            /* Option name is not valid. */
            optionName = NULL;
            optionNameSize = 0;
         }

         /* Get the option value. */
         if (optionValueSize > 0)
         {
            /* Allocate the buffer to hold the option value. */
            utilRc = FSUMallocate(optionValueSize, &buffer);
            if (utilRc != FSUM_PLUGIN_UTIL_OK)
            {
               /* Construct the error message. */
               errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
                                       "UMPlugin myFetchUM: failed to allocate memory of %d bytes for option value", optionValueSize);
 
               /* Log the error message. */
               FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

               /* Set the error return code. */
               rc = FSUM_LOOKUP_ERROR;
               goto exit;     
            }
            optionValue = (char*)buffer;
            /* Do not include the option name and the FSUM_FSUM_OPTION_NAME_VALUE_SEPARATOR. */
            strncpy (optionValue, &optionStartp[optionNameSize + 1], optionValueSize);
    
            /* If it is a password option, decrypt value of the option.*/
            if (isRemotePasswordOption)
            {
               remotePassword = NULL;
               /* Decrypt the password. */
               decryptPassword (optionValue, optionValueSize, &remotePassword, &remotePasswordSize);
               /* Free the password option value, and use the decrypted password.*/
               FSUMdeallocate(optionValue);
               optionValue = remotePassword;
               optionValueSize = remotePasswordSize;
               if (remotePassword == NULL)
               {
                  /* Construct the error message. */
                  errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
                                          "UMPlugin myFetchUM: decrypt password failed.");
 
                  /* Log the error message. */
                  FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

                  /* Set the error return code. */
                  rc = FSUM_LOOKUP_ERROR;
                  goto exit;
               } 
            } /* The option is REMOTE_PASSWORD. */
         } /* The option value is valid. */
         else
         {
            /* The option value is not valid. */
            optionValue = NULL;
            optionValueSize = 0;
         } /* If the option name is valid. */

         /* Determine if the option chain has been traversed. */
         if (charCount >= optionChainSize)
         {
            done = 1;
         }
         else /* Move to the next option. */
         {  /* Option chain looks like the following: */
            /* REMOTE_AUTHID:J15USER1;REMOTE_PASSWORD:1resu51j */
            optionStartp = &optionChainStartp[charCount];
         }

         /* Add the option to the user mapping entry. */
         if (optionName != NULL)
         {
            utilRc = FSUMaddUMOption(a_entry, optionName, optionNameSize, optionValue, optionValueSize);
            if (utilRc != FSUM_PLUGIN_UTIL_OK)
            {
               /* Construct the error message. */
               errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
                                       "UMPlugin myFetchUM: failed to add option %s", optionName);

               /* Log the error message. */
               FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 
 
               /* Set the error return code. */
               rc = FSUM_LOOKUP_ERROR;
               goto exit;     
            }	
            /* Free the storage for the option name and option value. */
            FSUMdeallocate(optionName);
            optionName = NULL;
            optionNameSize = 0;
            FSUMdeallocate(optionValue);
            optionValue = NULL;
            optionValueSize = 0;
         }
      } /* When not finished with the option chain. */
   } /* if found == 1 */
   else /* There is no matching entry. */
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
                           "UMPlugin myFetchUM: UM entry not found");
 
      /* Log the error message. */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code. */
      rc = FSUM_LOOKUP_ERROR;
      goto exit;     
   }
     
exit:
   
   if (optionName != NULL)
   {
     FSUMdeallocate(optionName);
   }

   if (optionValue != NULL)
   {
     FSUMdeallocate(optionValue);
   }

   return rc;
}

/* Implementation of the FSUMdisconnect API. The plug-in must implement this
   API. */
SQL_API_RC SQL_API_FN myDisconnect (void* a_FSUMRepository)
{
   SQL_API_RC rc = FSUM_PLUGIN_OK;
   char errMsgBuffer[FSUM_MAX_ERROR_MSG_SIZE];
   size_t errMsgLen;

   FILE *fd;
   
   /* Get back the handle to the repository (the opened file). */
   fd = (FILE *) a_FSUMRepository;

   /* Close the file */
   if (fclose (fd) != 0)
   {
      /* Construct the error message. */
      errMsgLen = snprintf(errMsgBuffer, sizeof(errMsgBuffer),
                              "UMPlugin myDisconnect: Failed to close file\n");

      /* Log the error message */
      FSUMlogErrorMsg (FSUM_LOG_ERROR, errMsgBuffer, errMsgLen); 

      /* Set the error return code */
      rc = FSUM_DISCONNECT_ERROR;
      goto exit;
   }
 
exit:

   return rc;
}

/* Implementation of the FSUMPluginTerm API. The plug-in must implement
   this API. */
SQL_API_RC SQL_API_FN myPluginTerm ()
{
   SQL_API_RC rc = FSUM_PLUGIN_OK;

   /**
    This function cleans up the global resources that the current thread
    in the db2fmp process allocates. This sample plug-in does not allocate
    any global resources; therefore, this sample does not use this function.
   **/
   return rc;

}

/* The plug-in initialization API function. You must use this name for this API. 
   Do not rename it. */
SQL_API_RC SQL_API_FN FSUMPluginInit(sqlint32 a_version, 
                                     FSUMPluginAPIs* a_pluginAPIs, 
                                     FSUMPluginUtilities* a_pluginUtils)
{
   SQL_API_RC rc = FSUM_PLUGIN_OK ;

   /* Pass the API function pointers to federated server */
   a_pluginAPIs->FSUMconnect = &myConnect;
   a_pluginAPIs->FSUMfetchUM = &myFetchUM;
   a_pluginAPIs->FSUMdisconnect = &myDisconnect;
   a_pluginAPIs->FSUMPluginTerm = &myPluginTerm;

   /* Get the function pointers for the utility functions */
   FSUMallocate = a_pluginUtils->allocate;
   FSUMdeallocate = a_pluginUtils->deallocate;
   FSUMlogErrorMsg = a_pluginUtils->logErrorMsg;
   FSUMaddUMOption = a_pluginUtils->addUMOption;
   
   /**
    If an error occurs, the plug-in must return error code
    rc = FSUM_INITIALIZE_ERROR. There are two additional optional ways
    to handle errors: Call FSUMlogErrorMsg to log the error, or
    use use a_errorMsg to send a message to federated server.
    (Set up a_errorMsgLen based on the size of a_errorMsg.)
   **/

   return rc;
}
