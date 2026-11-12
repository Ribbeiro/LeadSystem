process.env.NODE_ENV = 'test';
process.env.UPLOAD_DIR = require('node:path').join(
  require('node:os').tmpdir(),
  `leadsystem-uploads-${process.pid}`,
);

const assert = require('node:assert/strict');
const { after, before, beforeEach, describe, test } = require('node:test');

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const request = require('supertest');

const { createApp } = require('../src/app');
const { Product, User, Order, Quote, PasswordReset } = require('../src/models');
const { seed, loadCatalog } = require('../src/seed');
const { sendMail } = require('../src/services');

let mongo;
let app;

before(async () => {
  mongo = await MongoMemoryServer.create();
  await mongoose.connect(mongo.getUri());
  app = createApp();
});

after(async () => {
  await mongoose.disconnect();
  await mongo.stop();
});

beforeEach(async () => {
  await mongoose.connection.db.dropDatabase();
  await Promise.all(mongoose.modelNames().map((name) => mongoose.model(name).syncIndexes()));
  await seed();
  sendMail.outbox.length = 0;
});

async function login(email, password) {
  const res = await request(app).post('/api/auth/login').send({ email, password });
  assert.equal(res.status, 200, res.body.message);
  return res.body.token;
}
const asAdmin = () => login('leandro@email.com', 'Santi@2026');
const asClient = () => login('carlos@email.com', 'Cliente@2026');

const address = {
  street: 'Rua Amazonas',
  number: '50',
  neighborhood: 'Centro',
  city: 'São Caetano do Sul',
  state: 'SP',
  postalCode: '09520-070',
};

describe('catálogo', () => {
  test('seed carrega os 24 produtos reais do site', async () => {
    const res = await request(app).get('/api/products');
    assert.equal(res.status, 200);
    assert.equal(res.body.data.length, loadCatalog().length);
    assert.equal(res.body.data.length, 24);
    for (const product of res.body.data) {
      assert.ok(product.price > 0);
      assert.ok(product.images.length > 0);
    }
  });

  test('seed não duplica dados ao rodar de novo', async () => {
    await seed();
    assert.equal(await Product.countDocuments(), 24);
    assert.equal(await User.countDocuments(), 2);
  });

  test('somente admin altera produtos', async () => {
    const client = await asClient();
    const denied = await request(app)
      .put('/api/products/novo-produto')
      .set('Authorization', `Bearer ${client}`)
      .send({ name: 'Novo', category: 'Grelhas', price: 10, stock: 1 });
    assert.equal(denied.status, 403);

    const admin = await asAdmin();
    const ok = await request(app)
      .put('/api/products/novo-produto')
      .set('Authorization', `Bearer ${admin}`)
      .send({ name: 'Novo', category: 'Grelhas', price: 10, stock: 1 });
    assert.equal(ok.status, 200);
    assert.equal(ok.body.data.id, 'novo-produto');
  });
});

describe('autenticação', () => {
  test('cadastro, login e /me', async () => {
    const reg = await request(app).post('/api/auth/register').send({
      name: 'Maria da Silva',
      email: 'Maria@Email.com',
      phone: '(11) 97777-6666',
      password: 'Maria@2026',
    });
    assert.equal(reg.status, 201);
    assert.equal(reg.body.user.email, 'maria@email.com');
    assert.equal(reg.body.user.role, 'client');
    assert.equal(reg.body.user.passwordHash, undefined);

    const token = await login('maria@email.com', 'Maria@2026');
    const me = await request(app).get('/api/auth/me').set('Authorization', `Bearer ${token}`);
    assert.equal(me.body.user.name, 'Maria da Silva');
  });

  test('rejeita senha fraca, e-mail repetido e credencial errada', async () => {
    const weak = await request(app)
      .post('/api/auth/register')
      .send({ name: 'Ana Souza', email: 'ana@email.com', phone: '11977776666', password: 'fraca' });
    assert.equal(weak.status, 400);
    const dup = await request(app).post('/api/auth/register').send({
      name: 'Outro Carlos',
      email: 'carlos@email.com',
      phone: '11977776666',
      password: 'Senha@2026',
    });
    assert.equal(dup.status, 409);
    const wrong = await request(app)
      .post('/api/auth/login')
      .send({ email: 'carlos@email.com', password: 'errada' });
    assert.equal(wrong.status, 401);
  });

  test('token inválido e conta bloqueada', async () => {
    const bad = await request(app).get('/api/auth/me').set('Authorization', 'Bearer xyz');
    assert.equal(bad.status, 401);
    await User.updateOne({ email: 'carlos@email.com' }, { blocked: true });
    const blocked = await request(app)
      .post('/api/auth/login')
      .send({ email: 'carlos@email.com', password: 'Cliente@2026' });
    assert.equal(blocked.status, 403);
  });

  test('recuperação de senha por código enviado por e-mail', async () => {
    const forgot = await request(app)
      .post('/api/auth/password/forgot')
      .send({ email: 'carlos@email.com' });
    assert.equal(forgot.status, 200);
    assert.equal(sendMail.outbox.length, 1);
    const code = /(\d{6})/.exec(sendMail.outbox[0].text)[1];

    const wrong = await request(app)
      .post('/api/auth/password/reset')
      .send({ email: 'carlos@email.com', code: '000000', newPassword: 'Nova@2026' });
    assert.equal(wrong.status, 400);

    const ok = await request(app)
      .post('/api/auth/password/reset')
      .send({ email: 'carlos@email.com', code, newPassword: 'Nova@2026' });
    assert.equal(ok.status, 200);
    assert.ok(ok.body.token);
    await login('carlos@email.com', 'Nova@2026');

    const reuse = await request(app)
      .post('/api/auth/password/reset')
      .send({ email: 'carlos@email.com', code, newPassword: 'Outra@2026' });
    assert.equal(reuse.status, 400);
  });

  test('código bloqueia após 5 tentativas e não revela e-mails', async () => {
    const unknown = await request(app)
      .post('/api/auth/password/forgot')
      .send({ email: 'ninguem@email.com' });
    assert.equal(unknown.status, 200);
    assert.equal(sendMail.outbox.length, 0);

    await request(app).post('/api/auth/password/forgot').send({ email: 'carlos@email.com' });
    const code = /(\d{6})/.exec(sendMail.outbox[0].text)[1];
    const wrongCode = code === '111111' ? '222222' : '111111';
    for (let i = 0; i < 5; i += 1) {
      await request(app)
        .post('/api/auth/password/reset')
        .send({ email: 'carlos@email.com', code: wrongCode, newPassword: 'Nova@2026' });
    }
    const locked = await request(app)
      .post('/api/auth/password/reset')
      .send({ email: 'carlos@email.com', code, newPassword: 'Nova@2026' });
    assert.equal(locked.status, 400);
    assert.equal((await PasswordReset.findOne()).attempts, 5);
  });
});

describe('pedidos', () => {
  test('preço vem do banco, aplica Pix e cupom, baixa estoque', async () => {
    const token = await asClient();
    const product = await Product.findOne({ pixPrice: { $exists: true } });
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({
        clientId: 'local-1',
        items: [{ productId: product._id, quantity: 2, unitPrice: 0.01 }],
        paymentMethod: 'Pix',
        couponCode: 'primeiracompra',
        shipping: 24.9,
        deliveryAddress: address,
      });
    assert.equal(res.status, 201, res.body.message);
    const order = res.body.data;
    assert.match(order.id, /^#SG-\d{4}-0001$/);
    assert.equal(order.items[0].unitPrice, product.price);
    const subtotal = product.price * 2;
    const pix = (product.price - product.pixPrice) * 2 * 0.9;
    assert.equal(order.subtotal, Math.round(subtotal * 100) / 100);
    assert.equal(order.discount, Math.round((subtotal * 0.1 + pix) * 100) / 100);
    assert.equal(order.couponCode, 'PRIMEIRACOMPRA');
    assert.equal((await Product.findById(product._id)).stock, product.stock - 2);
  });

  test('reenvio com o mesmo clientId não duplica o pedido', async () => {
    const token = await asClient();
    const product = await Product.findOne();
    const body = {
      clientId: 'local-2',
      items: [{ productId: product._id, quantity: 1 }],
      paymentMethod: 'Cartão',
      deliveryAddress: address,
    };
    const first = await request(app).post('/api/orders').set('Authorization', `Bearer ${token}`).send(body);
    const second = await request(app).post('/api/orders').set('Authorization', `Bearer ${token}`).send(body);
    assert.equal(first.status, 201);
    assert.equal(second.status, 200);
    assert.equal(second.body.data.id, first.body.data.id);
    assert.equal(await Order.countDocuments(), 1);
    assert.equal((await Product.findById(product._id)).stock, product.stock - 1);
  });

  test('rejeita estoque insuficiente sem alterar nada', async () => {
    const token = await asClient();
    const [a, b] = await Product.find().limit(2);
    await Product.updateOne({ _id: b._id }, { stock: 1 });
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({
        clientId: 'local-3',
        items: [
          { productId: a._id, quantity: 1 },
          { productId: b._id, quantity: 5 },
        ],
        paymentMethod: 'Pix',
        deliveryAddress: address,
      });
    assert.equal(res.status, 409);
    assert.equal((await Product.findById(a._id)).stock, a.stock);
    assert.equal(await Order.countDocuments(), 0);
  });

  test('cliente vê só os seus; admin vê todos e muda status', async () => {
    const client = await asClient();
    const product = await Product.findOne();
    const created = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${client}`)
      .send({
        clientId: 'local-4',
        items: [{ productId: product._id, quantity: 1 }],
        paymentMethod: 'Boleto',
        deliveryAddress: address,
      });
    const number = created.body.data.id;

    await request(app).post('/api/auth/register').send({
      name: 'Outra Pessoa',
      email: 'outra@email.com',
      phone: '11977776666',
      password: 'Outra@2026',
    });
    const other = await login('outra@email.com', 'Outra@2026');
    const otherList = await request(app).get('/api/orders').set('Authorization', `Bearer ${other}`);
    assert.equal(otherList.body.data.length, 0);
    const forbidden = await request(app)
      .get('/api/orders?scope=all')
      .set('Authorization', `Bearer ${other}`);
    assert.equal(forbidden.status, 403);

    const admin = await asAdmin();
    const all = await request(app).get('/api/orders?scope=all').set('Authorization', `Bearer ${admin}`);
    assert.equal(all.body.data.length, 1);

    const updated = await request(app)
      .patch(`/api/orders/${encodeURIComponent(number)}/status`)
      .set('Authorization', `Bearer ${admin}`)
      .send({ status: 'shipped', note: 'Postado nos Correios.' });
    assert.equal(updated.status, 200);
    assert.equal(updated.body.data.status, 'shipped');
    assert.equal(updated.body.data.timeline.at(-1).note, 'Postado nos Correios.');

    const mine = await request(app).get('/api/orders').set('Authorization', `Bearer ${client}`);
    assert.equal(mine.body.data[0].status, 'shipped');
    assert.ok(sendMail.outbox.some((mail) => mail.subject.includes('Em transporte')));
  });

  test('cancelamento devolve o estoque', async () => {
    const client = await asClient();
    const product = await Product.findOne();
    const created = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${client}`)
      .send({
        clientId: 'local-5',
        items: [{ productId: product._id, quantity: 3 }],
        paymentMethod: 'Pix',
        deliveryAddress: address,
      });
    const admin = await asAdmin();
    await request(app)
      .patch(`/api/orders/${encodeURIComponent(created.body.data.id)}/status`)
      .set('Authorization', `Bearer ${admin}`)
      .send({ status: 'cancelled' });
    assert.equal((await Product.findById(product._id)).stock, product.stock);
  });
});

describe('orçamentos, usuários, frete e upload', () => {
  test('orçamento criado pelo cliente é respondido pelo admin', async () => {
    const client = await asClient();
    const product = await Product.findOne();
    const created = await request(app)
      .post('/api/quotes')
      .set('Authorization', `Bearer ${client}`)
      .send({ clientId: 'q1', productId: product._id, details: 'Preciso de 10 unidades.' });
    assert.equal(created.status, 201);
    assert.match(created.body.data.id, /^#ORC-/);

    const admin = await asAdmin();
    const answered = await request(app)
      .patch(`/api/quotes/${encodeURIComponent(created.body.data.id)}`)
      .set('Authorization', `Bearer ${admin}`)
      .send({ status: 'answered', response: 'Valor especial enviado por e-mail.' });
    assert.equal(answered.body.data.status, 'answered');
    assert.equal(await Quote.countDocuments(), 1);
  });

  test('admin bloqueia e exclui usuário, mas não a si mesmo', async () => {
    const admin = await asAdmin();
    const users = await request(app).get('/api/users').set('Authorization', `Bearer ${admin}`);
    const carlos = users.body.data.find((user) => user.email === 'carlos@email.com');
    const leandro = users.body.data.find((user) => user.email === 'leandro@email.com');

    const self = await request(app)
      .patch(`/api/users/${leandro.id}`)
      .set('Authorization', `Bearer ${admin}`)
      .send({ blocked: true });
    assert.equal(self.status, 400);

    const blocked = await request(app)
      .patch(`/api/users/${carlos.id}`)
      .set('Authorization', `Bearer ${admin}`)
      .send({ blocked: true });
    assert.equal(blocked.body.data.blocked, true);

    const removed = await request(app)
      .delete(`/api/users/${carlos.id}`)
      .set('Authorization', `Bearer ${admin}`);
    assert.equal(removed.status, 204);
  });

  test('frete sem contrato devolve estimativa sinalizada', async () => {
    const res = await request(app).post('/api/shipping/quote').send({ cep: '01001-000' });
    assert.equal(res.status, 200);
    assert.equal(res.body.source, 'estimativa');
    assert.deepEqual(
      res.body.options.map((option) => option.service),
      ['PAC', 'SEDEX'],
    );
    const bad = await request(app).post('/api/shipping/quote').send({ cep: '123' });
    assert.equal(bad.status, 400);
  });

  test('upload de foto de produto (admin)', async () => {
    const admin = await asAdmin();
    const png = Buffer.from(
      '89504e470d0a1a0a0000000d4948445200000001000000010806000000' +
        '1f15c4890000000d49444154789c6360000002000154a24f5f0000000049454e44ae426082',
      'hex',
    );
    const res = await request(app)
      .post('/api/uploads')
      .set('Authorization', `Bearer ${admin}`)
      .attach('image', png, { filename: 'foto.png', contentType: 'image/png' });
    assert.equal(res.status, 201, res.body.message);
    assert.match(res.body.url, /\/uploads\/.+\.png$/);
    const file = await request(app).get(new URL(res.body.url).pathname);
    assert.equal(file.status, 200);

    const text = await request(app)
      .post('/api/uploads')
      .set('Authorization', `Bearer ${admin}`)
      .attach('image', Buffer.from('oi'), { filename: 'a.txt', contentType: 'text/plain' });
    assert.equal(text.status, 400);
  });
});
