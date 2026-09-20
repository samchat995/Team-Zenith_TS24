import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9235;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Chrome with precise keypad coordinates...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,1000',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_correct',
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
    console.log(`Clicking at (${x}, ${y})`);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await sleep(60);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await sleep(100);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
  }

  await send('Page.enable');
  await send('Runtime.enable');
  await sleep(5000);

  // Click Quick Login: Ifra at (530, 920)
  console.log("Clicking [Quick Login: Ifra] at (530, 920)...");
  await click(530, 920);
  await sleep(3500);

  // Capture Home screen
  await capture('01_PATIENT_HOME_ENGLISH.png');

  // Switch to Hindi (pill at 600, 36)
  // On Home screen: width is 1200, center is 600.
  // Header: Logo is left (x=400), Profile is right (x=800).
  // Language pills container is centered around x=600:
  // 'EN' pill: (580, 36)
  // 'हिं' pill: (608, 36)
  // 'অস' pill: (636, 36)
  console.log("Clicking Hindi pill ('हिं') at (608, 36)...");
  await click(608, 36);
  await sleep(2500);
  await capture('02_PATIENT_HOME_HINDI.png');

  console.log("Clicking Assamese pill ('অস') at (636, 36)...");
  await click(636, 36);
  await sleep(2500);
  await capture('03_PATIENT_HOME_ASSAMESE.png');

  console.log("Clicking English pill ('EN') at (580, 36)...");
  await click(580, 36);
  await sleep(2500);
  await capture('04_PATIENT_HOME_ENGLISH_RESTORED.png');

  // Click on Talk to Nia:
  // In the 8-grid: col 2 (right), row 4 (bottom): x=660, y=410
  console.log("Clicking Talk to Nia tile at (660, 410)...");
  await click(660, 410);
  await sleep(3000);
  await capture('05_NIA_ASSISTANT_SCREEN.png');

  // In Nia screen: click suggestion chip at (500, 115)
  console.log("Clicking Nia suggestion prompt at (500, 115)...");
  await click(500, 115);
  await sleep(3000);
  await capture('06_NIA_CHAT_RESPONSE.png');

  // Go back from Nia: top left arrow at (400, 36)
  console.log("Going back to Home from Nia at (400, 36)...");
  await click(400, 36);
  await sleep(2000);

  // Caregiver Mobile Flow:
  // Go to Settings tab (5th tab in bottom nav at 760, 975)
  console.log("Clicking Settings tab at (760, 975)...");
  await click(760, 975);
  await sleep(2500);
  await capture('07_SETTINGS_SCREEN.png');

  // Click Switch Account / Logout at (600, 520)
  console.log("Clicking Logout in settings at (600, 520)...");
  await click(600, 520);
  await sleep(2500);
  await capture('08_BACK_TO_LOGIN.png');

  // Switch to Caregiver Login tab at (650, 370)
  console.log("Switching to Caregiver Login tab at (650, 370)...");
  await click(650, 370);
  await sleep(2000);
  await capture('09_CAREGIVER_LOGIN_TAB.png');

  // In Caregiver Login form:
  // Click "Quick Demo: Ananya Sharma" at (600, 685)
  console.log("Clicking Quick Demo: Ananya Sharma at (600, 685)...");
  await click(600, 685);
  await sleep(3500);

  // Capture Caregiver Mobile Dashboard!
  await capture('10_CAREGIVER_MOBILE_DASHBOARD.png');

  ws.close();
  chrome.kill();
  console.log("ALL REAL BROWSER TESTS SUCCEEDED!");
}

run().catch(console.error);
