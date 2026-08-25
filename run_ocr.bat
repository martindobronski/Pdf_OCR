@echo off
REM run_ocr.bat - Startet die vorkompilierte PDF OCR Applikation mit Java 25
SETLOCAL EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set JAR_FILE=%SCRIPT_DIR%target\pdf-ocr-1.0-SNAPSHOT.jar

REM =========================================================================
REM CONFIGURATION: Pfad zu Java 25 definieren (Maven wird nicht benoetigt)
REM =========================================================================
set JAVA_HOME_25=c:\dev\jdk\jdk-25.0.2+10
set JAVA_EXEC="%JAVA_HOME_25%\bin\java.exe"

REM JAVA_HOME und PATH temporaer fuer diese Session auf Java 25 umbiegen
set JAVA_HOME=%JAVA_HOME_25%
set PATH=%JAVA_HOME_25%\bin;%PATH%

echo === PDF OCR Runner ===

REM 1. Pruefen, ob Java 25 an der angegebenen Stelle existiert
if not exist %JAVA_EXEC% (
    echo [FEHLER] Java 25 wurde unter folgendem Pfad nicht gefunden:
    echo          %JAVA_HOME_25%
    echo Bitte den Installationspfad in dieser Batch-Datei ueberpruefen.
    pause
    exit /b 1
)

REM 2. Pruefen, ob die fertige JAR-Datei existiert
if not exist "%JAR_FILE%" (
    echo [FEHLER] JAR-Datei nicht gefunden: %JAR_FILE%
    echo Bitte kompilieren Sie das Projekt zuerst mit "start-windows.bat"
    pause
    exit /b 1
)

REM 3. Applikation direkt starten (mit aktiviertem Native Access fuer Java 25)
echo [INFO] Starte PDF OCR Anwendung mit Java 25...
echo -----------------------------------------------------------------------
%JAVA_EXEC% --enable-native-access=ALL-UNNAMED -jar "%JAR_FILE%" %*

ENDLOCAL
