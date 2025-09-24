import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/models/gig.dart';
import 'package:wawu_mobile/screens/gigs_screen/single_gig_screen/fullscreen_media_viewer.dart';

class GigHeader extends StatefulWidget {
  final Gig gig;

  const GigHeader({super.key, required this.gig});

  @override
  State<GigHeader> createState() => _GigHeaderState();
}

class _GigHeaderState extends State<GigHeader> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<dynamic> _mediaItems = [];

  @override
  void initState() {
    super.initState();
    // Populate media list: video first, then photos
    if (widget.gig.assets.video != null && widget.gig.assets.video!.link.isNotEmpty) {
      _mediaItems.add(widget.gig.assets.video!);
    }
    _mediaItems.addAll(widget.gig.assets.photos);

    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullscreenViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenMediaViewer(
          mediaItems: _mediaItems,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mediaItems.isEmpty) {
      return FlexibleSpaceBar(
        background: Container(
          color: Colors.purple.shade100,
          child:
              Icon(Icons.photo, color: Colors.purple.shade200, size: 80),
        ),
      );
    }

    return FlexibleSpaceBar(
      background: Stack(
        fit: StackFit.expand,
        children: [
          // **LAYER 1: INTERACTIVE SLIDER**
          // This is the base layer that needs to receive user gestures.
          PageView.builder(
            controller: _pageController,
            itemCount: _mediaItems.length,
            itemBuilder: (context, index) {
              final item = _mediaItems[index];

              Widget mediaWidget;
              if (item is Video) {
                // Video thumbnail
                mediaWidget = Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    if (widget.gig.assets.photos.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: widget.gig.assets.photos[0].link,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(color: Colors.purple.shade100),
                    Container(color: Colors.black.withOpacity(0.4)),
                    const Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 80),
                  ],
                );
              } else {
                // Photo
                mediaWidget = CachedNetworkImage(
                  imageUrl: (item as Photo).link,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.shade300),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.purple.shade100,
                    child: Icon(Icons.broken_image,
                        color: Colors.purple.shade200, size: 80),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _openFullscreenViewer(index),
                child: mediaWidget,
              );
            },
          ),
          
          // **LAYER 2: DECORATIVE OVERLAYS (NON-INTERACTIVE)**
          // We wrap all decorative elements in an IgnorePointer so gestures
          // pass through them to the PageView below.
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 60, right: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.gig.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(blurRadius: 10.0, color: Colors.black54)
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        widget.gig.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // **LAYER 3: PAGE INDICATOR**
          // This sits on top but is small enough not to cause major issues.
          if (_mediaItems.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_mediaItems.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}