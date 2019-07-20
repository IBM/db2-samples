/******************************************************************************
**
** Source File Name: fsumpluginfile.h
**
** (C) COPYRIGHT International Business Machines Corp. Y1, Y2
** All Rights Reserved
** Licensed Materials - Property of IBM
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
** Function = header file for sample file based user mapping plugin
**
** Operating System: All
**
*******************************************************************************/
#ifndef FS_H_UM_PLUGIN_FILE_INCLUDED
#define FS_H_UM_PLUGIN_FILE_INCLUDED

#define FSUM_CONFIG_FILE_NAME             "fsumplugin_file.cfg" 
#define FSUM_IDENTIFIER_SEPARATOR         ';'
#define FSUM_OPTION_NAME_VALUE_SEPARATOR  ':'
#if defined ( _WIN32 )
#define FSUM_UM_ENTRY_SEPARATOR           "\r\n"
#else
#define FSUM_UM_ENTRY_SEPARATOR           "\n"
#endif
#define ENTRY_SEPARATOR_SIZE              sizeof(FSUM_UM_ENTRY_SEPARATOR) - 1

/* search key include FS instance name, database name, remote server name,
and local user name. So the max key size is 4 * FSUM_MAX_IDENTIFIER_SIZE
and 4 separator between these identifiers */
#define FSUM_MAX_SEARCH_KEY_SIZE (4 * FSUM_MAX_NAME_LEN + 4 * sizeof(char))

#endif /* FS_H_UM_PLUGIN_FILE_INCLUDED */
