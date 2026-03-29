import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

const _kGreen = Color(0xFF22C55E);
const _kInactive = Color(0xFF2B3D2F);

class BottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with TickerProviderStateMixin {
  late final AnimationController _pillController;
  late Animation<double> _pillPosition;

  late final List<AnimationController> _bounceControllers;
  late final List<Animation<double>> _bounceAnims;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;

  static const _items = [
    _NavItem(
        icon: Icons.home_rounded,
        outlineIcon: Icons.home_outlined,
        label: 'Home'),
    _NavItem(
        icon: Icons.vpn_key_rounded,
        outlineIcon: Icons.vpn_key_outlined,
        label: 'Cash2Keys'),
    _NavItem(
        icon: Icons.person_rounded,
        outlineIcon: Icons.person_outline_rounded,
        label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();

    _pillController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _pillPosition = Tween<double>(
      begin: widget.currentIndex.toDouble(),
      end: widget.currentIndex.toDouble(),
    ).animate(
        CurvedAnimation(parent: _pillController, curve: Curves.easeOutExpo));

    _bounceControllers = List.generate(
        _items.length,
        (_) => AnimationController(
            vsync: this, duration: const Duration(milliseconds: 380)));
    _bounceAnims = _bounceControllers
        .map((c) => TweenSequence<double>([
              TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.22), weight: 28),
              TweenSequenceItem(
                  tween: Tween(begin: 1.22, end: 0.92), weight: 28),
              TweenSequenceItem(
                  tween: Tween(begin: 0.92, end: 1.04), weight: 22),
              TweenSequenceItem(
                  tween: Tween(begin: 1.04, end: 1.0), weight: 22),
            ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    _glowController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glowController, curve: Curves.easeInOut);

    _bounceControllers[widget.currentIndex].forward();
  }

  @override
  void didUpdateWidget(BottomNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _pillPosition = Tween<double>(
        begin: old.currentIndex.toDouble(),
        end: widget.currentIndex.toDouble(),
      ).animate(
          CurvedAnimation(parent: _pillController, curve: Curves.easeOutExpo));
      _pillController.forward(from: 0);
      _bounceControllers[widget.currentIndex].forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    for (final c in _bounceControllers) c.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = screenWidth / _items.length;

    return AnimatedBuilder(
      animation: Listenable.merge([_pillPosition, _glowAnim]),
      builder: (context, _) {
        final pillLeft = _pillPosition.value * itemWidth;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              decoration: BoxDecoration(
                // Transparent — lets the page content show through the blur
                color: AppColors.background.withOpacity(0.40),
                border: Border(
                  top: BorderSide(
                    color: _kGreen.withOpacity(0.12),
                    width: 0.8,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Stack(
                    children: [
                      // Sliding top indicator line
                      Positioned(
                        top: 0,
                        left: pillLeft + itemWidth * 0.28,
                        child: Container(
                          width: itemWidth * 0.44,
                          height: 2.5,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(2)),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _kGreen
                                    .withOpacity(0.75 + 0.2 * _glowAnim.value),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _kGreen
                                    .withOpacity(0.45 + 0.2 * _glowAnim.value),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Subtle pill highlight behind active item
                      Positioned(
                        top: 8,
                        left: pillLeft + itemWidth * 0.15,
                        child: Container(
                          width: itemWidth * 0.70,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                _kGreen.withOpacity(0.12),
                                _kGreen.withOpacity(0.03),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Nav items
                      Row(
                        children: List.generate(
                          _items.length,
                          (i) => Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (i != widget.currentIndex) widget.onTap(i);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: ScaleTransition(
                                scale: _bounceAnims[i],
                                child: _NavTile(
                                  item: _items[i],
                                  isSelected: widget.currentIndex == i,
                                  glowValue: _glowAnim.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final double glowValue;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.glowValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _kGreen.withOpacity(0.25 + 0.10 * glowValue),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    isSelected ? item.icon : item.outlineIcon,
                    key: ValueKey(isSelected),
                    color: isSelected ? _kGreen : _kInactive,
                    size: isSelected ? 23 : 21,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: GoogleFonts.dmMono(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected
                  ? _kGreen.withOpacity(0.85)
                  : _kInactive.withOpacity(0.55),
              letterSpacing: isSelected ? 0.6 : 0.1,
            ),
            child: Text(item.label.toUpperCase()),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData outlineIcon;
  final String label;
  const _NavItem(
      {required this.icon, required this.outlineIcon, required this.label});
}
