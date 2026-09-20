import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9232;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Chrome for CDP mouse event verification...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,1000',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_cdp',
    'http://localhost:8080'
  ]);

  await sleep(4000);
  const pagesRes = await fetch(`http://127.0.0.1:${PORT}/json/list`);
  const pages = await pagesRes.json();
  const page = pages.find(p => p.url.includes('8080')) || pages[0];

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise(r => ws.onopen = r);

  let id = 1;
  function send(method, params = {}) {
    return new Promise((resolve) => {
      const msgId = id++;
      const handler = (event) => {
        const msg = JSON.parse(event.data);
        if (msg.id === msgId) {
          ws.removeEventListener('message', handler);
          resolve(msg.result);
        }
      };
      ws.addEventListener('message', handler);
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });
  }

  async function capture(filename) {
    const res = await send('Page.captureScreenshot', { format: 'png' });
    const filepath = `C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\${filename}`;
    fs.writeFileSync(filepath, Buffer.from(res.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  async function click(x, y) {
    console.log(`CDP Click at (${x}, ${y})`);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await sleep(40);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await sleep(80);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
  }

  await send('Page.enable');
  await send('Runtime.enable');
  await sleep(5000);

  // Click on "1" keypad button: (420, 615)
  console.log("Clicking '1'...");
  await click(420, 615);
  await sleep(400);

  // Click on "2" keypad button: (500, 615)
  console.log("Clicking '2'...");
  await click(500, 615);
  await sleep(400);

  // Click on "3" keypad button: (580, 615)
  console.log("Clicking '3'...");
  await click(580, 615);
  await sleep(400);

  // Click on "4" keypad button: (420, 695)
  console.log("Clicking '4'...");
  await click(420, 695);
  await sleep(400);

  // Click on '✓' keypad button: (580, 850)
  console.log("Clicking '✓'...");
  await click(580, 850);
  await sleep(4000);

  await capture('verified_after_pin_login.png');

  ws.close();
  chrome.kill();
}

run().catch(console.error);
