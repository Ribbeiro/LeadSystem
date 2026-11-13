import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/santigrill_catalog.dart';
import '../models/app_models.dart';
import '../models/product.dart';
import '../widgets/shared.dart';

/// Abre links externos (WhatsApp, telefone, e-mail, mapa, site) e avisa o
/// usuário quando o aparelho não tem um app capaz de abri-los.
abstract final class ExternalLinks {
  static Future<bool> open(BuildContext context, Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        'Não foi possível abrir este link. Verifique sua conexão ou se há um '
        'aplicativo compatível instalado.',
      );
    }
    return opened;
  }

  static Future<bool> url(BuildContext context, String url) =>
      open(context, Uri.parse(url));

  static Future<bool> phone(BuildContext context, String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return open(context, Uri(scheme: 'tel', path: digits));
  }

  static Future<bool> whatsapp(
    BuildContext context,
    CompanyInfo company, {
    String? message,
  }) {
    final number = CompanyInfo.internationalNumber(company.whatsapp);
    if (number == null) {
      showAppSnackBar(context, 'WhatsApp da empresa não informado.');
      return Future.value(false);
    }
    return open(context, Uri.https('wa.me', '/$number', {'text': ?message}));
  }

  static Future<bool> email(
    BuildContext context,
    String address, {
    String? subject,
  }) => open(
    context,
    Uri(
      scheme: 'mailto',
      path: address,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    ),
  );

  static Future<bool> map(BuildContext context, String address) => open(
    context,
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    }),
  );

  /// Envia o resumo do pedido para o WhatsApp da loja.
  static Future<bool> sendOrder(
    BuildContext context,
    CompanyInfo company,
    CustomerOrder order,
  ) => whatsapp(context, company, message: orderSummary(order));

  /// Envia o resumo do orçamento para o WhatsApp da loja.
  static Future<bool> sendQuote(
    BuildContext context,
    CompanyInfo company,
    QuoteRequest quote,
  ) => whatsapp(context, company, message: quoteSummary(quote));
}

/// Texto do pedido para o WhatsApp (formatação *negrito* do WhatsApp).
String orderSummary(CustomerOrder order) {
  final address = order.deliveryAddress;
  final buffer = StringBuffer()
    ..writeln('Olá! Fiz um pedido pelo app SantiGrill.')
    ..writeln()
    ..writeln('*Pedido ${order.id}*');
  for (final item in order.items) {
    final option = item.option == null ? '' : ' (${item.option})';
    buffer.writeln(
      '• ${item.quantity}x ${item.name}$option - ${money(item.total)}',
    );
  }
  buffer
    ..writeln()
    ..writeln('Subtotal: ${money(order.subtotal)}');
  if (order.discount > 0) {
    buffer.writeln('Descontos: - ${money(order.discount)}');
  }
  buffer
    ..writeln('Frete: ${money(order.shipping)}')
    ..writeln('*Total: ${money(order.total)}* (${order.paymentMethod})')
    ..writeln()
    ..writeln(
      'Entrega: ${address.street}, ${address.number} - '
      '${address.neighborhood}, ${address.city}/${address.state} - '
      'CEP ${address.postalCode}',
    );
  if (order.customerName != null) {
    buffer.writeln('Cliente: ${order.customerName}');
  }
  return buffer.toString().trim();
}

String quoteSummary(QuoteRequest quote) => [
  'Olá! Solicitei um orçamento pelo app SantiGrill.',
  '',
  '*Orçamento ${quote.id}*',
  'Produto: ${quote.productName}',
  'Necessidade: ${quote.details}',
  '',
  'Nome: ${quote.customerName}',
  'Telefone: ${quote.phone}',
  'E-mail: ${quote.email}',
].join('\n');
