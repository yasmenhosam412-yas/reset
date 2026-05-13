import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:new_project/core/l10n/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class PostTextWithLinks extends StatefulWidget {
  const PostTextWithLinks({
    super.key,
    required this.text,
    this.style,
    this.linkColor,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle? style;
  final Color? linkColor;
  final TextAlign? textAlign;
  final int? maxLines;

  static final RegExp urlPattern = RegExp(
    r'(https?:\/\/\S+|www\.\S+)',
    caseSensitive: false,
  );

  @override
  State<PostTextWithLinks> createState() => _PostTextWithLinksState();
}

class _PostTextWithLinksState extends State<PostTextWithLinks> {
  final List<TapGestureRecognizer> _recognizers = [];

  String? _builtForText;
  Brightness? _builtForBrightness;
  List<InlineSpan> _spans = const [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  static String _stripTrailingPunctuation(String s) {
    var t = s.trim();
    const trailing = '.,;:!?，。)]}';
    while (t.isNotEmpty && trailing.contains(t[t.length - 1])) {
      t = t.substring(0, t.length - 1);
    }
    return t;
  }

  Future<void> _openUrl(String rawSegment) async {
    if (!mounted) return;
    var normalized = _stripTrailingPunctuation(rawSegment);
    if (normalized.isEmpty) return;
    if (!RegExp(r'^https?://', caseSensitive: false).hasMatch(normalized)) {
      if (normalized.toLowerCase().startsWith('www.')) {
        normalized = 'https://$normalized';
      } else {
        return;
      }
    }
    final uri = Uri.tryParse(normalized);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return;
    }
    final opened =
        await _tryLaunchUrl(uri, LaunchMode.externalApplication) ||
        await _tryLaunchUrl(uri, LaunchMode.platformDefault) ||
        await _tryLaunchUrl(uri, LaunchMode.inAppBrowserView);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.couldNotOpenLink)));
  }

  Future<bool> _tryLaunchUrl(Uri uri, LaunchMode mode) async {
    try {
      return await launchUrl(uri, mode: mode);
    } catch (_) {
      return false;
    }
  }

  void _rebuildSpansIfNeeded() {
    final brightness = Theme.of(context).brightness;
    if (_builtForText == widget.text && _builtForBrightness == brightness) {
      return;
    }
    _builtForText = widget.text;
    _builtForBrightness = brightness;

    _disposeRecognizers();

    final baseStyle =
        widget.style ??
        Theme.of(context).textTheme.bodyLarge ??
        const TextStyle();
    final linkTint = widget.linkColor ?? Theme.of(context).colorScheme.primary;
    final linkStyle = baseStyle.copyWith(
      color: linkTint,
      decoration: TextDecoration.underline,
      decorationColor: linkTint.withValues(alpha: 0.65),
    );

    final text = widget.text;
    if (!PostTextWithLinks.urlPattern.hasMatch(text)) {
      _spans = [TextSpan(text: text, style: baseStyle)];
      return;
    }

    final out = <InlineSpan>[];
    var start = 0;
    for (final m in PostTextWithLinks.urlPattern.allMatches(text)) {
      if (m.start > start) {
        out.add(
          TextSpan(text: text.substring(start, m.start), style: baseStyle),
        );
      }
      final segment = m.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => _openUrl(segment);
      _recognizers.add(recognizer);
      out.add(
        TextSpan(text: segment, style: linkStyle, recognizer: recognizer),
      );
      start = m.end;
    }
    if (start < text.length) {
      out.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    _spans = out;
  }

  @override
  Widget build(BuildContext context) {
    _rebuildSpansIfNeeded();

    return SelectableText.rich(
      TextSpan(children: _spans),
      textAlign: widget.textAlign ?? TextAlign.start,
      maxLines: widget.maxLines,
    );
  }
}
