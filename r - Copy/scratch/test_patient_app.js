import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9226;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Chrome for Patient App Testing...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,950',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_patient',
    'http://localhost:8080'
  ]);

  await sleep(3500);

  const pagesRes = await fetch(`http://127.0.0.1:${PORT}/json/list`);
  const pages = await pagesRes.json();
  const targetPage = pages.find(p => p.url.includes('8080')) || pages.find(p => p.type === 'page');
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

  async function clickAt(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await sleep(50);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  }

  await send('Page.enable');
  await send('Runtime.enable');

  console.log("Waiting for Flutter to initialize...");
  await sleep(6000);

  // 1. Capture Login Screen
  await capture('test_step1_login_screen.png');

  // In Flutter web (HTML/Canvas renderer), clicks on Flutter semantical nodes or coordinates:
  // Let's inspect text elements or semantics in DOM
  const domInfo = await evaluate(`
    (() => {
      const flt = document.querySelector('flt-glass-pane') || document.querySelector('flutter-view');
      const textElements = Array.from(document.querySelectorAll('flt-semantics, p, span, div, button'));
      return {
        hasFlutter: !!flt,
        texts: textElements.map(e => e.textContent || e.innerText || e.getAttribute('aria-label')).filter(Boolean).slice(0, 30)
      };
    })()
  `);
  console.log("DOM Info:", JSON.stringify(domInfo, null, 2));

  // The login screen has Quick Login button around center:
  // Window size is 1200 x 950. The center card is around x=600, y=500-750.
  // "Quick Login: Ifra (PIN 1234)" button is located right below the PIN dots.
  console.log("Clicking Quick Login (Ifra)...");
  // The quick login button is near (600, 680) or let's dispatch click
  await clickAt(600, 680);
  await sleep(3500);

  // 2. Capture Home Screen
  await capture('test_step2_home_screen.png');

  // Check if Home Screen is reached by checking for Header/Pills:
  // The language pill "हिं" is around top right (approx x=710, y=36)
  console.log("Clicking Hindi language pill...");
  await clickAt(710, 36);
  await sleep(2500);
  await capture('test_step3_home_hindi.png');

  console.log("Clicking Assamese language pill...");
  await clickAt(740, 36);
  await sleep(2500);
  await capture('test_step4_home_assamese.png');

  console.log("Clicking English language pill back...");
  await clickAt(675, 36);
  await sleep(2500);
  await capture('test_step5_home_english.png');

  // Test Talk to Nia banner button
  // Near bottom of home screen, or 8-tile grid item: Talk to Nia is bottom right of the 8 grid (approx x=660, y=470)
  console.log("Opening Nia Assistant...");
  await clickAt(660, 470);
  await sleep(3000);
  await capture('test_step6_nia_screen.png');

  // On Nia screen, click suggestion pill "What reminders do I have?" (approx x=450, y=105)
  console.log("Clicking prompt in Nia...");
  await clickAt(450, 105);
  await sleep(3000);
  await capture('test_step7_nia_response.png');

  // Close Nia: back arrow is at top left (x=380, y=35)
  console.log("Returning to Home from Nia...");
  await clickAt(380, 35);
  await sleep(2000);

  ws.close();
  chrome.kill();
  console.log("Patient App verification script finished!");
}

run().catch(err => {
  console.error("Test failed:", err);
  process.exit(1);
});
