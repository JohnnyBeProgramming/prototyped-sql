@echo off

rem db_user=
rem db_pass=
set db_sspi=1
set db_name=ProtoDB
set db_host=localhost
rem restore_pre=Admin\RestoreDB.sql
rem restore_bak=%CD%\Backups\Northwind.bak
set migrate_exe=..\DotNet and CSharp\Prototyped.net\Build\Debug\proto.exe
set migrate_arg=sql init -conn:ProtoDB
set migrate_log=SqlUpdates.log
set results_pre=Results\Before
set results_post=Results\After
set sqlcmd=sqlcmd -S "%db_host%"
set sqlarg=-s"," -W -w 999

if "%1"=="-debug" set "debug=1"

echo -------------------------------------------------------------------------------
echo  Running SQL Scripts and Queries
echo -------------------------------------------------------------------------------
if not "%db_sspi%"=="" set sqlcmd=%sqlcmd% -E
if not "%db_user%"=="" set sqlcmd=%sqlcmd% -U "%db_user%" 
if not "%db_pass%"=="" set sqlcmd=%sqlcmd% -P "%db_pass%"

echo  - Clearing old result sets...
if exist "%migrate_log%" del "%migrate_log%" /Q > NUL

:data_clear_pre
IF NOT EXIST "%results_pre%" goto data_clear_post
del "%results_pre%\*.*" /s /q > NUL
rd "%results_pre%" /s /q > NUL

:data_clear_post
IF NOT EXIST "%results_post%" goto db_restore
del "%results_post%\*.*" /s /q > NUL
rd "%results_post%" /s /q > NUL

:db_restore
IF NOT EXIST "%restore_bak%" goto db_snapshot_pre
IF NOT EXIST "%restore_pre%" goto db_snapshot_pre
echo  - Restoring original database... & if "%debug%"=="1" echo  - Press any key to start... & pause > nul
%sqlcmd% %sqlarg% -d "master" -v TargetName="%db_name%" -v BackupFile="%restore_bak%" -i "Admin\NoCounts.sql","%restore_pre%" -o "%migrate_log%" || goto error
echo  - Database Restored successfully!


:db_snapshot_pre
rem ********************************************************************************
set results_db=%db_name%
set results_dir=%results_pre%
call :run_queries
rem ********************************************************************************

:db_migrate
echo -------------------------------------------------------------------------------
if not exist "%migrate_exe%" (
	echo  ! [ Warning ] Target exe not found! Press any key to continue... 
	pause > nul 
	goto db_migrate_done
)
echo  - Running database updates... & if "%debug%"=="1" echo  - Press any key to start... & pause > nul
echo  - Upgrading Database > "%migrate_log%"
echo Command: %migrate_exe% >> "%migrate_log%"
echo Params : %migrate_arg% >> "%migrate_log%"
if "%debug%"=="1" goto db_exe_gen_debug

rem ********************************************************************************

:db_exe_gen_full
goto db_exe_gen_start

:db_exe_gen_debug
goto db_exe_gen_start

:db_exe_gen_start
for /f "delims=" %%i in ("%migrate_exe%") do set "myexe=%%~nxi"
echo    + %myexe% %migrate_arg%		& "%migrate_exe%" %migrate_arg% 
rem  if not errorlevel 0 goto db_exe_gen_failed

:db_exe_gen_sql
if not exist "Migrations" echo    ! SQL scripts folder 'Migrations\' not found. Skipping... & goto db_exe_gen_success
call :run_migrations || goto db_exe_gen_failed

if errorlevel 1 goto db_exe_gen_failed
goto db_exe_gen_success

rem ********************************************************************************
:db_migrate_done
goto db_exe_gen_done

rem ********************************************************************************

:db_exe_gen_failed
echo  - Warning: Database upgrade failed! See logs for  details...
call "%migrate_log%"
goto error

:db_exe_gen_success
echo  - Updates completed successfully.
goto db_exe_gen_done

:db_exe_gen_done
echo -------------------------------------------------------------------------------


:db_snapshot_post
rem ********************************************************************************
set results_db=%db_name%
set results_dir=%results_post%
call :run_queries
rem ********************************************************************************


goto done

:error
echo -------------------------------------------------------------------------------
echo  [ Error ] An error occurred while executing this script
echo -------------------------------------------------------------------------------
pause
goto end

:done
echo -------------------------------------------------------------------------------
echo  [ Done ] 
echo -------------------------------------------------------------------------------
echo  - Press any key to continue... & timeout 10 > nul

goto end
rem *********************************************************************************
rem *********************************************************************************

:run_queries
rem *********************************************************************************
rem *** Iterate all subfolders and execute SQL scripts (to output folder)
rem *********************************************************************************
echo  - Creating snapshots on [ %results_db% ] to [ %results_dir% ] & if "%debug%"=="1" echo  - Press any key to start... & pause > nul
set base_dir=%CD%\
set script_dir=%base_dir%Queries\
setlocal DisableDelayedExpansion
if not exist "Queries" goto :eof
cd Queries
for /r %%i in (*.sql) do (
	set fileName=%%i
	setlocal EnableDelayedExpansion
	set fileName=!fileName:%script_dir%=!
	set fileOutput=!fileName:.sql=.csv!
	echo    + !fileOutput!
	set data_path_file="%base_dir%%results_dir%\%results_db%\!fileOutput!"
	for %%A in (!data_path_file!) do (
    	set data_path_folder=%%~dpA
	)
	IF NOT EXIST "!data_path_folder!" md "!data_path_folder!"
	%sqlcmd% %sqlarg% -d "%results_db%" -i "%base_dir%\Admin\NoCounts.sql","%script_dir%!fileName!" -o "%base_dir%%results_dir%\%results_db%\!fileOutput!"
	endlocal	
)
cd ..
goto :eof
rem *********************************************************************************

:run_migrations
rem *********************************************************************************
rem *** Iterate all subfolders and execute SQL scripts
rem *********************************************************************************
echo  - Running SQL migrations on [ %results_db% ] 
set base_dir=%CD%\
set script_dir=%base_dir%Migrations\
setlocal DisableDelayedExpansion
if not exist "Migrations" goto :eof
cd Migrations
for /r %%i in (*.sql) do (
	set fileName=%%i
	setlocal EnableDelayedExpansion
	set fileName=!fileName:%script_dir%=!
	set fileOutput=!fileName:.sql=.log!
	echo    + !fileName!
	%sqlcmd% %sqlarg% -d "%results_db%" -i "%base_dir%\Admin\NoCounts.sql","%script_dir%!fileName!" || goto error
	endlocal	
)
cd ..
goto :eof
rem *********************************************************************************

:end