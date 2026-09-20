import { spawn } from 'child_process';

const CHROME_PATH = "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe";
const PORT = 9230;

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
    '--user-data-dir=C:\\Users\\Avay\\.gemini\\antigravity-ide\\brain\\dbc7f3b5-4b9b-4ed0-a82e-92a2154441da\\scratch\\chrome_sem',
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
  await sleep(4000);

  // Activate accessibility
  console.log("Activating Flutter accessibility...");
  await send('Runtime.evaluate', {
    expression: `
      (() => {
        const btn = document.querySelector('flt-semantics-placeholder');
        if (btn) btn.click();
      })()
    `
  });

  await sleep(2000);

  // Now inspect flt-semantics in glass-pane shadowRoot
  const res = await send('Runtime.evaluate', {
    expression: `
      (() => {
        const glass = document.querySelector('flt-glass-pane');
        if (!glass || !glass.shadowRoot) return [];
        const nodes = Array.from(glass.shadowRoot.querySelectorAll('flt-semantics, [aria-label]'));
        return nodes.map(n => ({
          tag: n.tagName,
          aria: n.getAttribute('aria-label'),
          text: n.innerText || n.textContent,
          role: n.getAttribute('role')
        })).filter(x => x.aria || (x.text && x.text.trim().length > 0)).slice(0, 40);
      })()
    `,
    returnByValue: true
  });

  console.log("Semantics Nodes found:", JSON.stringify(res.result.value, null, 2));

  ws.close();
  chrome.kill();
}

run().catch(console.error);
