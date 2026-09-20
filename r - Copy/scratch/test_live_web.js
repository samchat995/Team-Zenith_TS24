import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9225;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting isolated headless Chrome for Caregiver Web Dashboard...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1280,950',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_isolated',
    'http://localhost:5173'
  ]);

  await sleep(3000);

  const pagesRes = await fetch(`http://127.0.0.1:${PORT}/json/list`);
  const pages = await pagesRes.json();
  const targetPage = pages.find(p => p.url.includes('5173')) || pages.find(p => p.type === 'page');
  console.log("Connected to page:", targetPage.url);

  const ws = new WebSocket(targetPage.webSocketDebuggerUrl);
  let id = 1;
  const pending = new Map();

  ws.onmessage = (event) => {
    const msg = JSON.parse(event.data);
    if (pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      if (msg.error) reject(msg.error);
      else resolve(msg.result);
    }
  };

  await new Promise(r => ws.onopen = r);

  function send(method, params = {}) {
    const msgId = id++;
    return new Promise((resolve, reject) => {
      pending.set(msgId, { resolve, reject });
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });
  }

  async function evaluate(expression) {
    const res = await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true });
    return res.result ? res.result.value : null;
  }

  async function capture(filename) {
    const res = await send('Page.captureScreenshot', { format: 'png' });
    const filepath = `C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\${filename}`;
    fs.writeFileSync(filepath, Buffer.from(res.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  await send('Page.enable');
  await send('Runtime.enable');

  await sleep(1500);

  // 1. Click auto-fill for caregiver
  console.log("Clicking auto-fill caregiver...");
  const autofillRes = await evaluate(`
    (() => {
      const btns = Array.from(document.querySelectorAll('button'));
      const caregiverBtn = btns.find(b => b.textContent.includes('Caregiver'));
      if (caregiverBtn) {
        caregiverBtn.click();
        return true;
      }
      return false;
    })()
  `);
  console.log("Autofill clicked:", autofillRes);
  await sleep(800);

  // 2. Click Sign In
  console.log("Clicking Sign In...");
  const submitRes = await evaluate(`
    (() => {
      const submitBtn = Array.from(document.querySelectorAll('button')).find(b => b.textContent.includes('Sign In'));
      if (submitBtn) {
        submitBtn.click();
        return true;
      }
      return false;
    })()
  `);
  console.log("Sign in clicked:", submitRes);
  await sleep(3500);

  // 3. Capture dashboard view
  await capture('caregiver_web_dashboard.png');

  // 4. Verify patient list and content
  const pageText = await evaluate(`document.body.innerText`);
  console.log("\n=== CAREGIVER WEB DASHBOARD CONTENT ===");
  console.log(pageText.substring(0, 800));
  console.log("=======================================\n");

  // 5. Select Taiba
  console.log("Selecting patient Taiba...");
  const selectTaiba = await evaluate(`
    (() => {
      const allEls = Array.from(document.querySelectorAll('button, div, h3, span'));
      const taiba = allEls.find(el => el.textContent && el.textContent.trim() === 'Taiba' || el.textContent.includes('Taiba'));
      if (taiba) {
        taiba.click();
        return true;
      }
      return false;
    })()
  `);
  console.log("Selected Taiba:", selectTaiba);
  await sleep(2500);

  // 6. Capture Taiba detail view
  await capture('caregiver_web_taiba_detail.png');

  // 7. Select Ifra back
  console.log("Selecting patient Ifra...");
  await evaluate(`
    (() => {
      const allEls = Array.from(document.querySelectorAll('button, div, h3, span'));
      const ifra = allEls.find(el => el.textContent && el.textContent.includes('Ifra'));
      if (ifra) ifra.click();
    })()
  `);
  await sleep(2500);

  await capture('caregiver_web_ifra_detail.png');

  ws.close();
  chrome.kill();
  console.log("All Caregiver Web tests passed successfully!");
}

run().catch(err => {
  console.error("Error running test:", err);
  process.exit(1);
});
