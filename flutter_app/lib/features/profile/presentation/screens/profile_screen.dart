import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../application/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(profileSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: settingsAsync.when(
        loading: () => const ListSkeletonLoader(),
        error: (err, st) => ErrorStateView(message: l10n.somethingWentWrong),
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
          ),
          children: [
            _ProfileHeader(settings: settings),
            const SizedBox(height: AppSpacing.xl),
            _SectionCard(
              children: [
                _NavRow(
                  icon: PhosphorIconsRegular.chartBar,
                  label: l10n.profileStatistics,
                  onTap: () => context.push('/profile/statistics'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.profileAppearance),
            _SectionCard(
              children: [
                _ThemeRow(currentThemeMode: settings.themeMode),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.profileLanguage),
            _SectionCard(
              children: [
                _LanguageRow(currentLocaleCode: settings.localeCode),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.profileNotifications),
            _SectionCard(
              children: [
                _NotificationsRow(enabled: settings.notificationsEnabled),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.profileSubjects),
            const _SubjectsSection(),
            const SizedBox(height: AppSpacing.lg),
            SectionHeader(title: l10n.profileAbout),
            _SectionCard(
              children: [
                _InfoRow(
                  icon: PhosphorIconsRegular.sparkle,
                  label: l10n.profileAiStatus,
                  value: AppConfig.hasValidApiKeyConfigured
                      ? l10n.profileAiConfigured
                      : l10n.profileAiNotConfigured,
                  valueColor: AppConfig.hasValidApiKeyConfigured
                      ? AppColors.success
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                _InfoRow(
                  icon: PhosphorIconsRegular.info,
                  label: l10n.profileVersion,
                  value: '1.0.0',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  final UserSettingsTableData settings;
  const _ProfileHeader({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIconsFill.userCircle, size: AppIconSize.xl, color: scheme.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settings.displayName.isEmpty ? l10n.profileDisplayName : settings.displayName,
                  style: textTheme.titleMedium,
                ),
                if (settings.gradeLevel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(settings.gradeLevel, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(PhosphorIconsRegular.pencilSimple),
            tooltip: l10n.profileEditDetails,
            onPressed: () => _showEditDetailsSheet(context, ref, settings),
          ),
        ],
      ),
    );
  }

  void _showEditDetailsSheet(BuildContext context, WidgetRef ref, UserSettingsTableData settings) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: settings.displayName);
    final gradeController = TextEditingController(text: settings.gradeLevel);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
            MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profileEditDetails, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.profileDisplayName),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: gradeController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.profileGradeLevel),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () async {
                  final controller = ref.read(profileControllerProvider);
                  await controller.updateDisplayName(nameController.text.trim());
                  await controller.updateGradeLevel(gradeController.text.trim());
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lgRadius,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: scheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label),
      trailing: Icon(PhosphorIconsRegular.caretRight, size: AppIconSize.sm, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(label),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor ?? scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ThemeRow extends ConsumerWidget {
  final String currentThemeMode;
  const _ThemeRow({required this.currentThemeMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(profileControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(PhosphorIconsRegular.paintBrush, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(l10n.settingsTheme)),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', label: Text(l10n.themeSystem)),
              ButtonSegment(value: 'light', label: Text(l10n.themeLight)),
              ButtonSegment(value: 'dark', label: Text(l10n.themeDark)),
            ],
            selected: {currentThemeMode},
            showSelectedIcon: false,
            onSelectionChanged: (s) => controller.updateThemeMode(s.first),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends ConsumerWidget {
  final String currentLocaleCode;
  const _LanguageRow({required this.currentLocaleCode});

  static const _languages = [
    ('en', 'English'),
    ('ru', 'Русский'),
    ('hy', 'Հայերեն'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(profileControllerProvider);

    return Column(
      children: _languages.map((lang) {
        final (code, label) = lang;
        final selected = code == currentLocaleCode;
        return ListTile(
          leading: Icon(
            selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          ),
          title: Text(label),
          onTap: () => controller.updateLocale(code),
        );
      }).toList(),
    );
  }
}

class _NotificationsRow extends ConsumerWidget {
  final bool enabled;
  const _NotificationsRow({required this.enabled});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(profileControllerProvider);

    return SwitchListTile(
      secondary: Icon(PhosphorIconsRegular.bell, color: scheme.onSurfaceVariant),
      title: Text(l10n.profileNotifications),
      subtitle: Text(l10n.profileNotificationsSubtitle),
      value: enabled,
      onChanged: (v) => controller.setNotificationsEnabled(v),
    );
  }
}

class _SubjectsSection extends ConsumerWidget {
  const _SubjectsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();

    return StreamBuilder<List<Subject>>(
      stream: subjectsAsync,
      builder: (context, snapshot) {
        final subjects = snapshot.data ?? const <Subject>[];
        final customSubjects = subjects.where((s) => s.isCustom).toList();

        return _SectionCard(
          children: [
            ListTile(
              leading: Icon(PhosphorIconsRegular.stack, color: Theme.of(context).colorScheme.onSurfaceVariant),
              title: Text(l10n.profileManageSubjects),
              trailing: Text(
                '${subjects.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              onTap: () => _showManageSheet(context, ref, subjects, localeCode),
            ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.plus),
              title: Text(l10n.profileAddCustomSubject),
              onTap: () => _showAddSubjectDialog(context, ref, customSubjects.length),
            ),
          ],
        );
      },
    );
  }

  void _showManageSheet(BuildContext context, WidgetRef ref, List<Subject> subjects, String localeCode) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(l10n.profileManageSubjects, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              for (final subject in subjects)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SubjectChip(
                    subjectKey: subject.key,
                    label: subject.displayName(localeCode),
                  ),
                  trailing: subject.isCustom
                      ? IconButton(
                          icon: const Icon(PhosphorIconsRegular.trash),
                          onPressed: () {
                            ref.read(profileControllerProvider).deleteCustomSubject(subject.id);
                          },
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref, int existingCustomCount) {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    // Same palette as the fixed curriculum's colorHex values (see
    // `_seedDefaultSubjects` in app_database.dart), cycled so custom
    // subjects get a visually distinct, deterministic accent too.
    const palette = [
      '0xFF5B6EE8', // subjectMath
      '0xFF4CAF7D', // subjectScience
      '0xFFC77B4C', // subjectHistory
      '0xFFB05FC2', // subjectLanguage
      '0xFFE0637A', // subjectLiterature
      '0xFF5B9EE8', // subjectSocial
    ];
    final colorHex = palette[existingCustomCount % palette.length];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileAddCustomSubject),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: l10n.materialTitle),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              ref.read(profileControllerProvider).addCustomSubject(
                    name: name,
                    colorHex: colorHex,
                  );
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}
