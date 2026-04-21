#!/bin/bash
echo "=========================================="
echo "         File Share Server Setup "
echo "=========================================="

# 1. Create package.json if not exists
if [ ! -f package.json ]; then
    echo "Creating package.json..."
    npm init -y > /dev/null
fi

# 2. Install dependencies
echo "Installing dependencies..."
npm install express multer cors

# 3. Create server uploads folder
SERVER_PATH="/data/data/com.termux/files/home/storage/shared/Download/server"
mkdir -p "$SERVER_PATH"

# 4. Create server.js
cat > server.js << 'EOF'
const express = require('express');
const multer = require('multer');
const path = require('path');
const cors = require('cors');
const fs = require('fs');
const os = require('os');

// প্রথমে app তৈরি করুন
const app = express();

// তারপর app.use() গুলো ব্যবহার করুন
app.use(cors());
app.use(express.static('./'));

// Large file support & speed optimization (app তৈরি করার পর)
app.use(express.json({ limit: '100gb' }));
app.use(express.urlencoded({ limit: '100gb', extended: true }));

// Increase timeouts for large files
app.use((req, res, next) => {
    req.setTimeout(3600000); // 1 hour timeout
    res.setTimeout(3600000); // 1 hour timeout
    next();
});

const SERVER_UPLOAD_PATH = '/data/data/com.termux/files/home/storage/shared/Download/server';

app.use('/view-file', express.static(SERVER_UPLOAD_PATH));

if (!fs.existsSync(SERVER_UPLOAD_PATH)) {
    fs.mkdirSync(SERVER_UPLOAD_PATH, { recursive: true });
}

const storage = multer.diskStorage({
    destination: (req, file, cb) => { cb(null, SERVER_UPLOAD_PATH); },
    filename: (req, file, cb) => {
        const timestamp = Date.now();
        const extension = path.extname(file.originalname);
        const name = path.basename(file.originalname, extension).replace(/[^a-zA-Z0-9]/g, '_');
        cb(null, `${name}_${timestamp}${extension}`);
    }
});

const upload = multer({ 
    storage: storage, 
    limits: { fileSize: 100 * 1024 * 1024 * 1024 }, // 100 GB
    preservePath: false
});

function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return '127.0.0.1';
}

app.post('/upload', upload.single('file'), (req, res) => {
    if (!req.file) return res.json({ success: false, message: 'No file selected' });
    res.json({ success: true, message: 'Uploaded successfully' });
});

app.get('/download/:filename', (req, res) => {
    const filePath = path.join(SERVER_UPLOAD_PATH, decodeURIComponent(req.params.filename));
    res.download(filePath);
});

app.get('/files', (req, res) => {
    fs.readdir(SERVER_UPLOAD_PATH, (err, files) => {
        if (err) return res.json({ success: false });
        const fileList = files.map(file => {
            try {
                const stats = fs.statSync(path.join(SERVER_UPLOAD_PATH, file));
                return { name: file, size: stats.size, created: stats.ctime };
            } catch (e) { return null; }
        }).filter(f => f);
        res.json({ success: true, files: fileList });
    });
});

const PORT = 3000;
const localIP = getLocalIP();

app.listen(PORT, () => {
    console.log('==========================================');
    console.log('     Cloud Share Server Started');
    console.log('==========================================');
    console.log(`🚀 Local:    http://localhost:${PORT}`);
    console.log(`🌐 Network:  http://${localIP}:${PORT}`);
    console.log('==========================================');
    console.log('📱 Share this link with friends on same WiFi:');
    console.log(`   🔗 http://${localIP}:${PORT}`);  
    console.log('==========================================');
});
EOF

# 5. Create index.html (Updated with img tags)
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>anonymous</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="container">
        <header class="header">
            <div class="logo">
                <img src="assist/share.svg" alt="Logo">
                <h1>Cloud Share</h1>
            </div>
            <div id="fileCount" class="badge">0 files</div>
        </header>

        <main class="content">
            <div class="card">
                <input type="file" id="fileInput" hidden>
                <div class="drop-zone" onclick="document.getElementById('fileInput').click()">
                    <img src="assist/upload.svg" alt="Upload Icon" class="upload-img">
                    <p>Tap to Upload</p>
                </div>
                <div id="selectedFile" class="selected-file-box" style="display:none">
                    <div id="filePreview"></div>
                    <div class="upload-btns">
                        <button class="btn btn-primary" onclick="uploadFile()">Upload Now</button>
                        <button class="btn btn-outline" onclick="clearSelection()">Cancel</button>
                    </div>
                </div>
                <div id="progressSection" class="progress-container" style="display:none">
                    <div class="progress-bar"><div id="progressFill"></div></div>
                    <span id="progressPercentage">0%</span>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h3>Files</h3>
                    <button class="refresh-btn" onclick="loadFiles()">
                        <img src="assist/reload.svg" alt="Sync" style="width: 20px;">
                    </button>
                </div>
                <div id="filesList" class="files-list"></div>
                <div id="emptyState" class="empty-state">No files shared yet</div>
            </div>
        </main>
    </div>
    <script src="script.js"></script>
</body>
</html>
EOF

# 6. Create style.css
cat > style.css << 'EOF'
:root {
    --primary: #4f46e5;
    --danger: #ef4444;
    --success: #10b981;
    --bg: #f3f4f6;
    --card: #ffffff;
}

* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

body {
    background: var(--bg);
    color: #1f2937;
}

.container {
    max-width: 600px;
    margin: 0 auto;
}

.header {
    background: var(--primary);
    color: white;
    padding: 20px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-radius: 0 0 15px 15px;
}

.logo {
    display: flex;
    align-items: center;
    gap: 10px;
}

.logo img {
    width: 35px;
    height: 35px;
}

.badge {
    background: rgba(255, 255, 255, 0.2);
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 0.8rem;
}

.content {
    padding: 15px;
    display: flex;
    flex-direction: column;
    gap: 15px;
}

.card {
    background: var(--card);
    border-radius: 12px;
    padding: 15px;
    box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
}

.card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
}

.drop-zone {
    border: 2px dashed #cbd5e1;
    border-radius: 10px;
    padding: 25px;
    text-align: center;
    cursor: pointer;
    transition: 0.3s;
}

.drop-zone:hover {
    background: #f8fafc;
    border-color: var(--primary);
}

.upload-img {
    width: 50px;
    margin-bottom: 10px;
}

.file-item {
    display: flex;
    align-items: center;
    padding: 12px;
    border-bottom: 1px solid #f1f5f9;
    gap: 12px;
}

.file-icon img {
    width: 40px;
    height: 40px;
    object-fit: contain;
}

.file-info {
    flex-grow: 1;
    overflow: hidden;
}

.file-name {
    font-weight: 600;
    font-size: 0.9rem;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: #334155;
}

.file-meta {
    font-size: 0.75rem;
    color: #64748b;
}

.action-btns {
    display: flex;
    gap: 8px;
}

.btn-icon {
    border: none;
    padding: 8px;
    border-radius: 8px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: 0.2s;
}

.btn-icon img {
    width: 18px;
    filter: invert(1);
}

.btn-view {
    background: var(--success);
}

.btn-download {
    background: var(--primary);
}

.progress-bar {
    height: 8px;
    background: #e2e8f0;
    border-radius: 4px;
    overflow: hidden;
    margin-top: 10px;
}

#progressFill {
    height: 100%;
    background: var(--primary);
    width: 0%;
    transition: 0.2s;
}

.upload-btns {
    display: flex;
    gap: 10px;
    margin-top: 10px;
}

.btn {
    flex: 1;
    padding: 12px;
    border-radius: 8px;
    border: none;
    font-weight: bold;
    cursor: pointer;
}

.btn-primary {
    background: var(--primary);
    color: white;
}

.btn-outline {
    background: #f1f5f9;
    color: #475569;
}

.refresh-btn {
    background: none;
    border: none;
    cursor: pointer;
    padding: 5px;
}

.empty-state {
    text-align: center;
    padding: 20px;
    color: #94a3b8;
    font-size: 0.9rem;
}
EOF

# 7. Create script.js (Updated with image-based icon logic)
cat > script.js << 'EOF'
const fileInput = document.getElementById('fileInput');
const filesList = document.getElementById('filesList');

function getFileIcon(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const base = "assist/";
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].includes(ext)) return base + "picture.svg";
    if (['mp4', 'webm', 'mov', 'avi'].includes(ext)) return base + "video.svg";
    if (['mp3', 'wav', 'ogg'].includes(ext)) return base + "audio.svg";
    if (['pdf'].includes(ext)) return base + "pdf.svg";
    if (['zip', 'rar', '7z'].includes(ext)) return base + "zip.svg";
    if (['txt', 'doc', 'docx'].includes(ext)) return base + "xlsx.svg";
    
    return base + "file-question.svg"; // Default
}

async function loadFiles() {
    const res = await fetch('/files');
    const data = await res.json();
    if (!data.success) return;

    document.getElementById('fileCount').textContent = `${data.files.length} files`;
    document.getElementById('emptyState').style.display = data.files.length ? 'none' : 'block';
    
    filesList.innerHTML = data.files.map(file => {
    const ext = file.name.split('.').pop().toLowerCase();
    const isViewable = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'mp4', 'webm', 'mov', 'avi', 'mp3', 'wav', 'ogg'].includes(ext);
    
    return `
    <div class="file-item">
        <div class="file-icon">
            <img src="${getFileIcon(file.name)}" alt="file-icon">
        </div>
        <div class="file-info">
            <div class="file-name">${file.name}</div>
            <div class="file-meta">${(file.size/1024/1024).toFixed(2)} MB</div>
        </div>
        <div class="action-btns">
            ${isViewable ? `<button class="btn-icon btn-view" onclick="window.open('/view-file/${encodeURIComponent(file.name)}')">
                <img src="assist/view.svg" alt="view">
            </button>` : ''}
            <button class="btn-icon btn-download" onclick="window.location.href='/download/${encodeURIComponent(file.name)}'">
                <img src="assist/download.svg" alt="download">
            </button>
        </div>
    </div>
    `;
}).join('');
}

fileInput.onchange = () => {
    if(fileInput.files[0]) {
        document.getElementById('selectedFile').style.display = 'block';
        document.getElementById('filePreview').innerHTML = `<p style="font-size: 0.9rem; color: #444;">Selected: <b>${fileInput.files[0].name}</b></p>`;
    }
};

function uploadFile() {
    const file = fileInput.files[0];
    if(!file) return;
    
    // Check file size (100GB limit)
    if(file.size > 100 * 1024 * 1024 * 1024) {
        alert('File too large! Maximum 100GB allowed.');
        return;
    }
    
    const formData = new FormData();
    formData.append('file', file);

    const xhr = new XMLHttpRequest();
    document.getElementById('progressSection').style.display = 'block';

    const startTime = Date.now(); 
    
    // Speed optimization: increase chunk size
    xhr.upload.onprogress = (e) => {
        if(e.lengthComputable) {
            const p = Math.round((e.loaded / e.total) * 100);
            const speed = (e.loaded / 1024 / 1024 / (Date.now() - startTime) * 1000).toFixed(2);
            document.getElementById('progressFill').style.width = p + '%';
            document.getElementById('progressPercentage').innerHTML = `${p}% <span style="font-size: 0.7rem;">(${speed} MB/s)</span>`;
        }
    };

    
    xhr.onload = () => {
        if(xhr.status === 200) {
            alert('Upload Success!');
            location.reload();
        } else {
            alert('Upload Failed!');
        }
    };

    xhr.open('POST', '/upload');
    xhr.send(formData);
}

function clearSelection() {
    fileInput.value = '';
    document.getElementById('selectedFile').style.display = 'none';
}

loadFiles();



EOF

echo "Setup Complete! Run 'node server.js' to start."
