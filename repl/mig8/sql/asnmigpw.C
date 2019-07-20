/*********************************************************************/
/*                                                                   */
/*     IBM DataPropagator                                            */
/*                                                                   */
/*     Sample ASNMIGPW program                                       */
/*                                                                   */
/*     Licensed Materials - Property of IBM                          */
/*                                                                   */
/*     (C) Copyright IBM Corp. 2003 All Rights Reserved              */
/*                                                                   */
/*     US Government Users Restricted Rights - Use, duplication      */
/*     or disclosure restricted by GSA ADP Schedule Contract         */
/*     with IBM Corp.                                                */
/*                                                                   */
/*********************************************************************/
/*     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                */
/*     PLEASE READ THE FOLLOWING BEFORE PROCEEDING...                */
/*     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!                */
/*********************************************************************/
/*                                                                   */
/*     This program migrates a version 7 Apply password file to a    */
/*     version 8 password file format. The command syntax is:        */
/*                                                                   */
/*     asnmigpw version-7-pwdfile version-8-pwdfile                  */
/*                                                                   */
/* Note: The password file for version 8 has to be created before    */
/*       using the asnpwd init command.                              */
/*                                                                   */
/*********************************************************************/
/*                                                                   */
/*           NOTICE TO USERS OF THE SOURCE CODE EXAMPLE              */
/*                                                                   */
/* INTERNATIONAL BUSINESS MACHINES CORPORATION PROVIDES THE SOURCE   */
/* CODE EXAMPLE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER         */
/* EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO THE IMPLIED   */
/* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR        */
/* PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE */
/* SOURCE CODE EXAMPLE IS WITH YOU. SHOULD ANY PART OF THE SOURCE    */
/* CODE EXAMPLE PROVES DEFECTIVE, YOU (AND NOT IBM) ASSUME THE       */
/* ENTIRE COST OF ALL NECESSARY SERVICING, REPAIR OR CORRECTION.     */
/*                                                                   */
/*********************************************************************/

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#define MAXLINE 255

char line[MAXLINE];
char token[MAXLINE];

static char *linePtr;

void toUpperStr (char* charPtr)
   {
   int ix;
   for (ix=0; charPtr[ix] != '\0'; ix++)
      {
      charPtr[ix] = toupper(charPtr[ix]);
      }
   }

void nextToken()
   {
   int c;
   char *tokenPtr = &token[0];
   c = (int) *linePtr;
   while (c && isspace(c))
      {
      *linePtr++;
      c = (int) *linePtr;
      }
   if (c)
      {
      if (isgraph(c))
         {
         while (c && isgraph(c))
            {
            *tokenPtr++ = *linePtr++;
            c = (int) *linePtr;
            }
         }
      else
         {
         *tokenPtr++ = *linePtr++;
         }
      }
   *tokenPtr = '\0';
   }

void nextReservedWord()
   {
   int c;
   char *tokenPtr = &token[0];
   c = (int) *linePtr;
   while (c && isspace(c))
      {
      *linePtr++;
      c = (int) *linePtr;
      }
   if (c)
      {
      if (isalnum(c))
         {
         while (c && isalnum(c))
            {
            *tokenPtr++ = *linePtr++;
            c = (int) *linePtr;
            }
         }
      else
         {
         *tokenPtr++ = *linePtr++;
         }
      }
   *tokenPtr = '\0';
   }


int getData(char *server, char *user, char *pwd)
   {
   short ix;
   for (ix=0 ; ix < 3 ; ix++)
      {
      nextReservedWord();
      toUpperStr(token);
      if (strcmp(token, "SERVER") == 0) {
         nextReservedWord();
         if (strcmp(token, "=") != 0) {
            printf("ASNMIGPWD: Invalid keywork: expecting '%s'\n", "=");
            return 1;
            }
         nextToken();
         strcpy(server, token);
         }
      else if (strcmp(token, "USER") == 0) {
         nextReservedWord();
         if (strcmp(token, "=") != 0) {
            printf("ASNMIGPWD: Invalid keywork: expecting '%s'\n", "=");
            return 2;
            }
         nextToken();
         strcpy(user, token);
         }
      else if (strcmp(token, "PWD") == 0) {
         nextReservedWord();
         if (strcmp(token, "=") != 0) {
            printf("ASNMIGPWD: Invalid keywork: expecting '%s'\n", "=");
            return 3;
            }
         nextToken();
         strcpy(pwd, token);
         }
      else {
         printf("ASNMIGPWD: Invalid keywork '%s' expecting %s\n", 
                token, "'SERVER', 'USER' or 'PWD'");
         return 4;
         }
      }
   return 0;
   }

int main(int argc, char *args[]) 
   {
   // This tool that is no longer required
   return 0;
   int len, rc;
   FILE *fp1;
   char f1[FILENAME_MAX];
   char server[9];
   char user[MAXLINE];
   char pwd[MAXLINE];
   char command[MAXLINE];
   char pwdfile[MAXLINE];
   if (argc < 2 && argc > 3)
      {
      printf("ASNMIGPW usage:\n");
      printf("asnmigp v7_pwd_file [v8_pwd_file]\n");
      }
   else
      {
      sprintf(f1, "%s", args[1]);
      if (argc == 3)
         strcpy(pwdfile, args[2]);
      else
         strcpy(pwdfile, "asnpwd.aut");
      if ((fp1 = fopen(f1, "r")) == NULL)
         printf("failure opening output file %s \n", f1);
      else
         {
         while (fgets(line, MAXLINE, fp1) != NULL)
            {
            strcpy(server, "");
            strcpy(user, "");
            strcpy(pwd, "");
            linePtr = &line[0];
            len = strlen(line);
            if (line[len-1] == '\n')      // Avoid new line in string
               line[len-1] = '\0';
            rc = getData(server, user, pwd);
            if (rc != 0)
               return rc;
            sprintf(command, 
                   "asnpwd add alias %s id %s password \"%s\" using %s ",
                   server,user,pwd, pwdfile);
            printf("%s\n",command);
            system(command);
            }
         }
      }
   return 0;
   }
