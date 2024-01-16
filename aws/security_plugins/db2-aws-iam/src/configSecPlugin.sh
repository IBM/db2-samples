#!/bin/sh

PRINCIPAL_NAME=__PRINCIPAL_NAME__
INSTANCE_OWNER=db2inst1


if [ "$USER" != "$INSTANCE_OWNER" ]; then
    echo "Script must be run by db2inst1"
    exit 1
fi

if [ "$1" == "-remove" ]; then
        db2 update dbm cfg using AUTHENTICATION SERVER
	db2 update dbm cfg using srvcon_auth NOT_SPECIFIED
	db2 update dbm cfg using srvcon_gssplugin_list NULL
	db2 update dbm cfg using group_plugin NULL
	db2 update dbm cfg using SRVCON_PW_PLUGIN NULL
else
    db2 update dbm cfg using srvcon_gssplugin_list  ${PRINCIPAL_NAME}
    db2 update dbm cfg using srvcon_auth GSS_SERVER_ENCRYPT
    db2 update dbm cfg using LOCAL_GSSPLUGIN ${PRINCIPAL_NAME}
    db2 update dbm cfg using AUTHENTICATION GSSPLUGIN
    db2 update dbm cfg using srvcon_auth GSS_SERVER_ENCRYPT
    db2 update dbm cfg using group_plugin ${PRINCIPAL_NAME}group
    db2 update dbm cfg using sysadm_group NULL
    db2set DB2AUTH=OSAUTHDB,ALLOW_LOCAL_FALLBACK,PLUGIN_AUTO_RELOAD
fi


