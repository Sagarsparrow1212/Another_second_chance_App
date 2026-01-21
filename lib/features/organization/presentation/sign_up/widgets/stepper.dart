import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homelyhope/core/theme/app_theme.dart';

class Steppers extends ConsumerStatefulWidget {
  final int currentStep;
  final Function(int) onStepChanged;

  const Steppers({
    super.key,
    required this.currentStep,
    required this.onStepChanged,
  });

  @override
  ConsumerState<Steppers> createState() => _SteppersState();
}

class _SteppersState extends ConsumerState<Steppers> {
  final List<StepData> _steps = const [
    StepData(title: 'Organisation Details', subtitle: ''),
    StepData(title: 'Address Details', subtitle: ''),
    StepData(title: 'Upload Documents', subtitle: ''),
  ];

  // Track which steps have been animated to prevent replay
  final Set<int> _animatedSteps = {};

  @override
  void didUpdateWidget(Steppers oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detect when a step first becomes completed (wasn't completed before, but is now)
    for (int i = 0; i < _steps.length; i++) {
      final wasCompleted = i < oldWidget.currentStep;
      final isNowCompleted = i < widget.currentStep;

      // If step just became completed, trigger animation
      if (!wasCompleted && isNowCompleted) {
        _animatedSteps.add(i);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildStepIndicator();
  }

  Widget _buildStepIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            Expanded(
              child: GestureDetector(
                // onTap: () => widget.onStepChanged(i),
                child: _buildStepItem(
                  step: _steps[i],
                  stepNumber: i + 1,
                  isActive: i == widget.currentStep,
                  isCompleted: i < widget.currentStep,
                ),
              ),
            ),
            if (i != _steps.length - 1)
              SizedBox(
                width: screenWidth * 0.2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: _buildConnector(i < widget.currentStep),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required StepData step,
    required int stepNumber,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- CIRCLE (always fixed) ---
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppTheme.primary
                : isActive
                ? AppTheme.primary
                : Colors.grey[300],
            border: Border.all(
              color: isActive
                  ? AppTheme.secondary
                  : isCompleted
                  ? Colors.transparent
                  : Colors.black,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Animate(
              // Key changes only when step should animate (first time it becomes completed)
              // This prevents animation replay on subsequent rebuilds
              key: ValueKey(
                'step_${stepNumber}_animated_${_animatedSteps.contains(stepNumber - 1)}',
              ),
              effects: (isCompleted && _animatedSteps.contains(stepNumber - 1))
                  ? [
                      RotateEffect(
                        duration: 350.ms,
                        curve: Curves.easeOutBack,
                        begin: 0,
                        end: 1,
                      ),
                      FadeEffect(
                        duration: 300.ms,
                        curve: Curves.easeOut,
                        begin: 0.0,
                        end: 1.0,
                      ),
                    ]
                  : [],
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : isActive
                  ? Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    )
                  : Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // --- FIX: Equal height for title + subtitle block ---
        SizedBox(
          height: 40, // adjust to fit 1 or 2 lines
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive || isCompleted
                      ? AppTheme.primary
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (step.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  step.subtitle!,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector(bool isCompleted) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 4,
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child:
                Container(
                      width: constraints.maxWidth, // full width fixed
                      height: 4,
                      color: AppTheme.primary,
                    )
                    .animate(target: isCompleted ? 1 : 0)
                    .scaleX(
                      duration: 650.ms,
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.centerLeft,
                    )
                    .fadeIn(duration: 600.ms)
                    .slideX(begin: -0.1, end: 0, duration: 300.ms),
          ),
        );
      },
    );
  }
}

class StepData {
  final String title;
  final String? subtitle;

  const StepData({required this.title, this.subtitle});
}
