--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version V10.5 Fixpak 7 for Linux, UNIX AND Windows            */
--                                                                   */
--     Sample SQL Replication migration script for UNIX AND NT       */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 2015. All Rights Reserved             */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate SQL Apply tables from V10 to V10.5 Fixpak 7.
--
-- IMPORTANT:
-- * Please refer to the SQL Rep migration doc before attempting this migration.
-- *********************************************************************

UPDATE ASN.IBMSNAP_APPLEVEL SET ARCH_LEVEL = '1021';


