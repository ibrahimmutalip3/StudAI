import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/ai/parsers/flashcard_generation_parser.dart';
import '../../../../core/ai/prompts/flashcard_prompts.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../core/utils/json_list.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/widgets/ai_result_sheet.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../ai_tutor/domain/ai_tutor_launch_args.dart';
import '../../application/note_ai_controller.dart';

const _newNoteId = 'new';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;
  const NoteEditorScreen({super.key, this.noteId});

  bool get isNew => noteId == null || noteId == _newNoteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _subjectId;
  List<String> _imagePaths = [];
  bool _loaded = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isNew) {
      _loadExisting();
    } else {
      _loaded = true;
    }
    _titleController.addListener(_markDirty);
    _contentController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _loadExisting() async {
    final dao = ref.read(noteDaoProvider);
    final note = await dao.getById(widget.noteId!);
    if (note != null && mounted) {
      setState(() {
        _titleController.text = note.title;
        _contentController.text = note.content;
        _subjectId = note.subjectId;
        _imagePaths = decodeStringList(note.imagePaths);
        _loaded = true;
      });
    } else if (mounted) {
      setState(() => _loaded = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _attachImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (file == null) return;
    final saved = await _copyIntoAppDir(File(file.path));
    setState(() {
      _imagePaths = [..._imagePaths, saved];
      _dirty = true;
    });
  }

  Future<void> _attachFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final saved = await _copyIntoAppDir(File(file.path));
    setState(() {
      _imagePaths = [..._imagePaths, saved];
      _dirty = true;
    });
  }

  Future<String> _copyIntoAppDir(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final notesDir = Directory(p.join(dir.path, 'notes'));
    if (!await notesDir.exists()) await notesDir.create(recursive: true);
    final fileName = '${IdGenerator.next()}${p.extension(source.path)}';
    final dest = File(p.join(notesDir.path, fileName));
    await source.copy(dest.path);
    return dest.path;
  }

  Future<String> _save() async {
    final dao = ref.read(noteDaoProvider);
    final id = (widget.isNew) ? IdGenerator.next() : widget.noteId!;
    await dao.upsert(
      NotesCompanion(
        id: Value(id),
        title: Value(_titleController.text.trim()),
        subjectId: Value(_subjectId),
        content: Value(_contentController.text.trim()),
        imagePaths: Value(encodeStringList(_imagePaths)),
        updatedAt: Value(DateTime.now()),
      ),
    );
    _dirty = false;
    return id;
  }

  Future<void> _saveAndClose() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      if (mounted) context.pop();
      return;
    }
    await _save();
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    if (widget.isNew) {
      if (mounted) context.pop();
      return;
    }
    await ref.read(noteDaoProvider).delete(widget.noteId!);
    if (mounted) context.pop();
  }

  void _runAiAction(NoteAiAction action, String title) {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    AiResultSheet.show(
      context,
      title: title,
      resultProvider: noteAiResultProvider(NoteAiRequest(action: action, content: content)),
      onSave: () => _applyStructureResult(action),
    );
  }

  void _applyStructureResult(NoteAiAction action) {
    if (action != NoteAiAction.structure) return;
    final result = ref.read(
      noteAiResultProvider(NoteAiRequest(action: action, content: _contentController.text.trim())),
    );
    result.whenData((text) {
      setState(() {
        _contentController.text = text;
        _dirty = true;
      });
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final subjectsAsync = ref.watch(subjectDaoProvider).watchAll();

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? l10n.newNote : l10n.edit),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.sparkle),
            tooltip: l10n.aiTutorTitle,
            onPressed: _contentController.text.trim().isEmpty
                ? null
                : () => _showAiSheet(context),
          ),
          if (!widget.isNew)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trash),
              onPressed: () => _confirmDelete(context),
            ),
          TextButton(onPressed: _saveAndClose, child: Text(l10n.done)),
        ],
      ),
      body: StreamBuilder<List<Subject>>(
        stream: subjectsAsync,
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? const <Subject>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.huge,
            ),
            children: [
              _SubjectPicker(
                subjects: subjects,
                selected: _subjectId,
                localeCode: localeCode,
                onChanged: (value) => setState(() {
                  _subjectId = value;
                  _dirty = true;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: Theme.of(context).textTheme.headlineSmall,
                decoration: InputDecoration(
                  hintText: l10n.noteTitleHint,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _contentController,
                textCapitalization: TextCapitalization.sentences,
                minLines: 8,
                maxLines: null,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: l10n.noteContentHint,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_imagePaths.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) => ClipRRect(
                      borderRadius: AppRadii.mdRadius,
                      child: Image.file(
                        File(_imagePaths[index]),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _attachImage,
                    icon: const Icon(PhosphorIconsRegular.camera),
                    label: Text(l10n.noteFromCamera),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: _attachFromGallery,
                    icon: const Icon(PhosphorIconsRegular.image),
                    label: Text(l10n.noteAttachImage),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: _contentController.text.trim().isEmpty
                    ? null
                    : () => _askAiAboutThis(subjects, localeCode),
                icon: const Icon(PhosphorIconsRegular.sparkle),
                label: Text(l10n.materialAiAskAboutThis),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _askAiAboutThis(List<Subject> subjects, String localeCode) async {
    await _save();
    final subject = subjects.where((s) => s.id == _subjectId).firstOrNull;
    if (!mounted) return;
    context.push(
      '/ai-tutor',
      extra: AiTutorLaunchArgs(
        subjectKey: subject?.key,
        subjectName: subject?.displayName(localeCode),
        notesExcerpt: _contentController.text.trim(),
      ),
    );
  }

  void _showAiSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.aiTutorTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              _AiActionTile(
                icon: PhosphorIconsRegular.magicWand,
                label: l10n.noteAiStructure,
                onTap: () {
                  Navigator.of(context).pop();
                  _runAiAction(NoteAiAction.structure, l10n.noteAiStructure);
                },
              ),
              _AiActionTile(
                icon: PhosphorIconsRegular.textAlignLeft,
                label: l10n.noteAiSummarize,
                onTap: () {
                  Navigator.of(context).pop();
                  _runAiAction(NoteAiAction.summarize, l10n.noteAiSummarize);
                },
              ),
              _AiActionTile(
                icon: PhosphorIconsRegular.listBullets,
                label: l10n.noteAiKeyPoints,
                onTap: () {
                  Navigator.of(context).pop();
                  _runAiAction(NoteAiAction.keyPoints, l10n.noteAiKeyPoints);
                },
              ),
              _AiActionTile(
                icon: PhosphorIconsRegular.calendarBlank,
                label: l10n.noteAiFindDates,
                onTap: () {
                  Navigator.of(context).pop();
                  _runAiAction(NoteAiAction.findDates, l10n.noteAiFindDates);
                },
              ),
              _AiActionTile(
                icon: PhosphorIconsRegular.function,
                label: l10n.noteAiFindFormulas,
                onTap: () {
                  Navigator.of(context).pop();
                  _runAiAction(NoteAiAction.findFormulas, l10n.noteAiFindFormulas);
                },
              ),
              _AiActionTile(
                icon: PhosphorIconsRegular.question,
                label: l10n.noteAiQuestions,
                onTap: () {
                  Navigator.of(context).pop();
                  _runAiAction(NoteAiAction.generateQuestions, l10n.noteAiQuestions);
                },
              ),
              _AiActionTile(
                icon: PhosphorIconsRegular.cards,
                label: l10n.noteAiFlashcards,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _generateFlashcardsFromNote();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateFlashcardsFromNote() async {
    final l10n = AppLocalizations.of(context)!;
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final aiService = ref.read(aiServiceProvider);
    final locale = ref.read(localeCodeProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final rawJson = await aiService.generateStructuredJson(
        systemPrompt: FlashcardPrompts.system(locale),
        userPrompt: FlashcardPrompts.userPrompt(sourceContent: content, cardCount: 10),
      );
      final cards = FlashcardGenerationParser.parse(rawJson);
      final deckId = IdGenerator.next();
      final flashcardDao = ref.read(flashcardDaoProvider);
      await flashcardDao.upsertDeck(
        FlashcardDecksCompanion(
          id: Value(deckId),
          title: Value(_titleController.text.trim().isNotEmpty
              ? _titleController.text.trim()
              : l10n.newDeck),
          subjectId: Value(_subjectId),
        ),
      );
      for (final card in cards) {
        await flashcardDao.upsertCard(
          FlashcardsCompanion(
            id: Value(IdGenerator.next()),
            deckId: Value(deckId),
            front: Value(card.front),
            back: Value(card.back),
            subjectId: Value(_subjectId),
          ),
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.flashcardsCreated(cards.length))),
        );
        context.push('/materials/flashcards/$deckId/study');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.somethingWentWrong)));
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteBody),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              context.pop();
              _delete();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _SubjectPicker extends StatelessWidget {
  final List<Subject> subjects;
  final String? selected;
  final String localeCode;
  final ValueChanged<String?> onChanged;

  const _SubjectPicker({
    required this.subjects,
    required this.selected,
    required this.localeCode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: l10n.noSubject,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: AppSpacing.sm),
          ...subjects.map((s) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _Chip(
                  label: s.displayName(localeCode),
                  selected: selected == s.id,
                  onTap: () => onChanged(s.id),
                ),
              )),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
    );
  }
}

class _AiActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AiActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
