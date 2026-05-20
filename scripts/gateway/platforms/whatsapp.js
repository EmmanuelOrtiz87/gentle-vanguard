import wweb from 'whatsapp-web.js';
import qrcode from 'qrcode-terminal';
import path from 'node:path';
import fs from 'node:fs';
import { generateReply } from '../ai-responder.js';

const { Client, LocalAuth } = wweb;

export async function startWhatsAppBot(cfg, onMessage, log) {
  if (!cfg.sessionDir) {
    log('whatsapp: no sessionDir configured, skipping');
    return null;
  }

  const sessionDir = path.resolve(cfg.sessionDir);
  fs.mkdirSync(sessionDir, { recursive: true });

  const client = new Client({
    authStrategy: new LocalAuth({ dataPath: sessionDir }),
    puppeteer: { headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox'] },
    webVersionCache: { type: 'remote', remotePath: 'https://raw.githubusercontent.com/wppconnect-team/wa-version/main/html/2.2412.54.html' },
  });

  let qrDisplayed = false;
  let readyResolved = false;
  let resolveReady;

  const readyPromise = new Promise((resolve) => { resolveReady = resolve; });

  client.on('qr', (qr) => {
    if (!qrDisplayed) {
      qrDisplayed = true;
      log('\nwhatsapp: === SCAN QR CODE WITH WHATSAPP ===');
      qrcode.generate(qr, { small: false });
    }
  });

  client.on('ready', () => {
    log(`whatsapp: connected as ${client.info?.pushname || client.info?.wid?.user || 'unknown'}`);
    if (!readyResolved) {
      readyResolved = true;
      resolveReady();
    }
  });

  client.on('message', async (msg) => {
    if (!msg.body) return;
    const isGroup = msg.from.includes('@g.us');
    if (isGroup) return;

    const senderRaw = msg.from.replace('@c.us', '').replace('@s.whatsapp.net', '');
    const isSelfMsg = msg.fromMe || senderRaw === (client.info?.wid?.user || '');
    const isAllowed = !cfg.allowedNumbers?.length || cfg.allowedNumbers.includes(senderRaw);

    if (!isAllowed && !isSelfMsg) return;

    onMessage({
      from: msg._data?.notifyName || senderRaw || 'unknown',
      text: msg.body,
      raw: { from: msg.from, isGroup: false, messageId: msg.id._serialized, timestamp: msg.timestamp },
    });

    let reply;
    if (isSelfMsg && cfg.ai?.enabled) {
      reply = `🤖 Procesando...\n\n"${msg.body.slice(0, 200)}"`;
      await client.sendMessage(msg.from, reply);
      const aiReply = await generateReply(cfg, msg.body, log);
      if (aiReply) {
        await client.sendMessage(msg.from, aiReply);
      } else {
        await client.sendMessage(msg.from, '❌ No pude procesar la respuesta.');
      }
    } else if (isSelfMsg) {
      reply = `🤖 *Gentle-Vanguard*\n\nRecibí: "${msg.body.slice(0, 200)}"\n\n📌 Para respuesta IA, configurá gateway.json → ai.enabled: true con tu API key.`;
      await client.sendMessage(msg.from, reply);
    } else if (isAllowed) {
      reply = `✅ Mensaje recibido — ID: ${msg.id.id}\nGracias por escribir.`;
      await client.sendMessage(msg.from, reply);
    }
  });

  client.on('disconnected', (reason) => {
    log(`whatsapp: disconnected (${reason})`);
    if (reason === 'LOGOUT') {
      log('whatsapp: logged out, clearing session...');
      fs.rmSync(path.join(sessionDir, 'LocalAuth'), { recursive: true, force: true });
      log('whatsapp: session cleared. Restart gateway to scan QR again.');
    }
  });

  client.on('auth_failure', (msg) => {
    log(`whatsapp: auth failure -> ${msg}`);
  });

  client.initialize();

  await readyPromise;

  const adapter = {
    platform: 'whatsapp',
    send: async (to, text) => {
      await client.sendMessage(to, text);
    },
    stop: async () => {
      await client.destroy();
    },
  };

  return adapter;
}
