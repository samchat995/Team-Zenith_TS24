import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9240;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Mobile Flow Verification (430x900)...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=430,900',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_mob_flow',
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
    console.log(`Click at (${x}, ${y})`);
    await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y });
    await sleep(60);
    await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', buttons: 1, clickCount: 1 });
    await sleep(100);
    await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', buttons: 0, clickCount: 1 });
  }

  await send('Page.enable');
  await send('Runtime.enable');
  await sleep(4500);

  // 1. Enter PIN 1-2-3-4
  console.log("Entering PIN 1...");
  await click(125, 650);
  await sleep(600);

  console.log("Entering PIN 2...");
  await click(215, 650);
  await sleep(600);

  console.log("Entering PIN 3...");
  await click(305, 650);
  await sleep(600);

  console.log("Entering PIN 4...");
  await click(125, 735);
  await sleep(3500);

  // 2. Verified Patient Home Screen in English
  await capture('01_HOME_ENGLISH.png');

  // 3. Switch Language to Hindi ('हिं' pill at top center: approx 260, 35)
  console.log("Switching to Hindi...");
  await click(260, 35);
  await sleep(2500);
  await capture('02_HOME_HINDI.png');

  // 4. Switch Language to Assamese ('অস' pill at top: approx 325, 35)
  console.log("Switching to Assamese...");
  await click(325, 35);
  await sleep(2500);
  await capture('03_HOME_ASSAMESE.png');

  // 5. Switch back to English ('EN' pill at approx 190, 35)
  console.log("Switching back to English...");
  await click(190, 35);
  await sleep(2500);
  await capture('04_HOME_ENGLISH_RESTORED.png');

  // 6. Test Nia: In Home screen, scroll down slightly or click Nia tile in 8-grid
  // Row 4 right tile (Nia) is at approx x=320, y=490
  console.log("Opening Nia Assistant...");
  await click(320, 490);
  await sleep(3000);
  await capture('05_NIA_SCREEN.png');

  // In Nia: click first prompt chip (What reminders do I have?) at approx x=130, y=130
  console.log("Clicking reminder query in Nia...");
  await click(130, 130);
  await sleep(3000);
  await capture('06_NIA_CHAT_REPLY.png');

  // Go back to Home: top-left back button at (25, 35)
  console.log("Returning to Home...");
  await click(25, 35);
  await sleep(2000);

  // 7. Test Caregiver Mobile Login
  // Bottom nav tab 5 (Settings) is at x=390, y=875
  console.log("Clicking Settings tab in bottom nav...");
  await click(390, 875);
  await sleep(2000);
  await capture('07_SETTINGS_TAB.png');

  // Scroll down and click Logout at (215, 620)
  console.log("Clicking Logout in settings...");
  await click(215, 620);
  await sleep(2500);
  await capture('08_LOGIN_SCREEN_AFTER_LOGOUT.png');

  // On Login screen, click "Caregiver Login" tab at (300, 375)
  console.log("Clicking Caregiver Login tab...");
  await click(300, 375);
  await sleep(2000);
  await capture('09_CAREGIVER_LOGIN_FORM.png');

  // In Caregiver form, click "Quick Demo: Ananya Sharma" at approx (215, 680)
  console.log("Clicking Quick Demo Ananya Sharma...");
  await click(215, 680);
  await sleep(3500);

  // Capture Caregiver Mobile Dashboard!
  await capture('10_CAREGIVER_MOBILE_DASHBOARD.png');

  ws.close();
  chrome.kill();
  console.log("MOBILE FLOW TEST FULLY COMPLETE!");
}

run().catch(console.error);
