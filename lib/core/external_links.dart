import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/santigrill_catalog.dart';
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
}
