#!/bin/bash
echo   "********************************"
echo   "*                              *"
echo   "*    INSIGHT SAIKU WEB UI      *"
echo   "*      Automation Test         *"
echo   "*         on Linux             *"
echo   "*                              *"
echo   "********************************"

javaTestProjectPath="/home/ubuntu/insight-autotest/saiku-test-source-files"
javaSeleniumJarPath="/home/ubuntu/Downloads/selenium-2.44.0"

cd ~/insight-autotest/saiku-test-source-files
cd $javaTestProjectPath

# path="/usr/local/java/jdk1.8.0_25/bin/"

# set the classpath, this tells java where to look for the library files, and the project bin folder is added as it will store the .class file after compile.
export CLASSPATH="$javaSeleniumJarPath/*:$javaSeleniumJarPath/libs/*:$javaTestProjectPath/bin/"

# compile the dataProviderExample.java file, the -d parameter tells javac where to put the .class file that is created on compile.
javac -verbose $javaTestProjectPath/src/main/* $javaTestProjectPath/src/query/*  -d $javaTestProjectPath/bin/

# check that java compiles files without problems.
if [[ $? != 0 ]] 
then 
    echo "java compiling failed!"
    exit 1
fi

# execute testng framework by giving the path of the testng.xml file as a parameter. The xml file tells testng what test to run.
java org.testng.TestNG $javaTestProjectPath/testlaunch.xml