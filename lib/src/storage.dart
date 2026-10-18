import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageLoadResult {
  final AppData data;
  final Object? recoveryError;
  final Object? backupError;
  final bool backupSaved;

  const StorageLoadResult({
    required this.data,
    this.recoveryError,
    this.backupError,
    this.backupSaved = false,
  });

  bool get recoveredCorruptedData => recoveryError != null;
}

class StorageWriteException implements Exception {
  final Object? cause;
  final StackTrace? stackTrace;

  const StorageWriteException({this.cause, this.stackTrace});

  @override
  String toString() => 'Failed to save local data';
}

class PrefsStorage {
  static const currentTermsVersion = '2026-07-17';
  static const _key = 'app_data_v1';
  static const _corruptedBackupKey = 'app_data_corrupted_backup_v1';
  static const _onboardingCompletedKey = 'onboarding_completed_v1';
  static const _adsRemovedKey = 'ads_removed_demo_v1';
  static const _guidedTourCompletedKey = 'guided_tour_completed_v1';
  static const _termsVersionKey = 'terms_version_v1';
  static const _termsAcceptedAtKey = 'terms_accepted_at_v1';
  static const _researchConsentKey = 'research_consent_v1';
  static const _catalogPhotoLicenseKey = 'catalog_photo_license_v1';
  static const _textScaleKey = 'text_scale_v1';
  static const _profileNameKey = 'profile_name_v1';
  final SharedPreferences prefs;

  PrefsStorage(this.prefs);

  bool get onboardingCompleted =>
      prefs.getBool(_onboardingCompletedKey) ?? false;

  bool get adsRemoved => prefs.getBool(_adsRemovedKey) ?? false;

  bool get guidedTourCompleted =>
      prefs.getBool(_guidedTourCompletedKey) ?? false;

  bool get termsAccepted =>
      prefs.getString(_termsVersionKey) == currentTermsVersion;

  DateTime? get termsAcceptedAt {
    final value = prefs.getString(_termsAcceptedAtKey);
    return value == null ? null : DateTime.tryParse(value);
  }

  bool get researchConsent => prefs.getBool(_researchConsentKey) ?? false;

  bool get catalogPhotoLicense =>
      prefs.getBool(_catalogPhotoLicenseKey) ?? false;

  String get profileName => prefs.getString(_profileNameKey)?.trim() ?? '';

  double get textScale =>
      (prefs.getDouble(_textScaleKey) ?? 1.0).clamp(1.0, 1.5).toDouble();

  Future<void> completeGuidedTour() => _setBool(_guidedTourCompletedKey, true);

  Future<void> acceptTerms({
    required bool researchConsent,
    required bool catalogPhotoLicense,
  }) async {
    try {
      final values = await Future.wait([
        prefs.setString(_termsVersionKey, currentTermsVersion),
        prefs.setString(_termsAcceptedAtKey, DateTime.now().toIso8601String()),
        prefs.setBool(_researchConsentKey, researchConsent),
        prefs.setBool(_catalogPhotoLicenseKey, catalogPhotoLicense),
      ]);
      if (values.any((saved) => !saved)) throw const StorageWriteException();
    } on StorageWriteException {
      rethrow;
    } catch (error, stackTrace) {
      throw StorageWriteException(cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> setResearchConsent(bool value) =>
      _setBool(_researchConsentKey, value);

  Future<void> setCatalogPhotoLicense(bool value) =>
      _setBool(_catalogPhotoLicenseKey, value);

  Future<void> setProfileName(String value) async {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length < 2 || normalized.length > 40) {
      throw ArgumentError.value(
        value,
        'value',
        'Profile name must contain between 2 and 40 characters',
      );
    }
    try {
      final saved = await prefs.setString(_profileNameKey, normalized);
      if (!saved) throw const StorageWriteException();
    } on StorageWriteException {
      rethrow;
    } catch (error, stackTrace) {
      throw StorageWriteException(cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> setTextScale(double value) async {
    final normalized = value.clamp(1.0, 1.5).toDouble();
    try {
      final saved = await prefs.setDouble(_textScaleKey, normalized);
      if (!saved) throw const StorageWriteException();
    } on StorageWriteException {
      rethrow;
    } catch (error, stackTrace) {
      throw StorageWriteException(cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> setAdsRemoved(bool value) async {
    await _setBool(_adsRemovedKey, value);
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      final saved = await prefs.setBool(key, value);
      if (!saved) throw const StorageWriteException();
    } on StorageWriteException {
      rethrow;
    } catch (error, stackTrace) {
      throw StorageWriteException(cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final saved = await prefs.setBool(_onboardingCompletedKey, true);
      if (!saved) throw const StorageWriteException();
    } on StorageWriteException {
      rethrow;
    } catch (error, stackTrace) {
      throw StorageWriteException(cause: error, stackTrace: stackTrace);
    }
  }

  Future<void> save(AppData data) async {
    try {
      final saved = await prefs.setString(_key, encodeAppData(data));
      if (!saved) {
        throw const StorageWriteException();
      }
    } on StorageWriteException {
      rethrow;
    } catch (error, stackTrace) {
      throw StorageWriteException(cause: error, stackTrace: stackTrace);
    }
  }

  Future<StorageLoadResult> load() async {
    final raw = prefs.getString(_key);
    if (raw == null) {
      return StorageLoadResult(data: AppData.initial());
    }

    try {
      return StorageLoadResult(data: decodeAppData(raw));
    } catch (error) {
      Object? backupError;
      var backupSaved = false;

      try {
        backupSaved = await prefs.setString(_corruptedBackupKey, raw);
        if (!backupSaved) {
          backupError = StateError('SharedPreferences rejected backup write');
        }
      } catch (error) {
        backupError = error;
      }

      return StorageLoadResult(
        data: AppData.initial(),
        recoveryError: error,
        backupError: backupError,
        backupSaved: backupSaved,
      );
    }
  }
}
