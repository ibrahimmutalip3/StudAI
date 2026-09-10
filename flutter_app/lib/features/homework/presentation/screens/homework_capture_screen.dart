import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/providers/dao_providers.dart';
import '../../../../core/providers/locale_providers.dart';
import '../../../../core/ai/ai_service.dart';
import '../../../../core/ai/ai_error_translator.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/utils/subject_localization.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/homework_edit_args.dart';

enum _CaptureState { pickImage, recognizing, review, error }

class HomeworkCaptureScreen extends ConsumerStatefulWidget {
  const HomeworkCaptureScreen({super.key});

  @override
  ConsumerState<HomeworkCaptureScreen> createState() => _HomeworkCaptureScreenState();
}

class _HomeworkCaptureScreenState extends ConsumerState<HomeworkCaptureScreen> {
  _CaptureState _state = _CaptureState.pickImage;
  File? _image;
  HomeworkRecognitionResult? _result;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _image = File(file.path);
      _state = _CaptureState.recognizing;
    });
    await _recognize();
  }

  Future<void> _recognize() async {
    final localeCode = ref.read(localeCodeProvider);
    final aiService = ref.read(aiServiceProvider);
    try {
      final bytes = await _image!.readAsBytes();
      final result = await aiService.recognizeHomeworkImage(
        imageBytes: bytes,
        mimeType: 'image/jpeg',
        context: AIContext(localeCode: localeCode),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _state = _CaptureState.review;
      });
    } catch (e) {
      if (!mounted) return;
      final presentation = AiErrorTranslator.translate(e, localeCode: localeCode);
      setState(() {
        _errorMessage = presentation.message;
        _state = _CaptureState.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addHomeworkFromCamera)),
      body: SafeArea(
        child: switch (_state) {
          _CaptureState.pickImage => _PickImageBody(
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            ),
          _CaptureState.recognizing => _RecognizingBody(image: _image),
          _CaptureState.review => _ReviewBody(
              image: _image!,
              result: _result!,
              onRetake: () => setState(() => _state = _CaptureState.pickImage),
            ),
          _CaptureState.error => Center(
              child: ErrorStateView(
                message: _errorMessage ?? l10n.somethingWentWrong,
                actionLabel: l10n.tryAgain,
                onAction: () => setState(() => _state = _CaptureState.pickImage),
              ),
            ),
        },
      ),
    );
  }
}

class _PickImageBody extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  const _PickImageBody({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
              child: Icon(PhosphorIconsFill.camera, size: AppIconSize.xl, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              l10n.editBeforeSaving,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onCamera,
              icon: const Icon(PhosphorIconsRegular.camera),
              label: Text(l10n.addHomeworkFromCamera),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(PhosphorIconsRegular.image),
              label: const Text('Choose from gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizingBody extends StatelessWidget {
  final File? image;
  const _RecognizingBody({required this.image});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (image != null)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ClipRRect(
              borderRadius: AppRadii.lgRadius,
              child: Image.file(image!, height: 220, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
        const Spacer(),
        const CircularProgressIndicator(),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.recognizing, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _ReviewBody extends ConsumerStatefulWidget {
  final File image;
  final HomeworkRecognitionResult result;
  final VoidCallback onRetake;

  const _ReviewBody({required this.image, required this.result, required this.onRetake});

  @override
  ConsumerState<_ReviewBody> createState() => _ReviewBodyState();
}

class _ReviewBodyState extends ConsumerState<_ReviewBody> {
  late final _titleController = TextEditingController(text: widget.result.title);
  late final _descriptionController = TextEditingController(text: widget.result.description);

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeCode = ref.watch(localeCodeProvider);
    final scheme = Theme.of(context).colorScheme;
    final lowConfidence = widget.result.confidence < 0.4;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        ClipRRect(
          borderRadius: AppRadii.lgRadius,
          child: Image.file(widget.image, height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (lowConfidence)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.14),
              borderRadius: AppRadii.mdRadius,
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.warning, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.editBeforeSaving, style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          ),
        Text(l10n.isThisCorrect, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: l10n.homeworkTitle),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: () {
            context.pushReplacement(
              '/homework/new',
              extra: HomeworkEditArgs(
                title: _titleController.text.trim(),
                subjectId: widget.result.subjectGuessKey,
                description: _descriptionController.text.trim(),
              ),
            );
          },
          child: Text(l10n.confirmAndSave),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(onPressed: widget.onRetake, child: Text(l10n.retry)),
      ],
    );
  }
}
