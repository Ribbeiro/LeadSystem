const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const bcrypt = require('bcryptjs');
const cors = require('cors');
const express = require('express');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const multer = require('multer');

const config = require('./config');
const {
  User,
  Product,
  Order,
  Quote,
  Coupon,
  PasswordReset,
  nextNumber,
} = require('./models');
const { sendMail, quoteShipping } = require('./services');

const ORDER_STATUS_LABEL = {
  received: 'Pedido recebido',
  paymentApproved: 'Pagamento aprovado',
  preparing: 'Em preparação',
  shipped: 'Em transporte',
  delivered: 'Entregue',
  cancelled: 'Cancelado',
};

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

const asyncRoute = (handler) => (req, res, next) =>
  Promise.resolve(handler(req, res, next)).catch(next);

const normalizeEmail = (value) => String(value || '').trim().toLowerCase();
const validEmail = (value) => /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value);
const validPassword = (value) =>
  typeof value === 'string' && value.length >= 8 && /[A-Z]/.test(value) && /\d/.test(value);
const round2 = (value) => Math.round(value * 100) / 100;

function signToken(user) {
  return jwt.sign({ sub: user._id.toString(), role: user.role }, config.jwtSecret, {
    expiresIn: config.jwtExpiresIn,
  });
}

// ------------------------------------------------------------ middleware

const authenticate = asyncRoute(async (req, _res, next) => {
  const header = req.get('authorization') || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) throw new HttpError(401, 'Faça login para continuar.');
  let payload;
  try {
    payload = jwt.verify(token, config.jwtSecret);
  } catch {
    throw new HttpError(401, 'Sessão expirada. Entre novamente.');
  }
  const user = await User.findById(payload.sub);
  if (!user) throw new HttpError(401, 'Conta não encontrada.');
  if (user.blocked) throw new HttpError(403, 'Conta bloqueada. Fale com a SantiGrill.');
  req.user = user;
  next();
});

const requireAdmin = (req, _res, next) => {
  if (req.user?.role !== 'admin') {
    return next(new HttpError(403, 'Acesso restrito à equipe SantiGrill.'));
  }
  return next();
};

// ------------------------------------------------------------ app

function createApp() {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', 1);
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors());
  app.use(express.json({ limit: '200kb' }));

  fs.mkdirSync(config.uploadDir, { recursive: true });
  app.use('/uploads', express.static(config.uploadDir, { maxAge: '30d', immutable: true }));

  const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: config.isTest ? 1000 : 30,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    message: { message: 'Muitas tentativas. Aguarde alguns minutos.' },
  });

  // -------------------------------------------------------- saúde
  app.get('/health', (_req, res) => {
    res.json({
      service: 'LeadSystem API',
      status: 'ok',
      database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    });
  });

  // -------------------------------------------------------- autenticação
  app.post(
    '/api/auth/register',
    authLimiter,
    asyncRoute(async (req, res) => {
      const name = String(req.body?.name || '').trim();
      const email = normalizeEmail(req.body?.email);
      const phone = String(req.body?.phone || '').trim();
      const password = req.body?.password;
      if (name.length < 3) throw new HttpError(400, 'Informe seu nome completo.');
      if (!validEmail(email)) throw new HttpError(400, 'Informe um e-mail válido.');
      if (phone.replace(/\D/g, '').length < 10) {
        throw new HttpError(400, 'Informe um telefone com DDD.');
      }
      if (!validPassword(password)) {
        throw new HttpError(
          400,
          'A senha deve ter 8 caracteres, uma letra maiúscula e um número.',
        );
      }
      if (await User.exists({ email })) {
        throw new HttpError(409, 'Este e-mail já está cadastrado.');
      }
      const user = await User.create({
        name,
        email,
        phone,
        passwordHash: await bcrypt.hash(password, 10),
      });
      res.status(201).json({ token: signToken(user), user: user.toPublic() });
    }),
  );

  app.post(
    '/api/auth/login',
    authLimiter,
    asyncRoute(async (req, res) => {
      const email = normalizeEmail(req.body?.email);
      const password = String(req.body?.password || '');
      const user = await User.findOne({ email });
      if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
        throw new HttpError(401, 'E-mail ou senha incorretos.');
      }
      if (user.blocked) throw new HttpError(403, 'Conta bloqueada. Fale com a SantiGrill.');
      res.json({ token: signToken(user), user: user.toPublic() });
    }),
  );

  app.get('/api/auth/me', authenticate, (req, res) => {
    res.json({ user: req.user.toPublic() });
  });

  app.patch(
    '/api/auth/me',
    authenticate,
    asyncRoute(async (req, res) => {
      const { name, phone, currentPassword, newPassword } = req.body || {};
      if (name !== undefined) {
        if (String(name).trim().length < 3) throw new HttpError(400, 'Nome inválido.');
        req.user.name = String(name).trim();
      }
      if (phone !== undefined) req.user.phone = String(phone).trim();
      if (newPassword !== undefined) {
        if (!(await bcrypt.compare(String(currentPassword || ''), req.user.passwordHash))) {
          throw new HttpError(400, 'A senha atual está incorreta.');
        }
        if (!validPassword(newPassword)) {
          throw new HttpError(400, 'A nova senha não atende aos requisitos.');
        }
        req.user.passwordHash = await bcrypt.hash(newPassword, 10);
      }
      await req.user.save();
      res.json({ user: req.user.toPublic() });
    }),
  );

  // Recuperação de senha: código de 6 dígitos por e-mail, válido por 15 min,
  // no máximo 5 tentativas. A resposta é igual para e-mails inexistentes,
  // para não revelar quem tem conta.
  app.post(
    '/api/auth/password/forgot',
    authLimiter,
    asyncRoute(async (req, res) => {
      const email = normalizeEmail(req.body?.email);
      const user = validEmail(email) ? await User.findOne({ email }) : null;
      let previewUrl;
      if (user && !user.blocked) {
        const code = String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
        await PasswordReset.deleteMany({ user: user._id });
        await PasswordReset.create({
          user: user._id,
          codeHash: await bcrypt.hash(code, 8),
          expiresAt: new Date(Date.now() + 15 * 60 * 1000),
        });
        const sent = await sendMail({
          to: user.email,
          subject: 'Código para redefinir sua senha - SantiGrill',
          text:
            `Olá, ${user.name.split(' ')[0]}!\n\n` +
            `Seu código para redefinir a senha no app SantiGrill é: ${code}\n\n` +
            'Ele vale por 15 minutos. Se você não pediu a troca, ignore este e-mail.',
        });
        previewUrl = sent.previewUrl;
      }
      res.json({
        message: 'Se o e-mail estiver cadastrado, enviaremos um código em instantes.',
        // Somente no modo demonstração (caixa de teste Ethereal, nunca em
        // produção): link para abrir o e-mail de teste e ver o código.
        ...(config.mailMode === 'ethereal' && previewUrl ? { previewUrl } : {}),
      });
    }),
  );

  app.post(
    '/api/auth/password/reset',
    authLimiter,
    asyncRoute(async (req, res) => {
      const email = normalizeEmail(req.body?.email);
      const code = String(req.body?.code || '').trim();
      const newPassword = req.body?.newPassword;
      const invalid = new HttpError(400, 'Código inválido ou expirado.');
      const user = await User.findOne({ email });
      if (!user) throw invalid;
      const reset = await PasswordReset.findOne({
        user: user._id,
        usedAt: null,
        expiresAt: { $gt: new Date() },
      });
      if (!reset || reset.attempts >= 5) throw invalid;
      if (!(await bcrypt.compare(code, reset.codeHash))) {
        reset.attempts += 1;
        await reset.save();
        throw invalid;
      }
      if (!validPassword(newPassword)) {
        throw new HttpError(
          400,
          'A nova senha deve ter 8 caracteres, uma letra maiúscula e um número.',
        );
      }
      user.passwordHash = await bcrypt.hash(newPassword, 10);
      await user.save();
      reset.usedAt = new Date();
      await reset.save();
      res.json({ token: signToken(user), user: user.toPublic() });
    }),
  );

  // -------------------------------------------------------- produtos
  app.get(
    '/api/products',
    asyncRoute(async (req, res) => {
      const filter = req.query.all === 'true' ? {} : { active: true };
      const products = await Product.find(filter).sort({ createdAt: 1, _id: 1 });
      res.json({ data: products.map((product) => product.toPublic()) });
    }),
  );

  app.get(
    '/api/products/:id',
    asyncRoute(async (req, res) => {
      const product = await Product.findById(req.params.id);
      if (!product) throw new HttpError(404, 'Produto não encontrado.');
      res.json({ data: product.toPublic() });
    }),
  );

  const productFields = [
    'name',
    'shortName',
    'category',
    'description',
    'price',
    'promotionalPrice',
    'pixPrice',
    'installments',
    'installmentValue',
    'stock',
    'images',
    'specifications',
    'measures',
    'voltageOptions',
    'weightGrams',
    'videoUrl',
    'url',
    'badge',
    'active',
  ];
  const pickProduct = (body) => {
    const data = {};
    for (const field of productFields) {
      if (body[field] !== undefined) data[field] = body[field];
    }
    return data;
  };

  app.put(
    '/api/products/:id',
    authenticate,
    requireAdmin,
    asyncRoute(async (req, res) => {
      const id = String(req.params.id).trim().toLowerCase();
      if (!/^[a-z0-9-]{3,}$/.test(id)) throw new HttpError(400, 'Código de produto inválido.');
      const data = pickProduct(req.body || {});
      const product = await Product.findByIdAndUpdate(
        id,
        { $set: data, $setOnInsert: { _id: id } },
        { upsert: true, new: true, runValidators: true },
      );
      res.json({ data: product.toPublic() });
    }),
  );

  app.delete(
    '/api/products/:id',
    authenticate,
    requireAdmin,
    asyncRoute(async (req, res) => {
      const removed = await Product.findByIdAndDelete(req.params.id);
      if (!removed) throw new HttpError(404, 'Produto não encontrado.');
      res.status(204).end();
    }),
  );

  const upload = multer({
    storage: multer.diskStorage({
      destination: config.uploadDir,
      filename: (_req, file, done) => {
        const ext = file.mimetype === 'image/png' ? '.png' : '.jpg';
        done(null, `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`);
      },
    }),
    limits: { fileSize: 5 * 1024 * 1024, files: 1 },
    fileFilter: (_req, file, done) => {
      if (['image/jpeg', 'image/png'].includes(file.mimetype)) return done(null, true);
      return done(new HttpError(400, 'Envie uma imagem JPG ou PNG.'));
    },
  });

  app.post(
    '/api/uploads',
    authenticate,
    requireAdmin,
    upload.single('image'),
    (req, res) => {
      if (!req.file) throw new HttpError(400, 'Nenhuma imagem enviada.');
      const base = config.publicUrl || `${req.protocol}://${req.get('host')}`;
      res.status(201).json({ url: `${base}/uploads/${req.file.filename}` });
    },
  );

  // -------------------------------------------------------- frete
  app.post(
    '/api/shipping/quote',
    asyncRoute(async (req, res) => {
      const cep = String(req.body?.cep || '').replace(/\D/g, '');
      if (cep.length !== 8) throw new HttpError(400, 'Informe um CEP com 8 números.');
      const items = Array.isArray(req.body?.items) ? req.body.items : [];
      const ids = items.map((item) => String(item.productId));
      const products = await Product.find({ _id: { $in: ids } });
      const weighted = items.map((item) => ({
        quantity: Number(item.quantity) || 1,
        weightGrams: products.find((p) => p._id === String(item.productId))?.weightGrams,
      }));
      res.json(await quoteShipping(cep, weighted));
    }),
  );

  // -------------------------------------------------------- cupons
  app.get(
    '/api/coupons/:code',
    asyncRoute(async (req, res) => {
      const coupon = await Coupon.findById(String(req.params.code).toUpperCase());
      if (!coupon || !coupon.active) throw new HttpError(404, 'Cupom inválido.');
      res.json({ data: coupon });
    }),
  );

  // -------------------------------------------------------- pedidos
  app.post(
    '/api/orders',
    authenticate,
    asyncRoute(async (req, res) => {
      const body = req.body || {};
      const clientId = String(body.clientId || '').trim();
      if (!clientId) throw new HttpError(400, 'Identificador do pedido ausente.');

      // Idempotência: reenvio do mesmo pedido (ex.: após queda de rede)
      // devolve o registro já criado.
      const existing = await Order.findOne({ customer: req.user._id, clientId });
      if (existing) return res.status(200).json({ data: existing.toPublic() });

      const requested = Array.isArray(body.items) ? body.items : [];
      if (requested.length === 0) throw new HttpError(400, 'Inclua ao menos um item.');
      if (!['Pix', 'Cartão', 'Boleto'].includes(body.paymentMethod)) {
        throw new HttpError(400, 'Forma de pagamento inválida.');
      }
      const address = body.deliveryAddress || {};
      if (!address.street || !address.city || !address.postalCode) {
        throw new HttpError(400, 'Endereço de entrega incompleto.');
      }

      // Preços e estoque vêm do banco; o valor enviado pelo app é ignorado.
      const items = [];
      let subtotal = 0;
      let pixDiscount = 0;
      for (const entry of requested) {
        const quantity = Number(entry.quantity);
        const product = await Product.findById(String(entry.productId));
        if (!product || !product.active) {
          throw new HttpError(409, `Produto indisponível: ${entry.productId}.`);
        }
        if (!Number.isInteger(quantity) || quantity < 1 || quantity > product.stock) {
          throw new HttpError(409, `Estoque insuficiente para ${product.name}.`);
        }
        const unitPrice =
          product.promotionalPrice && product.promotionalPrice < product.price
            ? product.promotionalPrice
            : product.price;
        if (product.pixPrice && product.pixPrice < unitPrice) {
          pixDiscount += (unitPrice - product.pixPrice) * quantity;
        }
        subtotal += unitPrice * quantity;
        items.push({
          productId: product._id,
          name: product.name,
          unitPrice,
          quantity,
          image: product.images[0],
          option: product.voltageOptions.includes(entry.option) ? entry.option : undefined,
        });
      }

      let couponDiscount = 0;
      let couponCode;
      if (body.couponCode) {
        const coupon = await Coupon.findById(String(body.couponCode).toUpperCase());
        const now = new Date();
        const available =
          coupon &&
          coupon.active &&
          (!coupon.expiresAt || coupon.expiresAt > now) &&
          (coupon.usageLimit == null || coupon.usedCount < coupon.usageLimit) &&
          subtotal >= (coupon.minimumSubtotal || 0);
        if (available) {
          couponDiscount = subtotal * (coupon.discountPercent / 100);
          couponCode = coupon._id;
          pixDiscount *= 1 - coupon.discountPercent / 100;
        }
      }
      const discount =
        couponDiscount + (body.paymentMethod === 'Pix' ? pixDiscount : 0);
      const shipping = Math.max(0, Number(body.shipping) || 0);

      // Baixa de estoque condicional (evita vender além do disponível
      // quando dois clientes compram ao mesmo tempo).
      const decremented = [];
      for (const item of items) {
        const result = await Product.updateOne(
          { _id: item.productId, stock: { $gte: item.quantity } },
          { $inc: { stock: -item.quantity } },
        );
        if (result.modifiedCount !== 1) {
          await Promise.all(
            decremented.map((done) =>
              Product.updateOne({ _id: done.productId }, { $inc: { stock: done.quantity } }),
            ),
          );
          throw new HttpError(409, `Estoque insuficiente para ${item.name}.`);
        }
        decremented.push(item);
      }
      if (couponCode) {
        await Coupon.updateOne({ _id: couponCode }, { $inc: { usedCount: 1 } });
      }

      const now = new Date();
      const order = await Order.create({
        number: await nextNumber('SG'),
        clientId,
        customer: req.user._id,
        customerEmail: req.user.email,
        customerName: req.user.name,
        items,
        subtotal: round2(subtotal),
        discount: round2(discount),
        shipping: round2(shipping),
        total: round2(subtotal - discount + shipping),
        couponCode,
        paymentMethod: body.paymentMethod,
        deliveryAddress: address,
        timeline: [
          {
            status: 'received',
            title: ORDER_STATUS_LABEL.received,
            note: 'Pedido registrado no aplicativo.',
            createdAt: now,
          },
        ],
      });

      sendMail({
        to: req.user.email,
        subject: `Pedido ${order.number} recebido - SantiGrill`,
        text:
          `Recebemos seu pedido ${order.number} no valor de R$ ${order.total
            .toFixed(2)
            .replace('.', ',')}.\nAcompanhe o andamento pelo app.`,
      }).catch(() => {});

      return res.status(201).json({ data: order.toPublic() });
    }),
  );

  app.get(
    '/api/orders',
    authenticate,
    asyncRoute(async (req, res) => {
      const all = req.query.scope === 'all';
      if (all && req.user.role !== 'admin') throw new HttpError(403, 'Acesso restrito.');
      const filter = all ? {} : { customer: req.user._id };
      if (req.query.since) filter.updatedAt = { $gt: new Date(req.query.since) };
      const orders = await Order.find(filter).sort({ createdAt: -1 }).limit(500);
      res.json({ data: orders.map((order) => order.toPublic()) });
    }),
  );

  app.patch(
    '/api/orders/:number/status',
    authenticate,
    requireAdmin,
    asyncRoute(async (req, res) => {
      const status = String(req.body?.status || '');
      if (!ORDER_STATUS_LABEL[status]) throw new HttpError(400, 'Status inválido.');
      const order = await Order.findOne({ number: req.params.number });
      if (!order) throw new HttpError(404, 'Pedido não encontrado.');
      if (order.status !== status) {
        order.status = status;
        order.timeline.push({
          status,
          title: ORDER_STATUS_LABEL[status],
          note: String(req.body?.note || '').trim() || 'Status atualizado pela equipe SantiGrill.',
          createdAt: new Date(),
        });
        if (status === 'cancelled') {
          await Promise.all(
            order.items.map((item) =>
              Product.updateOne({ _id: item.productId }, { $inc: { stock: item.quantity } }),
            ),
          );
        }
        await order.save();
        sendMail({
          to: order.customerEmail,
          subject: `Pedido ${order.number}: ${ORDER_STATUS_LABEL[status]}`,
          text: `Seu pedido ${order.number} mudou para "${ORDER_STATUS_LABEL[status]}".`,
        }).catch(() => {});
      }
      res.json({ data: order.toPublic() });
    }),
  );

  // -------------------------------------------------------- orçamentos
  app.post(
    '/api/quotes',
    authenticate,
    asyncRoute(async (req, res) => {
      const body = req.body || {};
      const clientId = body.clientId ? String(body.clientId) : undefined;
      if (clientId) {
        const existing = await Quote.findOne({ customer: req.user._id, clientId });
        if (existing) return res.json({ data: existing.toPublic() });
      }
      const details = String(body.details || '').trim();
      if (details.length < 10) throw new HttpError(400, 'Descreva a sua necessidade.');
      const product = body.productId ? await Product.findById(String(body.productId)) : null;
      const quote = await Quote.create({
        number: await nextNumber('ORC'),
        clientId,
        customer: req.user._id,
        productId: product?._id,
        productName: product?.name || body.productName,
        customerName: String(body.customerName || req.user.name).trim(),
        email: normalizeEmail(body.email || req.user.email),
        phone: String(body.phone || req.user.phone).trim(),
        details,
      });
      return res.status(201).json({ data: quote.toPublic() });
    }),
  );

  app.get(
    '/api/quotes',
    authenticate,
    asyncRoute(async (req, res) => {
      const all = req.query.scope === 'all';
      if (all && req.user.role !== 'admin') throw new HttpError(403, 'Acesso restrito.');
      const quotes = await Quote.find(all ? {} : { customer: req.user._id })
        .sort({ createdAt: -1 })
        .limit(500);
      res.json({ data: quotes.map((quote) => quote.toPublic()) });
    }),
  );

  app.patch(
    '/api/quotes/:number',
    authenticate,
    requireAdmin,
    asyncRoute(async (req, res) => {
      const quote = await Quote.findOne({ number: req.params.number });
      if (!quote) throw new HttpError(404, 'Orçamento não encontrado.');
      const status = req.body?.status;
      if (status) {
        if (!['pending', 'reviewing', 'answered', 'approved', 'rejected'].includes(status)) {
          throw new HttpError(400, 'Status inválido.');
        }
        quote.status = status;
      }
      if (req.body?.response !== undefined) quote.response = String(req.body.response).trim();
      await quote.save();
      if (quote.response) {
        sendMail({
          to: quote.email,
          subject: `Orçamento ${quote.number} - SantiGrill`,
          text: `Resposta da equipe SantiGrill:\n\n${quote.response}`,
        }).catch(() => {});
      }
      res.json({ data: quote.toPublic() });
    }),
  );

  // -------------------------------------------------------- usuários (admin)
  app.get(
    '/api/users',
    authenticate,
    requireAdmin,
    asyncRoute(async (_req, res) => {
      const users = await User.find().sort({ createdAt: 1 });
      res.json({ data: users.map((user) => user.toPublic()) });
    }),
  );

  app.patch(
    '/api/users/:id',
    authenticate,
    requireAdmin,
    asyncRoute(async (req, res) => {
      if (!mongoose.isValidObjectId(req.params.id)) throw new HttpError(404, 'Usuário não encontrado.');
      const user = await User.findById(req.params.id);
      if (!user) throw new HttpError(404, 'Usuário não encontrado.');
      if (user._id.equals(req.user._id) && (req.body?.blocked || req.body?.role === 'client')) {
        throw new HttpError(400, 'Você não pode bloquear ou rebaixar a própria conta.');
      }
      if (req.body?.role !== undefined) {
        if (!['client', 'admin'].includes(req.body.role)) throw new HttpError(400, 'Perfil inválido.');
        user.role = req.body.role;
      }
      if (req.body?.blocked !== undefined) user.blocked = Boolean(req.body.blocked);
      await user.save();
      res.json({ data: user.toPublic() });
    }),
  );

  app.delete(
    '/api/users/:id',
    authenticate,
    requireAdmin,
    asyncRoute(async (req, res) => {
      if (!mongoose.isValidObjectId(req.params.id)) throw new HttpError(404, 'Usuário não encontrado.');
      if (req.user._id.equals(req.params.id)) {
        throw new HttpError(400, 'Você não pode excluir a própria conta.');
      }
      const removed = await User.findByIdAndDelete(req.params.id);
      if (!removed) throw new HttpError(404, 'Usuário não encontrado.');
      res.status(204).end();
    }),
  );

  // -------------------------------------------------------- erros
  app.use((_req, res) => {
    res.status(404).json({ message: 'Rota não encontrada.' });
  });

  // eslint-disable-next-line no-unused-vars
  app.use((error, _req, res, _next) => {
    if (error instanceof HttpError) {
      return res.status(error.status).json({ message: error.message });
    }
    if (error instanceof multer.MulterError) {
      return res.status(400).json({ message: 'Imagem muito grande (máximo 5 MB).' });
    }
    if (error?.type === 'entity.parse.failed') {
      return res.status(400).json({ message: 'JSON inválido.' });
    }
    if (error?.name === 'ValidationError' || error?.name === 'CastError') {
      return res.status(400).json({ message: 'Dados inválidos.' });
    }
    if (!config.isTest) console.error(error);
    return res.status(500).json({ message: 'Não foi possível concluir a operação.' });
  });

  return app;
}

module.exports = { createApp, HttpError, uploadsPath: path.resolve(config.uploadDir) };
