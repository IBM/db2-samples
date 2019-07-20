--****************************************************************************
-- (c) Copyright IBM Corp. 2017 All rights reserved.
--
-- The following sample of source code ("Sample") is owned by International
-- Business Machines Corporation or one of its subsidiaries ("IBM") and is
-- copyrighted and licensed, not sold. You may use, copy, modify, and
-- distribute the Sample in any form without payment to IBM, for the purpose of
-- assisting you in the development of your applications.
--
-- The Sample code is provided to you on an "AS IS" basis, without warranty of
-- any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
-- IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
-- not allow for the exclusion or limitation of implied warranties, so the above
-- limitations or exclusions may not apply to you. IBM shall not be liable for
-- any damages you suffer as a result of using, copying, modifying or
-- distributing the Sample, even if IBM has been advised of the possibility of
-- such damages.
--*****************************************************************************

echo ********************************************************;
echo                                                         ;
echo  This script was generated                              ;
echo                                                         ;
echo    by db2mon.pl version 1.2.0                           ;
echo                                                         ;
echo    for DB2 version 11.1                                 ;
echo                                                         ;
echo    on Tue Nov  6 17:55:45 2018                          ;
echo                                                         ;
echo    with 30 seconds pause between collections  ;
echo    in db2mon.sql and db2mon_export.sql                  ;
echo    (0 seconds pause means script will wait for <ENTER>) ;
echo                                                         ;
echo  Changes to this script will be overwritten the next    ;
echo  time db2mon.pl is run.                                 ;
echo                                                         ;
echo  1. Change to a directory containing IXF files produced ;
echo     by db2mon_export.sql                                ;
echo  2. Connect to an analysis database where you will load ;
echo     the monitoring data saved by db2mon_export.sql.     ;
echo     This is often a separate database, different        ;
echo     from the one where data was originally collected.   ;
echo  3. Run with CLP as in 'db2 -tvf db2mon_import.sql'     ;
echo                                                         ;
echo  The script will import the monitor data and create     ;
echo  tables containing the delta values of all collected    ;
echo  metrics.                                               ;
echo                                                         ;
echo  Next step after db2mon_import: run db2mon_report       ;
echo  to perform offline analysis.                           ;
echo                                                         ;
echo ********************************************************;
echo                                                         ;

select cast(substr(current schema,1,24) as varchar(24)) as current_schema from sysibm.sysdummy1;

--#SET TERMINATOR @

----------------------------------------------------------------------------------
-- procedure db2mon.diff_quiet_drop
--
-- Routine for executing SQL DROP statement, which catches 'not found' errors.

CREATE OR REPLACE PROCEDURE db2mon.diff_quiet_drop( IN statement VARCHAR(1000) )
LANGUAGE SQL
BEGIN
   DECLARE SQLSTATE CHAR(5);
   DECLARE NotThere    CONDITION FOR SQLSTATE '42704';
   DECLARE NotThereSig CONDITION FOR SQLSTATE '42883';

   DECLARE EXIT HANDLER FOR NotThere, NotThereSig
      SET SQLSTATE = '     ';

   SET statement = 'DROP ' || statement;
   EXECUTE IMMEDIATE statement;
END@



----------------------------------------------------------------------------------
-- procedure db2mon.diff_log
--
-- Writes a text string to db2mon.diff_log, breaking up long lines into smaller ones.
-- In case of an error in db2mon.diff, we will open a cursor on this table and dump out
-- the contents.
-- COMMITs after each write, so that if an error occurs, we don't lose our messages.

CREATE OR REPLACE PROCEDURE db2mon.diff_log( IN message CLOB(100000) )
LANGUAGE SQL
BEGIN

   DECLARE start integer;
   DECLARE len integer;
   DECLARE insert_stmt_str char(80);
   DECLARE buffer char(81);

   set start = 1;
   set len = length(message);

   set insert_stmt_str = 'insert into db2mon.diff_log values ( ? )';
   prepare insert_stmt from insert_stmt_str;

   while len > 0 do
     set buffer = cast(substr(message,start,min(len,80)) as varchar(80)) || case when len > 80 then '-' else '' end;
     execute insert_stmt using buffer;
     set start = start + 80;
     set len = len - 80;
   end while;
   execute insert_stmt using ' ';

   commit work;

END@




----------------------------------------------------------------------------------
-- procedure db2mon.diff
--
-- Routine to calculate delta values between tables loaded from db2mon data collection.
-- Basename is passed in, and input tables are 'basename'_start and _end.
-- Routine creates 'basename'_diff, with the delta values.
-- Numeric columns are subtracted, and non-numeric columns are
-- simply copied from the 'after' case.
--
-- Key columns (keyColumnList) are how we find the before and after rows in multi-row data sets.
-- e.g. MEMBER for MON_GET_DATABASE,  MEMBER and WORKLOAD_ID for MON_GET_WORKLOAD, etc.
-- There are also numeric columns that we don't diff (things that don't represent
-- an increasing count / time).    The names are passed in through nonDiffColumnList.
--

CREATE OR REPLACE TYPE db2mon.stringArray AS VARCHAR(256) ARRAY[6]@

CREATE OR REPLACE PROCEDURE db2mon.diff
  (IN p_tabname VARCHAR (256),
   IN keyColumnList VARCHAR(256),
   IN nonDiffColumnList VARCHAR(256) )
DYNAMIC RESULT SETS 1
LANGUAGE SQL
BEGIN

    DECLARE keycolumn db2mon.stringArray;
    DECLARE maxkeys INTEGER default 6;
    DECLARE keysused INTEGER default 0;
    DECLARE keystring VARCHAR(4096);

    DECLARE base_table_name varchar(128);
    DECLARE start_table_name varchar(128);
    DECLARE stmt_str clob(200000);
    DECLARE column_list clob(200000);
    DECLARE colname_stmt_str varchar(256);
    DECLARE schema_name varchar(128);
    DECLARE colname varchar(128);
    DECLARE typename varchar(128);

    DECLARE a_keycolumn db2mon.stringArray;
    DECLARE b_keycolumn db2mon.stringArray;
    DECLARE v_no_data integer;
    DECLARE message varchar(16000) default '';
    DECLARE offset integer default 0;

    DECLARE key_card bigint;
    DECLARE table_card bigint;

    DECLARE loop integer;
    DECLARE SQLSTATE char(5);
    DECLARE SQLCODE integer default 0;

    DECLARE Syntax CONDITION FOR SQLSTATE '42601';
    DECLARE Invalid CONDITION FOR SQLSTATE '42703';
    DECLARE Undefined CONDITION FOR SQLSTATE '42704';
    DECLARE Improper CONDITION FOR SQLSTATE '42907';

    DECLARE colname_cursor cursor for colname_stmt;
    DECLARE keycount_cursor cursor for keycount_stmt;

    DECLARE output_cursor cursor with return to caller for output_Stmt;

    DECLARE continue handler for not found set v_no_data=1;



    ----------------------------------------------------------------------------------
    -- Create an exit handler to catch typical errors, and report them in a more
    -- useful way
    DECLARE EXIT HANDLER FOR Syntax, Undefined, Invalid, Improper
    begin
       DECLARE local_message varchar(16000);
       SET local_message = 'PREPARE failed, sqlcode ' || char(sqlcode) || ': ' || stmt_str;
       CALL db2mon.diff_log( local_message );

       set stmt_str = 'SELECT message from db2mon.diff_log';

       prepare output_Stmt from stmt_str;
       open output_cursor;
    end;


    ----------------------------------------------------------------------------------
    -- We write messages, including SQL statmeents for the views & tables we create,
    -- to db2mon.diff_log, which can be used to diagnos problems if they occur.

    call db2mon.diff_quiet_drop( 'table db2mon.diff_log' );
    set stmt_str = 'create table db2mon.diff_log( message char(81) )';
    execute immediate stmt_str;

    set nonDiffColumnList=','||upper(nonDiffColumnList)||',';

    set keyColumnList=upper(keyColumnList)||',';
    set loop=1;
    set keysused=0;
    set keystring='';
    set offset=locate(',',keyColumnList);
    while loop <= maxkeys and offset > 1
    do
        set keycolumn[loop] = upper(substr(keyColumnList,1,offset-1));
        set keystring = keystring || ' ' || keycolumn[loop];
        if length(keycolumn[loop]) > 0 then
            set keysused = keysused+1;
        end if;
        set keyColumnList=substr(keyColumnList,offset+1);
        set offset=locate(',',keyColumnList);
        set loop=loop+1;
    end while;

    set base_table_name=upper(p_tabname);
    set colname_stmt_str = 'select colname,typename from syscat.columns ' ||
            'where tabschema = current schema and tabname = ? order by colno with UR';

    set start_table_name=base_table_name||'_START';


    set v_no_data=0;


    if keysused > 0 then
        ----------------------------------------------------------------------------------
        -- There's a key column, so we want to try to make sure it's at least lower cardinality
        -- than the table itself.

        set stmt_str = 'select count(*),count(distinct ';
        set loop=1;
        while loop <= keysused
        do
            set stmt_str = stmt_str || 'cast(coalesce(varchar('||keycolumn[loop]||'),'' '') as varchar(500))' || case when loop < keysused then '||' else '' end;
            set loop=loop+1;
        end while;
        set stmt_str = stmt_str || ') from '|| p_tabname || '_start with UR';
        prepare keycount_stmt from stmt_str;
        call db2mon.diff_log( stmt_str );
        open keycount_cursor;
        fetch keycount_cursor into table_card,key_card;
        close keycount_cursor;
    else
        ----------------------------------------------------------------------------------
        -- No key column - better be a single row result.

        set stmt_str = 'select count(*) from '|| p_tabname || '_start with UR';
        prepare keycount_stmt from stmt_str;
        call db2mon.diff_log( stmt_str );
        open keycount_cursor;
        fetch keycount_cursor into table_card;
        set key_card = 0;
        close keycount_cursor;
    end if;

    ----------------------------------------------------------------------------------
    -- Create the 'diff' table (where we insert monitor data), which will also be
    -- used as the template for the 'before' and 'after' tables.

    call db2mon.diff_quiet_drop( 'table ' || base_table_name || '_diff' );
    set stmt_str = 'create table ' || base_table_name || '_diff as (select cast(null as integer) ts_delta,t.* from ' || p_tabname || '_start t) with no data';

    if ( keysused = 0 and table_card <= 1 ) or table_card = key_card then

        ----------------------------------------------------------------------------------
        -- If all is well at this point (cardinality of the key column is ok), then create the tables
        prepare stmt_handle from stmt_str;
        call db2mon.diff_log( stmt_str );
        execute stmt_handle;


        ----------------------------------------------------------------------------------
        -- Now to create the view for the delta itself.  We need to go through column-by-column
        -- in the original table, so open a SELECT on that.

        set stmt_str = colname_stmt_str;
        prepare colname_stmt from stmt_str;
        call db2mon.diff_log( stmt_str );
        open colname_cursor using start_table_name;
        fetch colname_cursor into colname,typename;


        ----------------------------------------------------------------------------------
        -- Start building the subselect, and add on to it as we go.
        set stmt_str = 'select (((JULIAN_DAY(A.ts)-JULIAN_DAY(B.ts))*24 + (HOUR(A.ts)-HOUR(B.ts)))*60 + (MINUTE(A.ts)-MINUTE(B.ts)))*60 + (SECOND(A.ts)-SECOND(B.ts)) ';
        set column_list = ' ';

        set loop=1;
        while loop <= keysused
        do
            set a_keycolumn[loop] = 'A.'||keycolumn[loop];
            set b_keycolumn[loop] = 'B.'||keycolumn[loop];
            set loop=loop+1;
        end while;

        while ( v_no_data = 0 )
        do
            set column_list = case when column_list = ' ' then colname else column_list || ' ,' || colname end;

            if ( TYPENAME in ('BIGINT','INTEGER','SMALLINT','DECIMAL','FLOAT')
                 and colname not in (select keycol from table(keycolumn) as t(keycol))

               -- there are some numeric columns we don't want to delta.
               -- eventually we may have to qualify these with table names, but for now we'll assume
               -- the column name alone is enough
               and colname not in ('MEMBER','BP_CUR_BUFFSZ','NLEAF','NLEVELS','SECTION_NUMBER')
               and colname not like ('%_ID') )
            then
                    if( locate(','||colname||',' , nonDiffColumnList) > 0 ) then
                        set stmt_str = stmt_str || ', A.'||colname ;
                    else
                        -- For numeric types, subtract before from after.
                        set stmt_str = stmt_str || ', A.'||colname || '-B.'||colname;
                    end if;
            else
                    -- For non-numeric types, just pick up 'after'
                    set stmt_str = stmt_str || ', A.'||colname;

                    -- If any of the keycolumns is a CLOB, we need to substring it down for easy comparison.
                    set loop=1;
                    while loop <= keysused
                    do
                        if ( colname = keycolumn[loop] and typename = 'CLOB' ) then
                            set a_keycolumn[loop] = 'varchar(substr(A.'||keycolumn[loop]||',1,min(1000,length(A.'||keycolumn[loop]||'))))';
                            set b_keycolumn[loop] = 'varchar(substr(B.'||keycolumn[loop]||',1,min(1000,length(B.'||keycolumn[loop]||'))))';
                            set   keycolumn[loop] = 'varchar(substr(  '||keycolumn[loop]||',1,min(1000,length(  '||keycolumn[loop]||'))))';
                        end if;
                        set loop=loop+1;
                    end while;
            end if;

            fetch colname_cursor into colname,typename;

        end while;

        close colname_cursor;

        ----------------------------------------------------------------------------------
        -- Pull together the insert statement.
        -- We use concat() here instead of || because stmt_str is a LOB and || seems to have a
        -- return type of VARCHAR

        set stmt_str = concat( 'INSERT INTO ', concat( base_table_name, concat( '_diff ( ts_delta, ',
            concat( column_list, concat( ')',concat( stmt_str,concat(' from ',concat(base_table_name,concat('_start B, ',
            base_table_name || '_end A ' )))))))));

        set loop=1;
        while loop <= keysused
        do
            set stmt_str=concat(stmt_str,
                         case when loop=1 then 'where ' else 'and ' end ||
                         'coalesce(char(' || b_keycolumn[loop] || '),'' '') = coalesce(char(' || a_keycolumn[loop] || '),'' '')' ) ;
            set loop=loop+1;
        end while;

        if keysused > 0 then
          -- Make sure we include rows that are only in the AFTER table (new SQL in mgpcs, etc.)

          set stmt_str = concat(stmt_str,
            ' union all select ' ||
            '(select (((JULIAN_DAY(min(A.ts))-JULIAN_DAY(min(B.ts)))*24 + (HOUR(min(A.ts))-HOUR(min(B.ts))))*60 + (MINUTE(min(A.ts))-MINUTE(min(B.ts))))*60 + (SECOND(min(A.ts))-SECOND(min(B.ts))) from ' ||
            base_table_name || '_end A, ' || base_table_name || '_start B) ,' ||
            'A.* from ' || concat( base_table_name,concat('_end A where not exists ',
            concat( '(select ', concat( b_keycolumn[1], concat( ' from ', concat( base_table_name,'_start B ')))))));

          set loop=1;
          while loop <= keysused
          do
              set stmt_str=concat(stmt_str,
                           case when loop=1 then 'where ' else 'and ' end ||
                           'coalesce(char(' || b_keycolumn[loop] || '),'' '') = coalesce(char(' || a_keycolumn[loop] || '),'' '')' ) ;
              set loop=loop+1;
          end while;
          set stmt_str = stmt_str || ')';

        end if;

        call db2mon.diff_log( stmt_str );

        prepare stmt_handle from stmt_str;
        execute stmt_handle;
        call db2mon.diff_log( stmt_str );



    else  -- cardinalities don't look right, so we log a message and bail out.

        if keysused > 0 then
          set stmt_str = 'SELECT msg from table ( values(''db2mon.diff: key column "';
          set loop=1;
          while loop <= keysused
          do
              set stmt_str=stmt_str || keycolumn[loop] || '" ';
              set loop=loop+1;
          end while;
          set stmt_str=stmt_str || ' not unique in table, or key columns not specified "' || p_tabname || '"'')) t(msg)';
        else
          set stmt_str = 'SELECT msg from table ( ' ||
                        'values(''db2mon.diff: key columns not specified for "' ||
                        p_tabname || '" and cardinality > 1'')) t(msg)';
        end if;

        prepare output_Stmt from stmt_str;
        call db2mon.diff_log( stmt_str );
        open output_cursor;

    end if;   -- key card == table card

END @

--#SET TERMINATOR ;

drop table db_get_cfg_start;
import from db_get_cfg_start.ixf of ixf modified by forcecreate create into db_get_cfg_start;
create index idx_db_get_cfg_start on db_get_cfg_start (member, name);
drop table dbmcfg_start;
import from dbmcfg_start.ixf of ixf modified by forcecreate create into dbmcfg_start;
create index idx_dbmcfg_start on dbmcfg_start (name);
drop table env_cf_sys_resources_start;
import from env_cf_sys_resources_start.ixf of ixf modified by forcecreate create into env_cf_sys_resources_start;
create index idx_env_cf_sys_resources_start on env_cf_sys_resources_start (id, name);
drop table env_get_reg_variables_start;
import from env_get_reg_variables_start.ixf of ixf modified by forcecreate create into env_get_reg_variables_start;
create index idx_env_get_reg_variables_start on env_get_reg_variables_start (member, reg_var_name);
drop table env_get_system_resources_start;
import from env_get_system_resources_start.ixf of ixf modified by forcecreate create into env_get_system_resources_start;
create index idx_env_get_system_resources_start on env_get_system_resources_start (member);
drop table env_inst_info_start;
import from env_inst_info_start.ixf of ixf modified by forcecreate create into env_inst_info_start;
drop table mon_current_sql_plus_start;
import from mon_current_sql_plus_start.ixf of ixf modified by forcecreate create into mon_current_sql_plus_start;
drop table mon_get_appl_lockwait_plus_start;
import from mon_get_appl_lockwait_plus_start.ixf of ixf modified by forcecreate create into mon_get_appl_lockwait_plus_start;
drop table mon_get_bufferpool_start;
import from mon_get_bufferpool_start.ixf of ixf modified by forcecreate create into mon_get_bufferpool_start;
create index idx_mon_get_bufferpool_start on mon_get_bufferpool_start (member, bp_name);
drop table mon_get_cf_start;
import from mon_get_cf_start.ixf of ixf modified by forcecreate create into mon_get_cf_start;
create index idx_mon_get_cf_start on mon_get_cf_start (id);
drop table mon_get_cf_cmd_start;
import from mon_get_cf_cmd_start.ixf of ixf modified by forcecreate create into mon_get_cf_cmd_start;
create index idx_mon_get_cf_cmd_start on mon_get_cf_cmd_start (hostname, id, cf_cmd_name);
drop table mon_get_cf_wait_time_start;
import from mon_get_cf_wait_time_start.ixf of ixf modified by forcecreate create into mon_get_cf_wait_time_start;
create index idx_mon_get_cf_wait_time_start on mon_get_cf_wait_time_start (member, hostname, id, cf_cmd_name);
drop table mon_get_connection_start;
import from mon_get_connection_start.ixf of ixf modified by forcecreate create into mon_get_connection_start;
create index idx_mon_get_connection_start on mon_get_connection_start (member, application_name, application_handle, client_applname);
drop table mon_get_extended_latch_wait_start;
import from mon_get_extended_latch_wait_start.ixf of ixf modified by forcecreate create into mon_get_extended_latch_wait_start;
create index idx_mon_get_extended_latch_wait_start on mon_get_extended_latch_wait_start (member, latch_name);
drop table mon_get_group_bufferpool_start;
import from mon_get_group_bufferpool_start.ixf of ixf modified by forcecreate create into mon_get_group_bufferpool_start;
create index idx_mon_get_group_bufferpool_start on mon_get_group_bufferpool_start (member);
drop table mon_get_memory_pool_start;
import from mon_get_memory_pool_start.ixf of ixf modified by forcecreate create into mon_get_memory_pool_start;
create index idx_mon_get_memory_pool_start on mon_get_memory_pool_start (member);
drop table mon_get_memory_set_start;
import from mon_get_memory_set_start.ixf of ixf modified by forcecreate create into mon_get_memory_set_start;
create index idx_mon_get_memory_set_start on mon_get_memory_set_start (member);
drop table mon_get_page_access_info_start;
import from mon_get_page_access_info_start.ixf of ixf modified by forcecreate create into mon_get_page_access_info_start;
create index idx_mon_get_page_access_info_start on mon_get_page_access_info_start (member, tabschema, tabname, objtype, data_partition_id, iid);
drop table mon_get_pkg_cache_stmt_start;
import from mon_get_pkg_cache_stmt_start.ixf of ixf modified by forcecreate create into mon_get_pkg_cache_stmt_start;
create index idx_mon_get_pkg_cache_stmt_start on mon_get_pkg_cache_stmt_start (member, planid, executable_id);
drop table mon_get_serverlist_start;
import from mon_get_serverlist_start.ixf of ixf modified by forcecreate create into mon_get_serverlist_start;
create index idx_mon_get_serverlist_start on mon_get_serverlist_start (member);
drop table mon_get_table_start;
import from mon_get_table_start.ixf of ixf modified by forcecreate create into mon_get_table_start;
create index idx_mon_get_table_start on mon_get_table_start (member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id);
drop table mon_get_tablespace_start;
import from mon_get_tablespace_start.ixf of ixf modified by forcecreate create into mon_get_tablespace_start;
create index idx_mon_get_tablespace_start on mon_get_tablespace_start (member, tbsp_name);
drop table mon_get_transaction_log_start;
import from mon_get_transaction_log_start.ixf of ixf modified by forcecreate create into mon_get_transaction_log_start;
create index idx_mon_get_transaction_log_start on mon_get_transaction_log_start (member);
drop table mon_get_utility_start;
import from mon_get_utility_start.ixf of ixf modified by forcecreate create into mon_get_utility_start;
drop table mon_get_workload_start;
import from mon_get_workload_start.ixf of ixf modified by forcecreate create into mon_get_workload_start;
create index idx_mon_get_workload_start on mon_get_workload_start (member, workload_name);
drop table db_get_cfg_end;
import from db_get_cfg_end.ixf of ixf modified by forcecreate create into db_get_cfg_end;
create index idx_db_get_cfg_end on db_get_cfg_end (member, name);
drop table dbmcfg_end;
import from dbmcfg_end.ixf of ixf modified by forcecreate create into dbmcfg_end;
create index idx_dbmcfg_end on dbmcfg_end (name);
drop table env_cf_sys_resources_end;
import from env_cf_sys_resources_end.ixf of ixf modified by forcecreate create into env_cf_sys_resources_end;
create index idx_env_cf_sys_resources_end on env_cf_sys_resources_end (id, name);
drop table env_get_reg_variables_end;
import from env_get_reg_variables_end.ixf of ixf modified by forcecreate create into env_get_reg_variables_end;
create index idx_env_get_reg_variables_end on env_get_reg_variables_end (member, reg_var_name);
drop table env_get_system_resources_end;
import from env_get_system_resources_end.ixf of ixf modified by forcecreate create into env_get_system_resources_end;
create index idx_env_get_system_resources_end on env_get_system_resources_end (member);
drop table env_inst_info_end;
import from env_inst_info_end.ixf of ixf modified by forcecreate create into env_inst_info_end;
drop table mon_current_sql_plus_end;
import from mon_current_sql_plus_end.ixf of ixf modified by forcecreate create into mon_current_sql_plus_end;
drop table mon_get_appl_lockwait_plus_end;
import from mon_get_appl_lockwait_plus_end.ixf of ixf modified by forcecreate create into mon_get_appl_lockwait_plus_end;
drop table mon_get_bufferpool_end;
import from mon_get_bufferpool_end.ixf of ixf modified by forcecreate create into mon_get_bufferpool_end;
create index idx_mon_get_bufferpool_end on mon_get_bufferpool_end (member, bp_name);
drop table mon_get_cf_end;
import from mon_get_cf_end.ixf of ixf modified by forcecreate create into mon_get_cf_end;
create index idx_mon_get_cf_end on mon_get_cf_end (id);
drop table mon_get_cf_cmd_end;
import from mon_get_cf_cmd_end.ixf of ixf modified by forcecreate create into mon_get_cf_cmd_end;
create index idx_mon_get_cf_cmd_end on mon_get_cf_cmd_end (hostname, id, cf_cmd_name);
drop table mon_get_cf_wait_time_end;
import from mon_get_cf_wait_time_end.ixf of ixf modified by forcecreate create into mon_get_cf_wait_time_end;
create index idx_mon_get_cf_wait_time_end on mon_get_cf_wait_time_end (member, hostname, id, cf_cmd_name);
drop table mon_get_connection_end;
import from mon_get_connection_end.ixf of ixf modified by forcecreate create into mon_get_connection_end;
create index idx_mon_get_connection_end on mon_get_connection_end (member, application_name, application_handle, client_applname);
drop table mon_get_extended_latch_wait_end;
import from mon_get_extended_latch_wait_end.ixf of ixf modified by forcecreate create into mon_get_extended_latch_wait_end;
create index idx_mon_get_extended_latch_wait_end on mon_get_extended_latch_wait_end (member, latch_name);
drop table mon_get_group_bufferpool_end;
import from mon_get_group_bufferpool_end.ixf of ixf modified by forcecreate create into mon_get_group_bufferpool_end;
create index idx_mon_get_group_bufferpool_end on mon_get_group_bufferpool_end (member);
drop table mon_get_memory_pool_end;
import from mon_get_memory_pool_end.ixf of ixf modified by forcecreate create into mon_get_memory_pool_end;
create index idx_mon_get_memory_pool_end on mon_get_memory_pool_end (member);
drop table mon_get_memory_set_end;
import from mon_get_memory_set_end.ixf of ixf modified by forcecreate create into mon_get_memory_set_end;
create index idx_mon_get_memory_set_end on mon_get_memory_set_end (member);
drop table mon_get_page_access_info_end;
import from mon_get_page_access_info_end.ixf of ixf modified by forcecreate create into mon_get_page_access_info_end;
create index idx_mon_get_page_access_info_end on mon_get_page_access_info_end (member, tabschema, tabname, objtype, data_partition_id, iid);
drop table mon_get_pkg_cache_stmt_end;
import from mon_get_pkg_cache_stmt_end.ixf of ixf modified by forcecreate create into mon_get_pkg_cache_stmt_end;
create index idx_mon_get_pkg_cache_stmt_end on mon_get_pkg_cache_stmt_end (member, planid, executable_id);
drop table mon_get_serverlist_end;
import from mon_get_serverlist_end.ixf of ixf modified by forcecreate create into mon_get_serverlist_end;
create index idx_mon_get_serverlist_end on mon_get_serverlist_end (member);
drop table mon_get_table_end;
import from mon_get_table_end.ixf of ixf modified by forcecreate create into mon_get_table_end;
create index idx_mon_get_table_end on mon_get_table_end (member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id);
drop table mon_get_tablespace_end;
import from mon_get_tablespace_end.ixf of ixf modified by forcecreate create into mon_get_tablespace_end;
create index idx_mon_get_tablespace_end on mon_get_tablespace_end (member, tbsp_name);
drop table mon_get_transaction_log_end;
import from mon_get_transaction_log_end.ixf of ixf modified by forcecreate create into mon_get_transaction_log_end;
create index idx_mon_get_transaction_log_end on mon_get_transaction_log_end (member);
drop table mon_get_utility_end;
import from mon_get_utility_end.ixf of ixf modified by forcecreate create into mon_get_utility_end;
drop table mon_get_workload_end;
import from mon_get_workload_end.ixf of ixf modified by forcecreate create into mon_get_workload_end;
create index idx_mon_get_workload_end on mon_get_workload_end (member, workload_name);
drop table syscat_tables;
import from syscat_tables.ixf of ixf modified by forcecreate create into syscat_tables;
create index idx_syscat_tables on syscat_tables (tbspaceid,tableid);
drop table syscat_tablespaces;
import from syscat_tablespaces.ixf of ixf modified by forcecreate create into syscat_tablespaces;
create index idx_syscat_tablespaces on syscat_tablespaces (tbspaceid);
drop table syscat_bufferpools;
import from syscat_bufferpools.ixf of ixf modified by forcecreate create into syscat_bufferpools;
create index idx_syscat_bufferpools on syscat_bufferpools (bufferpoolid);
drop table syscat_sequences;
import from syscat_sequences.ixf of ixf modified by forcecreate create into syscat_sequences;
call db2mon.diff_quiet_drop( 'table env_get_system_resources_diff' );
call db2mon.diff('env_get_system_resources','member','os_name,host_name,os_version,os_release,cpu_total,cpu_online,cpu_configured,cpu_speed,cpu_hmt_degree,memory_total,memory_free,cpu_load_short,cpu_load_medium,cpu_load_long,cpu_usage_total');
call db2mon.diff_quiet_drop( 'table mon_get_bufferpool_diff' );
call db2mon.diff('mon_get_bufferpool','member,bp_name','bp_cur_buffsz,automatic');
call db2mon.diff_quiet_drop( 'table mon_get_cf_cmd_diff' );
call db2mon.diff('mon_get_cf_cmd','hostname,id,cf_cmd_name','');
call db2mon.diff_quiet_drop( 'table mon_get_cf_wait_time_diff' );
call db2mon.diff('mon_get_cf_wait_time','member,hostname,id,cf_cmd_name','');
call db2mon.diff_quiet_drop( 'table mon_get_connection_diff' );
call db2mon.diff('mon_get_connection','member,application_name,application_handle,client_applname','connection_reusability_status,reusability_status_reason');
call db2mon.diff_quiet_drop( 'table mon_get_extended_latch_wait_diff' );
call db2mon.diff('mon_get_extended_latch_wait','member,latch_name','');
call db2mon.diff_quiet_drop( 'table mon_get_group_bufferpool_diff' );
call db2mon.diff('mon_get_group_bufferpool','member','');
call db2mon.diff_quiet_drop( 'table mon_get_page_access_info_diff' );
call db2mon.diff('mon_get_page_access_info','member,tabschema,tabname,objtype,data_partition_id,iid','');
call db2mon.diff_quiet_drop( 'table mon_get_pkg_cache_stmt_diff' );
call db2mon.diff('mon_get_pkg_cache_stmt','member,planid,executable_id','package_name,stmt_text,stmtid,semantic_env_id,active_sorts_top,sort_heap_top,sort_shrheap_top');
create index idx_mon_get_pkg_cache_stmt_diff on mon_get_pkg_cache_stmt_diff (member, planid, executable_id);
call db2mon.diff_quiet_drop( 'table mon_get_table_diff' );
call db2mon.diff('mon_get_table','member,tabname,tabschema,data_partition_id,tbsp_id,tab_file_id','data_sharing_state_change_time,data_sharing_state');
create index idx_mon_get_table_diff on mon_get_table_diff (member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id);
call db2mon.diff_quiet_drop( 'table mon_get_tablespace_diff' );
call db2mon.diff('mon_get_tablespace','member,tbsp_name','tbsp_page_size,tbsp_id,tbsp_extent_size,tbsp_prefetch_size,fs_caching');
call db2mon.diff_quiet_drop( 'table mon_get_transaction_log_diff' );
call db2mon.diff('mon_get_transaction_log','member','');
call db2mon.diff_quiet_drop( 'table mon_get_workload_diff' );
call db2mon.diff('mon_get_workload','member,workload_name','sort_shrheap_allocated');
