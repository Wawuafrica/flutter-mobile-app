import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

class FadingCarousel extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final bool isBorderRadius;
  final Duration autoSlideInterval;
  final bool autoSlide;

  const FadingCarousel({
    this.autoSlide = true,
    this.autoSlideInterval = const Duration(seconds: 5),
    super.key,
    required this.children,
    this.height = 200,
    this.isBorderRadius = true,
  });

  @override
  FadingCarouselState createState() => FadingCarouselState();
}

class FadingCarouselState extends State<FadingCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoSlide) {
      _startAutoSlide();
    }
  }

  @override
  void didUpdateWidget(FadingCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoSlide != oldWidget.autoSlide || 
        widget.autoSlideInterval != oldWidget.autoSlideInterval) {
      _stopAutoSlide();
      if (widget.autoSlide) {
        _startAutoSlide();
      }
    }
  }

  @override
  void dispose() {
    _stopAutoSlide();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlide() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoSlideInterval, (_) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.children.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopAutoSlide() {
    _timer?.cancel();
    _timer = null;
  }

  void _onPageChanged(int page) {
    if (_currentPage != page) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _stopAutoSlide();
            } else if (notification is ScrollEndNotification) {
              if (widget.autoSlide) {
                _startAutoSlide();
              }
            }
            return false;
          },
          child: Container(
            height: widget.height,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  widget.isBorderRadius ? 10 : 0),
            ),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.children.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                    }
                    return Opacity(opacity: value, child: child);
                  },
                  child: widget.children[index],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            widget.children.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: 5.0,
              height: 5.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentPage == index
                        ? wawuColors.primary
                        : Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
