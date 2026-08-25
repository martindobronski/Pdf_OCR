@echo off
REM start-windows.bat - Start PDF OCR application on Windows

set SCRIPT_DIR=%~dp0
set JAR_FILE=%SCRIPT_DIR%target\pdf-ocr-1.0-SNAPSHOT.jar

if not exist "%JAR_FILE%" (
    echo FEHLER: JAR-Datei nicht gefunden: %JAR_FILE%
    echo Bitte zuerst kompilieren: mvn clean package
    exit /b 1
)

java -jar "%JAR_FILE%" %*
