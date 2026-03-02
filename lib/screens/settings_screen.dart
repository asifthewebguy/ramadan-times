import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/location_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('LOCATION'),
          _SettingsTile(
            title: 'Current Location',
            subtitle: provider.city,
            icon: Icons.location_on_outlined,
            onTap: () => _showLocationSheet(context, provider),
          ),

          _SectionHeader('CALCULATION'),
          _DropdownTile<String>(
            title: 'Calculation Method',
            icon: Icons.calculate_outlined,
            value: provider.calcMethod,
            items: AppConstants.calcMethodNames,
            onChanged: (v) => provider.setCalcMethod(v!),
          ),
          _DropdownTile<String>(
            title: 'Madhab (Asr)',
            icon: Icons.menu_book_outlined,
            value: provider.madhab,
            items: const ["Shafi'i", 'Hanafi'],
            onChanged: (v) => provider.setMadhab(v!),
          ),

          _SectionHeader('DISPLAY'),
          _SwitchTile(
            title: '24-Hour Format',
            subtitle: 'Display times in 24-hour format',
            icon: Icons.schedule_outlined,
            value: provider.use24h,
            onChanged: provider.setTimeFormat,
          ),

          _SectionHeader('PRAYER TIMER'),
          _SwitchTile(
            title: 'Enable Prayer Timer',
            subtitle: 'Time your salah and optionally track completions',
            icon: Icons.timer_outlined,
            value: provider.prayerTimerEnabled,
            onChanged: provider.setPrayerTimerEnabled,
          ),
          if (provider.prayerTimerEnabled) ...[
            _SwitchTile(
              title: 'Auto-Start Timer',
              subtitle: 'Start timer automatically when screen opens',
              icon: Icons.play_arrow_outlined,
              value: provider.prayerTimerAutoStart,
              onChanged: provider.setPrayerTimerAutoStart,
            ),
            _SwitchTile(
              title: 'Enable Prayer Logging',
              subtitle: 'Track daily prayer completions',
              icon: Icons.check_circle_outline,
              value: provider.prayerTimerLogging,
              onChanged: provider.setPrayerTimerLogging,
            ),
            _SwitchTile(
              title: 'Haptic Feedback',
              subtitle: 'Vibrate on prayer completion',
              icon: Icons.vibration_outlined,
              value: provider.prayerTimerHaptic,
              onChanged: provider.setPrayerTimerHaptic,
            ),
            _SwitchTile(
              title: 'Show Suggested Durations',
              subtitle: 'Display gentle duration guidance',
              icon: Icons.info_outline,
              value: provider.prayerTimerShowDuration,
              onChanged: provider.setPrayerTimerShowDuration,
            ),
          ],

          _SectionHeader('NOTIFICATIONS'),
          _SwitchTile(
            title: 'Enable Notifications',
            subtitle: 'Sehri, Iftar and prayer alerts',
            icon: Icons.notifications_outlined,
            value: provider.notifEnabled,
            onChanged: provider.setNotifEnabled,
          ),
          if (provider.notifEnabled) ...[
            _DropdownTile<int>(
              title: 'Sehri Reminder',
              icon: Icons.alarm_outlined,
              value: provider.sehriReminderMin,
              items: AppConstants.sehriReminderOptions,
              itemLabel: (v) => '$v min before Fajr',
              onChanged: (v) => provider.setSehriReminderMin(v!),
            ),
            _SwitchTile(
              title: 'Iftar Alert',
              subtitle: 'Notify at Maghrib time',
              icon: Icons.restaurant_outlined,
              value: provider.iftarAlert,
              onChanged: provider.setIftarAlert,
            ),
          ],

          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ramadan Times v1.0.0\nAll prayer calculations are performed locally.\nNo data leaves your device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showLocationSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LocationSheet(provider: provider),
    );
  }
}

class _LocationSheet extends StatefulWidget {
  final AppProvider provider;
  const _LocationSheet({required this.provider});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _controller = TextEditingController();
  List<LocationResult> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searching = true);
    final results = await LocationService().searchCity(query.trim());
    if (mounted) setState(() { _results = results; _searching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Change Location',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search city...',
              hintStyle: const TextStyle(color: AppColors.textDim),
              filled: true,
              fillColor: AppColors.primaryLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textDim),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.gold),
                      ),
                    )
                  : null,
            ),
            onSubmitted: _search,
          ),
          const SizedBox(height: 8),
          // Use GPS option
          ListTile(
            leading: const Icon(Icons.my_location, color: AppColors.gold),
            title: const Text('Use Current GPS Location',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () async {
              Navigator.pop(context);
              await widget.provider.initialize();
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (_results.isNotEmpty) ...[
            const Divider(color: AppColors.primaryLight),
            ..._results.map((r) => ListTile(
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.textSecondary),
                  title: Text(r.city,
                      style: const TextStyle(color: AppColors.textPrimary)),
                  subtitle: Text(
                      '${r.lat.toStringAsFixed(4)}, ${r.lng.toStringAsFixed(4)}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.provider.setLocation(r.lat, r.lng, r.city);
                  },
                  contentPadding: EdgeInsets.zero,
                )),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Reusable setting widgets ──────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(title, style: AppTheme.sectionHeader),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold, size: 22),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold, size: 22),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
          : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final T value;
  final List<T> items;
  final String Function(T)? itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.items,
    this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.gold, size: 22),
      title: Text(title,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15)),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: AppColors.primaryMid,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        items: items.map((item) {
          final label = itemLabel != null ? itemLabel!(item) : item.toString();
          return DropdownMenuItem<T>(
            value: item,
            child: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
