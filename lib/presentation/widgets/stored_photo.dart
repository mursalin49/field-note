import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/local/photo_storage.dart';

class StoredPhoto extends StatelessWidget {
  const StoredPhoto({
    super.key,
    required this.path,
    this.height,
    this.width,
    this.fit,
    this.errorBuilder,
  });

  final String path;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && path.startsWith('data:')) {
      return Image.memory(PhotoStorage.decodeDataUrl(path),
          height: height, width: width, fit: fit, errorBuilder: errorBuilder);
    }
    return Image.file(File(path),
        height: height, width: width, fit: fit, errorBuilder: errorBuilder);
  }
}
