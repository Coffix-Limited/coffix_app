import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildError();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder != null ? (_, __) => placeholder! : null,
      errorWidget: errorWidget != null ? (_, __, ___) => errorWidget! : null,
    );
  }

  Widget _buildError() => SizedBox(
    width: width,
    height: height,
    child: errorWidget ?? const Icon(Icons.broken_image_outlined),
  );
}
