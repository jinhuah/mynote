@echo off

REM Set date format
@For /F "tokens=1,2,3 delims=/ " %%A in ('Date /t') do @( 
Set Day=%%A
Set Month=%%B
Set Year=%%C
Set DateNow=%%C%%B%%A
)

REM Set time format
@For /F "tokens=1,2,3 delims=: " %%A in ('Time /t') do @( 
Set Hour=%%A
Set Min=%%B
Set TimeNow=%%A%%B
)

Set All=%DateNow%%TimeNow%
xcopy "D:\work\eclipse-workspace\CI-Test-Jinhua\test-output\*.*" "\\NAS1\Public\jinhua\TestResults\test-output-%All%\" /D /E /C /R /I /K /Y 

REM C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe C:\Users\Jinhua\Test\Saiku-UI-test\sendEmailWithAttachment.ps1
