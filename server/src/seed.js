const fs = require('node:fs');

const bcrypt = require('bcryptjs');

const config = require('./config');
const { User, Product, Coupon } = require('./models');

const DEFAULT_STOCK = 10;

const clean = (value) =>
  String(value || '')
    .replace(/ /g, ' ')
    .replace(/[ \t]+/g, ' ')
    .replace(/ *\n */g, '\n')
    .replace(/\n{3,}/g, '\n\n')
    .trim();

// Mesmas regras de lib/data/santigrill_catalog.dart, para que app e API
// exibam os produtos igualmente.
function titleCase(value) {
  const letters = value.replace(/[^A-Za-zÀ-ÿ]/g, '');
  if (!letters || letters !== letters.toUpperCase()) return value;
  const lower = new Set(['de', 'da', 'do', 'das', 'dos', 'e', 'para', 'com']);
  return value
    .split(' ')
    .map((word, index) => {
      if (!word) return word;
      const w = word.toLowerCase();
      return index > 0 && lower.has(w) ? w : word[0] + w.slice(1);
    })
    .join(' ');
}

function shortName(name) {
  const cleaned = name
    .replace(/\s*Santi\s?grill\s*/gi, ' ')
    .replace(/(\s+e\s+|\/)rotat[óo]rio/gi, '')
    .replace(/\s+el[ée]trico/gi, '')
    .replace(/\s+/g, ' ')
    .trim();
  return cleaned || name;
}

function watchUrl(embed) {
  if (!embed) return undefined;
  const match = /embed\/([\w-]+)/.exec(embed);
  return match ? `https://www.youtube.com/watch?v=${match[1]}` : embed;
}

function loadCatalog() {
  const data = JSON.parse(fs.readFileSync(config.catalogPath, 'utf8'));
  const names = {};
  const parents = {};
  for (const category of data.categorias || []) {
    names[category.id] = category.nome;
    parents[category.id] = category.categoriaPai || null;
  }
  const categoryName = (id) => {
    let current = id;
    while (parents[current]) current = parents[current];
    return names[current] || current;
  };

  return (data.produtos || []).map((item) => {
    const specs = item.especificacoes || {};
    const specifications = {};
    const add = (label, value) => {
      const text = value == null ? '' : String(value).trim();
      if (text) specifications[label] = text;
    };
    add('Marca', specs.marca);
    add('Modelo', specs.modelo);
    add('Voltagem', specs.voltagem);
    add('Garantia', specs.garantia);
    add('Peso', specs.peso);
    add('Dimensões', specs.dimensoes);
    add('EAN', specs.ean);
    const measures = (specs.medidasDescricao || [])
      .map((line) => String(line).replace(/^[\s*-]+/, '').replace(/[\s*]+$/, '').trim())
      .filter((line) => line && !line.endsWith(':'));
    const options = new Set();
    for (const variation of item.variacoes || []) {
      for (const option of variation.opcoes || []) options.add(String(option));
    }
    const name = titleCase(String(item.nome || '').trim());
    const pix = item.pagamento?.pixAVista;
    const card = item.pagamento?.cartao;
    return {
      _id: item.id,
      name,
      shortName: shortName(name),
      category: categoryName(item.categoria),
      description: clean(item.descricao),
      price: item.preco,
      promotionalPrice: item.precoPromocional ?? undefined,
      pixPrice: pix?.valor,
      installments: card?.parcelas,
      installmentValue: card?.valorParcela,
      stock: item.disponivel === false ? 0 : DEFAULT_STOCK,
      images: item.imagens || [],
      specifications,
      measures,
      voltageOptions: options.size > 1 ? [...options] : [],
      videoUrl: watchUrl(specs.video),
      url: item.url,
    };
  });
}

/**
 * Popula o banco na primeira execução: catálogo oficial, cupom de
 * demonstração e (fora de produção) as contas de demonstração do app.
 * Nunca sobrescreve dados existentes.
 */
async function seed() {
  if ((await Product.estimatedDocumentCount()) === 0) {
    await Product.insertMany(loadCatalog());
  }
  if (!(await Coupon.exists({ _id: 'PRIMEIRACOMPRA' }))) {
    await Coupon.create({
      _id: 'PRIMEIRACOMPRA',
      description: '10% de desconto na primeira compra',
      discountPercent: 10,
      minimumSubtotal: 0,
    });
  }
  if (config.seedDemoUsers) {
    const demo = [
      {
        name: 'Leandro Gonçalves',
        email: 'leandro@email.com',
        phone: '(11) 99999-4321',
        role: 'admin',
        password: 'Santi@2026',
      },
      {
        name: 'Carlos Silva',
        email: 'carlos@email.com',
        phone: '(11) 98888-1111',
        role: 'client',
        password: 'Cliente@2026',
      },
    ];
    for (const { password, ...user } of demo) {
      if (!(await User.exists({ email: user.email }))) {
        await User.create({ ...user, passwordHash: await bcrypt.hash(password, 10) });
      }
    }
  }
}

module.exports = { seed, loadCatalog };
