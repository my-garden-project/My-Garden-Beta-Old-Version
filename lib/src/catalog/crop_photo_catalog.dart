import 'dart:convert';

import 'package:flutter/services.dart';

class CropPhoto {
  final String assetPath;
  final String fileTitle;
  final String sourceUrl;
  final String originalUrl;
  final String author;
  final String license;
  final String licenseUrl;
  final bool attributionRequired;

  const CropPhoto({
    required this.assetPath,
    required this.fileTitle,
    required this.sourceUrl,
    required this.originalUrl,
    required this.author,
    required this.license,
    required this.licenseUrl,
    required this.attributionRequired,
  });

  factory CropPhoto.fromJson(Map<String, dynamic> json) => CropPhoto(
        assetPath: json['asset'] as String,
        fileTitle: json['fileTitle'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        originalUrl: json['originalUrl'] as String? ?? '',
        author: json['author'] as String? ?? '',
        license: json['license'] as String? ?? '',
        licenseUrl: json['licenseUrl'] as String? ?? '',
        attributionRequired: json['attributionRequired'] as bool? ?? false,
      );
}

class CropPhotoPair {
  final CropPhoto growing;
  final CropPhoto harvested;
  final CropPhoto ripeness;

  const CropPhotoPair({
    required this.growing,
    required this.harvested,
    required this.ripeness,
  });

  factory CropPhotoPair.fromJson(Map<String, dynamic> json) {
    final harvested = CropPhoto.fromJson(
      json['harvested'] as Map<String, dynamic>,
    );
    final rawRipeness = json['ripeness'];
    return CropPhotoPair(
      growing: CropPhoto.fromJson(
        json['growing'] as Map<String, dynamic>,
      ),
      harvested: harvested,
      ripeness: rawRipeness is Map<String, dynamic>
          ? CropPhoto.fromJson(rawRipeness)
          : harvested,
    );
  }
}

class CropPhotoCatalog {
  final String source;
  final String sourcePolicyUrl;
  final String checkedOn;
  final String note;
  final Map<String, CropPhotoPair> records;

  const CropPhotoCatalog({
    required this.source,
    required this.sourcePolicyUrl,
    required this.checkedOn,
    required this.note,
    required this.records,
  });

  factory CropPhotoCatalog.fromJson(Map<String, dynamic> json) {
    final rawRecords = json['records'] as Map<String, dynamic>? ?? const {};
    return CropPhotoCatalog(
      source: json['source'] as String? ?? '',
      sourcePolicyUrl: json['sourcePolicyUrl'] as String? ?? '',
      checkedOn: json['checkedOn'] as String? ?? '',
      note: json['note'] as String? ?? '',
      records: {
        for (final entry in rawRecords.entries)
          entry.key: CropPhotoPair.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
    );
  }
}

class CropPhotoRepository {
  static const assetPath = 'assets/images/crops/manifest.json';
  static CropPhotoCatalog? _cached;

  static Future<CropPhotoCatalog> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final loaded = await _loadFromAssetBundle();
    _cached = loaded;
    return loaded;
  }

  static Future<CropPhotoCatalog> _loadFromAssetBundle() async {
    final bytes = await rootBundle.load(assetPath);
    final source = utf8.decode(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    return CropPhotoCatalog.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }
}
