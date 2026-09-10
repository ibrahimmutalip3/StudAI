import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/daos/test_dao.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class TestsListScreen extends ConsumerWidget {
  const TestsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final testsAsync = ref.watch(testDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.testsTitle)),
      body: StreamBuilder<List<TestWithSubject>>(
        stream: testsAsync,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const ListSkeletonLoader();
          final tests = snapshot.data!;
          if (tests.isEmpty) {
            return EmptyStateView(
              icon: PhosphorIconsRegular.testTube,
              title: l10n.testsEmptyTitle,
              subtitle: l10n.testsEmptySubtitle,
              actionLabel: l10n.newTest,
              onAction: () => context.push('/materials/tests/generate'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
            ),
            itemCount: tests.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = tests[index];
              return _TestCard(item: item, localeCode: localeCode);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/materials/tests/generate'),
        icon: const Icon(PhosphorIconsBold.plus),
        label: Text(l10n.newTest),
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  final TestWithSubject item;
  final String localeCode;
  const _TestCard({required this.item, required this.localeCode});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.forSubjectKey(item.subject.key);
    final hasScore = item.test.lastScoreTotal != null;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.lgRadius,
      child: InkWell(
        onTap: () => context.push(
          hasScore ? '/materials/tests/${item.test.id}/results' : '/materials/tests/${item.test.id}/take',
        ),
        borderRadius: AppRadii.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.mdRadius,
                ),
                child: Icon(PhosphorIconsFill.testTube, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.test.title, style: textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      item.subject.displayName(localeCode),
                      style: textTheme.bodySmall?.copyWith(color: accent),
                    ),
                  ],
                ),
              ),
              if (hasScore)
                Text(
                  l10n.testScore(item.test.lastScoreCorrect ?? 0, item.test.lastScoreTotal ?? 0),
                  style: textTheme.labelMedium,
                )
              else
                Icon(PhosphorIconsRegular.caretRight, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
