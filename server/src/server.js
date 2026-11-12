const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');
const mongoose = require('mongoose');

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 3000);
const mongoUri = process.env.MONGODB_URI;

app.disable('x-powered-by');
app.use(cors());
app.use(express.json({ limit: '100kb' }));

const products = [
  {
    id: 'CHU-001',
    name: 'Churrasqueira Premium Aço',
    category: 'Churrasqueiras',
    price: 899.9,
    rating: 4.8,
    stock: 10,
  },
  {
    id: 'ESP-004',
    name: 'Espeto Giratório 4 Hastes',
    category: 'Espetos',
    price: 249.9,
    rating: 4.7,
    stock: 16,
  },
  {
    id: 'GRE-002',
    name: 'Grelha Dupla Ferro Fundido',
    category: 'Grelhas',
    price: 129.9,
    rating: 4.9,
    stock: 22,
  },
  {
    id: 'KIT-008',
    name: 'Kit Churrasco Profissional',
    category: 'Kits',
    price: 189.9,
    rating: 4.6,
    stock: 8,
  },
];

app.get('/health', (_request, response) => {
  response.json({
    service: 'LeadSystem API',
    status: 'ok',
    database: mongoose.connection.readyState === 1 ? 'connected' : 'demo-mode',
  });
});

app.get('/api/products', (request, response) => {
  const query = String(request.query.q || '').toLowerCase();
  const category = String(request.query.category || '');
  const result = products.filter((product) => {
    const matchesQuery = !query || product.name.toLowerCase().includes(query);
    const matchesCategory = !category || category === 'Todos' || product.category === category;
    return matchesQuery && matchesCategory;
  });
  response.json({ data: result });
});

app.post('/api/auth/login', (request, response) => {
  const { email, password } = request.body ?? {};
  if (!email || !password) {
    return response.status(400).json({ message: 'E-mail e senha são obrigatórios.' });
  }
  // A autenticação real ainda não está implementada no servidor: o app valida localmente.
  return response.status(501).json({ message: 'Autenticação no servidor ainda não disponível.' });
});

app.post('/api/orders', (request, response) => {
  const { items, payment } = request.body ?? {};
  if (!Array.isArray(items) || items.length === 0) {
    return response.status(400).json({ message: 'Inclua ao menos um item.' });
  }
  let total = 0;
  for (const item of items) {
    const product = products.find((candidate) => candidate.id === item?.productId);
    const quantity = Number(item?.quantity);
    if (!product || !Number.isInteger(quantity) || quantity < 1 || quantity > product.stock) {
      return response.status(400).json({ message: 'Item inválido ou sem estoque suficiente.' });
    }
    total += product.price * quantity;
  }
  return response.status(201).json({
    id: `SG-${Date.now()}`,
    status: 'received',
    total: Math.round(total * 100) / 100,
    payment: String(payment ?? ''),
  });
});

app.post('/api/quotes', (request, response) => {
  const { productId, contact } = request.body ?? {};
  if (!productId || !contact) {
    return response.status(400).json({ message: 'Produto e contato são obrigatórios.' });
  }
  return response.status(201).json({ id: `ORC-${Date.now()}`, status: 'pending' });
});

app.use((_request, response) => {
  response.status(404).json({ message: 'Rota não encontrada.' });
});

app.use((error, _request, response, _next) => {
  console.error(error);
  response.status(500).json({ message: 'Não foi possível concluir a operação.' });
});

async function start() {
  if (mongoUri) {
    try {
      await mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 3000 });
      console.log('MongoDB conectado.');
    } catch (error) {
      console.warn('MongoDB indisponível; API iniciada em modo de demonstração.');
    }
  }

  app.listen(port, () => {
    console.log(`LeadSystem API disponível em http://localhost:${port}`);
  });
}

start();
