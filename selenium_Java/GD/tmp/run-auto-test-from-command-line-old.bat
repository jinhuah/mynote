@echo off
REM create variable that stores the project folder path. This variable will used in the subsequent statements.
set javaTestProjectPath=C:\Users\Jinhua\workspace\Saiku-UI-Tests

REM move to the project folder
c:
cd %javaTestProjectPath%

REM set path to dir that contains javac.exe and java.exe
set path=C:\Program Files\Java\jdk1.7.0_21\bin

REM set the classpath, this tells java where to look for the library files, the project bin folder is added as it will store the .class file after compile
set classpath=%javaTestProjectPath%\bin;C:\Users\Jinhua\test\selenium-2.32.0\libs\junit-dep-4.11.jar;C:\Users\Jinhua\test\selenium-2.32.0\selenium-java-2.32.0.jar;C:\Users\Jinhua\test\selenium-2.32.0\selenium-java-2.32.0-srcs.jar;C:\Users\Jinhua\test\selenium-2.32.0\libs\testng-6.8.jar;C:\Users\Jinhua\test\selenium-2.32.0\libs\jcommander-1.29.jar;C:\Users\Jinhua\test\selenium-2.32.0\libs\*

REM compile the dataProviderExample.java file, the -d parameter tells javac where to put the .class file that is created on compile
javac -verbose %javaTestProjectPath%\src\login\* %javaTestProjectPath%\src\main\* %javaTestProjectPath%\src\query\*  -d %javaTestProjectPath%\bin

REM execute testng framework by giving the path of the testng.xml file as a parameter. The xml file tells testng what test to run
java org.testng.TestNG %javaTestProjectPath%\testng.xml

