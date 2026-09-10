import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/database/tables.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/l10n/generated/app_localizations.dart';

enum _AddStep { chooseType, details }

class MaterialAddScreen extends ConsumerStatefulWidget {
  const MaterialAddScreen({super.key});

  @override
  ConsumerState<MaterialAddScreen> createState() => _MaterialAddScreenState();
}

class _MaterialAddScreenState extends ConsumerState<MaterialAddScreen> {
  _AddStep _step = _AddStep.chooseType;
  MaterialType _type = MaterialType.text;
  String? _filePath;
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _textController = TextEditingController();
  String? _subjectId;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    final path = result?.files.single.path;
    if (path == null) return;
    final saved = await _copyIntoAppDir(File(path));
    setState(() {
      _type = MaterialType.pdf;
      _filePath = saved;
      _titleController.text = p.basenameWithoutExtension(path);
      _step = _AddStep.details;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (file == null) return;
    final saved = await _copyIntoAppDir(File(file.path));
    setState(() {
      _type = MaterialType.image;
      _filePath = saved;
      _step = _AddStep.details;
    });
  }

  void _chooseText() {
    setState(() {
      _type = MaterialType.text;
      _step = _AddStep.details;
    });
  }

  Future<String> _copyIntoAppDir(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final materialsDir = Directory(p.join(dir.path, 'materials'));
    if (!await materialsDir.exists()) await materialsDir.create(recursive: true);
    final fileName = '${IdGenerator.next()}${p.extension(source.path)}';
    final dest = File(p.join(materialsDir.path, fileName));
    await source.copy(dest.path);
    return dest.path;
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty || _subjectId == null) return;
    setState(() => _saving = true);
    final dao = ref.read(materialDaoProvider);
    await dao.upsert(
      StudyMaterialsCompanion(
        id: Value(IdGenerator.next()),
        title: Value(_titleController.text.trim()),
        subjectId: Value(_subjectId!),
        topic: Value(_topicController.text.trim()),
        type: Value(_type),
        filePath: Value(_filePath ?? ''),
        textContent: Value(_type == MaterialType.text ? _textController.text.trim() : ''),
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == _AddStep.chooseType ? l10n.addMaterial : l10n.addMaterial),
        leading: _step == _AddStep.details
            ? IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowLeft),
                onPressed: () => setState(() => _step = _AddStep.chooseType),
              )
            : null,
      ),
      body: _step == _AddStep.chooseType
          ? _ChooseTypeBody(onPdf: _pickPdf, onImage: _pickImage, onText: _chooseText)
          : _DetailsBody(
              type: _type,
              filePath: _filePath,
              titleController: _titleController,
              topicController: _topicController,
              textController: _textController,
              subjectId: _subjectId,
              onSubjectChanged: (v) => setState(() => _subjectId = v),
              onSave: _save,
              saving: _saving,
            ),
    );
  }
}

class _ChooseTypeBody extends StatelessWidget {
  final VoidCallback onPdf;
  final VoidCallback onImage;
  final VoidCallback onText;
  const _ChooseTypeBody({required this.onPdf, required this.onImage, required this.onText});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(l10n.chooseMaterialType, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        _TypeOption(icon: PhosphorIconsRegular.filePdf, label: l10n.materialFromPdf, onTap: onPdf),
        const SizedBox(height: AppSpacing.md),
        _TypeOption(icon: PhosphorIconsRegular.image, label: l10n.materialFromImage, onTap: onImage),
        const SizedBox(height: AppSpacing.md),
        _TypeOption(icon: PhosphorIconsRegular.notePencil, label: l10n.materialFromText, onTap: onText),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TypeOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: AppRadii.lgRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.lgRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: AppIconSize.lg),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
              Icon(PhosphorIconsRegular.caretRight, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  final MaterialType type;
  final String? filePath;
  final TextEditingController titleController;
  final TextEditingController topicController;
  final TextEditingController textController;
  final String? subjectId;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onSave;
  final bool saving;

  const _DetailsBody({
    required this.type,
    required this.filePath,
    required this.titleController,
    required this.topicController,
    required this.textController,
    required this.subjectId,
    required this.onSubjectChanged,
    required this.onSave,
    required this.saving,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();

    return StreamBuilder<List<Subject>>(
      stream: subjectsAsync,
      builder: (context, snapshot) {
        final subjects = snapshot.data ?? const <Subject>[];
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (type == MaterialType.image && filePath != null)
              ClipRRect(
                borderRadius: AppRadii.lgRadius,
                child: Image.file(File(filePath!), height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
            if (type == MaterialType.pdf && filePath != null)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: AppRadii.lgRadius,
                ),
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.filePdf, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        p.basename(filePath!),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.materialTitle),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: subjectId ?? (subjects.isNotEmpty ? subjects.first.id : null),
              items: subjects
                  .map((s) => DropdownMenuItem(value: s.id, child: Text(s.displayName(localeCode))))
                  .toList(),
              onChanged: onSubjectChanged,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: topicController,
              decoration: const InputDecoration(labelText: 'Topic'),
            ),
            if (type == MaterialType.text) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: textController,
                maxLines: 10,
                decoration: InputDecoration(labelText: l10n.materialContent),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.save),
            ),
          ],
        );
      },
    );
  }
}
