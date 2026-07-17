// archiver.js
const fs = require('fs');
const path = require('path');
const archiver = require('archiver'); // npm install archiver
const unzipper = require('unzipper'); // npm install unzipper

const CLOUD_DIR = 'cloud';

function ensureCloudDir() {
    if (!fs.existsSync(CLOUD_DIR)) {
        fs.mkdirSync(CLOUD_DIR, { recursive: true });
    }
}

function getArchiveName() {
    const now = new Date();
    const ts = `${now.getFullYear()}${String(now.getMonth()+1).padStart(2,'0')}${String(now.getDate()).padStart(2,'0')}_${String(now.getHours()).padStart(2,'0')}${String(now.getMinutes()).padStart(2,'0')}${String(now.getSeconds()).padStart(2,'0')}`;
    return `archive_${ts}.zip`;
}

function addFiles(filePaths) {
    ensureCloudDir();
    const archiveName = getArchiveName();
    const archivePath = path.join(CLOUD_DIR, archiveName);
    const output = fs.createWriteStream(archivePath);
    const archive = archiver('zip', { zlib: { level: 9 } });
    output.on('close', () => {
        console.log(`Archive created: ${archivePath}`);
    });
    archive.on('error', (err) => {
        console.error('Archive error:', err);
    });
    archive.pipe(output);
    for (const filePath of filePaths) {
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) {
            archive.directory(filePath, false);
        } else {
            archive.file(filePath, { name: path.basename(filePath) });
        }
    }
    archive.finalize();
}

function listArchives() {
    ensureCloudDir();
    const files = fs.readdirSync(CLOUD_DIR).filter(f => f.endsWith('.zip'));
    if (files.length === 0) {
        console.log('No archives found.');
        return;
    }
    console.log('Archives:');
    for (const f of files) {
        const stat = fs.statSync(path.join(CLOUD_DIR, f));
        console.log(`  ${f} (${stat.size} bytes)`);
    }
}

function extractArchive(archiveName) {
    ensureCloudDir();
    const archivePath = path.join(CLOUD_DIR, archiveName);
    if (!fs.existsSync(archivePath)) {
        console.log(`Archive '${archiveName}' not found.`);
        return;
    }
    fs.createReadStream(archivePath)
        .pipe(unzipper.Extract({ path: '.' }))
        .on('close', () => {
            console.log(`Extracted '${archiveName}' to current directory.`);
        })
        .on('error', (err) => {
            console.error('Extract error:', err);
        });
}

function main() {
    const args = process.argv.slice(2);
    if (args.length < 1) {
        console.log('Usage: node archiver.js <add|list|extract> [args...]');
        return;
    }
    const cmd = args[0];
    switch (cmd) {
        case 'add':
            if (args.length < 2) {
                console.log('Usage: archiver.js add <file/dir> [<file/dir>...]');
                return;
            }
            addFiles(args.slice(1));
            break;
        case 'list':
            listArchives();
            break;
        case 'extract':
            if (args.length !== 2) {
                console.log('Usage: archiver.js extract <archive_name>');
                return;
            }
            extractArchive(args[1]);
            break;
        default:
            console.log(`Unknown command: ${cmd}`);
    }
}

if (require.main === module) {
    main();
}
