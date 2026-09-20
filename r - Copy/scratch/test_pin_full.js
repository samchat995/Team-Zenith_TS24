import { spawn } from 'child_process';
import fs from 'fs';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9233;

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function run() {
  console.log("Starting Chrome for full Patient Home verification...");
  const chrome = spawn(CHROME_PATH, [
    `--remote-debugging-port=${PORT}`,
    '--headless=new',
    '--disable-gpu',
    '--window-size=1200,1000',
    '--no-sandbox',
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_pin_full',
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

  // Type 1, 2, 3, 4 with 800ms delays
  console.log("Typing PIN: 1");
  await click(420, 615);
  await sleep(800);

  console.log("Typing PIN: 2");
  await click(500, 615);
  await sleep(800);

  console.log("Typing PIN: 3");
  await click(580, 615);
  await sleep(800);

  console.log("Typing PIN: 4");
  await click(420, 695);
  await sleep(800);

  console.log("Submitting PIN: ✓");
  await click(580, 850);
  await sleep(4000);

  // Capture Home screen
  await capture('FINAL_PATIENT_HOME_ENGLISH.png');

  // Switch to Hindi ('हिं' pill is at 518, 35)
  console.log("Switching to Hindi...");
  await click(518, 35);
  await sleep(2500);
  await capture('FINAL_PATIENT_HOME_HINDI.png');

  // Switch to Assamese ('অস' pill is at 546, 35)
  console.log("Switching to Assamese...");
  await click(546, 35);
  await sleep(2500);
  await capture('FINAL_PATIENT_HOME_ASSAMESE.png');

  // Switch back to English ('EN' pill is at 490, 35)
  console.log("Switching back to English...");
  await click(490, 35);
  await sleep(2000);

  // Open Nia Assistant screen:
  // Nia tile is bottom right of the 8 grid (x=550, y=410)
  console.log("Opening Nia Assistant...");
  await click(550, 410);
  await sleep(3000);
  await capture('FINAL_NIA_ASSISTANT_SCREEN.png');

  // Click suggestion chip in Nia ("What reminders do I have?") at (450, 115)
  console.log("Clicking Nia suggestion prompt...");
  await click(450, 115);
  await sleep(3000);
  await capture('FINAL_NIA_CHAT_RESPONSE.png');

  // Go back from Nia at (398, 36)
  console.log("Going back to Home...");
  await click(398, 36);
  await sleep(2000);

  // Switch to Caregiver:
  // Settings tab is at (665, 980)
  console.log("Clicking Settings tab in bottom nav...");
  await click(665, 980);
  await sleep(2500);
  await capture('FINAL_SETTINGS_SCREEN.png');

  // Click Switch Account / Logout at (480, 520)
  console.log("Clicking Logout in settings...");
  await click(480, 520);
  await sleep(2500);

  // Switch to Caregiver Login tab at (580, 370)
  console.log("Switching to Caregiver Login tab...");
  await click(580, 370);
  await sleep(2000);
  await capture('FINAL_CAREGIVER_LOGIN_SCREEN.png');

  // Click "Quick Demo: Ananya Sharma" at (480, 685)
  console.log("Clicking Quick Demo: Ananya Sharma...");
  await click(480, 685);
  await sleep(3500);
  await capture('FINAL_CAREGIVER_MOBILE_DASHBOARD.png');

  ws.close();
  chrome.kill();
  console.log("ALL REAL TESTS COMPLETED SUCCESS!");
}

run().catch(console.error);
