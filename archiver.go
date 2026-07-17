// archiver.go
package main

import (
	"archive/zip"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

const cloudDir = "cloud"

func ensureCloudDir() error {
	return os.MkdirAll(cloudDir, 0755)
}

func archiveName() string {
	return fmt.Sprintf("archive_%s.zip", time.Now().Format("20060102_150405"))
}

func addFiles(paths []string) {
	if err := ensureCloudDir(); err != nil {
		fmt.Println("Error creating cloud dir:", err)
		return
	}
	name := archiveName()
	archivePath := filepath.Join(cloudDir, name)
	file, err := os.Create(archivePath)
	if err != nil {
		fmt.Println("Error creating archive:", err)
		return
	}
	defer file.Close()
	zipWriter := zip.NewWriter(file)
	defer zipWriter.Close()
	for _, path := range paths {
		info, err := os.Stat(path)
		if err != nil {
			fmt.Printf("Skipping %s: %v\n", path, err)
			continue
		}
		if info.IsDir() {
			err = filepath.Walk(path, func(fullPath string, f os.FileInfo, err error) error {
				if err != nil {
					return err
				}
				if f.IsDir() {
					return nil
				}
				relPath, err := filepath.Rel(path, fullPath)
				if err != nil {
					return err
				}
				return addFileToZip(zipWriter, fullPath, relPath)
			})
			if err != nil {
				fmt.Printf("Error walking %s: %v\n", path, err)
			}
		} else {
			if err := addFileToZip(zipWriter, path, filepath.Base(path)); err != nil {
				fmt.Printf("Error adding %s: %v\n", path, err)
			}
		}
	}
	fmt.Printf("Archive created: %s\n", archivePath)
}

func addFileToZip(zipWriter *zip.Writer, fullPath, relPath string) error {
	file, err := os.Open(fullPath)
	if err != nil {
		return err
	}
	defer file.Close()
	header, err := zip.FileInfoHeader(os.FileInfo(fullPath))
	if err != nil {
		return err
	}
	header.Name = relPath
	writer, err := zipWriter.CreateHeader(header)
	if err != nil {
		return err
	}
	_, err = io.Copy(writer, file)
	return err
}

func listArchives() {
	if err := ensureCloudDir(); err != nil {
		fmt.Println("Error accessing cloud dir:", err)
		return
	}
	files, err := os.ReadDir(cloudDir)
	if err != nil {
		fmt.Println("Error reading cloud dir:", err)
		return
	}
	var archives []string
	for _, f := range files {
		if !f.IsDir() && filepath.Ext(f.Name()) == ".zip" {
			archives = append(archives, f.Name())
		}
	}
	if len(archives) == 0 {
		fmt.Println("No archives found.")
		return
	}
	fmt.Println("Archives:")
	for _, a := range archives {
		info, _ := os.Stat(filepath.Join(cloudDir, a))
		fmt.Printf("  %s (%d bytes)\n", a, info.Size())
	}
}

func extractArchive(name string) {
	if err := ensureCloudDir(); err != nil {
		fmt.Println("Error accessing cloud dir:", err)
		return
	}
	archivePath := filepath.Join(cloudDir, name)
	if _, err := os.Stat(archivePath); os.IsNotExist(err) {
		fmt.Printf("Archive '%s' not found.\n", name)
		return
	}
	reader, err := zip.OpenReader(archivePath)
	if err != nil {
		fmt.Println("Error opening archive:", err)
		return
	}
	defer reader.Close()
	for _, file := range reader.File {
		err := extractFile(file)
		if err != nil {
			fmt.Printf("Error extracting %s: %v\n", file.Name, err)
		}
	}
	fmt.Printf("Extracted '%s' to current directory.\n", name)
}

func extractFile(file *zip.File) error {
	rc, err := file.Open()
	if err != nil {
		return err
	}
	defer rc.Close()
	path := file.Name
	if file.FileInfo().IsDir() {
		return os.MkdirAll(path, 0755)
	}
	// Ensure parent directories exist
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}
	outFile, err := os.Create(path)
	if err != nil {
		return err
	}
	defer outFile.Close()
	_, err = io.Copy(outFile, rc)
	return err
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: archiver.go <add|list|extract> [args...]")
		return
	}
	cmd := os.Args[1]
	switch cmd {
	case "add":
		if len(os.Args) < 3 {
			fmt.Println("Usage: archiver.go add <file/dir> [<file/dir>...]")
			return
		}
		addFiles(os.Args[2:])
	case "list":
		listArchives()
	case "extract":
		if len(os.Args) != 3 {
			fmt.Println("Usage: archiver.go extract <archive_name>")
			return
		}
		extractArchive(os.Args[2])
	default:
		fmt.Printf("Unknown command: %s\n", cmd)
	}
}
