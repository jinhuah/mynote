

REM Start Selenium remote driver hub
cd C:\Users\Jinhua\Desktop\Selenium
call runSeleniumHub.bat
:quit
endlocal

REM launch suiku webserver
cd C:\Users\Jinhua\test\downloads\saiku-server
call start-saiku.bat

REM Start Saiku UI automation test
REMcall C:\Users\Jinhua\test\Saiku-UI-test\run-auto-test-from-command-line.bat