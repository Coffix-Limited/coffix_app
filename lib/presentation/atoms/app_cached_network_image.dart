import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffix_app/core/constants/sizes.dart';
import 'package:flutter/material.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    if (imageUrl?.isEmpty ?? true) {
      return _buildError();
    }

    // Decode thumbnails at display resolution (scaled by device pixel ratio)
    // instead of full size, so small images render fast and use little memory.
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memCacheWidth = width != null ? (width! * dpr).round() : null;
    final memCacheHeight = height != null ? (height! * dpr).round() : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.md),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        cacheKey: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        maxWidthDiskCache: 1080,
        maxHeightDiskCache: 1080,
        // Use `placeholder` (shown only on the first network fetch) rather than
        // `progressIndicatorBuilder` (shown on every load phase), so cache hits
        // on resume don't re-trigger the shimmer.
        placeholder: placeholder != null
            ? (_, _) => placeholder!
            : (_, _) => Shimmer(
                child: SizedBox(width: width, height: height),
              ),
        errorWidget: errorWidget != null ? (_, _, _) => errorWidget! : null,
      ),
    );
  }

  Widget _buildError() => SizedBox(
    width: width,
    height: height,
    child: errorWidget ?? const Icon(Icons.broken_image_outlined),
  );
}
