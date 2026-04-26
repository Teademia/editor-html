import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import fs from 'node:fs/promises';
import path from 'node:path';

function imageSaverPlugin() {
  function detectImageExt(buffer, contentType = '') {
    if (buffer[0] === 0x89 && buffer[1] === 0x50 && buffer[2] === 0x4e && buffer[3] === 0x47) return '.png';
    if (buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) return '.jpg';
    if (
      buffer.slice(0, 4).toString('ascii') === 'RIFF'
      && buffer.slice(8, 12).toString('ascii') === 'WEBP'
    ) return '.webp';
    const type = contentType.toLowerCase();
    if (type.includes('png')) return '.png';
    if (type.includes('jpeg') || type.includes('jpg')) return '.jpg';
    if (type.includes('webp')) return '.webp';
    return '';
  }

  return {
    name: 'local-image-saver',
    configureServer(server) {
      server.middlewares.use('/api/save-generated-image', async (req, res) => {
        if (req.method !== 'POST') {
          res.statusCode = 405;
          res.end('Method Not Allowed');
          return;
        }

        try {
          let body = '';
          req.setEncoding('utf8');
          for await (const chunk of req) body += chunk;

          const { url, filename } = JSON.parse(body || '{}');
          if (!url || !filename) {
            res.statusCode = 400;
            res.end(JSON.stringify({ error: 'Missing url or filename' }));
            return;
          }

          let buffer;
          let contentType = '';
          if (String(url).startsWith('data:')) {
            const match = String(url).match(/^data:([^;,]+)?(;base64)?,(.*)$/);
            if (!match) throw new Error('Invalid data URL');
            contentType = match[1] || '';
            buffer = Buffer.from(decodeURIComponent(match[3]), match[2] ? 'base64' : 'utf8');
          } else {
            const response = await fetch(url);
            if (!response.ok) {
              throw new Error(`Fetch image failed: ${response.status}`);
            }
            contentType = response.headers.get('content-type') || '';
            buffer = Buffer.from(await response.arrayBuffer());
          }

          const ext = detectImageExt(buffer, contentType);
          if (!ext) {
            throw new Error('Downloaded file is not a supported image (png/jpg/webp)');
          }

          const requestedName = String(filename).replace(/[<>:"/\\|?*\x00-\x1F]/g, '_');
          const parsedName = path.parse(requestedName);
          const safeName = `${parsedName.name || 'background'}${ext}`;
          const targetDir = path.resolve(server.config.root, 'executor/assets/backgrounds');
          await fs.mkdir(targetDir, { recursive: true });
          await fs.writeFile(path.join(targetDir, safeName), buffer);

          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ path: `assets/backgrounds/${safeName}`, filename: safeName }));
        } catch (error) {
          res.statusCode = 500;
          res.setHeader('Content-Type', 'application/json');
          res.end(JSON.stringify({ error: error.message }));
        }
      });
    },
  };
}

export default defineConfig({
  plugins: [vue(), imageSaverPlugin()],
});
