import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9231;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,1000',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_ptr',
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

  await send('Page.enable');
  await send('Runtime.enable');
  await sleep(5000);

  // Dispatch PointerEvent to glass pane
  console.log("Dispatching PointerEvents to (420, 918)...");
  await send('Runtime.evaluate', {
    expression: `
      (() => {
        const glass = document.querySelector('flt-glass-pane');
        const target = glass || document.body;
        const x = 420;
        const y = 918;

        const pDown = new PointerEvent('pointerdown', {
          clientX: x, clientY: y,
          screenX: x, screenY: y,
          button: 0, buttons: 1,
          bubbles: true, cancelable: true,
          pointerId: 1, pointerType: 'mouse', isPrimary: true
        });
        const pUp = new PointerEvent('pointerup', {
          clientX: x, clientY: y,
          screenX: x, screenY: y,
          button: 0, buttons: 0,
          bubbles: true, cancelable: true,
          pointerId: 1, pointerType: 'mouse', isPrimary: true
        });

        target.dispatchEvent(pDown);
        setTimeout(() => target.dispatchEvent(pUp), 80);
        return true;
      })()
    `
  });

  await sleep(3500);

  const res = await send('Page.captureScreenshot', { format: 'png' });
  fs.writeFileSync('C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\pointer_test_result.png', Buffer.from(res.data, 'base64'));
  console.log("Saved pointer_test_result.png");

  ws.close();
  chrome.kill();
}

run().catch(console.error);
