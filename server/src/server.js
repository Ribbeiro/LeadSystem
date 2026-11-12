const mongoose = require('mongoose');

const config = require('./config');
const { createApp } = require('./app');
const { seed } = require('./seed');

async function start() {
  try {
    await mongoose.connect(config.mongoUri, { serverSelectionTimeoutMS: 5000 });
  } catch (error) {
    console.error(
      `Não foi possível conectar ao MongoDB em ${config.mongoUri}.\n` +
        'Inicie o MongoDB (ex.: docker compose up -d) ou ajuste MONGODB_URI no .env.',
    );
    console.error(error.message);
    process.exit(1);
  }
  await seed();
  const app = createApp();
  app.listen(config.port, '0.0.0.0', () => {
    console.log(`LeadSystem API em http://localhost:${config.port} (MongoDB conectado)`);
    console.log(
      'No emulador Android use http://10.0.2.2:' +
        `${config.port}; no celular, o IP deste computador na mesma rede Wi-Fi.`,
    );
  });
}

start();
