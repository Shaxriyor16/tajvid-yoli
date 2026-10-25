// Script to generate PNG image assets for Tajvid Yo'li app
const fs = require('fs');
const zlib = require('zlib');
const path = require('path');

// PNG file structure helpers
function pngChunk(type, data) {
  const length = Buffer.alloc(4);
  length.writeUInt32BE(data.length, 0);
  const typeBuffer = Buffer.from(type, 'ascii');
  const crcBuffer = Buffer.alloc(4);
  const crc = zlib.crc32(Buffer.concat([typeBuffer, data]));
  crcBuffer.writeUInt32BE(crc >>> 0, 0);
  return Buffer.concat([length, typeBuffer, data, crcBuffer]);
}

function createPNG(width, height, pixelData) {
  // PNG signature
  const signature = Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

  // IHDR chunk
  const ihdrData = Buffer.alloc(13);
  ihdrData.writeUInt32BE(width, 0);
  ihdrData.writeUInt32BE(height, 4);
  ihdrData[8] = 8;   // bit depth
  ihdrData[9] = 2;   // color type: RGB
  ihdrData[10] = 0;  // compression
  ihdrData[11] = 0;  // filter
  ihdrData[12] = 0;  // interlace
  const ihdr = pngChunk('IHDR', ihdrData);

  // IDAT chunk - add filter byte (0) at start of each row
  const rawData = Buffer.alloc(height * (1 + width * 3));
  for (let y = 0; y < height; y++) {
    rawData[y * (1 + width * 3)] = 0; // filter type: none
    for (let x = 0; x < width; x++) {
      const srcIdx = (y * width + x) * 3;
      const dstIdx = y * (1 + width * 3) + 1 + x * 3;
      rawData[dstIdx] = pixelData[srcIdx];
      rawData[dstIdx + 1] = pixelData[srcIdx + 1];
      rawData[dstIdx + 2] = pixelData[srcIdx + 2];
    }
  }
  const compressed = zlib.deflateSync(rawData);
  const idat = pngChunk('IDAT', compressed);

  // IEND chunk
  const iend = pngChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdr, idat, iend]);
}

function lerp(a, b, t) {
  return Math.round(a + (b - a) * t);
}

// Create directories
const dirs = ['assets/images', 'assets/icons'];
dirs.forEach(d => {
  const fullPath = path.join(__dirname, d);
  if (!fs.existsSync(fullPath)) {
    fs.mkdirSync(fullPath, { recursive: true });
  }
});

// 1. Register illustration - gradient background with abstract Islamic pattern
function createRegisterIllustration() {
  const width = 400, height = 300;
  const pixels = Buffer.alloc(width * height * 3);

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = (y * width + x) * 3;
      // Gradient from dark teal to emerald
      const t = y / height;
      const t2 = x / width;
      const r = lerp(10, 63, t * 0.7 + t2 * 0.3);
      const g = lerp(26, 170, t * 0.7 + t2 * 0.3);
      const b = lerp(18, 168, t * 0.7 + t2 * 0.3);

      // Add subtle star pattern
      if ((x + y) % 47 === 0 && Math.random() > 0.3) {
        const star = 1.3;
        pixels[idx] = Math.min(255, r * star);
        pixels[idx + 1] = Math.min(255, g * star);
        pixels[idx + 2] = Math.min(255, b * star);
      } else {
        pixels[idx] = r;
        pixels[idx + 1] = g;
        pixels[idx + 2] = b;
      }
    }
  }

  // Draw a simple crescent moon shape
  const moonCx = 200, moonCy = 120, moonR = 50;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const dx = x - moonCx, dy = y - moonCy;
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < moonR) {
        // Check if inside the crescent (subtract a smaller circle)
        const dx2 = x - (moonCx + 15), dy2 = y - moonCy;
        const dist2 = Math.sqrt(dx2 * dx2 + dy2 * dy2);
        if (dist2 > moonR - 15) {
          const idx = (y * width + x) * 3;
          pixels[idx] = 246;
          pixels[idx + 1] = 226;
          pixels[idx + 2] = 168;
        }
      }
    }
  }

  return createPNG(width, height, pixels);
}

// 2. Prayer times illustration - mosque silhouette
function createPrayerTimesIllustration() {
  const width = 400, height = 250;
  const pixels = Buffer.alloc(width * height * 3);

  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const idx = (y * width + x) * 3;
      const t = y / height;
      // Gradient from dark to lighter teal
      pixels[idx] = lerp(5, 18, t * 0.5);
      pixels[idx + 1] = lerp(15, 35, t * 0.5);
      pixels[idx + 2] = lerp(14, 31, t * 0.5);
    }
  }

  // Draw minarets and dome (simplified)
  function drawRect(x1, y1, x2, y2, r, g, b) {
    for (let y = y1; y < y2; y++) {
      for (let x = x1; x < x2; x++) {
        const idx = (y * width + x) * 3;
        pixels[idx] = r;
        pixels[idx + 1] = g;
        pixels[idx + 2] = b;
      }
    }
  }

  function drawCircle(cx, cy, radius, r, g, b) {
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const dx = x - cx, dy = y - cy;
        if (dx * dx + dy * dy < radius * radius) {
          const idx = (y * width + x) * 3;
          pixels[idx] = r;
          pixels[idx + 1] = g;
          pixels[idx + 2] = b;
        }
      }
    }
  }

  // Main dome
  drawCircle(200, 140, 55, 63, 170, 168);
  // Dome base
  drawRect(145, 140, 255, 170, 234, 210, 148);

  // Left minaret
  drawRect(80, 100, 95, 170, 234, 210, 148);
  drawCircle(87, 95, 12, 234, 210, 148);

  // Right minaret
  drawRect(305, 100, 320, 170, 234, 210, 148);
  drawCircle(312, 95, 12, 234, 210, 148);

  // Ground
  drawRect(0, 170, width, height, 10, 26, 18);

  return createPNG(width, height, pixels);
}

// 3. Google icon
function createGoogleIcon() {
  const size = 48;
  const pixels = Buffer.alloc(size * size * 3);

  // White background
  for (let i = 0; i < pixels.length; i++) {
    pixels[i] = 255;
  }

  // Google colors: blue, red, yellow, green
  // Simplified: draw 4 colored quarters
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const idx = (y * size + x) * 3;
      const cx = x - 24, cy = y - 24;
      const dist = Math.sqrt(cx * cx + cy * cy);

      if (dist < 18) {
        // Blue (top)
        if (cy < 0) {
          pixels[idx] = 66; pixels[idx + 1] = 133; pixels[idx + 2] = 244;
        }
        // Red (top-right)
        else if (cx > 0) {
          pixels[idx] = 234; pixels[idx + 1] = 67; pixels[idx + 2] = 53;
        }
        // Yellow (bottom)
        else if (cy > 0) {
          pixels[idx] = 251; pixels[idx + 1] = 188; pixels[idx + 2] = 4;
        }
        // Green (bottom-left)
        else {
          pixels[idx] = 52; pixels[idx + 1] = 168; pixels[idx + 2] = 83;
        }
      }
    }
  }

  return createPNG(size, size, pixels);
}

// 4. Apple icon
function createAppleIcon() {
  const size = 48;
  const pixels = Buffer.alloc(size * size * 3);

  // White background
  for (let i = 0; i < pixels.length; i++) {
    pixels[i] = 255;
  }

  // Draw apple shape (simplified)
  function drawPixel(x, y, r, g, b) {
    if (x >= 0 && x < size && y >= 0 && y < size) {
      const idx = (y * size + x) * 3;
      pixels[idx] = r;
      pixels[idx + 1] = g;
      pixels[idx + 2] = b;
    }
  }

  // Apple body - draw a simple apple shape
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const dx = x - 24, dy = y - 24;
      // Apple shape: circle with a bite
      const dist = Math.sqrt(dx * dx + dy * dy);
      if (dist < 16) {
        // Check for bite on the right
        if (dx > 8 && dy > -4) continue;
        drawPixel(x, y, 0, 0, 0);
      }
    }
  }

  // Apple leaf
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const dx = x - 24, dy = y - 24;
      if (dx > -6 && dx < 6 && dy > -20 && dy < -14) {
        drawPixel(x, y, 46, 125, 50);
      }
    }
  }

  return createPNG(size, size, pixels);
}

// Generate all images
const images = {
  'assets/images/register_illustration.png': createRegisterIllustration(),
  'assets/images/prayer_times_illustration.png': createPrayerTimesIllustration(),
  'assets/icons/google.png': createGoogleIcon(),
  'assets/icons/apple.png': createAppleIcon(),
};

Object.entries(images).forEach(([filename, data]) => {
  const fullPath = path.join(__dirname, filename);
  fs.writeFileSync(fullPath, data);
  console.log(`Created: ${filename} (${data.length} bytes)`);
});

console.log('\nAll assets generated successfully!');
