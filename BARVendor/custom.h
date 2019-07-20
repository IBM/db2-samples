/* custom.h
 *
 * This is a sample C header file describing the XBSA.
 *
 * This appendix is not a normative part of the
 * specification and is provided for illustrative
 * purposes only.
 *
 * Implementations must ensure that the sizes of integer
 * datatypes match their names, not necessarily the typedefs
 * presented in this example.
 *
 */

#ifndef _BSA_CUSTOM_H_
#define _BSA_CUSTOM_H_


/* BSA_Boolean
 */
typedef char BSA_Boolean;

/* BSA_Int16
 */
typedef short BSA_Int16;

/* BSA_Int32
 */
typedef long BSA_Int32;


/* BSA_UInt16
 */
typedef unsigned short BSA_UInt16;

/* BSA_UInt32
 */
typedef unsigned long BSA_UInt32;

/* BSA_Int64
 */
typedef struct {    /* defined as two 32-bit integers */
    BSA_Int32   left;
    BSA_UInt32   right;
} BSA_Int64;

/* BSA_UInt64
 */
typedef struct {        /* defined as two unsigned 32-bit integers*/
    BSA_UInt32  left;
    BSA_UInt32  right;
} BSA_UInt64;

#define BSA_API_VERSION     1
#define BSA_API_RELEASE     1
#define BSA_API_LEVEL       1

/* Return Codes Used
 */
#define BSA_RC_OK                           0x00
#define BSA_RC_SUCCESS                      0x00

#endif
