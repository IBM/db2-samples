/* base64.c -- routines to encode/decode base64 data */
/* $OpenLDAP$ */
/* This work is part of OpenLDAP Software <http://www.openldap.org/>.
 *
 * Copyright 1998-2018 The OpenLDAP Foundation.
 * Portions Copyright 1998-2003 Kurt D. Zeilenga.
 * Portions Copyright 1995 IBM Corporation.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted only as authorized by the OpenLDAP
 * Public License.
 *
 * A copy of this license is available in the file LICENSE in the
 * top-level directory of the distribution or, alternatively, at
 * <http://www.OpenLDAP.org/license.html>.
 */
/* Portions Copyright (c) 1996, 1998 by Internet Software Consortium.
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND INTERNET SOFTWARE CONSORTIUM DISCLAIMS
 * ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL INTERNET SOFTWARE
 * CONSORTIUM BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL
 * DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR
 * PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 */
/* This work is based upon Base64 routines (developed by IBM) found
 * Berkeley Internet Name Daemon (BIND) as distributed by ISC.  They
 * were adapted for inclusion in OpenLDAP Software by Kurt D. Zeilenga.
 */

#include "base64.h"
#include <assert.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>



static const char Base64[] =
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char Pad64 = '=';

/*************************************************************************
*
*  Function Name     = base64_decode
*
*  Descriptive Name  = Base64 decoding function
*
*  Dependencies      =
*
*  Restrictions      =
*
*  Input             = in - input string to be decoded
*                      in_len - input string length
*                      out - Base64 decoded string(this variable must be freed 
*                            by a caller)
*
*  Output            =
*
*  Normal Return     = nonzero length of the decoded string
*
*  Error Return      = 0 as the length of the decoded string
*
***************************************************************************/
size_t base64_decode(const char *in, size_t in_len, unsigned char **out)
{
  size_t out_len = (in_len*3)/4;
  unsigned char *decoded = NULL;
  int bits_collected = 0;
  unsigned int accumulator = 0;
  size_t outpos = 0, i = 0;

  if( !out ) 
  { 
    return 0;
  }
  decoded = calloc(sizeof(char), out_len + 1);
  if( !decoded ) 
  {
    return 0;
  }

  for(i = 0, outpos = 0; i < in_len; ++i) 
  {
    const char c = in[i];
    if( c == '=' ) 
    {
      continue;
    }

    if ( c >= CODE_BOOK_SIZE || c < 0 || (reverse_table_url_safe[c] == -1) ) 
    {
      // invalid character, early exit 
      free(decoded);
      return 0;
    }
    // valid code book goes up to 6 bits 
    accumulator = (accumulator << 6) | reverse_table_url_safe[c];
    bits_collected += 6;
    if( bits_collected >= 8 ) 
    {
      bits_collected -= 8;
      decoded[outpos++] = (char)((accumulator >> bits_collected) & 0xffu);
    }
  }
  *out = decoded;
  return outpos;
}

