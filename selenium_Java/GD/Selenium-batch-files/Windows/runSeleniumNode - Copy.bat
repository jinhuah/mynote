@ECHO OFF
ECHO *********************************
ECHO * WINDOWS SELENIUM SERVER NODE  *
ECHO *********************************
ECHO.
ECHO Starting node
cd %CD%
call java ^
 -Dos.name=windows ^
 -Dwebdriver.chrome.driver=chromedriver.exe ^
 -Dwebdriver.ie.driver=IEDriverServer.exe  ^
 -jar selenium-server-standalone-2.42.2.jar ^
 -role node -hub http://localhost:4444/grid/register ^
 -browser "browserName=internet explorer,version=11,platform=WINDOWS" ^
 -browser "browserName=chrome,platform=WINDOWS" ^
 -browser "browserName=firefox,platform=WINDOWS"
ECHO.
PAUSE
