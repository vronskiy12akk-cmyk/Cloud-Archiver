📦 Cloud Archiver – Multi‑Language Edition
A lightweight archiving tool that compresses files and folders into ZIP archives and uploads them to a simulated cloud storage (local cloud/ directory).
Supports add, list, and extract operations.
Built in 7 programming languages – perfect for learning file compression, CLI design, and cloud storage simulation.

✨ Features
Add – compress one or more files/folders into a ZIP archive.

Upload – automatically saves the archive to the cloud/ folder with a timestamp.

List – display all archives stored in the cloud.

Extract – extract a ZIP archive from the cloud to the current directory.

Cross‑platform – works on Windows, macOS, and Linux.

CLI – simple command‑line interface with intuitive arguments.

🗂 Languages & Files
Language	File
Python	archiver.py
Go	archiver.go
JavaScript (Node)	archiver.js
C#	Archiver.cs
Java	Archiver.java
Ruby	archiver.rb
Swift	archiver.swift
🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler.

Language	Command
Python	python archiver.py add file.txt folder/
Go	go run archiver.go add file.txt folder/
JavaScript	node archiver.js add file.txt folder/
C#	dotnet run -- add file.txt folder/
Java	javac Archiver.java && java Archiver add file.txt folder/
Ruby	ruby archiver.rb add file.txt folder/
Swift	swift archiver.swift add file.txt folder/
🎮 Commands
add <path> [<path>...] – create a new archive from the given paths and upload it.

list – show all archives in the cloud.

extract <archive_name> – extract the specified archive to the current directory.

📁 Cloud Storage
All archives are stored in the cloud/ directory (created automatically).
Archive names are automatically generated with a timestamp (e.g., archive_20260114_123456.zip).

📜 License
MIT – use freely.
