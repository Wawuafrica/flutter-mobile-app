import 'package:flutter/material.dart';
import 'package:wawu_mobile/utils/constants/colors.dart';

/// Atomic: OnboardingProgressIndicator
/// Shows current onboarding step as a small circular progress indicator positioned at top right.
/// Shows a filled circle with check mark when completed (100%).
class OnboardingProgressIndicator extends StatefulWidget {
  final String currentStep;
  final List<String> steps;
  final Map<String, String> stepLabels;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    required this.steps,
    required this.stepLabels,
  });

  @override
  State<OnboardingProgressIndicator> createState() =>
      _OnboardingProgressIndicatorState();
}

class _OnboardingProgressIndicatorState
    extends State<OnboardingProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _currentStepIndex() => widget.steps.indexOf(widget.currentStep);

  @override
  void didUpdateWidget(OnboardingProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double progress = (_currentStepIndex() + 1) / widget.steps.length;

    // Trigger animation when progress reaches 100%
    if (progress >= 1.0 && oldWidget.currentStep != widget.currentStep) {
      _animationController.forward();
    } else if (progress < 1.0) {
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _currentStepIndex();
    final double progress = (currentIndex + 1) / widget.steps.length;
    final bool isCompleted = progress >= 1.0;

    return Container(
      margin: const EdgeInsets.only(right: 20),
      width: 24,
      height: 24,
      child:
          isCompleted
              ? AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: wawuColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  );
                },
              )
              : CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                backgroundColor: wawuColors.primary.withAlpha(50),
                valueColor: AlwaysStoppedAnimation<Color>(wawuColors.primary),
              ),
    );
  }
}
