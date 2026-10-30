import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const LinkifiedText({super.key, required this.text, this.style});

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  static final _urlPattern = RegExp(
    r'(?:https?://|www\.)[^\s<>()]+',
    caseSensitive: false,
  );
  final List<TapGestureRecognizer> _recognizers = [];
  List<TextSpan> _spans = const [];

  @override
  void initState() {
    super.initState();
    _buildSpans();
  }

  @override
  void didUpdateWidget(covariant LinkifiedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _buildSpans();
  }

  void _buildSpans() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in _urlPattern.allMatches(widget.text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }
      final raw = match.group(0)!;
      final link = raw.replaceFirst(RegExp(r'[.,;:!?]+$'), '');
      final trailing = raw.substring(link.length);
      final uri = Uri.tryParse(
        link.startsWith('www.') ? 'https://$link' : link,
      );
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        final recognizer = TapGestureRecognizer()..onTap = () => _open(uri);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: link,
            style: const TextStyle(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: recognizer,
          ),
        );
      } else {
        spans.add(TextSpan(text: link));
      }
      if (trailing.isNotEmpty) spans.add(TextSpan(text: trailing));
      cursor = match.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }
    _spans = spans;
  }

  Future<void> _open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được liên kết này.')),
      );
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(TextSpan(children: _spans), style: widget.style);
  }
}
