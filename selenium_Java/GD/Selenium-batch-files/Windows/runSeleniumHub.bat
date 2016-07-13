@ECHO OFF
ECHO *******************************
ECHO * WINDOWS SELENIUM SERVER HUB *
ECHO *******************************
ECHO.

d:
cd %CD%
ECHO Starting hub
call java -jar selenium-server-standalone-2.42.2.jar -role hub
ECHO.
PAUSE
