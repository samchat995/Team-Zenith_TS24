import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9228;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Chrome for exact click coordinates...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,1000',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_exact',
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
    console.log(`Clicking at (${x}, ${y})`);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
    await sleep(60);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
  }

  await send('Page.enable');
  await send('Runtime.enable');

  console.log("Waiting for Flutter Web app to load...");
  await sleep(5000);

  // Click [⚡ Quick Login: Ifra] at EXACT center (420, 918)
  console.log("Clicking [Quick Login: Ifra] at (420, 918)...");
  await clickAt(420, 918);
  await sleep(3500);

  // Capture Home screen
  await capture('01_patient_home_verified.png');

  // Switch to Hindi: 'हिं' pill is at (508, 58) on login or on Home:
  // On Home screen: Header is at top:
  // Logo is at (405, 35)
  // 'EN' pill: (490, 35)
  // 'हिं' pill: (518, 35)
  // 'অস' pill: (546, 35)
  console.log("Clicking 'हिं' pill at (518, 35)...");
  await clickAt(518, 35);
  await sleep(2500);
  await capture('02_patient_home_hindi_verified.png');

  console.log("Clicking 'অস' pill at (546, 35)...");
  await clickAt(546, 35);
  await sleep(2500);
  await capture('03_patient_home_assamese_verified.png');

  console.log("Clicking 'EN' pill at (490, 35)...");
  await clickAt(490, 35);
  await sleep(2500);
  await capture('04_patient_home_english_restored.png');

  // Click Talk to Nia on Home screen:
  // The Nia card in 8-grid is at x=550, y=410
  console.log("Clicking Talk to Nia tile at (550, 410)...");
  await clickAt(550, 410);
  await sleep(3000);
  await capture('05_nia_screen_verified.png');

  // In Nia screen: click suggestion chip at (450, 115)
  console.log("Clicking prompt in Nia at (450, 115)...");
  await clickAt(450, 115);
  await sleep(3000);
  await capture('06_nia_chat_response_verified.png');

  // Go back from Nia: back button at (398, 36)
  console.log("Going back to Home from Nia...");
  await clickAt(398, 36);
  await sleep(2000);

  // Go to Settings tab: 5th tab in bottom nav at (665, 980)
  console.log("Clicking Settings tab at (665, 980)...");
  await clickAt(665, 980);
  await sleep(2500);
  await capture('07_settings_screen_verified.png');

  // Click Switch Account / Logout at (480, 520)
  console.log("Clicking Logout in settings at (480, 520)...");
  await clickAt(480, 520);
  await sleep(3000);
  await capture('08_back_to_login_screen.png');

  // Switch to Caregiver Login tab at (580, 370)
  console.log("Clicking Caregiver Login tab at (580, 370)...");
  await clickAt(580, 370);
  await sleep(2500);
  await capture('09_caregiver_login_form.png');

  // In Caregiver Login form:
  // Click "Quick Demo: Ananya Sharma" button at (480, 685)
  console.log("Clicking Quick Demo Ananya Sharma at (480, 685)...");
  await clickAt(480, 685);
  await sleep(3500);

  // Capture Caregiver Mobile Dashboard!
  await capture('10_caregiver_mobile_dashboard_verified.png');

  ws.close();
  chrome.kill();
  console.log("Exact verification finished successfully!");
}

run().catch(err => {
  console.error("Test failed:", err);
  process.exit(1);
});
