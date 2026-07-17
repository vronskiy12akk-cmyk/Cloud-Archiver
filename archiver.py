# archiver.py
import os
import sys
import zipfile
import shutil
from datetime import datetime

CLOUD_DIR = "cloud"

def ensure_cloud_dir():
    os.makedirs(CLOUD_DIR, exist_ok=True)

def get_archive_name():
    return f"archive_{datetime.now().strftime('%Y%m%d_%H%M%S')}.zip"

def add_files(files):
    ensure_cloud_dir()
    archive_name = get_archive_name()
    archive_path = os.path.join(CLOUD_DIR, archive_name)
    with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for path in files:
            if os.path.isdir(path):
                for root, dirs, files in os.walk(path):
                    for f in files:
                        full = os.path.join(root, f)
                        arcname = os.path.relpath(full, start=os.path.dirname(path))
                        zf.write(full, arcname)
            else:
                zf.write(path, os.path.basename(path))
    print(f"Archive created: {archive_path}")

def list_archives():
    ensure_cloud_dir()
    archives = [f for f in os.listdir(CLOUD_DIR) if f.endswith('.zip')]
    if not archives:
        print("No archives found.")
    else:
        print("Archives:")
        for a in sorted(archives):
            size = os.path.getsize(os.path.join(CLOUD_DIR, a))
            print(f"  {a} ({size} bytes)")

def extract_archive(archive_name):
    ensure_cloud_dir()
    archive_path = os.path.join(CLOUD_DIR, archive_name)
    if not os.path.exists(archive_path):
        print(f"Archive '{archive_name}' not found.")
        return
    with zipfile.ZipFile(archive_path, 'r') as zf:
        zf.extractall('.')
    print(f"Extracted '{archive_name}' to current directory.")

def main():
    if len(sys.argv) < 2:
        print("Usage: archiver.py <add|list|extract> [args...]")
        return
    cmd = sys.argv[1].lower()
    if cmd == 'add':
        if len(sys.argv) < 3:
            print("Usage: archiver.py add <file/dir> [<file/dir>...]")
            return
        add_files(sys.argv[2:])
    elif cmd == 'list':
        list_archives()
    elif cmd == 'extract':
        if len(sys.argv) != 3:
            print("Usage: archiver.py extract <archive_name>")
            return
        extract_archive(sys.argv[2])
    else:
        print(f"Unknown command: {cmd}")

if __name__ == '__main__':
    main()
