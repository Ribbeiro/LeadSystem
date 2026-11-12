// Modo demonstração: sobe tudo de graça, sem Docker e sem contas.
//
//   npm run demo           -> MongoDB local + API em http://localhost:3000
//   npm run demo:tunnel    -> idem + endereço HTTPS público (Cloudflare)
//
// - MongoDB: binário oficial baixado pelo mongodb-memory-server na primeira
//   execução; os dados ficam salvos em server/.data (persistem entre execuções).
// - E-mails: caixa de teste Ethereal (sem cadastro); o link para ver cada
//   e-mail aparece no console e no app.
// - HTTPS público: túnel rápido da Cloudflare (trycloudflare.com), sem conta.
//   O endereço muda a cada execução e só funciona com este computador ligado.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');

process.env.MAIL_MODE ||= 'ethereal';

const withTunnel = process.argv.includes('--tunnel');
const port = Number(process.env.PORT || 3000);
const dataDir = path.join(__dirname, '..', '.data', 'mongo');

function lanAddresses() {
  return Object.values(os.networkInterfaces())
    .flat()
    .filter((net) => net && net.family === 'IPv4' && !net.internal)
    .map((net) => net.address);
}

async function startTunnel() {
  const { bin, install, Tunnel } = require('cloudflared');
  if (!fs.existsSync(bin)) {
    console.log('Baixando o cloudflared (somente na primeira vez)...');
    await install(bin);
  }
  const tunnel = Tunnel.quick(`http://localhost:${port}`);
  const url = await new Promise((resolve, reject) => {
    tunnel.once('url', resolve);
    tunnel.once('error', reject);
    setTimeout(() => reject(new Error('Túnel não respondeu em 60 s.')), 60_000);
  });
  process.on('SIGINT', () => tunnel.stop());
  return url;
}

(async () => {
  fs.mkdirSync(dataDir, { recursive: true });
  console.log('Iniciando MongoDB local (primeira vez pode baixar ~70 MB)...');
  const { MongoMemoryServer } = require('mongodb-memory-server');
  const mongo = await MongoMemoryServer.create({
    instance: { dbPath: dataDir, storageEngine: 'wiredTiger', port: 27018 },
  });
  process.env.MONGODB_URI = mongo.getUri('leadsystem');

  let publicUrl = '';
  if (withTunnel) {
    try {
      publicUrl = await startTunnel();
      process.env.PUBLIC_URL = publicUrl;
    } catch (error) {
      console.warn(`Não foi possível abrir o túnel HTTPS: ${error.message}`);
    }
  }

  const mongoose = require('mongoose');
  await mongoose.connect(process.env.MONGODB_URI);
  const { createApp } = require('../src/app');
  const { seed } = require('../src/seed');
  await seed();

  createApp().listen(port, '0.0.0.0', () => {
    const lines = [
      '',
      '=== LeadSystem API (modo demonstração) ===',
      `Neste computador:  http://localhost:${port}`,
      `Emulador Android:  http://10.0.2.2:${port}`,
      ...lanAddresses().map((ip) => `Celular (Wi-Fi):   http://${ip}:${port}`),
    ];
    if (publicUrl) lines.push(`Qualquer rede (HTTPS): ${publicUrl}`);
    lines.push(
      '',
      'No app: Perfil > Servidor e sincronização > cole um dos endereços.',
      'Contas: leandro@email.com / Santi@2026 (admin) · carlos@email.com / Cliente@2026',
      'E-mails de teste: o link "ver e-mail" aparece aqui e no app.',
      'Ctrl+C para encerrar (os dados ficam em server/.data).',
      '',
    );
    console.log(lines.join('\n'));
  });

  const shutdown = async () => {
    await mongoose.disconnect().catch(() => {});
    await mongo.stop({ doCleanup: false }).catch(() => {});
    process.exit(0);
  };
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
