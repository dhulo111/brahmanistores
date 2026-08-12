import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'બ્રહ્માણી પ્રોવિઝનમાં સ્વાગત છે',
      'subtitle': 'તમારા ઘર માટે જરૂરી તમામ કરિયાણું હવે એક જ જગ્યાએથી મેળવો.',
    },
    {
      'title': 'શ્રેષ્ઠ ગુણવત્તા',
      'subtitle': 'અમે તમને ઉચ્ચ ગુણવત્તાવાળી પ્રોડક્ટ્સ પ્રદાન કરવા માટે પ્રતિબદ્ધ છીએ.',
    },
    {
      'title': 'સરળ ખરીદી',
      'subtitle': 'તમારા ફોન પરથી સરળતાથી ઓર્ડર કરો અને સમય બચાવો.',
    },
    {
      'title': 'ઝડપી ડિલિવરી',
      'subtitle': 'તમારો સામાન સમયસર તમારા ઘરે પહોંચાડીશું.',
    },
  ];

  void _onNext() {
    if (_currentPage == _pages.length - 1) {
      Hive.box('settings').put('hasSeenOnboarding', true);
      context.go('/login');
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Placeholder for Illustration
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.primaryGreen, width: 2),
                          ),
                          child: const Icon(
                            Icons.shopping_basket_rounded,
                            size: 100,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          _pages[index]['title']!,
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[index]['subtitle']!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index 
                              ? AppTheme.primaryGreen 
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: Text(_currentPage == _pages.length - 1 ? 'શરૂ કરો' : 'આગળ'), // Start : Next
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
