import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/notifications/devotional_reminder_service.dart';
import '../../../services/preferences/preferences_service.dart';

class SmartNotificationSheet extends StatelessWidget {
  const SmartNotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SmartNotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<DevotionalReminderService>();
    final prefs = context.watch<PreferencesService>();
    final lang = prefs.getSelectedLanguage();
    final upcomingList = reminders.getUpcomingSmartNotifications(lang);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: const BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.saffronPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: AppColors.maroonPrimary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Devotional Notifications',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
                    ),
                    Text(
                      'Spaced non-intrusive reminders with dynamic sacred content',
                      style: TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notification Cards & Settings
          Expanded(
            child: ListView(
              children: [
                // 1. Brahma Muhurta & Morning Suprabhatam
                _buildReminderCard(
                  context,
                  title: '🌅 Brahma Muhurta & Suprabhatam',
                  subtitle: 'Daily morning awakening (Calculated: ${reminders.getCalculatedBrahmaMuhurtaTime()})',
                  icon: Icons.wb_sunny_rounded,
                  iconColor: AppColors.saffronPrimary,
                  enabled: reminders.morningEnabled,
                  onToggle: (val) async {
                    await reminders.requestNotificationPermissions();
                    await reminders.toggleMorning(val);
                  },
                ),
                const SizedBox(height: 9),

                // 2. Mid-Day Sacred Wisdom & Vachana
                _buildReminderCard(
                  context,
                  title: '🌸 Mid-Day Sacred Wisdom & Shloka',
                  subtitle: 'Basavanna, Dasa Sahitya & Gita verse with meaning at 01:00 PM',
                  icon: Icons.auto_stories_rounded,
                  iconColor: AppColors.goldDark,
                  enabled: reminders.midDayWisdomEnabled,
                  onToggle: (val) async {
                    await reminders.requestNotificationPermissions();
                    await reminders.toggleMidDayWisdom(val);
                  },
                ),
                const SizedBox(height: 9),

                // 3. Evening Sandhya Deepam
                _buildReminderCard(
                  context,
                  title: '🪔 Evening Sandhya Aarti & Deepam',
                  subtitle: 'Sunset diya lighting & Lalitha Sahasranamam (${reminders.eveningTime})',
                  icon: Icons.wb_twilight_rounded,
                  iconColor: AppColors.maroonPrimary,
                  enabled: reminders.eveningEnabled,
                  onToggle: (val) async {
                    await reminders.requestNotificationPermissions();
                    await reminders.toggleEvening(val);
                  },
                ),
                const SizedBox(height: 9),

                // 4. Night Shantih & Nidra Prayer
                _buildReminderCard(
                  context,
                  title: '🌙 Night Shantih & Peace Prayer',
                  subtitle: 'Peaceful bedtime shloka and sleep prayer at 09:45 PM',
                  icon: Icons.bedtime_rounded,
                  iconColor: const Color(0xFF4A148C),
                  enabled: reminders.nightNidraEnabled,
                  onToggle: (val) async {
                    await reminders.requestNotificationPermissions();
                    await reminders.toggleNightNidra(val);
                  },
                ),
                const SizedBox(height: 9),

                // 5. Festival & Vrata Alerts
                _buildReminderCard(
                  context,
                  title: '✨ Ekadashi & Festival Alerts',
                  subtitle: 'Auspicious Tithis, Sankashti & festival morning notices (08:00 AM)',
                  icon: Icons.campaign_rounded,
                  iconColor: const Color(0xFFC04000),
                  enabled: reminders.festivalAlerts,
                  onToggle: (val) async {
                    await reminders.requestNotificationPermissions();
                    await reminders.toggleFestivalAlerts(val);
                  },
                ),
                const SizedBox(height: 18),

                // Upcoming Preview Section
                const Text(
                  'Today\'s Scheduled Dynamic Notification Preview',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.maroonPrimary),
                ),
                const SizedBox(height: 8),

                ...upcomingList.map((notif) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x22C8A050)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notif.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      notif.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    notif.time,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      color: AppColors.maroonPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notif.body,
                                style: const TextStyle(fontSize: 11, color: Colors.black87, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x18000000)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: iconColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        value: enabled,
        activeColor: AppColors.maroonPrimary,
        onChanged: onToggle,
      ),
    );
  }
}
