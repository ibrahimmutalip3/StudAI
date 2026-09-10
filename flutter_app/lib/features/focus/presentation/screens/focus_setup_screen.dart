import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/daos/homework_dao.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/focus_session_args.dart';

class FocusSetupScreen extends ConsumerStatefulWidget {
  const FocusSetupScreen({super.key});

  @override
  ConsumerState<FocusSetupScreen> createState() => _FocusSetupScreenState();
}

class _FocusSetupScreenState extends ConsumerState<FocusSetupScreen> {
  HomeworkWithSubject? _selectedHomework;
  bool _noHomework = false;
  int _durationMinutes = 25;

  static const _durations = [15, 25, 45, 60];

  void _start() {
    final args = FocusSessionArgs(
      homeworkId: _selectedHomework?.homework.id,
      homeworkTitle: _selectedHomework?.homework.title,
      subjectId: _selectedHomework?.subject.id,
      subjectKey: _selectedHomework?.subject.key,
      subjectName: _selectedHomework != null
          ? _selectedHomework!.subject.displayName(ref.read(localeCodeProvider))
          : null,
      durationMinutes: _durationMinutes,
    );
    context.push('/focus/session', extra: args);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final homeworkAsync = ref.watch(homeworkDaoProvider).watchUpcoming(days: 14);
    final localeCode = ref.watch(localeCodeProvider);
    final canStart = _noHomework || _selectedHomework != null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.focusSetupTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
        ),
        children: [
          Text(l10n.focusChooseHomework, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          StreamBuilder<List<HomeworkWithSubject>>(
            stream: homeworkAsync,
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <HomeworkWithSubject>[];
              return Column(
                children: [
                  ...items.map((hw) => _SelectableRow(
                        title: hw.homework.title,
                        subtitle: hw.subject.displayName(localeCode),
                        accent: AppColors.forSubjectKey(hw.subject.key),
                        selected: _selectedHomework?.homework.id == hw.homework.id,
                        onTap: () => setState(() {
                          _selectedHomework = hw;
                          _noHomework = false;
                        }),
                      )),
                  _SelectableRow(
                    title: l10n.focusNoHomeworkOption,
                    subtitle: null,
                    accent: AppColors.subjectOther,
                    selected: _noHomework,
                    icon: PhosphorIconsRegular.bookOpen,
                    onTap: () => setState(() {
                      _noHomework = true;
                      _selectedHomework = null;
                    }),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.focusDuration, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: _durations
                .map((m) => ChoiceChip(
                      label: Text(l10n.focusMinutes(m)),
                      selected: _durationMinutes == m,
                      onSelected: (_) => setState(() => _durationMinutes = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xxl),
          FilledButton.icon(
            onPressed: canStart ? _start : null,
            icon: const Icon(PhosphorIconsFill.timer),
            label: Text(l10n.focusStart),
          ),
        ],
      ),
    );
  }
}

class _SelectableRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _SelectableRow({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        borderRadius: AppRadii.mdRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.mdRadius,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: AppRadii.smRadius,
                  ),
                  child: Icon(icon ?? PhosphorIconsRegular.checkSquare, color: accent, size: AppIconSize.sm),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accent)),
                    ],
                  ),
                ),
                Icon(
                  selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
