import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';

Uri? resolveAttachmentUrl(String value) {
  final url = value.trim();
  if (url.isEmpty) return null;
  final apiUri = Uri.parse(ApiEndpoints.baseUrl);
  if (url.startsWith('/uploads/')) return apiUri.resolve(url);
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    return null;
  }
  if (!kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
    return uri.replace(host: apiUri.host);
  }
  return uri;
}
