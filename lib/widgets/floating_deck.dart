import 'package:flutter/material.dart';
import '../core/app_colors.dart';

typedef OnTabSelected = void Function(int index);

class FloatingDeck extends StatefulWidget {
  final int currentIndex;
  final OnTabSelected onTabSelected;

  const FloatingDeck({super.key, required this.currentIndex, required this.onTabSelected});

  @override
  State<FloatingDeck> createState() => _FloatingDeckState();
}

class _FloatingDeckState extends State<FloatingDeck> {
  int? _pressedIndex;

  @override
  Widget build(BuildContext context) {
    // Scale factor (15% smaller)
    final double scale = 0.85;
  final screenWidth = MediaQuery.of(context).size.width;
  final maxWidth = screenWidth * 0.8; // Crunch in by 10% each side
    // Use a cohesive set of rounded/aesthetic icons
    final items = [
      Icons.home_filled, // Home
      Icons.forum_rounded, // Chats
      Icons.play_circle_filled, // RizzScroll (moved to 3rd position)
      Icons.business_center_rounded, // Jobs (moved to 4th position)
      Icons.person_search_rounded, // Search/View Profiles (5th position)
      Icons.account_circle_rounded, // Profile
    ];

    return Positioned(
      left: screenWidth * 0.15,
      right: screenWidth * 0.15,
      bottom: 20,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10 * scale, horizontal: 8 * scale),
              decoration: BoxDecoration(
                color: AppColors.deckBackground.withOpacity(0.85),
                borderRadius: BorderRadius.circular(38 * scale),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20 * scale,
                    offset: Offset(0, 10 * scale),
                  ),
                ],
              ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(items.length, (i) {
                final active = i == widget.currentIndex;
                final isPressed = _pressedIndex == i;

                if (active) {
                    final activeChild = Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0 * scale),
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTapDown: (_) => setState(() => _pressedIndex = i),
                        onTapUp: (_) {
                          setState(() => _pressedIndex = null);
                          widget.onTabSelected(i);
                        },
                        onTapCancel: () => setState(() => _pressedIndex = null),
                        child: Container(
                          width: 80 * scale, // Larger touch area
                          height: 40 * scale, // Keep deck height unchanged
                          alignment: Alignment.center,
                          child: AnimatedScale(
                            scale: isPressed ? 0.94 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOut,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              width: 60 * scale * 1.85,
                              height: 60 * scale * 1.85 ,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.neonRed, // Solid dopamine red
                                boxShadow: [
                                  BoxShadow(color: AppColors.neonRed.withOpacity(0.36), blurRadius: 14 * scale, spreadRadius: 0.5 * scale),
                                  BoxShadow(color: Colors.black.withOpacity(0.24), blurRadius: 8 * scale, offset: Offset(0, 6 * scale)),
                                ],
                              ),
                              child: Center(
                                child: Icon(items[i], color: Colors.white, size: 26 * scale * 1.05),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );

                  return Flexible(fit: FlexFit.tight, child: Center(child: activeChild));
                }

                final inactiveChild = Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapDown: (_) => setState(() => _pressedIndex = i),
                    onTapUp: (_) {
                      setState(() => _pressedIndex = null);
                      widget.onTabSelected(i);
                    },
                    onTapCancel: () => setState(() => _pressedIndex = null),
                    child: Container(
                      width: 80 * scale, // Larger touch area
                      height: 60 * scale, // Keep deck height unchanged
                      alignment: Alignment.center, // Center icon vertically and horizontally
                      child: AnimatedScale(
                        scale: isPressed ? 0.94 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        child: Container(
                          width: 44 * scale,
                          height: 44 * scale,
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(items[i], color: Colors.white70, size: 18 * scale * 1.05 * 1.10),
                        ),
                      ),
                    ),
                  ),
                );

                return Flexible(fit: FlexFit.tight, child: Center(child: inactiveChild));
              }),
            ),
          ),
        ),
      ),
    );
  }
}
