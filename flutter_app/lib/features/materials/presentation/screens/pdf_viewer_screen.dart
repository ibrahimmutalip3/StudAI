import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/state_views.dart';

/// Full-screen PDF viewer for a material stored locally at [filePath].
///
/// Uses Syncfusion's PDF viewer (already a pubspec dependency). Syncfusion
/// requires a license key to suppress the trial watermark in release
/// builds — see [AppConfig.syncfusionLicenseKey] and the registration call
/// in main.dart. Without a key, the viewer still works but shows a small
/// trial banner; that's a licensing decision for the app owner to make
/// (Syncfusion offers a free Community License —
/// https://www.syncfusion.com/sales/communitylicense), not something to
/// silently fake here.
class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  final TextEditingController _searchInputController = TextEditingController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  bool _hasError = false;
  bool _isSearching = false;

  @override
  void dispose() {
    _searchInputController.dispose();
    _searchResult.removeListener(_onSearchResultChanged);
    super.dispose();
  }

  void _onSearchResultChanged() {
    if (mounted) setState(() {});
  }

  void _runSearch(String query) {
    _searchResult.removeListener(_onSearchResultChanged);
    if (query.trim().isEmpty) {
      setState(() => _searchResult = PdfTextSearchResult());
      return;
    }
    _searchResult = _controller.searchText(query.trim());
    _searchResult.addListener(_onSearchResultChanged);
    setState(() {});
  }

  void _closeSearch() {
    _searchResult.clear();
    _searchResult.removeListener(_onSearchResultChanged);
    _searchInputController.clear();
    setState(() {
      _isSearching = false;
      _searchResult = PdfTextSearchResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final file = File(widget.filePath);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchInputController,
                autofocus: true,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: l10n.pdfSearch,
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _runSearch,
                onChanged: _runSearch,
              )
            : Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: _isSearching
            ? [
                if (_searchResult.hasResult)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Center(
                      child: Text(
                        '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  onPressed: _searchResult.hasResult ? () => _searchResult.previousInstance() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: _searchResult.hasResult ? () => _searchResult.nextInstance() : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _closeSearch,
                ),
              ]
            : [
                IconButton(
                  tooltip: l10n.pdfSearch,
                  icon: const Icon(Icons.search),
                  onPressed: () => setState(() => _isSearching = true),
                ),
              ],
      ),
      body: !file.existsSync()
          ? ErrorStateView(
              message: l10n.pdfFileMissing,
              actionLabel: l10n.close,
              onAction: () => context.pop(),
            )
          : _hasError
              ? ErrorStateView(
                  message: l10n.pdfCouldNotOpen,
                  actionLabel: l10n.close,
                  onAction: () => context.pop(),
                )
              : SfPdfViewer.file(
                  file,
                  controller: _controller,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  onDocumentLoadFailed: (details) {
                    setState(() => _hasError = true);
                  },
                ),
    );
  }
}
