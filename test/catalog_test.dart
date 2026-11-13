import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/data/santigrill_catalog.dart';

import 'test_helpers.dart';

/// Garante que o catálogo extraído do site está íntegro: todo produto tem
/// preço real, categoria conhecida e imagens existentes e leves.
void main() {
  final catalog = loadTestCatalog();

  test('carrega produtos e categorias do site', () {
    expect(catalog.products, hasLength(24));
    expect(catalog.categories, containsAll(['Grelhas', 'Espetos']));
    expect(catalog.version, isNotEmpty);
  });

  test('todo produto tem id único, nome, preço e categoria válida', () {
    final ids = <String>{};
    for (final product in catalog.products) {
      expect(ids.add(product.id), isTrue, reason: 'id duplicado ${product.id}');
      expect(product.name, isNotEmpty);
      expect(product.price, greaterThan(0), reason: product.id);
      expect(catalog.categories, contains(product.category));
    }
  });

  test('imagens existem e são otimizadas para mobile', () {
    for (final product in catalog.products) {
      expect(product.images, isNotEmpty, reason: product.id);
      for (final path in product.images) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        expect(file.lengthSync(), lessThan(150 * 1024), reason: path);
      }
    }
    expect(File('assets/images/brand/logo.png').existsSync(), isTrue);
  });

  test('dados da empresa vêm do site', () {
    final company = catalog.company;
    expect(company.name, 'SantiGrill');
    expect(company.cnpj, isNotNull);
    expect(company.phones, isNotEmpty);
    expect(company.emails, everyElement(contains('@santigrill.com.br')));
    expect(company.whatsappUrl, startsWith('https://wa.me/55'));
    expect(company.address, contains('Santo André'));
  });

  test('políticas da loja estão disponíveis', () {
    final ids = catalog.info.map((section) => section.id);
    expect(ids, containsAll(['pagamento', 'entrega', 'trocas']));
    expect(catalog.faq, isNotEmpty);
  });

  test('número internacional do WhatsApp', () {
    expect(CompanyInfo.internationalNumber('(11) 98827-7030'), '5511988277030');
    expect(CompanyInfo.internationalNumber(null), isNull);
    expect(CompanyInfo.internationalNumber('123'), isNull);
  });
}
