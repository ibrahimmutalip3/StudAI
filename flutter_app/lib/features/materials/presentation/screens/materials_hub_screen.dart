import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/tables.dart';
import '../../../../core/database/daos/material_dao.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

class MaterialsHubScreen extends ConsumerWidget {
  const MaterialsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final materialsAsync = ref.watch(materialDaoProvider).watchAll();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.materialsTitle),
          actions: [
            IconButton(
              icon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              onPressed: () => context.push('/search'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: l10n.materialsTitle),
              Tab(text: l10n.notesTitle),
              Tab(text: l10n.flashcardsTitle),
              Tab(text: l10n.testsTitle),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MaterialsList(materialsAsync: materialsAsync, localeCode: localeCode),
            const _NotesShortcut(),
            const _FlashcardsShortcut(),
            const _TestsShortcut(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/materials/add'),
          child: const Icon(PhosphorIconsBold.plus),
        ),
      ),
    );
  }
}

class _MaterialsList extends ConsumerWidget {
  final Stream<List<MaterialWithSubject>> materialsAsync;
  final String localeCode;
  const _MaterialsList({required this.materialsAsync, required this.localeCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<List<MaterialWithSubject>>(
      stream: materialsAsync,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ListSkeletonLoader();
        final items = snapshot.data!;
        if (items.isEmpty) {
          return EmptyStateView(
            icon: PhosphorIconsRegular.stack,
            title: l10n.materialsEmptyTitle,
            subtitle: l10n.materialsEmptySubtitle,
            actionLabel: l10n.addMaterial,
            onAction: () => context.push('/materials/add'),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.86,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _MaterialCard(
              item: item,
              localeCode: localeCode,
              onTap: () => context.push('/materials/${item.material.id}'),
            );
          },
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialWithSubject item;
  final String localeCode;
  final VoidCallback onTap;
  const _MaterialCard({required this.item, required this.localeCode, required this.onTap});

  IconData get _icon {
    switch (item.material.type) {
      case StudyMaterialType.pdf:
        return PhosphorIconsFill.filePdf;
      case StudyMaterialType.image:
        return PhosphorIconsFill.image;
      case StudyMaterialType.note:
        return PhosphorIconsFill.notePencil;
      case StudyMaterialType.text:
        return PhosphorIconsFill.fileText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.forSubjectKey(item.subject.key);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.smRadius,
                ),
                child: Icon(_icon, color: accent, size: AppIconSize.md),
              ),
              const Spacer(),
              Text(
                item.material.title,
                style: textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.subject.displayName(localeCode),
                style: textTheme.bodySmall?.copyWith(color: accent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesShortcut extends StatelessWidget {
  const _NotesShortcut();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () => context.push('/materials/notes'),
              icon: const Icon(PhosphorIconsRegular.notePencil),
              label: Text(l10n.notesTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardsShortcut extends StatelessWidget {
  const _FlashcardsShortcut();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.push('/materials/flashcards'),
        icon: const Icon(PhosphorIconsRegular.cards),
        label: Text(l10n.flashcardsTitle),
      ),
    );
  }
}

class _TestsShortcut extends StatelessWidget {
  const _TestsShortcut();
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: FilledButton.icon(
        onPressed: () => context.push('/materials/tests'),
        icon: const Icon(PhosphorIconsRegular.testTube),
        label: Text(l10n.testsTitle),
      ),
    );
  }
}
