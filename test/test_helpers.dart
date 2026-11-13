import 'dart:io';

import 'package:leadsystem/core/app_state.dart';
import 'package:leadsystem/data/santigrill_catalog.dart';

SantiGrillCatalog? _cached;

/// Catálogo oficial lido diretamente de assets/data/santigrill.json.
SantiGrillCatalog loadTestCatalog() =>
    _cached ??= SantiGrillCatalog.fromJsonString(
      File(SantiGrillCatalog.assetPath).readAsStringSync(),
    );

/// Estado em memória (sem persistência) com o catálogo real.
AppState buildTestState() => AppState(null, loadTestCatalog());
