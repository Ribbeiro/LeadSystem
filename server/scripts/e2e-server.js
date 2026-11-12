// Sobe a API com um MongoDB temporário em memória, para testes de ponta a
// ponta do app (test/e2e_api_test.dart). Uso: node scripts/e2e-server.js [porta]
process.env.NODE_ENV = 'test';
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

(async () => {
  const mongo = await MongoMemoryServer.create();
  await mongoose.connect(mongo.getUri());
  const { createApp } = require('../src/app');
  const { seed } = require('../src/seed');
  await seed();
  const port = Number(process.argv[2] || 3999);
  createApp().listen(port, '127.0.0.1', () => {
    console.log(`E2E API pronta em http://127.0.0.1:${port}`);
  });
})();
