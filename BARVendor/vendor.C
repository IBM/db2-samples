/****************************************************************************
** Licensed Materials - Property of IBM
** 
** Governed under the terms of the International
** License Agreement for Non-Warranted Sample Code.
**
** (C) COPYRIGHT International Business Machines Corp. 1995 - 2002
** All Rights Reserved.
**
** US Government Users Restricted Rights - Use, duplication or
** disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*****************************************************************************
**
** SOURCE FILE NAME: vendor.C
**
** SAMPLE: Implements the DB2 Backup/Restore Vendor APIs
**         using the XBSA Draft 0.8 level API
**
** FUNCTIONS USED:
**         sqluvint -  Initialization media vendor session
**         sqluvget -  Retrieve data from media vendor
**         sqluvput -  Sends data to media vendor
**         sqluvend -  End of media vendor session
**         sqluvdel -  Delete media vendor session data
**
*****************************************************************************
*
* For information on developing C++ applications, see the Application
* Development Guide.
*
* For more information on Backup & Restore APIs for Vendor Products, refer
* to Appendix D in the Administrative API Reference.
*
* For the latest information on programming, compiling, and running DB2 
* applications, visit the DB2 application development website: 
*     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "xbsa.h"


#ifndef WIN32
#include "unistd.h"
#endif

#include "sqlutil.h"
#include "sqluvend.h"
#include "sqluv.h"

// ----------------------------------------------------------------------------
// This is an internally used constant passed to bldObjName
// as backup type when we don't know what type of restore
// we are doing.
// ----------------------------------------------------------------------------
#define CREATE_OBJECT_INITIAL_SIZE  1000

#define SET_ERR_REASON( return_code, rc )                              \
{                                                                      \
   return_code->reserve = NULL;                                        \
   return_code->return_code = (sqlint32) rc;                           \
   sprintf(return_code->description, "%ld %ld", __LINE__, rc); \
}

// ----------------------------------------------------------------------------
// XBSA related data
// ----------------------------------------------------------------------------

typedef struct _xbsahandle
{
   BSA_UInt32            xbsaHandle;
   int                   status;
   ObjectDescriptor     *ObjectDescPtr;
   QueryDescriptor      *QueryDescPtr;
   char                 *ptr;
} DB2XBSAHANDLE;

// State Bits
#define INIT_DONE             0x01
#define READ_BEGUN            0x02
#define BACKUP                0x04
#define RESTORE               0x08

int  bldWriteObjDesc ( ObjectDescriptor  *,
                       QueryDescriptor   *,
                       DB2_info          *,
                       sqluint32             ,
                       sqluint32             );

int  bldReadObjDesc ( ObjectDescriptor  *,
                      QueryDescriptor   *,
                      DB2_info          *);

int  getLatestCopy ( QueryDescriptor  *,
                     ObjectDescriptor *,
                     sqluint32           *,
                     sqluint16);

void initBSAStructures( ObjectDescriptor  *objDesc,
                        QueryDescriptor   *qryDesc,
                        DB2_info          *db2_info);


#define   INIT_MAX_XBSA_OBJS 100
#ifndef WIN32
  #define PATH_SEP  '/'
  #define PATH_SEP_STR "/"
#else
  #define PATH_SEP '\\'
  #define PATH_SEP_STR "\\"
#endif

// ----------------------------------------------------------------------------
//
// SQLUVINT
//
// This function is where initialization and allocation of all the
// resources needed for the vendor media session are done. This includes
// such items as memory, devices, and programs/processes.  This sample
// allocates memory blocks and initializes the XBSA interface that is
// used as the storage mechanism.
//
// DB2 sends information through the 'Init_input' structure referenced
// here by the pointer 'in'.  Please see sqluvend.h for exact structure
// definitions and other defines. The Init_input structure holds the DB2
// information for the session in 'DB2_info', which includes DB2 UDB
// product version and levels ('DB2_id', 'version', 'release', and
// 'level') of the DB2 server. This structure also contains the
// following information:
//    A caller action  ('action') indicates what type of operation is to
//       occur for the session; 'SQLUV_WRITE' or 'SQLUV_READ'.
//    'filename' - The image name, represented in the following format
//        on UNIX <DBALIAS>.<type>.<instance>.<DB Partition #>.
//        <Catalog Partition#>.<timestamp>.<seq_no>  Filename is not
//        used by Backup, or restore, however, it is used to provide
//        recovery for a Load Copy image.
//     'server_id' - name of the DB2 UDB server starting this media
//        session.
//    'db2instance' - DB2 instance name of the database we are operating
//        on.
//    The 'type' for backup or restore: (defined in sqlutil.h and sqluv.h)
//
//       backup (SQLUV_WRITE) SQLUB_DB - full database backup
//                            SQLUB_FULL - full database backup
//                            SQLUB_TABLESPACE - table space level backup
//                            SQLUB_LOAD_COPY - Load Copy image
//                            SQLUB_INCREMENTAL - Incremental
//                            SQLUB_DELTA - Incremental Delta
//       restore (SQLUV_READ) SQLUD_DB - full database image
//                            SQLUD_FULL - full database backup
//                            SQLUD_ONLINE_TABLESPACE - online table space
//                            SQLUD_TABLESPACE - table space
//                            SQLUD_HISTORY - history file restore
//                            SQLUD_INCREMENTAL - restore of incremental image
//                            SQLUD_AUTOMATIC - automatic restore
//
//    This 'type'  is a an image action type and is sent as a bit mask
//    and should be separated out with SQLUB_TYPE_MASK and SQLUB_INCR_MASK
//    for backup and SQLUD_TYPE_MASK  SQLUD_INCR_MASK for restore.
//
//    'dbname' - database name we are performing backup/restore on.
//    'alias' - database alias we are performing backup/restore on.
//    'timestamp' of the backup being made or image to be recovered.
//    'sequence' number of backup image. This corresponds to the unique
//        number for the media session during backup/restore.
//        Range is (001,999) for backup.
//        Restore use of sequence is a little more intricate. For restore
//        the value of sequence will be zero since we don't know
//        yet what image sequences exist yet until we do a query for the
//        image objects. This function must return the number of sequences
//        or objects found for image in num_objects_in_backup (see
//        below describing 'Vendor_info') Subsequent calls by DB2
//        to sqluvget will provide a specific sequence number
//        as 'obj_num'. (see sqluvget).
//     'max_bytes_per_txn' The maximum number of bytes DB2 wants to use
//        for data transfer in a buffer.
//     'nodeNum' -  DB2 Database Partition on which the backup/restore
//        is happening.
//
//     The following input variables are for use by the vendor server
//     you are using, or have implemented, if one exists.  (A la TSM)
//     'nodename' - Name of physical node on which image is to be or was
//         generated from.
//     'password' for the above node.
//     'owner' or originator, a user id of who 'owns' the image.  The
//         user who invoked the operation.
//     'mcNameP' - Management Class
//
// Other input variables in Init_input are:
//    - the vendor options specified by the DB2 API caller. (size_options
//      contains the size of the data block being referenced by the
//      'options' pointer).
//    - Estimated database size  (size_HI_order, size_LOW_order) which
//      you may use in resource  pre-allocation if needed.
//    - Number of media sessions started by DB2 (num_sessions).
//
// For subsequent vendor calls DB2 needs information returned in the
// the structure 'Init_output' and referenced by pointer 'out'
// The following should be returned within the 'Init_output' structure:
//
//    pointer to 'Vendor_info' ('vendor_session') and pointer to
//    allocated memory for the vendor control block 'pVendorCB'.
//
//    Memory which these pointers reference must be allocated by you the
//    vendor. You are responsible for cleaning up and de-allocating this
//    memory when the session terminates. (abnormally, or not). This is
//    to be done in sqluvend.
//
//    'Vendor_info' contains :
//        - a string identifying the vendor, ('vendor_id')
//        - the current product info for the vendor - Can be used to
//          store the version of any interface you are using in turn to
//          store/retrieve data.  -e.g. XBSA release/level as in this
//          sample, or TSM API level ('version', 'release', 'level').
//        - Name that identifies database server ('server_id').
//        - Maximum bytes for transfer the vendor can support.
//          ('max_bytes_per_txn')
//        - Number of objects found for restore ('num_objects_in_backup').
//          This is the number of storage objects found by you that match
//          the information given about backup image.  (query made
//          up of 'dbname', 'nodeNum',  'timestamp', etc. from 'DB2_info'
//          Note: timestamp may be partial causing multiple matches on
//          a search. It is possible to find no match as well.
//          'nodeNum' here refers to the database partition number.)
//
//    The vendor control block is a structure defined by you. It's
//    purpose is to keep track of resources used between vendor calls.
//    In this example we have defined DB2XBSAHANDLE structure to keep
//    track of handles, descriptors and status needed for XBSA.
//
// DB2 also needs the return code information.  It is held in the
// 'Return_code' structure and is referenced by 'return_code' pointer.
// This must also be allocated in sqluvint. The contents of this
// structure are simply the integer variable 'return_code' and
// description string.  They are used return message strings to the user
// and for the db2diag.log.  The value of the return_code may be
// anything you wish to define, and may be a value returned from other
// functions or APIs.
//
// The sqluvint function itself must return a value when done processing.
// The values you may use are in defined in sqluvend.h.  The following are
// some of the defined error codes and what actions they produce in DB2:
//
// SQLUV_OK   Initialization OK - DB2 proceeds normally.
//
// Media Access Error Codes:
// SQLUV_LINK_EXIST, SQLUV_INIT_FAILED, SQLUV_DEV_ERROR,
// SQLUV_COMM_ERROR, SQLUV_COMMIT_FAILED, SQLUV_ABORT_FAILED,
// SQLUV_WARNING, SQLUV_LINK_NOT_EXIST, SQLUV_NO_DEV_AVAIL
//
// Api Error codes
// SQLUV_INV_VERSION, SQLUV_INV_ACTION, SQLUV_INV_USERID,
// SQLUV_INV_OPTIONS, SQLUV_INV_DEV_HANDLE, SQLUV_BUFF_SIZE,
// SQLUV_UNEXPECTED_ERROR, SQLUV_INV_PASSWORD
//
// For both Media Access Errors and Api Errors DB2 will fail
// initialization of this session and of the Media Controller process
// requesting the session.
//
// ----------------------------------------------------------------------------

int sqluvint ( struct Init_input   *in,
               struct Init_output  *out,
               struct Return_code  *return_code)
{
   ApiVersion           ApiVersion   = {0};
   int                  rc           = SQLUV_OK;
   BSA_Int16            xbsaRC       = BSA_RC_OK;
   int                  searchCount  = 0;
   DB2XBSAHANDLE       *handle       = NULL;
   Vendor_info         *VendorInfo   = NULL;
   SecurityToken       *secTokenPtr  = NULL;
   char                *cptr         = NULL;
   DataBlock            dataBlk      = {0};
   sqluint32            type         = 0;
   sqluint32            incr         = 0;
   sqluint16            DBPartitionNum  = 0;
   int                  uniqueBackup = 0;
   char                *tptr         = NULL;
   int                  timestampLen = SQLU_TIME_STAMP_LEN;
   char                 timestamp[SQLU_TIME_STAMP_LEN+1] = {0};



   // Allocate space to keep track BSA information (DB2XBSAHANDLE)
   // This will eventually be returned as the Vendor Control Block (pVendorCB)
   // -------------------------------------------------------------------------
   handle = (DB2XBSAHANDLE *) malloc ( sizeof (DB2XBSAHANDLE) );
   if (handle == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno );
      goto exit;
   }
   memset ( handle, 0x00, sizeof (DB2XBSAHANDLE));

   secTokenPtr = (SecurityToken*)malloc(BSA_MAX_TOKEN_SIZE);
   if (secTokenPtr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno );
      goto exit;
   }
   memset(secTokenPtr, 0x00, BSA_MAX_TOKEN_SIZE);

   handle->ObjectDescPtr = (ObjectDescriptor*)malloc(sizeof(ObjectDescriptor));
   if (handle->ObjectDescPtr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno );
      goto exit;
   }
   memset(handle->ObjectDescPtr, 0x00, sizeof(ObjectDescriptor));

   handle->QueryDescPtr = (QueryDescriptor*)malloc(sizeof(QueryDescriptor));
   if (handle->QueryDescPtr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno );
      goto exit;
   }
   memset(handle->QueryDescPtr, 0x00, sizeof(QueryDescriptor));

   if ((*(in->DB2_session->action) != SQLUV_WRITE) &&
       (*(in->DB2_session->action) != SQLUV_READ))
   {
      rc = SQLUV_INV_ACTION;
      SET_ERR_REASON(return_code, 0 );
      goto exit;
   }

   // The backup type and possibly incremental info are both sent
   // as bit masks in the 'type' field.  Separate them out for use here.
   // -------------------------------------------------------------------------
   type = incr = strtoul(in->DB2_session->type, NULL, 16);
   type &= SQLUB_TYPE_MASK;
   incr &= SQLUB_INCR_MASK;


   BSAQueryApiVersion(&ApiVersion);


   handle->ObjectDescPtr->objName.objectSpaceName[0] = '\0';
   handle->ObjectDescPtr->objName.pathName[0] = '\0';
   handle->ObjectDescPtr->status = BSAObjectStatus_ACTIVE;

   //
   // Initialize the BSA structures
   // -------------------------------------------------------------------------
   initBSAStructures(handle->ObjectDescPtr, handle->QueryDescPtr, in->DB2_session);

   // Start XBSA session.
   // -------------------------------------------------------------------------
   xbsaRC = BSAInit(&handle->xbsaHandle,            /* Will contain session handle on return. */
                    secTokenPtr,                    /* password */
                    &handle->ObjectDescPtr->Owner,  /* Node name and Owner name */
                    NULL);

   if (xbsaRC != BSA_RC_SUCCESS)
   {
      SET_ERR_REASON(return_code, xbsaRC );
      rc = SQLUV_INIT_FAILED;
      goto exit;
   }

   // To begin an XBSA transaction.
   // -------------------------------------------------------------------------
   xbsaRC = BSABeginTxn ( handle->xbsaHandle );
   if ( xbsaRC != BSA_RC_SUCCESS)
   {
      SET_ERR_REASON(return_code, xbsaRC );
      rc = SQLUV_INIT_FAILED;
      goto exit;
   }

   // -------------------------------------------------------------------------
   // If BACKUP do the following.
   // -------------------------------------------------------------------------
   if (*(in->DB2_session->action) == SQLUV_WRITE)
   {
      char *SendBuffer;

      // Build the object name
      //
      // On restore do not set the type for the object and query
      // descriptor or we will not be able to restore a table space from
      // a full DB image
      // ----------------------------------------------------------------------
      rc = bldWriteObjDesc(handle->ObjectDescPtr,
                           handle->QueryDescPtr,
                           in->DB2_session,
                           type, incr);
      if (((in->size_HI_order == 0) && (in->size_LOW_order == 0))                                                         )
      {
         in->size_HI_order = 0;
         in->size_LOW_order = SQL_MAXRECL_4K * CREATE_OBJECT_INITIAL_SIZE;
      }
      handle->ObjectDescPtr->size.left = in->size_HI_order;
      handle->ObjectDescPtr->size.right = in->size_LOW_order;

      // Must have a buffer allocated to create an object
      // A size of CREATE_OBJECT_INITIAL_SIZE is being used,
      // this is an arbitrary value
      // ----------------------------------------------------------------------
      SendBuffer = (char *)malloc(CREATE_OBJECT_INITIAL_SIZE);
      if (SendBuffer == NULL)
      {
         rc = SQLUV_INIT_FAILED;
         SET_ERR_REASON(return_code, errno );
         goto exit;
      }
      memset(SendBuffer,0x00,CREATE_OBJECT_INITIAL_SIZE);
      dataBlk.bufferLen = CREATE_OBJECT_INITIAL_SIZE;
      dataBlk.numBytes  = 0;
      dataBlk.bufferPtr = SendBuffer;

      // Create the object
      // ----------------------------------------------------------------------
      xbsaRC = BSACreateObject( handle->xbsaHandle,       /* BSA session Handle */
                                handle->ObjectDescPtr,
                               &dataBlk);
      if ( xbsaRC != BSA_RC_SUCCESS)
      {
         SET_ERR_REASON(return_code, xbsaRC );
         rc = SQLUV_INIT_FAILED;
         free(SendBuffer);
         goto exit;
      }

      free(SendBuffer);
      handle->status = INIT_DONE | BACKUP;

   } // Backup init ends.

   // -------------------------------------------------------------------------
   // If RESTORE do the following.
   // -------------------------------------------------------------------------
   else if (*(in->DB2_session->action) == SQLUV_READ)
   {
      // Build the object name
      //
      // On restore do not set the type for the object and query descriptor or
      // we will not be able to restore a table space from a full DB image
      // ----------------------------------------------------------------------
      rc = bldReadObjDesc(handle->ObjectDescPtr,
                           handle->QueryDescPtr,
                           in->DB2_session);

      // If timestamp is not provided, assume restoring from latest backup.
      // ----------------------------------------------------------------------
      if ((in->DB2_session->timestamp    == NULL) ||
          (in->DB2_session->timestamp[0] == '\0'))
      {
         // Do query to match the backup image.
         // After calling this function and rc > 0, the objName in QueryDesc
         // contains the full objName except the seq_no.
         // -------------------------------------------------------------------
         rc = getLatestCopy (handle->QueryDescPtr,
                             handle->ObjectDescPtr,
                            &handle->xbsaHandle,
                             in->DB2_session->nodeNum );
         if (rc != 0)
         {
            SET_ERR_REASON(return_code, rc);
            goto exit;
         }
         handle->QueryDescPtr->objName = handle->ObjectDescPtr->objName;
      }

      // At this point, QueryDesc contains timestamp.
      // ----------------------------------------------------------------------
      xbsaRC = BSAQueryObject ( handle->xbsaHandle, handle->QueryDescPtr, 
                                handle->ObjectDescPtr);
      if (   (xbsaRC != BSA_RC_SUCCESS)
          && (xbsaRC != BSA_RC_NO_MORE_DATA)
          && (xbsaRC != BSA_RC_MORE_DATA))
      {
         SET_ERR_REASON(return_code, xbsaRC );
         rc = SQLUV_OBJ_NOT_FOUND;
         goto exit;
      }

      while (   (xbsaRC == BSA_RC_MORE_DATA)
             || (xbsaRC == BSA_RC_NO_MORE_DATA)
             || ( xbsaRC == BSA_RC_SUCCESS))
      {

         // Ensure we are looking for data for this DB partition number only
         // -------------------------------------------------------------------
         tptr = strrchr(handle->ObjectDescPtr->objName.objectSpaceName,
                        PATH_SEP);
         if (tptr == NULL)
            tptr = handle->ObjectDescPtr->objName.objectSpaceName;
         else
            tptr+=strlen("/NODE");

         DBPartitionNum = (sqluint16)atoi(tptr);
         if (in->DB2_session->nodeNum == DBPartitionNum)
         {
            // Check the sequence number.  If it's a 1, then this is
            //       a new backup image.  If it's not a 1, then it's
            //       just part of a backup we've already counted.
            // ----------------------------------------------------------------
            int stringLen = strlen(handle->ObjectDescPtr->objName.pathName);
           if ((handle->ObjectDescPtr->objName.pathName[stringLen-2] == '.') &&
               (handle->ObjectDescPtr->objName.pathName[stringLen-1] == '1'))
               uniqueBackup++;

            searchCount++;
         }

         //
         // Just processes the last item
         // -------------------------------------------------------------------
         if (xbsaRC == BSA_RC_NO_MORE_DATA)
           break;

         xbsaRC = BSAGetNextQueryObject (handle->xbsaHandle,
                                         handle->ObjectDescPtr);
         if (xbsaRC == BSA_RC_NO_MATCH)
           break;
      }

      //
      // No BSA object match found on server for backup image given
      // ----------------------------------------------------------------------
      if (searchCount == 0)
      {
         rc = SQLUV_OBJ_NOT_FOUND;
         SET_ERR_REASON(return_code, rc );
         goto exit;
      }

      // Error occured other than no match or no more data
      // ----------------------------------------------------------------------
      if ((xbsaRC != BSA_RC_NO_MATCH) && (xbsaRC != BSA_RC_NO_MORE_DATA))
      {
         SET_ERR_REASON(return_code, rc );
         rc = SQLUV_DEV_ERROR;
         goto exit;
      }

      // If we have reached this point we have initialized BSA successfully and
      // got at least one image match.
      // ----------------------------------------------------------------------
      rc = SQLUV_OK;

      // If one than more match found, then notify DB2 as this is an error
      // condition will cause an error message to be returned to the DB2 user.
      // ----------------------------------------------------------------------
      if (uniqueBackup > 1)
      {
         SET_ERR_REASON(return_code, rc );
         rc = SQLUV_OBJS_FOUND;
         goto exit;
      }

      // Update our internal status flag for this session
      // ----------------------------------------------------------------------
      handle->status = INIT_DONE | RESTORE;

   }  // Restore init ends.

success: // Construct return structure.

   // Allocate space for the Vendor information block for output pointer
   // vendor_session
   // -------------------------------------------------------------------------
   handle->ptr = (char *) malloc (sizeof(Return_code)+sizeof(Vendor_info));
   if (handle->ptr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno );
      goto exit;
   }
   memset(handle->ptr, 0x00, sizeof(Return_code)+sizeof(Vendor_info));
   cptr = handle->ptr ;

   // Fill in vendor information for BSA vendor session
   // -------------------------------------------------------------------------

   // Vendor Id.
   VendorInfo = out->vendor_session = (Vendor_info *) cptr;
   cptr += sizeof (Vendor_info);

   out->vendor_session->vendor_id = "XBSA";

   // Version.
   sprintf(cptr, "%d", ApiVersion.version);
   out->vendor_session->version = cptr;
   cptr += strlen(cptr);              // point to next available position.

   // Release.
   sprintf(cptr, "%d", ApiVersion.release);
   out->vendor_session->release = cptr;
   cptr += strlen(cptr);              // point to next available position.

   // Level
   sprintf(cptr, "%d", ApiVersion.level);
   out->vendor_session->level = cptr;
   cptr += strlen(cptr);              // point to next available position.

   // Reserve
   out->vendor_session->reserve = NULL;

   // Device Handle.
   // Return the BSA handle as the vendor control block
   // -------------------------------------------------------------------------
   out->pVendorCB = (void *)handle;

   // Reserve
   out->reserve = NULL;

   // Matches found for image object criteria
   // -------------------------------------------------------------------------
   out->vendor_session->num_objects_in_backup = searchCount;

// Error exit
// ----------------------------------------------------------------------------
exit:
   if (secTokenPtr != NULL)
      free(secTokenPtr);

   // Free all memory and terminate BSA session (if started) if an error was
   // encountered.
   // -------------------------------------------------------------------------
   if ((handle != NULL) && !(handle->status & INIT_DONE))
   {
      if (handle->xbsaHandle != 0)
         BSATerminate (handle->xbsaHandle);
      if (handle->ptr)
      {
         free(handle->ptr);
         handle->ptr = NULL;
      }
      if (handle->QueryDescPtr)
      {
         free(handle->QueryDescPtr);
         handle->QueryDescPtr = NULL;
      }
      if (handle->ObjectDescPtr)
      {
         free(handle->ObjectDescPtr);
         handle->ObjectDescPtr = NULL;
      }
      free (handle);
      handle = NULL;
   }
   return(rc);

}


// ----------------------------------------------------------------------------
//
// SQLUVGET
//
// This function is called by DB2 once a session has been successfully
// initialized to get or retrieve data from storage. DB2 will send you
// a handle ('hdle'), which is actually a pointer to the vendor control
// block that was described and setup in sqluvint.
//
// The pointer 'data' to the 'Data' structure is for input and output.
//    On restore the 'Data' structure indicates which object or sequence
//    is to be read. ('obj_num'). (Range is 0 to 998 so must add one to
//    get actual sequence number.)
//   'buff_size' contains the buffer's size, that is, how much data DB2
//       wants sqluvget to try to retrieve at once. DO NOT attempt to
//       return more to DB2 than what this indicates, as it will overflow
//       the allocated memory space.
//   'actual_buff_size' is an output field and is the actual bytes read
//       by you, the vendor.
//   'dataptr' is the pointer to the data buffer. It is pre-allocated
//       and managed by DB2. This is where you put the data you read
//       from storage. Be careful not to write outside the allocated
//       space! (specified by 'buff_size').
//
// The return code info is returned by a pointer 'return_code' to the
// 'Return_code' structure (see sqluvint).
// Function return values are in sqluvend.h.  Ensure you return the correct
// value for the situation.
//
// SQLUV_OK  - DB2 continues,  expects more data so calls sqluvget again.
// SQLUV_MORE_DATA - Same as SQLUV_OK.
//
// SQLUV_ENDOFMEDIA_NO_DATA  - Reached end of media didn't read any data.
// SQLUV_ENDOFMEDIA -  Reached end of media while reading data.
//
// Depending on what stage DB2 is in, the above two values may or may not
// result in a successful operation. For example, during a read media
// header operation, if we return SQLUV_ENDOFMEDIA and the amount of data
// read doesn't equal the defined media header size, then the DB2
// restore will fail. If it is of equal size the operation is OK because
// it is possible to have an image with just a media header. If this is
// a regular call to sqluvget then both of these return codes will prompt
// DB2 to call sqluvend to end the session normally.
//
// SQLUV_WARNING - DB2 will call sqluvend to end the session with vote
//                 set to  SQLUV_COMMIT.
// Any other error - DB2 will call sqluvend with vote set to SQLUV_TERMINATE
//                   to indicate we need close down the session as
//                   quickly as possible.
// ----------------------------------------------------------------------------
int sqluvget ( void               *hdle,
               struct Data        *data,
               struct Return_code *return_code)
{
   int             rc            = SQLUV_OK;
   BSA_Int16       xbsaRC        = BSA_RC_OK;
   DataBlock       dataBlk       = {0};
   DB2XBSAHANDLE  *handle        = (DB2XBSAHANDLE *)hdle;
   int             bytestoread   = 0;
   char           *workptr       = (char *)data->dataptr;
   int            sequenceNum    = 0;
   char           *ptr           = NULL;

   if ( !(handle->status & RESTORE) )
   {
      rc = SQLUV_INV_ACTION;
      SET_ERR_REASON(return_code, 0 );
      goto exit;
   }

   // Reset the sequence number at the end of the object descriptor
   // -------------------------------------------------------------------------
   sequenceNum = data->obj_num+1;

   ptr = strrchr(handle->ObjectDescPtr->objName.pathName,'.');
   if (ptr != NULL)
     sprintf(ptr, ".%d", sequenceNum);

   handle->QueryDescPtr->objName = handle->ObjectDescPtr->objName;
   if ( !( handle->status & READ_BEGUN ))
   {
      // First query the object so that the ObjectDescPtr structure is set
      // correctly
      // ----------------------------------------------------------------------
      xbsaRC = BSAQueryObject ( handle->xbsaHandle, handle->QueryDescPtr,
                                handle->ObjectDescPtr);
      if (   (xbsaRC != BSA_RC_SUCCESS)
          && (xbsaRC != BSA_RC_NO_MORE_DATA)
          && (xbsaRC != BSA_RC_MORE_DATA))
      {
         SET_ERR_REASON(return_code, xbsaRC );
         rc = SQLUV_OBJ_NOT_FOUND;
         goto exit;
      }

      handle->status |= READ_BEGUN;

      dataBlk.bufferPtr = (char *)data->dataptr;
      dataBlk.bufferLen = data->buff_size;  // data size expect.
      dataBlk.numBytes = data->buff_size;
      xbsaRC = BSAGetObject ( handle->xbsaHandle, handle->ObjectDescPtr,
                             &dataBlk);
      data->actual_buff_size = dataBlk.numBytes;

      if (xbsaRC == BSA_RC_MORE_DATA)
      {
         data->actual_buff_size = 0;
         bytestoread= data->buff_size;
         dataBlk.bufferLen = data->buff_size;
         dataBlk.bufferPtr = (char *)data->dataptr;
         xbsaRC = BSAGetData ( handle->xbsaHandle, &dataBlk );

         data->actual_buff_size += dataBlk.numBytes;

         SET_ERR_REASON(return_code, xbsaRC );

         if (xbsaRC == BSA_RC_MORE_DATA)
         {
            rc = SQLUV_MORE_DATA;
            goto exit;
         }
      }

      if ( xbsaRC != BSA_RC_SUCCESS)
      {
         SET_ERR_REASON(return_code, xbsaRC );
         if (xbsaRC == BSA_RC_NO_MATCH)
            // Notify DB2 if we could not find a match to the image on the
            // server. An error message indicating such will be returned
            // to the DB2 user.
            // ----------------------------------------------------------------
             rc = SQLUV_OBJ_NOT_FOUND;
         else
             rc = SQLUV_IO_ERROR;
         goto exit;
      }
   }
   else      // if not first get.
   {
         data->actual_buff_size = 0;
         dataBlk.bufferLen = data->buff_size;
         dataBlk.bufferPtr = (char *)data->dataptr;

         bytestoread = data->buff_size;
         workptr = (char *)data->dataptr;
         //
         // Split up the large buffer to fit into the 16 bit interface
         // (XBSA API  Draft 0.8 restriction/limitation)
         // -------------------------------------------------------------------
         do
         {
            if (bytestoread >= USHRT_MAX)
               dataBlk.bufferLen= USHRT_MAX - 16;
            else
               dataBlk.bufferLen=bytestoread;

            dataBlk.bufferPtr = workptr;
            dataBlk.numBytes  = dataBlk.bufferLen;
            xbsaRC = BSAGetData ( handle->xbsaHandle, &dataBlk );
            data->actual_buff_size += dataBlk.numBytes;

            SET_ERR_REASON(return_code, xbsaRC );

            if (xbsaRC == BSA_RC_MORE_DATA)
               rc = SQLUV_MORE_DATA;
            else if (xbsaRC != BSA_RC_NO_MORE_DATA)
            {
               rc = SQLUV_IO_ERROR;
               goto exit;
            }

            workptr     += dataBlk.numBytes;
            bytestoread -= dataBlk.numBytes;

         } while (bytestoread > 0 && rc == SQLUV_MORE_DATA);
   }
   if (xbsaRC == BSA_RC_NO_MORE_DATA)
   {
     rc = SQLUV_ENDOFMEDIA;
   }
   SET_ERR_REASON(return_code, xbsaRC );

exit:

  return(rc);

} // sqluvget()


// ----------------------------------------------------------------------------
//
// SQLUVPUT
//
// Once a session has been successfully initialized this function is called
// by DB2 to put or write data to storage.
// DB2 will send you a handle ('hdle'),  which is actually a pointer the
// vendor control block, that is setup and initialized in sqluvint.
//
// The pointer 'data' to the 'Data' structure is for input and output.
//    'buff_size' contains the buffers size that is being used, that is
//        how much data DB2 wants sqluvput to try to write.
//    'actual_buff_size' is an output field and is the actual bytes
//        written, or processed by sqluvput. If this field ends up being
//        less than buff_size,  then do not return SQLUV_OK,  unless it is
//        OK to lose the remaining data in the buffer. Return another value
//        that indicates an error. This will result in the buffer being put
//        back on DB2's buffer queue for another session (if it exists)
//        to process. If is possible to redo this buffer in it's entirety,
//        then ask DB2 to re-send the buffer.
//
//     'dataptr' is an input pointer to the data (DB2 data buffer) to
//        process.
//
// The return code info is returned by a pointer 'return_code' to struct
// 'Return_code' (see sqluvint)
//
// Function return values are in sqluvend.h.
// The next actions of DB2 may differ depending on what is value is returned
// here.
// Returning SQLUV_OK - DB2 will continue, as long as there is more buffers
//              to send. If not, it will begin normal vendor session
//              termination.
//           SQLUV_ENDOFMEDIA - This indicates to DB2 that there was a
//              normal end of storage on the media. The data that has been
//              already written will be treated as committed to storage, and
//              DB2 will end this vendor session by calling sqluvend with
//              the SQLUV_COMMIT flag. See sqluvend for further info.
//           SQLUV_END_OF_TAPE - Tells DB2 that there is not enough storage
//              space to write this buffer out completely. This could be
//              detected while a portion of the buffer has been written.
//              DB2 will call sqluvend with SQLUV_TERMINATE flag.
//              See sqluvend for further info.
//           SQLUV_NO_DEV_AVAIL - Media Access error - DB2 will terminate
//              or abort the session and fail the backup.
//           SQLUV_DATA_RESEND will cause DB2 to re-send the same buffer
//              from it's start on the next sqluvput call. This will only
//              be done once, the second time SQLUV_DATA_RESEND is returned
//              it will treated as an error.
// ----------------------------------------------------------------------------
int sqluvput ( void *              hdle,
               struct Data        *data,
               struct Return_code *return_code)
{
   DataBlock      dataBlk        = {0};
   DB2XBSAHANDLE *handle         = (DB2XBSAHANDLE *)hdle;
   int            rc             = SQLUV_OK;
   BSA_Int16      xbsaRC         = BSA_RC_OK;
   int            byteswritten   = 0;
   int            bytestowrite   = 0;
   char          *workpointer    = (char *)data->dataptr;

   if ( !(handle->status & BACKUP) )
   {
      rc = SQLUV_INV_ACTION;
      SET_ERR_REASON(return_code, 0 );
      goto exit;
   }

   bytestowrite = data->buff_size;

   // split up the data to fit into the 16 bit interface
   // (Limitation of the XBSA Draft 0.8 level API)
   // -------------------------------------------------------------------------
   while (bytestowrite > 0)
   {
      if (bytestowrite >= USHRT_MAX)
         dataBlk.bufferLen = USHRT_MAX - 16;
      else
         dataBlk.bufferLen = bytestowrite;

      dataBlk.bufferPtr = workpointer;
      dataBlk.numBytes  = dataBlk.bufferLen;
      bytestowrite     -= dataBlk.bufferLen;

      xbsaRC = BSASendData ( handle->xbsaHandle, &dataBlk);
      if (xbsaRC != BSA_RC_SUCCESS)
      {
         SET_ERR_REASON(return_code, xbsaRC );
         rc = SQLUV_IO_ERROR;
         goto exit;
      }
      else
      { // End of tape check
         if (dataBlk.numBytes == 0)
         {
            rc = SQLUV_END_OF_TAPE;
            SET_ERR_REASON(return_code, rc );
            goto exit;
         }
      }

      byteswritten   += dataBlk.numBytes;
      workpointer    += dataBlk.numBytes;
   }
   dataBlk.numBytes = byteswritten;

exit:

  // actual number of bytes written.
  // --------------------------------------------------------------------------
  data->actual_buff_size = byteswritten;
  return(rc);
}


// ----------------------------------------------------------------------------
//
//  SQLUVEND
//
//  This function cleans up all resources for a media session.  It will be
//  called for both successful and unsuccessful termination.
//  'action'  indicates whether the data was compeletly processed by this
//     session, or whether a problem occurred.
//  'hdle'  handle or pointer to vendor control block for the session (input)
//  'in_out'  pointer to structure 'Init_output'
//        'vendor_session' pointer to struct Vendor_info (input)
//        'pVendorCB'  pointer to vendor control block  (input)
//  'return_code' pointer to 'Return_code' structure  (output)
//
//  Release all memory allocated during initialization if completed
//  successfully and call cleanup API's or functions.
// ----------------------------------------------------------------------------
int sqluvend ( sqlint32             action,
               void                *hdle,
               struct Init_output  *in_out,
               struct Return_code  *return_code)
{
   int            rc           = SQLUV_OK;
   BSA_Int16      xbsaRC       = BSA_RC_OK;
   Vote           vote         = BSAVote_COMMIT;
   sqluint16      rc_reason    = {0x00};
   DB2XBSAHANDLE *handle       = (DB2XBSAHANDLE * ) hdle;

   if (handle==NULL) // init failed
      goto exit;

   if (handle->status & INIT_DONE)
   {

      xbsaRC = BSAEndData ( handle ->xbsaHandle );
      if ( xbsaRC != BSA_RC_SUCCESS)
      {
         rc = SQLUV_DEV_ERROR;
         action = SQLUV_ABORT;
      }

      if ((action == SQLUV_COMMIT) ||
         (action == SQLUV_TERMINATE))
         vote = BSAVote_COMMIT;
      else
         vote = BSAVote_ABORT;

      xbsaRC = BSAEndTxn ( handle->xbsaHandle, vote);
      if ( xbsaRC != BSA_RC_SUCCESS)
      {
         rc = SQLUV_DEV_ERROR;
      }
   }

   BSATerminate (handle->xbsaHandle);

   // free allocated memory.
   if (handle->ptr != NULL)
   {
      free(handle->ptr);
      handle->ptr = NULL;
   }

   if (handle->ObjectDescPtr != NULL)
   {
      free(handle->ObjectDescPtr);
      handle->ObjectDescPtr = NULL;
   }

   if (handle->QueryDescPtr != NULL)
   {
      free(handle->QueryDescPtr);
      handle->QueryDescPtr = NULL;
   }

   free(handle);
   handle = NULL;

exit:

   // SQLUV_TERMINATE indicates that we had to terminate to obtain the
   // failing reasoncode, to not reset it.
   // -------------------------------------------------------------------------
   if (action != SQLUV_TERMINATE)
      SET_ERR_REASON(return_code, rc);

   return(rc);
}


// ----------------------------------------------------------------------------
//
// SQLUVDEL
//
// This function will be invoked by DB2 when a backup fails after all
// sessions have ended. It is not a good idea to leave an incomplete
// backup image around.
//
// This function should create it's own session, and so, must initialize
// any resources to be used. See sqluvint for description of input/output
// parameters.
// ----------------------------------------------------------------------------
int sqluvdel ( Init_input   * in,
               Init_output  * vendorDevData,
               Return_code  * return_code)
{
   ApiVersion         ApiVersion                  = {0x00};
   ObjectName         objName                     = {0x00};
   int                fileCount                   = 0;
   BSA_UInt32         xbsaHandle                  = 0;
   SecurityToken      tokenPtr                    = {0x00};
   ObjectDescriptor  *ObjectDescPtr               = NULL;
   QueryDescriptor   *QueryDescPtr                = NULL;
   int                rc                          = SQLUV_OK;
   BSA_Int16          xbsaRC                      = BSA_RC_OK;
   int                ix                          = 0;
   int                currentMaxObjsAllocate      = INIT_MAX_XBSA_OBJS;

   SQLUV_BMH *mediaHeader = (SQLUV_BMH *)vendorDevData->vendor_session->reserve;

   typedef struct objectIdent
   {
      ObjectName      objName;
      CopyType        copyType;
      CopyId          copyID;
   } OBJECT_IDENT;
   OBJECT_IDENT      *fileListPtr = NULL;


   fileListPtr = (OBJECT_IDENT*)malloc(sizeof(OBJECT_IDENT)*currentMaxObjsAllocate);
   if (fileListPtr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno);
      goto exit;
   }
   memset(fileListPtr, 0x00, (sizeof(OBJECT_IDENT)*currentMaxObjsAllocate));


   ObjectDescPtr = (ObjectDescriptor*)malloc(sizeof(ObjectDescriptor));
   if (ObjectDescPtr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno);
      goto exit;
   }
   memset(ObjectDescPtr, 0x00, sizeof(ObjectDescriptor));

   QueryDescPtr = (QueryDescriptor*)malloc(sizeof(QueryDescriptor));
   if (QueryDescPtr == NULL)
   {
      rc = SQLUV_INIT_FAILED;
      SET_ERR_REASON(return_code, errno);
      goto exit;
   }
   memset(QueryDescPtr, 0x00, sizeof(QueryDescriptor));

   ObjectDescPtr->version       = ObjectDescriptorVersion;
   strcpy(ObjectDescPtr->Owner.bsaObjectOwner, "DB2");
   ObjectDescPtr->Owner.appObjectOwner[0] = '\0';
   ObjectDescPtr->copyType      = BSACopyType_BACKUP;
   ObjectDescPtr->size.left     = 0;
   ObjectDescPtr->size.right    = 0;
   strcpy(ObjectDescPtr->resourceType, "database");
   ObjectDescPtr->objectType    = BSAObjectType_FILE;
   ObjectDescPtr->encodingList  = NULL;
   strcpy(ObjectDescPtr->desc, "DB2 Backup");
   strcpy(QueryDescPtr->desc, "DB2 Backup");
   ObjectDescPtr->objectInfo[0] = '\0';
   QueryDescPtr->owner          = ObjectDescPtr->Owner;
   QueryDescPtr->objName        = ObjectDescPtr->objName;
   QueryDescPtr->copyType       = ObjectDescPtr->copyType;
   QueryDescPtr->objectType     = ObjectDescPtr->objectType;
   QueryDescPtr->status         = ObjectDescPtr->status;

   BSAQueryApiVersion(&ApiVersion);

   // Initialize BSA session
   // -------------------------------------------------------------------------
   xbsaRC = BSAInit(&xbsaHandle,      /* Will contain session handle on retrun. */
                    &tokenPtr,        /* password                               */
                    &ObjectDescPtr->Owner,   /* Node name and Owner name               */
                     NULL);           /* Environment variables                  */
   if (xbsaRC != BSA_RC_SUCCESS)
   {
      SET_ERR_REASON(return_code, xbsaRC);
      goto exit;
   }

   // Build image to be deleted into objName
   // -------------------------------------------------------------------------
   sprintf(objName.objectSpaceName, "%s%s",
           PATH_SEP_STR, mediaHeader->clientDBAlias);

   sprintf(&objName.objectSpaceName[strlen(objName.objectSpaceName)], "%sNODE%4.4d", 
         PATH_SEP_STR, in->DB2_session->nodeNum);

   sprintf(&objName.objectSpaceName[strlen(objName.objectSpaceName)], "%s%s.%s.*",
           PATH_SEP_STR, "*" SQLUV_NAME_SUFFIX, mediaHeader->timestamp);

   QueryDescPtr->objName  = objName;
   QueryDescPtr->status   = BSAObjectStatus_ANY;

   // Find all objects matching image name
   // -------------------------------------------------------------------------
   xbsaRC = BSAQueryObject(xbsaHandle, QueryDescPtr, ObjectDescPtr);
   if (( xbsaRC != BSA_RC_SUCCESS) && (xbsaRC !=  BSA_RC_NO_MORE_DATA))
   {
      goto cleanup;
   }

   // Save all matching image objects in list
   // -------------------------------------------------------------------------
   while (( xbsaRC == BSA_RC_SUCCESS) || (xbsaRC ==  BSA_RC_NO_MORE_DATA) || (xbsaRC == BSA_RC_MORE_DATA))
   {
      if (fileCount > currentMaxObjsAllocate)
      {
         //
         // Double the size, reallocate and initialize
         // -------------------------------------------------------------------
         currentMaxObjsAllocate += currentMaxObjsAllocate;
         realloc(fileListPtr, sizeof(OBJECT_IDENT)*currentMaxObjsAllocate);
         if (fileListPtr == NULL)
         {
            rc = SQLUV_INIT_FAILED;
            SET_ERR_REASON(return_code, rc);
            goto exit;
         }
         memset((void *)&fileListPtr[(currentMaxObjsAllocate/2)],0x00,
                (sizeof(OBJECT_IDENT)*(currentMaxObjsAllocate/2)));
      }
      fileListPtr[fileCount].objName   = ObjectDescPtr->objName;
      fileListPtr[fileCount].copyType  = ObjectDescPtr->copyType;
      fileListPtr[fileCount].copyID    = ObjectDescPtr->copyId;
      fileCount++;

      if (xbsaRC == BSA_RC_NO_MORE_DATA)
        break;
      xbsaRC = BSAGetNextQueryObject(xbsaHandle, ObjectDescPtr);
      if (xbsaRC == BSA_RC_NO_MATCH)
        break;
   }

finished:
   xbsaRC = BSABeginTxn( xbsaHandle );
   if ( xbsaRC != BSA_RC_SUCCESS)
   {
      goto cleanup;
   }

   //
   // Go through the list just created and do the deletes.
   // -------------------------------------------------------------------------
   for(ix=0;ix<fileCount;ix++)
   {
      xbsaRC = BSADeleteObject(xbsaHandle,      /* BSA session Handle */
                           fileListPtr[ix].copyType,
                           &fileListPtr[ix].objName,
                           &fileListPtr[ix].copyID);
      if ( xbsaRC != BSA_RC_SUCCESS)
      {
         (void) BSAEndTxn(xbsaHandle,BSAVote_ABORT);
         goto cleanup;
      }
   }

   // Everything OK?  Commit the deletes.
   // -------------------------------------------------------------------------
   xbsaRC = BSAEndTxn(xbsaHandle,BSAVote_COMMIT);
   if ( xbsaRC != BSA_RC_SUCCESS)
   {
      goto cleanup;
   }

cleanup:
   // Terminate BSA session
   // -------------------------------------------------------------------------
   (void) BSATerminate (xbsaHandle);
   if ( xbsaRC != BSA_RC_SUCCESS)
      rc = SQLUV_IO_ERROR;

exit:

   // Free allocated memory
   // -------------------------------------------------------------------------
   if (ObjectDescPtr != NULL)
   {
     free(ObjectDescPtr);
     ObjectDescPtr = NULL;
   }
   if (QueryDescPtr != NULL)
   {
     free(QueryDescPtr);
     ObjectDescPtr = NULL;
   }
   if (fileListPtr != NULL)
   {
     free(fileListPtr);
     ObjectDescPtr = NULL;
   }

   return (rc);
}


// ----------------------------------------------------------------------------
// The functions that follow below are support functions for this sample
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Initialize all common BSA structures
// ----------------------------------------------------------------------------
void initBSAStructures( ObjectDescriptor  *objDesc,
                        QueryDescriptor   *qryDesc,
                        DB2_info          *db2_info)
{
#ifndef WIN32
   const char          *extraSeparator = "";
#else
   const char          *extraSeparator = PATH_SEP_STR;
#endif

   sprintf(objDesc->objName.objectSpaceName, "%c%s%s",PATH_SEP,extraSeparator,
           db2_info->alias);

   // The objDesc->version parameter is assumed to be
   // an input parameter. The current version number is defined in
   // custom.h .
   // -------------------------------------------------------------------------
   objDesc->version       = ObjectDescriptorVersion;
   objDesc->copyType      = BSACopyType_BACKUP;
   objDesc->objectType    = BSAObjectType_FILE;
   objDesc->size.left     = 0;
   objDesc->size.right    = 0;
   objDesc->encodingList  = NULL;
   objDesc->objectInfo[0] = '\0';

   objDesc->Owner.appObjectOwner[0] = '\0';
   strcpy(objDesc->Owner.bsaObjectOwner, "DB2");
   strcpy(objDesc->resourceType, "database");
   strcpy(objDesc->desc, "DB2 Backup");
   strcpy(qryDesc->desc, "DB2 Backup");

   // Init the query strcuture
   // -------------------------------------------------------------------------
   qryDesc->status     = BSAObjectStatus_ANY;
   qryDesc->owner      = objDesc->Owner;
   qryDesc->objName    = objDesc->objName;
   qryDesc->copyType   = objDesc->copyType;
   qryDesc->objectType = objDesc->objectType;
   qryDesc->status     = objDesc->status;


   return;
}

// ----------------------------------------------------------------------------
// To construct the XBSA file name
// ----------------------------------------------------------------------------
int  bldWriteObjDesc ( ObjectDescriptor  *objDesc,
                       QueryDescriptor   *qryDesc,
                       DB2_info          *db2_info,
                       sqluint32          type,
                       sqluint32          incr)
{
   int    rc                           = SQLUV_OK;

   // -------------------------------------------------------------------------
   sprintf(objDesc->objName.objectSpaceName, "/%s", db2_info->alias);

   sprintf(&objDesc->objName.objectSpaceName[strlen(objDesc->objName.objectSpaceName)],
          "%sNODE%4.4d", PATH_SEP_STR, db2_info->nodeNum);

   if ((db2_info->filename == NULL) || (db2_info->filename[0] == '\0'))
   {
      // ObjectName = /ALIAS/NODExxxx/
      //              /*_BACKUP.timestamp.seq_no
      //
      // For backup, timestamp is generated by the agent and is used
      // by all the media IO.
      // ----------------------------------------------------------------------
      sprintf(objDesc->objName.pathName, "%c%s.%s.%s",
              PATH_SEP,
              SQLUV_NAME_GENERATE(type, incr),
              db2_info->timestamp,
              db2_info->sequence );
   }
   else
   {
      // if backup and filename is provided.
      sprintf(objDesc->objName.pathName, "%c%s.%s.%s",
               PATH_SEP,
               db2_info->filename,
               db2_info->timestamp,
               db2_info->sequence );
   }

   return (rc);
}
// ----------------------------------------------------------------------------
// To construct the XBSA file name
// ----------------------------------------------------------------------------
int  bldReadObjDesc ( ObjectDescriptor  *objDesc,
                      QueryDescriptor   *qryDesc,
                      DB2_info          *db2_info)
{
   int    rc                           = SQLUV_OK;

   // Legatto XBSA's implementation requires that double-backslashes ("\\\\")
   // be passed on non-UNIX platforms because they interpert the '\'
   // character in XBSA to mean escape.  Therefore to use '\' as a regular
   // character we must escape it twice.  Once for the compiler and once
   // again for Legatto.  If your implemtation of XBSA does not assume
   // this then the code following needs to be modified to reflect this.
   // -------------------------------------------------------------------------

#ifndef WIN32
   const char *   extraSeparator = "";
#else
   const char *   extraSeparator = PATH_SEP_STR;
#endif
   const char *   filename       = "*" SQLUV_NAME_SUFFIX;
   char *         timestamp      = "";

   sprintf(&qryDesc->objName.objectSpaceName[strlen(qryDesc->objName.objectSpaceName)],
           "%s%sNODE%4.4d", PATH_SEP_STR, extraSeparator, db2_info->nodeNum);

   if (*db2_info->sequence == '0')
   {
      // this must be the first time in since all sequence
      // numbers start at '1'.
      // ----------------------------------------------------------------------
      *db2_info->sequence = '1';
   }

   // Restore does not currently supply a filename, but the
   // recovery of a load copy might.
   // -------------------------------------------------------------------------
   if ((db2_info->filename != NULL) && (db2_info->filename[0] != '\0'))
      filename = db2_info->filename;

   if ((db2_info->timestamp != NULL) && (db2_info->timestamp[0] != '\0'))
      timestamp = db2_info->timestamp;

   // filename not provided.
   // fs = /ALIAS
   // hl = /NODExxxx
   // ll = /*_BACKUP.timestamp.seq_no
   // -------------------------------------------------------------------------
   sprintf(qryDesc->objName.pathName, "%c%s%s.%s*.*",
           PATH_SEP, extraSeparator, filename, timestamp);

   return (rc);
}


// ----------------------------------------------------------------------------
// Select the latest backup image.
// The objName in QueryDesc is set to the search pattern.
// ----------------------------------------------------------------------------
int  getLatestCopy ( QueryDescriptor     * QueryDescPtr,
                     ObjectDescriptor    * objDataPtr,
                     sqluint32              * Handle,
                     sqluint16             nodeNum )
{
   DataBlock             dataBlk                     = {0x00};
   int                   rc                          = SQLUV_OK;
   BSA_Int16             xbsaRC                      = BSA_RC_OK;
   int                   CNamelen                    = 0;
   char                  objSpaceName [BSA_MAX_OSNAME+1] = {0x00};
   char                  pathName [BSA_MAX_OSNAME+1] = {0x00};
   char                 *tptr                        = NULL;
   int                   foundTSBackup               = FALSE;
   int                   foundDBBackup               = FALSE;
   int                   foundABackup                = FALSE;
   sqluint16             DBPartitionNum              = 0;

   xbsaRC = BSAQueryObject( *Handle,QueryDescPtr, objDataPtr);
   if ((xbsaRC != BSA_RC_SUCCESS) && (xbsaRC != BSA_RC_MORE_DATA) && (xbsaRC != BSA_RC_NO_MORE_DATA))
      goto exit;

   while ((xbsaRC == BSA_RC_MORE_DATA) || (xbsaRC == BSA_RC_NO_MORE_DATA) || ( xbsaRC == BSA_RC_SUCCESS))
   {

      // Ensure we are looking for data for this node only
      // ----------------------------------------------------------------------
      tptr = strrchr(objDataPtr->objName.objectSpaceName, PATH_SEP);
      if (tptr == NULL)
         tptr = objDataPtr->objName.objectSpaceName;
      else
        tptr+=strlen("/NODE");

      DBPartitionNum = (sqluint16)atoi(tptr);
      if (nodeNum == DBPartitionNum)
      {
        // Make a note of the type of backup.  If we find both a DB backup
        // and a table space backup, that means that the type of backup
        // to restore wasn't specified and we have both types on the
        // stroage server.  This is ambiguous.
        // --------------------------------------------------------------------
        if (   !strncmp((objDataPtr->objName.pathName)+1,
                        SQLUV_NAME_DB_FULL, sizeof(SQLUV_NAME_DB_FULL)-1)
            || !strncmp((objDataPtr->objName.pathName)+1,
                        SQLUV_NAME_DB, sizeof(SQLUV_NAME_DB)-1))
        {
           foundDBBackup = TRUE;
        }
        else if (!strncmp((objDataPtr->objName.pathName)+1,
                           SQLUV_NAME_TSP, sizeof(SQLUV_NAME_TSP)-1))
        {
           foundTSBackup = TRUE;
        }

        // Initialize image info when we find first matching backup image.
        if (! foundABackup)
        {
           strncpy(pathName, objDataPtr->objName.pathName,BSA_MAX_OSNAME );
           strncpy(objSpaceName, objDataPtr->objName.objectSpaceName,BSA_MAX_OSNAME);
           tptr = strrchr (pathName, '.');

           foundABackup = TRUE;

           *tptr = '\0';            // remove the sequence no. fr the fname.
           CNamelen = strlen(pathName);
        }
        else
        {
           if ((strncmp( objDataPtr->objName.pathName,
                          pathName, CNamelen ) > 0))  // CNamelen upto timestamp.
           {
              // keep the latest copy.
              tptr = strrchr (objDataPtr->objName.pathName, '.');
              if (tptr == NULL)
                 continue;
              *tptr = '\0';
              strncpy(pathName, objDataPtr->objName.pathName,BSA_MAX_OSNAME );
              strncpy(objSpaceName, objDataPtr->objName.objectSpaceName,BSA_MAX_OSNAME);
           }
        }
     }
     if (xbsaRC == BSA_RC_NO_MORE_DATA)
        break;
      xbsaRC = BSAGetNextQueryObject ( *Handle, objDataPtr);
      if (xbsaRC == BSA_RC_NO_MATCH)
        break;
   }

exit:

   if (foundTSBackup && foundDBBackup)
   {
      rc = SQLUV_OBJS_FOUND;
   }
   else if (foundABackup)
   {
      strcpy( objDataPtr->objName.objectSpaceName, objSpaceName );
      strcpy( objDataPtr->objName.pathName, pathName );
      strcat( objDataPtr->objName.pathName, ".*");  // seq_no.
      rc = SQLUV_OK;
   }
   else
   {
      rc = SQLUV_OBJ_NOT_FOUND;
   }

   return (rc);
}

#ifdef __cplusplus
}
#endif


