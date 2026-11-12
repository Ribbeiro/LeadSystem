const path = require('node:path');
const dotenv = require('dotenv');

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const env = process.env;
const isProduction = env.NODE_ENV === 'production';
const isTest = env.NODE_ENV === 'test';

if (isProduction && (!env.JWT_SECRET || env.JWT_SECRET.length < 32)) {
  throw new Error('Defina JWT_SECRET com pelo menos 32 caracteres em produção.');
}

module.exports = {
  isProduction,
  isTest,
  port: Number(env.PORT || 3000),
  mongoUri: env.MONGODB_URI || 'mongodb://127.0.0.1:27017/leadsystem',
  jwtSecret: env.JWT_SECRET || 'dev-only-secret-troque-em-producao-0000000',
  jwtExpiresIn: env.JWT_EXPIRES_IN || '7d',
  publicUrl: (env.PUBLIC_URL || '').replace(/\/$/, ''),
  uploadDir: env.UPLOAD_DIR || path.join(__dirname, '..', 'uploads'),
  catalogPath:
    env.CATALOG_PATH ||
    path.join(__dirname, '..', '..', 'assets', 'data', 'santigrill.json'),
  smtp: {
    host: env.SMTP_HOST,
    port: Number(env.SMTP_PORT || 587),
    secure: env.SMTP_SECURE === 'true',
    user: env.SMTP_USER,
    pass: env.SMTP_PASS,
    from: env.MAIL_FROM || 'SantiGrill <nao-responda@santigrill.com.br>',
  },
  correios: {
    user: env.CORREIOS_USER,
    accessCode: env.CORREIOS_ACCESS_CODE,
    postCard: env.CORREIOS_POST_CARD,
    originCep: (env.CORREIOS_ORIGIN_CEP || '09195510').replace(/\D/g, ''),
    services: (env.CORREIOS_SERVICES || '03220,03298').split(','),
  },
  defaultPackage: {
    weightGrams: Number(env.DEFAULT_PACKAGE_WEIGHT_G || 3000),
    lengthCm: Number(env.DEFAULT_PACKAGE_LENGTH_CM || 50),
    widthCm: Number(env.DEFAULT_PACKAGE_WIDTH_CM || 40),
    heightCm: Number(env.DEFAULT_PACKAGE_HEIGHT_CM || 30),
  },
  seedDemoUsers: env.SEED_DEMO_USERS !== 'false',
};
