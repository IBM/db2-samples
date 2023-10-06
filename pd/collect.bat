::/*
::Copyright <holder> All Rights Reserved.
::
::SPDX-License-Identifier: Apache-2.0
::*/
::
::Signed-off-by: Bharat Goyal <bharat.goyal@ibm.com>

@ECHO OFF

::USAGE: Collect.bat <DBNAME> <APPHDL> <ITERATION> <INTERVAL>
::If Iteration or Interval not passed then by default 3 Iteration with interval 30s 

::Variable Setting
SET ITERATION=3
SET INTERVAL=30


:INIT
	IF %1.==. GOTO MISSING
	IF %2.==. GOTO NOAPPHDL
	IF %3.==. GOTO DEFAULT
	IF %4.==. GOTO DEFAULT
	GOTO CHANGE_VAR
	GOTO END

	:MISSING
	  ECHO.
	  ECHO DBNAME is Missing. Exiting...
	  ECHO.
	  ECHO USAGE: Db2WindowsCollect.bat ^<DBNAME^> [^<APPHDL^>] [^<ITERATION^>] [^<INTERVAL^>]
	  GOTO END
	:DEFAULT
	  SET ITERATION=3
	  SET INTERVAL=30
	  SET APPHDL=%2
	  GOTO START
	  GOTO END

	:NOAPPHDL
	  SET DBNAME=%1
	  SET ITERATION=3
	  SET INTERVAL=30
	  SET APPHDL=-1
	  GOTO START
	  GOTO END	  

	:END
	  EXIT /B 1

:CHANGE_VAR
	SET DBNAME=%1
	SET APPHDL=%2
	SET ITERATION=%3
	SET INTERVAL=%4


:START


	::Setting Variables
	SET /a It=%ITERATION%
	SET /a COUNT=1

	ECHO:
		ECHO  .=========================================================.
		ECHO  ^|                                                         ^|
		ECHO  ^|            Diagnostic Data Collection Started           ^|
		ECHO  ^|                                                         ^|
		ECHO  .=========================================================.
	ECHO:

	::Show configuration used. 
	ECHO Parameters Used: 
	ECHO.
	ECHO DBNAME            : %DBNAME%
	ECHO APPHDL            : %APPHDL%
	ECHO ITERATION         : %ITERATION%
	ECHO INTERVAL          : %INTERVAL%

	:: Connecting to DB
	db2 connect to %DBNAME%
	ECHO.
	ECHO Stacks will be generated here ^: 
	db2 get dbm cfg | findstr DIAGPATH
	ECHO.


	:: Calling setup folder function
	call :SETUP
	ECHO:
		ECHO  .=========================================================.
		ECHO  ^|                                                         ^|
		ECHO  ^|            Diagnostic Data Collection Finished          ^|
		ECHO  ^|                                                         ^|
		ECHO  .=========================================================.
	ECHO:
	EXIT /B 1


	::Setting up directory to save data.
	:SETUP
	
		:: Check if the db2mon*.sql exists else exit.
	    SET FOLDERNAME=db2dump_%date:~-10%_%time:~0,2%%time:~3,2%%time:~6,2%
		
		if %INTERVAL%==30 (		
				if not exist "%CD%\db2mon.sql" ( echo "File: %CD%\db2mon.sql does not exist. Please make sure this file exists." && EXIT /B 1 )
		) ELSE (			
		  if not exist "%CD%\db2monBefore.sql" ( echo "File: %CD%\db2monBefore.sql does not exist. Please make sure this file exists." && EXIT /B 1 )
		  if not exist "%CD%\db2monAfter.sql" ( echo "File: %CD%\db2monAfter.sql does not exist. Please make sure this file exists." && EXIT /B 1 )
		)

		if not exist "%CD%\%FOLDERNAME%" (mkdir "%CD%\%FOLDERNAME%" && ECHO STEP 1^: Folder Creation Completed.)  else (ECHO STEP 1^: Skipping Folder Creation.)
		
		SET DUMPPATH="%CD%\%FOLDERNAME%"


	::Diagonistic data which needs to be collected.
	:DIAG


	:Loop
		
		if %COUNT% GTR %ITERATION% GOTO END_LOOP
			:: Getting date_time
			SET SUBFILENAME=%date:~-10%_%time:~0,2%%time:~3,2%%time:~6,2%
			ECHO.
			ECHO STEP 2^: Collecting Data [ %COUNT%/%It% ]
			
			:: ---------EDIT THIS SECTION FOR DATA Collection-----> ONLY!!!!!!
			
			ECHO STEP 2.1^: Running db2pd commands [ %COUNT%/%It% ]
			start /b db2pd -stack all -rep 10 3                    > %DUMPPATH%\db2pd_stackall_%SUBFILENAME%.out	
			start /b db2 GET SNAPSHOT FOR ALL ON %DBNAME% 		   > %DUMPPATH%\snapshot_all_%SUBFILENAME%.out		
			start /b db2pd -vmstat 5 10                            > %DUMPPATH%\db2pd_vmstat_%SUBFILENAME%.out 
			start /b db2pd -iostat 5 10                            > %DUMPPATH%\db2pd_iostat_%SUBFILENAME%.out 
			start /b db2pd -latches -repeat 2 15                   > %DUMPPATH%\db2pd_latches_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -edu -rep 10 3             > %DUMPPATH%\db2pd_edu_%SUBFILENAME%.out
			start /b db2pd -db %DBNAME%  -edus interval=5 top=10   > %DUMPPATH%\db2pd_edu_top_%SUBFILENAME%.out
			start /b db2pd -winx                                   > %DUMPPATH%\db2pd_winx_%SUBFILENAME%.out
			start /b tasklist          							   > %DUMPPATH%\tasklist_%SUBFILENAME%.out
			start /b wmic cpu 									   > %DUMPPATH%\wmic_cpu_%SUBFILENAME%.out
			start /b wmic diskdrive 							   > %DUMPPATH%\wmic_diskdrive_%SUBFILENAME%.out
			start /b wmic logicaldisk 							   > %DUMPPATH%\wmic_logicaldisk_%SUBFILENAME%.out
			start /b wmic memphysical 							   > %DUMPPATH%\wmic_memphysical_%SUBFILENAME%.out
			
			start /b db2pd -db %DBNAME% -memblocks all top         > %DUMPPATH%\db2pd.memblocks.all_%SUBFILENAME%.out
			start /b db2pd -fmpexechistory n=512 genquery          > %DUMPPATH%\db2pd.fmpexechistory_%SUBFILENAME%.out
			start /b db2pd -workload                               > %DUMPPATH%\db2pd.workload_%SUBFILENAME%.out
			start /b db2pd -db %DBNAME% -utilities -rep 10 3	   > %DUMPPATH%\db2pd_utilities_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -reorg index -rep 10 3	   > %DUMPPATH%\db2pd_reorg_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -runstats -rep 10 3		   > %DUMPPATH%\db2pd_runstats_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -hadr  -repeat 10 3		   > %DUMPPATH%\db2pd_hadr_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -recovery -rep 10 3		   > %DUMPPATH%\db2pd_recovery_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -gfw -rep 10 3			   > %DUMPPATH%\db2pd_gfw_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -fmp -rep 10 3			   > %DUMPPATH%\db2pd_fmp_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -temptable -rep 10 3	   > %DUMPPATH%\db2pd_temptable_%SUBFILENAME%.out 
			
			start /b db2pd -db %DBNAME% -tablespaces -repeat 10 3  > %DUMPPATH%\db2pd_tablespaces_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -bufferpools -repeat 10 3  > %DUMPPATH%\db2pd_bufferpool_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -extent -repeat 10 3	   > %DUMPPATH%\db2pd_extent_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -logs -repeat 10 3		   > %DUMPPATH%\db2pd_logs_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -active -repeat 10 3	   > %DUMPPATH%\db2pd_active_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -dynamic                   > %DUMPPATH%\db2pd_dynamic_%SUBFILENAME%.out
			start /b db2pd -db %DBNAME% -dbptnmem -memsets -mempools      > %DUMPPATH%\db2pd_mem_%SUBFILENAME%.out
			start /b db2pd -db %DBNAME% -tcbstats all                     > %DUMPPATH%\db2pd_tcbstats_%SUBFILENAME%.out
			start /b db2pd -db %DBNAME% -static                           > %DUMPPATH%\db2pd_static_%SUBFILENAME%.out
			start /b db2pd -db %DBNAME% -cleaner -repeat 10 3             > %DUMPPATH%\db2pd_cleaner_%SUBFILENAME%.out 
			start /b db2pd -db %DBNAME% -dirtypages summary  -repeat 10 3 > %DUMPPATH%\db2pd_dirtypages_%SUBFILENAME%.out 
		
			start /b db2pd -osinfo                                        > %DUMPPATH%\db2pd_osinfo_%SUBFILENAME%.out		
			start /b db2 GET SNAPSHOT FOR DYNAMIC SQL ON %DBNAME%         > %DUMPPATH%\snapshot_dynamic_%SUBFILENAME%.out
			
			ECHO STEP 2.2^: Running netstat commands [ %COUNT%/%It% ]
			start /b netstat -nat                                         > %DUMPPATH%\OS_netstat_at_%SUBFILENAME%.out
			start /b netstat -n                                           > %DUMPPATH%\OS_netstat_n_%SUBFILENAME%.out
			start /b netstat -v        									  > %DUMPPATH%\OS_netstat_v_%SUBFILENAME%.out
			start /b netstat -rs       									  > %DUMPPATH%\OS_netstat_rs_%SUBFILENAME%.out
			
			if %APPHDL%==-1 (
				
				ECHO STEP 2.3^: Collecting data for every apphdl [ %COUNT%/%It% ]
				start /b db2pd -agents   -repeat 10 3                               > %DUMPPATH%\db2pd_agents_%SUBFILENAME%.out				
				start /b db2pd -db %DBNAME% -apinfo all 							> %DUMPPATH%\db2pd_apinfo_%SUBFILENAME%.out
				start /b db2pd -db %DBNAME% -apinfo metrics                         > %DUMPPATH%\db2pd_apinfo_metrics_%SUBFILENAME%.out
				start /b db2pd -db %DBNAME% -applications -repeat 10 3			    > %DUMPPATH%\db2pd_applications_%SUBFILENAME%.out 
				start /b db2pd -db %DBNAME% -transactions -repeat 10 3			    > %DUMPPATH%\db2pd_transactions_%SUBFILENAME%.out 
				start /b db2pd -db %DBNAME% -sort -repeat 10 3                      > %DUMPPATH%\db2pd_sort_%SUBFILENAME%.out 
				start /b db2pd -db %DBNAME% -locks showlocks waits -wlocks detail -repeat 10 3    > %DUMPPATH%\db2pd_locks_%SUBFILENAME%.out 
				start /b db2 GET SNAPSHOT FOR APPLICATIONS ON %DBNAME% GLOBAL 		> %DUMPPATH%\snapshot_applications_%SUBFILENAME%.out	
				ECHO STEP 2.4^: Running db2trc perfcount for 20 seconds. DO NOT PRESS CTRL+C [ %COUNT%/%It% ]
				db2trc on -perfcount -t -edu
				timeout /T 20 /NOBREAK
				db2trc dmp %DUMPPATH%\trc.perfcount.%SUBFILENAME%.dmp
				db2trc off						
				ECHO STEP 2.5^: Running db2trc sqlbfix - Dumping 2 times every 5 seconds. DO NOT PRESS CTRL+C [ %COUNT%/%It% ]			
				db2trc on -Madd sqlbfix 
				timeout /T 5 /NOBREAK
				db2trc dmp %DUMPPATH%\trc1.sqlbfix.%SUBFILENAME%.dmp 
				timeout /T 5 /NOBREAK
				db2trc dmp %DUMPPATH%\trc2.sqlbfix.%SUBFILENAME%.dmp 
				db2trc off
				
			) ELSE (
				
				ECHO STEP 2.3^: Collecting data for apphdl %APPHDL% [ %COUNT%/%It% ]
				start /b db2pd -agents app=%APPHDL% -repeat 10 3                     > %DUMPPATH%\db2pd_agents_%SUBFILENAME%.out
				start /b db2pd -db %DBNAME% -apinfo %APPHDL% metrics -repeat 10 3    > %DUMPPATH%\db2pd_apinfo_metrics_%SUBFILENAME%.out
				start /b db2pd -db %DBNAME% -applications %APPHDL% -repeat 10 3		 > %DUMPPATH%\db2pd_applications_%SUBFILENAME%.out 
				start /b db2pd -db %DBNAME% -transactions %APPHDL% -repeat 10 3		 > %DUMPPATH%\db2pd_transactions_%SUBFILENAME%.out 
				start /b db2pd -db %DBNAME% -sort apphdl=%APPHDL% -repeat 10 3       > %DUMPPATH%\db2pd_sort_%SUBFILENAME%.out 
				start /b db2pd -db %DBNAME% -locks apphdl=%APPHDL% showlocks waits -wlocks detail -repeat 10 3    > %DUMPPATH%\db2pd_locks_%SUBFILENAME%.out 
				start /b db2 GET SNAPSHOT FOR APPLICATIONS agentid %APPHDL% ON %DBNAME% GLOBAL                    > %DUMPPATH%\snapshot_applications_%SUBFILENAME%.out
				
				ECHO STEP 2.4^: Running db2trc for apphdl %APPHDL% - Dumping 3 times every 10 seconds. DO NOT PRESS CTRL+C [ %COUNT%/%It% ]
				db2trc on -t -apphdl %APPHDL%
				timeout /T 10 /NOBREAK
				db2trc dmp %DUMPPATH%\trc1.ROW.%SUBFILENAME%.dmp
				timeout /T 10 /NOBREAK
				db2trc dmp %DUMPPATH%\trc2.ROW.%SUBFILENAME%.dmp
				timeout /T 10 /NOBREAK
				db2trc dmp %DUMPPATH%\trc3.ROW.%SUBFILENAME%.dmp
				db2trc off 
				
				ECHO STEP 2.5^: Running CDE Trace for apphdl %APPHDL% - Dumping 3 times every 10 seconds. DO NOT PRESS CTRL+C [ %COUNT%/%It% ]
				db2trc on -t -Madd CDE_PERF_TRACE -apphdl %APPHDL%
				timeout /T 10 /NOBREAK 
				db2trc dmp %DUMPPATH%\trc1.CDE.%SUBFILENAME%.dmp
				timeout /T 10 /NOBREAK 
				db2trc dmp %DUMPPATH%\trc2.CDE.%SUBFILENAME%.dmp
				timeout /T 10 /NOBREAK 
				db2trc dmp %DUMPPATH%\trc3.CDE.%SUBFILENAME%.dmp
				db2trc off 
			)
					
			ECHO STEP 3^: Running Db2mon for %INTERVAL% seconds. DO NOT PRESS CTRL+C [ %COUNT%/%It% ]
			db2 -v connect to %DBNAME%
			
			if %INTERVAL%==30 (		
				db2 -tvf "%CD%"\db2mon.sql             > %DUMPPATH%\db2mon_report_%SUBFILENAME%.out
			) ELSE (			
				db2 +c -tvf "%CD%"\db2monBefore.sql > %DUMPPATH%\db2monBefore_%SUBFILENAME%.out
				timeout /T %INTERVAL% /NOBREAK
				db2 +c -tvf "%CD%"\db2monAfter.sql > %DUMPPATH%\db2mon_report_%SUBFILENAME%.out
			)
			
			db2 -v commit work
			db2 -v connect reset
        
			ECHO STEP 4^: Collecting explain_from_section from db2mon - %DUMPPATH%\db2mon_report_%SUBFILENAME%.out.
			@echo off
			setlocal EnableDelayedExpansion
            
			for /f "delims=" %%i in ('type "%DUMPPATH%\db2mon_report_%SUBFILENAME%.out"') do (
				set "Line=%%i"
				set "First13=!Line:~0,13!"
				if "!First13!"=="EXECUTABLE_ID" (
					rem echo !Line!
				    rem Extract the next word
					for /f "tokens=2" %%j in ("!Line!") do (
						set execid=%%j
						echo Gathering Explain of section for EXECUTABLE_ID: !execid!
						rem Remove the single quotes
						set "fmtexecid=!execid:'=!"
						if not exist "%DUMPPATH%"\db2mon_exfmt_!fmtexecid!_%SUBFILENAME%.out (
							db2 connect to %DBNAME%
							db2 "call explain_from_section( !execid!, 'M', null, -1, '', ?,?,?,?,? )" > %DUMPPATH%\db2mon_explain_from_section_!fmtexecid!_%SUBFILENAME%.out
							db2exfmt -d %DBNAME%  -1 -o %DUMPPATH%\db2mon_exfmt_!fmtexecid!_%SUBFILENAME%.out
						) ELSE (
							echo  db2mon1 "%DUMPPATH%"\db2mon_exfmt_!fmtexecid!_%SUBFILENAME%.out Already exists.
						)
					)
				)
			)
			set "FoundStart="
			for /f "tokens=*" %%i in ('type "%DUMPPATH%\db2mon_report_%SUBFILENAME%.out"') do (

				set "Line=%%i"
				REM echo !Line!
				set "First13=!Line:~0,13!"
				REM echo !First13!
				if "!First13!"=="INF#EXPLN: St" (
					set "FoundStart=1"
					 REM echo !Line!		
				) else if defined FoundStart (
					REM echo !Line!
					echo !Line! | findstr "x'0" >nul
					if !errorlevel! == 0 (
							REM echo !Line!
							rem Extract the next word
							for /f "tokens=2" %%j in ("!Line!") do (
								set execid=%%j
								rem Remove the single quotes
								set "fmtexecid=!execid:'=!"
								echo Gathering Explain of section for EXECUTABLE_ID: !execid!
								if not exist "%DUMPPATH%"\db2mon_exfmt_!fmtexecid!_%SUBFILENAME%.out (
									db2 connect to %DBNAME%
									db2 "call explain_from_section( !execid!, 'M', null, -1, '', ?,?,?,?,? )" > %DUMPPATH%\db2mon_explain_from_section_!fmtexecid!_%SUBFILENAME%.out
									db2exfmt -d %DBNAME%  -1 -o "%DUMPPATH%"\db2mon_exfmt_!fmtexecid!_%SUBFILENAME%.out
								) ELSE (
									echo  db2mon2 "%DUMPPATH%"\db2mon_exfmt_!fmtexecid!_%SUBFILENAME%.out Already exists.
								)
							)	
					)
					echo !Line! | findstr "record(s) selected." > nul
					if !errorlevel! == 0 (
					set "FoundStart="
					goto :ExitDb2monExfmtLoop
				   )
				)
			)
			:ExitDb2monExfmtLoop
			endlocal
			
			:: Control of Main Looping
			ECHO END OF ITERATION %COUNT% of %It% . DO NOT PRESS CTRL+C.
			
			SET /a COUNT+=1
			if %COUNT% LEQ %It%  ( timeout /T %INTERVAL% /NOBREAK )
			GOTO Loop
		:END_LOOP
		
		ECHO STEP 5^: Formatting db2pd_Stackall
		
		setlocal enabledelayedexpansion

		for %%F in ("%DUMPPATH%\db2pd_stackall_*.out") do (
			set "binfound="
			for /f "tokens=*" %%A in ('findstr "stack.bin" "%%F"') do (
				if not defined binfound (
						for %%B in (%%A) do (
						set "lastword=%%B"
						)
						for %%C in (!lastword!) do (
						set "filename=%%~nC"
						)

					REM echo Last word containing "bin" in %%F: !lastword!
					REM echo Filename: !filename!
					if not exist "%DUMPPATH%"\db2pd_stackall_fmt_!filename!.fmt (
						REM echo db2pd_stackall_fmt_!filename!.fmt does not exist in %DUMPPATH%
						db2xprt !lastword! > "%DUMPPATH%"\db2pd_stackall_fmt_!filename!.fmt 
					) ELSE (
						echo db2pd_stackall_fmt_!filename!.fmt Already exist in %DUMPPATH%
					)
					set "binfound=1"
				)
			)
		)
		
		ECHO STEP 6^: Formatting Trace Files
		
		if %APPHDL%==-1 (
			for %%F in ("%DUMPPATH%\trc.perfcount.*.dmp") do (
				for %%C in (%%F ) do (
					set "filename=%%~nC"
					echo Formatting trace file %%F
					ddb2trc perffmt %%F %DUMPPATH%\!filename!.perffmt	
				)
			)

			for %%F in ("%DUMPPATH%\trc*.sqlbfix.*.dmp") do (
				for %%C in (%%F ) do (
					set "filename=%%~nC"
					echo Formatting trace file %%F
					db2trc fmt %%F "%DUMPPATH%"\!filename!.fmt
					db2trc flw -t %%F "%DUMPPATH%"\!filename!.flw
				)
			)
		
		) ELSE (
			for %%F in ("%DUMPPATH%\trc*.ROW.*.dmp") do (
				for %%C in (%%F ) do (
					set "filename=%%~nC"
					echo Formatting trace file %%F
					db2trc flw -t %%F "%DUMPPATH%"\!filename!.flw
					db2trc fmt %%F "%DUMPPATH%"\!filename!.fmt
					db2trc flw -rds -t %%F "%DUMPPATH%"\!filename!.rds
					db2trc perfrep -rds -g -sort timeelapsed %%F "%DUMPPATH%"\!filename!.perfrep
				)
			)

			for %%F in ("%DUMPPATH%\trc*.CDE.*.dmp") do (
				for %%C in (%%F ) do (
					set "filename=%%~nC"
					echo Formatting trace file %%F
					db2trc fmt %%F "%DUMPPATH%"\!filename!.fmt
				)
			)
		)
		endlocal	
		
		ECHO STEP 7^: Collecting REORGCHK Data
		db2 connect to %DBNAME%
		db2 +c -v "call REORGCHK_TB_STATS('T','ALL')" > %DUMPPATH%\REORGCHK_TB_STATS_%SUBFILENAME%.out
		db2 +c -v "select table_schema, table_name,DATAPARTITIONNAME,card,overflow,  f1,  f2,  f3,  reorg  from SESSION.TB_STATS where REORG LIKE '%%*%%'" > %DUMPPATH%\NeedTSReorg_%SUBFILENAME%.out
		db2 +c -v "CALL SYSPROC.REORGCHK_IX_STATS('T', 'ALL')" > %DUMPPATH%\REORGCHK_IX_STATS_%SUBFILENAME%.out
		db2 +c -v "SELECT TABLE_SCHEMA,TABLE_NAME,INDEX_SCHEMA,INDEX_NAME,DATAPARTITIONNAME,INDCARD,F4,F5,F6,F7,F8,REORG FROM SESSION.IX_STATS  WHERE REORG LIKE '%%*%%'" > %DUMPPATH%\NeedTXReorg_%SUBFILENAME%.out
		db2 -v "select TABSCHEMA,TABNAME,CREATE_TIME,ALTER_TIME,INVALIDATE_TIME,STATS_TIME,COLCOUNT,TABLEID,TBSPACEID,CARD,NPAGES,MPAGES,FPAGES,OVERFLOW,LASTUSED,TABLEORG from syscat.tables WHERE TABSCHEMA NOT LIKE 'SYS%%' AND TYPE = 'T' order by STATS_TIME,TABSCHEMA,TABNAME " > %DUMPPATH%\syscat_tables_%SUBFILENAME%.out
		db2 connect reset
        
