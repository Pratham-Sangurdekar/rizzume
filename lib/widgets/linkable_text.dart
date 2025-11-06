import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LinkableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Function(String url) onLinkTap;
  final int? maxLines;
  final TextOverflow? overflow;

  const LinkableText({
    super.key,
    required this.text,
    this.style,
    required this.onLinkTap,
    this.maxLines,
    this.overflow,
  });

  // Regular expression to match URLs
  static final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/[^\s]+)|'
    r'(www\.[^\s]+)|'
    r'([a-zA-Z0-9][a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*)',
    caseSensitive: false,
  );

  List<InlineSpan> _buildTextSpans() {
    final List<InlineSpan> spans = [];
    final matches = _urlRegExp.allMatches(text);
    
    if (matches.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return spans;
    }

    int lastMatchEnd = 0;

    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }

      // Add the URL as a clickable link
      String url = match.group(0)!;
      // Ensure URL has protocol
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }

      spans.add(TextSpan(
        text: match.group(0),
        style: (style ?? const TextStyle()).copyWith(
          color: const Color(0xFFFF1493), // Neon pink
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFFF1493),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => onLinkTap(url),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(children: _buildTextSpans()),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}
