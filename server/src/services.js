const nodemailer = require('nodemailer');
const config = require('./config');

// ---------------------------------------------------------------- e-mail

let transport;

/**
 * Envia e-mail. Modos (config.mailMode):
 * - smtp: servidor SMTP do .env (ex.: Gmail com senha de app);
 * - ethereal: caixa de teste gratuita do nodemailer, criada na hora e sem
 *   cadastro; devolve previewUrl para abrir o e-mail no navegador;
 * - console: apenas registra no console (padrão sem configuração).
 */
async function sendMail({ to, subject, text }) {
  sendMail.outbox.push({ to, subject, text });
  if (config.mailMode === 'console') {
    if (!config.isTest) {
      console.info(`[e-mail simulado] Para: ${to}
Assunto: ${subject}
${text}`);
    }
    return { simulated: true };
  }
  if (!transport) {
    if (config.mailMode === 'ethereal') {
      const account = await nodemailer.createTestAccount();
      transport = nodemailer.createTransport({
        host: account.smtp.host,
        port: account.smtp.port,
        secure: account.smtp.secure,
        auth: { user: account.user, pass: account.pass },
      });
    } else {
      transport = nodemailer.createTransport({
        host: config.smtp.host,
        port: config.smtp.port,
        secure: config.smtp.secure,
        auth: config.smtp.user
          ? { user: config.smtp.user, pass: config.smtp.pass }
          : undefined,
      });
    }
  }
  const info = await transport.sendMail({ from: config.smtp.from, to, subject, text });
  const previewUrl = nodemailer.getTestMessageUrl(info) || undefined;
  if (previewUrl) console.info(`[e-mail de teste] ${subject} -> ver em ${previewUrl}`);
  return { simulated: false, previewUrl };
}
sendMail.outbox = [];

// ---------------------------------------------------------------- frete

const SERVICE_NAMES = { '03220': 'SEDEX', '03298': 'PAC' };

/** Frete estimado por região (usado sem contrato dos Correios). */
function estimateShipping(cep) {
  const region = Number(cep.slice(0, 1));
  // Faixas por região do CEP a partir de Santo André/SP (origem da loja).
  const table = [
    { pac: 24.9, sedex: 39.9, pacDays: 4, sedexDays: 2 }, // 0 - Grande SP
    { pac: 29.9, sedex: 49.9, pacDays: 6, sedexDays: 3 }, // 1 - interior SP
    { pac: 39.9, sedex: 64.9, pacDays: 8, sedexDays: 4 }, // 2 - RJ/ES
    { pac: 39.9, sedex: 64.9, pacDays: 8, sedexDays: 4 }, // 3 - MG
    { pac: 54.9, sedex: 89.9, pacDays: 10, sedexDays: 5 }, // 4 - BA/SE
    { pac: 59.9, sedex: 99.9, pacDays: 12, sedexDays: 6 }, // 5 - PE/AL/PB/RN
    { pac: 69.9, sedex: 119.9, pacDays: 14, sedexDays: 7 }, // 6 - CE/PI/MA/PA/AM...
    { pac: 54.9, sedex: 89.9, pacDays: 10, sedexDays: 5 }, // 7 - DF/GO/TO/MT/MS/RO/AC
    { pac: 34.9, sedex: 59.9, pacDays: 7, sedexDays: 3 }, // 8 - PR/SC
    { pac: 39.9, sedex: 64.9, pacDays: 8, sedexDays: 4 }, // 9 - RS
  ][region];
  return [
    { service: 'PAC', price: table.pac, days: table.pacDays },
    { service: 'SEDEX', price: table.sedex, days: table.sedexDays },
  ];
}

let correiosToken;

async function correiosAuth() {
  if (correiosToken && correiosToken.expiresAt > Date.now() + 60_000) {
    return correiosToken.value;
  }
  const { user, accessCode, postCard } = config.correios;
  const response = await fetch(
    'https://api.correios.com.br/token/v1/autentica/cartaopostagem',
    {
      method: 'POST',
      headers: {
        Authorization: `Basic ${Buffer.from(`${user}:${accessCode}`).toString('base64')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ numero: postCard }),
      signal: AbortSignal.timeout(8000),
    },
  );
  if (!response.ok) throw new Error(`Correios auth ${response.status}`);
  const data = await response.json();
  correiosToken = {
    value: data.token,
    expiresAt: new Date(data.expiraEm).getTime() || Date.now() + 30 * 60_000,
  };
  return correiosToken.value;
}

/**
 * Cotação real pela API dos Correios (exige contrato: CORREIOS_USER,
 * CORREIOS_ACCESS_CODE e CORREIOS_POST_CARD no .env).
 */
async function correiosQuote(cep, pkg) {
  const token = await correiosAuth();
  const headers = { Authorization: `Bearer ${token}` };
  const results = [];
  for (const code of config.correios.services) {
    const query = new URLSearchParams({
      cepOrigem: config.correios.originCep,
      cepDestino: cep,
      psObjeto: String(Math.max(pkg.weightGrams, 300)),
      tpObjeto: '2',
      comprimento: String(pkg.lengthCm),
      largura: String(pkg.widthCm),
      altura: String(pkg.heightCm),
    });
    const [price, deadline] = await Promise.all([
      fetch(`https://api.correios.com.br/preco/v1/nacional/${code}?${query}`, {
        headers,
        signal: AbortSignal.timeout(8000),
      }),
      fetch(
        `https://api.correios.com.br/prazo/v1/nacional/${code}?cepOrigem=${config.correios.originCep}&cepDestino=${cep}`,
        { headers, signal: AbortSignal.timeout(8000) },
      ),
    ]);
    if (!price.ok || !deadline.ok) continue;
    const priceData = await price.json();
    const deadlineData = await deadline.json();
    results.push({
      service: SERVICE_NAMES[code] || code,
      price: Number(String(priceData.pcFinal).replace(',', '.')),
      days: Number(deadlineData.prazoEntrega),
    });
  }
  if (results.length === 0) throw new Error('Correios sem resultados');
  return results;
}

/**
 * Cotação de frete. Usa a API oficial quando há contrato configurado;
 * caso contrário (ou se ela falhar), devolve a estimativa por região,
 * sinalizada com source = "estimativa".
 */
async function quoteShipping(cep, items = []) {
  const weight = items.reduce(
    (sum, item) =>
      sum + (item.weightGrams || config.defaultPackage.weightGrams) * (item.quantity || 1),
    0,
  );
  const pkg = {
    ...config.defaultPackage,
    weightGrams: weight || config.defaultPackage.weightGrams,
  };
  const { user, accessCode, postCard } = config.correios;
  if (user && accessCode && postCard) {
    try {
      return { source: 'correios', options: await correiosQuote(cep, pkg) };
    } catch (error) {
      if (!config.isTest) console.warn('Falha na API dos Correios:', error.message);
    }
  }
  return { source: 'estimativa', options: estimateShipping(cep) };
}

module.exports = { sendMail, quoteShipping, estimateShipping };
