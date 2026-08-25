@echo off
REM start-windows.bat - Build und Start der PDF OCR Applikation mit Java 25 und Maven 3.9.16
SETLOCAL EnableDelayedExpansion

set SCRIPT_DIR=%~dp0
set JAR_FILE=%SCRIPT_DIR%target\pdf-ocr-1.0-SNAPSHOT.jar

REM =========================================================================
REM CONFIGURATION: Pfade zu Java 25 und Maven 3.9.16 definieren
REM =========================================================================
set JAVA_HOME_25=c:\dev\jdk\jdk-25.0.2+10
set MAVEN_HOME_3=c:\dev\Tools\maven\apache-maven-3.9.16

set JAVA_EXEC="%JAVA_HOME_25%\bin\java.exe"
set MAVEN_EXEC="%MAVEN_HOME_3%\bin\mvn.cmd"

REM Temporaer JAVA_HOME und M2_HOME fuer diese Session umstellen
set JAVA_HOME=%JAVA_HOME_25%
set MAVEN_HOME=%MAVEN_HOME_3%
set M2_HOME=%MAVEN_HOME_3%

REM Pfad so anpassen, dass zuerst unser Java 25 und Maven 3.9.16 gefunden werden
set PATH=%JAVA_HOME_25%\bin;%MAVEN_HOME_3%\bin;%PATH%

REM ZUSAETZLICH: Deaktiviert die SSL-Validierung global in der JVM fuer Maven (behebt den Zertifikatsfehler beim Dependency-Download)
set MAVEN_OPTS=-Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true -Dmaven.wagon.http.ssl.ignore.validity.dates=true

echo === PDF OCR Starter ===

REM 1. Pruefen, ob Java 25 an der angegebenen Stelle existiert
if not exist %JAVA_EXEC% (
    echo [FEHLER] Java 25 wurde unter folgendem Pfad nicht gefunden:
    echo          %JAVA_HOME_25%
    echo Bitte den Installationspfad in dieser Batch-Datei ueberpruefen.
    pause
    exit /b 1
)

REM 2. Pruefen, ob Maven 3.9.16 an der angegebenen Stelle existiert
if not exist %MAVEN_EXEC% (
    echo [FEHLER] Maven 3.9.16 wurde unter folgendem Pfad nicht gefunden:
    echo          %MAVEN_HOME_3%
    echo Bitte den Installationspfad in dieser Batch-Datei ueberpruefen.
    pause
    exit /b 1
)

REM 3. Existierende JAR-Datei loeschen, um einen garantiert sauberen Rebuild zu erzwingen
if exist "%JAR_FILE%" (
    del "%JAR_FILE%" /f /q
)

echo [INFO] Starte automatischen Build mit Java 25 und Maven 3.9.16...
echo [INFO] SSL-Sicherheitspruefungen werden global fuer das interne Signal Iduna Repo umgangen...

REM Fuehrt den Maven-Build aus (MAVEN_OPTS greift hier automatisch)
call %MAVEN_EXEC% clean package

REM Erneute Pruefung nach dem Build-Versuch
if not exist "%JAR_FILE%" (
    echo.
    echo [FEHLER] Build fehlgeschlagen. Die JAR-Datei konnte nicht erstellt werden.
    echo Bitte pruefen Sie die obigen Maven-Fehlermeldungen.
    pause
    exit /b 1
)
echo [ERFOLG] Build war erfolgreich!
echo.

REM 4. Applikation starten (mit aktiviertem Native Access fuer Java 25)
echo [INFO] Starte PDF OCR Anwendung mit Java 25...
echo -----------------------------------------------------------------------
%JAVA_EXEC% --enable-native-access=ALL-UNNAMED -jar "%JAR_FILE%" %*

ENDLOCAL
