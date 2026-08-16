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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).user;
      final bool isAdmin = user?.role == 'ADMIN';
      _currentHoverIndex = getUiIndex(widget.navigationShell.currentIndex, isAdmin);
      _showTagFor(_currentHoverIndex);
    });
  }

  @override
  void didUpdateWidget(covariant MainLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex != widget.navigationShell.currentIndex) {
      if (!_isDragging) {
         final user = ref.read(authProvider).user;
         final bool isAdmin = user?.role == 'ADMIN';
         _showTagFor(getUiIndex(widget.navigationShell.currentIndex, isAdmin));
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
    _tagTimer = Timer(const Duration(milliseconds: 2000), () {
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
    if (isAdmin) {
      // Admin: 0 -> Home(0), 1 -> Products(1), 2 -> All Transactions(5), 3 -> Users(2), 4 -> Profile(4)
      if (uiIndex == 0) return 0;
      if (uiIndex == 1) return 1;
      if (uiIndex == 2) return 5;
      if (uiIndex == 3) return 2;
      if (uiIndex == 4) return 4;
      return 0;
    } else {
      // User: 0 -> Home(0), 1 -> Products(1), 2 -> My Ledger(3), 3 -> Profile(4)
      if (uiIndex == 0) return 0;
      if (uiIndex == 1) return 1;
      if (uiIndex == 2) return 3;
      if (uiIndex == 3) return 4;
      return 0;
    }
  }

  int getUiIndex(int branchIndex, bool isAdmin) {
    if (isAdmin) {
      if (branchIndex == 0) return 0;
      if (branchIndex == 1) return 1;
      if (branchIndex == 5) return 2;
      if (branchIndex == 2) return 3;
      if (branchIndex == 4) return 4;
      return 0;
    } else {
      if (branchIndex == 0) return 0;
      if (branchIndex == 1) return 1;
      if (branchIndex == 3) return 2;
      if (branchIndex == 4) return 3;
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = widget.navigationShell.currentIndex;
    final user = ref.watch(authProvider).user;
    final bool isAdmin = user?.role == 'ADMIN';
    final int tabCount = isAdmin ? 5 : 4;
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
                  final double indicatorSize = tabCount == 5 ? 38.0 : 42.0; // Smaller sizes for 60px height
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
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            height: 60, // Reduced height
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3), // Darker glass base
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                )
                              ]
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
                                    curve: _isDragging ? Curves.linear : Curves.easeOutBack,
                                    left: currentCenter - ((indicatorSize + (tabCount == 5 ? 16 : 24)) / 2),
                                    top: (57 - indicatorSize) / 2, // 57 is 60 (height) - 3 (borders)
                                    child: Container(
                                      width: indicatorSize + (tabCount == 5 ? 16 : 24),
                                      height: indicatorSize,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: AppTheme.primaryGreen.withOpacity(0.4),
                                          width: 1,
                                        ),
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
                                          tabCount: tabCount,
                                        ),
                                        _buildNavItem(
                                          icon: Icons.shopping_bag_rounded,
                                          isSelected: uiIndex == 1,
                                          tabCount: tabCount,
                                        ),
                                        if (isAdmin) ...[
                                          _buildNavItem(
                                            icon: Icons.receipt_long_rounded,
                                            isSelected: uiIndex == 2,
                                            tabCount: tabCount,
                                          ),
                                          _buildNavItem(
                                            icon: Icons.people_alt_rounded,
                                            isSelected: uiIndex == 3,
                                            tabCount: tabCount,
                                          )
                                        ] else ...[
                                          _buildNavItem(
                                            icon: Icons.menu_book_rounded,
                                            isSelected: uiIndex == 2,
                                            tabCount: tabCount,
                                          ),
                                        ],
                                        _buildNavItem(
                                          icon: Icons.person_rounded,
                                          isSelected: uiIndex == (isAdmin ? 4 : 3),
                                          avatarUrl: user?.avatarUrl,
                                          tabCount: tabCount,
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
                      _buildFloatingTag('હોમ', 0, tabWidth, tabCount),
                      _buildFloatingTag('પ્રોડક્ટ્સ', 1, tabWidth, tabCount),
                      if (isAdmin) ...[
                        _buildFloatingTag('એન્ટ્રીઓ', 2, tabWidth, tabCount),
                        _buildFloatingTag('યુઝર્સ', 3, tabWidth, tabCount),
                      ] else ...[
                        _buildFloatingTag('ખાતું', 2, tabWidth, tabCount),
                      ],
                      _buildFloatingTag('પ્રોફાઇલ', isAdmin ? 4 : 3, tabWidth, tabCount),
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

  Widget _buildFloatingTag(String label, int index, double tabWidth, int tabCount) {
    bool isHovered = (index == _currentHoverIndex) && _isTagVisible;
    return Positioned(
      left: index * tabWidth,
      width: tabWidth,
      top: -46, // Space for the label above the bar
      bottom: 0, // Cover the entire height down to the pill
      child: IgnorePointer(
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack, // Gives a nice bounce effect
          alignment: isHovered ? Alignment.topCenter : const Alignment(0, 0.5), // Slides up to topCenter when active
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isHovered ? 1.0 : 0.0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: tabCount == 5 ? 10 : 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: tabCount == 5 ? 11 : 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    required int tabCount,
  }) {
    final double avatarSize = isSelected ? (tabCount == 5 ? 30 : 34) : (tabCount == 5 ? 24 : 28);
    final double iconSize = isSelected ? (tabCount == 5 ? 26 : 28) : (tabCount == 5 ? 22 : 24);

    return Expanded(
      child: Center(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: avatarSize,
                height: avatarSize,
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
                  size: iconSize,
                ),
              ),
      ),
    );
  }
}
