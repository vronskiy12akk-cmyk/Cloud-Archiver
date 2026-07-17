# archiver.rb
require 'zip'
require 'fileutils'
require 'time'

CLOUD_DIR = 'cloud'

def ensure_cloud_dir
  FileUtils.mkdir_p(CLOUD_DIR)
end

def archive_name
  "archive_#{Time.now.strftime('%Y%m%d_%H%M%S')}.zip"
end

def add_files(paths)
  ensure_cloud_dir
  name = archive_name
  archive_path = File.join(CLOUD_DIR, name)
  Zip::File.open(archive_path, Zip::File::CREATE) do |zipfile|
    paths.each do |path|
      if File.directory?(path)
        Dir.glob(File.join(path, '**', '*')).each do |file|
          next if File.directory?(file)
          entry_name = File.basename(file) # simplified; to preserve structure, we'd need relative path
          zipfile.add(File.basename(file), file)
        end
      elsif File.file?(path)
        zipfile.add(File.basename(path), path)
      else
        puts "Warning: #{path} does not exist, skipping."
      end
    end
  end
  puts "Archive created: #{archive_path}"
end

def list_archives
  ensure_cloud_dir
  archives = Dir.glob(File.join(CLOUD_DIR, '*.zip')).map { |f| File.basename(f) }.sort
  if archives.empty?
    puts "No archives found."
    return
  end
  puts "Archives:"
  archives.each do |a|
    size = File.size(File.join(CLOUD_DIR, a))
    puts "  #{a} (#{size} bytes)"
  end
end

def extract_archive(archive_name)
  ensure_cloud_dir
  archive_path = File.join(CLOUD_DIR, archive_name)
  unless File.exist?(archive_path)
    puts "Archive '#{archive_name}' not found."
    return
  end
  Zip::File.open(archive_path) do |zipfile|
    zipfile.each do |entry|
      dest_path = entry.name
      FileUtils.mkdir_p(File.dirname(dest_path))
      entry.extract(dest_path) { true } # overwrite
    end
  end
  puts "Extracted '#{archive_name}' to current directory."
end

def main
  if ARGV.empty?
    puts "Usage: ruby archiver.rb <add|list|extract> [args...]"
    return
  end
  cmd = ARGV[0].downcase
  case cmd
  when 'add'
    if ARGV.length < 2
      puts "Usage: archiver.rb add <file/dir> [<file/dir>...]"
      return
    end
    add_files(ARGV[1..-1])
  when 'list'
    list_archives
  when 'extract'
    if ARGV.length != 2
      puts "Usage: archiver.rb extract <archive_name>"
      return
    end
    extract_archive(ARGV[1])
  else
    puts "Unknown command: #{cmd}"
  end
end

if __FILE__ == $0
  main
end
