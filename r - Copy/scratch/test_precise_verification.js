import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9227;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Chrome for precise Patient Home verification...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,1000',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_precise',
    'http://localhost:8080'
  ]);

  await sleep(4000);

  const pagesRes = await fetch(`http://127.0.0.1:${PORT}/json/list`);
  const pages = await pagesRes.json();
  const targetPage = pages.find(p => p.url.includes('8080')) || pages.find(p => p.type === 'page');

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

  async function capture(filename) {
    const res = await send('Page.captureScreenshot', { format: 'png' });
    const filepath = `C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\${filename}`;
    fs.writeFileSync(filepath, Buffer.from(res.data, 'base64'));
    console.log(`Saved screenshot: ${filename}`);
  }

  async function clickAt(x, y) {
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await sleep(60);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  }

  await send('Page.enable');
  await send('Runtime.enable');

  console.log("Waiting for app to load...");
  await sleep(4500);

  // 1. Click Quick Login: Ifra button at (420, 945)
  console.log("Clicking [Quick Login: Ifra] at (420, 945)...");
  await clickAt(420, 945);
  await sleep(3500);

  // Capture Home screen
  await capture('verified_patient_home_en.png');

  // Check language switching on Home:
  // In the Home header, the pill is around x=708, y=36 for 'हिं'
  console.log("Clicking Hindi pill (हिं)...");
  await clickAt(708, 36);
  await sleep(2000);
  await capture('verified_patient_home_hi.png');

  console.log("Clicking Assamese pill (অস)...");
  await clickAt(738, 36);
  await sleep(2000);
  await capture('verified_patient_home_as.png');

  console.log("Clicking English pill (EN)...");
  await clickAt(675, 36);
  await sleep(2000);
  await capture('verified_patient_home_en_restored.png');

  // Now click on "Talk to Nia" (8-tile action grid item at bottom right of grid)
  // The grid has 2 cols, 4 rows. Grid item 8 (Nia) is around x=690, y=410
  console.log("Clicking Talk to Nia tile...");
  await clickAt(690, 410);
  await sleep(3000);
  await capture('verified_nia_screen.png');

  // In Nia screen:
  // Click first suggestion chip ("What reminders do I have?") around (460, 105)
  console.log("Clicking suggestion chip in Nia...");
  await clickAt(460, 105);
  await sleep(3000);
  await capture('verified_nia_chat_response.png');

  // Go back from Nia to Home: back button is at (380, 36)
  console.log("Going back to Home...");
  await clickAt(380, 36);
  await sleep(2000);

  // Now test Caregiver Mobile Flow:
  // Switch to Settings tab: bottom nav 5th icon (Settings) is at x=780, y=975
  console.log("Clicking Settings tab in bottom nav...");
  await clickAt(780, 975);
  await sleep(2000);
  await capture('verified_settings_screen.png');

  // Click Logout / Switch Account: near bottom of settings screen (approx x=600, y=700)
  console.log("Clicking Switch Account / Logout...");
  await clickAt(600, 700);
  await sleep(2500);
  await capture('verified_back_to_login.png');

  // On Login screen, switch to "Caregiver Login" tab (approx x=580, y=365)
  console.log("Switching to Caregiver Login tab...");
  await clickAt(580, 365);
  await sleep(2000);
  await capture('verified_caregiver_login_tab.png');

  // Click "Quick Demo: Ananya Sharma" or Sign In (approx x=600, y=650)
  console.log("Clicking Quick Demo: Ananya Sharma...");
  await clickAt(600, 650);
  await sleep(3000);
  await capture('verified_caregiver_mobile_dashboard.png');

  ws.close();
  chrome.kill();
  console.log("ALL VERIFICATIONS FINISHED!");
}

run().catch(err => {
  console.error("Test failed:", err);
  process.exit(1);
});
