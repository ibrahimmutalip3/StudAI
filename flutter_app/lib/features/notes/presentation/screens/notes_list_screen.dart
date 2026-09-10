import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

/// Notes list — reached from the Materials hub's "Notes" shortcut.
/// Grid of note cards (title + content preview), newest-edited first,
/// with a FAB that opens a blank editor.
class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final notesAsync = ref.watch(noteDaoProvider).watchAll();
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notesTitle)),
      body: StreamBuilder<List<Subject>>(
        stream: subjectsAsync,
        builder: (context, subjectSnap) {
          final subjectById = {
            for (final s in subjectSnap.data ?? const <Subject>[]) s.id: s,
          };
          return StreamBuilder<List<Note>>(
            stream: notesAsync,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const ListSkeletonLoader();
              final notes = snapshot.data!;
              if (notes.isEmpty) {
                return EmptyStateView(
                  icon: PhosphorIconsRegular.notePencil,
                  title: l10n.notesEmptyTitle,
                  subtitle: l10n.notesEmptySubtitle,
                  actionLabel: l10n.addNote,
                  onAction: () => context.push('/materials/notes/new'),
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
                  childAspectRatio: 0.82,
                ),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final subject = note.subjectId != null ? subjectById[note.subjectId] : null;
                  return _NoteCard(
                    note: note,
                    subject: subject,
                    localeCode: localeCode,
                    onTap: () => context.push('/materials/notes/${note.id}'),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/materials/notes/new'),
        child: const Icon(PhosphorIconsBold.plus),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final Subject? subject;
  final String localeCode;
  final VoidCallback onTap;

  const _NoteCard({
    required this.note,
    required this.subject,
    required this.localeCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = subject != null ? AppColors.forSubjectKey(subject!.key) : AppColors.subjectOther;

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
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                  ),
                  if (subject != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        subject!.displayName(localeCode),
                        style: textTheme.labelSmall?.copyWith(color: accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                note.title.isEmpty ? l10n.untitled : note.title,
                style: textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  note.content,
                  style: textTheme.bodySmall,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
