import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9222;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Launching headless Chrome...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1280,900',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_profile'
  ]);

  await sleep(2000);

  // Get WebSocket debugger URL
  const versionRes = await fetch(`http://127.0.0.1:${PORT}/json/version`);
  const versionData = await versionRes.json();
  console.log("Browser version:", versionData.Browser);

  // Get WebSocket debugger URL from existing page
  const pagesRes = await fetch(`http://127.0.0.1:${PORT}/json/list`);
  const pages = await pagesRes.json();
  console.log("Pages found:", pages.length);
  const wsUrl = pages[0].webSocketDebuggerUrl;

  const ws = new WebSocket(wsUrl);
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

  async function captureScreenshot(filepath) {
    const res = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(filepath, Buffer.from(res.data, 'base64'));
    console.log("Saved screenshot:", filepath);
  }

  await send('Page.enable');
  await send('DOM.enable');
  await send('Runtime.enable');

  console.log("Navigating to http://localhost:5173...");
  await send('Page.navigate', { url: 'http://localhost:5173' });
  await sleep(2000);

  // Step 1: Click "Auto-fill" on Caregiver (Ananya)
  console.log("Clicking Auto-fill for Caregiver...");
  const autofilled = await evaluate(`
    (() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const autofillBtn = buttons.find(b => b.textContent.includes('Auto-fill'));
      if (autofillBtn) {
        autofillBtn.click();
        return true;
      }
      return false;
    })()
  `);
  console.log("Autofill result:", autofilled);
  await sleep(500);

  // Step 2: Click "Sign In to Console ->"
  console.log("Submitting login form...");
  const signedIn = await evaluate(`
    (() => {
      const buttons = Array.from(document.querySelectorAll('button'));
      const submitBtn = buttons.find(b => b.textContent.includes('Sign In to Console'));
      if (submitBtn) {
        submitBtn.click();
        return true;
      }
      return false;
    })()
  `);
  console.log("Submit clicked:", signedIn);
  await sleep(2500);

  // Step 3: Capture dashboard screenshot
  await captureScreenshot('C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\caregiver_web_dashboard.png');

  // Step 4: Verify Dashboard content
  const dashboardText = await evaluate(`document.body.innerText`);
  console.log("--- DASHBOARD TEXT SAMPLE ---");
  console.log(dashboardText.substring(0, 500));
  console.log("-----------------------------");

  // Step 5: Test patient selection Ifra
  console.log("Testing patient Ifra selection...");
  await evaluate(`
    (() => {
      const patientCards = Array.from(document.querySelectorAll('*'));
      const ifra = patientCards.find(el => el.textContent && el.textContent.includes('Ifra') && (el.tagName === 'BUTTON' || el.tagName === 'DIV' || el.onclick));
      if (ifra) ifra.click();
    })()
  `);
  await sleep(1500);

  // Step 6: Test patient selection Taiba
  console.log("Testing patient Taiba selection...");
  await evaluate(`
    (() => {
      const patientCards = Array.from(document.querySelectorAll('*'));
      const taiba = patientCards.find(el => el.textContent && el.textContent.includes('Taiba') && (el.tagName === 'BUTTON' || el.tagName === 'DIV' || el.onclick));
      if (taiba) taiba.click();
    })()
  `);
  await sleep(1500);

  await captureScreenshot('C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\caregiver_web_patient_detail.png');

  ws.close();
  chrome.kill();
  console.log("Caregiver Web Dashboard test completed successfully!");
}

run().catch(err => {
  console.error("Test failed:", err);
  process.exit(1);
});
