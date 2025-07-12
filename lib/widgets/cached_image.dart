import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A unified image widget for network and asset images with caching and fallback.
///
/// Usage:
///   CachedImage(urlOrAsset: 'https://...', ...)
///   CachedImage(urlOrAsset: 'assets/images/other/avatar.webp', ...)
class CachedImage extends StatelessWidget {
  final String urlOrAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImage({
    Key? key,
    required this.urlOrAsset,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);

  bool get _isNetwork => urlOrAsset.startsWith('http');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: urlOrAsset,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => placeholder ??
            Center(child: SizedBox(width: width ?? 24, height: height ?? 24, child: CircularProgressIndicator(strokeWidth: 2))),
        errorWidget: (context, url, error) => errorWidget ??
            Icon(Icons.broken_image, size: width ?? 24, color: Colors.grey),
        imageBuilder: (context, imageProvider) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : borderRadius,
            image: DecorationImage(image: imageProvider, fit: fit),
          ),
        ),
      );
    } else {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : borderRadius,
          image: DecorationImage(
            image: AssetImage(urlOrAsset),
            fit: fit,
          ),
        ),
      );
    }
  }
}
