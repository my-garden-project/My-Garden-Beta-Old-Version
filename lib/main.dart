import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app_theme.dart';
import 'src/app_state.dart';
import 'src/app/app_shell.dart';
import 'src/catalog/crop_catalog_repository.dart';
import 'src/storage.dart';
import 'src/screens/onboarding_screen.dart';
import 'src/screens/legal_screen.dart';
import 'src/screens/startup_screen.dart';
import 'src/screens/profile_setup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = PrefsStorage(prefs);
  final catalog = await CropCatalogRepository.loadOrNull();
  final state = await AppState.load(
    storage,
    catalogCrops: catalog?.toCrops() ?? const [],
  );

  runApp(
    GardenApp(
      state: state,
      storage: storage,
      initialOnboardingCompleted: storage.onboardingCompleted,
      initialTermsAccepted: storage.termsAccepted,
      initialProfileConfigured: state.profileName.isNotEmpty,
    ),
  );
}

class GardenApp extends StatefulWidget {
  final AppState state;
  final PrefsStorage storage;
  final bool initialOnboardingCompleted;
  final bool initialTermsAccepted;
  final bool initialProfileConfigured;

  const GardenApp({
    super.key,
    required this.state,
    required this.storage,
    this.initialOnboardingCompleted = true,
    this.initialTermsAccepted = true,
    this.initialProfileConfigured = true,
  });

  @override
  State<GardenApp> createState() => _GardenAppState();
}

class _GardenAppState extends State<GardenApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  late bool _onboardingCompleted;
  late bool _termsAccepted;
  late bool _profileConfigured;
  bool _startupCompleted = false;

  @override
  void initState() {
    super.initState();
    _onboardingCompleted = widget.initialOnboardingCompleted;
    _termsAccepted = widget.initialTermsAccepted;
    _profileConfigured = widget.initialProfileConfigured;
    if (widget.state.recoveredCorruptedData) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final message = widget.state.corruptedBackupSaved
            ? 'Локальні дані були пошкоджені. Резервну копію збережено.'
            : 'Локальні дані були пошкоджені. Не вдалося створити резервну копію.';
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(message)),
        );
      });
    }
  }

  Future<bool> _acceptTerms({
    required bool researchConsent,
    required bool catalogPhotoLicense,
  }) async {
    try {
      await widget.storage.acceptTerms(
        researchConsent: researchConsent,
        catalogPhotoLicense: catalogPhotoLicense,
      );
      widget.state.refreshConsentFromStorage();
      if (!mounted) return false;
      setState(() => _termsAccepted = true);
      return true;
    } on StorageWriteException {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Не вдалося зберегти вибір. Спробуйте ще раз.'),
        ),
      );
      return false;
    }
  }

  Future<bool> _completeOnboarding() async {
    try {
      await widget.storage.completeOnboarding();
      if (!mounted) return false;
      setState(() => _onboardingCompleted = true);
      return true;
    } on StorageWriteException {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Не вдалося зберегти налаштування. Спробуйте ще раз.'),
        ),
      );
      return false;
    }
  }

  Future<bool> _saveProfileName(String name) async {
    try {
      await widget.state.setProfileName(name);
      if (!mounted) return false;
      setState(() => _profileConfigured = true);
      return true;
    } on Object {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Не вдалося зберегти ім’я. Спробуйте ще раз.'),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InheritedAppState(
      state: widget.state,
      storage: widget.storage,
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) => MaterialApp(
          title: 'Мій город',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _scaffoldMessengerKey,
          theme: buildAppTheme(),
          locale: const Locale('uk'),
          supportedLocales: const [
            Locale('uk'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(16) / 16;
            final combinedScale = (systemScale * widget.state.textScale)
                .clamp(1.0, 2.0)
                .toDouble();
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(combinedScale),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: !_startupCompleted
                ? StartupScreen(
                    key: const ValueKey('startup'),
                    onFinished: () => setState(() => _startupCompleted = true),
                  )
                : !_onboardingCompleted
                    ? OnboardingScreen(
                        key: const ValueKey('onboarding'),
                        onFinished: _completeOnboarding,
                      )
                    : !_profileConfigured
                        ? ProfileSetupScreen(
                            key: const ValueKey('profile-setup'),
                            onFinished: _saveProfileName,
                          )
                        : !_termsAccepted
                            ? ConsentScreen(
                                key: const ValueKey('consent'),
                                onAccepted: _acceptTerms,
                              )
                            : const AppShell(key: ValueKey('app-shell')),
          ),
        ),
      ),
    );
  }
}
