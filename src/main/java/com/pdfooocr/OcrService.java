package com.pdfooocr;

import net.sourceforge.tess4j.ITesseract;
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import net.sourceforge.tess4j.util.LoadLibs;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.pdfbox.text.PDFTextStripper;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.nio.file.Path;

public class OcrService {

    private static final String OS_NAME = System.getProperty("os.name").toLowerCase();

    private final ITesseract tesseract;

    public OcrService() {
        String tessDataPath = resolveTessDataPath();
        String nativeLibPath = resolveNativeLibPath();

        System.setProperty("jna.library.path", nativeLibPath);

        this.tesseract = new Tesseract();
        this.tesseract.setDatapath(tessDataPath);
        this.tesseract.setLanguage("deu+eng");
        this.tesseract.setPageSegMode(3);

        System.out.println("  -> OS: " + OS_NAME);
        System.out.println("  -> Tessdata: " + tessDataPath);
        System.out.println("  -> Native Libs: " + nativeLibPath);
    }

    private String resolveTessDataPath() {
        String envPath = System.getenv("TESSDATA_PREFIX");
        if (envPath != null && !envPath.isBlank()) {
            return envPath;
        }

        if (isWindows()) {
            String programFiles = System.getenv("PROGRAMFILES");
            if (programFiles == null) {
                programFiles = "C:\\Program Files";
            }
            return programFiles + "\\Tesseract-OCR\\tessdata";
        }

        return "/opt/homebrew/share/tessdata";
    }

    private String resolveNativeLibPath() {
        if (isWindows()) {
            String programFiles = System.getenv("PROGRAMFILES");
            if (programFiles == null) {
                programFiles = "C:\\Program Files";
            }
            return programFiles + "\\Tesseract-OCR";
        }

        return "/opt/homebrew/lib";
    }

    private static boolean isWindows() {
        return OS_NAME.contains("win");
    }

    public String extractTextFromPdf(Path pdfPath) throws IOException, TesseractException {
        StringBuilder fullText = new StringBuilder();

        try (PDDocument document = Loader.loadPDF(pdfPath.toFile())) {
            PDFRenderer pdfRenderer = new PDFRenderer(document);
            int pageCount = document.getNumberOfPages();

            String existingText = extractExistingText(document);
            if (existingText != null && !existingText.isBlank()) {
                System.out.println("  -> Direkter Text extrahiert (kein OCR noetig)");
                return existingText;
            }

            System.out.println("  -> Kein Text vorhanden, fuehre OCR durch (" + pageCount + " Seiten)...");

            for (int page = 0; page < pageCount; page++) {
                System.out.println("    Seite " + (page + 1) + "/" + pageCount + "...");

                BufferedImage image = pdfRenderer.renderImageWithDPI(page, 300, ImageType.GRAY);
                String pageText = tesseract.doOCR(image);

                if (pageText != null && !pageText.isBlank()) {
                    fullText.append(pageText);
                    if (page < pageCount - 1) {
                        fullText.append("\n\n--- Seite ").append(page + 1).append(" ---\n\n");
                    }
                }
            }
        }

        return fullText.toString();
    }

    private String extractExistingText(PDDocument document) throws IOException {
        PDFTextStripper stripper = new PDFTextStripper();
        String text = stripper.getText(document);
        String stripped = text.replaceAll("\\s+", "").trim();
        if (stripped.length() > 50) {
            return text;
        }
        return null;
    }
}
