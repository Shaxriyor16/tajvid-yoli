import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class Breakpoints {
  Breakpoints._();
  static const double tablet = 700;
  static const double desktop = 1100;
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

const List<NavDestinationItem> kNavDestinations = [
  NavDestinationItem(
    icon: CupertinoIcons.house,
    selectedIcon: CupertinoIcons.house_fill,
    labelKey: 'home',
    path: '/home',
  ),
  NavDestinationItem(
    icon: CupertinoIcons.book,
    selectedIcon: CupertinoIcons.book_fill,
    labelKey: 'quran',
    path: '/quran',
  ),
  NavDestinationItem(
    icon: CupertinoIcons.mic,
    selectedIcon: CupertinoIcons.mic_fill,
    labelKey: 'check',
    path: '/ai-check',
  ),
  NavDestinationItem(
    icon: CupertinoIcons.person,
    selectedIcon: CupertinoIcons.person_fill,
    labelKey: 'profile',
    path: '/profile',
  ),
];

class NavDestinationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String labelKey;
  final String path;
  const NavDestinationItem({
    required this.icon,
    required this.selectedIcon,
    required this.labelKey,
    required this.path,
  });
}

class AdaptiveShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdaptiveShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    final palette = AppPalette.of(context);
    final currentIndex = navigationShell.currentIndex;
    // Tab almashganda sahifa yumshoq paydo bo'ladi; tablar xotirada qoladi.
    final content = Material(
      type: MaterialType.transparency,
      child: _TabFade(index: currentIndex, child: navigationShell),
    );

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: AppColors.adaptiveBackground(context),
        child: isMobile
            ? Stack(
                children: [
                  Positioned.fill(child: content),
                  _FloatingGlassNavBar(
                    currentIndex: currentIndex,
                    onSelect: (i) => _goBranch(i),
                  ),
                ],
              )
            : Row(
                children: [
                  _DesktopRail(
                      currentIndex: currentIndex,
                      onSelect: (i) => _goBranch(i)),
                  VerticalDivider(
                      width: 1, thickness: 1, color: palette.divider),
                  Expanded(child: content),
                ],
              ),
      ),
    );
  }

  void _goBranch(int i) => navigationShell.goBranch(
        i,
        initialLocation: i == navigationShell.currentIndex,
      );
}

/// Tab almashganda mazmunni 220 ms davomida yengil paydo qiladi.
class _TabFade extends StatefulWidget {
  final int index;
  final Widget child;
  const _TabFade({required this.index, required this.child});

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220), value: 1);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0.55);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _fade, child: widget.child);
}

class _FloatingGlassNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _FloatingGlassNavBar(
      {required this.currentIndex, required this.onSelect});

  @override
  State<_FloatingGlassNavBar> createState() => _FloatingGlassNavBarState();
}

class _FloatingGlassNavBarState extends State<_FloatingGlassNavBar> {
  double _dragX = 0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _dragX = widget.currentIndex.toDouble();
  }

  @override
  void didUpdateWidget(_FloatingGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _dragX = widget.currentIndex.toDouble();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final width = MediaQuery.of(context).size.width - 32; // Container width
    final itemWidth = width / kNavDestinations.length;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dx = rtl ? -details.delta.dx : details.delta.dx;

    setState(() {
      _isDragging = true;
      _dragX =
          (_dragX + dx / itemWidth).clamp(0.0, kNavDestinations.length - 1.0);
    });

    final targetIndex = _dragX.round();
    if (targetIndex != widget.currentIndex) {
      HapticFeedback.selectionClick();
      widget.onSelect(targetIndex);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragX = widget.currentIndex.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                height: 72,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: palette.navFill,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: palette.navBorder,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: _isDragging
                          ? Duration.zero
                          : const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      alignment: AlignmentDirectional(
                        -1.0 + (_dragX * (2.0 / (kNavDestinations.length - 1))),
                        0,
                      ),
                      child: GestureDetector(
                        onHorizontalDragUpdate: _onHorizontalDragUpdate,
                        onHorizontalDragEnd: _onHorizontalDragEnd,
                        child: FractionallySizedBox(
                          widthFactor: 1 / kNavDestinations.length,
                          child: Container(
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.gold2.withValues(alpha: 0.25),
                                  AppColors.gold2.withValues(alpha: 0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.gold2.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.gold2.withValues(alpha: 0.15),
                                  blurRadius: 15,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(kNavDestinations.length, (i) {
                        return Expanded(
                          child: _NavButton(
                            item: kNavDestinations[i],
                            selected: i == widget.currentIndex,
                            onTap: () => widget.onSelect(i),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final NavDestinationItem item;
  final bool selected;
  final VoidCallback onTap;
  const _NavButton(
      {required this.item, required this.selected, required this.onTap});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  double _scale = 1.0;

  void _onTapDown(_) {
    setState(() => _scale = 0.88);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final itemColor =
        widget.selected ? palette.accentGold : palette.navUnselected;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _scale,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: itemColor),
              duration: const Duration(milliseconds: 250),
              builder: (context, color, _) => Icon(
                widget.selected ? widget.item.selectedIcon : widget.item.icon,
                size: 26,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: 10,
                color: itemColor,
                fontWeight: widget.selected ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.2,
              ),
              child: Text(l10n.get(widget.item.labelKey)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesktopRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  const _DesktopRail({required this.currentIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Image.asset('assets/logo.png', width: 48, height: 48),
          const SizedBox(height: 32),
          ...List.generate(kNavDestinations.length, (i) {
            final item = kNavDestinations[i];
            final selected = i == currentIndex;
            return ListTile(
              leading: Icon(selected ? item.selectedIcon : item.icon,
                  color: selected ? palette.accentGold : palette.textMid),
              title: Text(l10n.get(item.labelKey),
                  style: TextStyle(
                      color: selected ? palette.textHi : palette.textMid,
                      fontSize: 14)),
              onTap: () => onSelect(i),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              selected: selected,
              selectedTileColor: palette.fieldFill,
            );
          }),
        ],
      ),
    );
  }
}
