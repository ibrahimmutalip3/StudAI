import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/database/daos/test_dao.dart';
import '../../../../core/database/daos/material_dao.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/utils/subject_localization.dart';

/// Small horizontally-scrolling test card used in the Today screen's
/// "Upcoming tests" row.
class TestPreviewCard extends StatelessWidget {
  final TestWithSubject item;
  final String localeCode;
  final VoidCallback onTap;

  const TestPreviewCard({
    super.key,
    required this.item,
    required this.localeCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.forSubjectKey(item.subject.key);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.smRadius,
                ),
                child: Icon(PhosphorIconsRegular.testTube, color: accent, size: AppIconSize.sm),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.test.title,
                style: textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.subject.displayName(localeCode),
                style: textTheme.bodySmall?.copyWith(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small horizontally-scrolling material card used in the Today
/// screen's "Worth reviewing" row.
class MaterialPreviewCard extends StatelessWidget {
  final MaterialWithSubject item;
  final String localeCode;
  final VoidCallback onTap;

  const MaterialPreviewCard({
    super.key,
    required this.item,
    required this.localeCode,
    required this.onTap,
  });

  IconData get _icon {
    switch (item.material.type) {
      case StudyMaterialType.pdf:
        return PhosphorIconsRegular.filePdf;
      case StudyMaterialType.image:
        return PhosphorIconsRegular.image;
      case StudyMaterialType.note:
        return PhosphorIconsRegular.notePencil;
      case StudyMaterialType.text:
        return PhosphorIconsRegular.fileText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = AppColors.forSubjectKey(item.subject.key);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.mdRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.mdRadius,
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: AppRadii.smRadius,
                ),
                child: Icon(_icon, color: accent, size: AppIconSize.sm),
              ),
              const SizedBox(height: AppSpacing.sm),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
