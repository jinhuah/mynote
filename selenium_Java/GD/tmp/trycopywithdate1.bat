:: 
:: Copies Files Modified or Created Today
::  to the Upload Directory 
::
@ECHO OFF

ECHO. | DATE | FIND /I "Current" >: C:\BATCH\CUR-DATE.BAT
ECHO @SET CUR-DATE=%%4 >: C:\BATCH\CURRENT.BAT
CALL C:\BATCH\CUR-DATE.BAT

REM Copies Files based on Today's Date ("NUL" Hides Screen Messages)
XCOPY C:\Users\Jinhua\test\Saiku-UI-test\Saiku-UI-2.4-bugs.txt C:\Users\Jinhua\test\Saiku-UI-test /D:%CUR-DATE% > NUL

CALL C:\BATCH\DR.BAT C:\UPLOAD

REM Removes the Date Variable From the Environment
SET CUR-DATE=

REM Deletes the temporary Batch Files
DEL CUR-DATE.BAT
DEL CURRENT.BAT