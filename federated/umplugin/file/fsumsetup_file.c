/******************************************************************************
**
** Source File Name: fsumsetupfile.c
**
** (C) COPYRIGHT International Business Machines Corp. Y1, Y2
** All Rights Reserved
** Licensed Materials - Property of IBM
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
** Function = sample setup program to set up the path and name of file
**
** Operating System: All
**
*******************************************************************************/
#include <stdio.h>
#include "fsumplugin.h"

/* read a line from the command line */
sqlint32 fsum_getline(char line[], int max)
{
  sqlint32 nch = 0;
  int c;
  max = max - 1;   /* leave room for '\0' */

   while((c = getchar()) != '\n')
   {
      if(nch < max)
      {
         line[nch] = (char)c;
      }
      nch = nch + 1;
   }

   if(nch >= max + 1)
   {
     printf("File name is too long\n");
     return EOF;
   }

   if(c == EOF || nch == 0)
   {
      printf("File name is invalid.\n"); 
      return EOF;
   }

   line[nch] = '\0';
   return nch;
}


/* read a line (path and file name info) from command line and store the 
 * information in the config file fsumpluginfile.cfg.  
 */
int main()
{
   char pluginFileName[FSUM_MAX_PATH_LEN + FSUM_MAX_NAME_LEN +1]; /* leave room for '\0' */
   const char configFileName[] = "fsumplugin_file.cfg";
   sqlint32 pluginFileNameLen = 0;
   FILE *fd = NULL;

   printf("Full path and name of file (UM repository): ");

   pluginFileNameLen = fsum_getline(pluginFileName, FSUM_MAX_PATH_LEN + FSUM_MAX_NAME_LEN +1);

   if (pluginFileNameLen == EOF)
   {
      /* invalid file name early exit */
      return 0;
   }

   /* open the config file for write */
   fd = fopen (configFileName, "wb");

   /* write the plugin full path information to the config file */
   fwrite(pluginFileName, sizeof(pluginFileName[0]), pluginFileNameLen, fd);

   /* close the file */
   fclose(fd); 

   return 0;
}
