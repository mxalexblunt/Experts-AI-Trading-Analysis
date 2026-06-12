import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../chat/screens/stock_chat_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../watchlist/screens/watchlist_screen.dart';
import 'home_screen.dart';

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  int _index = 0;
  int _previousIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenSettings: _openSettings),
      WatchlistScreen(onOpenSettings: _openSettings),
      const StockChatScreen(),
      const SettingsScreen(),
    ];
    final tabRoots = [
      for (var i = 0; i < screens.length; i++)
        HeroMode(
          enabled: i == _index,
          child: screens[i],
        ),
    ];
    final orderedTabIndexes = [
      for (var i = 0; i < tabRoots.length; i++)
        if (i != _index) i,
      _index,
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: ClipRect(
              child: Stack(
                children: [
                  for (final tabIndex in orderedTabIndexes)
                    _AnimatedTabPage(
                      selected: tabIndex == _index,
                      offset: _tabOffset(tabIndex),
                      child: tabRoots[tabIndex],
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 92,
            child: const _BottomBarBlur(),
          ),
          Positioned(
            left: AppSpacing.tiny,
            right: AppSpacing.tiny,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppSpacing.small),
              child: _FloatingTabBar(
                index: _index,
                onChanged: _setIndex,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    _setIndex(3);
  }

  void _setIndex(int value) {
    if (value == _index) return;
    setState(() {
      _previousIndex = _index;
      _index = value;
    });
  }

  Offset _tabOffset(int tabIndex) {
    if (tabIndex == _index) return Offset.zero;
    final direction = _index >= _previousIndex ? -1.0 : 1.0;
    if (tabIndex == _previousIndex) return Offset(0.035 * direction, 0);
    return Offset(tabIndex < _index ? -0.035 : 0.035, 0);
  }
}

class _AnimatedTabPage extends StatelessWidget {
  const _AnimatedTabPage({
    required this.selected,
    required this.offset,
    required this.child,
  });

  final bool selected;
  final Offset offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !selected,
        child: ExcludeSemantics(
          excluding: !selected,
          child: TickerMode(
            enabled: selected,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: selected ? Offset.zero : offset,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBarBlur extends StatelessWidget {
  const _BottomBarBlur();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.canvas.withValues(alpha: 0.72),
              border: Border(
                top: BorderSide(
                  color: AppColors.canvasPure.withValues(alpha: 0.64),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({
    required this.index,
    required this.onChanged,
  });

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    _TabItem(icon: CupertinoIcons.house_fill, label: 'Home'),
    _TabItem(icon: CupertinoIcons.briefcase, label: 'Watchlist'),
    _TabItem(icon: CupertinoIcons.chat_bubble_2_fill, label: 'AI Chat'),
    _TabItem(icon: CupertinoIcons.gear_alt, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(42),
        border: Border.all(
          color: AppColors.canvasPure.withValues(alpha: 0.88),
        ),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              child: _TabButton(
                item: _items[i],
                selected: i == index,
                onPressed: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final _TabItem item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      pressedOpacity: 0.82,
      onPressed: onPressed,
      child: AnimatedContainer(
        key: ValueKey('tab_${item.label.toLowerCase()}'),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Center(
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            scale: selected ? 1.06 : 0.94,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : CupertinoColors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                boxShadow: selected ? AppShadows.subtle : null,
              ),
              child: Icon(
                item.icon,
                size: selected ? 25 : 26,
                color: selected ? AppColors.ink : AppColors.textSecondary,
                semanticLabel: item.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class TabPlaceholderScreen extends StatelessWidget {
  const TabPlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppColors.canvas,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            middle: Text(title, style: AppTypography.headline),
            alwaysShowMiddle: false,
            backgroundColor: AppColors.canvas.withValues(alpha: 0.94),
            border: null,
            heroTag: 'placeholder_${title}_sliver_navigation_bar',
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(title, style: AppTypography.title2)),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
