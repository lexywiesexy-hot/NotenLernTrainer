const fs = require('fs');
const http = require('http');
const path = require('path');

const port = Number(process.env.PORT || 3000);
const rootDir = __dirname;
const htmlPath = path.join(rootDir, 'notenlerntrainer.html');

function sendFile(res, filePath) {
  fs.readFile(filePath, (error, data) => {
    if (error) {
      res.writeHead(error.code === 'ENOENT' ? 404 : 500, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end(error.code === 'ENOENT' ? 'Not found' : 'Server error');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    const types = {
      '.html': 'text/html; charset=utf-8',
      '.js': 'application/javascript; charset=utf-8',
      '.css': 'text/css; charset=utf-8',
      '.json': 'application/json; charset=utf-8'
    };

    const headers = {
      'Content-Type': types[ext] || 'application/octet-stream'
    };

    // Force fresh HTML on Railway/mobile browsers so the single-file app does not get stuck on stale markup.
    if (ext === '.html') {
      headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, proxy-revalidate';
      headers.Pragma = 'no-cache';
      headers.Expires = '0';
      headers.Surrogate-Control = 'no-store';
    }

    res.writeHead(200, headers);
    res.end(data);
  });
}

http.createServer((req, res) => {
  const pathname = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`).pathname;

  if (pathname === '/' || pathname === '/index.html' || pathname === '/notenlerntrainer.html') {
    sendFile(res, htmlPath);
    return;
  }

  sendFile(res, path.join(rootDir, pathname.replace(/^\/+/, '')));
}).listen(port, '0.0.0.0', () => {
  console.log(`Server listening on ${port}`);
});
