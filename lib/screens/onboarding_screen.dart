import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_themes.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

  static const String _prefKey = 'hasSeenOnboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: 'Welcome to RideWealth Assistant',
      description:
          'Your all-in-one tool for managing your rideshare business finances. '
          'Let\'s take a quick look at what you can do.',
      useLogo: true,
    ),
    _OnboardingPage(
      icon: Icons.directions_car,
      title: 'Track Your Mileage',
      description:
          'Log your start and end mileage for every day or trip. '
          'Your records are saved and organized by month for easy reference.',
    ),
    _OnboardingPage(
      icon: Icons.attach_money,
      title: 'Manage Income & Expenses',
      description:
          'Record your earnings and business expenses in one place. '
          'Categorize everything to stay organized come tax time.',
    ),
    _OnboardingPage(
      icon: Icons.calculate,
      title: 'Estimate Your Taxes',
      description:
          'Get estimated tax calculations based on your income, expenses, '
          'and mileage deductions using rates you choose.',
    ),
    _OnboardingPage(
      icon: Icons.download,
      title: 'Export Your Data',
      description:
          'Export your mileage, income, and expense records to CSV anytime. '
          'Perfect for sharing with your tax preparer.',
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _complete() async {
    await OnboardingScreen.setOnboardingComplete();
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppThemes.buildAppBar(context, 'RideWealth Assistant'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (page.useLogo)
                          Image.asset(
                            'RWAlogo.png',
                            width: 120,
                            height: 120,
                          )
                        else
                          Icon(
                            page.icon,
                            size: 80,
                            color: isDark
                                ? AppThemes.accentColor
                                : AppThemes.primaryColor,
                          ),
                        const SizedBox(height: 32),
                        Text(
                          page.title,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? (isDark
                              ? AppThemes.accentColor
                              : AppThemes.primaryColor)
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            // Buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _complete,
                    child: const Text('Skip'),
                  ),
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                    ),
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

class _OnboardingPage {
  final IconData? icon;
  final String title;
  final String description;
  final bool useLogo;

  const _OnboardingPage({
    this.icon,
    required this.title,
    required this.description,
    this.useLogo = false,
  });
}
