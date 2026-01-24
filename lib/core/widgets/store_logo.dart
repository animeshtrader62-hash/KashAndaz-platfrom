import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

class StoreLogo extends StatelessWidget {
  final String? url;
  final String? storeName;
  final double size;
  final double radius;
  final Color backgroundColor;
  final Color borderColor;

  const StoreLogo({
    super.key,
    required this.url,
    this.storeName,
    this.size = 40,
    this.radius = 8,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFEAEAEA),
  });

  static const Map<String, String> _staticLogoMap = {
    // PNG-only fallbacks via Google favicon endpoint (served as image/png).
    // These are resilient and don't depend on a specific third-party logo file path.
    'amazon': 'https://www.google.com/s2/favicons?sz=128&domain=amazon.in',
    'flipkart': 'https://www.google.com/s2/favicons?sz=128&domain=flipkart.com',
    'myntra': 'https://www.google.com/s2/favicons?sz=128&domain=myntra.com',
    'ajio': 'https://www.google.com/s2/favicons?sz=128&domain=ajio.com',
  };

  // Neutral image fallback (only used when backend URL is missing and store name
  // is not in the static map). If this image fails, we show the icon fallback.
  static const String _defaultFallbackLogoUrl =
      'https://www.google.com/s2/favicons?sz=128&domain=example.com';

  static String _canonicalizeName(String name) {
    final lower = name.trim().toLowerCase();
    final buffer = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      final c = String.fromCharCode(codeUnit);
      // Mandatory: lowercase + remove non-alphabet characters.
      final isAlpha = RegExp(r'[a-z]').hasMatch(c);
      if (isAlpha) buffer.write(c);
    }
    return buffer.toString();
  }

  static bool _isRasterLogoUrl(String url) {
    // Mandatory: accept only PNG/JPG/JPEG.
    final lower = url.toLowerCase();
    if (lower.contains('.png') || lower.contains('.jpg') || lower.contains('.jpeg')) return true;

    // Special-case: Google S2 favicon endpoint returns image/png even without an extension.
    if (lower.contains('google.com/s2/favicons')) return true;
    return false;
  }

  static String? _sanitizeLogoUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) return null;

    var normalized = trimmed;
    if (normalized.startsWith('//')) {
      normalized = 'https:$normalized';
    }
    if (normalized.startsWith('http://')) {
      normalized = 'https://${normalized.substring('http://'.length)}';
    }
    if (!normalized.startsWith('https://')) return null;

    final lower = normalized.toLowerCase();
    if (lower.endsWith('.svg')) return null;

    if (!_isRasterLogoUrl(normalized)) return null;

    return normalized;
  }

  static String? _staticLogoForStoreName(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return null;

    // Mandatory: map by keyword detection, not exact match.
    final lower = n.toLowerCase();
    final slug =
        lower.contains('amazon') ? 'amazon'
        : lower.contains('flipkart') ? 'flipkart'
        : lower.contains('myntra') ? 'myntra'
        : lower.contains('ajio') ? 'ajio'
        : null;

    if (slug != null) return _staticLogoMap[slug];

    // Fallback: normalized letters-only key (helps when names include punctuation).
    final key = _canonicalizeName(n);
    if (key.isEmpty) return null;
    for (final entry in _staticLogoMap.entries) {
      if (key.contains(entry.key)) return entry.value;
    }
    return null;
  }

  ({String url, String source}) _resolveLogo() {
    final fromBackend = _sanitizeLogoUrl(url);
    if (fromBackend != null) {
      return (url: fromBackend, source: 'backend');
    }

    final fromStatic = _staticLogoForStoreName(storeName);
    if (fromStatic != null) {
      return (url: fromStatic, source: 'static-map');
    }

    return (url: _defaultFallbackLogoUrl, source: 'default-fallback');
  }

  static String _wrapWithProxyForWeb(String resolvedUrl) {
    if (!kIsWeb) return resolvedUrl;

    final encoded = Uri.encodeQueryComponent(resolvedUrl);
    return '${ApiConstants.baseUrl}/api/assets/image?url=$encoded';
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveLogo();

    final displayUrl = _wrapWithProxyForWeb(resolved.url);

    if (kDebugMode) {
      debugPrint(
        '[StoreLogo] name="${storeName ?? ''}" rawUrl="${(url ?? '').trim()}" '
        'resolved="${resolved.url}" displayUrl="$displayUrl" source=${resolved.source}',
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: CachedNetworkImage(
        imageUrl: displayUrl,
        fit: BoxFit.contain,
        // Memory rules: cap all logo decodes/caches to 120x120.
        memCacheWidth: 120,
        memCacheHeight: 120,
        maxWidthDiskCache: 120,
        maxHeightDiskCache: 120,
        fadeInDuration: const Duration(milliseconds: 150),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, _) => const ColoredBox(
          color: Color(0xFFF3F4F6),
          child: SizedBox.expand(),
        ),
        errorWidget: (context, failedUrl, error) {
          if (kDebugMode) {
            debugPrint(
              '[StoreLogo] IMAGE_LOAD_FAILED url="$failedUrl" err="$error" name="${storeName ?? ''}" rawUrl="${(url ?? '').trim()}"',
            );
          }
          // No generic icon fallback (forbidden). Show a neutral container.
          return Container(color: backgroundColor);
        },
      ),
    );
  }
}
