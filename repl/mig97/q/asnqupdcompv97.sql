--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.7 for Linux, UNIX AND Windows                      */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT          */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2009. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Q Capture Migration script to set the compatibility to '0907'

-- This script should be run only after all receiving q apply have been
-- migrated to V97

-- Script to migrate Q Capture control tables from V95 to V97.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
--
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables into V97.
--


--  Set CAPPARMS COMPATIBILITY to the correct value
--  depending on the level of QApply ARCH_LEVEL.  It should
--  be set to Qapply ARCH_LEVEL.
--
--  If Qapply is running in 9.1, this value should be  0901.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0901';
--
--  If Qapply is running in 8.2 this value should be  0802.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0802';
--
--  If Qapply is running with 91 APAR PK49430 or above (Qapply
--  ARCH_LEVEL 0905), then COMPATIBILTY value should be  0905.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0905';

--  If Qapply is running in 9.7, this value should be  0907.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0907';


UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0907';
