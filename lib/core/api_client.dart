import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Erro de comunicação com a API. [isNetwork] indica falha de rede
/// (servidor fora do ar, sem internet, tempo esgotado), caso em que o app
/// continua offline e tenta de novo depois.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.isNetwork = false});

  final String message;
  final int? statusCode;
  final bool isNetwork;

  @override
  String toString() => message;
}

/// Cliente HTTP da API LeadSystem (pasta server/).
class ApiClient {
  ApiClient(String baseUrl, {http.Client? client})
    : baseUrl = normalizeUrl(baseUrl),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? token;

  static const timeout = Duration(seconds: 12);

  static String normalizeUrl(String value) {
    var url = value.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url.replaceAll(RegExp(r'/+$'), '');
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, Object?>> get(String path, {Map<String, String>? query}) =>
      _send(() => _client.get(_uri(path, query), headers: _headers));

  Future<Map<String, Object?>> post(String path, Object? body) => _send(
    () => _client.post(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<Map<String, Object?>> put(String path, Object? body) => _send(
    () => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<Map<String, Object?>> patch(String path, Object? body) => _send(
    () => _client.patch(_uri(path), headers: _headers, body: jsonEncode(body)),
  );

  Future<Map<String, Object?>> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _headers));

  /// Envia uma foto (multipart) e devolve a URL pública dela.
  Future<String> uploadImage(List<int> bytes, String filename) async {
    final request = http.MultipartRequest('POST', _uri('/api/uploads'))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: filename.toLowerCase().endsWith('.png')
              ? MediaType('image', 'png')
              : MediaType('image', 'jpeg'),
        ),
      );
    final data = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
    );
    final url = data['url'];
    if (url is! String) throw const ApiException('Resposta inválida do envio.');
    return url;
  }

  Future<bool> health() async {
    try {
      final data = await get('/health');
      return data['status'] == 'ok';
    } on ApiException {
      return false;
    }
  }

  /// Codifica ids como "#SG-2026-0001" para uso em caminhos de URL.
  static String encodeId(String id) => Uri.encodeComponent(id);

  Future<Map<String, Object?>> _send(
    Future<http.Response> Function() request,
  ) async {
    http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'O servidor demorou para responder.',
        isNetwork: true,
      );
    } on SocketException {
      throw const ApiException('Sem conexão com o servidor.', isNetwork: true);
    } on http.ClientException {
      throw const ApiException('Sem conexão com o servidor.', isNetwork: true);
    } on HandshakeException {
      throw const ApiException(
        'Falha na conexão segura com o servidor.',
        isNetwork: true,
      );
    }
    Map<String, Object?> data = const {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) {
          data = decoded.map((key, value) => MapEntry('$key', value));
        }
      } on FormatException {
        data = const {};
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    final message = data['message']?.toString();
    throw ApiException(
      message ?? 'Erro ${response.statusCode} no servidor.',
      statusCode: response.statusCode,
      isNetwork: response.statusCode >= 500 || response.statusCode == 429,
    );
  }

  void close() => _client.close();
}
