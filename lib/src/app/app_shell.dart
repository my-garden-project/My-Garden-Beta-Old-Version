import 'package:flutter/material.dart';

import '../app_state.dart';
import '../app_theme.dart';
import '../screens/calendar_screen.dart';
import '../screens/fertilizer_marketplace_screen.dart';
import '../screens/garden_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/recommendations_screen.dart';
import '../storage.dart';
import '../widgets/guided_tour_overlay.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool? _adsRemoved;
  bool _bannerClosedForSession = false;
  bool _tourQueued = false;
  bool _tourShowing = false;
  final _tourBrandKey = GlobalKey();
  final _tourHelpKey = GlobalKey();
  final _tourCreateKey = GlobalKey();
  final _tourNavigationKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final storage = InheritedAppState.of(context).storage;
    _adsRemoved ??= storage.adsRemoved;
    if (!_tourQueued && !storage.guidedTourCompleted) {
      _tourQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) await _startTour();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final tabs = <Widget>[
      GardenListScreen(
        tourBrandKey: _tourBrandKey,
        tourHelpKey: _tourHelpKey,
        tourCreateKey: _tourCreateKey,
      ),
      const CalendarScreen(),
      const RecommendationsScreen(),
      ProfileScreen(
        adsRemoved: _adsRemoved ?? false,
        onAdsChanged: _setAdsRemoved,
        onShowTour: () => _startTour(force: true),
      ),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: tabs,
            ),
          ),
          if (!(_adsRemoved ?? false) && !_bannerClosedForSession)
            _MiniPartnerBanner(
              onOpen: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FertilizerMarketplaceScreen(),
                ),
              ),
              onClose: () => setState(() => _bannerClosedForSession = true),
              onRemoveAds: _showRemoveAds,
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: _tourNavigationKey,
        height: textScale >= 1.4 ? 96 : 80,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          if (index == _selectedIndex) return;
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Tooltip(
              message: 'Ваші ділянки та посадки',
              child: Icon(Icons.yard_outlined),
            ),
            selectedIcon: Tooltip(
              message: 'Ваші ділянки та посадки',
              child: Icon(Icons.yard_rounded),
            ),
            label: 'Городи',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Календар робіт і нагадувань',
              child: Icon(Icons.calendar_month_outlined),
            ),
            selectedIcon: Tooltip(
              message: 'Календар робіт і нагадувань',
              child: Icon(Icons.calendar_month_rounded),
            ),
            label: 'Календар',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Догляд, захист і корисні пропозиції',
              child: Icon(Icons.auto_awesome_outlined),
            ),
            selectedIcon: Tooltip(
              message: 'Догляд, захист і корисні пропозиції',
              child: Icon(Icons.auto_awesome_rounded),
            ),
            label: 'Поради',
          ),
          NavigationDestination(
            icon: Tooltip(
              message: 'Профіль, доступність і приватність',
              child: Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: Tooltip(
              message: 'Профіль, доступність і приватність',
              child: Icon(Icons.person_rounded),
            ),
            label: 'Профіль',
          ),
        ],
      ),
    );
  }

  Future<void> _startTour({bool force = false}) async {
    if (_tourShowing || !mounted) return;
    if (!force && InheritedAppState.of(context).storage.guidedTourCompleted) {
      return;
    }
    _tourShowing = true;
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex = 0);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (!mounted) return;
    await showGuidedTour(
      context,
      steps: [
        GuidedTourStep(
          targetKey: _tourBrandKey,
          icon: Icons.yard_outlined,
          title: 'Ваші городи',
          description:
              'Тут зберігаються ділянки, їхні розміри, сітки, сегменти й '
              'розміщення культур.',
        ),
        GuidedTourStep(
          targetKey: _tourCreateKey,
          icon: Icons.add_rounded,
          title: 'Створіть або додайте ділянку',
          description: 'Кнопка відкриває просту форму. Площу можна вказати в '
              'гектарах, сотках або квадратних метрах.',
        ),
        GuidedTourStep(
          targetKey: _tourNavigationKey,
          icon: Icons.touch_app_outlined,
          title: 'Головна навігація',
          description: 'Переходьте між городами, календарем, рекомендаціями та '
              'налаштуваннями профілю.',
        ),
        GuidedTourStep(
          targetKey: _tourHelpKey,
          icon: Icons.help_outline_rounded,
          title: 'Допомога завжди поруч',
          description:
              'Затисніть незнайому іконку, щоб побачити коротку підказку. '
              'Цю екскурсію можна повторити у профілі.',
        ),
      ],
    );
    if (!mounted) return;
    try {
      await InheritedAppState.of(context).storage.completeGuidedTour();
    } on StorageWriteException {
      // The tour can still finish even if this preference cannot be saved.
    }
    _tourShowing = false;
  }

  Future<void> _setAdsRemoved(bool value) async {
    try {
      await InheritedAppState.of(context).storage.setAdsRemoved(value);
      if (mounted) {
        setState(() {
          _adsRemoved = value;
          if (!value) _bannerClosedForSession = false;
        });
      }
    } on StorageWriteException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не вдалося зберегти налаштування.')),
        );
      }
    }
  }

  Future<void> _showRemoveAds() async {
    final enable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Версія без мінібанера'),
        content: const Text(
          'У фінальній версії банер зникатиме після підписки або окремої покупки. Зараз можна безкоштовно перевірити тестовий режим без банера.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Пізніше'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.workspace_premium_outlined),
            label: const Text('Спробувати без банера'),
          ),
        ],
      ),
    );
    if (enable == true) await _setAdsRemoved(true);
  }
}

class _MiniPartnerBanner extends StatelessWidget {
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onRemoveAds;

  const _MiniPartnerBanner({
    required this.onOpen,
    required this.onClose,
    required this.onRemoveAds,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: const Color(0xFFFFF4DA),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          key: const Key('mini-partner-banner'),
          borderRadius: BorderRadius.circular(16),
          onTap: onOpen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD98A)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Прибрати рекламу',
                  onPressed: onRemoveAds,
                  icon: const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF9A6700),
                  ),
                ),
                const SizedBox(width: 2),
                const Expanded(
                  child: Text(
                    'Реклама • добрива',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Закрити на цей сеанс',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
