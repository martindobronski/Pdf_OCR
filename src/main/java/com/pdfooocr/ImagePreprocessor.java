package com.pdfooocr;

import java.awt.geom.AffineTransform;
import java.awt.image.AffineTransformOp;
import java.awt.image.BufferedImage;
import java.awt.image.ConvolveOp;
import java.awt.image.Kernel;

public class ImagePreprocessor {

    private static final int BORDER_SIZE = 10;
    private static final int SAUVOLA_WINDOW = 15;
    private static final double SAUVOLA_K = 0.2;
    private static final double SAUVOLA_R = 128;

    public BufferedImage preprocess(BufferedImage image) {
        BufferedImage result = toGrayscale(image);
        result = enhanceContrast(result);
        result = denoise(result);
        result = deskew(result);
        result = binarize(result);
        result = addBorder(result, BORDER_SIZE);
        return result;
    }

    private BufferedImage toGrayscale(BufferedImage image) {
        if (image.getType() == BufferedImage.TYPE_BYTE_GRAY) {
            return image;
        }
        BufferedImage gray = new BufferedImage(image.getWidth(), image.getHeight(), BufferedImage.TYPE_BYTE_GRAY);
        var g = gray.createGraphics();
        g.drawImage(image, 0, 0, null);
        g.dispose();
        return gray;
    }

    private BufferedImage enhanceContrast(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int[] pixels = image.getRGB(0, 0, width, height, null, 0, width);

        int min = 255;
        int max = 0;
        for (int pixel : pixels) {
            int gray = pixel & 0xFF;
            if (gray < min) min = gray;
            if (gray > max) max = gray;
        }

        if (max - min < 50) {
            return applyHistogramEqualization(image);
        }

        int range = max - min;
        if (range == 0) range = 1;

        BufferedImage result = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_GRAY);
        int[] newPixels = new int[pixels.length];
        for (int i = 0; i < pixels.length; i++) {
            int gray = pixels[i] & 0xFF;
            int stretched = ((gray - min) * 255) / range;
            stretched = Math.max(0, Math.min(255, stretched));
            newPixels[i] = (stretched << 16) | (stretched << 8) | stretched;
        }
        result.setRGB(0, 0, width, height, newPixels, 0, width);
        return result;
    }

    private BufferedImage applyHistogramEqualization(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int totalPixels = width * height;

        int[] histogram = new int[256];
        int[] pixels = image.getRGB(0, 0, width, height, null, 0, width);

        for (int pixel : pixels) {
            histogram[pixel & 0xFF]++;
        }

        double[] cdf = new double[256];
        cdf[0] = histogram[0];
        for (int i = 1; i < 256; i++) {
            cdf[i] = cdf[i - 1] + histogram[i];
        }

        double cdfMin = 0;
        for (int i = 0; i < 256; i++) {
            if (cdf[i] > 0) {
                cdfMin = cdf[i];
                break;
            }
        }

        int[] lookup = new int[256];
        for (int i = 0; i < 256; i++) {
            lookup[i] = (int) Math.round(((cdf[i] - cdfMin) / (totalPixels - cdfMin)) * 255);
            lookup[i] = Math.max(0, Math.min(255, lookup[i]));
        }

        BufferedImage result = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_GRAY);
        int[] newPixels = new int[pixels.length];
        for (int i = 0; i < pixels.length; i++) {
            int gray = lookup[pixels[i] & 0xFF];
            newPixels[i] = (gray << 16) | (gray << 8) | gray;
        }
        result.setRGB(0, 0, width, height, newPixels, 0, width);
        return result;
    }

    private BufferedImage denoise(BufferedImage image) {
        float[] kernel = {
            0f, 1f, 0f,
            1f, 1f, 1f,
            0f, 1f, 0f
        };
        kernel = normalizeKernel(kernel);
        Kernel medianKernel = new Kernel(3, 3, kernel);
        ConvolveOp op = new ConvolveOp(medianKernel, ConvolveOp.EDGE_NO_OP, null);
        return op.filter(image, null);
    }

    private float[] normalizeKernel(float[] kernel) {
        float sum = 0;
        for (float v : kernel) sum += v;
        if (sum > 0) {
            for (int i = 0; i < kernel.length; i++) kernel[i] /= sum;
        }
        return kernel;
    }

    private BufferedImage deskew(BufferedImage image) {
        int scale = 4;
        int scaledWidth = image.getWidth() / scale;
        int scaledHeight = image.getHeight() / scale;

        BufferedImage scaled = new BufferedImage(scaledWidth, scaledHeight, BufferedImage.TYPE_BYTE_GRAY);
        var g = scaled.createGraphics();
        g.drawImage(image, 0, 0, scaledWidth, scaledHeight, null);
        g.dispose();

        double bestAngle = 0;
        double bestScore = 0;

        for (double angle = -3.0; angle <= 3.0; angle += 0.5) {
            BufferedImage rotated = rotateImage(scaled, angle);
            double score = calculateProjectionScore(rotated);
            if (score > bestScore) {
                bestScore = score;
                bestAngle = angle;
            }
        }

        if (Math.abs(bestAngle) >= 0.5) {
            return rotateImage(image, bestAngle);
        }
        return image;
    }

    private double calculateProjectionScore(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int[] pixels = image.getRGB(0, 0, width, height, null, 0, width);

        int[] horizontalProjection = new int[height];
        for (int y = 0; y < height; y++) {
            int count = 0;
            for (int x = 0; x < width; x++) {
                int gray = pixels[y * width + x] & 0xFF;
                if (gray < 128) count++;
            }
            horizontalProjection[y] = count;
        }

        double mean = 0;
        for (int val : horizontalProjection) mean += val;
        mean /= height;

        double variance = 0;
        for (int val : horizontalProjection) {
            variance += (val - mean) * (val - mean);
        }
        return variance / height;
    }

    private BufferedImage rotateImage(BufferedImage image, double angleDegrees) {
        double angleRadians = Math.toRadians(angleDegrees);
        int width = image.getWidth();
        int height = image.getHeight();

        AffineTransform transform = new AffineTransform();
        transform.rotate(angleRadians, width / 2.0, height / 2.0);

        AffineTransformOp op = new AffineTransformOp(transform, AffineTransformOp.TYPE_BILINEAR);
        BufferedImage rotated = new BufferedImage(width, height, image.getType());
        op.filter(image, rotated);
        return rotated;
    }

    private BufferedImage binarize(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int[] pixels = image.getRGB(0, 0, width, height, null, 0, width);

        int windowSize = SAUVOLA_WINDOW;
        int halfWindow = windowSize / 2;

        int[] integralImage = new int[width * height];
        int[] integralSqImage = new int[width * height];

        for (int y = 0; y < height; y++) {
            int rowSum = 0;
            int rowSumSq = 0;
            for (int x = 0; x < width; x++) {
                int gray = pixels[y * width + x] & 0xFF;
                rowSum += gray;
                rowSumSq += gray * gray;
                integralImage[y * width + x] = rowSum + (y > 0 ? integralImage[(y - 1) * width + x] : 0);
                integralSqImage[y * width + x] = rowSumSq + (y > 0 ? integralSqImage[(y - 1) * width + x] : 0);
            }
        }

        BufferedImage result = new BufferedImage(width, height, BufferedImage.TYPE_BYTE_BINARY);

        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++) {
                int y1 = Math.max(0, y - halfWindow);
                int y2 = Math.min(height - 1, y + halfWindow);
                int x1 = Math.max(0, x - halfWindow);
                int x2 = Math.min(width - 1, x + halfWindow);

                int area = (y2 - y1 + 1) * (x2 - x1 + 1);

                int sum = integralImage[y2 * width + x2];
                if (y1 > 0) sum -= integralImage[(y1 - 1) * width + x2];
                if (x1 > 0) sum -= integralImage[y2 * width + (x1 - 1)];
                if (y1 > 0 && x1 > 0) sum += integralImage[(y1 - 1) * width + (x1 - 1)];

                int sumSq = integralSqImage[y2 * width + x2];
                if (y1 > 0) sumSq -= integralSqImage[(y1 - 1) * width + x2];
                if (x1 > 0) sumSq -= integralSqImage[y2 * width + (x1 - 1)];
                if (y1 > 0 && x1 > 0) sumSq += integralSqImage[(y1 - 1) * width + (x1 - 1)];

                double mean = (double) sum / area;
                double variance = ((double) sumSq / area) - (mean * mean);
                double stddev = Math.sqrt(Math.max(0, variance));

                double threshold = mean * (1 + SAUVOLA_K * (stddev / SAUVOLA_R - 1));

                int gray = pixels[y * width + x] & 0xFF;
                int black = (gray < threshold) ? 0 : 0xFFFFFF;
                result.setRGB(x, y, black);
            }
        }

        return result;
    }

    private BufferedImage addBorder(BufferedImage image, int borderSize) {
        int width = image.getWidth();
        int height = image.getHeight();
        int newWidth = width + 2 * borderSize;
        int newHeight = height + 2 * borderSize;

        BufferedImage bordered = new BufferedImage(newWidth, newHeight, image.getType());
        var g = bordered.createGraphics();
        g.setColor(java.awt.Color.WHITE);
        g.fillRect(0, 0, newWidth, newHeight);
        g.drawImage(image, borderSize, borderSize, null);
        g.dispose();

        return bordered;
    }

    public boolean hasGraphics(BufferedImage image) {
        int width = image.getWidth();
        int height = image.getHeight();
        int[] pixels = image.getRGB(0, 0, width, height, null, 0, width);

        int totalPixels = width * height;
        int blackPixels = 0;
        int edgePixels = 0;

        for (int pixel : pixels) {
            int gray = pixel & 0xFF;
            if (gray < 128) blackPixels++;
        }

        for (int x = 0; x < width; x++) {
            if ((pixels[x] & 0xFF) < 128) edgePixels++;
            if ((pixels[(height - 1) * width + x] & 0xFF) < 128) edgePixels++;
        }
        for (int y = 0; y < height; y++) {
            if ((pixels[y * width] & 0xFF) < 128) edgePixels++;
            if ((pixels[y * width + width - 1] & 0xFF) < 128) edgePixels++;
        }

        double density = (double) blackPixels / totalPixels;
        double edgeDensity = (double) edgePixels / (2 * (width + height));

        return density > 0.15 || edgeDensity > 0.3;
    }
}
