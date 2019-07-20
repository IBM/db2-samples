--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version V10.5 FPs for Linux, UNIX AND Windows            */
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
-- Script to migrate SQL Apply tables from V10.5 Fixpak 7 to the latest
-- fixpack.
--
-- IMPORTANT:
-- * Please refer to the SQL Rep migration doc before attempting this migration.
-- *********************************************************************

ALTER TABLE ASN.IBMSNAP_SUBS_MEMBR ALTER COLUMN PREDICATES SET DATA TYPE VARCHAR(2048) ALTER COLUMN UOW_CD_PREDICATES SET DATA TYPE VARCHAR(2048);


