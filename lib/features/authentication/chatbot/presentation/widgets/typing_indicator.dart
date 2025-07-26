import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const CircleAvatar(radius: 12, backgroundColor: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 600),
                    tween: Tween(begin: 0.3, end: 1.0),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: const Text(
                          ".",
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                    onEnd: () {},
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
