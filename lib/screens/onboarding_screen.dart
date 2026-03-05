import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// 6-step first-launch onboarding flow.
/// On completion, calls [AppProvider.completeOnboarding()] and
/// replaces itself with the main nav shell.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 6;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish(BuildContext context) {
    context.read<AppProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_totalPages, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? AppColors.gold
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(onNext: _next),
                  _LocationPage(onNext: _next),
                  _CalcMethodPage(onNext: _next),
                  _MadhabPage(onNext: _next),
                  _NotificationsPage(onNext: _next),
                  _DonePage(onFinish: () => _finish(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Welcome ──────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mosque, color: AppColors.gold, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Ramadan Times',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Accurate prayer times, Sehri & Iftar\ncountdowns, and Qibla direction.\nOffline. Private. Respectful.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          _PrimaryButton(label: 'Get Started', onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Step 2: Location ─────────────────────────────────────────────────────────

class _LocationPage extends StatefulWidget {
  final VoidCallback onNext;
  const _LocationPage({required this.onNext});

  @override
  State<_LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<_LocationPage> {
  void _requestLocation(BuildContext context) {
    // Fire-and-forget: permission dialog surfaces immediately, GPS fix + geocoding
    // resolve in the background while the onboarding flow continues.
    // The home screen shimmer covers the loading state.
    context.read<AppProvider>().initialize();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return _PageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on_outlined, color: AppColors.gold, size: 64),
          const SizedBox(height: 24),
          const Text(
            'Your Location',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prayer times are calculated using your GPS coordinates. Your location never leaves your device.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
            label: 'Allow Location',
            onPressed: () => _requestLocation(context),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onNext,
            child: const Text(
              "Skip — I'll set it manually later",
              style: TextStyle(color: AppColors.textDim, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Calculation Method ───────────────────────────────────────────────

class _CalcMethodPage extends StatelessWidget {
  final VoidCallback onNext;
  const _CalcMethodPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return _PageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.calculate_outlined, color: AppColors.gold, size: 56),
          const SizedBox(height: 20),
          const Text(
            'Calculation Method',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Different schools use different angles\nfor Fajr and Isha calculation.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: provider.calcMethod,
                isExpanded: true,
                dropdownColor: AppColors.primaryMid,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14),
                items: AppConstants.calcMethodNames
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m,
                              style: const TextStyle(
                                  color: AppColors.textPrimary)),
                        ))
                    .toList(),
                onChanged: (v) => provider.setCalcMethod(v!),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _PrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

// ── Step 4: Madhab ───────────────────────────────────────────────────────────

class _MadhabPage extends StatelessWidget {
  final VoidCallback onNext;
  const _MadhabPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return _PageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_outlined, color: AppColors.gold, size: 56),
          const SizedBox(height: 20),
          const Text(
            'Madhab',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your school of jurisprudence affects\nthe Asr prayer time calculation.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 28),
          _MadhabOption(
            title: "Shafi'i / Hanbali / Maliki",
            subtitle: 'Shadow = 1× object height (default)',
            selected: provider.madhab != 'Hanafi',
            onTap: () => provider.setMadhab("Shafi'i"),
          ),
          const SizedBox(height: 10),
          _MadhabOption(
            title: 'Hanafi',
            subtitle: 'Shadow = 2× object height',
            selected: provider.madhab == 'Hanafi',
            onTap: () => provider.setMadhab('Hanafi'),
          ),
          const SizedBox(height: 32),
          _PrimaryButton(label: 'Continue', onPressed: onNext),
        ],
      ),
    );
  }
}

class _MadhabOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _MadhabOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.1)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.primaryLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.gold : AppColors.textDim,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: selected
                            ? AppColors.gold
                            : AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 5: Notifications ────────────────────────────────────────────────────

class _NotificationsPage extends StatelessWidget {
  final VoidCallback onNext;
  const _NotificationsPage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return _PageShell(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.notifications_outlined,
                color: AppColors.gold, size: 56),
            const SizedBox(height: 20),
            const Text(
              'Notifications',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get reminded before Sehri ends and\nalerted at Iftar time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Master toggle
            _ToggleRow(
              label: 'Enable Notifications',
              value: provider.notifEnabled,
              onChanged: provider.setNotifEnabled,
            ),

            if (provider.notifEnabled) ...[
              const SizedBox(height: 16),
              // Sehri reminder options
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Sehri Reminder',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.sehriReminderOptions.map((min) {
                  final selected = provider.sehriReminderMin == min;
                  return ChoiceChip(
                    label: Text('$min min'),
                    selected: selected,
                    onSelected: (_) => provider.setSehriReminderMin(min),
                    backgroundColor: AppColors.cardBg,
                    selectedColor: AppColors.gold.withValues(alpha: 0.2),
                    labelStyle: TextStyle(
                        color: selected ? AppColors.gold : AppColors.textSecondary,
                        fontSize: 12),
                    side: BorderSide(
                        color: selected ? AppColors.gold : AppColors.primaryLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              _ToggleRow(
                label: 'Iftar Alert (at Maghrib)',
                value: provider.iftarAlert,
                onChanged: provider.setIftarAlert,
              ),
            ],

            const SizedBox(height: 32),
            _PrimaryButton(label: 'Continue', onPressed: onNext),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ── Step 6: Done ─────────────────────────────────────────────────────────────

class _DonePage extends StatelessWidget {
  final VoidCallback onFinish;
  const _DonePage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return _PageShell(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.qiblaGreen, size: 72),
          const SizedBox(height: 20),
          const Text(
            "You're all set!",
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Location: ${provider.city}\nMethod: ${provider.calcMethod}\nMadhab: ${provider.madhab}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.7),
          ),
          const SizedBox(height: 40),
          _PrimaryButton(
              label: 'Go to Prayer Times', onPressed: onFinish),
        ],
      ),
    );
  }
}

// ── Shared layout helpers ─────────────────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final Widget child;
  const _PageShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: child,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _PrimaryButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}
