#!/bin/bash
# start-macos.sh - Start PDF OCR application on macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JAR_FILE="$SCRIPT_DIR/target/pdf-ocr-1.0-SNAPSHOT.jar"

if [ ! -f "$JAR_FILE" ]; then
    echo "FEHLER: JAR-Datei nicht gefunden: $JAR_FILE"
    echo "Bitte zuerst kompilieren: mvn clean package"
    exit 1
fi

java -jar "$JAR_FILE" "$@"
