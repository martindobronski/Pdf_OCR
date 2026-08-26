package com.pdfooocr;

import net.sourceforge.tess4j.ITesseract;
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.ImageType;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.apache.pdfbox.text.PDFTextStripper;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;

public class OcrService {

    private static final String OS_NAME = System.getProperty("os.name").toLowerCase();
    private static final String OS_ARCH = System.getProperty("os.arch").toLowerCase();
    private static final String WORK_DIR = "pdf-ocr-tmp";

    private final ITesseract tesseract;
    private final ImagePreprocessor preprocessor;

    public OcrService() {
        String tessDataPath = extractAndResolveTessdata();
        String nativeLibPath = extractAndResolveNativeLibs();

        System.setProperty("jna.library.path", nativeLibPath);

        this.tesseract = new Tesseract();
        this.tesseract.setDatapath(tessDataPath);
        this.tesseract.setLanguage("deu+eng");
        this.tesseract.setPageSegMode(3);
        this.tesseract.setVariable("preserve_interword_spaces", "1");

        this.preprocessor = new ImagePreprocessor();

        System.out.println("  -> OS: " + OS_NAME + " (" + OS_ARCH + ")");
        System.out.println("  -> Tessdata: " + tessDataPath);
        System.out.println("  -> Native Libs: " + nativeLibPath);
        System.out.println("  -> Bildvorverarbeitung: aktiviert");
    }

    private String extractAndResolveTessdata() {
        String envPath = System.getenv("TESSDATA_PREFIX");
        if (envPath != null && !envPath.isBlank()) {
            System.out.println("  -> Using TESSDATA_PREFIX: " + envPath);
            return envPath;
        }

        Path targetDir = Path.of(WORK_DIR, "tessdata");
        List<String> files = List.of("deu.traineddata", "eng.traineddata", "osd.traineddata");

        if (extractFiles("tessdata", targetDir, files)) {
            return targetDir.toAbsolutePath().toString();
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

    private String extractAndResolveNativeLibs() {
        String platformDir = resolvePlatformDir();
        Path targetDir = Path.of(WORK_DIR, "native", platformDir);
        List<String> files = getNativeFiles(platformDir);

        if (extractFiles("native/" + platformDir, targetDir, files)) {
            return targetDir.toAbsolutePath().toString();
        }

        if (isWindows()) {
            String programFiles = System.getenv("PROGRAMFILES");
            if (programFiles == null) {
                programFiles = "C:\\Program Files";
            }
            return programFiles + "\\Tesseract-OCR";
        }

        return "/opt/homebrew/lib";
    }

    private boolean extractFiles(String resourceBase, Path targetDir, List<String> files) {
        try {
            Files.createDirectories(targetDir);

            boolean allExtracted = true;
            for (String file : files) {
                Path targetFile = targetDir.resolve(file);

                if (Files.exists(targetFile) && Files.size(targetFile) > 0) {
                    continue;
                }

                String resourcePath = resourceBase + "/" + file;
                try (InputStream is = getClass().getClassLoader().getResourceAsStream(resourcePath)) {
                    if (is != null) {
                        Files.copy(is, targetFile, StandardCopyOption.REPLACE_EXISTING);
                    } else {
                        allExtracted = false;
                    }
                }
            }
            return allExtracted;
        } catch (IOException e) {
            System.out.println("  -> Warning: Could not extract bundled resources: " + e.getMessage());
            return false;
        }
    }

    private String resolvePlatformDir() {
        if (isWindows()) {
            return "windows-x64";
        }
        if (isMac()) {
            return isArm() ? "macos-aarch64" : "macos-x64";
        }
        if (isLinux()) {
            return isArm() ? "linux-aarch64" : "linux-x64";
        }
        return "unknown";
    }

    private List<String> getNativeFiles(String platformDir) {
        return switch (platformDir) {
            case "macos-aarch64", "macos-x64" -> Arrays.asList(
                "libtesseract.dylib",
                "libtesseract.5.dylib",
                "libleptonica.dylib",
                "libleptonica.6.dylib",
                "libarchive.dylib",
                "libarchive.13.dylib",
                "libtiff.dylib",
                "libtiff.6.dylib",
                "libjpeg.dylib",
                "libjpeg.8.dylib",
                "libwebp.dylib",
                "libwebp.7.dylib",
                "libopenjp2.dylib",
                "libopenjp2.7.dylib",
                "libpng16.dylib",
                "libpng16.16.dylib",
                "libzstd.dylib",
                "libzstd.1.dylib",
                "liblzma.dylib",
                "liblzma.5.dylib",
                "liblz4.dylib",
                "liblz4.1.dylib",
                "libb2.dylib",
                "libb2.1.dylib",
                "libgif.dylib",
                "libwebpmux.dylib",
                "libwebpmux.3.dylib",
                "libsharpyuv.dylib",
                "libsharpyuv.0.dylib"
            );
            case "windows-x64" -> Arrays.asList(
                "tesseract.dll",
                "leptonica-1.82.0.dll",
                "libarchive-13.dll",
                "libpng16-16.dll",
                "libjpeg-8.dll",
                "libtiff-6.dll",
                "libwebp-7.dll",
                "libwebpmux-3.dll",
                "libsharpyuv-0.dll",
                "libopenjp2-7.dll",
                "libzstd.dll",
                "liblzma-5.dll",
                "liblz4.dll",
                "libzlib.dll"
            );
            default -> List.of();
        };
    }

    private static boolean isWindows() {
        return OS_NAME.contains("win");
    }

    private static boolean isMac() {
        return OS_NAME.contains("mac") || OS_NAME.contains("darwin");
    }

    private static boolean isLinux() {
        return OS_NAME.contains("linux");
    }

    private static boolean isArm() {
        return OS_ARCH.contains("aarch64") || OS_ARCH.contains("arm");
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

                boolean hasGraphics = preprocessor.hasGraphics(image);
                if (hasGraphics) {
                    System.out.println("      -> Grafik erkannt, verwende PSM 11");
                    this.tesseract.setPageSegMode(11);
                } else {
                    this.tesseract.setPageSegMode(3);
                }

                BufferedImage processed = preprocessor.preprocess(image);
                String pageText = tesseract.doOCR(processed);

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
