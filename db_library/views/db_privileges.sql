--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all the direct privileges granted on the system, including those gained via object ownership. Also include database level privileges, set session user privlies etc
 * 
 * This view extends the provided SYSIBMADM.PRIVILEGES view to also include
 * 
 *  - any Privileges given on objects that are owned by a user, role, group or PUBLIC
 *  - any database level authorities granted to a user, role, group or PUBLIC
 *  - any SET SESSION_USER privliges granted to a user
 *  - any ROLEs that a user, role, group or PUBLIC is a member of
 *
 * In this way, the view provides all of the GRANTs that have been explictly or implicitly performed on a system
 * , including privileges granted at database creation time to the instance owner
 * 
 * The view shows on direct privileges that a user, role, group or PUBLIC has,
 * , not any in-direct privliges that are inherited from a role or group membership, or from PUBLIC.
 * 
 */

CREATE OR REPLACE VIEW DB_PRIVILEGES AS
	SELECT DISTINCT
		AUTHID
	,	AUTHIDTYPE
	,	PRIVILEGE
	,	GRANTABLE
	,	OBJECTNAME
	,	OBJECTSCHEMA
	,	OBJECTTYPE
	,   'REVOKE ' || CASE PRIVILEGE WHEN 'REFERENCE' THEN 'REFERENCES' ELSE PRIVILEGE END || ' ON ' 
	    || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
	    || CASE WHEN OBJECTSCHEMA = '' THEN '' ELSE '"' || OBJECTSCHEMA ||  '".' END
	    || CASE WHEN OBJECTNAME   = '' THEN '' ELSE '"' || OBJECTNAME ||  '"' END || ' FROM ' 
	    || CASE WHEN AUTHID = 'PUBLIC' AND AUTHIDTYPE = 'G' THEN 'PUBLIC' 
	       ELSE CASE AUTHIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || AUTHID ||  '"' END AS REVOKE_STMT
    ,   'GRANT '  || CASE PRIVILEGE WHEN 'REFERENCE' THEN 'REFERENCES' ELSE PRIVILEGE END || ' ON '
        || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
        || CASE WHEN OBJECTSCHEMA = '' THEN '' ELSE '"' || OBJECTSCHEMA ||  '".' END 
        || CASE WHEN OBJECTNAME   = '' THEN '' ELSE '"' || OBJECTNAME ||  '"' END || ' TO ' 
        || CASE WHEN AUTHID = 'PUBLIC' AND AUTHIDTYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE AUTHIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || AUTHID ||  '"' END
        || CASE WHEN GRANTABLE = 'G' THEN ' WITH GRANT OPTION' ELSE '' END                                                        AS GRANT_STMT
	FROM
	    SYSIBMADM.PRIVILEGES
UNION ALL
    SELECT
        OWNER            AS AUTHID
    ,   OWNERTYPE        AS AUTHIDTYPE
    ,   'OWNER'          AS PRIVILEGE
    ,   'N'              AS GRANTABLE
    ,   OBJECTNAME
    ,   OBJECTSCHEMA
    ,   OBJECTTYPE
    ,   'TRANSFER OWNERSHIP OF ' || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
        || ' "' || OBJECTSCHEMA ||  '"."' || OBJECTNAME ||  '"' || ' TO USER SOME_OTHER_USER PRESERVE PRIVILEGES ' 
         AS REVOKE_STMT
    ,   'TRANSFER OWNERSHIP OF ' || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
        || ' "' || OBJECTSCHEMA ||  '"."' || OBJECTNAME ||  '"' || ' TO ' 
        || CASE WHEN OWNER = 'PUBLIC' AND OWNERTYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE OWNERTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || OWNER ||  '"' END AS GRANT_STMT
    FROM 
        SYSIBMADM.OBJECTOWNERS
    WHERE
        OWNER <> 'SYSIBM'
UNION ALL
	SELECT DISTINCT
	    A.GRANTEE                                    AS AUTHID
	,   A.GRANTEETYPE                                AS AUTHIDTYPE
	,   B.PRIVILEGE
	,   CASE WHEN B.AUTH = 'G' THEN 'Y' ELSE 'N' END AS GRANTABLE
	,   CURRENT SERVER                               AS OBJECTNAME
	,   ''                                           AS OBJECTSCHEMA
	,   CAST ('DATABASE' AS VARCHAR (11))            AS OBJECTTYPE
    ,   'REVOKE ' || PRIVILEGE || ' ON DATABASE FROM ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEETYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END AS REVOKE_STMT
    ,   'GRANT '  || PRIVILEGE || ' ON DATABASE TO ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEETYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END 
           || CASE WHEN AUTH = 'G' THEN ' WITH GRANT OPTION' ELSE '' END                                                            AS GRANT_STMT
	FROM SYSCAT.DBAUTH A          
	, LATERAL(VALUES
	    (BINDADDAUTH         ,'BINDADD')
	,   (CONNECTAUTH         ,'CONNECT')
	,   (CREATETABAUTH       ,'CREATETAB')
	,   (DBADMAUTH           ,'DBADM')
	,   (EXTERNALROUTINEAUTH ,'CREATE_EXTERNAL_ROUTINE')
	,   (IMPLSCHEMAAUTH      ,'IMPLICIT_SCHEMA')      
	,   (LOADAUTH            ,'LOAD')
	,   (NOFENCEAUTH         ,'CREATE_NOT_FENCED_ROUTINE') 
	,   (QUIESCECONNECTAUTH  ,'QUIESCE_CONNECT')
	,   (LIBRARYADMAUTH      ,'LIBRARYADMAUTH')
	,   (SECURITYADMAUTH     ,'SECADM')
	,   (SQLADMAUTH          ,'SQLADM')
	,   (WLMADMAUTH          ,'WLMADM')
	,   (EXPLAINAUTH         ,'EXPLAIN')
	,   (DATAACCESSAUTH      ,'DATAACCESS')
	,   (ACCESSCTRLAUTH      ,'ACCESSCTRL')
	) B ( AUTH, PRIVILEGE )
	WHERE  B.AUTH IN ('Y','G')
UNION ALL
	SELECT DISTINCT
	    TRUSTEDID               AS AUTHID
	,   TRUSTEDIDTYPE           AS AUTHIDTYPE
	,   'SETSESSIONUSER'        AS PRIVILEGE
	,   'N'                     AS GRANTABLE
	,   SURROGATEAUTHID         AS OBJECTNAME
	,   ''                      AS OBJECTSCHEMA
	,   SURROGATEAUTHIDTYPE     AS OBJECTTYPE
    ,   'REVOKE SETSESSIONUSER ON ' || CASE SURROGATEAUTHIDTYPE WHEN 'U' THEN 'USER ' || SURROGATEAUTHID ELSE 'PUBLIC' END || ' FROM ' 
        || CASE TRUSTEDIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || TRUSTEDID || '"'          AS REVOKE_STMT
    ,   'GRANT  SETSESSIONUSER ON ' || CASE SURROGATEAUTHIDTYPE WHEN 'U' THEN 'USER ' || SURROGATEAUTHID ELSE 'PUBLIC' END || ' TO '
        || CASE TRUSTEDIDTYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || TRUSTEDID || '"'          AS GRANT_STMT 
	FROM
	    SYSCAT.SURROGATEAUTHIDS
	WHERE
	    TRUSTEDIDTYPE <> 'C'  -- exclude SYSATSCONTEXT
UNION ALL
    SELECT GRANTEE              AS AUTHID
    ,      GRANTEETYPE          AS AUTHIDTYPE
    ,      'MEMBERSHIP'         AS PRIVILEGE
    ,      ADMIN                AS GRANTABLE
    ,      ROLENAME             AS OBJECTNAME
    ,      ''                   AS OBJECTSCHEMA
    ,      'ROLE'               AS OBJECTTYPE
    ,   'REVOKE ROLE FROM ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEETYPE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END AS REVOKE_STMT
    ,   'GRANT ROLE TO ' 
        || CASE WHEN GRANTEE = 'PUBLIC' AND GRANTEETYPE = 'G' THEN 'PUBLIC' 
           ELSE CASE GRANTEE WHEN 'G' THEN 'GROUP' WHEN 'U' THEN 'USER' WHEN 'R' THEN 'ROLE' END || ' "' || GRANTEE ||  '"' END
        || CASE WHEN ADMIN = 'Y' THEN ' WITH ADMIN OPTION' ELSE '' END                                                        AS GRANT_STMT
    FROM SYSCAT.ROLEAUTH
