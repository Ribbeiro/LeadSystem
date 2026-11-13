const mongoose = require('mongoose');

const { Schema } = mongoose;

const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    phone: { type: String, trim: true, default: '' },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['client', 'admin'], default: 'client' },
    blocked: { type: Boolean, default: false },
  },
  { timestamps: true },
);

userSchema.methods.toPublic = function toPublic() {
  return {
    id: this._id.toString(),
    name: this.name,
    email: this.email,
    phone: this.phone,
    role: this.role,
    blocked: this.blocked,
    createdAt: this.createdAt,
  };
};

const productSchema = new Schema(
  {
    _id: { type: String },
    name: { type: String, required: true, trim: true },
    shortName: { type: String, trim: true },
    category: { type: String, required: true, trim: true },
    description: { type: String, default: '' },
    price: { type: Number, required: true, min: 0 },
    promotionalPrice: { type: Number, min: 0 },
    pixPrice: { type: Number, min: 0 },
    installments: { type: Number, min: 1 },
    installmentValue: { type: Number, min: 0 },
    stock: { type: Number, required: true, min: 0, default: 0 },
    images: { type: [String], default: [] },
    specifications: { type: Map, of: String, default: {} },
    measures: { type: [String], default: [] },
    voltageOptions: { type: [String], default: [] },
    weightGrams: { type: Number, min: 0 },
    videoUrl: String,
    url: String,
    badge: String,
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

productSchema.methods.toPublic = function toPublic() {
  const json = this.toObject({ flattenMaps: true });
  json.id = json._id;
  delete json._id;
  delete json.__v;
  return json;
};

const addressSchema = new Schema(
  {
    label: String,
    street: String,
    number: String,
    complement: String,
    neighborhood: String,
    city: String,
    state: String,
    postalCode: String,
  },
  { _id: false },
);

const orderSchema = new Schema(
  {
    number: { type: String, required: true, unique: true },
    clientId: { type: String, required: true },
    customer: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    customerEmail: { type: String, required: true },
    customerName: String,
    items: [
      {
        _id: false,
        productId: String,
        name: String,
        unitPrice: Number,
        quantity: Number,
        image: String,
        option: String,
      },
    ],
    subtotal: Number,
    discount: Number,
    shipping: Number,
    total: Number,
    couponCode: String,
    paymentMethod: { type: String, enum: ['Pix', 'Cartão', 'Boleto'] },
    deliveryAddress: addressSchema,
    status: {
      type: String,
      enum: [
        'received',
        'paymentApproved',
        'preparing',
        'shipped',
        'delivered',
        'cancelled',
      ],
      default: 'received',
    },
    timeline: [
      {
        _id: false,
        status: String,
        title: String,
        note: String,
        createdAt: Date,
      },
    ],
  },
  { timestamps: true },
);
orderSchema.index({ customer: 1, clientId: 1 }, { unique: true });

orderSchema.methods.toPublic = function toPublic() {
  const json = this.toObject();
  return {
    id: json.number,
    clientId: json.clientId,
    createdAt: json.createdAt,
    updatedAt: json.updatedAt,
    customerEmail: json.customerEmail,
    customerName: json.customerName,
    items: json.items,
    subtotal: json.subtotal,
    discount: json.discount,
    shipping: json.shipping,
    total: json.total,
    couponCode: json.couponCode,
    paymentMethod: json.paymentMethod,
    deliveryAddress: json.deliveryAddress,
    status: json.status,
    timeline: json.timeline,
  };
};

const quoteSchema = new Schema(
  {
    number: { type: String, required: true, unique: true },
    clientId: { type: String },
    customer: { type: Schema.Types.ObjectId, ref: 'User' },
    productId: String,
    productName: String,
    customerName: { type: String, required: true },
    email: { type: String, required: true, lowercase: true, trim: true },
    phone: { type: String, required: true },
    details: { type: String, required: true },
    status: {
      type: String,
      enum: ['pending', 'reviewing', 'answered', 'approved', 'rejected'],
      default: 'pending',
    },
    response: String,
  },
  { timestamps: true },
);
quoteSchema.index({ customer: 1, clientId: 1 }, { unique: true, sparse: true });

quoteSchema.methods.toPublic = function toPublic() {
  const json = this.toObject();
  return {
    id: json.number,
    clientId: json.clientId,
    productId: json.productId,
    productName: json.productName,
    customerName: json.customerName,
    email: json.email,
    phone: json.phone,
    details: json.details,
    status: json.status,
    response: json.response,
    createdAt: json.createdAt,
    updatedAt: json.updatedAt,
  };
};

const couponSchema = new Schema(
  {
    _id: { type: String },
    description: String,
    discountPercent: { type: Number, min: 1, max: 100, required: true },
    minimumSubtotal: { type: Number, default: 0 },
    usageLimit: Number,
    usedCount: { type: Number, default: 0 },
    expiresAt: Date,
    active: { type: Boolean, default: true },
  },
  { timestamps: true },
);

const passwordResetSchema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  codeHash: { type: String, required: true },
  attempts: { type: Number, default: 0 },
  expiresAt: { type: Date, required: true },
  usedAt: Date,
});
passwordResetSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const counterSchema = new Schema({ _id: String, seq: { type: Number, default: 0 } });

const User = mongoose.model('User', userSchema);
const Product = mongoose.model('Product', productSchema);
const Order = mongoose.model('Order', orderSchema);
const Quote = mongoose.model('Quote', quoteSchema);
const Coupon = mongoose.model('Coupon', couponSchema);
const PasswordReset = mongoose.model('PasswordReset', passwordResetSchema);
const Counter = mongoose.model('Counter', counterSchema);

/** Gera números sequenciais legíveis: #SG-2026-0001, #ORC-2026-0001. */
async function nextNumber(prefix) {
  const year = new Date().getFullYear();
  const key = `${prefix}-${year}`;
  const counter = await Counter.findByIdAndUpdate(
    key,
    { $inc: { seq: 1 } },
    { upsert: true, new: true },
  );
  return `#${prefix}-${year}-${String(counter.seq).padStart(4, '0')}`;
}

module.exports = {
  User,
  Product,
  Order,
  Quote,
  Coupon,
  PasswordReset,
  Counter,
  nextNumber,
};
