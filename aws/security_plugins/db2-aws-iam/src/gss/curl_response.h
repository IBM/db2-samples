/****************************************************************************
** Licensed Materials - Property of IBM
**
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 2024
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
**
**********************************************************************************
**
**  Source File Name = src/gss/curl_response.h           (%W%)
**
**  Descriptive Name = Header file for curl related operations
**
**  Function:
**
*
*
*********************************************************************************/

#ifndef _CURL_RESPONSE_H_
#define _CURL_RESPONSE_H_
#include <stdlib.h>
#include <string.h>

struct write_buf {
  char *ptr; /* null terminated */
  size_t size; /* size excluding null */
};

static size_t write_callback(char *ptr, size_t size, 
    size_t nmemb, void *userdata)
{
  size_t bytes = size * nmemb;
  struct write_buf *buf = (struct write_buf *) userdata;

  buf->ptr = (char *) realloc(buf->ptr, buf->size + bytes + 1);
  if (!buf->ptr) {
    return 0;
  }

  memcpy(buf->ptr + buf->size, ptr, bytes);
  buf->size += bytes;
  buf->ptr[buf->size] = 0;

  return bytes;
}

static size_t no_output_callback(void *ptr, size_t size,
    size_t nmemb, void *userdata)
{
  return size * nmemb;
}

#endif
