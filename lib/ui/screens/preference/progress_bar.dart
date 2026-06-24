import 'package:flutter/material.dart';

class ProgressStoryBar extends StatelessWidget {
  final int current;
  final int total;

  const ProgressStoryBar({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: List.generate(total, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index < current
                    ? Colors.green
                    : Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class FooterNav extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const FooterNav({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (currentStep > 1)
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              child: const Text('Back'),
            ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: onNext,
            child: Text(
              currentStep == totalSteps ? 'Finish' : 'Next >',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class StepWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const StepWrapper({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF114514))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF114514))),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
