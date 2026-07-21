const fs = require('fs');
const path = require('path');
const file = path.join(process.cwd(), 'lib/features/library/presentation/pages/library_page.dart');
let s = fs.readFileSync(file, 'utf8');
function mustReplace(pattern, replacement, label) {
  const before = s;
  s = s.replace(pattern, replacement);
  if (s === before) throw new Error('No replacement: ' + label);
}
mustReplace('            onUpload: () => context.push(UploadPage.routePath),', '            onUpload: () => _showUploadMethodSheet(context),', 'upload handler');
mustReplace(/  void _showComingSoon\(BuildContext context, String label\) \{[\s\S]*?\n  \}\n\}/, String.raw`  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label $_comingSoon')));
  }

  void _showUploadMethodSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.mameroom.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _UploadMethodSheet(
        onPdfUpload: () {
          Navigator.of(sheetContext).pop();
          context.push(UploadPage.routePath);
        },
        onComingSoon: (label) {
          Navigator.of(sheetContext).pop();
          _showComingSoon(context, label);
        },
      ),
    );
  }
}`, 'sheet method');
mustReplace(/\s+SliverToBoxAdapter\(\s+child: SizedBox\(height: metrics\.largeGap\),\s+\),\s+SliverToBoxAdapter\(\s+child: _UploadSection\([\s\S]*?\),\s+\),\s+SliverToBoxAdapter\(\s+child: SizedBox\(height: metrics\.gap\),\s+\),\s+SliverToBoxAdapter\(\s+child: _QuotaBanner\(dense: metrics\.dense\),\s+\),/, String.raw`
                          SliverToBoxAdapter(
                            child: SizedBox(height: metrics.largeGap),
                          ),
                          SliverToBoxAdapter(
                            child: _QuotaBanner(dense: metrics.dense),
                          ),`, 'remove upload section sliver');
mustReplace('      height: dense ? 98 : 108,', '      height: dense ? 76 : 84,', 'quick height');
s = s.replace('          SizedBox(height: dense ? 12 : 16),', '          SizedBox(height: dense ? 10 : 12),');
s = s.replace('          SizedBox(height: dense ? 14 : 16),', '          SizedBox(height: dense ? 10 : 12),');
s = s.replace('          SizedBox(height: dense ? 10 : 12),\n          Row(\n            children: [\n              Expanded(\n                child: LinearProgressIndicator(', '          SizedBox(height: dense ? 8 : 10),\n          Row(\n            children: [\n              Expanded(\n                child: LinearProgressIndicator(');
s = s.replace('          SizedBox(height: dense ? 10 : 12),\n          SizedBox(\n            height: dense ? 44 : 50,', '          SizedBox(height: dense ? 8 : 10),\n          SizedBox(\n            height: dense ? 42 : 46,');
mustReplace(/\s+Text\(\s+latestMaterial\.recentStudyLabel,\s+style: Theme\.of\(context\)\.textTheme\.labelSmall\?\.copyWith/, String.raw`
              Text(
                '\${latestMaterial.memoryPercent}%  \u{00B7}  \${latestMaterial.recentStudyLabel}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith`, 'recent material meta');
mustReplace(/\s+Text\(\s+'\$\{material\.recentStudyLabel\}  \\\\u\{00B7\}  \$\{_questionCount\(material\.totalQuestionCount\)\}',\s+maxLines: 1,\s+overflow: TextOverflow\.ellipsis,\s+style: Theme\.of\(context\)\.textTheme\.labelSmall\?\.copyWith\(\s+color: colors\.muted,\s+fontWeight: FontWeight\.w800,\s+\),\s+\),/, String.raw`
                  Wrap(
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      _TinyInfo(label: _questionCount(material.totalQuestionCount)),
                      _TinyInfo(label: '\${material.memoryPercent}%'),
                      _TinyInfo(label: material.recentStudyLabel),
                    ],
                  ),`, 'material meta');
mustReplace(/Text\(\s+'\$\{material\.memoryPercent\}%',\s+style: Theme\.of\(context\)\.textTheme\.labelSmall\?\.copyWith\(\s+color: colors\.ink,\s+fontWeight: FontWeight\.w900,\s+\),\s+\),/, String.raw`Text(
                        '\${material.progressPercent}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),`, 'progress percent');
mustReplace(/class _UploadSection extends StatelessWidget \{[\s\S]*?\n\}\n\nclass _EmptyState/, 'class _EmptyState', 'remove upload section class');
mustReplace(/class _UploadCta extends StatelessWidget \{[\s\S]*?\n\}\n\nclass _Metric/, 'class _Metric', 'remove upload cta');
s = s.replace('          padding: EdgeInsets.symmetric(horizontal: dense ? 4 : 6, vertical: 8),', '          padding: EdgeInsets.symmetric(horizontal: dense ? 3 : 5, vertical: 6),');
s = s.replace('              Icon(icon, color: colors.primary, size: dense ? 28 : 32),\n              const SizedBox(height: 8),', '              Icon(icon, color: colors.primary, size: dense ? 30 : 34),\n              const SizedBox(height: 5),');
s = s.replace('                  fontSize: dense ? 11 : 12,', '                  fontSize: dense ? 10 : 11,');
const sheetClasses = String.raw`class _UploadMethodSheet extends StatelessWidget {
  const _UploadMethodSheet({
    required this.onPdfUpload,
    required this.onComingSoon,
  });

  final VoidCallback onPdfUpload;
  final ValueChanged<String> onComingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _selectUploadMethod,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          _UploadMethodTile(
            icon: Icons.picture_as_pdf_rounded,
            label: _pdfUploadLabel,
            status: _available,
            onTap: onPdfUpload,
          ),
          _UploadMethodTile(
            icon: Icons.description_outlined,
            label: _wordUploadLabel,
            status: _comingSoonShort,
            onTap: () => onComingSoon(_wordUploadLabel),
          ),
          _UploadMethodTile(
            icon: Icons.slideshow_outlined,
            label: _powerPointUploadLabel,
            status: _comingSoonShort,
            onTap: () => onComingSoon(_powerPointUploadLabel),
          ),
          _UploadMethodTile(
            icon: Icons.image_outlined,
            label: _imageUploadLabel,
            status: _comingSoonShort,
            onTap: () => onComingSoon(_imageUploadLabel),
          ),
          _UploadMethodTile(
            icon: Icons.photo_camera_outlined,
            label: _cameraUploadLabel,
            status: _comingSoonShort,
            onTap: () => onComingSoon(_cameraUploadLabel),
          ),
          _UploadMethodTile(
            icon: Icons.text_fields_rounded,
            label: _textPasteLabel,
            status: _comingSoonShort,
            onTap: () => onComingSoon(_textPasteLabel),
          ),
        ],
      ),
    );
  }
}

class _UploadMethodTile extends StatelessWidget {
  const _UploadMethodTile({
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.primaryMist.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: colors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.mameroom.muted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

`;
mustReplace('class _Metric extends StatelessWidget {', sheetClasses + 'class _Metric extends StatelessWidget {', 'insert sheet classes');
s = s.replace(/const _uploadMaterial = '.*?';\r?\nconst _pdfUpload = '.*?';\r?\nconst _imageUpload = '.*?';\r?\nconst _textInput = '.*?';/s, String.raw`const _selectUploadMethod =
    '\u{C5C5}\u{B85C}\u{B4DC} \u{BC29}\u{C2DD} \u{C120}\u{D0DD}';
const _pdfUploadLabel = 'PDF \u{C5C5}\u{B85C}\u{B4DC}';
const _wordUploadLabel = 'Word \u{C5C5}\u{B85C}\u{B4DC}';
const _powerPointUploadLabel = 'PowerPoint \u{C5C5}\u{B85C}\u{B4DC}';
const _imageUploadLabel = '\u{C774}\u{BBF8}\u{C9C0} \u{C5C5}\u{B85C}\u{B4DC}';
const _cameraUploadLabel = '\u{C0AC}\u{C9C4} \u{CD2C}\u{C601}';
const _textPasteLabel = '\u{D14D}\u{C2A4}\u{D2B8} \u{BD99}\u{C5EC}\u{B123}\u{AE30}';
const _available = '\u{C0AC}\u{C6A9} \u{AC00}\u{B2A5}';
const _comingSoonShort = '\u{C900}\u{BE44} \u{C911}';`);
if (s.includes("const _uploadMaterial")) throw new Error('Old upload constants remain');
s = s.replace(/const _quotaText =\r?\n    '.*?';/s, String.raw`const _quotaText =
    '\u{BB38}\u{C81C} \u{C0DD}\u{C131} \u{AC00}\u{B2A5} \u{00B7} \u{B0A8}\u{C740} \u{C0DD}\u{C131}\u{B7C9} 30\u{AC1C}';`);
fs.writeFileSync(file, s);



