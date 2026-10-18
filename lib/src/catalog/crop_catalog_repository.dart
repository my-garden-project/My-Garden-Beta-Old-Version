import 'dart:convert';

import 'package:flutter/services.dart';

import 'crop_catalog.dart';

class CropCatalogRepository {
  static const dataAsset =
      'assets/data/crop_catalog/edible_crops_ua_pl_batch_001_50.json';
  static const qaAsset =
      'assets/data/crop_catalog/edible_crops_ua_pl_batch_001_qa.json';
  static const cropSpecificSourcesAsset =
      'assets/data/crop_catalog/crop_specific_sources.json';

  static CropCatalog? _cached;

  static Future<CropCatalog> load({AssetBundle? bundle}) async {
    if (bundle != null) return _load(bundle);
    final cached = _cached;
    if (cached != null) return cached;
    final loaded = await _load(rootBundle);
    _cached = loaded;
    return loaded;
  }

  static Future<CropCatalog?> loadOrNull({AssetBundle? bundle}) async {
    try {
      return await load(bundle: bundle);
    } on Object {
      return null;
    }
  }

  static Future<CropCatalog> _load(AssetBundle bundle) async {
    Future<String> readUtf8(String asset) async {
      final bytes = await bundle.load(asset);
      return utf8.decode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }

    final rawFiles = await Future.wait([
      readUtf8(dataAsset),
      readUtf8(qaAsset),
      readUtf8(cropSpecificSourcesAsset),
    ]);
    final data = jsonDecode(rawFiles[0]);
    final qa = jsonDecode(rawFiles[1]);
    final cropSpecificSources = jsonDecode(rawFiles[2]);
    if (data is! Map || qa is! Map || cropSpecificSources is! Map) {
      throw const FormatException('Crop catalog assets must contain objects');
    }
    return CropCatalog.fromJson(
      Map<String, dynamic>.from(data),
      qa: Map<String, dynamic>.from(qa),
      cropSpecificSources: CropSpecificSourceIndex.fromJson(
        Map<String, dynamic>.from(cropSpecificSources),
      ),
    );
  }
}
