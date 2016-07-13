@echo off
echo   ********************************
echo   *                              *
echo   *    INSIGHT SAIKU WEB UI      * 
echo   *      AUTOMATION TEST         *
echo   *                              *
echo   ********************************
REM create variables that stores the project folder path and Selenium Jar path. This variables will be used in the subsequent statements.
set javaTestProjectPath=D:\work\eclipse-workspace\CI-Test-Jinhua
set javaSeleniumJarPath=D:\work\Tools\selenium-2.41.0

REM move to the project folder
c:
cd %javaTestProjectPath%

REM set path to dir that contains javac.exe and java.exe
set path=C:\Program Files\Java\jdk1.8.0\bin

REM set the classpath, this tells java where to look for the library files, and the project bin folder is added as it will store the .class file after compile
set classpath=%javaSeleniumJarPath%\*;%javaSeleniumJarPath%\libs\*;%javaTestProjectPath%\bin

REM compile the dataProviderExample.java file, the -d parameter tells javac where to put the .class file that is created on compile
javac -verbose %javaTestProjectPath%\src\login\* %javaTestProjectPath%\src\main\* %javaTestProjectPath%\src\query\*  -d %javaTestProjectPath%\bin

REM execute testng framework by giving the path of the testng.xml file as a parameter. The xml file tells testng what test to run
java org.testng.TestNG %javaTestProjectPath%\testngtmp.xml

