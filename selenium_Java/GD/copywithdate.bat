@echo off

REM Set date format
@For /F "tokens=1,2,3 delims=/ " %%A in ('Date /t') do @( 
Set Day=%%A
Set Month=%%B
Set Year=%%C
Set DATE=%%C%%B%%A
)

REM Set time format
for /F "tokens=5-8 delims=:. " %%i in ('echo.^| time ^| find "current" ') do set t=%%i%%j
set t=%t%_
if "%t:~3,1%"=="_" set t=0%t%
set t=%t:~0,4%

REM Set date+time
set All=%DATE%%t%

@For /F "tokens=1,2,3 delims=: " %%A in ('Time /t') do @( 
Set Hour=%%A
Set Min=%%B
Set Allm=%%A%%B
)
echo %Allm%



REM copy C:\Users\Jinhua\Test\Saiku-UI-test\try-batch\test.txt C:\Users\Jinhua\Test\Saiku-UI-test\try-batch\test%All%.txt
