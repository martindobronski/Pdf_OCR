package com.pdfooocr;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;
import java.util.stream.Collectors;

public class PdfOcrApplication {

    private static final String DEFAULT_INPUT_DIR = "input";
    private static final String DEFAULT_OUTPUT_DIR = "output";

    public static void main(String[] args) {
        String inputDir = args.length > 0 ? args[0] : DEFAULT_INPUT_DIR;
        String outputDir = args.length > 1 ? args[1] : DEFAULT_OUTPUT_DIR;

        System.out.println("PDF OCR Texterkennung gestartet");
        System.out.println("Input-Verzeichnis:  " + inputDir);
        System.out.println("Output-Verzeichnis: " + outputDir);
        System.out.println("-----------------------------------");

        Path inputPath = Paths.get(inputDir);
        Path outputPath = Paths.get(outputDir);

        if (!Files.exists(inputPath) || !Files.isDirectory(inputPath)) {
            System.err.println("FEHLER: Input-Verzeichnis '" + inputDir + "' existiert nicht.");
            System.exit(1);
        }

        try {
            Files.createDirectories(outputPath);
        } catch (IOException e) {
            System.err.println("FEHLER: Output-Verzeichnis konnte nicht erstellt werden: " + e.getMessage());
            System.exit(1);
        }

        List<Path> pdfFiles;
        try (var stream = Files.list(inputPath)) {
            pdfFiles = stream
                    .filter(p -> p.toString().toLowerCase().endsWith(".pdf"))
                    .sorted()
                    .collect(Collectors.toList());
        } catch (IOException e) {
            System.err.println("FEHLER: Verzeichnis konnte nicht gelesen werden: " + e.getMessage());
            System.exit(1);
            return;
        }

        if (pdfFiles.isEmpty()) {
            System.out.println("Keine PDF-Dateien im Input-Verzeichnis gefunden.");
            return;
        }

        System.out.println("Gefundene PDF-Dateien: " + pdfFiles.size());
        System.out.println();

        OcrService ocrService = new OcrService();
        int successCount = 0;
        int errorCount = 0;

        for (Path pdfFile : pdfFiles) {
            String baseName = getBaseName(pdfFile.getFileName().toString());
            Path outputFile = outputPath.resolve(baseName + ".txt");

            System.out.println("Verarbeite: " + pdfFile.getFileName());
            try {
                String text = ocrService.extractTextFromPdf(pdfFile);
                Files.writeString(outputFile, text);
                System.out.println("  -> Erkannt: " + text.length() + " Zeichen geschrieben nach " + outputFile.getFileName());
                successCount++;
            } catch (Exception e) {
                System.err.println("  -> FEHLER: " + e.getMessage());
                errorCount++;
            }
        }

        System.out.println();
        System.out.println("Verarbeitung abgeschlossen.");
        System.out.println("Erfolgreich: " + successCount + " | Fehler: " + errorCount);
    }

    private static String getBaseName(String filename) {
        int lastDot = filename.lastIndexOf('.');
        return lastDot > 0 ? filename.substring(0, lastDot) : filename;
    }
}
