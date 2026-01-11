import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _selectedInterests = [];

  final List<Map<String, String>> _pages = [
    {
      'title': 'Находите компанию',
      'description':
          'Ищите людей с похожими интересами для совместного досуга',
      'icon': 'people',
    },
    {
      'title': 'Выбирайте место',
      'description':
          'Автоматический подбор мест на основе ваших предпочтений и локации',
      'icon': 'place',
    },
    {
      'title': 'Общайтесь',
      'description':
          'Обсуждайте детали встречи в удобном чате с участниками',
      'icon': 'chat',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToLogin() {
    // TODO: Navigate to login
    // Navigator.pushReplacementNamed(context, AppRoutes.login);
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
                itemCount: _pages.length + 1,
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildOnboardingPage(_pages[index]);
                  } else {
                    return _buildInterestsPage();
                  }
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> page) {
    IconData icon;
    switch (page['icon']) {
      case 'people':
        icon = Icons.people;
        break;
      case 'place':
        icon = Icons.place;
        break;
      case 'chat':
        icon = Icons.chat_bubble;
        break;
      default:
        icon = Icons.info;
    }

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 120,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 48),
          Text(
            page['title']!,
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page['description']!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Выберите интересы',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Это поможет найти подходящие встречи',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.meetingCategories.map((category) {
                  final isSelected = _selectedInterests.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedInterests.add(category);
                        } else {
                          _selectedInterests.remove(category);
                        }
                      });
                    },
                    backgroundColor: AppTheme.backgroundColor,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textPrimaryColor,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Индикаторы страниц
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length + 1,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Кнопки
          Row(
            children: [
              if (_currentPage > 0)
                TextButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Назад'),
                ),
              const Spacer(),
              if (_currentPage < _pages.length)
                TextButton(
                  onPressed: _goToLogin,
                  child: const Text('Пропустить'),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _currentPage == _pages.length
                    ? (_selectedInterests.isNotEmpty ? _goToLogin : null)
                    : _nextPage,
                child: Text(
                  _currentPage == _pages.length ? 'Начать' : 'Далее',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
