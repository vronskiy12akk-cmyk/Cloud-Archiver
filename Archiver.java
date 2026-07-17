// Archiver.java
import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.zip.*;

public class Archiver {
    private static final String CLOUD_DIR = "cloud";

    public static void main(String[] args) throws IOException {
        if (args.length < 1) {
            System.out.println("Usage: java Archiver <add|list|extract> [args...]");
            return;
        }
        String cmd = args[0].toLowerCase();
        switch (cmd) {
            case "add":
                if (args.length < 2) {
                    System.out.println("Usage: Archiver add <file/dir> [<file/dir>...]");
                    return;
                }
                addFiles(args);
                break;
            case "list":
                listArchives();
                break;
            case "extract":
                if (args.length != 2) {
                    System.out.println("Usage: Archiver extract <archive_name>");
                    return;
                }
                extractArchive(args[1]);
                break;
            default:
                System.out.println("Unknown command: " + cmd);
        }
    }

    private static void ensureCloudDir() throws IOException {
        Files.createDirectories(Paths.get(CLOUD_DIR));
    }

    private static String getArchiveName() {
        return "archive_" + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss")) + ".zip";
    }

    private static void addFiles(String[] args) throws IOException {
        ensureCloudDir();
        String archiveName = getArchiveName();
        String archivePath = CLOUD_DIR + File.separator + archiveName;
        try (FileOutputStream fos = new FileOutputStream(archivePath);
             ZipOutputStream zos = new ZipOutputStream(fos)) {
            for (int i = 1; i < args.length; i++) {
                Path p = Paths.get(args[i]);
                if (Files.isDirectory(p)) {
                    addDirectoryToZip(zos, p, "");
                } else if (Files.exists(p)) {
                    addFileToZip(zos, p, p.getFileName().toString());
                } else {
                    System.out.println("Warning: " + args[i] + " does not exist, skipping.");
                }
            }
        }
        System.out.println("Archive created: " + archivePath);
    }

    private static void addDirectoryToZip(ZipOutputStream zos, Path dir, String base) throws IOException {
        Files.walk(dir).filter(Files::isRegularFile).forEach(file -> {
            try {
                String rel = base + (base.isEmpty() ? "" : "/") + dir.relativize(file).toString();
                addFileToZip(zos, file, rel);
            } catch (IOException e) {
                System.err.println("Error adding " + file + ": " + e.getMessage());
            }
        });
    }

    private static void addFileToZip(ZipOutputStream zos, Path file, String entryName) throws IOException {
        ZipEntry entry = new ZipEntry(entryName);
        zos.putNextEntry(entry);
        Files.copy(file, zos);
        zos.closeEntry();
    }

    private static void listArchives() throws IOException {
        ensureCloudDir();
        try (var stream = Files.list(Paths.get(CLOUD_DIR))) {
            var archives = stream.filter(p -> p.toString().endsWith(".zip"))
                                 .map(Path::getFileName)
                                 .map(Path::toString)
                                 .sorted()
                                 .toList();
            if (archives.isEmpty()) {
                System.out.println("No archives found.");
                return;
            }
            System.out.println("Archives:");
            for (String a : archives) {
                long size = Files.size(Paths.get(CLOUD_DIR, a));
                System.out.printf("  %s (%d bytes)\n", a, size);
            }
        }
    }

    private static void extractArchive(String archiveName) throws IOException {
        ensureCloudDir();
        Path archivePath = Paths.get(CLOUD_DIR, archiveName);
        if (!Files.exists(archivePath)) {
            System.out.println("Archive '" + archiveName + "' not found.");
            return;
        }
        try (ZipInputStream zis = new ZipInputStream(Files.newInputStream(archivePath))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                Path outPath = Paths.get(entry.getName());
                if (entry.isDirectory()) {
                    Files.createDirectories(outPath);
                } else {
                    Files.createDirectories(outPath.getParent());
                    Files.copy(zis, outPath, StandardCopyOption.REPLACE_EXISTING);
                }
                zis.closeEntry();
            }
        }
        System.out.println("Extracted '" + archiveName + "' to current directory.");
    }
}
