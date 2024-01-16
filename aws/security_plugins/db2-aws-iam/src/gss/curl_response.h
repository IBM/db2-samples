/**********************************************************************
*
*  IBM CONFIDENTIAL
*  OCO SOURCE MATERIALS
*
*  COPYRIGHT:  P#2 P#1
*              (C) COPYRIGHT IBM CORPORATION 2023, 2024
*
*  The source code for this program is not published or otherwise divested of
*  its trade secrets, irrespective of what has been deposited with the U.S.
*  Copyright Office.
*
*  Source File Name = src/gss/curl_response.h           (%W%)
*
*  Descriptive Name = Header file for curl related operations
*
*  Function:
*
*  Dependencies:
*
*  Restrictions:
*
***********************************************************************/

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
