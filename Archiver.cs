// Archiver.cs
using System;
using System.IO;
using System.IO.Compression;
using System.Linq;

class Archiver
{
    const string CloudDir = "cloud";

    static void EnsureCloudDir()
    {
        Directory.CreateDirectory(CloudDir);
    }

    static string GetArchiveName()
    {
        return $"archive_{DateTime.Now:yyyyMMdd_HHmmss}.zip";
    }

    static void AddFiles(string[] paths)
    {
        EnsureCloudDir();
        string archiveName = GetArchiveName();
        string archivePath = Path.Combine(CloudDir, archiveName);
        using (var zip = ZipFile.Open(archivePath, ZipArchiveMode.Create))
        {
            foreach (string p in paths)
            {
                if (Directory.Exists(p))
                {
                    var files = Directory.GetFiles(p, "*", SearchOption.AllDirectories);
                    foreach (var f in files)
                    {
                        string entryName = Path.GetRelativePath(p, f);
                        zip.CreateEntryFromFile(f, entryName);
                    }
                }
                else if (File.Exists(p))
                {
                    zip.CreateEntryFromFile(p, Path.GetFileName(p));
                }
                else
                {
                    Console.WriteLine($"Warning: {p} does not exist, skipping.");
                }
            }
        }
        Console.WriteLine($"Archive created: {archivePath}");
    }

    static void ListArchives()
    {
        EnsureCloudDir();
        var archives = Directory.GetFiles(CloudDir, "*.zip").Select(Path.GetFileName).ToList();
        if (archives.Count == 0)
        {
            Console.WriteLine("No archives found.");
            return;
        }
        Console.WriteLine("Archives:");
        foreach (var a in archives.OrderBy(x => x))
        {
            var info = new FileInfo(Path.Combine(CloudDir, a));
            Console.WriteLine($"  {a} ({info.Length} bytes)");
        }
    }

    static void ExtractArchive(string archiveName)
    {
        EnsureCloudDir();
        string archivePath = Path.Combine(CloudDir, archiveName);
        if (!File.Exists(archivePath))
        {
            Console.WriteLine($"Archive '{archiveName}' not found.");
            return;
        }
        ZipFile.ExtractToDirectory(archivePath, ".", true);
        Console.WriteLine($"Extracted '{archiveName}' to current directory.");
    }

    static void Main(string[] args)
    {
        if (args.Length < 1)
        {
            Console.WriteLine("Usage: Archiver.exe <add|list|extract> [args...]");
            return;
        }
        string cmd = args[0].ToLower();
        switch (cmd)
        {
            case "add":
                if (args.Length < 2)
                {
                    Console.WriteLine("Usage: Archiver.exe add <file/dir> [<file/dir>...]");
                    return;
                }
                AddFiles(args.Skip(1).ToArray());
                break;
            case "list":
                ListArchives();
                break;
            case "extract":
                if (args.Length != 2)
                {
                    Console.WriteLine("Usage: Archiver.exe extract <archive_name>");
                    return;
                }
                ExtractArchive(args[1]);
                break;
            default:
                Console.WriteLine($"Unknown command: {cmd}");
                break;
        }
    }
}
