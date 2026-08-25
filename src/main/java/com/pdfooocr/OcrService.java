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

    private static final String TESSDATA_PATH = "/opt/homebrew/share/tessdata";
    private static final String NATIVE_LIB_PATH = "/opt/homebrew/lib";

    private final ITesseract tesseract;

    public OcrService() {
        System.setProperty("jna.library.path", NATIVE_LIB_PATH);

        this.tesseract = new Tesseract();
        this.tesseract.setDatapath(TESSDATA_PATH);
        this.tesseract.setLanguage("deu+eng");
        this.tesseract.setPageSegMode(3);

        File tessDataDir = new File(TESSDATA_PATH);
        this.tesseract.setDatapath(LoadLibs.extractTessResources("tessdata").getAbsolutePath());
        this.tesseract.setDatapath(tessDataDir.getAbsolutePath());
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
