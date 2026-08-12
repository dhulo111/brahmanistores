import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/providers/nav_provider.dart';
import '../../auth/providers/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _isDragging = false;
  double _dragCenterX = 0.0;
  
  int _currentHoverIndex = 0;
  bool _isTagVisible = false;
  Timer? _tagTimer;

  @override
  void initState() {
    super.initState();
    _currentHoverIndex = widget.navigationShell.currentIndex;
    _showTagFor(_currentHoverIndex);
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      if (!_isDragging) {
         _showTagFor(widget.navigationShell.currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _tagTimer?.cancel();
    super.dispose();
  }

  void _showTagFor(int index) {
    if (!mounted) return;
    setState(() {
      _currentHoverIndex = index;
      _isTagVisible = true;
    });
    
    _tagTimer?.cancel();
    _tagTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isTagVisible = false;
        });
      }
    });
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  int getBranchIndex(int uiIndex, bool isAdmin) {
    if (isAdmin) return uiIndex; // 0->0, 1->1, 2->2
    if (uiIndex == 0) return 0;
    if (uiIndex == 1) return 2;
    return 0;
  }

  int getUiIndex(int branchIndex, bool isAdmin) {
    if (isAdmin) return branchIndex;
    if (branchIndex == 0) return 0;
    if (branchIndex == 2) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = widget.navigationShell.currentIndex;
    final user = ref.watch(authProvider).user;
    final bool isAdmin = user?.role == 'ADMIN';
    final int tabCount = isAdmin ? 3 : 2;
    final int uiIndex = getUiIndex(currentIndex, isAdmin);
    
    final bool isNavBarVisible = ref.watch(navBarVisibilityProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 1. The actual page content
          widget.navigationShell,
          
          // 2. The Bottom Navigation Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 32,
            right: 32,
            bottom: isNavBarVisible ? 24 : -100, // Slides out of view
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double availableWidth = constraints.maxWidth - 2; // 2px for left/right borders
                  final double tabWidth = availableWidth / tabCount;
                  final double indicatorSize = 48.0; // Perfect circle size for the water drop
                  final double minCenter = tabWidth / 2;
                  final double maxCenter = ((tabCount - 1) * tabWidth) + (tabWidth / 2);

                  // If not dragging, calculate center based on the current uiIndex
                  final double currentCenter = _isDragging 
                      ? _dragCenterX 
                      : (uiIndex * tabWidth) + (tabWidth / 2);
                      
                  final int calculatedHoverIndex = _isDragging 
                      ? ((_dragCenterX - minCenter) / tabWidth).round().clamp(0, tabCount - 1)
                      : uiIndex;

                  if (_isDragging && calculatedHoverIndex != _currentHoverIndex) {
                     // Defer state update to avoid calling setState during build phase
                     WidgetsBinding.instance.addPostFrameCallback((_) {
                       _showTagFor(calculatedHoverIndex);
                     });
                  }

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. The Pill Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1, // 1px border on all sides
                              ),
                            ),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) {
                                int targetUiIndex = (details.localPosition.dx / tabWidth).floor().clamp(0, tabCount - 1);
                                if (targetUiIndex != uiIndex) {
                                  _onTap(getBranchIndex(targetUiIndex, isAdmin));
                                } else {
                                  _showTagFor(targetUiIndex);
                                }
                              },
                              onHorizontalDragStart: (details) {
                                setState(() {
                                  _isDragging = true;
                                  _dragCenterX = details.localPosition.dx.clamp(minCenter, maxCenter);
                                });
                              },
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  _dragCenterX = details.localPosition.dx.clamp(minCenter, maxCenter);
                                });
                              },
                              onHorizontalDragEnd: (details) {
                                int targetUiIndex = ((_dragCenterX - minCenter) / tabWidth).round().clamp(0, tabCount - 1);
                                setState(() {
                                  _isDragging = false;
                                });
                                
                                if (targetUiIndex != uiIndex) {
                                  _onTap(getBranchIndex(targetUiIndex, isAdmin));
                                } else {
                                  _showTagFor(targetUiIndex);
                                }
                              },
                              child: Stack(
                                children: [
                                  // The Sliding Pill Indicator
                                  AnimatedPositioned(
                                    duration: Duration(milliseconds: _isDragging ? 50 : 400),
                                    curve: _isDragging ? Curves.linear : Curves.easeOutExpo,
                                    left: currentCenter - ((indicatorSize + 32) / 2),
                                    top: (62 - indicatorSize) / 2,
                                    child: Container(
                                      width: indicatorSize + 32, // Wider pill shape
                                      height: indicatorSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(30), // Pill rounded edges
                                      ),
                                    ),
                                  ),
                                  // The Icons
                                  Positioned.fill(
                                    child: Row(
                                      children: [
                                        _buildNavItem(
                                          icon: Icons.home_rounded,
                                          isSelected: uiIndex == 0,
                                        ),
                                        if (isAdmin)
                                          _buildNavItem(
                                            icon: Icons.verified_user_rounded,
                                            isSelected: uiIndex == 1,
                                          ),
                                        _buildNavItem(
                                          icon: Icons.person_rounded,
                                          isSelected: uiIndex == (isAdmin ? 2 : 1),
                                          avatarUrl: user?.avatarUrl,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // 2. Floating Tags
                      _buildFloatingTag('હોમ', 0, tabWidth),
                      if (isAdmin) _buildFloatingTag('મંજૂરી', 1, tabWidth),
                      _buildFloatingTag('પ્રોફાઇલ', isAdmin ? 2 : 1, tabWidth),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingTag(String label, int index, double tabWidth) {
    bool isHovered = (index == _currentHoverIndex) && _isTagVisible;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack, // Gives a nice bounce effect
      left: index * tabWidth,
      width: tabWidth,
      top: isHovered ? -48 : 0, // Slides up from inside the pill when active
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isHovered ? 1.0 : 0.0,
        child: Align(
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.5)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    String? avatarUrl,
  }) {
    return Expanded(
      child: Center(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isSelected ? 34 : 28, // Slightly larger to look perfect inside the 48px drop
                height: isSelected ? 34 : 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: isSelected
                      ? null // Remove border when selected (inside the drop)
                      : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  image: DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Icon(
                  icon,
                  color: isSelected ? AppTheme.primaryGreen : Colors.white.withOpacity(0.4),
                  size: isSelected ? 28 : 24,
                ),
              ),
      ),
    );
  }
}
