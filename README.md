# PDF OCR Texterkennung

Java-Programm zur automatisierten Texterkennung von PDF-Dateien. Das Programm liest alle PDF-Dateien aus einem Input-Verzeichnis, führt eine OCR-Texterkennung durch und speichert den erkannten Text in einem Output-Verzeichnis.

## Features

- **Direkte Textextraktion**: Bei textbasierten PDFs wird der Text direkt extrahiert
- **OCR-Texterkennung**: Bei bildbasierten PDFs wird Tesseract OCR verwendet
- **Mehrsprachig**: Unterstützt Deutsch und Englisch
- **Einfache Bedienung**: Kommandozeilen-basiert
- **Keine externen Abhängigkeiten**: Tesseract OCR ist in der JAR gebündelt

## Voraussetzungen

- Java 17 oder höher
- Maven (nur zum Kompilieren)

## Kompilieren

```bash
mvn clean package
```

## Verwendung

### Standard-Verzeichnisse

```bash
java -jar target/pdf-ocr-1.0-SNAPSHOT.jar
```

Dies verwendet `input/` als Input- und `output/` als Output-Verzeichnis.

### Benutzerdefinierte Verzeichnisse

```bash
java -jar target/pdf-ocr-1.0-SNAPSHOT.jar /pfad/zu/pdfs /pfad/zu/ausgabe
```

## Projektstruktur

```
Pdf_OCR/
├── pom.xml                              # Maven-Konfiguration
├── fix-rpaths.sh                        # Script zum Aktualisieren der Dylibs
├── download-tesseract-windows.ps1       # Windows Download-Script
├── input/                               # PDF-Dateien hier ablegen
├── output/                              # Ergebnisse werden hier gespeichert
├── src/main/java/com/pdfooocr/
│   ├── PdfOcrApplication.java           # Hauptklasse
│   └── OcrService.java                  # OCR-Logik mit Resource-Extraktion
└── src/main/resources/
    ├── tessdata/                        # Sprachmodelle (deu, eng, osd)
    └── native/
        └── macos-aarch64/               # macOS Apple Silicon Libraries
```

## Funktionsweise

1. **Startup**: Beim Start werden gebündelte Ressourcen (Tessdata + Native Libraries) in ein Temp-Verzeichnis extrahiert
2. **PDF-Scan**: Das Programm durchsucht das Input-Verzeichnis nach PDF-Dateien
3. **Textprüfung**: Zuerst wird geprüft, ob das PDF bereits textbasiert ist
4. **OCR bei Bedarf**: Bei bildbasierten PDFs wird Tesseract OCR mit 300 DPI aufgerufen
5. **Ausgabe**: Die Ergebnisse werden als `.txt`-Dateien im Output-Verzeichnis gespeichert

## Plattformunterstützung

| Plattform | Status | Native Libraries |
|-----------|--------|------------------|
| macOS (Apple Silicon) | ✅ Vollständig | Gebündelt in JAR |
| macOS (Intel) | 🔧 Geplant | Muss hinzugefügt werden |
| Windows (x64) | 🔧 Geplant | Download-Script vorhanden |
| Linux (x64) | ❌ Nicht unterstützt | - |

### Windows Setup

Um Windows-Support hinzuzufügen:

1. Auf einem Windows-Rechner ausführen:
```powershell
.\download-tesseract-windows.ps1
```

2. Die heruntergeladenen DLLs werden nach `src/main/resources/native/windows-x64/` kopiert

3. Neu kompilieren:
```bash
mvn clean package
```

## Technologien

- **Apache PDFBox** 3.0.3 - PDF-Verarbeitung
- **Tess4J** 5.12.0 - Java-Wrapper für Tesseract OCR
- **Tesseract OCR** 5.5.3 - Texterkennungs-Engine

## Lizenz

MIT License
