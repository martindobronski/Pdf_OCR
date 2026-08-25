# PDF OCR Texterkennung

Java-Programm zur automatisierten Texterkennung von PDF-Dateien. Das Programm liest alle PDF-Dateien aus einem Input-Verzeichnis, führt eine OCR-Texterkennung durch und speichert den erkannten Text in einem Output-Verzeichnis.

## Features

- **Direkte Textextraktion**: Bei textbasierten PDFs wird der Text direkt extrahiert
- **OCR-Texterkennung**: Bei bildbasierten PDFs wird Tesseract OCR verwendet
- **Mehrsprachig**: Unterstützt Deutsch und Englisch
- **Einfache Bedienung**: Kommandozeilen-basiert

## Voraussetzungen

- Java 17 oder höher
- Maven
- Tesseract OCR (über Homebrew installiert)

### Tesseract installieren

```bash
brew install tesseract tesseract-lang
```

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
├── pom.xml                          # Maven-Konfiguration
├── input/                           # PDF-Dateien hier ablegen
├── output/                          # Ergebnisse werden hier gespeichert
├── src/main/java/com/pdfooocr/
│   ├── PdfOcrApplication.java       # Hauptklasse
│   └── OcrService.java              # OCR-Logik
└── target/
    └── pdf-ocr-1.0-SNAPSHOT.jar     # Kompiliertes JAR
```

## Funktionsweise

1. **PDF-Scan**: Das Programm durchsucht das Input-Verzeichnis nach PDF-Dateien
2. **Textprüfung**: Zuerst wird geprüft, ob das PDF bereits textbasiert ist
3. **OCR bei Bedarf**: Bei bildbasierten PDFs wird Tesseract OCR mit 300 DPI aufgerufen
4. **Ausgabe**: Die Ergebnisse werden als `.txt`-Dateien im Output-Verzeichnis gespeichert

## Technologien

- **Apache PDFBox** 3.0.3 - PDF-Verarbeitung
- **Tess4J** 5.12.0 - Java-Wrapper für Tesseract OCR
- **Tesseract OCR** 5.5.3 - Texterkennungs-Engine

## Lizenz

MIT License
