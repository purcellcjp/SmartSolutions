@echo off

:: This enables delayed expansion, which is necessary for variable manipulation within a for loop
setlocal enabledelayedexpansion

:: Get current date and time and format them
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do (
    set "month=%%b"
    set "day=%%c"
    set "year=%%d"
)
for /f "tokens=1-3 delims=:. " %%a in ("%time%") do (
    set "hour=%%a"
    set "minute=%%b"
    set "second=%%c"
)

:: Pad single-digit values with a leading zero if necessary
if "%month:~0,1%"==" " set "month=0%month:~1,1%"
if "%day:~0,1%"==" " set "day=0%day:~1,1%"
if "%hour:~0,1%"==" " set "hour=0%hour:~1,1%"
if "%minute:~0,1%"==" " set "minute=0%minute:~1,1%"
if "%second:~0,1%"==" " set "second=0%second:~1,1%"

:: Construct the timestamp
set "timestamp=%year%%month%%day%_%hour%%minute%%second%"

:: Send attachment report via SMTP Gateway
C:
CD C:\Reports
:: Define directory to search


:: Define string to find and string to replace it with
SET "prn_extension=.PRN"
SET "tab_extension=.TAB"
SET "txt_extension=.txt"
SET "csv_extension=.csv"

SET "string_to_replace=_%timestamp%"

:: Loop through all files in directory
FOR %%a IN (*.*) DO (

   SET "old_filename=%%a"   :: get full file name with extension
   SET "extension=%%~xa"

   IF /i "!extension!"=="%tab_extension%" (
      REN "%%a" "!old_filename:%tab_extension%=%string_to_replace%%txt_extension%!"

   ) ELSE IF /i "!extension!"=="%prn_extension%" (
         REN "%%a" "!old_filename:%prn_extension%=%string_to_replace%%csv_extension%!"
   )

)

:: Run SendReport program
CD C:\FTP_DATA\EXEDEV\Batch
java -classpath C:\FTP_DATA\EXEDEV\SendReport\out\production\SendReport;C:\FTP_DATA\EXEDEV\SendReport\lib\javax.mail.jar SendReport

CD C:\Reports

exit /b 0
