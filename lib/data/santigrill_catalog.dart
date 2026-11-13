import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/product.dart';

/// Conteúdo oficial da SantiGrill extraído de https://www.santigrill.com.br/
/// e salvo em `assets/data/santigrill.json` (ver docs/MAPEAMENTO_SITE.md).
///
/// O app lê esse arquivo na inicialização; nenhum preço ou dado da empresa é
/// definido no código.
class SantiGrillCatalog {
  const SantiGrillCatalog({
    required this.version,
    required this.company,
    required this.categories,
    required this.products,
    required this.info,
    required this.faq,
  });

  static const assetPath = 'assets/data/santigrill.json';

  /// Estoque inicial atribuído a cada produto. O site não publica estoque;
  /// o valor é operacional e pode ser ajustado no painel administrativo.
  static const defaultStock = 10;

  /// Identifica a versão do catálogo (data da coleta). Quando muda, o app
  /// substitui o catálogo salvo no aparelho pelo novo.
  final String version;
  final CompanyInfo company;
  final List<String> categories;
  final List<Product> products;
  final List<InfoSection> info;
  final List<FaqItem> faq;

  static const empty = SantiGrillCatalog(
    version: '',
    company: CompanyInfo.empty,
    categories: [],
    products: [],
    info: [],
    faq: [],
  );

  static Future<SantiGrillCatalog> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return SantiGrillCatalog.fromJsonString(raw);
  }

  factory SantiGrillCatalog.fromJsonString(String raw) =>
      SantiGrillCatalog.fromJson(_map(jsonDecode(raw)));

  factory SantiGrillCatalog.fromJson(Map<String, Object?> json) {
    final categoryNames = <String, String>{};
    final categoryParents = <String, String?>{};
    for (final raw in _list(json['categorias'])) {
      final category = _map(raw);
      final id = category['id']?.toString() ?? '';
      categoryNames[id] = category['nome']?.toString() ?? id;
      categoryParents[id] = category['categoriaPai']?.toString();
    }
    String categoryName(String id) {
      var current = id;
      // Subcategorias (ex.: grelhas-moeda) são agrupadas na categoria principal.
      while (categoryParents[current] != null) {
        current = categoryParents[current]!;
      }
      return categoryNames[current] ?? current;
    }

    final products = _list(
      json['produtos'],
    ).map((raw) => _product(_map(raw), categoryName)).toList();

    final categories = <String>[];
    for (final entry in categoryNames.entries) {
      if (categoryParents[entry.key] == null) categories.add(entry.value);
    }

    final info = _map(json['informacoes']);
    final sections = <InfoSection>[
      for (final entry in const {
        'pagamento': 'Formas de pagamento',
        'entrega': 'Envio e entrega',
        'garantia': 'Garantia',
        'trocas': 'Trocas e devoluções',
        'seguranca': 'Segurança',
      }.entries)
        if (_map(info[entry.key])['texto'] case final String text
            when text.trim().isNotEmpty)
          InfoSection(
            id: entry.key,
            title: entry.value,
            body: _cleanText(text),
            url: _map(info[entry.key])['url']?.toString(),
          ),
    ];

    final faq = [
      for (final raw in _list(info['faq']))
        if (_map(raw) case final item
            when (item['pergunta'] ?? item['question']) != null)
          FaqItem(
            question: (item['pergunta'] ?? item['question']).toString(),
            answer: _cleanText(
              (item['resposta'] ?? item['answer'] ?? '').toString(),
            ),
          ),
    ];

    return SantiGrillCatalog(
      version: json['coletadoEm']?.toString() ?? '',
      company: CompanyInfo.fromJson(_map(json['empresa'])),
      categories: categories,
      products: products,
      info: sections,
      faq: faq,
    );
  }

  static Product _product(
    Map<String, Object?> json,
    String Function(String) categoryName,
  ) {
    final specs = _map(json['especificacoes']);
    final specifications = <String, String>{};
    void addSpec(String label, Object? value) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) specifications[label] = text;
    }

    addSpec('Marca', specs['marca']);
    addSpec('Modelo', specs['modelo']);
    addSpec('Voltagem', specs['voltagem']);
    addSpec('Garantia', specs['garantia']);
    addSpec('Peso', specs['peso']);
    addSpec('Dimensões', specs['dimensoes']);
    addSpec('EAN', specs['ean']);

    final measures = _list(specs['medidasDescricao'])
        .map((line) => line.toString().replaceAll(RegExp(r'^[\s*\-]+'), ''))
        .map((line) => line.replaceAll(RegExp(r'[\s*]+$'), '').trim())
        .where((line) => line.isNotEmpty && !line.endsWith(':'))
        .toList();

    final options = <String>{};
    for (final raw in _list(json['variacoes'])) {
      for (final option in _list(_map(raw)['opcoes'])) {
        options.add(option.toString());
      }
    }

    final payment = _map(json['pagamento']);
    final pix = _map(payment['pixAVista']);
    final card = _map(payment['cartao']);
    final name = json['nome']?.toString().trim() ?? '';

    return Product(
      id: json['id']?.toString() ?? '',
      name: _titleCase(name),
      shortName: _shortName(_titleCase(name)),
      category: categoryName(json['categoria']?.toString() ?? ''),
      description: _cleanText(json['descricao']?.toString() ?? ''),
      price: (json['preco'] as num?)?.toDouble() ?? 0,
      promotionalPrice: (json['precoPromocional'] as num?)?.toDouble(),
      pixPrice: (pix['valor'] as num?)?.toDouble(),
      installments: (card['parcelas'] as num?)?.toInt(),
      installmentValue: (card['valorParcela'] as num?)?.toDouble(),
      stock: json['disponivel'] == false ? 0 : defaultStock,
      images: _list(json['imagens']).map((item) => item.toString()).toList(),
      specifications: specifications,
      measures: measures,
      voltageOptions: options.length > 1 ? options.toList() : const [],
      videoUrl: _watchUrl(specs['video']?.toString()),
      url: json['url']?.toString(),
    );
  }

  /// Converte o embed do YouTube em link que abre no app/navegador.
  static String? _watchUrl(String? embed) {
    if (embed == null || embed.isEmpty) return null;
    final match = RegExp(r'embed/([\w-]+)').firstMatch(embed);
    return match == null
        ? embed
        : 'https://www.youtube.com/watch?v=${match.group(1)}';
  }

  /// Alguns nomes no site estão todos em maiúsculas; padroniza a exibição
  /// mantendo siglas como INOX e medidas.
  static String _titleCase(String value) {
    final letters = value.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ]'), '');
    if (letters.isEmpty || letters != letters.toUpperCase()) return value;
    const lower = {'de', 'da', 'do', 'das', 'dos', 'e', 'para', 'com'};
    var first = true;
    return value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          final lowerWord = word.toLowerCase();
          final result = !first && lower.contains(lowerWord)
              ? lowerWord
              : word[0] + lowerWord.substring(1);
          first = false;
          return result;
        })
        .join(' ');
  }

  /// Nome curto para os cards: remove termos repetidos em todos os itens da
  /// mesma linha (ex.: "e rotatório elétrico"), deixando visível o que os
  /// diferencia (ex.: "3 espetos"). O nome completo aparece no detalhe.
  static String _shortName(String name) {
    final cleaned = name
        .replaceAll(RegExp(r'\s*Santi\s?grill\s*', caseSensitive: false), ' ')
        .replaceAll(
          RegExp(r'(\s+e\s+|/)rotat[óo]rio', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+el[ée]trico', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty ? name : cleaned;
  }

  static String _cleanText(String value) => value
      .replaceAll(' ', ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

class CompanyInfo {
  const CompanyInfo({
    required this.name,
    this.legalName,
    this.cnpj,
    this.slogan,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.phones = const [],
    this.whatsapp,
    this.emails = const [],
    this.facebook,
    this.businessHours,
    this.website,
    this.highlights = const [],
  });

  static const empty = CompanyInfo(name: 'SantiGrill');

  final String name;
  final String? legalName;
  final String? cnpj;
  final String? slogan;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final List<String> phones;
  final String? whatsapp;
  final List<String> emails;
  final String? facebook;
  final String? businessHours;
  final String? website;
  final List<String> highlights;

  String get address => [
    street,
    if (city != null) '${city!}${state == null ? '' : ' - $state'}',
    if (postalCode != null) 'CEP $postalCode',
  ].whereType<String>().join(', ');

  /// Número no formato internacional (55 + DDD + número) para links tel/wa.me.
  static String? internationalNumber(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return null;
    return digits.startsWith('55') ? digits : '55$digits';
  }

  String? get whatsappUrl {
    final number = internationalNumber(whatsapp);
    return number == null ? null : 'https://wa.me/$number';
  }

  factory CompanyInfo.fromJson(Map<String, Object?> json) {
    final address = _map(json['endereco']);
    String? text(Object? value) {
      final result = value?.toString().trim();
      return result == null || result.isEmpty ? null : result;
    }

    return CompanyInfo(
      name: text(json['nome']) ?? 'SantiGrill',
      legalName: text(json['razaoSocial']),
      cnpj: text(json['cnpj']),
      slogan: text(json['slogan']),
      street: [
        text(address['logradouro']),
        text(address['numero']),
      ].whereType<String>().join(', ').ifEmptyNull,
      city: text(address['cidade']),
      state: text(address['uf']),
      postalCode: text(address['cep']),
      phones: _list(json['telefones']).map((item) => '$item').toList(),
      whatsapp: text(json['whatsapp']),
      emails: _list(json['emails']).map((item) => '$item').toList(),
      facebook: text(_map(json['redesSociais'])['facebook']),
      businessHours: text(json['horarioAtendimento']),
      website: text(json['site']),
      highlights: _list(json['destaquesHome']).map((item) => '$item').toList(),
    );
  }
}

class InfoSection {
  const InfoSection({
    required this.id,
    required this.title,
    required this.body,
    this.url,
  });

  final String id;
  final String title;
  final String body;
  final String? url;
}

class FaqItem {
  const FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}

Map<String, Object?> _map(Object? value) {
  if (value is Map<String, Object?>) return value;
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
  return const {};
}

List<Object?> _list(Object? value) => value is List ? value : const [];
